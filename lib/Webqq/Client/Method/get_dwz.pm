use JSON;
use Webqq::Client::Util qw(console);
sub Webqq::Client::get_dwz {
    my $self = shift;
    my $url = shift;
    my $api = 'http://dwz.cn/create.php';
    my $ua = $self->{ua};
    my $res;
    my $dwz;
    eval{
        local $SIG{ALRM} = sub{die "timeout";};
        alarm 5;
        $res = $ua->post($api,[url=>$url],);
        alarm 0;
        if($res->is_success){
            my $json = JSON->new->utf8->decode($res->content);
            $dwz = $json->{tinyurl} if $json->{status}==0; 
        };
    };
    console "[Webqq::Client::get_dwz] $@\n" if $@ and $self->{debug};

    return $dwz;
    
};
1;
