#一个简单的echo-reply的qq机器人
#你发送什么信息给它，它就回复相同的内容给你
use lib '../lib/';
use Webqq::Client;
use Digest::MD5 qw(md5_hex);

my $qq = 12345678  ;
my $pwd = md5_hex('your password');
my $client = Webqq::Client->new(debug=>0);
$client->login( qq=> $qq, pwd => $pwd);


$client->load("ShowMsg");
#设置全局默认的发送消息后的回调函数，主要用于判断消息是否成功发送
$client->on_send_message = sub{
    my ($msg,$is_success,$status) = @_;

    #使用ShowMsg插件打印发送的消息
    $client->call("ShowMsg",$msg);
};

#设置接收到消息后的回调函数
$client->on_receive_message = sub{
    #传递给回调的参数是一个包含接收到的消息的hash引用
    #$msg = {
    #    type        => message|group_message 消息类型
    #    msg_id      => 系统生成的消息id
    #    from_uin    => 消息发送者uin，回复消息时需要用到
    #    to_uin      => 消息接受者uin，就是自己的qq
    #    content     => 消息内容，采用UTF8编码
    #    msg_time    => 消息的接收时间
    #    ttl
    #    msg_class
    #    allow_plugin
    #}
    my $msg = shift;
   
    #使用ShowMsg插件打印接收到的消息 
    $client->call("ShowMsg",$msg);

    #新的方式
    $client->reply_message($msg,$msg->{content});

    #老的方式，你需要根据消息的类型调用相应的发送消息方法
    #if($msg->{type} eq 'message'){
    #    $client->send_message(
    #        to_uin     =>  $msg->{from_uin},
    #        content    =>  $msg->{content} ,
    #    ) ;
    #}
    #elsif($msg->{type} eq 'group_message'){
    #    $client->send_group_message(
    #        to_uin     =>  $msg->{from_uin},
    #        content    =>  $msg->{content},
    #    ) ;        
    #}
    #elsif($msg->{type} eq 'sess_message'){
    #    $client->send_sess_message(
    #        to_uin     =>  $msg->{from_uin},
    #        content    =>  $msg->{content},
    #        group_code =>  $msg->{group_code},
    #    );
    #}
};
$client->run;
