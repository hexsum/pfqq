use JSON;
use Encode;
use Storable qw(dclone);
sub Webqq::Client::_send_sess_message{
    my($self,$msg) = @_;
    my $msg_origin = dclone($msg);
    $msg->{$_} = decode("utf8",$msg->{$_} ) for keys %$msg;
    my $ua = $self->{asyn_ua};
    my $send_message_callback = $msg->{cb} || $self->{on_send_message};
    my $callback = sub{
        my $response = shift;
        print $response->content() if $self->{debug};
        my $status = $self->parse_send_status_msg( $response->content() );
        if(defined $status and $status->{is_success}==0){
            $self->send_sess_message($msg_origin);
            return;
        } 
        elsif(defined $status and ref $send_message_callback eq 'CODE'){
            $send_message_callback->(
                $msg_origin,                   #msg
                $status->{is_success},  #is_success
                $status->{status}       #status
            );
        }
    };

    my $api_url = 'http://d.web2.qq.com/channel/send_sess_msg2';
    my @headers = $self->{type} eq 'webqq'? (Referer =>  'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3')
                :                           (Referer =>  'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2')
                ;
    my $content = [$msg->{content},[]];
    my %r = (
        to              => $msg->{to_uin}, 
        group_sig       => $msg->{group_sig}, 
        face            => $self->{qq_database}{user}{face} || 591,
        content         => JSON->new->utf8->encode($content),
        msg_id          => $msg->{msg_id},
        service_type    => $msg->{service_type},
        clientid        => $self->{qq_param}{clientid},
        psessionid      => $self->{qq_param}{psessionid},
    );
    
    my $post_content = [
        r           =>  decode("utf8",JSON->new->encode(\%r)),
    ];

    if($self->{type} eq 'webqq'){
        push @$post_content,(
            clientid    =>  $self->{qq_param}{clientid},
            psessionid  =>  $self->{qq_param}{psessionid},
        );
    }

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
