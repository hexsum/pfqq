use JSON;
use Webqq::Client::Util qw(console);
sub Webqq::Client::_get_online_list_info {
    my $self = shift;
    return undef if $self->{type} ne 'smartqq';
    
    my $ua = $self->{ua};
    my $api_url = 'http://d.web2.qq.com/channel/get_online_buddies2';
    my %r = (
        vfwebqq     =>  $self->{qq_param}{vfwebqq},
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
        t           =>  time(),
    );    
    my @headers = (Referer => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1');
    my $response = $ua->post($api_url,[r=>JSON->new->utf8->encode(\%r)], @headers);
    if($response->is_success){
        my $json;
        eval{
            $json = JSON->new->utf8->decode($response->content()) ;
        };
        if($self->{debug}){
            console $@."\n" if $@;
        }
        return undef if $json->{retcode} !=0;
        my %online_list;
        for(@{ $json->{result} }) {
            my $uin = $_->{uin};
            $online_list->{$uin}   = {
                'state'       => $_->{status},
                'client_type' => $_->{client_type},
            };
        }
        return $online_list;
    }
    else{return undef;}
}
1;
