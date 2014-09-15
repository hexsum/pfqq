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
        $self->_recv_message();
    };

    my %r = (
        clientid    =>  $self->{qq_param}{clientid},
        psessionid  =>  $self->{qq_param}{psessionid},
        key         =>  0,
        ids         =>  [],
    );

    my @headers = (Referer=>"http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3",);
    $ua->post(
        $api_url,
        [
            r           =>  JSON->new->encode(\%r),
            clientid    =>  $self->{qq_param}{clientid},
            psessionid  =>  $self->{qq_param}{psessionid}
        ],
        @headers,
        $callback
    );
     
}
1;
