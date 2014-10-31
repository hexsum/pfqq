use JSON;
use Webqq::Client::Util qw(hash);
sub Webqq::Client::_get_friends_info{
    my $self = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_user_friends2';
    my $ua = $self->{ua};
    my @headers  = (Referer=>'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3');
    my %r = (
        h           =>  "hello",
        hash        => hash($self->{qq_param}{ptwebqq},$self->{qq_param}{qq}),  
        vfwebqq     => $self->{qq_param}{vfwebqq},
    );
    my $response = $ua->post($api_url,[r=>JSON->new->encode(\%r)],@headers);
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode($response->content());
        return undef if $json->{retcode}!=0 ;
        return $json->{result};
    }
    else{return undef}
}
1;
