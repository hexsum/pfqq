use URI::Escape qw(uri_escape);
use Webqq::Client::Util qw(console);
sub Webqq::Client::_prepare_for_login{
    my $self = shift;
    console "初始化 $self->{type} 客户端参数...\n";
    my $ua = $self->{ua};
    my $webqq_api_url = 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=5&mibao_css=m_webqq&appid=1003903&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fweb2.qq.com%2Floginproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20140612002';
    
    my $smartqq_api_url = 'https://ui.ptlogin2.qq.com/cgi-bin/login?daid=164&target=self&style=16&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2Fw.qq.com%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001';
    
    my $api_url = $self->{type} eq 'webqq'? $webqq_api_url
                :                           $smartqq_api_url
                ;  
    my @headers = $self->{type} eq 'webqq'? (Referer=>'http://web2.qq.com/webqq.html')
                :                           (Referer=>'http://w.qq.com/')
                ;
    my @global_param = qw(
        g_pt_version
        g_login_sig
        g_style
        g_mibao_css
        g_daid
        g_appid
    );

    my $regex_pattern = 'var\s*(' . join("|",@global_param) . ')\s*=\s*encodeURIComponent\("(.*?)"\)';
    for(my $i=1;$i<=$self->{ua_retry_times};$i++){
        my $response = $ua->get($api_url,@headers);
        if($response->is_success){
            my $content = $response->content();
            my %kv = map {uri_escape($_)} $content=~/$regex_pattern/g ;        
            for(keys %kv){
                $self->{qq_param}{$_} = $kv{$_};
            }
            return 1;
        }
    }
    return 0;
}
1;
