package Webqq::Client::Plugin::HelloGirl;
use AE;
my @hello = (
    "希望你在群里开心愉快,有问题我们会尽快帮忙解决",
    "有问题尽管问哦，谁敢欺负你找管理员",
    "\@全体成员 难得女生发话，有问题请大家尽快帮忙解决",
);
my %last;
sub call{
    my ($client,$msg) = @_;
    if($msg->{type} eq 'group_message'){
        my $gender = $client->search_member_in_group($msg->{group_code},$msg->{send_uin})->{gender};
        if($gender eq 'female'){
            my $from_nick;
            if($msg->{type} eq 'group_message'){
                $from_nick = $msg->{card} || $msg->from_nick;
            }
            else{
                $from_nick = $msg->from_nick;
            }
            
            my $from_qq   = $msg->from_qq;
            if(exists $last{$from_qq} and time - $last{$from_qq} < 3600){
                return 1;
            }
            $client->reply_message($msg,"\@$from_nick " . $hello[int rand($#hello+1)]);      
            my $watcher = rand();
            $client->{watchers}{$watcher} = AE::timer 600,0,sub{
                delete $client->{watchers}{$watcher};
                $client->reply_message($msg,"\@$from_nick " . "还需要什么帮助吗");
            } if rand(100) > 60;     
            $last{$from_qq} = time;
            return 1;
        }
    };     

    return 1;
}
1;
