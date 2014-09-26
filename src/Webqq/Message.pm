package Webqq::Message;
use JSON;
use Encode;
use Webqq::Client::Util qw(console_stderr console);
sub reply_message{
    my $client = shift;
    my $msg = shift;
    my $content = shift;
    if(ref $msg ne 'HASH'){
        console_stderr "输入的msg数据非法\n";
        return 0;
    }
    if($msg->{type} eq 'message'){
        $client->send_message(
            $client->create_msg(to_uin=>$msg->{from_uin},content=>$content)
        );

    }
    elsif($msg->{type} eq 'group_message'){
        my $to_uin = $client->search_group($msg->{group_code})->{gid} || $msg->{from_uin};
        $client->send_group_message(
            $client->create_group_msg( to_uin=>$to_uin,content=>$content  )  
        ); 
    }
    elsif($msg->{type} eq 'sess_message'){
        $client->send_sess_message(
            $client->create_sess_msg(
                group_sig =>  $client->_get_group_sig($msg->{id},$msg->{from_uin},$msg->{service_type}),
                to_uin    =>  $msg->{from_uin},
                content   =>  $content,
                service_type =>  $msg->{service_type},
            )
        );
    }
    
}
sub create_sess_msg{
    my $client = shift;
    return $client->_create_msg(@_,type=>'sess_message');
}
sub create_group_msg{   
    my $client = shift;
    return $client->_create_msg(@_,type=>'group_message');
}
sub create_msg{
    my $client = shift;
    return $client->_create_msg(@_,type=>'message');
}
sub _create_msg {
    my $client = shift;
    my %p = @_;
    $p{content} =~s/\r|\n/\n/g;
    my %msg = (
        type        => $p{type},
        msg_id      => $p{msg_id} || ++$client->{qq_param}{send_msg_id},
        from_uin    => $p{from_uin} || $client->{qq_param}{from_uin},
        to_uin      => $p{to_uin},
        content     => $p{content},
        cb          => $p{cb},
    );
    if($p{type} eq 'sess_message'){
        $msg{service_type} = $p{service_type};
        $msg{group_sig} = $p{group_sig};
    }
    return bless \%msg,__PACKAGE__;
     
}

sub parse_send_status_msg{
    my $client = shift;
    my ($json_txt) = @_;
    my $json     = undef;
    eval{$json = JSON->new->decode($json_txt)};
    console_stderr "解析消息失败: $@ 对应的消息内容为: $json_txt\n" if $@;
    if($json){
        #发送消息成功
        if($json->{retcode}==0){
            return {is_success=>1,status=>"发送成功"}; 
        }
        else{
            return {is_success=>0,status=>"发送失败"};
        }
    }
}
#消息的后期处理
sub msg_put{   
    my $client = shift;
    my $msg = shift;
    if(ref $msg->{content} eq 'ARRAY'){
        if($msg->{content}[0] eq 'cface'){$msg->{content} = decode("utf8","[图片]")}
        elsif($msg->{content}[0] eq 'face'){$msg->{content} = decode("utf8","[系统表情]")}
        else{$msg->{content} = decode("utf8","未识别内容")} 
    }
    #将整个hash从unicode转为UTF8编码
    $msg->{$_} = encode("utf8",$msg->{$_} ) for keys %$msg;
    $msg->{content}=~s/ $//;
    $msg->{content}=~s/\r|\n/\n/g;
    
    $client->{receive_message_queue}->put($msg);
}

sub parse_receive_msg{
    my $client = shift;
    my ($json_txt) = @_;  
    my $json     = undef;
    eval{$json = JSON->new->decode($json_txt)};
    console_stderr "解析消息失败: $@ 对应的消息内容为: $json_txt\n" if $@;
    if($json){
        #一个普通的消息
        if($json->{retcode}==0){
            for my $m (@{ $json->{result} }){
                #收到群临时消息
                if($m->{poll_type} eq 'sess_message'){
                    my $msg = {
                        type        =>  'sess_message',
                        msg_id      =>  $m->{value}{msg_id},
                        from_uin    =>  $m->{value}{from_uin},
                        to_uin      =>  $m->{value}{to_uin},
                        msg_time    =>  $m->{value}{'time'},
                        content     =>  $m->{value}{content}[1],
                        service_type=>  $m->{value}{service_type},
                        id          =>  $m->{value}{id},
                    };
                    $client->msg_put($msg);
                }
                #收到的消息是普通消息
                elsif($m->{poll_type} eq 'message'){
                    my $msg = {
                        type        =>  'message',
                        msg_id      =>  $m->{value}{msg_id},
                        from_uin    =>  $m->{value}{from_uin},
                        to_uin      =>  $m->{value}{to_uin},
                        msg_time    =>  $m->{value}{'time'},
                        content     =>  $m->{value}{content}[1],
                    };
                    $client->msg_put($msg);
                }   
                #收到的消息是群消息
                elsif($m->{poll_type} eq 'group_message'){
                    my $msg = {
                        type        =>  'group_message',
                        msg_id      =>  $m->{value}{msg_id},
                        from_uin    =>  $m->{value}{from_uin},
                        to_uin      =>  $m->{value}{to_uin},
                        msg_time    =>  $m->{value}{'time'},
                        content     =>  $m->{value}{content}[1],
                        send_uin    =>  $m->{value}{send_uin},
                        group_code  =>  $m->{value}{group_code}, 
                    };
                    $client->msg_put($msg);
                }
                #收到强制下线消息
                elsif($m->{poll_type} eq 'kick_message'){
                    if($m->{value}{show_reason} ==1){
                        console "$m->{value}{reason}\n" ;
                    }
                    else {console "您已被迫下线\n" }
                    exit;                    
                }
                #还未识别和处理的消息
                else{

                }  
            }
        }
        #可以忽略的消息，暂时不做任何处理
        elsif($json->{retcode} == 102){}
        #更新客户端ptwebqq值
        elsif($json->{retcode} == 116){$client->{qq_param}{ptwebqq} = $json->{p};}
        #未重新登录
        elsif($json->{retcode} ==100){
            console_stderr "需要重新登录\n";
        }
        #重新连接失败
        elsif($json->{retcode} ==120 or $json->{retcode} ==121){
            console_stderr "重新连接失败\n";
        }
        #其他未知消息
        else{console_stderr "读取到未知消息: $json_txt\n";}
    } 
}
1;

