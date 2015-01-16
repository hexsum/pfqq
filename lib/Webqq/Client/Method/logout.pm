use Webqq::Client::Util qw(console);
sub Webqq::Client::logout { 
    my $self = shift;
    console "正在注销...\n";
    if($self->{type} eq 'smartqq'){
        $self->{cookie_jar}->set_cookie(0,"ptwebqq",undef,"/","qq.com",undef,undef,undef,-1);
        $self->{cookie_jar}->set_cookie(0,"skey",undef,"/","qq.com",undef,undef,undef,-1);
        console "注销完毕\n";
        return 1;
    }
    my $ua = $self->{ua};
    my $api_url = 'http://d.web2.qq.com/channel/logout2';
    my @query_string = (
        ids         =>  undef,
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
        t           =>  time,
    );
    my @headers = (Referer  =>  'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3');
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        my $content = $response->content();
        print $content,"\n" if $self->{debug};
        console "注销完毕\n";
        return 1;
    }
    else{return 0}
}
1;
