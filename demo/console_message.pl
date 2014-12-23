#将接收到的普通信息和群信息打印到终端
use lib '../lib/';
use Webqq::Client;
use Digest::MD5 qw(md5_hex);

my $qq = 12345678 ;
my $pwd = md5_hex('your password');

#初始化客户端
my $client = Webqq::Client->new(debug=>0);

#登录
$client->login( qq=> $qq, pwd => $pwd);

#加载Webqq::Client::Plugin::ShowMsg插件
$client->load("ShowMsg");

$client->on_send_message = sub{
    my $msg = shift;
    #执行插件，打印发送的消息
    $client->call("ShowMsg",$msg);
};
$client->on_receive_message = sub{
    my $msg = shift;
    #执行插件，打印接收到的消息
    $client->call("ShowMsg",$msg);
};
$client->run;
