use JSON;
use Encode;
sub Webqq::Client::_get_discuss_list_info {
    my $self = shift;
    my $ua = $self->{ua};
    return undef if $self->{type} ne 'smartqq';
    my $api_url = 'http://s.web2.qq.com/api/get_discus_list';   
    my @query_string = (
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
        vfwebqq     =>  $self->{qq_param}{vfwebqq},
        t           =>  time(),
    );
     
    my @headers = (
        Referer  => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',
    );
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        #{"retcode":0,"result":{"dnamelist":[{"name":"测试2","did":2742986730},{"name":"测试","did":3420777698}]}}
        print $response->content(),"\n" if $self->{debug};
        my $json;
        eval{
            $json = JSON->new->utf8->decode($response->content()) ;
        };
        print $@ if $@ and $self->{debug};
        $json = {} unless defined $json;
        return undef if $json->{retcode}!=0;  
        for(@{ $json->{result}{dnamelist} }){
            $_->{name} = encode("utf8",$_->{name});
        } 
        return $json->{result}{dnamelist};
        
    }
    else{return undef;}

}

1;
