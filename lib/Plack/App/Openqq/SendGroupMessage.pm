package Plack::App::Openqq::SendGroupMessage;
use parent qw(Plack::Component);
use URI::Escape qw(uri_unescape);
use AE;
use JSON;
sub call{
    my $self = shift;
    my $client = $self->{client};
    my $env  = shift;
    my %query_string;
    for my $query_string (split(/&/,$env->{QUERY_STRING} )){
        my($key,$value) = split /=/,$query_string;
        $query_string{$key} = $value;
    }  
    my $uin = $query_string{uin};
    my $content = uri_unescape($query_string{content});   
    my $cb = uri_unescape($query_string{cb});
    my $msg = $client->create_group_msg(to_uin=>$uin,content=>$content);
    $msg->{cb} = sub{
       my($msg,$is_success,$status) = @_;
       $client->post($cb,[msg_id=>$msg->{msg_id},is_success=>$is_success,status=>$status],sub{return}); 
    } if defined $cb;
    $client->send_group_message($msg);
    my $status = {
        msg_id      =>  $msg->{msg_id},
    };
    my $json = JSON->new->utf8->encode($status);
    return [
        200,
        ['Content-Type' => 'text/plain'],
        [$json],
    ];
}

1;
