package Webqq::Client::App::Msgstat;
use Storable qw(retrieve store);
use File::Path qw/mkpath/;
use Webqq::Client::Util qw(console console_stderr);
use Exporter 'import';
@EXPORT = qw(Msgstat Report);

if($^O !~ /linux/){
    console_stderr "Webqq::Client::App::Msgstat只能运行在linux系统上\n";
    exit;
}
mkpath "/tmp/webqq/data",{mode=>0711};

my $msgstat;
my $once = 1;
$msgstat=(-e "/tmp/webqq/data/msgstat")?retrieve("/tmp/webqq/data/msgstat"):{};
sub Msgstat{
    my ($msg,$client,$time,$filter_group) = @_; 
    $time = "17:30" unless defined $time;
    return if $msg->{type} ne 'group_message';
    my $group_code = $msg->group_code;
    my $group_name = $msg->group_name;
    my $from_uin = $msg->{send_uin};
    my $from_nick = $msg->from_nick;
    my $from_card = $msg->from_card;
    return unless $group_name;
    return unless $from_uin;
    #my $from_qq = $msg->from_qq;
    $msgstat->{$group_name}{$from_uin}{nick}=$from_nick;
    $msgstat->{$group_name}{$from_uin}{card}=$from_card;
    $msgstat->{$group_name}{$from_uin}{msg}++;
    $msgstat->{$group_name}{$from_uin}{sys_img}++ if $msg->{content} =~/\[系统表情\]/;
    $msgstat->{$group_name}{$from_uin}{other_img}++ if $msg->{content} =~/\[图片\]/;
    
    if($msg->{content} =~ /^-msgstat/){
        my ($top,$gn) = $msg->{content}=~/^-msgstat\s*(\d*)\s*(.*)$/g;
        $group_name = $gn if $gn;
        my $to_uin = $client->search_group($msg->{group_code})->{gid} || $msg->{from_uin};
        $client->send_group_message(
            $client->create_group_msg(
                to_uin=>$to_uin,
                content=>Report($group_name,$top),
                group_code=>$msg->{group_code},
            )
        );
    }

    if($once){
        $client->{watchers}{rand()} = AE::timer 60,60,sub{
            console "消息统计数据存盘\n";
            store($msgstat,"/tmp/webqq/data/msgstat");
        };
        #my $group_name = "PERL学习交流";
        $client->add_job("群发言排行榜",$time,sub{
            for(@{$client->{qq_database}{group_list}}){
                if(defined $filter_group){
                    next if $_->{name} ne $filter_group;
                }
                my $gid = $_->{gid} ;  
                my $content = Report($_->{name});
                $content =  "群发言排行榜:\n" . $content;
                if(defined $gid and $content){
                    $client->send_group_message(
                        $client->create_group_msg( 
                            to_uin=>$gid,
                            content=>$content,
                            group_code=>$client->get_group_code_from_gid($gid)
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
}

sub Report{
    my $group_name = shift;
    my $top = shift;
    $top = 4 unless $top;
    my $content = "";
    my @sort_uin = 
    sort {$msgstat->{$group_name}{$b}{other_img} <=> $msgstat->{$group_name}{$a}{other_img}}
    keys %{$msgstat->{$group_name}};
    
    my @top5_uin = @sort_uin[0..$top];
    $content .= sprintf("%4s  %4s  %4s  %s\n","消息","图片","纯度","昵称"); 
    for(@top5_uin){
        next if $msgstat->{$group_name}{$_}{other_img} ==0;
        next if $msgstat->{$group_name}{$_}{msg} ==0;
        my $nick = $msgstat->{$group_name}{$_}{card}||$msgstat->{$group_name}{$_}{nick};
        $content .= sprintf("%4s  %4s  %4s  %s\n",
            $msgstat->{$group_name}{$_}{msg},
            $msgstat->{$group_name}{$_}{other_img},
            sprintf("%.1f",($msgstat->{$group_name}{$_}{msg}-$msgstat->{$group_name}{$_}{other_img})*100/$msgstat->{$group_name}{$_}{msg}),
            $nick,  
        );
    } 
    return $content;
}

1;
