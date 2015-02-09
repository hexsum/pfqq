use JSON;
use Webqq::Client::Util qw(hash);
sub Webqq::Client::_get_user_friends{
    my $self = shift;
    my $api_url = 'http://s.web2.qq.com/api/get_user_friends2';
    my $ua = $self->{ua};
    my @headers = $self->{type} eq 'webqq'? (Referer=>'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3')
                :                           (Referer=>'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')   
                ;
    my %r = (
        hash        => hash($self->{qq_param}{ptwebqq},$self->{qq_param}{qq}),  
        vfwebqq     => $self->{qq_param}{vfwebqq},
    );
    if($self->{type} eq 'webqq'){
        $r{"h"} = "hello";
    }
    my $response = $ua->post($api_url,[r=>JSON->new->utf8->encode(\%r)],@headers);
    if($response->is_success){
        print $response->content(),"\n" if $self->{debug};
        my $json = JSON->new->utf8->decode($response->content());
        return undef if $json->{retcode}!=0 ;
        my $friends_state = $self->_get_friends_state();
        my %categories ;
        my %info;
        my %marknames;
        my %vipinfo;
        my %state;
        if(defined $friends_state){
            for(@{$friends_state}){
                $state{$_->{uin}}{state} = $_->{state};
                $state{$_->{uin}}{client_type} = $_->{client_type};
            }
        }
        for(@{ $json->{result}{categories}}){
            $categories{ $_->{'index'} } = {'sort'=>$_->{'sort'},name=>encode("utf8",$_->{name}) };
        }
        $categories{0} = {sort=>0,name=>'我的好友'};
        for(@{ $json->{result}{info}}){
            $info{$_->{uin}} = {face=>$_->{face},flag=>$_->{flag},nick=>encode("utf8",$_->{nick}),};
        }
        for(@{ $json->{result}{marknames} }){
            $marknames{$_->{uin}} = {markname=>encode("utf8",$_->{markname}),type=>$_->{type}};
        }
        for(@{ $json->{result}{vipinfo} }){
            $vipinfo{$_->{u}} = {vip_level=>$_->{vip_level},is_vip=>$_->{is_vip}};
        }        
        for(@{$json->{result}{friends}}){
            my $uin  = $_->{uin};
            if(exists $state{$_->{uin}}){
                $_->{state} = $state{$uin}{state};
                $_->{client_type} = $state{$uin}{client_type};
            }
            else{
                $_->{state} = 'offline';
                $_->{client_type} = 'unknown';
            }
            $_->{categorie} = $categories{$_->{categories}}{name};
            $_->{nick}  = $info{$uin}{nick};
            $_->{face} = $info{$uin}{face};
            $_->{markname} = $marknames{$uin}{markname};
            $_->{is_vip} = $vipinfo{$uin}{is_vip};
            $_->{vip_level} = $vipinfo{$uin}{vip_level};
            delete $_->{categories};
        }
        return $json->{result}{friends};
    }
    else{return undef}
}
1;
