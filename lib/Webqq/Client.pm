package Webqq::Client;
use strict;
use JSON;
use Encode;
use Time::HiRes qw(gettimeofday);
use LWP::Protocol::https;
use Storable qw(dclone);
use List::Util qw(first);
use base qw(Webqq::Message Webqq::Client::Cron Webqq::Client::Plugin);
use Webqq::Client::Cache;
use Webqq::Message::Queue;

#定义模块的版本号
our $VERSION = "8.5.3";

use LWP::UserAgent;#同步HTTP请求客户端
use Webqq::UserAgent;#异步HTTP请求客户端

use Webqq::Client::Util qw(console);

#为避免在主文件中包含大量Method的代码，降低阅读性，故采用分文件加载的方式
#类似c语言中的.h文件和.c文件的关系
use Webqq::Client::Method::_prepare_for_login;
use Webqq::Client::Method::_check_verify_code;
use Webqq::Client::Method::_get_img_verify_code;
use Webqq::Client::Method::_login1;
use Webqq::Client::Method::_check_sig;
use Webqq::Client::Method::_login2;
use Webqq::Client::Method::_recv_message;
use Webqq::Client::Method::_get_group_info;
use Webqq::Client::Method::_get_group_sig;
use Webqq::Client::Method::_get_group_list_info;
use Webqq::Client::Method::_get_user_friends;
use Webqq::Client::Method::_get_user_info;
use Webqq::Client::Method::_get_friend_info;
use Webqq::Client::Method::_get_stranger_info;
use Webqq::Client::Method::_send_message;
use Webqq::Client::Method::_send_group_message;
use Webqq::Client::Method::_get_vfwebqq;
use Webqq::Client::Method::_send_sess_message;
use Webqq::Client::Method::logout;
use Webqq::Client::Method::get_qq_from_uin;
use Webqq::Client::Method::get_single_long_nick;
use Webqq::Client::Method::_report;
use Webqq::Client::Method::get_dwz;
use Webqq::Client::Method::_get_offpic;
use Webqq::Client::Method::_cookie_proxy;
use Webqq::Client::Method::_relink;
use Webqq::Client::Method::_get_discuss_list_info;
use Webqq::Client::Method::_get_discuss_info;
use Webqq::Client::Method::change_state;
use Webqq::Client::Method::_send_discuss_message;
use Webqq::Client::Method::_get_friends_state;
use Webqq::Client::Method::_get_recent_info;

our $LAST_DISPATCH_TIME = undef;
our $SEND_INTERVAL      = 3;
our $CLIENT_COUNT       = 0;

sub new {
    my $class = shift;
    my %p = @_;

    console "该模块已经停止使用和开发，请换用 Mojo::Webqq 参考文档: https://metacpan.org/pod/Mojo::Webqq\n";
    exit;
    my $agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062';

    my ($second,$microsecond)=gettimeofday;
    my $send_msg_id = $second*1000+$microsecond;
    $send_msg_id=($send_msg_id-$send_msg_id%1000)/1000;
    $send_msg_id=($send_msg_id%10000)*10000;
    my $self = {
        cookie_jar  => HTTP::Cookies->new(hide_cookie2=>1), 
        qq_param        =>  {
            qq                      =>  undef,
            pwd                     =>  undef,    
            is_https                =>  defined $p{security}?$p{security}:0,
            is_need_img_verifycode  =>  0,
            img_verifycode_source  =>   'TTY',   #NONE|TTY|CALLBACK
            send_msg_id             =>  $send_msg_id,
            clientid                =>  53999199,
            psessionid              =>  'null',
            vfwebqq                 =>  undef,
            ptwebqq                 =>  undef,
            state                   =>  $p{state} || 'online', #online|away|busy|silent|hidden|offline,
            passwd_sig              =>  '',
            verifycode              =>  undef,
            verifysession           =>  undef,
            pt_verifysession        =>  undef,
            md5_salt                =>  undef,
            cap_cd                  =>  undef,
            isRandSalt              =>  0,
            ptvfsession             =>  undef,
            api_check_sig           =>  undef,
            g_pt_version            =>  undef,
            g_login_sig             =>  undef,
            g_style                 =>  5,
            g_mibao_css             =>  'm_webqq',
            g_daid                  =>  164,
            g_appid                 =>  1003903,
            g_pt_version            =>  10092,
            rc                      =>  1,
        },
        qq_database     =>  {
            user        =>  {},
            friends     =>  [],
            group_list  =>  [],
            discuss_list=>  [],
            recent      =>  [],
            group       =>  [],
            discuss     =>  [],
        },
        encrypt_method              => "perl", #perl|js
        is_first_login              =>  -1,
        is_stop                     =>  0,
        cache_for_uin_to_qq         => Webqq::Client::Cache->new,
        cache_for_qq_to_uin         => Webqq::Client::Cache->new,
        cache_for_number_to_uin     => Webqq::Client::Cache->new,
        cache_for_uin_to_number     => Webqq::Client::Cache->new,
        cache_for_group_sig         => Webqq::Client::Cache->new,
        cache_for_stranger          => Webqq::Client::Cache->new,
        cache_for_friend            => Webqq::Client::Cache->new,
        cache_for_single_long_nick  => Webqq::Client::Cache->new,
        cache_for_group             => Webqq::Client::Cache->new,
        cache_for_group_member      => Webqq::Client::Cache->new,
        cache_for_discuss           => Webqq::Client::Cache->new,
        cache_for_discuss_member    => Webqq::Client::Cache->new,
        cache_for_metacpan          => Webqq::Client::Cache->new,
        on_receive_message          =>  undef,
        on_receive_offpic           =>  undef,
        on_send_message             =>  undef,
        on_login                    =>  undef,
        on_new_friend               =>  undef,
        on_new_group                =>  undef,
        on_new_discuss              =>  undef,
        on_new_group_member         =>  undef,
        on_loss_group_member        =>  undef,
        on_new_discuss_member       =>  undef,
        on_loss_discuss_member      =>  undef,
        on_input_img_verifycode     =>  undef,
        on_friend_change_state      =>  undef,
        on_run                      =>  undef,
        on_ready                    =>  undef,
        receive_message_queue       =>  Webqq::Message::Queue->new,
        send_message_queue          =>  Webqq::Message::Queue->new,
        debug                       => $p{debug}, 
        login_state                 => "init",
        watchers                    => {},
        type                        => $p{type} || 'smartqq',#webqq or smartqq
        plugin_num                  =>  0,
        plugins                     =>  {},
        ua_retry_times              =>  5, 
        je                          =>  undef,
        poll_failure_count_max      =>  3,
        poll_failure_count          =>  0,
        client_version              =>  $VERSION,
        
    };
    $self->{ua} = LWP::UserAgent->new(
                cookie_jar      =>  $self->{cookie_jar},
                agent           =>  $agent,
                timeout         =>  300,
                ssl_opts        =>  {verify_hostname => 0},
    );
    $self->{asyn_ua} = Webqq::UserAgent->new(
                cookie_jar  =>  $self->{cookie_jar},
                agent       =>  $agent,
                request_timeout =>  300,
                inactivity_timeout  =>  300,
    );
    $self->{qq_param}{from_uin}  =$self->{qq_param}{qq};
    if($self->{debug}){
        $self->{ua}->add_handler(request_send => sub {
            my($request, $ua, $h) = @_;
            print $request->as_string;
            return;
        });

        $self->{ua}->add_handler(
            response_header => sub { my($response, $ua, $h) = @_;
            print $response->as_string;
            return;
        });
    }
    $self->{default_qq_param} =  dclone($self->{qq_param});
    $self->{default_qq_database} = dclone($self->{qq_database});

    bless $self,$class;
    $self->_prepare();
    return $self;
}
sub on_send_message :lvalue {
    my $self = shift;
    $self->{on_send_message};
}

