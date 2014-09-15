sub Webqq::Client::_get_group_list_info{
    my $self  = shift;
    my $ua = $self->{asyn_ua};
    my $api_url = 'http://s.web2.qq.com/api/get_group_name_list_mask2';
    my @headers = (Referer => 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3');
    my %r = (
        hash        =>  ,
        vfwebqq     =>  $self->{qq_param}{vfwebqq},
        
    );  
}
1;
