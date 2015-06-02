use JSON ;
use Webqq::Client::Util qw(console);
sub Webqq::Client::_login2{
    my $self = shift;
    console "尝试进行登录(阶段2)...\n";
    my $ua = $self->{ua};
    my $api_url = 'http://d.web2.qq.com/channel/login2';
    my @headers = $self->{type} eq 'webqq'? (Referer=>'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3')
                :                           (Referer=>'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2')
                ;
    my %r = (
        status      =>  $self->{qq_param}{state},
        ptwebqq     =>  $self->{qq_param}{ptwebqq},
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
    );    
    
    if($self->{type} eq 'webqq'){
        $r{passwd_sig} = $self->{qq_param}{passwd_sig};
    }

    for(my $i=0;$i<=$self->{ua_retry_times};$i++){
        my $response = $ua->post($api_url,[r=>JSON->new->utf8->encode(\%r)], @headers);
        if($response->is_success){
            print $response->content() if $self->{debug};
            my $content = $response->content();
            my $data = JSON->new->utf8->decode($content);
            if($data->{retcode} ==0){
                $self->{qq_param}{psessionid} = $data->{result}{psessionid};
                #$self->{qq_param}{vfwebqq} = $data->{result}{vfwebqq};
                $self->_cookie_proxy();
                $self->{login_state} = 'success';
                return 1;
            }
        }
    }
    return 0;
}
1;