sub on_receive_message :lvalue{
    my $self = shift;
    $self->{on_receive_message};
}

sub on_receive_offpic :lvalue{
    my $self = shift;
    $self->{on_receive_offpic};
}

sub on_login :lvalue {
    my $self = shift;
    $self->{on_login};
}
sub on_ready :lvalue {
    my $self = shift;
    $self->{on_ready};
}
sub on_run :lvalue {
    my $self = shift;
    $self->{on_run};
}
sub on_friend_change_state :lvalue {
    my $self = shift;
    $self->{on_friend_change_state};
}

sub on_new_friend :lvalue {
    my $self = shift;
    $self->{on_new_friend};
}

sub on_new_group :lvalue {
    my $self = shift;
    $self->{on_new_group};
}

sub on_new_group_member :lvalue {
    my $self = shift;
    $self->{on_new_group_member};
}

sub on_loss_group_member :lvalue {
    my $self = shift;
    $self->{on_loss_group_member};
}

sub on_new_discuss :lvalue {
    my $self = shift;
    $self->{on_new_discuss};
}
sub on_new_discuss_member :lvalue {
    my $self = shift;
    $self->{on_new_discuss_member};
}
sub on_loss_discuss_member :lvalue {
    my $self = shift;
    $self->{on_loss_discuss_member};
}

sub on_input_img_verifycode :lvalue {
    my $self = shift;
    $self->{on_input_img_verifycode};
}

sub login{
    my $self = shift;
    my %p = @_;
      
    if($self->{is_first_login} == -1){
        $self->{is_first_login} = 1;
    }     
    elsif($self->{is_first_login} == 1){
        $self->{is_first_login} = 0;
    }

    @{$self->{default_qq_param}}{qw(qq pwd)} = @p{qw(qq pwd)};
    @{$self->{qq_param}}{qw(qq pwd)} = @p{qw(qq pwd)};
    $self->{qq_param}{security} = $p{security} if defined $p{security};
    $self->{qq_param}{state} = $p{state} 
        if defined $p{state} and first {$_ eq $p{state}} qw(online away busy silent hidden offline);
    console "QQ账号: $self->{default_qq_param}{qq}\n";
    #my $is_big_endian = unpack( 'xc', pack( 's', 1 ) ); 
    $self->{qq_param}{qq} = $self->{default_qq_param}{qq};
    $self->{default_qq_param}{pwd} = lc $self->{default_qq_param}{pwd};
    $self->{qq_param}{pwd} = $self->{default_qq_param}{pwd} ;

    if(
           $self->_prepare_for_login()    
        && $self->_check_verify_code()     
        && $self->_get_img_verify_code()

    ){
        while(){
            my $ret = $self->_login1();
            if($ret == -1){
                $self->_get_img_verify_code();
                next;
            }
            elsif($ret == -2 and $self->{encrypt_method} ne "js"){#encrypt_method fail,change another
                console "登录失败，尝试更换加密算法计算方式，重新登录...\n";
                $self->{encrypt_method} = "js";
                $self->relogin();
                return;
            }
            elsif($ret == 1){
                   $self->_report()
                && $self->_check_sig() 
                && $self->_get_vfwebqq()
                && $self->_login2();
                last;
            }
            else{
                last;
            }
        }
    }

    #登录不成功，客户端退出运行
    if($self->{login_state} ne 'success'){
        console "登录失败，客户端退出（可能网络不稳定，请多尝试几次）\n";
        $self->stop();
    }
    else{
        console "登录成功\n";
    }
    #获取个人资料信息
    $self->update_user_info();  
    #显示欢迎信息
    $self->welcome();
    #更新好友信息
    $self->update_friends_info();
    #更新群信息
    $self->update_group_info();
    #更新讨论组信息
    $self->update_discuss_info();
    #更新最近联系人信息
    $self->update_recent_info();
    #使用Webqq::Qun添加更多好友和群属性信息
    $self->_update_extra_info();
    #执行on_login回调
    if(ref $self->{on_login} eq 'CODE'){
        eval{
            $self->{on_login}->();
        };
        console $@ . "\n" if $@;
    }
    return 1;
}
sub relogin{
    my $self = shift;   
    console "正在重新登录...\n";

    $self->logout();
    $self->{login_state} = 'relogin';

    #清空cookie
    $self->{cookie_jar} = HTTP::Cookies->new(hide_cookie2=>1);
    $self->{ua}->cookie_jar($self->{cookie_jar});
    $self->{asyn_ua}->{cookie_jar} = $self->{cookie_jar};
    #重新设置初始化参数
    $self->{cache_for_uin_to_qq}        = Webqq::Client::Cache->new;
    $self->{cache_for_qq_to_uin}        = Webqq::Client::Cache->new;
    $self->{cache_for_number_to_uin}    = Webqq::Client::Cache->new;
    $self->{cache_for_uin_to_number}    = Webqq::Client::Cache->new;
    $self->{cache_for_group_sig}        = Webqq::Client::Cache->new;
    $self->{cache_for_group}            = Webqq::Client::Cache->new;
    $self->{cache_for_group_member}     = Webqq::Client::Cache->new;
    $self->{cache_for_discuss}          = Webqq::Client::Cache->new;
    $self->{cache_for_discuss_member}   = Webqq::Client::Cache->new;
    $self->{cache_for_friend}           = Webqq::Client::Cache->new;
    $self->{cache_for_stranger}         = Webqq::Client::Cache->new;
    $self->{cache_for_single_long_nick} = Webqq::Client::Cache->new;

    $self->{qq_param} = dclone($self->{default_qq_param});
    $self->{qq_database} = dclone($self->{default_qq_database});
    $self->login(qq=>$self->{default_qq_param}{qq},pwd=>$self->{default_qq_param}{pwd});
}
sub _get_vfwebqq;
sub _prepare_for_login;
sub _check_verify_code;
sub _get_img_verify_code;
sub _check_sig;
sub _login1;
sub _login2;
sub _get_user_info;
sub _get_friend_info;
sub _get_group_info;
sub _get_group_list_info;
sub _get_user_friends;
sub _get_discuss_list_info;
sub _send_message;
sub _send_group_message;
sub _get_msg_tip;
sub change_state;
sub get_qq_from_uin;
sub get_single_long_nick;
sub _report;
sub _cookie_proxy;
sub _get_offpic;
sub _relink;
sub _get_discuss_list_info;
sub _get_discuss_info;
sub _get_friends_state;
sub _get_recent_info;

