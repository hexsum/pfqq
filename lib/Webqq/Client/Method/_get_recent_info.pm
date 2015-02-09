use JSON;
sub Webqq::Client::_get_recent_info {
    my $self  = shift;
    my $ua  = $self->{ua};
    return undef if $self->{type} ne 'smartqq';
    my $api_url = 'http://d.web2.qq.com/channel/get_recent_list2';
    my @headers = (
        Referer => 'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2',
    );     

    my %r = (
        vfwebqq         =>  $self->{qq_param}{vfwebqq},
        clientid        =>  $self->{qq_param}{clientid},
        psessionid      =>  $self->{qq_param}{psessionid},
    ); 
    my $response = $ua->post($api_url,[r=>JSON->new->utf8->encode(\%r)],@headers);    
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode($response->content());        
        return undef if $json->{retcode}!=0 ;
        my %type = (0 => 'friend',1 => 'group', 2 => 'discuss');
        my @recent;
        for(@{$json->{result}}){
            next unless exists $type{$_->{type}};
            $_->{type} = $type{$_->{type}};
            push @recent,$_;
        }
        return @recent>0?\@recent:undef;
    } 

}
1;
