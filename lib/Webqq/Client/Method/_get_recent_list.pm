use JSON;
use Webqq::Client::Util qw(console);
sub Webqq::Client::_get_recent_list {
    my $self = shift;
    return undef if $self->{type} ne 'smartqq';
    
    my $ua = $self->{ua};
    my $api_url = 'http://d.web2.qq.com/channel/get_recent_list2';
    my @query_string  = (
        vfwebqq     =>  $self->{qq_param}{vfwebqq},
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
        t           =>  time(),
    ); 

    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my @headers = (Referer => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1');
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        my $json;
        eval{
            $json = JSON->new->utf8->decode($response->content()) ;
        };
        if($self->{debug}){
            console $@."\n" if $@;
        }
        return undef if $json->{retcode} !=0;
        my $recent_list = $json->{result};
        return $recent_list;
    }
    else{return undef;}
}
1;
