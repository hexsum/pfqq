use JSON;
use Webqq::Client::Util qw(code2state code2client);
sub Webqq::Client::_get_friends_state {
    my $self = shift;
    return undef if $self->{type} ne 'smartqq';
    my $ua = $self->{ua};
    my $api_url = 'http://d.web2.qq.com/channel/get_online_buddies2';
    my @headers  = (
        Referer=>'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2'    
    );
    my @query_string = (
        vfwebqq         =>  $self->{qq_param}{vfwebqq},
        clientid        =>  $self->{qq_param}{clientid},
        psessionid      =>  $self->{qq_param}{psessionid},
        t               =>  time,
    ); 
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    print "GET $api_url\n" if $self->{debug};
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode( $response->content() );    
        return undef if $json->{retcode} !=0;
        for(@{$json->{result}}){
            $_->{client_type} = code2client($_->{client_type});
            $_->{state} = $_->{status};
            delete $_->{status};
        }
        return $json->{result};
    }
    else{return undef}
}
1;