#接受一个消息，将它放到发送消息队列中
sub send_message{
    my $self = shift;
    if(@_ == 1 and ref $_[0] eq 'Webqq::Message::Message::Send'){
        my $msg = shift;
        $self->{send_message_queue}->put($msg); 
    }
    else{
        my $msg = $self->_create_msg(@_,type=>'message');    
        $self->{send_message_queue}->put($msg);    
    }
};
#接受一个群临时消息，将它放到发送消息队列中
sub send_sess_message{
    my $self = shift;
    if(@_ == 1 and ref $_[0] eq 'Webqq::Message::SessMessage::Send'){
        my $msg = shift;
        $self->{send_message_queue}->put($msg);
    }
    else{
        my $msg = $self->_create_msg(@_,type=>'sess_message');
        $self->{send_message_queue}->put($msg);
    }
}

sub send_discuss_message {
    my $self = shift;
    if(@_ == 1 and ref $_[0] eq 'Webqq::Message::DiscussMessage::Send'){
        my $msg = shift;
        $self->{send_message_queue}->put($msg);
    }   
    else{
        my $msg = $self->_create_msg(@_,type=>'discuss_message');
        $self->{send_message_queue}->put($msg);
    }
};

#接受一个群消息，将它放到发送消息队列中
sub send_group_message{
    my $self = shift;   
    if(@_ == 1 and ref $_[0] eq 'Webqq::Message::GroupMessage::Send'){
        my $msg = shift;
        $self->{send_message_queue}->put($msg);
    }
    else{
        my $msg = $self->_create_msg(@_,type=>'group_message');
        $self->{send_message_queue}->put($msg);
    }
};
sub welcome{
    my $self = shift;
    my $w = $self->{qq_database}{user};
    console "欢迎回来, $w->{nick}($w->{province})\n";
    console "个性签名: " . ($w->{single_long_nick}?$w->{single_long_nick}:"（无）") . "\n"
};
sub logout;
sub _prepare {
    my $self = shift;
    $self->_load_extra_accessor();
    #设置从接收消息队列中接收到消息后对应的处理函数
    $self->{receive_message_queue}->get(sub{
        my $msg = shift;
        return if $self->{is_stop}; 
        #触发on_new_friend/on_new_group_member回调
        if($msg->{type} eq 'message'){
            if(ref $self->{on_receive_offpic} eq 'CODE'){
                for(@{$msg->{raw_content}}){
                    if($_->{type} eq 'offpic'){
                        $self->_get_offpic($_->{file_path},$msg->{from_uin},$self->{on_receive_offpic});
                    }   
                }
            }
            $self->_detect_new_friend($msg->{from_uin});
        }
        elsif($msg->{type} eq 'group_message'){
            $self->_detect_new_group($msg->{group_code});
            $self->_detect_new_group_member($msg->{group_code},$msg->{send_uin});
        }
        elsif($msg->{type} eq 'discuss_message'){
            $self->_detect_new_discuss($msg->{did});
            $self->_detect_new_discuss_member($msg->{did},$msg->{send_uin});
        }
        elsif($msg->{type} eq 'buddies_status_change'){
            my $who = $self->update_friend_state_info($msg->{uin},$msg->{state},$msg->{client_type});
            if(defined $who and ref $self->{on_friend_change_state} eq 'CODE'){
                eval{
                    $self->{on_friend_change_state}->($who);
                };
                console "$@\n" if $@; 
            }
        }
        
        #接收队列中接收到消息后，调用相关的消息处理回调，如果未设置回调，消息将丢弃
        if(ref $self->{on_receive_message} eq 'CODE'){
            eval{
                $self->{on_receive_message}->($msg); 
            };
            console $@ . "\n" if $@;
        }
    });

    #设置从发送消息队列中提取到消息后对应的处理函数
    $self->{send_message_queue}->get(sub{
        my $msg = shift;
        return if $self->{is_stop}; 
        #消息的ttl值减少到0则丢弃消息
        if($msg->{ttl} <= 0){
            my $status = {is_success=>0,status=>"发送失败"};
            if(ref $msg->{cb} eq 'CODE'){
                $msg->{cb}->(
                    $msg,
                    $status->{is_success},
                    $status->{status},
                );
            }
            if(ref $self->{on_send_message} eq 'CODE'){
                $self->{on_send_message}->(
                    $msg,
                    $status->{is_success},
                    $status->{status},
                );
            }
        
            return;
        }
        $msg->{ttl}--;

        my $rand_watcher_id = rand();
        my $delay = 0;
        my $now = time;
        if(defined $LAST_DISPATCH_TIME){
            $delay = $now<$LAST_DISPATCH_TIME+$SEND_INTERVAL?
                        $LAST_DISPATCH_TIME+$SEND_INTERVAL-$now
                    :   0;
        }
        $self->{watchers}{$rand_watcher_id} = AE::timer $delay,0,sub{
            delete $self->{watchers}{$rand_watcher_id};
            $msg->{msg_time} = time;
                $msg->{type} eq 'message'           ?   $self->_send_message($msg)
            :   $msg->{type} eq 'group_message'     ?   $self->_send_group_message($msg)
            :   $msg->{type} eq 'sess_message'      ?   $self->_send_sess_message($msg)
            :   $msg->{type} eq 'discuss_message'   ?   $self->_send_discuss_message($msg)
            :                                           undef
            ;
        };
        $LAST_DISPATCH_TIME = $now+$delay;
        
    });

};

