package Webqq::Client;
use Storable qw(dclone);
use base qw(Webqq::Message);
use Webqq::Client::Cache;
use Webqq::Message::Queue;

#定义模块的版本号
our $VERSION = v1.6;

use LWP::UserAgent;#同步HTTP请求客户端
use AnyEvent::UserAgent;#异步HTTP请求客户端

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
use Webqq::Client::Method::_get_group_list_info;
use Webqq::Client::Method::_get_friends_list_info;
use Webqq::Client::Method::_get_user_info;
use Webqq::Client::Method::_send_message;
use Webqq::Client::Method::_send_group_message;
use Webqq::Client::Method::logout;
use Webqq::Client::Method::get_qq_from_uin;
use Webqq::Client::Method::_get_msg_tip;


sub new {
    my $class = shift;
    my %p = @_;
    my $cookie_jar  = HTTP::Cookies->new(hide_cookie2=>1);
    my $agent       = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.103';
    my $request_timeout = 300; 
    $self = {
        ua      => LWP::UserAgent->new(
                cookie_jar  =>  $cookie_jar,
                agent       =>  $agent,
                timeout     =>  $request_timeout
        ),
        asyn_ua => AnyEvent::UserAgent->new(
                cookie_jar  =>  $cookie_jar,
                agent       =>  $agent,
                request_timeout =>  0,
                inactivity_timeout  =>  0,
        ),
        cookie_jar  => $cookie_jar, 
        qq_param        =>  {
            qq                      =>  undef,
            pwd                     =>  undef,    
            is_need_img_verifycode  =>  0,
            send_msg_id             =>  11111111+int(rand(99999999)),
            clientid                =>  11111111+int(rand(99999999)),
            psessionid              =>  'null',
            vfwebqq                 =>  undef,
            ptwebqq                 =>  undef,
            status                  =>  'online',
            passwd_sig              =>  '',
            verifycode              =>  undef,
            verifysession           =>  undef,
            md5_salt                =>  undef,
            cap_cd                  =>  undef,
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
            group       =>  [],
            discuss     =>  [],
        },
        cache_for_uin_to_qq => Webqq::Client::Cache->new,
        on_receive_message  =>  undef,
        on_send_message     =>  undef,
        receive_message_queue    =>  Webqq::Message::Queue->new,
        send_message_queue       =>  Webqq::Message::Queue->new,
        debug => $p{debug},
        
    };
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

    return bless $self;
}
sub on_send_message :lvalue {
    my $self = shift;
    $self->{on_send_message};
}

sub on_receive_message :lvalue{
    my $self = shift;
    $self->{on_receive_message};
}

sub login{
    my $self = shift;
    my %p = @_;
    @{$self->{qq_param}}{qw(qq pwd)} = @p{qw(qq pwd)};
    console "QQ账号: $self->{qq_param}{qq} 密码: $self->{qq_param}{pwd}\n";
    #my $is_big_endian = unpack( 'xc', pack( 's', 1 ) ); 
    $self->{qq_param}{pwd} = pack "H*",lc $self->{qq_param}{pwd};
    return  
           $self->_prepare_for_login()    
        && $self->_check_verify_code()     
        && $self->_get_img_verify_code()   
        && $self->_login1()                
        && $self->_check_sig()             
        && $self->_login2();
}
sub _prepare_for_login;
sub _check_verify_code;
sub _get_img_verify_code;
sub _check_sig;
sub _login1;
sub _login2;
sub _get_user_info;
sub _get_group_info;
sub _get_group_list_info;
sub _get_friends_info;
sub _get_friends_list_info;
sub _get_discuss_list_info;
sub _send_message;
sub _send_group_message;
sub _get_msg_tip;
sub change_status;
sub get_qq_from_uin;

#接受一个消息，将它放到发送消息队列中
sub send_message{
    my $self = shift;
    my $msg = shift;
    $self->{send_message_queue}->put($msg);
};

#接受一个群消息，将它放到发送消息队列中
sub send_group_message{
    my $self = shift;
    my $msg = shift;
    $self->{send_message_queue}->put($msg);
};
sub welcome{
    my $self = shift;
    my $w = $self->{qq_database}{user};
    console "欢迎回来, $w->{nick}($w->{province})\n";
    console "个人说明: " . ($w->{personal}?$w->{personal}:"（无）") . "\n"
    #个人信息存储在$self->{qq_database}{user}中
    #    face
    #    birthday
    #    occupation
    #    phone
    #    allow
    #    college
    #    uin
    #    constel
    #    blood
    #    homepage
    #    stat
    #    vip_info
    #    country
    #    city
    #    personal
    #    nick
    #    shengxiao
    #    email
    #    client_type
    #    province
    #    gender
    #    mobile
 
};
sub logout;
sub run {
    my $self = shift;
    #登录不成功，客户端退出运行
    if($self->{qq_param}{login_state} ne 'success'){
        console "登录失败\n";
        return ;
    }
    #获取个人资料信息
    $self->_get_user_info() && $self->welcome();
    #获取群列表信息
    $self->_get_group_list_info();
    #获取好友信息
    $self->_get_friends_list_info();
    #获取群列表中每个群的成员信息
    console "获取群成员信息...\n";
    for(@{ $self->{qq_database}{group_list} }){
        $self->_get_group_info($_->{code});
    }
    
    #设置从接收消息队列中接收到消息后对应的处理函数
    $self->{receive_message_queue}->get(sub{
        my $msg = shift;
        #接收队列中接收到消息后，调用相关的消息处理回调，如果未设置回调，消息将丢弃
        if(ref $self->on_receive_message eq 'CODE'){
            $self->on_receive_message->($msg); 
        }
    });

    #设置从发送消息队列中提取到消息后对应的处理函数
    $self->{send_message_queue}->get(sub{
        my $msg = shift;
        $self->_send_message($msg)  if $msg->{type} eq 'message';
        $self->_send_group_message($msg)  if $msg->{type} eq 'group_message';
    });


    console "开始接收消息\n";
    $self->_recv_message();
    console "客户端运行中...\n";
    my $timer = AE::timer 0 , 60 , sub{ $self->_get_msg_tip()};
    AE::cv->recv;
};
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
    for my $f( @{ $self->{qq_database}{friends} }){
        return dclone($f) if $f->{uin} eq $uin;
    } 
    return {};
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
    for my $g (@{$self->{qq_database}{group}}){
        if($g->{ginfo}{code} eq $gcode){
            for my $m(@{$g->{minfo} }){
                return dclone($m) if $m->{uin} eq $member_uin; 
            }
        }
    }
    return {};
}

#根据gcode查询对应的群信息,返回的是一个hash的引用
#{
#    face        #群头像
#    memo        #群描述
#    class       #群类型
#    fingermemo  #
#    code        #group_code
#    createtime  #创建时间
#    flag        #
#    level       #群等级
#    name        #群名称
#    gid         #gid
#    owner       #群拥有者
#}
sub search_group{
    my($self,$gcode) = @_;
    for(@{ $self->{qq_database}{group} }){
        return dclone($_->{ginfo}) if $_->{ginfo}{code} eq $gcode;
    }
    return {};
}
#sub search_group{
#    my($self,$gcode) = @_;
#    for(@{ $self->{qq_database}{group_list} }){
#        return dclone($_) if $_->{gcode} eq $gcode;
#    } 
#    return {};
#}

1;
