use Webqq::Client::Util qw(console);
sub Webqq::Client::_check_verify_code{
    console "检查验证码...\n";
    my $self = shift;
    my $ua = $self->{ua};
    my $api_url = 'https://ssl.ptlogin2.qq.com/check';
    my @headers = $self->{type} eq 'webqq'? (Referer=>'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=5&mibao_css=m_webqq&appid=1003903&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fweb2.qq.com%2Floginproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20140612002')
                :                           (Referer=>'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001')
                ;

    my $query_string_ul = $self->{type} eq 'webqq'? 'http%3A%2F%2Fweb2.qq.com%2Floginproxy.html'
                        :                           'http%3A%2F%2Fw.qq.com%2Fproxy.html'
                        ;
    my @query_string = (
        uin         =>  $self->{qq_param}{qq},
        appid       =>  $self->{qq_param}{g_appid},
        js_ver      =>  $self->{qq_param}{g_pt_version},
        js_type     =>  0,
        login_sig   =>  $self->{qq_param}{g_login_sig},
        u1          =>  $query_string_ul,
        r           =>  rand(),
    ); 
    
    if($self->{type} eq 'smartqq'){
        unshift @query_string,(
            pt_tea  => 1,
        );
    }
    
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);

    $ua->cookie_jar()->set_cookie(0,"chkuin",$self->{qq_param}{qq},"/","ptlogin2.qq.com",);    

    for(my $i=1;$i<=$self->{ua_retry_times};$i++){
        my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers);
        if($response->is_success){
            my $content = $response->content();
            print $content,"\n" if $self->{debug};
            my %d = ();
            @d{qw( retcode cap_cd md5_salt verifysession isRandSalt)} = $content=~/'(.*?)'/g ;
            $d{md5_salt} =~ s/\\\\x/\x/g; 
            #$self->{qq_param}{md5_salt} = eval qq{"$d{md5_salt}"};
            $self->{qq_param}{md5_salt} = $d{md5_salt};
            $self->{qq_param}{cap_cd} = $d{cap_cd};
            $self->{qq_param}{verifysession} = $d{verifysession};
            $self->{qq_param}{isRandSalt}   = $d{isRandSalt};
            if($d{retcode} ==0){
                console "检查结果: 很幸运，本次登录不需要验证码\n";
                $self->{qq_param}{verifycode} = $d{cap_cd};
            }
            elsif($d{retcode} == 1){
                console "检查结果: 需要输入图片验证码\n";
                $self->{qq_param}{is_need_img_verifycode} = 1
            }
            
            return 1;
        }
    }
    return 0;
}
1;