sub ready{
    my $self = shift;

    $self->{watchers}{rand()} = AE::timer 600,600,sub{
        $self->update_group_info();
        $self->_update_extra_info(type=>"group");
    };

    $self->{watchers}{rand()} = AE::timer 600+60,600,sub{
        $self->update_discuss_info();
    };

    console "开始接收消息\n";
    $self->_recv_message();

    if(ref $self->{on_ready} eq 'CODE'){
        eval{
            $self->{on_ready}->();
        };
        console "$@\n" if $@;
    }
    $CLIENT_COUNT++;
}

sub stop {
    my $self = shift;
    $self->{is_stop} = 1;
    if($CLIENT_COUNT > 1){
        $CLIENT_COUNT--;
        $self->{watchers}{rand()} = AE::timer 600,0,sub{
            undef %$self; 
        };
    }
    else{
        CORE::exit;         
    }
}

sub exit {
    my $self = shift;
    CORE::exit();
}

sub EXIT {
    CORE::exit();
}

sub run{
    my $self = shift;
    $self->ready();
    if(ref $self->{on_run} eq 'CODE'){
        eval{
            $self->{on_run}->();
        };
        console "$@\n" if $@;
    }
    console "客户端运行中...\n";
    $self->{cv} = AE::cv;
    $self->{cv}->recv
} 

sub RUN{
    console "启动全局事件循环...\n";
    AE::cv->recv;
}
sub search_cookie{
    my($self,$cookie) = @_;
    my $result = undef;
    $self->{cookie_jar}->scan(sub{
        my($version,$key,$val,$path,$domain,$port,$path_spec,$secure,$expires,$discard,$rest) =@_;
        if($key eq $cookie){
            $result = $val ;
            return;
        }
    });
    return $result;
}

#根据uin进行查询，返回一个friend的hash引用
#这个hash引用的结构是：
#{
#    flag        #标志，作用未知
#    face        #表情
#    uin         #uin
#    categories  #所属分组
#    nick        #昵称
#    markname    #备注名称
#    is_vip      #是否是vip会员
#    vip_level   #vip等级
#}
sub search_friend {
    my ($self,$uin) = @_;
    my $cache_data = $self->{cache_for_friend}->retrieve($uin);
    return $cache_data if defined $cache_data; 
   
    my $f = first {$_->{uin} eq $uin} @{ $self->{qq_database}{friends} };
    if(defined $f){
        my $f_clone = dclone($f);
        $self->{cache_for_friend}->store($uin,$f_clone);
        return $f_clone;
    }
    return undef;
}

#根据群的gcode和群成员的uin进行查询，返回群成员相关信息
#返回结果是一个群成员的hash引用
#{
#    nick        #昵称
#    province    #省份
#    gender      #性别
#    uin         #uin
#    country     #国家
#    city        #城市
#}
sub search_member_in_group{
    my ($self,$gcode,$member_uin) = @_;
    my $cache_data =  $self->{cache_for_group_member}->retrieve("$gcode|$member_uin");
    return $cache_data if defined $cache_data;
    #在现有的群中查找
    for my $g (@{$self->{qq_database}{group}}){ 
        #如果群是存在的
        if($g->{ginfo}{code} eq $gcode){    
            #在群中查找指定的成员
            #如果群数据库中包含群成员数据
            if(exists $g->{minfo} and ref $g->{minfo} eq 'ARRAY'){
                my $m = first {$_->{uin} eq $member_uin} @{$g->{minfo} };
                if(defined $m){
                    my $m_clone = dclone($m);
                    $self->{cache_for_group_member}->store("$gcode|$member_uin",$m_clone);
                    return $m_clone;
                }
                return undef;
                
            }
            #群数据中只有ginfo，没有minfo
            else{
                #尝试重新更新一下群信息，希望可以拿到minfo
                my $group_info = $self->_get_group_info($g->{ginfo}{code});         
                if(defined $group_info and ref $group_info->{minfo} eq 'ARRAY'){
                    #终于拿到minfo了 赶紧存起来 以备下次使用
                    $self->update_group_info($group_info);
                    #在minfo里找群成员
                    my $m = first {$_->{uin} eq $member_uin} @{$group_info->{minfo}};
                    if(defined $m){
                        my $m_clone = dclone($m);
                        $self->{cache_for_group_member}->store("$gcode|$member_uin",$m_clone);
                        return $m_clone;
                    }
                    #靠 还是没找到
                    return undef;
                }
                #很可惜，还是拿不到minfo
                else{
                    return undef;
                }
            }
        }
    }
    #遍历所有的群也找不到，返回undef
    return undef;
}

