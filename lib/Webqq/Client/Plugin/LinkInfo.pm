package Webqq::Client::Plugin::LinkInfo;
use HTML::Parser;
use Webqq::Client::Util qw(console);
use Date::Parse;
use POSIX qw(strftime);
use Encode;
sub call{
    my $client = shift;
    my $msg = shift;
    if($msg->{content}=~m#(https?://[^/]+[^\s\x80-\xff]+)#s){
        my $url = $1;       
        print "HEAD $url\n" if $client->{debug};
        $client->{asyn_ua}->head($url,(),sub{
            my $response = shift;
            return if !$response->is_success;
            if($response->header("content-type") !~ /text\/html/){
                print "$url [not-text/html]\n";
                return;
            }
            print "GET $url\n" if $client->{debug};
            $client->{asyn_ua}->get($url,(),sub{
                my $response = shift;
                return if !$response->is_success;
                return if $response->header("content-type") !~ /text\/html/;
                my $charset ;
                if($response->header("content-type")=~/charset\s*=\s*(utf\-?8|gb2312|gbk|gb18030)/i){
                    $charset = $1; 
                }
                elsif($response->content()=~/<meta.*?charset\s*=\s*(utf\-?8|gb2312|gbk|gb18030)/si){
                    $charset = $1;
                }
                else{
                    return;
                }

                return unless defined $charset;
                console "获取 $url 编码信息[$charset]\n" if $client->{debug};
                my $p=HTML::Parser->new;
                $p->ignore_elements(qw(script style a img));
                #$p->report_tags(qw(div p));
                $p->utf8_mode(0);

                my $is_title = 0;
                my $title;
                my $content; 
                my $expires = $response->header("last-modified");
                if(defined $expires){
                    $expires = strftime('%c',localtime(str2time($expires)));
                    $expires =~s/ \d+时\d+分\d+秒$//;
                }
            
                $p->handler(start=>sub{
                    my $tagname = shift;
                    $is_title=($tagname eq 'title'?1:0);  
                    $p->handler(text=>sub{my $text = shift;$is_title?($title .=$text):($content .= $text);},"text");
                },"tagname");

                my $html;
                if($charset=~/^gb/i){
                    $html = decode("gb2312",$response->content);
                }
                elsif($charset=~/^utf/i){
                    $html = decode("utf8",$response->content);
                }
                $p->parse($html);
                $p->eof;
                $title=~s/\s+|&[^&;]+;/ /g;
                $content=~s/\s+|&[^&;]+;/ /g;

                return unless $title;
                return unless $content;

                $title = substr($title,0,100) . (length($title)>100?"...":"");
                $content = substr($content,0,100) . "...";

                $url = substr($url,0,50) . (length($url)>50?"...":"");
                
                $title = "【网页标题】" . encode("utf8",$title);
                $expires = "【更新时间】" . $expires . "\n" if defined $expires;
                $content = "【网页正文】" . encode("utf8",$content);
                
                $client->reply_message($msg,"$title\n${expires}$content\n$url");
            });
        });
    }
}
1;
