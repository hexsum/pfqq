package Webqq::Client::Plugin::MsgSync;
use strict;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use List::Util qw(first);
use Webqq::Client::Util qw(truncate);
my $irc_client  = new AnyEvent::IRC::Client;
my $once = 1;
my $is_irc_join = 0;
my $debug = 0;

my $irc = {};
my $group_name = [];

my @group_list ;
sub call {
    my $client   = shift;
    my $msg      = shift;
    $debug = $client->{debug};
    my %p = @_;
    $group_name = $p{group};
    if($group_name eq "all"){
        @group_list = @{$client->{qq_database}{group_list}};
    }
    elsif(ref $group_name eq "ARRAY"){
        @group_list = ();
        for my $g (@{$client->{qq_database}{group_list}}){
            push @group_list,$g if first {$g->{name} eq $_} @$group_name;
        }
    }
    
    if ($once) {
        $irc = $p{irc};
        if(defined $irc){
            $irc->{server}  = "irc.freenode.net" unless defined $irc->{server};
            $irc->{port}    = 6667 unless defined $irc->{port};
            $irc->{channel}    = "#ChinaPerl" unless defined $irc->{channel};
            die "[".__PACKAGE__."] irc nick must be set\n" unless defined $irc->{nick};
            $irc_client->reg_cb(
                registered => sub { 
                    print "[".__PACKAGE__."] $irc->{nick} has registered $irc->{server}:$irc->{port}\n" if $debug;
                    $irc_client->send_msg(JOIN=>$irc->{channel});
                },
                join       => sub { 
                    print "[".__PACKAGE__."] $irc->{nick} has joined $irc->{channel}\n" if $debug;
                    $is_irc_join  = 1;
                },
                publicmsg  => sub { 
                    my($self,$channel, $ircmsg) = @_;
                    my $sender_nick = prefix_nick($ircmsg) || "UnknownNick";
                    my $msg_content = $ircmsg->{params}[1];
                    return if $ircmsg->{command} ne "PRIVMSG";
                    return if $msg_content =~/^[~ ]/;
                    #if($debug){
                    #    print "[".__PACKAGE__."] \@$sender_nick (in $channel) say: $msg_content\n";
                    #}
                    for(@group_list){
                        $client->send_group_message(
                            to_uin  =>  $_->{gid},
                            content =>  "[${sender_nick}#irc] " . $msg_content
                        );
                    }
                },
                disconnect => sub { 
                    print "[".__PACKAGE__."] $irc->{nick} has quit $irc->{server}:$irc->{port}\n" if $debug;
                    $irc_client->connect(
                        $irc->{server},
                        $irc->{port},   
                        {nick=>$irc->{nick},user=>$irc->{user},real=>$irc->{real},password=>$irc->{password}},
                    );
                },
            );
            $irc_client->connect(
                $irc->{server},
                $irc->{port},
                {nick=>$irc->{nick},user=>$irc->{user},real=>$irc->{real},password=>$irc->{password}},
            ); 
        }
        $client->{watchers}{rand()} = AE::timer 600,60,sub {
            if($irc_client->registered()){
                unless(defined $irc_client->channel_list($irc->{channel})){
                    $is_irc_join = 0;
                    $irc_client->send_msg(JOIN=>$irc->{channel}) ;
                }
            }
            else{
                $is_irc_join = 0;
                $irc_client->connect(
                    $irc->{server},
                    $irc->{port},
                    {nick=>$irc->{nick},user=>$irc->{user},real=>$irc->{real},password=>$irc->{password}},
                )
            }
        };
        $once = 0;
    }
    return 1 if ($msg->{msg_class} eq "send" and $msg->{content}=~/^\[.*?#.+?\]/);
    return 1 if $msg->{type} ne 'group_message';
    my $gn = $msg->group_name;
    return 1 unless first {$gn eq $_} @$group_name;
    my $msg_sender_nick = $msg->from_nick;
    my $msg_sender_card = $msg->from_card if $msg->{msg_class} eq 'recv';
    my $msg_sender = $msg_sender_card || $msg_sender_nick;
    $msg_sender = "昵称未知" unless defined $msg_sender;
    $msg_sender = $client->{qq_database}{user}{nick} if $msg_sender eq "我" and $msg->{msg_class} eq 'send';


    for(grep {$gn ne $_->{name}} @group_list){
        $client->send_group_message(
            to_uin  =>  $_->{gid},
            content =>  "[${msg_sender}#$gn] " . $msg->{content}
        );      
    }

    if($is_irc_join){
        for(split /\n/,truncate($msg->{content},max_bytes=>2000,max_lines=>10) ){
            $irc_client->send_msg(PRIVMSG => $irc->{channel}, "[$msg_sender] ". $_);
        }
    }
}
1;
