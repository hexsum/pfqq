use JSON;
use Encode;
use Webqq::Client::Util qw(hash console);
sub Webqq::Client::_get_friends_list_info{
    my $self = shift;
    console "获取好友信息...\n";
    my $api_url = 'http://s.web2.qq.com/api/get_user_friends2';
    my $ua = $self->{ua};
    my @headers  = (Referer=>'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3');
    my %r = (
        h           =>  "hello",
        hash        => hash($self->{qq_param}{ptwebqq},$self->{qq_param}{qq}),  
        vfwebqq     => $self->{qq_param}{vfwebqq},
    );
    my $response = $ua->post($api_url,[r=>JSON->new->encode(\%r)],@headers);
    if($response->is_success){
        print $response->content() if $self->{debug};
        my $json = JSON->new->utf8->decode($response->content());
        return 0 if $json->{retcode}!=0 ;
        my %categories ;
        my %info;
        my %marknames;
        my %vipinfo;
        for(@{ $json->{result}{categories}}){
            $categories{ $_->{'index'} } = {'sort'=>$_->{'sort'},name=>encode("utf8",$_->{name}) };
        }
        $categories{0} = {sort=>0,name=>'我的好友'};
        for(@{ $json->{result}{info}}){
            $info{$_->{uin}} = {face=>$_->{face},flag=>$_->{flag},nick=>encode("utf8",$_->{nick}),};
        }  
        for(@{ $json->{result}{marknames} }){
            $marknames{$_->{uin}} = {markname=>encode("utf8",$_->{markname},type=>$_->{type})};
        }
        for(@{ $json->{result}{vipinfo} }){
            $vipinfo{$_->{u}} = {vip_level=>$_->{vip_level},is_vip=>$_->{is_vip}};
        }

        $self->{qq_database}{friends} = $json->{result}{friends};  
        for(@{ $self->{qq_database}{friends} }){
            my $uin = $_->{uin};
            $_->{categorie} = $categories{$_->{categories}}{name};
            $_->{nick}  = $info{$uin}{nick};
            $_->{face} = $info{$uin}{face};
            $_->{markname} = $marknames{$uin}{markname};
            $_->{is_vip} = $vipinfo{$uin}{is_vip};
            $_->{vip_level} = $vipinfo{$uin}{vip_level};
        }
        return 1;
    }
    else{return 0}
}
1;
