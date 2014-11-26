use JSON;
sub Webqq::Client::_get_group_list_info{
    my $self  = shift;
    my $ua = $self->{ua};
    my $api_url = 'http://s.web2.qq.com/api/get_group_name_list_mask2';
    my @headers = $self->{type} eq 'webqq'? (Referer => 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3')    
                :                           (Referer => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
                ;
    my %r = (
        hash        =>  hash($self->{qq_param}{ptwebqq},$self->{qq_param}{qq}),
        vfwebqq     =>  $self->{qq_param}{vfwebqq},
    );  

    my $post_content = [ 
        r       =>  JSON->new->encode(\%r), 
    ];

    #if($self->{debug}){
    #    require URI;
    #    my $uri = URI->new('http:');
    #    $uri->query_form($post_content);
    #    print $api_url,"\n";
    #    print $uri->query(),"\n";
    #}

    my $response =  $ua->post(
        $api_url,
        $post_content,
        @headers,
    );
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode( $response->content() ); 
        return undef unless exists $json->{result}{gnamelist};
        return $json->{result};
    }
    else{return undef}
}
1;
