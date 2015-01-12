sub Webqq::Client::_cookie_proxy {
    my $self = shift;
    return 1 if $self->{type} ne 'smartqq';
    my $p_skey = $self->search_cookie("p_skey");
    my $p_uin = $self->search_cookie("p_uin");
    $self->{cookie_jar}->set_cookie(0,"p_skey",$p_skey,"/","w.qq.com"); 
    $self->{cookie_jar}->set_cookie(0,"p_uin",$p_skey,"/","w.qq.com"); 
    return 1;
};
1;
