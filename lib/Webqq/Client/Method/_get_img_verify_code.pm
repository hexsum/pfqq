use File::Temp qw/tempfile/;
use Webqq::Client::Util qw(console);
sub Webqq::Client::_get_img_verify_code{
    my $self = shift;
    if ($self->{qq_param}{is_need_img_verifycode} == 0){
        $self->{qq_param}{img_verifycode_source} = 'NONE';
        return 1 ;
    }
    my $ua = $self->{ua};
    my $api_url = 'https://ssl.captcha.qq.com/getimage';
    my @headers = $self->{type} eq 'webqq'? (Referer => 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=5&mibao_css=m_webqq&appid=1003903&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fweb2.qq.com%2Floginproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20140612002')
                :                           (Referer => 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001')
                ;
    my @query_string = (
        aid        => $self->{qq_param}{g_appid},
        r          => rand(),
        uin        => $self->{qq_param}{qq}, 
        cap_cd     => $self->{qq_param}{cap_cd},
    );    

    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string) ;
   
    for(my $i=1;$i<=$self->{ua_retry_times};$i++){ 
        my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
        if($response->is_success){
            my ($fh, $filename) = tempfile("webqq_img_verfiy_XXXX",SUFFIX =>".jpg",TMPDIR => 1);
            binmode $fh;
            print $fh $response->content();
            close $fh; 
            if(-t STDIN){
                console "请输入图片验证码 [ $filename ]: ";
                chomp($self->{qq_param}{verifycode} = <STDIN>);
                $self->{qq_param}{img_verifycode_source} = 'TTY';
            }
            elsif(ref $self->{on_input_img_verifycode} eq 'CODE'){
                my $code = $self->{on_input_img_verifycode}->($filename);
                if(defined $code){
                    $self->{qq_param}{verifycode} = $code;
                    $self->{qq_param}{img_verifycode_source} = 'CALLBACK';
                }
                else{console "无法从回调函数中获取有效的验证码，客户端终止\n";$self->stop();}
            }
            else{
                console "STDIN未连接到tty，无法输入验证码，客户端终止...\n";
                $self->stop();
            }
            return 1;
        }
    }
    return 0;
}
1;
