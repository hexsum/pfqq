package Webqq::Client::App::SmartReply;
use Exporter 'import';
use JSON;
use Encode;
@EXPORT=qw(SmartReply);
my $API = 'http://www.tuling123.com/openapi/api';
#my $API = 'http://www.xiaodoubi.com/bot/api.php?chat=';
sub SmartReply{
    my $msg = shift;
    my $client = shift;
    return unless $msg->{content} =~/\@小灰/;
    my $input = $msg->{content};
    my $userid = $msg->from_qq;
    $input=~s/\@小灰//;
    my @query_string = (
        "key"       =>  "4c53b48522ac4efdfe5dfb4f6149ae51",
        "userid"    =>  $userid,
        "info"      =>  $input,
    );
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    my $res;
    eval{
        local $SIG{ALRM} = sub{die "timout\n"};
        alarm 5;
        $res = $client->{ua}->get($API . "?" . join("&",@query_string_pairs));
        alarm 0;
    };
    print "Webqq::Client::App::SmartReply请求超时\n" if $@ and $client->{debug}; 
    if($res->is_success){
        print $res->content,"\n" if $client->{debug};
        my $reply;
        my $data = JSON->new->utf8->decode($res->content);
        return if $data->{code}=~/^4000[1-7]$/;
        if($data->{code} == 100000){
            $reply = encode("utf8",$data->{text});
        } 
        elsif($data->{code}== 200000){
            $reply = encode("utf8","$data->{text}\n$data->{url}");
        }
        $client->reply_message($msg,$reply) if $reply;
    }
    else{return }
     
}
1;
