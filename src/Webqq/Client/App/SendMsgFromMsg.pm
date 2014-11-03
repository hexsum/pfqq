package Webqq::Client::App::SendMsgFromMsg;
use Webqq::Client::Util qw(console);
use Exporter 'import';
@EXPORT = qw(SendMsgFromMsg);
my %GROUP_MARKNAME = qw(
    test    IT狂人  
    a       PERL学习交流
    b       perl技术
    c       PERL
);

sub SendMsgFromMsg{
    my $msg = shift;
    my $client = shift; 
    if($msg->{content} =~/^(?::m)(?:\n|[\t ]+)(.*?)(?:\n^|[\t ]+)(?::e)$/ms){
        my $command = $1;
        open my $fh,"<",\$command or return;
        while(<$fh>){
            chomp;      
            my $line = $_;
            console "从消息接收到发送消息指令: " . $line . "\n";
            my($group,$content) = split(/\s+/,$line,2);
            $group = $GROUP_MARKNAME{$group} if exists $GROUP_MARKNAME{$group};
            my $gid = undef;
            for(@{$client->{qq_database}{group_list}}){
                if($_->{name} eq $group or $_->{markname} eq $group){
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
        
        close $fh;
    }
}

1;