sub search_member_in_discuss {
    my ($self,$did,$member_uin) = @_;
    my $cache_data =  $self->{cache_for_discuss_member}->retrieve("$did|$member_uin");
    return $cache_data if defined $cache_data;
    #在现有的讨论组中查找
    for my $d (@{$self->{qq_database}{discuss}}){ 
        #如果讨论组是存在的
        if($d->{dinfo}{did} eq $did){    
            #在讨论组中查找指定的成员
            #如果讨论组数据库中包含讨论组成员数据
            if(exists $d->{minfo} and ref $d->{minfo} eq 'ARRAY'){
                my $m = first {$_->{uin} eq $member_uin} @{$d->{minfo} };
                if(defined $m){
                    my $m_clone = dclone($m);
                    $self->{cache_for_discuss_member}->store("$did|$member_uin",$m_clone);
                    return $m_clone;
                }
                return undef;
                
            }
            #群数据中只有dinfo，没有minfo
            else{
                #尝试重新更新一下讨论组信息，希望可以拿到minfo
                my $discuss_info = $self->_get_discuss_info($did);         
                if(defined $discuss_info and ref $discuss_info->{minfo} eq 'ARRAY'){
                    #终于拿到minfo了 赶紧存起来 以备下次使用
                    $self->update_discuss_info($discuss_info);
                    #在minfo里找讨论组成员
                    my $m = first {$_->{uin} eq $member_uin} @{$discuss_info->{minfo}};
                    if(defined $m){
                        my $m_clone = dclone($m);
                        $self->{cache_for_discuss_member}->store("$did|$member_uin",$m_clone);
                        return $m_clone;
                    }   
                    #靠 还是没找到
                    return undef;
                }
                #很可惜，还是拿不到minfo
                else{
                    return undef;
                }
            }
        }
    }
    #遍历所有的群也找不到，返回undef
    return undef;
}

sub search_discuss{
    my $self = shift;
    my $did = shift;
    my $cache_data = $self->{cache_for_discuss}->retrieve($did);
    return $cache_data if defined $cache_data;
    my $d = first {$_->{dinfo}{did} eq $did} @{ $self->{qq_database}{discuss} };
    if(defined $d){
        my $clone = dclone($d->{dinfo});
        $self->{cache_for_discuss}->store($did,$clone);
        return $clone;
    }
    return undef;
}

sub search_stranger{
    my($self,$tuin) = @_;
    my $cache_data =  $self->{cache_for_stranger}->retrieve($tuin);
    return $cache_data if defined $cache_data;
    for my $g ( @{$self->{qq_database}{group}} ){
        for my $m (@{ $g->{minfo}  }){
            if($m->{uin} eq $tuin){
                my $m_clone = dclone($m);
                $self->{cache_for_stranger}->store($tuin,$m_clone);
                return $m_clone;
            }
        }
    } 
    
    $self->_get_stranger_info($tuin) or undef;
}

sub search_group{
    my($self,$gcode) = @_;
    my $cache_data = $self->{cache_for_group}->retrieve($gcode);
    return $cache_data if defined $cache_data;

    my $g = first {$_->{ginfo}{code} eq $gcode} @{ $self->{qq_database}{group} };
    if(defined $g){
        my $clone = dclone($g->{ginfo});
        $self->{cache_for_group}->store($gcode,$clone);
        return $clone;
    }
    return undef ;
}

sub update_user_info{
    my $self = shift;   
    console "更新个人信息...\n";
    my $user_info = $self->_get_user_info();
    if(defined $user_info){
        for my $key (keys %{ $user_info }){
            if($key eq 'birthday'){
                $self->{qq_database}{user}{birthday} = 
                    encode("utf8", join("-",@{ $user_info->{birthday}}{qw(year month day)}  )  );
            }
            else{
                $self->{qq_database}{user}{$key} = encode("utf8",$user_info->{$key});
            }
        }
        my $single_long_nick = $self->get_single_long_nick($self->{qq_param}{qq});
        if(defined $single_long_nick){
            $self->{qq_database}{user}{single_long_nick} = $single_long_nick;
        }   
        $self->{qq_database}{user}{qq} = $self->{qq_param}{qq};
    }
    else{console "更新个人信息失败\n";}
}
sub update_friends_info{
    my $self=shift;
    my $friend = shift;
    if(defined $friend){
        for(@{ $self->{qq_database}{friends} }){
            if($_->{uin} eq $friend->{uin}){
                $_ = $friend;
                return;
            }
        }
        push @{ $self->{qq_database}{friends} },$friend;
        return;
    }
    console "更新好友信息...\n";
    my $friends_info = $self->_get_user_friends();
    if(defined $friends_info){
        $self->{qq_database}{friends} = $friends_info;
    }
    else{console "更新好友信息失败\n";}
    
}

sub update_discuss_info {
    my $self = shift;
    my $discuss = shift;
    my $is_init = 1 if @{$self->{qq_database}{discuss}}  == 0;
    if(defined $discuss){
        for( @{$self->{qq_database}{discuss}} ){
            if($_->{dinfo}{did} eq $discuss->{dinfo}{did} ){
                $self->_detect_loss_discuss_member($_,$discuss);
                $self->_detect_new_discuss_member2($_,$discuss);
                $_ = $discuss;
                return;
            }
        } 
        push @{$self->{qq_database}{discuss}},$discuss;
        if(!$is_init and ref $self->{on_new_discuss} eq 'CODE'){
            eval {
                $self->{on_new_discuss}->(dclone($discuss));
            };
            console $@ . "\n" if $@;
        }
        return;        
    }
    $self->update_discuss_list_info();
    for my $dl (@{ $self->{qq_database}{discuss_list} }){
        console "更新[ $dl->{name} ]讨论组信息...\n";
        my $discuss_info = $self->_get_discuss_info($dl->{did});
        if(defined $discuss_info){
            if(ref $discuss_info->{minfo} ne 'ARRAY'){
                console "更新[ $dl->{name} ]讨论组成功，但暂时没有获取到讨论组成员信息...\n";
            } 
            my $flag = 0;
            for( @{$self->{qq_database}{discuss}} ){
                if($_->{dinfo}{did} eq $discuss_info->{dinfo}{did} ){
                    $self->_detect_loss_discuss_member($_,$discuss_info);
                    $self->_detect_new_discuss_member2($_,$discuss_info);
                    $_ = $discuss_info if ref $discuss_info->{minfo} eq 'ARRAY';
                    $flag = 1;
                    last;
                }
            }
            if($flag == 0){
                push @{ $self->{qq_database}{discuss} }, $discuss_info;
                if( !$is_init and ref $self->{on_new_discuss} eq 'CODE'){
                    eval {
                        $self->{on_new_discuss}->(dclone($discuss_info));
                    };
                    console $@ . "\n" if $@;
                }
            } 
            
        }
        else{console "更新[ $dl->{name} ]讨论组信息失败\n";}
    }
}

