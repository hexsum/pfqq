use JSON;
use Encode;
use Storable qw(dclone);
sub Webqq::Client::_send_discuss_message {
    my $self = shift;
    return if $self->{type} ne 'smartqq';
    my $msg = shift;
    my $msg_clone = dclone($msg);  

    my $ua = $self->{asyn_ua};
    my $api_url = 'http://d.web2.qq.com/channel/send_discu_msg2';

    my $send_message_callback = $msg->{cb} || $self->{on_send_message};
    my $callback = sub{
        my $response = shift;   
        print $response->content(),"\n" if $self->{debug};
        my $status = $self->parse_send_status_msg( $response->content() );
        if(defined $status and $status->{is_success} == 0){
            $self->send_discuss_message($msg);
            return;
        }
        elsif(defined $status and ref $send_message_callback eq 'CODE'){
            $send_message_callback->(
                $msg,                   #msg
                $status->{is_success},  #is_success
                $status->{status}       #status
            );
        }
    };

    my @headers = (
        Referer => 'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2',
    ); 

    my $content = [decode("utf8",$msg_clone->{content}),"",[]];
    my %s = (
        did         => $msg_clone->{did} || $msg_clone->{to_uin},
        face        => $self->{qq_database}{user}{face} || 591,
        content     => JSON->new->utf8->encode($content),
        msg_id      => $msg_clone->{msg_id},
        clientid    => $self->{qq_param}{clientid},
        psessionid  => $self->{qq_param}{psessionid},
    );
    my $post_content = [
        r           =>  decode("utf8",JSON->new->encode(\%s)),
    ];
    
    if($self->{debug}){
        require URI;
        my $uri = URI->new('http:');
        $uri->query_form($post_content);    
        print $api_url,"\n";
        print $uri->query(),"\n";
    }

    $ua->post(
        $api_url,
        $post_content,
        @headers,
        $callback,
    );
 
}
1;
