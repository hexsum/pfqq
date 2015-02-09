use JSON;
use Webqq::Client::Util qw(console code2state code2client);
sub Webqq::Client::_get_group_info {
    my $self = shift;
    my $gcode = shift;
    my $ua = $self->{ua};
    my $api_url = 'http://s.web2.qq.com/api/get_group_info_ext2';
    my @query_string  = (
        gcode   =>  $gcode,
        vfwebqq =>  $self->{qq_param}{vfwebqq},
        t       =>  time(),
    ); 

    if($self->{type} eq 'webqq'){
        splice @query_string,2,0,(cb      =>  "undefined");
    }        

    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my @headers = $self->{type} eq 'webqq'? (Referer => 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3')
                :                           (Referer => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
                ;
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        my $json;
        eval{
            $json = JSON->new->utf8->decode($response->content()) ;
        };
        $json = {} unless defined $json;
        my $ginfo_status = exists $json->{result}{ginfo}?"[ginfo-ok]":"[ginfo-not-ok]";
        my $minfo_status = exists $json->{result}{minfo}?"[minfo-ok]":"[minfo-not-ok]";
        
        if($self->{debug}){
            print substr($response->content(),0,80),"${ginfo_status}${minfo_status}...\n";
            console $@."\n" if $@;
        }

        return undef unless exists $json->{result}{ginfo};
        #return undef unless exists $json->{result}{minfo};
        delete $json->{result}{ginfo}{members}; 
        for(keys %{$json->{result}{ginfo}}){
            $json->{result}{ginfo}{$_} = encode("utf8",$json->{result}{ginfo}{$_});
        }
        #retcode等于0说明包含完整的ginfo和minfo
        if($json->{retcode}==0){
            return undef unless exists $json->{result}{minfo};
            my %cards;
            for  (@{ $json->{result}{cards} }){
                $cards{$_->{muin}} = $_->{card};
            }
            my %state;
            for(@{ $json->{result}{stats} }){
                $state{$_->{uin}}{client_type} = $_->{client_type};
                $state{$_->{uin}}{state} = code2state($_->{'stat'});
            }
            for my $m(@{ $json->{result}{minfo} }){
                $m->{card} = $cards{$m->{uin}} if exists $cards{$m->{uin}} ; 
                if(exists $state{$m->{uin}}){
                    $m->{state} = $state{$m->{uin}}{state};
                    $m->{client_type} = code2client($state{$m->{uin}}{client_type});
                }
                else{
                    $m->{state} = 'offline';
                    $m->{client_type} = 'unknown';
                }
                for(keys %$m){
                    $m->{$_} = encode("utf8",$m->{$_});
                }
            }
            my $group_info  = {
                ginfo   =>  $json->{result}{ginfo},
                minfo   =>  $json->{result}{minfo},
            };
            #查询结果同时进行缓存，以优化查询速度
            #$self->{cache_for_group}->store($gcode,$group_info);
            return $group_info;
        }
        #只存在ginfo
        else{
            my $group_info = {
                ginfo   =>  $json->{result}{ginfo},
            };
            return $group_info;
        }
    }
    else{return undef;}
}
1;
