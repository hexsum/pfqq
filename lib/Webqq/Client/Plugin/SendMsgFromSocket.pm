package Webqq::Client::Plugin::SendMsgFromSocket;
use Webqq::Client::Util qw(console);
use AnyEvent::Socket;
use AnyEvent::Handle;
my %connection;
sub call{
    my $client = shift;
    tcp_server "127.0.0.1", 2014, sub {
        my($fh,$host,$port) = @_;
        my $client_id = rand();
        $connection{$client_id}[0] = $fh;
        my $hdl; $hdl = AnyEvent::Handle->new(
            fh  => $fh ,
            on_error => sub {
                my ($hdl, $fatal, $msg) = @_;
                $hdl->destroy;
                delete $client{$client_id};
            },
        );
        $connection{$client_id}[1] = $hdl;
        $hdl->push_read (line => sub {
            my ($hdl, $line) = @_;
            delete $connection{$client_id};
            console "从socket接收到发送消息指令: $line\n";
            my($type,$uin,$content) = split(/\s+/,$line,3);
            if($type eq 'group'){
                my $gcode = $client->get_group_code_from_gid($uin);
                unless(defined $gcode){
                    console "指定的群不存在,指令无效: $line\n";
                    return;
                }
                $client->send_group_message(to_uin=>$uin,content=>$content);
            }
            elsif($type eq 'friend'){
                my $f =  $client->search_friend($uin);
                unless(defined $f){
                    console "指定的好友不存在,指令无效: $line\n";
                    return;
                }
                $client->send_message(to_uin=>$uin,content=>$content);
            } 
            elsif($type eq 'discuss'){
                my $d =  $client->search_discuss($uin);
                unless(defined $d){
                    console "指定的讨论组不存在,指令无效: $line\n";
                    return;
                }
                $client->send_discuss_message(to_uin=>$uin,content=>$content);
            }
            elsif($type eq 'group_sess'){
                my($to_uin,$gid) = split /:/,$uin,2;
                my $gcode = $client->get_group_code_from_gid($gid);
                my $m = $client->search_member_in_group($gcode,$to_uin);
                unless(defined $m){
                    console "指定的群或群成员不存在,指令无效: $line\n";
                    return;
                }
                $client->send_sess_message(to_uin=>$to_uin,content=>$content,gid=>$gid);  
            }
            elsif($type eq 'discuss_sess'){
                my($to_uin,$did) = split /:/,$uin,2;
                my $m = $client->search_member_in_discuss($did,$to_uin);
                unless(defined $m){
                    console "指定的讨论组或讨论组成员不存在,指令无效: $line\n";
                    return;
                }
                $client->send_sess_message(to_uin=>$to_uin,content=>$content,did=>$did);
            }
        });
        
    };
}


1;
