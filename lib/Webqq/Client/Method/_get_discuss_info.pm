use JSON;
use Encode;
use Webqq::Client::Util qw(code2client);
sub Webqq::Client::_get_discuss_info {
    my $self = shift;       
    my $ua = $self->{ua};
    my $did = shift;
    return undef if $self->{type} ne 'smartqq';
    my $api_url  = 'http://d.web2.qq.com/channel/get_discu_info';
    my @query_string = (
        did         =>  $did,
        vfwebqq     =>  $self->{qq_param}{vfwebqq},
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
        t           =>  time(),
    );
    my @headers = (
        Referer  => 'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2',
    );

    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);

    if($response->is_success){
        print $response->content,"\n" if $self->{debug};
        my $json;
        eval{
            #my $d = $response->content();
            #$d=~s/\\u([a-zA-Z0-9]{4})/encode("utf8",eval qq#"\\x{$1}"#)/eg;
            #print $d,"\n" if $self->{debug};
            $json = JSON->new->utf8->decode($response->content());
        };    
        print $@ if $@ and $self->{debug};
        $json = {} unless defined $json;
        return undef if $json->{retcode}!=0;
        return undef unless exists $json->{result}{info};
        
        my %mem_list;
        my %mem_status;
        my %mem_info;
        my $minfo = [];

        for(@{ $json->{result}{info}{mem_list} }){
            $mem_list{$_->{mem_uin}}{ruin} = $_->{ruin};            
        }

        for(@{ $json->{result}{mem_status} }){
            $mem_status{$_->{uin}}{status} = $_->{status};
            $mem_status{$_->{uin}}{client_type} = $_->{client_type};
        }

        for(@{ $json->{result}{mem_info} }){
            $mem_info{$_->{uin}}{nick} = encode("utf8",$_->{nick});
        }

        for(keys %mem_list){
            my $m = {
                uin         => $_,  
                nick        => $mem_info{$_}{nick},
                ruin        => $mem_list{$_}{ruin},
            };
            if(exists $mem_status{$_}){
                $m->{state} = $mem_status{$_}{status};
                $m->{client_type} = code2client($mem_status{$_}{client_type});
            }
            else{
                $m->{state} = 'offline';
                $m->{client_type} = 'unknown';
            }
            push @{$minfo},$m;
        }

        my $discuss_info = {
            dinfo   => {
                did         =>  $json->{result}{info}{did},
                owner       =>  $json->{result}{info}{discu_owner},
                name        =>  encode("utf8",$json->{result}{info}{discu_name}),
                info_seq    =>  $json->{result}{info}{info_seq},
            },
            minfo           =>  (@$minfo>0?$minfo:undef),
        } ;
        return $discuss_info;
    }
    else{return undef;} 

}
1;
