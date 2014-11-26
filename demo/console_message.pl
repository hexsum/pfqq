#将接收到的普通信息和群信息打印到终端
use lib '../lib/';
use POSIX qw(strftime);
use Webqq::Client;
use Webqq::Client::Util qw(console);
use Webqq::Client::App::ShowMsg;
use Digest::MD5 qw(md5_hex);
use Encode;

my $qq = 12345678;
my $pwd = md5_hex('your password');

my $client = Webqq::Client->new(debug=>0);
$client->login( qq=> $qq, pwd => $pwd);
$client->on_receive_message = sub{
    my $msg = shift;
    ShowMsg($msg);
};
$SIG{INT} = sub{$client->logout();exit;};
$client->run;
