sub Webqq::Client::_report {
    my $self = shift;
    return 1;
    return 1 if $self->{type} ne 'smartqq';
    console "上报登录状态...\n";
    my $ua = $self->{ua};
    my $response = $ua->get('https://ui.ptlogin2.qq.com/cgi-bin/report?id=488358');
    print $response->content(),"\n" if $self->{debug};
    return 1;
}
1;
