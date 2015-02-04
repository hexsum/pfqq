use JSON;
sub Webqq::Client::_get_group_sig {
    my $self = shift;
    my($id,$to_uin,$service_type,) = @_;
    my $cache_data = $self->{cache_for_group_sig}->retrieve("$id|$to_uin|$service_type");
    return $cache_data if defined $cache_data;
    my $ua = $self->{ua};
    my $api_url = 'http://d.web2.qq.com/channel/get_c2cmsg_sig2';
    my @query_string  = (
        id              =>  $id,
        to_uin          =>  $to_uin,
        service_type    =>  $service_type,
        clientid        =>  $self->{qq_param}{clientid},
        psessionid      =>  $self->{qq_param}{psessionid},
        t               =>  time,
    ); 
    my @headers = $self->{type} eq 'webqq'? (Referer=>'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3')
                :                           (Referer=>'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2')
                ;

    
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content() if $self->{debug};
        my $json = JSON->new->utf8->decode($response->content()); 
        return undef if $json->{retcode}!=0;
        return undef if $json->{result}{value} eq "";
        $self->{cache_for_group_sig}->store("$id|$to_uin|$service_type",$json->{result}{value},300);
        return $json->{result}{value} ;
    }
    else{return undef}
}
1;
