package Webqq::Client::App::SmartReply2;
use Exporter 'import';
@EXPORT=qw(SmartReply2);
my $API = 'http://www.xiaodoubi.com/bot/api.php?chat=';
sub SmartReply2{
    my $msg = shift;
    my $client = shift;
    my $res;
    eval{
        local $SIG{ALRM} = sub{die "timout\n"};
        alarm 5;
        $res = $client->{ua}->get($API . $msg->{content});
        alarm 0;
    };
    print "Webqq::Client::App::SmartReply请求超时\n" if $@ and $client->{debug}; 
    if($res->is_success){
        my $data = $res->content;
        $data=~s/小逗比/小灰/g;
        if($data){
            $client->reply_message($msg,$data);
        }
    }
    else{return undef}
     
}
1;
