package Webqq::Message;
use Webqq::Message::Face;
use JSON;
use Encode;
use Webqq::Client::Util qw(console_stderr console);
use Scalar::Util qw(blessed);
sub reply_message{
    my $client = shift;
    my $msg = shift;
    my $content = shift;
    unless(blessed($msg)){
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
            $client->create_group_msg( 
                to_uin=>$to_uin,    
                content=>$content,
                group_code=>$msg->{group_code}  
            )  
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
        msg_class   => "send",
        msg_time    => time,
        cb          => $p{cb},
    );
    if($p{type} eq 'sess_message'){
        $msg{service_type} = $p{service_type};
        $msg{group_sig} = $p{group_sig};
    }
    elsif($p{type} eq 'group_message'){
        $msg{group_code} = $p{group_code}||$client->get_group_code_from_gid($p{to_uin});
        $msg{send_uin} = $msg{from_uin};
    }   
    my $msg_pkg = "\u$p{type}::Send"; 
    $msg_pkg=~s/_(.)/\u$1/g;
    return $client->_mk_ro_accessors(\%msg,$msg_pkg);
     
}

sub _load_extra_accessor {
    my $client = shift;
    *Webqq::Message::GroupMessage::Recv::group_name = sub{
        my $msg = shift;
        return $client->search_group($msg->{group_code})->{name} ;
    };
    *Webqq::Message::GroupMessage::Recv::from_gname = sub{
        my $msg = shift;
        return $client->search_group($msg->{group_code})->{name} ;
    };
    *Webqq::Message::GroupMessage::Recv::from_qq = sub{
        my $msg = shift;
        return $client->get_qq_from_uin($msg->{send_uin});
    };
    *Webqq::Message::GroupMessage::Recv::from_nick = sub{
        my $msg = shift;
        return $client->search_member_in_group($msg->{group_code},$msg->{send_uin})->{nick};
    };
    *Webqq::Message::GroupMessage::Recv::from_card = sub{
        my $msg = shift;
        return $client->search_member_in_group($msg->{group_code},$msg->{send_uin})->{card};
    };
    *Webqq::Message::GroupMessage::Send::group_name = sub{
        my $msg = shift;
        return $client->search_group($msg->{group_code})->{name} ;
    };
    *Webqq::Message::GroupMessage::Send::to_gname = sub{
        my $msg = shift;
        return $client->search_group($msg->{group_code})->{name} ;
    };
    *Webqq::Message::GroupMessage::Send::from_qq = sub{
        return $client->{qq_param}{qq};
    };
    *Webqq::Message::GroupMessage::Send::from_nick = sub{
        return "我";
    };


    *Webqq::Message::SessMessage::Recv::from_nick = sub{
        my $msg = shift;
        return $client->search_stranger($msg->{from_uin})->{nick}; 
    };
    *Webqq::Message::SessMessage::Recv::from_qq = sub {
        my $msg = shift;
        #return $client->get_qq_from_uin($msg->{from_uin}); 
        return $msg->{ruin};
    };
    *Webqq::Message::SessMessage::Recv::to_nick = sub{
        return "我";
    };
    *Webqq::Message::SessMessage::Recv::to_qq = sub {
        return $client->{qq_param}{qq};
    };

    *Webqq::Message::SessMessage::Send::from_nick = sub{
        return "我";
    };
    *Webqq::Message::SessMessage::Send::from_qq = sub {
        return $client->{qq_param}{qq};
    };
    *Webqq::Message::SessMessage::Send::to_nick = sub{
        my $msg = shift;
        return $client->search_stranger($msg->{to_uin})->{nick};
    };
    *Webqq::Message::SessMessage::Send::to_qq = sub{
        my $msg = shift;
        return $client->get_qq_from_uin($msg->{to_uin});
    };
    


    *Webqq::Message::Message::Recv::from_nick = sub{
        my $msg = shift;
        return $client->search_friend($msg->{from_uin})->{nick};
    };
    *Webqq::Message::Message::Recv::from_qq = sub{
        my $msg = shift;
        return $client->get_qq_from_uin($msg->{from_uin});
    };
    *Webqq::Message::Message::Recv::from_markname = sub{
        my $msg = shift;
        return $client->search_friend($msg->{from_uin})->{markname};
    };
    *Webqq::Message::Message::Recv::from_categories = sub {
        my $msg = shift;
        return $client->search_friend($msg->{from_uin})->{categories};
    };
    
    *Webqq::Message::Message::Recv::to_nick = sub{
        return "我";
    };
    *Webqq::Message::Message::Recv::to_qq = sub {
        return $client->{qq_param}{qq};
    };


    *Webqq::Message::Message::Send::from_nick = sub{
        return "我";
    };
    *Webqq::Message::Message::Send::from_qq = sub{
        return $client->{qq_param}{qq};
    };
    *Webqq::Message::Message::Send::to_nick = sub{
        my $msg = shift;
        return $client->search_friend($msg->{to_uin})->{nick};
    };
    *Webqq::Message::Message::Send::to_qq = sub{
        my $msg = shift;
        return $client->get_qq_from_uin($msg->{to_uin});
    };
    *Webqq::Message::Message::Send::to_markname = sub{
        my $msg = shift;
        return $client->search_friend($msg->{to_uin})->{markname};
    };
    *Webqq::Message::Message::Send::to_categories = sub{
        my $msg = shift;
        return $client->search_friend($msg->{to_uin})->{categories};
    };

}

