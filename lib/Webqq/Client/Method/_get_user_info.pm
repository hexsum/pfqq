use JSON;
use Webqq::Client::Util qw(code2state code2client);
sub Webqq::Client::_get_user_info{
    my $self = shift;
    my $webqq_api_url   ='http://s.web2.qq.com/api/get_friend_info2';
    my $smartqq_api_url ='http://s.web2.qq.com/api/get_self_info2';
    my $api_url =   $self->{type} eq 'webqq'?   $webqq_api_url
                :                               $smartqq_api_url
                ;
    my $ua = $self->{ua};
    my @headers = $self->{type} eq 'webqq'? (Referer=>'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3')
                :                           (Referer=>'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1');
                ;       
            
    my @query_string = (
        t               =>  time,
    ); 
    if($self->{type} eq 'webqq'){
        unshift @query_string,(
            tuin            =>  $self->{qq_param}{qq},
            verifysession   =>  undef,
            code            =>  undef,
            vfwebqq         =>  $self->{qq_param}{vfwebqq},
            vfwebqq         =>  $self->{qq_param}{vfwebqq}
        ); 
    }
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode( $response->content() );    
        return undef if $json->{retcode} !=0;
        $json->{result}{state} = $self->{qq_param}{state};
        $json->{result}{client_type} = 'web';
        return $json->{result};
    }
    else{return undef}
}
1;
