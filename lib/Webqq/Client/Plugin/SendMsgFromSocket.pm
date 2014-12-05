package Webqq::Client::Plugin::SendMsgFromSocket;
use Webqq::Client::Util qw(console);
use AnyEvent::Socket;
sub call{
    my $c = shift;
    tcp_server "unix/", "send_message", sub {
        my ($fh,) = @_;
        my $client  = $c;
        while(<$fh>){
            chomp;
            my $line = $_;
            console "从管道接收到发送消息指令: " . $line . "\n";
            my($group_name,$content) = split(/\s+/,$line,3); 
            my $gid = undef;
            for(@{$client->{qq_database}{group_list}}){
                if($_->{name} eq $group_name){
                    $gid = $_->{gid} ;
                    last;
                }
            }
        
            if(defined $gid){
                $client->send_group_message(
                    $client->create_group_msg( to_uin=>$gid,content=>$content)
                );
            }


        } 
    };
}

1;
