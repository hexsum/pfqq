#将接收到的普通信息和群信息打印到终端
use lib '../src/';
use POSIX qw(strftime);
use Webqq::Client;
use Webqq::Client::Util qw(console);
use Digest::MD5 qw(md5_hex);

my $qq = 12345678;
my $pwd = md5_hex('your password');

sub format_msg{
    my $msg_header  = shift;
    my $msg_content = shift;
    my @msg_content = split /\n/,$msg_content;
    my @msg_header = ($msg_header,(' ' x length($msg_header)) x $#msg_content  );
    while(@msg_content){
        my $lh = shift @msg_header; 
        my $lc = shift @msg_content;
        #你的终端可能不是UTF8编码，为了防止乱码，做下编码自适应转换
        console $lh, $lc,"\n";
    } 
}
my $client = Webqq::Client->new(debug=>0);
$client->login( qq=> $qq, pwd => $pwd);
$client->on_receive_message = sub{
    my $msg = shift;
    if($msg->{type} eq 'group_message'){
        #$msg是一个群消息的hash引用
        #    type       #消息类型
        #    msg_id     #系统生成的消息id
        #    from_uin   #消息来源uin，可以通过这个uin进行消息回复
        #    to_uin     #接受者uin，通常就是自己的qq号
        #    msg_time   #消息发送时间
        #    content    #消息内容
        #    send_uin   #发送者uin
        #    group_code #群的标识
        my $group_name = $client->search_group($msg->{group_code})->{name} ;
        my $msg_sender = $client->search_member_in_group($msg->{group_code},$msg->{send_uin});
        my $msg_sender_nick = $msg_sender->{nick};
        #my $msg_sender_qq   = $client->get_qq_from_uin($msg_sender->{uin});
        format_msg(
                strftime("[%y/%m/%d %H:%M:%S]",localtime($msg->{msg_time}))
            .   "\@$msg_sender_nick(群:$group_name) 说: ",
                $msg->{content}
        );         
    }
    elsif($msg->{type} eq 'message'){
        my $msg_sender = $client->search_friend($msg->{from_uin});
        my $msg_sender_qq = $client->get_qq_from_uin($msg_sender->{uin});
        my $msg_sender_nick = $msg_sender->{nick}; 
        format_msg(
                strftime("[%y/%m/%d %H:%M:%S]",localtime($msg->{msg_time}))
            .   "\@$msg_sender_nick(QQ:$msg_sender_qq) 说: ",
            $msg->{content} 
        );
    }
};
$SIG{INT} = sub{$client->logout();exit;};
$client->run;