sub _mk_ro_accessors {
    my $client = shift;
    my $msg =shift;    
    my $msg_pkg = shift;
    no strict 'refs';
    for my $field (keys %$msg){
        *{"Webqq::Message::${msg_pkg}::$field"} = sub{
            my $self = shift;
            my $pkg = ref $self;
            die "the value of \"$field\" in $pkg is read-only\n" if @_!=0;
            return $self->{$field};
        };
    }
          
    $msg = bless $msg,"Webqq::Message::$msg_pkg";
    return $msg;
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
    my $msg_content;
    shift @{ $msg->{content} };
    for my $c (@{ $msg->{content} }){
        if(ref $c eq 'ARRAY'){
            if($c->[0] eq 'cface'){$c=decode("utf8","[图片]");}
            elsif($c->[0] eq 'face'){$c=decode("utf8",face_to_txt($c));}
            else{$c = decode("utf8","[未识别内容]");}
        }
        elsif($c eq " "){
            next;
        }
        else{
            $c=~s/ $//;   
        }
        $msg_content .= $c;
    }
    $msg->{content} = $msg_content;
    #将整个hash从unicode转为UTF8编码
    $msg->{$_} = encode("utf8",$msg->{$_} ) for keys %$msg;
    $msg->{content}=~s/\r|\n/\n/g;
    my $msg_pkg = "\u$msg->{type}::Recv"; $msg_pkg=~s/_(.)/\u$1/g;
    $msg = $client->_mk_ro_accessors($msg,$msg_pkg) ;
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
                        content     =>  $m->{value}{content},
                        service_type=>  $m->{value}{service_type},
                        ruin        =>  $m->{value}{ruin},
                        id          =>  $m->{value}{id},
                        msg_class   =>  "recv",
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
                        content     =>  $m->{value}{content},
                        msg_class   =>  "recv",
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
                        content     =>  $m->{value}{content},
                        send_uin    =>  $m->{value}{send_uin},
                        group_code  =>  $m->{value}{group_code}, 
                        msg_class   =>  "recv",
                    };
                    $client->msg_put($msg);
                }
                #收到强制下线消息
                elsif($m->{poll_type} eq 'kick_message'){
                    if($m->{value}{show_reason} ==1){
                        my $reason = encode("utf8",$m->{value}{reason});
                        console "$reason\n" ;
                        exit;
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
        elsif($json->{retcode} ==100 or $json->{retcode} ==103){
            console_stderr "需要重新登录\n";
            $client->relogin();
        }
        #重新连接失败
        elsif($json->{retcode} ==120 or $json->{retcode} ==121 ){
            console_stderr "重新连接失败\n";
            $client->relogin();
        }
        #其他未知消息
        else{console_stderr "读取到未知消息: $json_txt\n";}
    } 
}
1;

