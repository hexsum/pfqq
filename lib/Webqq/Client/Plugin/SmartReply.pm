package Webqq::Client::Plugin::SmartReply;
use JSON;
use AE;
use Encode;
use POSIX qw(strftime);
use Webqq::Client::Util qw(truncate console);
my $API = 'http://www.tuling123.com/openapi/api';
my %limit;
my %ban;
my @limit_reply = (
    "对不起，请不要这么频繁的提问题",
    "对不起，您的提问次数太多",
    "说这么多话不累么，请休息几分钟",
    "能不能小窗我啊，别吵着大家",
);
#my $API = 'http://www.xiaodoubi.com/bot/api.php?chat=';
my $once = 1;
sub call{
    my $client = shift;
    my $msg = shift;
    return if $msg->{allow_plugin} == 0;
    my $msg_type = $msg->{type};    
    if($msg_type eq 'group_message'){
        return 1  if $msg->{content} !~/\@小灰/;
    }
    my $userid = $msg->from_qq;
    return 1 if exists $ban{$userid};

    my $from_nick;
    my $from_city = $msg->from_city if $msg->{type} ne 'sess_message';
    if($msg->{type} eq 'group_message'){
        $from_nick = $msg->from_card || $msg->from_nick;
    }
    else{
        $from_nick = $msg->from_nick;
    }
    
    if($msg->{type} eq 'group_message'){
        my $key = strftime("%H:%M",localtime(time));
        $key=~s/[0-9]$//;
        $limit{$key}{$msg->{from_uin}}{$userid}++;

        my $limit = $limit{$key}{$msg->{from_uin}}{$userid};
        if($limit>=3 and $limit<=4){
            $client->reply_message($msg,"\@$from_nick " . $limit_reply[int rand($#limit_reply+1)]);
            return 1;
        }
    
        if($limit >=5 and $limit <=6){
            $client->reply_message($msg,"\@$from_nick " . "警告，您提问过于频繁，即将被列入黑名单，请克制\n");
            return 1;
        }

        if($limit > 6){
            $ban{$userid} = 1;
            $client->reply_message($msg,"\@$from_nick " . "您已被列入黑名单，10分钟内提问无视\n");
            my $watcher = rand();
            $client->{watchers}{$watcher} = AE::timer 600,0,sub{
                delete $client->{watchers}{$watcher};
                delete $ban{$userid};
            };
            return 1;
        }
    }

    my $input = $msg->{content};
    $input=~s/\@[^ ]+ ?|\[[^\[\]]+\]\x01|\[[^\[\]]+\]//g;
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
        return 1 if $data->{code}=~/^4000[1-7]$/;
        if($data->{code} == 100000){
            $reply = encode("utf8",$data->{text});
        } 
        elsif($data->{code}== 200000){
            $reply = encode("utf8","$data->{text}\n$data->{url}");
        }
        else{
            return 1;
        }
        $reply  = "\@$from_nick " . $reply  if $msg_type eq 'group_message' and rand(100)>20;
        $reply = truncate($reply,max_bytes=>300,max_lines=>5) if $msg_type eq 'group_message';
        $client->reply_message($msg,$reply) if $reply;
    });
 
    if($once){
        $client->{watchers}{rand()} = AE::timer 600,600,sub{
            my $key = strftime("%H:%M",localtime(time-600));
            $key =~s/[0-9]$//g;
            #console "删除\%limit的key: $key\n" if $client->{debug};
            delete $limit{$key};
        };
        $once = 0;
    }       

    return 1;
}
1;
