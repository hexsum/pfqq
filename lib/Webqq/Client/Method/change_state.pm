use JSON;
use Webqq::Client::Util qw(console);
sub Webqq::Client::change_state{
    my $self = shift;
    return undef if $self->{type} ne 'smartqq';
    my $state = shift;
    my $api_url = 'http://d.web2.qq.com/channel/change_status2';
    my $ua = $self->{ua};
    my @headers  = (
        Referer=>'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2'    
    );
    my @query_string = (
        newstatus       =>  $state,
        clientid        =>  $self->{qq_param}{clientid},
        psessionid      =>  $self->{qq_param}{psessionid},
        t               =>  time,
    ); 

    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode( $response->content() );    
        return undef if $json->{retcode} !=0;
        console "登录状态已修改为：$state\n";
        return $state;
    }
    else{return undef}
}
1;
