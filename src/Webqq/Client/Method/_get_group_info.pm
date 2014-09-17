use JSON;
use Webqq::Client::Util qw(console);
sub Webqq::Client::_get_group_info {
    my $self = shift;
    my $ua = $self->{ua};
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
    my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
    if($response->is_success){
        my $json = JSON->new->utf8->decode($response->content()); 
        return 0 if $json->{retcode}!=0;
        $json->{result}{ginfo}{name} = encode("utf8",$json->{result}{ginfo}{name});
        delete $json->{result}{ginfo}{members};
        for my $m(@{ $json->{result}{minfo} }){
            for(keys %$m){
                $m->{$_} = encode("utf8",$m->{$_});
            }
        }
        push @{$self->{qq_database}{group}},
            {
                ginfo   =>  $json->{result}{ginfo},
                minfo   =>  $json->{result}{minfo} 
            };
        return 1;
    }
    else{return 0;}
}
1;
