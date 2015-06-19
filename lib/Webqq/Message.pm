package Webqq::Message;
use Webqq::Message::Face;
use JSON;
use Encode;
use Webqq::Client::Util qw(console code2client);
use Scalar::Util qw(blessed);
sub reply_message{
    my $client = shift;
    my $msg = shift;
    my $content = shift;
    unless(blessed($msg)){
        console "输入的msg数据非法\n";
        return 0;
    }
    if($msg->{type} eq 'message'){
        $client->send_message(
            $client->create_msg(to_uin=>$msg->{from_uin},content=>$content)
        );
    }
    elsif($msg->{type} eq 'group_message'){
        $client->send_group_message(
            $client->create_group_msg( 
                to_uin=>$msg->{from_uin},    
                content=>$content,
                group_code=>$msg->{group_code}  
            )  
        ); 
    }
    elsif($msg->{type} eq 'discuss_message'){
        $client->send_discuss_message(
            $client->create_discuss_msg(
                to_uin =>$msg->{did} || $msg->{from_uin},
                content =>$content,
            )   
        );
    }
    elsif($msg->{type} eq 'sess_message'){
        #群临时消息
        if($msg->{via} eq 'group'){
            $client->send_sess_message(
                $client->create_sess_msg(
                    to_uin          =>  $msg->{from_uin},
                    content         =>  $content,
                    group_code      =>  $msg->{group_code},
                    gid             =>  $msg->{gid},
                )
            );
        }
        #讨论组临时消息
        elsif($msg->{via} eq 'discuss'){
            $client->send_sess_message(
                $client->create_sess_msg(
                    to_uin          =>  $msg->{from_uin},
                    content         =>  $content,
                    did             =>  $msg->{did},           
                )
            );
        }
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
sub create_discuss_msg{
    my $client = shift;
    return $client->_create_msg(@_,type=>'discuss_message');
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
        ttl         => 5,
        allow_plugin => 1,
        client      =>  $client,
    );
    if($p{type} eq 'sess_message'){
        if(defined $p{group_code}){
            $msg{group_code} = $p{group_code};
            $msg{service_type} = 0;
            $msg{via} = 'group';
            my $id = defined $p{gid}?$p{gid}:$client->search_group($p{group_code})->{gid};
            $msg{group_sig} = $client->_get_group_sig($id,$p{to_uin},$msg{service_type});
        }
        elsif(defined $p{gid}){
            $msg{group_code} = $client->get_group_code_from_gid($p{gid});
            $msg{service_type} = 0;
            $msg{via} = 'group';
            my $id = $p{gid};
            $msg{group_sig} = $client->_get_group_sig($id,$p{to_uin},$msg{service_type});
        }
        elsif(defined $p{did}){
            $msg{did} = $p{did};
            $msg{service_type} = 1;
            $msg{via} = 'discuss';
            $msg{group_sig} = $client->_get_group_sig($p{did},$p{to_uin},$msg{service_type});
        }
        else{
            console "create_sess_msg()必须设置group_code或者did\n";
            return ;
        }
    }
    elsif($p{type} eq 'group_message'){
        $msg{group_code} = $p{group_code}||$client->get_group_code_from_gid($p{to_uin});
        $msg{send_uin} = $msg{from_uin};
    }   
    elsif($p{type} eq 'discuss_message'){
        $msg{did} = $p{did} || $p{to_uin};
        $msg{send_uin} = $msg{from_uin};
    }
    my $msg_pkg = "\u$p{type}::Send"; 
    $msg_pkg=~s/_(.)/\u$1/g;
    return $client->_mk_ro_accessors(\%msg,$msg_pkg);
     
}

sub _load_extra_accessor {
    *Webqq::Message::DiscussMessage::Recv::discuss_name = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $d = $client->search_discuss($msg->{did});
        return defined $d?$d->{name}:undef ;
    };
    *Webqq::Message::DiscussMessage::Recv::from_dname = sub{
        my $msg = shift; 
        my $client = $msg->{client};
        my $d = $client->search_discuss($msg->{did});
        return defined $d?$d->{name}:undef ;
    };    
    *Webqq::Message::DiscussMessage::Recv::from_qq = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $m = $client->search_member_in_discuss($msg->{did},$msg->{send_uin});
        return defined $m?$m->{ruin}:$client->get_qq_from_uin($msg->{send_uin});
    }; 
    *Webqq::Message::DiscussMessage::Recv::from_nick = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $m = $client->search_member_in_discuss($msg->{did},$msg->{send_uin});
        return defined $m?$m->{nick}:undef;
    };    
    
    *Webqq::Message::DiscussMessage::Send::discuss_name = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $d  = $client->search_discuss($msg->{did});
        return defined $d?$d->{name}:undef;
    };
    *Webqq::Message::DiscussMessage::Send::to_dname = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $d  = $client->search_discuss($msg->{did});
        return defined $d?$d->{name}:undef;
    };
    *Webqq::Message::DiscussMessage::Send::from_qq = sub{
        my $msg = shift;
        my $client = $msg->{client};
        return $client->{qq_param}{qq};
    };
    *Webqq::Message::DiscussMessage::Send::from_nick = sub{
        return "我";
    }; 

    *Webqq::Message::GroupMessage::Recv::group_name = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $g = $client->search_group($msg->{group_code});
        return defined $g?$g->{name}:undef ;
    };
    *Webqq::Message::GroupMessage::Recv::from_gname = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $g = $client->search_group($msg->{group_code});
        return defined $g?$g->{name}:undef ;
    };
    *Webqq::Message::GroupMessage::Recv::from_qq = sub{
        my $msg = shift;
        my $client = $msg->{client};
        #my $m = $client->search_member_in_group($msg->{group_code},$msg->{send_uin});
        #return $m->{qq} if(defined $m and defined $m->{qq});
        return $client->get_qq_from_uin($msg->{send_uin});
    };
    *Webqq::Message::GroupMessage::Recv::from_nick = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $m = $client->search_member_in_group($msg->{group_code},$msg->{send_uin});
        return defined $m?$m->{nick}:undef;
    };
    *Webqq::Message::GroupMessage::Recv::from_card = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $m = $client->search_member_in_group($msg->{group_code},$msg->{send_uin});
        return defined $m?$m->{card}:undef;
    };
    *Webqq::Message::GroupMessage::Recv::from_city = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $m = $client->search_member_in_group($msg->{group_code},$msg->{send_uin});
        return defined $m?$m->{city}:undef;
    };

    *Webqq::Message::GroupMessage::Send::group_name = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $g  = $client->search_group($msg->{group_code});
        return defined $g?$g->{name}:undef;
    };
    *Webqq::Message::GroupMessage::Send::to_gname = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $g  = $client->search_group($msg->{group_code});
        return defined $g?$g->{name}:undef;
    };
    *Webqq::Message::GroupMessage::Send::from_qq = sub{
        my $msg = shift;
        my $client = $msg->{client};
        return $client->{qq_param}{qq};
    };
    *Webqq::Message::GroupMessage::Send::from_nick = sub{
        return "我";
    };


    *Webqq::Message::SessMessage::Recv::from_nick = sub{
        my $msg = shift;
        my $client = $msg->{client};
        if($msg->{via} eq 'group'){
            my $m = $client->search_member_in_group($msg->{group_code},$msg->{from_uin});
            return defined $m?$m->{nick}:undef;
        }
        elsif($msg->{via} eq 'discuss'){
            my $m = $client->search_member_in_discuss($msg->{did},$msg->{from_uin});
            return defined $m?$m->{nick}:undef;
        }   
        else{return undef}
    };
    *Webqq::Message::SessMessage::Recv::from_qq = sub {
        my $msg = shift;
        my $client = $msg->{client};
        return $msg->{ruin};
    };
    *Webqq::Message::SessMessage::Recv::to_nick = sub{
        return "我";
    };
    *Webqq::Message::SessMessage::Recv::to_qq = sub {
        my $msg = shift;
        my $client = $msg->{client};
        return $client->{qq_param}{qq};
    };

    *Webqq::Message::SessMessage::Recv::via_type = sub {
        my $msg = shift;
        my $client = $msg->{client};
        return      $msg->{via} eq 'group'      ?       "群" 
                :   $msg->{via} eq 'discuss'    ?       "讨论组"
                :                                       undef
                ;
    }; 
    *Webqq::Message::SessMessage::Recv::via_name = sub {
        my $msg = shift;
        my $client = $msg->{client};
        if($msg->{via} eq 'group'){
            my $g = $client->search_group($msg->{group_code});
            return defined $g?$g->{name}:undef;
        }
        elsif($msg->{via} eq 'discuss'){
            my $d = $client->search_discuss($msg->{did});
            return defined $d?$d->{name}:undef;
        }
        else{return }
    };


    *Webqq::Message::SessMessage::Send::from_nick = sub{
        return "我";
    };
    *Webqq::Message::SessMessage::Send::from_qq = sub {
        my $msg = shift;
        my $client = $msg->{client};
        return $client->{qq_param}{qq};
    };
    *Webqq::Message::SessMessage::Send::to_nick = sub{
        my $msg = shift;
        my $client = $msg->{client};
        if($msg->{via} eq 'group'){
            my $m = $client->search_member_in_group($msg->{group_code},$msg->{to_uin});
            return defined $m?$m->{nick}:undef;
        }
        elsif($msg->{via} eq 'discuss'){
            my $m = $client->search_member_in_discuss($msg->{did},$msg->{to_uin});
            return defined $m?$m->{nick}:undef;
        }
        else{return }
    };
    *Webqq::Message::SessMessage::Send::to_qq = sub{
        my $msg = shift;
        my $client = $msg->{client};
        return $client->get_qq_from_uin($msg->{to_uin});
    };
    *Webqq::Message::SessMessage::Send::via_name = sub{
        my $msg = shift;
        my $client = $msg->{client};
        if($msg->{via} eq 'group'){
            my $g = $client->search_group($msg->{group_code});
            return defined $g?$g->{name}:undef; 
        }
        elsif($msg->{via} eq 'discuss'){
            my $d = $client->search_discuss($msg->{did});
            return defined $d?$d->{name}:undef;
        }
        else{return}
    };

    *Webqq::Message::SessMessage::Send::via_type = sub {
        my $msg = shift;
        my $client = $msg->{client};
        return      $msg->{via} eq 'group'      ?       "群"
                :   $msg->{via} eq 'discuss'    ?       "讨论组"
                :                                       undef
                ;
    };
    *Webqq::Message::Message::Recv::from_nick = sub{
        my $msg = shift;    
        my $client = $msg->{client};
        my $f = $client->search_friend($msg->{from_uin});
        return defined $f?$f->{nick}:undef;
    };
    *Webqq::Message::Message::Recv::from_qq = sub{
        my $msg = shift;
        my $client = $msg->{client};
        #my $f = $client->search_friend($msg->{from_uin});
        #return $f->{qq} if(defined $f and defined $f->{qq});
        return $client->get_qq_from_uin($msg->{from_uin});
    };
    *Webqq::Message::Message::Recv::from_markname = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $f = $client->search_friend($msg->{from_uin});
        return defined $f?$f->{markname}:undef;
    };
    *Webqq::Message::Message::Recv::from_categories = sub {
        my $msg = shift;    
        my $client = $msg->{client};
        my $f = $client->search_friend($msg->{from_uin});
        return defined $f?$f->{categories}:undef;
    };

    *Webqq::Message::Message::Recv::from_city = sub {
        my $msg = shift;    
        my $client = $msg->{client};
        my $f = $client->search_friend($msg->{from_uin});
        return defined $f?$f->{city}:undef;
    };
    
    *Webqq::Message::Message::Recv::to_nick = sub{
        return "我";
    };
    *Webqq::Message::Message::Recv::to_qq = sub {
        my $msg = shift;
        my $client = $msg->{client};
        return $client->{qq_param}{qq};
    };


    *Webqq::Message::Message::Send::from_nick = sub{
        return "我";
    };
    *Webqq::Message::Message::Send::from_qq = sub{
        my $msg = shift;
        my $client = $msg->{client};
        return $client->{qq_param}{qq};
    };
    *Webqq::Message::Message::Send::to_nick = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $f = $client->search_friend($msg->{to_uin});
        return defined $f?$f->{nick}:undef;
    };
    *Webqq::Message::Message::Send::to_qq = sub{
        my $msg = shift;
        my $client = $msg->{client};
        return $client->get_qq_from_uin($msg->{to_uin});
    };
    *Webqq::Message::Message::Send::to_markname = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $f = $client->search_friend($msg->{to_uin});
        return defined $f?$f->{markname}:undef;
    };
    *Webqq::Message::Message::Send::to_categories = sub{
        my $msg = shift;
        my $client = $msg->{client};
        my $f = $client->search_friend($msg->{to_uin});
        return defined $f?$f->{categories}:undef;
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
    eval{$json = JSON->new->utf8->decode($json_txt)};
    console "解析消息失败: $@ 对应的消息内容为: $json_txt\n" if $@ and $client->{debug};
    if(ref $json eq 'HASH' and $json->{retcode}==0){
        return {is_success=>1,status=>"发送成功"}; 
    }
    else{
        return {is_success=>0,status=>"发送失败"};
    }
}
#消息的后期处理
sub msg_put{   
    my $client = shift;
    my $msg = shift;
    $msg->{raw_content} = [];
    my $msg_content;
    shift @{ $msg->{content} };
    for my $c (@{ $msg->{content} }){
        if(ref $c eq 'ARRAY'){
            if($c->[0] eq 'cface'){
                push @{$msg->{raw_content}},{
                    type    =>  'cface',
                    content =>  '[图片]',
                    name    =>  $c->[1]{name},
                    file_id =>  $c->[1]{file_id},
                    key     =>  $c->[1]{key},
                    server  =>  $c->[1]{server},
                };
                $c="[图片]";
            }
            elsif($c->[0] eq 'offpic'){
                push @{$msg->{raw_content}},{
                    type        =>  'offpic',
                    content     =>  '[图片]',
                    file_path   =>  $c->[1]{file_path},
                };
                $c="[图片]";
            }
            elsif($c->[0] eq 'face'){
                push @{$msg->{raw_content}},{
                    type    =>  'face',
                    content =>  face_to_txt($c),
                    id      =>  $c->[1],
                }; 
                $c=face_to_txt($c);
            }
            else{
                push @{$msg->{raw_content}},{
                    type    =>  'unknown',
                    content =>  '[未识别内容]',
                };
                $c = "[未识别内容]";
            }
        }
        elsif($c eq " "){
            next;
        }
        else{
            $c=encode("utf8",$c);
            $c=~s/ $//;   
            $c=~s/\r|\n/\n/g;
            #{"retcode":0,"result":[{"poll_type":"group_message","value":{"msg_id":538,"from_uin":2859929324,"to_uin":3072574066,"msg_id2":545490,"msg_type":43,"reply_ip":182424361,"group_code":2904892801,"send_uin":1951767953,"seq":3024,"time":1418955773,"info_seq":390179723,"content":[["font",{"size":12,"color":"000000","style":[0,0,0],"name":"\u5FAE\u8F6F\u96C5\u9ED1"}],"[\u50BB\u7B11]\u0001 "]}}]}
            #if($c=~/\[[^\[\]]+?\]\x{01}/)
            push @{$msg->{raw_content}},{
                type    =>  'txt',
                content =>  $c,
            };
        }
        $msg_content .= $c;
    }
    $msg->{content} = $msg_content;
    $msg->{client} = $client;
    #将整个hash从unicode转为UTF8编码
    #$msg->{$_} = encode("utf8",$msg->{$_} ) for grep {$_ ne 'raw_content'}  keys %$msg;
    #$msg->{content}=~s/\r|\n/\n/g;
    if($msg->{content}=~/\(\d+\) 被管理员禁言\d+(分钟|小时|天)$/ or $msg->{content}=~/\(\d+\) 被管理员解除禁言$/){
        $msg->{type} = "sys_g_msg";
        return;
    }
    my $msg_pkg = "\u$msg->{type}::Recv"; $msg_pkg=~s/_(.)/\u$1/g;
    $msg = $client->_mk_ro_accessors($msg,$msg_pkg) ;
    $client->{receive_message_queue}->put($msg);
}

