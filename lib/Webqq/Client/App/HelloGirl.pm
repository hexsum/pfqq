package Webqq::Client::App::HelloGirl;
use Exporter 'import';
use AE;
@EXPORT=qw(HelloGirl);
my @hello = (
    "希望你在群里开心愉快,有问题我们会尽快帮忙解决",
    "有问题尽管问哦，谁敢欺负你找灰灰",
    "\@全体成员 难得女生发问，请大家尽快帮忙解决",
);
my %last;
sub HelloGirl{
    my ($msg,$client) = @_;
    if($msg->{type} eq 'group_message'){
        my $gender = $client->search_member_in_group($msg->{group_code},$msg->{send_uin})->{gender};
        if($gender eq 'female'){
            my $from_nick = $msg->from_nick;
            my $from_qq   = $msg->from_qq;
            if(exists $last{$from_qq} and time - $last{$from_qq} < 3600){
                return;
            }
            $client->reply_message($msg,"\@$from_nick " . $hello[int rand($#hello+1)]);      
            my $watcher = rand();
            $client->{watchers}{$watcher} = AE::timer 600,0,sub{
                delete $client->{watchers}{$watcher};
                $client->reply_message($msg,"\@$from_nick " . "你刚才聊到的内容，如果包含问题，有解决没");
            };     
            $last{$from_qq} = time;
            return;
        }
    };     
}
1;
