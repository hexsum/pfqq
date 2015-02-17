use JSON;
use Encode;
use Storable qw(dclone);
sub Webqq::Client::_send_message{
    my($self,$msg) = @_;
    #将整个hash从UTF8还原为unicode
    my $ua = $self->{asyn_ua};
    my $callback = sub{
        my $response = shift;   
        print $response->content() if $self->{debug};
        my $status = $self->parse_send_status_msg( $response->content() );
        if(defined $status and $status->{is_success} == 0){
            $self->send_message($msg);
            return;
        }
        elsif(defined $status){
            if(ref $msg->{cb} eq 'CODE'){
                $msg->{cb}->(
                    $msg,                   #msg
                    $status->{is_success},  #is_success
                    $status->{status}       #status
                );
            }
            if(ref $self->{on_send_message} eq 'CODE'){
                $self->{on_send_message}->(
                    $msg,                   #msg
                    $status->{is_success},  #is_success
                    $status->{status}       #status
                );
            }
        }
    };
    my $api_url = ($self->{qq_param}{is_https}?'https':'http') . '://d.web2.qq.com/channel/send_buddy_msg2';
    my @headers = $self->{type} eq 'webqq'? (Referer=>'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3')
                :                           (Referer=>'http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2')
                ;
    my $content = [decode("utf8",$msg->{content}),"",[]];
    my %s = (
        to      => $msg->{to_uin},
        face    => $self->{qq_database}{user}{face} || 570,
        content => JSON->new->utf8->encode($content),
        msg_id  =>  $msg->{msg_id},
        clientid => $self->{qq_param}{clientid},
        psessionid  => $self->{qq_param}{psessionid},
    );
    $s{content} = decode("utf8",$s{content}); 
    
    if($self->{type} eq 'smartqq'){
        $s{face} = $self->{qq_database}{user}{face} || "591";
    }
    my $post_content = [
        r           =>  JSON->new->utf8->encode(\%s),
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
