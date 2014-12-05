use JSON;
use Encode;
use Storable qw(dclone);
sub Webqq::Client::_send_group_message{
    my($self,$msg) = @_;
    #将整个hash从UTF8还原回uincode编码
    my $msg_origin = dclone($msg);
    $msg->{$_} = decode("utf8",$msg->{$_} ) for keys %$msg;
    my $ua = $self->{asyn_ua};

    my $send_message_callback = $msg->{cb}||$self->{on_send_message};
    my $callback = sub{
        my $response = shift;
        print $response->content() if $self->{debug};
        my $status = $self->parse_send_status_msg( $response->content() );
        if(ref $send_message_callback eq 'CODE' and defined $status){
            $send_message_callback->(
                $msg_origin,
                $status->{is_success},
                $status->{status},
            );
        } 
    };
    
    my $api_url = 'http://d.web2.qq.com/channel/send_qun_msg2';
    my @headers = $self->{type} eq 'webqq'? (Referer =>'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3')
                :                           (Referer =>'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2')
                ;
    my $content = [$msg->{content},[]];
    my %s = (
        group_uin   => $msg->{to_uin},
        content     => JSON->new->utf8->encode($content),
        msg_id      => $msg->{msg_id},
        clientid    => $self->{qq_param}{clientid},
        psessionid  => $self->{qq_param}{psessionid},
    );
       
    if($self->{type} eq 'smartqq'){
        $s{face} = "591";
    }
    my $post_content = [
        r           =>  decode("utf8",JSON->new->encode(\%s)),
    ]; 
    if($self->{type} eq 'webqq'){
        push @$post_content,(
            clientid    =>  $self->{qq_param}{clientid},
            psessionid  =>  $self->{qq_param}{psessionid}
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
