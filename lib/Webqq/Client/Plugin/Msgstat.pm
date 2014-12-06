package Webqq::Client::Plugin::Msgstat;
use Storable qw(retrieve store);
use File::Path qw/mkpath/;
use Webqq::Client::Util qw(console console_stderr);

if($^O !~ /linux/){
    console_stderr "Webqq::Client::App::Msgstat只能运行在linux系统上\n";
    exit;
}
mkpath "/tmp/webqq/data",{mode=>0711};

my $msgstat;
my $once = 1;
$msgstat=(-e "/tmp/webqq/data/msgstat")?retrieve("/tmp/webqq/data/msgstat"):{};
sub call{
    my ($client,$msg,$time,$group_filter) = @_; 
    $time = "17:30" unless defined $time;
    return 1 if $msg->{type} ne 'group_message';
    my $group_code = $msg->group_code;
    my $group_name = $msg->group_name;
    my $from_nick = $msg->from_nick;
    my $from_card = $msg->from_card;
    my $from_qq   = $msg->from_qq;
    
    return 1 unless $group_name;
    return 1 unless $from_qq;

    $msgstat->{$group_name}{$from_qq}{nick}=$from_nick;
    $msgstat->{$group_name}{$from_qq}{card}=$from_card;
    $msgstat->{$group_name}{$from_qq}{msg}++;
    $msgstat->{$group_name}{$from_qq}{sys_img}++ if $msg->{content} =~/\[系统表情\]/;
    $msgstat->{$group_name}{$from_qq}{other_img}++ if $msg->{content} =~/\[图片\]/;
    
    if($msg->{content} =~ /^-msgstat$/ and $from_qq == 308165330){
        my $content = Report($msgstat,$group_name);
        $client->reply_message($msg,$content) if $content;
    }

    if($once){
        $client->{watchers}{rand()} = AE::timer 60,300,sub{
            console "消息统计数据存盘\n" if $client->{debug};
            store($msgstat,"/tmp/webqq/data/msgstat");
        };
        #my $group_name = "PERL学习交流";
        $client->add_job("群发言排行榜",$time,sub{
            for(@{$client->{qq_database}{group_list}}){
                if(defined $group_filter){
                    next if $_->{name} ne $group_filter;
                }
                my $gid = $_->{gid} ;  
                my $content = Report($msgstat,$_->{name});
                $content =  "群发言排行榜:\n" . $content if $content;
                if($gid and $content){
                    $client->send_group_message(
                        $client->create_group_msg( 
                            to_uin=>$gid,
                            content=>$content,
                            group_code=>$_->{code}
                        )
                    );
                }
            }
        });

        $client->add_job("消息统计数据清空","23:59",sub{
            $msgstat = {};
        });
        $once=0;
    }
    return 1;
}

sub Report{
    my $msgstat = shift;
    my $group_name = shift;
    my $top = shift;
    $top>0?($top--):($top=10);
    my $content = "";
    my @sort_qq = 
    sort {$msgstat->{$group_name}{$b}{other_img}<=>$msgstat->{$group_name}{$a}{other_img} or $msgstat->{$group_name}{$b}{other_img}/$msgstat->{$group_name}{$b}{msg} <=> $msgstat->{$group_name}{$a}{other_img}/$msgstat->{$group_name}{$a}{msg}}
    grep {$msgstat->{$group_name}{$_}{msg}!=0}
    keys %{$msgstat->{$group_name}};
    
    my @top_qq = @sort_qq[0..$top];
    for(@top_qq){
        #next if $msgstat->{$group_name}{$_}{other_img} ==0;
        next if $msgstat->{$group_name}{$_}{msg} ==0;
        my $nick = $msgstat->{$group_name}{$_}{card}||$msgstat->{$group_name}{$_}{nick};
        $content .= sprintf("%4s  %4s  %4s  %s\n",
            $msgstat->{$group_name}{$_}{msg}+0,
            $msgstat->{$group_name}{$_}{other_img}+0,
            sprintf("%.1f",($msgstat->{$group_name}{$_}{other_img})*100/$msgstat->{$group_name}{$_}{msg}),
            $nick,  
        );
    } 
    $content = sprintf("%4s  %4s  %4s  %s\n","消息","图片","水度","昵称") . $content if $content;
    return $content;
}

1;
