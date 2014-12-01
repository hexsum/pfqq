package Webqq::Client::App::SmartReply;
use Exporter 'import';
use JSON;
use AE;
use Encode;
use POSIX qw(strftime);
use Webqq::Client::Util qw(truncate console);
@EXPORT=qw(SmartReply);
my $API = 'http://www.tuling123.com/openapi/api';
my %limit;
my @limit_reply = (
    "好累，让我休息下",
    "能让我休息会不",
    "对不起，请不要这么频繁的提问题",
    "对不起，您的提问次数太多",
    "说这么多话不累么，请休息几分钟",
    "能不能小窗\@我啊，别吵着大家",
);
#my $API = 'http://www.xiaodoubi.com/bot/api.php?chat=';
my $once = 1;
sub SmartReply{
    my $msg = shift;
    my $client = shift;
    return unless $msg->{content} =~/\@小灰 /;
    my $userid = $msg->from_qq;
    my $msg_type = $msg->{type};
    my $from_nick;
    my $from_city;
    if($msg->{type} eq 'group_message'){
        $from_nick = $msg->from_card || $msg->from_nick;
        $from_city = $msg->from_city;
    }
    else{
        $from_nick = $msg->from_nick;
    }
    
    my $cur_time = strftime("%H:%M",localtime(time));
    $limit{$cur_time}{$userid}++ if $msg->{type} eq 'group_message';
    if($limit{$cur_time}{$userid} > 3 and $msg->{type} eq 'group_message'){
        $client->reply_message($msg,"\@$from_nick " . $limit_reply[int rand($#limit_reply+1)]);
        return;
    }

    my $input = $msg->{content};
    $input=~s/\@[^ ]+ |\[[^\[\]]+\]\x01|\[[^\[\]]+\]//g;
    my @query_string = (
        "key"       =>  "4c53b48522ac4efdfe5dfb4f6149ae51",
        "userid"    =>  $userid,
        "info"      =>  $input,
    );
    push @query_string,(loc=>$from_city."市") if $from_city;
    my @query_string_pairs;
    push @query_string_pairs , shift(@query_string) . "=" . shift(@query_string) while(@query_string);
    $client->{asyn_ua}->get($API . "?" . join("&",@query_string_pairs),(),sub{
        my $res =shift;
        if($client->{debug}){
            print "GET " . $API . "?" . join("&",@query_string_pairs),"\n";
            print $res->as_string,"\n";
        }
        my $reply;
        my $data = JSON->new->utf8->decode($res->content);
        return if $data->{code}=~/^4000[1-7]$/;
        if($data->{code} == 100000){
            $reply = encode("utf8",$data->{text});
        } 
        elsif($data->{code}== 200000){
            $reply = encode("utf8","$data->{text}\n$data->{url}");
        }
        $reply  = "\@$from_nick " . $reply  if rand(100)>20;
        $reply = truncate($reply,max_bytes=>300,max_lines=>5) if $msg_type eq 'group_message';
        $client->reply_message($msg,$reply) if $reply;
    });
 
    if($once){
        $client->{watchers}{rand()} = AE::timer 60,60,sub{
            my $key = strftime("%H:%M",localtime(time-120));
            #console "删除\%limit的key: $key\n" if $client->{debug};
            delete $limit{$key};
        };
        $once = 0;
    }       
}
1;
