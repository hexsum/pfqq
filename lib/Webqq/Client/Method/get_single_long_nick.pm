use JSON;
use Encode;
sub Webqq::Client::get_single_long_nick{
    my $self = shift;
    return if $self->{type} ne 'smartqq';
    my $api_url = 'http://s.web2.qq.com/api/get_single_long_nick2';
    my $ua = $self->{ua};
    my @headers  = (Referer=>'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1');
    my @query_string = (
        tuin            =>  $self->{qq_param}{qq},
        vfwebqq         =>  $self->{qq_param}{vfwebqq},
        t               =>  time,
    ); 
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content() if $self->{debug};
        my $json = JSON->new->utf8->decode( $response->content() );    
        return undef if $json->{retcode} !=0;
        #{"retcode":0,"result":[{"uin":308165330,"lnick":""}]}
    }
    else{return undef}
}
1;
