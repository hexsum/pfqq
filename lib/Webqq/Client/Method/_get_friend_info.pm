use JSON;
use Webqq::Client::Util qw(code2state);
sub Webqq::Client::_get_friend_info{
    my $self = shift;
    my $uin = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_friend_info2';
    my $ua = $self->{ua};
    my @headers  = $self->{type} eq 'webqq'?    (Referer=>'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3')
                 :                              (Referer=>'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
                 ;
    my @query_string = (
        tuin            =>  $uin,
        vfwebqq         =>  $self->{qq_param}{vfwebqq},
        clientid        =>  $self->{qq_param}{clientid},
        psessionid      =>  $self->{qq_param}{psessionid},
        t               =>  time,
    ); 

    if($self->{type} eq 'webqq'){
        @query_string = (
            tuin            =>  $uin,
            verifysession   =>  undef,
            code            =>  undef,
            vfwebqq         =>  $self->{qq_param}{vfwebqq},
            t               =>  time,
        );
    }
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode( $response->content() );    
        return undef if $json->{retcode} !=0;
        my $user_info = $json->{result};
        for my $key (keys %{ $user_info }){
            if($key eq 'birthday'){
                $user_info->{$key} = 
                    encode("utf8", join("-",@{ $user_info->{birthday}}{qw(year month day)}  )  );
            }
            elsif($key eq 'stat'){
                $user_info{state} = code2state($user_info->{'stat'});
            }
            else{
                $user_info->{$key} = encode("utf8",$user_info->{$key});
            }
        }
        delete $user_info->{'stat'};
        return $user_info;
    }
    else{return undef}
}
1;
