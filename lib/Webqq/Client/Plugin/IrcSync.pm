package Webqq::Client::Plugin::IrcSync;
use AnyEvent::IRC::Client;
use List::Util qw(first);
my $irc  = new AnyEvent::IRC::Client;
my $once = 1;
my $join = 0;
sub call {
    my $client   = shift;
    my $msg      = shift;
    my %p        = @_;

    my $channel  = $p{channel} || "#ChinaPerl";
    return 1 if $msg->{type} ne "group_message";
    my $debug    = $client->{debug};
    
    if ($once) {
        my $server   = $p{server} || "irc.freenode.net";
        my $port     = $p{port} || 6667;
        my $nick     = $p{nick} or die "[Webqq::Client::Plugin::IrcSync] nick must be set\n";
        my $user     = $p{user};
        my $real     = $p{real};
        my $password = $p{password};
        $irc->reg_cb(
            registered => sub { print "[Webqq::Client::Plugin::IrcSync] $nick has registered $server:$port\n" if $debug;},
            join       => sub { 
                print "[Webqq::Client::Plugin::IRC] $nick has joined $channel\n" if $debug;
                $join  = 1;
            },
            publicmsg  => sub { 
                my($self,$channel, $ircmsg) = @_;
                my $sender_nick = substr($ircmsg->{prefix},0,index($ircmsg->{prefix},"!~")) || "UnknownNick";
                my $msg_content = $ircmsg->{params}[1];
                return if $ircmsg->{command} ne "PRIVMSG";
                return if $msg_content =~/^[~ ]/;
                #if($client->{debug}){
                #    print "[Webqq::Client::Plugin::IrcSync] \@$sender_nick (in $channel) say: $msg_content\n";
                #}
                my $group = first {$_->{name} eq $p{group_name}} @{$client->{qq_database}{group_list}} or return ;
                $client->send_group_message(
                    to_uin  =>  $group->{gid},
                    content =>  "[${sender_nick}#irc] " . $msg_content
                );
            },
            disconnect => sub { print "[Webqq::Client::Plugin::IrcSync] $nick has quit $server:$port\n" if $debug;},
        );
        $irc->send_srv(JOIN => $channel);
        $irc->connect($server,$port,{nick=>$nick,user=>$user,real=>$real,password=>$password});
        $once = 0;
    }
    return 1 unless $join;
    return 1 if ($msg->{msg_class} eq "send" and $msg->{content}=~/^\[.*#irc\]/);
    my $group_name = $msg->group_name;
    return 1 if $p{group_name} ne $group_name;
    my $msg_sender_nick = $msg->from_nick;
    my $msg_sender_card = $msg->from_card if $msg->{msg_class} eq 'recv';
    my $msg_sender = $msg_sender_card || $msg_sender_nick;
    $msg_sender = "昵称未知" unless defined $msg_sender;
    $msg_sender = $client->{qq_database}{user}{nick} if $msg_sender eq "我";
    for(split /\n/,$msg->{content}){
        $irc->send_msg(PRIVMSG => $channel, "[\@$msg_sender] ". $_);
    }
}
1;
