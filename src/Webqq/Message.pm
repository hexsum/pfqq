package Webqq::Message;
use JSON;
use Encode;
use Webqq::Client::Util qw(console_stderr);
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
                #收到的消息是普通消息
                if($m->{poll_type} eq 'message'){
                    my $msg = {
                        type        =>  'message',
                        msg_id      =>  $m->{value}{msg_id},
                        from_uin    =>  $m->{value}{from_uin},
                        to_uin      =>  $m->{value}{to_uin},
                        msg_time    =>  $m->{value}{'time'},
                        content     =>  $m->{value}{content}[1],
                    };
                    #将整个hash从unicode转为UTF8编码
                    $msg->{$_} = encode("utf8",$msg->{$_} ) for keys %$msg;
                    $msg->{content}=~s/ $//;
                    $msg->{content}=~s/\r|\n/\n/g;
                    
                    $client->{receive_message_queue}->put($msg);
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
                    #将整个hash从unicode转为UTF8编码
                    $msg->{$_} = encode("utf8",$msg->{$_} ) for keys %$msg;
                    $msg->{content}=~s/ $//;
                    $msg->{content}=~s/\r|\n/\n/g;
                    $client->{receive_message_queue}->put($msg);
                }
                #还未识别和处理的消息
                else{

                }  
            }
        }
        #可以忽略的消息，暂时不做任何处理
        elsif($json->{retcode} == 102){
        }
        #其他未知消息
        else{
            console_stderr "读取到未知消息: $json_txt\n";
        }
    } 
}
1;