sub update_discuss_list_info {
    my $self = shift;
    my $discuss  = shift;
    if(defined $discuss ){
        for(@{ $self->{qq_database}{discuss_list} }){
            if($_->{did} eq $discuss->{did}){
                $_ = $discuss;
                return;        
            }
        }
        push @{ $self->{qq_database}{discuss_list} }, $discuss;
        return;
    }
    console "更新讨论组列表信息...\n";
    my $discuss_list_info = $self->_get_discuss_list_info();
    if(defined $discuss_list_info){
        $self->{qq_database}{discuss_list} =  $discuss_list_info;
    }
    else{console "更新讨论组列表信息失败\n";}
    
}

sub update_group_info{
    my $self = shift;
    my $group = shift;
    my $is_init = 1 if @{$self->{qq_database}{group}}  == 0;
    if(defined $group){
        for( @{$self->{qq_database}{group}} ){
            if($_->{ginfo}{code} eq $group->{ginfo}{code} ){
                $self->_detect_loss_group_member($_,$group);
                $self->_detect_new_group_member2($_,$group);
                $_ = $group;
                return;
            }
        } 
        push @{$self->{qq_database}{group}},$group;
        if(!$is_init and ref $self->{on_new_group} eq 'CODE'){
            eval {
                $self->{on_new_group}->(dclone($group));
            };
            console $@ . "\n" if $@;
        }
        return;
    }
    $self->update_group_list_info();
    for my $gl (@{ $self->{qq_database}{group_list} }){
        console "更新[ $gl->{name} ]群信息...\n";
        my $group_info = $self->_get_group_info($gl->{code});
        if(defined $group_info){
            if(ref $group_info->{minfo} ne 'ARRAY'){
                console "更新[ $gl->{name} ]成功，但暂时没有获取到群成员信息...\n";
            }
            my $flag = 0;
            for( @{$self->{qq_database}{group}} ){
                if($_->{ginfo}{code} eq $group_info->{ginfo}{code} ){
                    $self->_detect_loss_group_member($_,$group_info);
                    $self->_detect_new_group_member2($_,$group_info);
                    $_ = $group_info if ref $group_info->{minfo} eq 'ARRAY';
                    $flag = 1;
                    last;
                }
            }
            if($flag == 0){
                push @{ $self->{qq_database}{group} }, $group_info;
                if( !$is_init and ref $self->{on_new_group} eq 'CODE'){
                    eval {
                        $self->{on_new_group}->(dclone($group_info));
                    };
                    console $@ . "\n" if $@;
                }
            }
        }
        else{console "更新[ $gl->{name} ]群信息失败\n";}
    }
}
sub update_recent_info {
    my $self = shift;
    my $recent = $self->_get_recent_info();
    $self->{qq_database}{recent} = $recent if defined $recent;
}
sub update_group_list_info{
    my $self = shift;
    my $group = shift;
    if(defined $group ){
        for(@{ $self->{qq_database}{group_list} }){
            if($_->{code} eq $group->{code}){
                $_ = $group;
                return;        
            }
        }
        push @{ $self->{qq_database}{group_list} }, $group;
        return;
    }
    console "更新群列表信息...\n";
    my $group_list_info = $self->_get_group_list_info();
    if(defined $group_list_info){
        $self->{qq_database}{group_list} =  $group_list_info->{gnamelist}; 
        my %gmarklist;
        for(@{ $group_list_info->{gmarklist} }){
            $gmarklist{$_->{uin}} = $_->{markname};
        }
        for(@{ $self->{qq_database}{group_list} }){
            $_->{markname} = $gmarklist{$_->{gid}};
            $_->{name} = encode("utf8",$_->{name});
        }
    }
    #else{console "更新群列表信息失败\n";}    
}

sub update_friend_state_info{
    my $self = shift;
    my ($uin,$state,$client_type) = @_;
    my $f = first {$_->{uin} eq $uin} @{$self->{qq_database}{friends}};
    if(defined $f){
        $f->{state} = $state;
        $f->{client_type} = $client_type;
        return dclone($f);
    }
    return undef;
}

sub get_group_code_from_gid {
    my $self = shift;
    my $gid = shift;
    my $group = first {$_->{gid} eq $gid} @{ $self->{qq_database}{group_list} };
    return defined $group?$group->{code}:undef;
}

sub _detect_new_friend{
    my $self = shift;
    my $uin  = shift;
    return if defined $self->search_friend($uin);
    #新增好友
    my $friend = $self->_get_friend_info($uin);
    if(defined $friend){
        $self->{cache_for_friend}->store($uin,$friend);
        push @{ $self->{qq_database}{friends} },$friend;
        if(ref $self->{on_new_friend} eq 'CODE'){
            eval{
                $self->{on_new_friend}->($friend); 
            };
            console $@ . "\n" if  $@;
        }
        return ;
    }
    #新增陌生好友(你是对方好友，但对方还不是你好友)
    else{
        my $default_friend = {
            uin =>  $uin,
            categories  => "陌生人",
            nick        => undef,
        };
        push @{ $self->{qq_database}{friends} },$default_friend;
        return ;
    }
    
}

sub _detect_new_group{
    my $self = shift;
    my $gcode = shift;
    return if defined $self->search_group($gcode);
    my $group_info = $self->_get_group_info($gcode);
    if(defined $group_info ){
        $self->update_group_list_info({
            name    =>  $group_info->{ginfo}{name},
            gid     =>  $group_info->{ginfo}{gid},
            code    =>  $group_info->{ginfo}{code},
        });
        push @{$self->{qq_database}{group}},$group_info;
        if(ref $self->{on_new_group} eq 'CODE'){
            eval{
                $self->{on_new_group}->(dclone($group_info));
            };  
            console $@ . "\n" if  $@;
        }
        return ;    
    }
    else{
        return ;
    }
}

