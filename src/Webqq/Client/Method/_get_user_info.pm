sub Webqq::Client::_get_user_info{
    my $self = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_friend_info2';
    my $ua = $self->{ua};
    my @headers  = (Referer=>'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3');
    my @query_string = (
        tuin            =>  $self->{qq_param}{qq},
        verifysession   =>  undef,
        code            =>  undef,
        vfwebqq         =>  $self->{qq_param}{vfwebqq},
        t               =>  time,
    ); 
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content();
           
    }
    else{

    } 
}
1;
