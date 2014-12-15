use JSON;
use Encode;
sub Webqq::Client::_get_stranger_info {
    my $self = shift;
    my $tuin = shift;
    return undef if $self->{type} ne 'webqq';
    my $ua = $self->{ua};
    my $cache_data = $self->{cache_for_stranger}->retrieve($tuin);
    return $cache_data if defined $cache_data;
    my $api_url = 'http://s.web2.qq.com/api/get_stranger_info2';
    my @headers = (
        Referer => 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3',
        'Content-Type'=>'utf-8',
    );
    my @query_string  = (
        tuin            =>  $tuin,
        verifysession   =>  undef,
        gid             =>  0,
        code            =>  undef,
        vfwebqq         =>  $self->{qq_param}{vfwebqq},
        t               =>  time,
    );
    
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);

    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode($response->content()); 
        return undef if $json->{retcode}!=0;
        $json->{result}{nick} = encode("utf8",$json->{result}{nick});
        $self->{cache_for_stranger}->store($tuin,$json->{result},300);
        return $json->{result};
    }
    
    else{return undef}
}
1;
