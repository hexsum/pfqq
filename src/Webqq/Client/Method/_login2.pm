use JSON qw(from_json to_json);
sub Webqq::Client::_login2{
    my $self = shift;
    print "尝试进行登录(阶段2)...\n";
    my $ua = $self->{ua};
    my $api_url = 'http://d.web2.qq.com/channel/login2';
    my @headers = (Referer=>'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3');
    my %r = (
        status      =>  $self->{qq_param}{status},
        ptwebqq     =>  $self->{qq_param}{ptwebqq},
        passwd_sig  =>  $self->{qq_param}{passwd_sig},
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
    );    
    
    my $response = $ua->post($api_url,[r=>to_json(\%r),clientid=>$self->{qq_param}{clientid},psessionid=>$self->{qq_param}{psessionid}], @headers);
    if($response->is_success){
        print $response->content() if $self->{debug};
        my $content = $response->content();
        my $data = from_json($content);
        if($data->{retcode} ==0){
            $self->{qq_param}{psessionid} = $data->{result}{psessionid};
            $self->{qq_param}{vfwebqq} = $data->{result}{vfwebqq};
            $self->{qq_param}{login_state} = 'success';
            print "登录成功\n";
        }
        return 1;
    }
    else{return 0}
}
1;