sub _detect_new_group_member{
    my $self = shift;
    my ($gcode,$member_uin) = @_;
    my $default_member = {
        nick     =>  undef,
        province =>  undef,
        gender   =>  undef,
        uin      =>  $member_uin,
        country  =>  undef,
        city     =>  undef,
        card     =>  undef,
    };

    my $group = first {$_->{ginfo}{code} eq $gcode} @{$self->{qq_database}{group}};
    #群至少得存在
    return unless defined $group;
    #如果包含群成员信息
    if(exists $group->{minfo}){
        return if defined $self->search_member_in_group($gcode,$member_uin);
        #查不到成员信息，说明是新增的成员，重新更新一次群信息
        my $new_group_member = {};
        my $group_info = $self->_get_group_info($gcode);
        #更新群信息成功
        if(defined $group_info and ref $group_info->{minfo} eq 'ARRAY'){
            #再次查找新增的成员
            my $m = first {$_->{uin} eq $member_uin} @{$group_info->{minfo}};
            if(defined $m){
                $self->{cache_for_group_member}->store("$gcode|$member_uin",dclone($m));
                $new_group_member = $m;
            }
            else{
                $new_group_member = $default_member;
            }
        }
        #群成员信息更新失败
        else{
            $new_group_member = $default_member;    
        }

        push @{$group->{minfo}},$new_group_member;
        if(ref $self->{on_new_group_member} eq 'CODE'){
            eval{
                $self->{on_new_group_member}->(dclone($group),dclone($new_group_member));
            };
            console $@ . "\n" if $@;
        }
        return;
    }
    else{
        return;
    }
}

sub _detect_new_group_member2 {
    my $self = shift;
    my($group_old,$group_new) = @_;
    return if ref $group_old->{minfo} ne 'ARRAY';
    return if ref $group_new->{minfo} ne 'ARRAY';
    my %e = map {$_->{uin} => undef} @{$group_old->{minfo}};
    for my $new (@{$group_new->{minfo}}){
        #旧的没有，新的有，说明是新增群成员
        unless(exists $e{$new->{uin}}){
            if(ref $self->{on_new_group_member} eq 'CODE'){
                eval{
                    $self->{on_new_group_member}->(dclone($group_new),dclone($new));
                };
                console $@ . "\n" if $@;
            };
        }
    }
    
}

sub _detect_loss_group_member {
    my $self = shift;
    my($group_old,$group_new) = @_;
    return if ref $group_old->{minfo} ne 'ARRAY';
    return if ref $group_new->{minfo} ne 'ARRAY';
    my %e = map {$_->{uin} => undef} @{$group_new->{minfo}};
    for my $old (@{$group_old->{minfo}}){
        #旧的有，新的没有，说明是已经退群的成员
        unless(exists $e{$old->{uin}}){
            if(ref $self->{on_loss_group_member} eq 'CODE'){
                eval{
                    $self->{on_loss_group_member}->(dclone($group_old),dclone($old));
                };
                console $@ . "\n" if $@;
            };
        }
        $self->{cache_for_group_member}->delete($group_old->{ginfo}{code} . "|" . $old->{uin});
    }

}

sub _detect_new_discuss{
    my $self = shift;
    my $did = shift;
    return if defined $self->search_discuss($did);
    my $discuss_info = $self->_get_discuss_info($did);
    if(defined $discuss_info ){
        $self->update_discuss_list_info({
            name    =>  $discuss_info->{dinfo}{name},
            did     =>  $discuss_info->{dinfo}{did},
        });
        push @{$self->{qq_database}{discuss}},$discuss_info;
        if(ref $self->{on_new_discuss} eq 'CODE'){
            eval{
                $self->{on_new_discuss}->(dclone($discuss_info));
            };  
            console $@ . "\n" if  $@;
        }
        return ;    
    }
    else{
        return ;
    }
}
sub _detect_loss_discuss_member {
    my $self = shift;
    my($discuss_old,$discuss_new) = @_;
    return if ref $discuss_old->{minfo} ne 'ARRAY';
    return if ref $discuss_new->{minfo} ne 'ARRAY';
    my %e = map {$_->{uin} => undef} @{$discuss_new->{minfo}};
    for my $old (@{$discuss_old->{minfo}}){
        #旧的有，新的没有，说明是已经退群的成员
        unless(exists $e{$old->{uin}}){
            if(ref $self->{on_loss_discuss_member} eq 'CODE'){
                eval{
                    $self->{on_loss_discuss_member}->(dclone($discuss_old),dclone($old));
                };
                console $@ . "\n" if $@;
            };
        }
        $self->{cache_for_discuss_member}->delete($discuss_old->{dinfo}{did} . "|" . $old->{uin});
    }    
}
sub _detect_new_discuss_member {
    my $self = shift;
    my ($did,$member_uin) = @_;
    my $default_member = {
        nick     =>  undef,
        uin      =>  $member_uin,
    };

    my $discuss = first {$_->{dinfo}{did} eq $did} @{$self->{qq_database}{discuss} };
    #群至少得存在
    return unless defined $discuss;
    #如果包含成员信息
    if(exists $discuss->{minfo}){
        return if defined $self->search_member_in_discuss($did,$member_uin);
        #查不到成员信息，说明是新增的成员，重新更新一次群信息
        my $new_discuss_member = {};
        my $discuss_info = $self->_get_discuss_info($did);
        #更新群信息成功
        if(defined $discuss_info and ref $discuss_info->{minfo} eq 'ARRAY'){
            #再次查找新增的成员
            my $m = first {$_->{uin} eq $member_uin} @{$discuss_info->{minfo}};
            if(defined $m){
                $self->{cache_for_discuss_member}->store("$did|$member_uin",dclone($m));
                $new_discuss_member = $m;
            } 
            else{
                #仍然找不到信息，只好直接返回空了
                $new_discuss_member = $default_member;
            }
        }
        #成员信息更新失败
        else{
            $new_discuss_member = $default_member;    
        }

        push @{$discuss->{minfo}},$new_discuss_member;
        if(ref $self->{on_new_discuss_member} eq 'CODE'){
            eval{
                $self->{on_new_discuss_member}->(dclone($discuss),dclone($new_discuss_member));
            };
            console $@ . "\n" if $@;
        }
        return;
    }
    else{
        return;
    }
}
sub _detect_new_discuss_member2 {
    my $self = shift;
    my($discuss_old,$discuss_new) = @_;
    return if ref $discuss_old->{minfo} ne 'ARRAY';
    return if ref $discuss_new->{minfo} ne 'ARRAY';
    my %e = map {$_->{uin} => undef} @{$discuss_old->{minfo}};
    for my $new (@{$discuss_new->{minfo}}){
        #旧的没有，新的有，说明是新增群成员
        unless(exists $e{$new->{uin}}){
            if(ref $self->{on_new_discuss_member} eq 'CODE'){
                eval{
                    $self->{on_new_discuss_member}->(dclone($discuss_new),dclone($new));
                };
                console $@ . "\n" if $@;
            };
        }
    }
}

