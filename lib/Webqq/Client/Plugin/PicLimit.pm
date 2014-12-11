package Webqq::Client::Plugin::PicLimit;
use AE;
use POSIX qw(strftime);
my %limit;
my @limit_reply = (
    "警告，请不要频繁发图",
    "对不起，本群禁止频繁贴图", 
);
my $once = 1;
sub call{
    my $client = shift;
    my $msg = shift;
    return if $msg->{type} ne 'group_message';
    return if $msg->{content} !~ /\[图片\]/;
    my $from_nick = $msg->from_card || $msg->from_nick;
    my $from_qq   = $msg->from_qq;
    #my $group_name = $msg->group_name;
    #my $group_code = $msg->group_code;
    my $key = strftime("%H",localtime(time));     
    $limit{$key}{$msg->{from_uin}}{$from_qq}++;

    if($limit{$key}{$msg->{from_uin}}{$from_qq} >= 3){
       $client->reply_message($msg,"\@$from_nick " . $limit_reply[ int(rand($#limit_reply+1)) ]); 
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
