package Plack::App::Openqq::SendSessMessage;
use parent qw(Plack::Component);
use URI::Escape qw(uri_unescape);
use JSON;
use Encode;;
sub call{
    my $self = shift;
    my $client = $self->{client};
    my $env  = shift;
    my %query_string;
    for my $query_string (split(/&/,$env->{QUERY_STRING} )){
        my($key,$value) = split /=/,$query_string;
        $query_string{$key} = $value;
    }  
    my $uin;
    if(defined $query_string{qq}){
        $uin = $client->get_uin_from_qq($query_string{qq});
    }
    else{
        $uin = $query_string{uin};
    }
    my $content = uri_unescape($query_string{content});   
    my $gid ;
    if(defined $query_string{number}){
        $gid = $client->get_uin_from_number($query_string{number});
    }
    else{
        $gid = $query_string{gid};   
    }
    my $did = $query_string{did};   

    return sub {
        my $responder = shift;
        my $msg = $client->create_sess_msg(to_uin=>$uin,content=>$content,gid=>$gid,did=>$did);
        $msg->{cb} = sub{
            my($msg,$is_success,$status) = @_;
            my $res = {
                msg_id  =>  $msg->{msg_id},
                code    =>  $is_success,
                status  =>  decode("utf8",$status),
            };
            my $json = JSON->new->utf8->encode($res);
            $responder->([
                200,
                ['Content-Type' => 'text/plain'],
                [$json],
            ]);
        };
        $client->send_sess_message($msg);
    };
}
1;