sub _update_extra_info{
    my $self = shift;
    my %p = @_;
    $p{type} = "all" unless defined  $p{type};
    eval{require Webqq::Qun;};
    if($@){
        console "Webqq::Qun模块未找到，已忽略相关功能\n" if $self->{debug};
        return;
    }
    eval{
        my $qun = Webqq::Qun->new(qq=>$self->{qq_param}{qq},pwd=>$self->{qq_param}{pwd},debug=>$self->{debug}); 
        $qun->authorize() or die "authorize fail\n";
        if($p{type} eq "all"){
            $qun->get_friend();
            $qun->get_qun();
            $self->{extra_qq_database} = {
                friends  =>  $qun->{friend},
                group   =>  $qun->{data},
            };
            $self->_update_extra_friend_info();
            $self->_update_extra_group_info();
        }
        elsif($p{type} eq "friend"){
            $qun->get_friend();
            $self->{extra_qq_database} = {
                friends =>  $qun->{friend},
            };
            $self->_update_extra_friend_info();
        }
        elsif($p{type} eq "group"){
            $qun->get_qun();
            $self->{extra_qq_database} = {
                group   =>  $qun->{data},
            };
            $self->_update_extra_group_info();
        }
    };
    if($@){
        console "Webqq::Qun模块执行失败：$@\n" if $self->{debug};
        return;
    }
    return 1;
    
}
sub _update_extra_friend_info{
    my $self = shift;
    return unless defined $self->{extra_qq_database}{friends};
    my %map;
    my %map_ignore;
    for (@{$self->{extra_qq_database}{friends}}){
        next if exists $map_ignore{$_->{nick}};
        $map_ignore{$_->{nick}} = 1;
        $map{$_->{nick}} = $_->{qq} ;
    }      
    for(@{$self->{qq_database}{friends}}){
        $_->{qq} = $map{$_->{nick}} if exists $map{$_->{nick}};
        $self->{cache_for_qq_to_uin}->store($_->{qq},$_->{uin});
        $self->{cache_for_uin_to_qq}->store($_->{uin},$_->{qq});
    }
    return 1;
}
sub _update_extra_group_info{
    my $self = shift;
    return unless defined $self->{extra_qq_database}{group};
    my %map_group;
    my %map_group_ignore;
    my %map_member;
    my %map_member_ignore;
    my @members;
    for (@{$self->{extra_qq_database}{group}}){
        next if exists $map_group_ignore{$_->{qun_name}};
        $map_group_ignore{$_->{qun_name}} = 1;
        
        push @members,@{$_->{members}} ;
        $map_group{$_->{qun_name}}{number} = $_->{qun_number};
        $map_group{$_->{qun_name}}{type} = $_->{qun_type};
    }
    for(@members){
        next if exists $map_member_ignore{$_->{qun_name},$_->{nick}};
        $map_member_ignore{$_->{qun_name},$_->{nick}} = 1;
        
        $map_member{$_->{qun_name},$_->{nick}}{_count}++;
        $map_member{$_->{qun_name},$_->{nick}}{qq}                 = $_->{qq};
        $map_member{$_->{qun_name},$_->{nick}}{qage}               = $_->{qage};
        $map_member{$_->{qun_name},$_->{nick}}{join_time}          = $_->{join_time};
        $map_member{$_->{qun_name},$_->{nick}}{last_speak_time}    = $_->{last_speak_time};
        $map_member{$_->{qun_name},$_->{nick}}{level}              = $_->{level};
        $map_member{$_->{qun_name},$_->{nick}}{role}               = $_->{role};
        $map_member{$_->{qun_name},$_->{nick}}{bad_record}         = $_->{bad_record};
    }
    for(@{$self->{qq_database}{group_list}}){
        if(exists $map_group{$_->{name}}){
            $_->{number} = $map_group{$_->{name}}{number};
            $_->{type} = $map_group{$_->{name}}{type} ; 
            $self->{cache_for_number_to_uin}->store($_->{number},$_->{gid});
            $self->{cache_for_uin_to_number}->store($_->{gid},$_->{number});
        }
    }
    for(@{$self->{qq_database}{group}}){
        $_->{ginfo}{number} = $map_group{$_->{ginfo}{name}}{number} if exists $map_group{$_->{ginfo}{name}}{number};
        $_->{ginfo}{type} = $map_group{$_->{ginfo}{name}}{type} if exists $map_group{$_->{ginfo}{name}}{type};
        next unless ref $_->{minfo} eq 'ARRAY';
        for my $m (@{$_->{minfo}}){
            if(exists $map_member{$_->{ginfo}{name},$m->{nick}}){
                $m->{qq}                = $map_member{$_->{ginfo}{name},$m->{nick}}{qq} ;
                $m->{qage}              = $map_member{$_->{ginfo}{name},$m->{nick}}{qage} ;
                $m->{join_time}         = $map_member{$_->{ginfo}{name},$m->{nick}}{join_time} ;
                $m->{last_speak_time}   = $map_member{$_->{ginfo}{name},$m->{nick}}{last_speak_time} ;
                $m->{level}             = $map_member{$_->{ginfo}{name},$m->{nick}}{level} ;
                $m->{role}              = $map_member{$_->{ginfo}{name},$m->{nick}}{role} ;
                $m->{bad_record}        = $map_member{$_->{ginfo}{name},$m->{nick}}{bad_record} ;
                $self->{cache_for_uin_to_qq}->store($m->{uin},$m->{qq});
                $self->{cache_for_qq_to_uin}->store($m->{qq},$m->{uin});
            }
        } 
    }
}

sub get_uin_from_qq{
    my $self = shift;
    my $qq   = shift;   
    return $self->{cache_for_qq_to_uin}->retrieve($qq);
}

sub get_uin_from_number {
    my $self = shift;
    my $number = shift;
    return $self->{cache_for_number_to_uin}->retrieve($number);    
}
sub get_number_from_uin {
    my $self = shift;
    my $uin = shift;
    return $self->{cache_for_uin_to_number}->retrieve($uin);
}
1;
__END__

