package Webqq::Client;
use base Webqq::Message;
use Webqq::Message::Queue;

#定义模块的版本号
our $VERSION = v1.3;

use LWP::UserAgent;#同步HTTP请求客户端
use AnyEvent::UserAgent;#异步HTTP请求客户端

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
use Webqq::Client::Method::_get_user_info;
use Webqq::Client::Method::_send_message;
use Webqq::Client::Method::_send_group_message;


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
            send_msg_id             =>  1,
            clientid                =>  1+int(rand(99999999)),
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
        },
        qq_database     =>  {
            user    =>  {},
            friends =>  {},
            group   =>  {},
            discuss =>  {},
        },
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
    print "QQ账号: $self->{qq_param}{qq} 密码: $self->{qq_param}{pwd}\n";
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
sub change_status;

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
sub show_message;
sub logout;
sub run {
    my $self = shift;
    #登录不成功，客户端退出运行
    if($self->{qq_param}{login_state} ne 'success'){
        print "登录失败\n";
        return ;
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

    print "开始接收消息\n";
    $self->_recv_message();
    print "客户端运行中...\n";
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

1;
