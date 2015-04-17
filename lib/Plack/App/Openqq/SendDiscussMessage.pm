package Plack::App::Openqq::SendDiscussMessage;
use parent qw(Plack::Component);
use URI::Escape qw(uri_unescape);
use JSON;
use Encode;
sub call{
    my $self = shift;
    my $client = $self->{client};
    my $env  = shift;
    my %query_string;
    for my $query_string (split(/&/,$env->{QUERY_STRING} )){
        my($key,$value) = split /=/,$query_string;
        $query_string{$key} = $value;
    }  
    my $uin = $query_string{uin} || $query_string{did};
    my $content = uri_unescape($query_string{content});   

    return sub {
        my $responder = shift;
        my $msg = $client->create_discuss_msg(to_uin=>$uin,content=>$content);
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
        $client->send_discuss_message($msg);
    };

}
1;
