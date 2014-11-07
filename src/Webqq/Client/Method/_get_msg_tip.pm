use Webqq::Client::Util qw(console);
sub Webqq::Client::_get_msg_tip{
    my $self = shift;
    my $ua = $self->{asyn_ua}; 
    my $api_url = 'http://web2.qq.com/web2/get_msg_tip';
    my @headers = (
        Referer =>  'http://web2.qq.com/webqq.html',
        'Content-Type'  =>  'utf-8',
    ); 
    my @query_string = (
        uin     =>  undef,
        tp      =>  1,
        id      =>  0,
        retype  =>  1,  
        rc      =>  $self->{qq_param}{rc}++,
        lv      =>  3,
        t       =>  time,
    );

    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    print $api_url.'?'.join("&",@query_string_pairs),"\n" if $self->{debug};
    $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers,sub{
        my $response  = shift;
        console "心跳检测\n" if $self->{debug};
    });
}
1;
