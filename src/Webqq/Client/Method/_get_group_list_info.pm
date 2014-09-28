use Webqq::Client::Util qw(hash console);
use JSON;
use Encode;
sub Webqq::Client::_get_group_list_info{
    my $self  = shift;
    console "获取群列表信息...\n";
    my $ua = $self->{ua};
    my $api_url = 'http://s.web2.qq.com/api/get_group_name_list_mask2';
    my @headers = (Referer => 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3');
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
        return 0 if $json->{retcode} != 0;
        #存储或更新qq_database中的group信息
        $self->{qq_database}{group_list} =  $json->{result}{gnamelist};
        my %gmarklist;
        for(@{ $json->{result}{gmarklist} }){
            $gmarklist{$_->{uin}} = $_->{markname};
        }
        for(@{ $self->{qq_database}{group_list} }){
            $_->{markname} = $gmarklist{$_->{gid}};
            $_->{name} = encode("utf8",$_->{name});
        }
        return 1;
    }
    else{return 0}
}
1;
