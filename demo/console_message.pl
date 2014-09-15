use lib '../src/';
use POSIX qw(strftime);
use Webqq::Client;
use Digest::MD5 qw(md5_hex);
use Encode;
use Encode::Locale;

my $qq = 12345678;
my $pwd = md5_hex('your password');
my $client = Webqq::Client->new(debug=>0);
$client->login( qq=> $qq, pwd => $pwd);
$client->on_receive_message = sub{
    my $msg = shift;
    my $line_h = join " ",strftime('[%Y/%m/%d %H:%M:%S]',localtime($msg->{msg_time})),$msg->{type},"" ;
    my @content = split /\\n/,$msg->{content};
    my @line_h = ($line_h,(' ' x length($line_h)) x $#content  );
    while(@content){
        my $lh = shift @line_h;
        my $lc = shift @content;
        #你的终端可能不是UTF8编码，为了防止乱码，做下编码自适应转换
        print $lh, encode("console_out",decode("utf8",$lc)),"\n";
    }
};
$client->run;
