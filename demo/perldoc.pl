use lib '../lib/';
use Webqq::Client;
use Webqq::Message;
use Webqq::Client::Util qw(console);
use Digest::MD5 qw(md5_hex);
use Webqq::Client::App::Perldoc;
use Webqq::Client::App::Perlcode;

chdir '/tmp/webqq';

my $qq = 12345678;
my $pwd = md5_hex('your password');
my $client = Webqq::Client->new(debug=>0);
$client->login( qq=> $qq, pwd => $pwd);

#设置全局默认的发送消息后的回调函数，主要用于判断消息是否成功发送
$client->on_send_message = sub{
    my ($msg,$is_success,$status) = @_;
    ##程序默认输出的是UTF8编码，你的终端可能是其他编码，做下自适应
    console "msg_id: ",$msg->{msg_id}," ",$status,"\n" ;
};

#设置接收到消息后的回调函数
$client->on_receive_message = sub{
    #传递给回调的参数是一个包含接收到的消息的hash引用
    #$msg = {
    #    type        => message|group_message|sess_message 消息类型
    #    msg_id      => 系统生成的消息id
    #    from_uin    => 消息发送者uin，回复消息时需要用到
    #    to_uin      => 消息接受者uin，就是自己的qq
    #    content     => 消息内容，采用UTF8编码
    #    msg_time    => 消息的接收时间
    #}
    my $msg = shift;
    #响应聊天消息中的perldoc查询命令，必须是perldoc -f|-v形式
    Perldoc     $msg,$client;
    #响应聊天消息中的perl代码执行指令
    #代码必须是以介于 :code|:c|perlcode|__CODE__ 和 :end|:e|end|__END__之间的代码
    Perlcode    $msg,$client;     
};
local $SIG{INT} = sub{$client->logout();exit;};
$client->run;
