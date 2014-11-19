use JSON;
use Webqq::Client::Util qw(console);
sub Webqq::Client::get_qq_from_uin{
    my $self = shift;
    my $uin = shift;
    my $cache_data =  $self->{cache_for_uin_to_qq}->retrieve($uin);
    return $cache_data if defined $cache_data;
    my $ua = $self->{ua};
    my $api_url = 'http://s.web2.qq.com/api/get_friend_uin2';
    my @headers  = (Referer=>'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3');
    my @query_string = (
        tuin            =>  $uin,
        verifysession   =>  undef,
        type            =>  1,
        code            =>  undef,
        vfwebqq         =>  $self->{qq_param}{vfwebqq},
        t               =>  time,
    );     
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode( $response->content() );
        if($json->{retcode} !=0){
            console "从指定uin: $uin 查询QQ号码失败\n";
            return undef;
        }
        $self->{cache_for_uin_to_qq}->store($uin,$json->{result}{account});
        return $json->{result}{account};
    }
}
1;
