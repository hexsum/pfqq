use JSON;
use Webqq::Client::Util qw(console);
sub Webqq::Client::_get_vfwebqq {
    my $self = shift;
    return 1 if $self->{type} ne 'smartqq';
    console "获取vfwebqq值...\n";
    my $api_url = 'http://s.web2.qq.com/api/getvfwebqq';
    my @query_string = (
        ptwebqq    =>  $self->{qq_param}{ptwebqq},
        clientid   =>  $self->{qq_param}{clientid},
        psessionid =>  undef,
        t          =>  rand(), 
    );  
    my @headers = (
        Referer => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',
    );
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    
    my $ua = $self->{ua};
    my $response = $ua->get($api_url . '?' .join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content,"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode($response->content);
        if($json->{retcode}!=0){
            console "获取vfwebqq值失败...\n";
            return 0;
        }
        $self->{qq_param}{vfwebqq} = $json->{result}{vfwebqq};
        return $json->{result}{vfwebqq};
    }
    else{   
        console "获取vfwebqq值失败...\n";
        return 0;
    }
}
1;
