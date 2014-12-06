package Webqq::Client::Plugin::SmartReply2;
my $API = 'http://www.xiaodoubi.com/bot/api.php?chat=';
sub call{
    my $client = shift;
    my $msg = shift;
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
