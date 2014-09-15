sub Webqq::Client::_get_group_info {
    my $self = shift;
    my $ua = $self->{asyn_ua};
    my ($gcode) = @_;
    my $api_url = 'http://s.web2.qq.com/api/get_group_info_ext2';
    my @query_string  = (
        gcode   =>  $gcode,
        cb      =>  "undefined",
        vfwebqq =>  $self->{qq_param}{vfwebqq},
        t       =>  time(),
    ); 
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my @headers = (Referer => 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3');
   
    $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers,sub{
        my $response = shift;
        print $response->as_string; 
    });
}
1;
