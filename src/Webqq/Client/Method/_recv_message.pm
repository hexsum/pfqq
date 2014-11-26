sub Webqq::Client::_recv_message{
    my $self = shift;
    my $ua = $self->{asyn_ua};
    my $callback = $self->{on_receive_message};
    my $api_url = 'http://d.web2.qq.com/channel/poll2';
    $callback = sub {
        my $response = shift;
        print $response->content() if $self->{debug};
        #分析接收到的消息，并把分析后的消息放到接收消息队列中
        $self->parse_receive_msg($response->content());
        #重新开始接收消息
        my $rand_watcher_id = rand();
        $self->{watchers}{$rand_watcher_id} = AE::timer 2,0,sub{
            delete $self->{watchers}{$rand_watcher_id};
            $self->_recv_message();
        };
    };

    my %r = (
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
        key         =>  undef,
    );
    if($self->{type} eq 'webqq'){
        $r{key} = 0;
        $r{ids} = [];
    }
    my $post_content = [
        r           =>  JSON->new->encode(\%r),
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

    my @headers = $self->{type} eq 'webqq'? (Referer=>"http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3")
                :                           (Referer=>"http://d.web2.qq.com/proxy.html?v=20130916001&callback=1&id=2")
                ;
    $ua->post(
        $api_url,   
        $post_content,
        @headers,
        $callback
    );
     
}
1;
