package Webqq::Client::App::SmartReply;
use Exporter 'import';
@EXPORT=qw(SmartReply);
my $API = 'http://www.xiaodoubi.com/bot/api.php?chat=';
sub SmartReply{
    my $msg = shift;
    my $client = shift;
    return unless $msg->{content} =~/^\@小灰/;
    my $input = $msg->{content};
    $input=~s/^\@小灰//;
    my $res;
    eval{
        local $SIG{ALRM} = sub{die "timout\n"};
        alarm 5;
        $res = $client->{ua}->get($API . $input);
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
    else{return }
     
}
1;
