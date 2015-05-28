use Digest::MD5 qw(md5 md5_hex);
use Webqq::Client::Util qw(console);
use Webqq::Encryption qw(pwd_encrypt pwd_encrypt_js);
sub Webqq::Client::_login1{ 
    console "尝试进行登录(阶段1)...\n";
    my $self = shift;
    my $encrypt_method = $self->{encrypt_method} || "js";
    my $ua = $self->{ua};
    my $api_url = 'https://ssl.ptlogin2.qq.com/login';
    my @headers = $self->{type} eq 'webqq'? (Referer => 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=5&mibao_css=m_webqq&appid=1003903&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fweb2.qq.com%2Floginproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20140612002')
                :                           (Referer => 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001')
                ;

    my $passwd;

    if($self->{type} eq 'webqq'){
        $md5_salt = eval qq{"$self->{qq_param}{md5_salt}"};
        $passwd = pack "H*",$self->{qq_param}{pwd};
        $passwd = uc md5_hex( uc(md5_hex( $passwd . $md5_salt)) . uc( $self->{qq_param}{verifycode}  ) );

    }
    else{
        eval{
            if($encrypt_method eq "perl"){
                $passwd = pwd_encrypt($self->{qq_param}{pwd},$self->{qq_param}{md5_salt},$self->{qq_param}{verifycode},1) ;
            }
            else{
                $passwd = pwd_encrypt_js($self->{qq_param}{pwd},$self->{qq_param}{md5_salt},$self->{qq_param}{verifycode},1) ;
            }
        };
        if($@){
            console "客户端加密算法执行错误：$@\n";
            return $encrypt_method eq "perl"?-2:-3;
        }
    }
    my $query_string_ul = $self->{type} eq 'webqq'? 'http%3A%2F%2Fweb2.qq.com%2Floginproxy.html%3Flogin2qq%3D1%26webqq_type%3D10'
                        :                           'http%3A%2F%2Fw.qq.com%2Fproxy.html%3Flogin2qq%3D1%26webqq_type%3D10'       
                        ;
    my $query_string_action = $self->{type} eq 'webqq' ? '3-14-15279'
                            :                            '0-23-19230'
                            ;

    
    my @query_string = (
        u               =>  $self->{qq_param}{qq},
        p               =>  $passwd,
        verifycode      =>  $self->{qq_param}{verifycode},
        webqq_type      =>  10,
        remember_uin    =>  1,
        login2qq        =>  1,
        aid             =>  $self->{qq_param}{g_appid},
        u1              =>  $query_string_ul,
        h               =>  1,
        ptredirect      =>  0,
        ptlang          =>  2052,
        daid            =>  $self->{qq_param}{g_daid},
        from_ui         =>  1,
        pttype          =>  1,  
        dumy            =>  undef,
        fp              =>  'loginerroralert',
        action          =>  $query_string_action,
        mibao_css       =>  $self->{qq_param}{g_mibao_css},
        t               =>  1,
        g               =>  1,
        js_type         =>  0,
        js_ver          =>  $self->{qq_param}{g_pt_version},
        pt_vcode_v1     =>  0,
        pt_verifysession_v1 =>   $self->{qq_param}{verifysession} || $self->search_cookie("verifysession"),
        
    );
    if($self->{type} eq 'webqq'){
        splice @query_string,-4,0,(pt_uistyle => $self->{qq_param}{g_style});
    }
    else{
        splice @query_string,-4,0,(login_sig => $self->{qq_param}{g_login_sig});
        splice @query_string,-4,0,(pt_randsalt => $self->{qq_param}{isRandSalt} );
    }
   
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string) ;

    for(my $i=1;$i<=$self->{ua_retry_times};$i++){
        my $response = $ua->get($api_url.'?'.join("&",@query_string_pairs),@headers );
        if($response->is_success){
            print $response->content() if $self->{debug};
            my $content = $response->content();
            my %d = ();
            @d{qw( retcode unknown_1 api_check_sig unknown_2 status uin )} = $content=~/'(.*?)'/g;
            #ptuiCB('4','0','','0','您输入的验证码不正确，请重新输入。', '12345678');
            #ptuiCB('3','0','','0','您输入的帐号或密码不正确，请重新输入。', '2735534596');
             
            if($d{retcode} == 4){
                console "您输入的验证码不正确，需要重新输入...\n";
                return -1;
            }
            elsif($d{retcode} == 3){
                if($encrypt_method eq "perl"){
                    return -2;
                }
                else{
                    console "您输入的帐号或密码不正确，客户端终止运行...\n";
                    $self->stop();
                }
            }   
            elsif($d{retcode} != 0){
                console "$d{status}，客户端终止运行...\n";
                $self->stop();
            }
            $self->{qq_param}{api_check_sig} = $d{api_check_sig};
            $self->{qq_param}{ptwebqq} = $self->search_cookie('ptwebqq');
            return 1;
        }
    }
    return 0;
}
1;