sub parse_receive_msg{
    my $client = shift;
    return if $client->{is_stop} ;
    my ($json_txt) = @_;  
    my $json     = undef;
    eval{$json = JSON->new->utf8->decode($json_txt)};
    console "解析消息失败: $@ 对应的消息内容为: $json_txt\n" if $@ and $client->{debug};
    if($json){
        #一个普通的消息
        if($json->{retcode}==0){
            $client->{poll_failure_count} = 0;
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
                        msg_class   =>  "recv",
                        ttl         =>  5,  
                        allow_plugin => 1,
                    };
                    #service_type =0 表示群临时消息，1 表示讨论组临时消息
                    if($m->{value}{service_type} == 0){
                        $msg->{gid} = $m->{value}{id};
                        $msg->{group_code}  =  $client->get_group_code_from_gid($m->{value}{id}),
                        $msg->{via}  = 'group';
                    }
                    elsif($m->{value}{service_type} == 1){
                        $msg->{did} = $m->{value}{id};
                        $msg->{via}  = 'discuss';    
                    }
                    else{return}
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
                        ttl         =>  5,
                        allow_plugin => 1,
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
                        ttl         =>  5,
                        allow_plugin => 1,
                    };
                    $client->msg_put($msg);
                }
                #收到讨论组消息
                elsif($m->{poll_type} eq 'discu_message'){
                    my $msg = {
                        type        =>  'discuss_message',
                        did         =>  $m->{value}{did},
                        from_uin    =>  $m->{value}{from_uin},
                        msg_id      =>  $m->{value}{msg_id},
                        send_uin    =>  $m->{value}{send_uin},
                        msg_time    =>  $m->{value}{'time'},
                        to_uin      =>  $m->{value}{'to_uin'},
                        content     =>  $m->{value}{content},
                        msg_class   =>  "recv",
                        ttl         =>  5,
                        allow_plugin => 1,
                    };
                    $client->msg_put($msg);
                }
                elsif($m->{poll_type} eq 'buddies_status_change'){
                    my $msg = {
                        type        =>  'buddies_status_change',
                        uin         =>  $m->{value}{uin},
                        state       =>  $m->{value}{status},
                        client_type =>  code2client($m->{value}{client_type}),
                    };
                    $client->msg_put($msg); 
                }   
                #收到系统消息
                elsif($m->{poll_type} eq 'sys_g_msg'){
                    #my $msg = {
                    #    type        =>  'sys_g_msg',
                    #    msg_id      =>  $m->{value}{msg_id},
                    #    from_uin    =>  $m->{value}{from_uin},
                    #    to_uin      =>  $m->{value}{to_uin},
                    #     
                    #};
                    #$client->msg_put($msg);
                }
                #收到强制下线消息
                elsif($m->{poll_type} eq 'kick_message'){
                    if($m->{value}{show_reason} ==1){
                        my $reason = encode("utf8",$m->{value}{reason});
                        console "$reason\n";
                        $client->stop();
                    }
                    else {console "您已被迫下线\n";$client->stop(); }
                }
                #还未识别和处理的消息
                else{

                }  
            }
        }
        #可以忽略的消息，暂时不做任何处理
        elsif($json->{retcode} == 102 or $json->{retcode} == 109 or $json->{retcode} == 110 ){
            $client->{poll_failure_count} = 0;
        }
        #更新客户端ptwebqq值
        elsif($json->{retcode} == 116){
            $client->{qq_param}{ptwebqq} = $json->{p};
            $client->{cookie_jar}->set_cookie(0,"ptwebqq",$json->{p},"/","qq.com",);
        }
        #未重新登录
        elsif($json->{retcode} ==100){
            console "因网络或其他原因与服务器失去联系，客户端需要重新登录...\n";
            $client->relogin();
        }
        #重新连接失败
        elsif($json->{retcode} ==120 or $json->{retcode} ==121 ){
            console "因网络或其他原因与服务器失去联系，客户端需要重新连接...\n";
            $client->_relink();
        }
        #其他未知消息
        else{
            $client->{poll_failure_count}++;
            console "获取消息失败，当前失败次数: $client->{poll_failure_count}\n";
            if($client->{poll_failure_count} > $client->{poll_failure_count_max}){
                console "接收消息失败次数超过最大值，尝试进行重新连接...\n";
                $client->{poll_failure_count}   =  0;
                $client->_relink();
            }
        }
    } 
}
1;

