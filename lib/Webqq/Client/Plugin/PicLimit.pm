package Webqq::Client::Plugin::PicLimit;
use AE;
use POSIX qw(strftime);
use List::Util qw(first);
my %limit;
my @limit_reply = (
    "警告，请不要频繁发图",
    "对不起，本群禁止频繁贴图", 
);

my @spam_reply = (
    "警告，本群禁止发灌水图",
    "请不要灌水",
);
my $once = 1;
sub call{
    my $client = shift;
    my $msg = shift;
    my $except_qq = shift;
    return if $msg->{type} ne 'group_message';

    #for(@{$msg->{raw_content}}){
    #    next if $_->{type} ne 'cface';
    #    if($_->{name}=~/\.gif$/i){ 
    #        my $from_nick = $msg->from_card || $msg->from_nick;
    #        my $from_qq   = $msg->from_qq;
    #        return if ref $except_qq eq 'ARRAY' and first {$from_qq == $_} @$except_qq ;
    #        $client->reply_message($msg,"\@$from_nick " . $spam_reply[ int(rand($#spam_reply+1)) ]);
    #        return;
    #    }
    #};

    return if $msg->{content} !~ /\[图片\]|\[[^\[\]]+\]\x01/;
    my $from_nick = $msg->from_card || $msg->from_nick;
    my $from_qq   = $msg->from_qq;
    return if ref $except_qq eq 'ARRAY' and first {$from_qq == $_} @$except_qq;
    #my $group_name = $msg->group_name;
    #my $group_code = $msg->group_code;
    my $key = strftime("%H",localtime(time));     
    $limit{$key}{$msg->{from_uin}}{$from_qq}++;

    my $limit = $limit{$key}{$msg->{from_uin}}{$from_qq};   
 
    if($limit >= 3 and $limit <=4){
        $client->reply_message($msg,"\@$from_nick " . $limit_reply[ int(rand($#limit_reply+1)) ]); 
    }
    elsif($limit>=5 and $limit <=6){
        $client->reply_message($msg,"\@$from_nick " . "无视警告，请管理员予以禁言惩罚");
    }
    elsif($limit>6){
        $client->reply_message($msg,"\@$from_nick " . "大量发图，严重影响群内交流，请管理员将此人踢出");
    }

    if($once){
        $client->{watchers}{rand()} = AE::timer 3600,3600,sub{
            my $key = strftime("%H",localtime(time-3600));
            delete $limit{$key};
        };
        $once = 0;
    }
}
1;
