package Webqq::Client::Plugin::ShowMsg;
use Webqq::Client::Util qw(console);
use POSIX qw(strftime);
use Encode;

sub call{
    my $client = shift;
    my $msg = shift;
    my $attach = shift; 
    if($msg->{type} eq 'group_message'){
        #$msg是一个群消息的hash引用，包含如下key
        
        #    type       #消息类型
        #    msg_id     #系统生成的消息id
        #    from_uin   #消息来源uin，可以通过这个uin进行消息回复
        #    to_uin     #接受者uin，通常就是自己的qq号
        #    msg_time   #消息发送时间
        #    content    #消息内容
        #    send_uin   #发送者uin
        #    group_code #群的标识
       
        #    你可以使用use Data::Dumper;print Dumper $msg来查看$msg的结构
 
        #    $msg使用了Automated accessor generation技术，每个hash的key都同时对应一个get方法
        #    即，你可以使用$msg->{key}或者$msg->key任意一种方式获取你想要的数据
        #    此外，使用$msg->method()的方式，你还会增加几个$msg->{key}没有的数据项
        #    $msg->from_qq
        #    $msg->from_nick
        #    $msg->group_name

        my $group_name = $msg->group_name;
        my $msg_sender_nick = $msg->from_nick;
        my $msg_sender_card = $msg->from_card if $msg->{msg_class} eq 'recv';
        my $msg_sender = $msg_sender_card || $msg_sender_nick;
        $msg_sender = "昵称未知" unless defined $msg_sender;
        #my $msg_sender_qq  = $msg->from_qq;
        format_msg(
                strftime("[%y/%m/%d %H:%M:%S]",localtime($msg->{msg_time}))
            .   "\@$msg_sender(在群:$group_name) 说: ",
                $msg->{content} . $attach
        );         
    }
    #我们多了如下的get数据项
    #   $msg->from_nick
    #   $msg->from_qq
    #   $msg->from_markname
    #   $msg->from_categories
    elsif($msg->{type} eq 'message'){
        my $msg_sender_nick = $msg->from_nick; 
        my $msg_sender_markname = $msg->from_markname if $msg->{msg_class} eq 'recv'; 
        my $msg_sender = $msg_sender_markname || $msg_sender_nick;
        my $msg_receiever_nick = $msg->to_nick;
        my $msg_receiever_markname = $msg->to_markname if $msg->{msg_class} eq 'send';
        my $msg_receiever = $msg_receiever_markname || $msg_receiever_nick;
        $msg_receiever = "昵称未知" unless defined $msg_receiever;
        $msg_sender = "昵称未知" unless defined $msg_sender;
        
        format_msg(
                strftime("[%y/%m/%d %H:%M:%S]",localtime($msg->{msg_time}))
            .   "\@$msg_sender(对好友:\@$msg_receiever) 说: ",
            $msg->{content}  . $attach
        );
    }

    #消息是临时消息
    #   $msg->from_qq
    #   $msg->from_nick
    elsif($msg->{type} eq 'sess_message'){
        my $msg_sender_nick = $msg->from_nick;
        my $msg_receiever_nick = $msg->to_nick;
        my $via_name = $msg->via_name;
        my $via_type = $msg->via_type;
        $msg_sender_nick = "昵称未知" unless defined $msg_sender_nick;
        $msg_receiever_nick= "昵称未知" unless defined $msg_receiever_nick;
        if($msg->{msg_class} eq 'recv'){
            format_msg(
                strftime("[%y/%m/%d %H:%M:%S]",localtime($msg->{msg_time}))
                .   "\@$msg_sender_nick(来自$via_type:$via_name 对:\@$msg_receiever_nick) 说: ",
                $msg->{content} . $attach
            );
        }
        elsif($msg->{msg_class} eq 'send'){
            format_msg(
                strftime("[%y/%m/%d %H:%M:%S]",localtime($msg->{msg_time}))
                .   "\@$msg_sender_nick(对:\@$msg_receiever_nick 来自$via_type:$via_name) 说: ",
                $msg->{content} . $attach
            );
        }
    }

    elsif($msg->{type} eq 'discuss_message'){
        my $discuss_name = $msg->discuss_name;
        my $msg_sender = $msg->from_nick;
        $msg_sender = "昵称未知" unless defined $msg_sender;
        #my $msg_sender_qq  = $msg->from_qq;
        format_msg(
                strftime("[%y/%m/%d %H:%M:%S]",localtime($msg->{msg_time}))
            .   "\@$msg_sender(在讨论组:$discuss_name) 说: ",
                $msg->{content} . $attach
        );
        
    }

    return 1;
}

sub format_msg{
    my $msg_header  = shift;
    my $msg_content = shift;
    my @msg_content = split /\n/,$msg_content;
    $msg_header = decode("utf8",$msg_header);
    my $chinese_count=()=$msg_header=~/\p{Han}/g    ;
    my $total_count = length($msg_header);
    $msg_header=encode("utf8",$msg_header);

    my @msg_header = ($msg_header,(' ' x ($total_count-$chinese_count+$chinese_count*2)) x $#msg_content  );
    while(@msg_content){
        my $lh = shift @msg_header; 
        my $lc = shift @msg_content;
        #你的终端可能不是UTF8编码，为了防止乱码，做下编码自适应转换
        console $lh, $lc,"\n";
    } 
}

1;
