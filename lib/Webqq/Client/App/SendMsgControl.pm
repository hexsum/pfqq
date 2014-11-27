package Webqq::Client::App::SendMsgControl;
use Exporter 'import';
use Webqq::Client::Util qw(console);
@EXPORT=qw(SendMsgControl);
sub SendMsgControl{
    my($msg,$client) = @_;
    if($msg->{content}=~/^-shutdown$/){
        my $from_qq = $msg->from_qq;
        return unless $from_qq == 308165330;
        $client->reply_message($msg,"系统已关闭消息发送功能");
        $client->{send_message_queue}->{callback_for_get} = sub{return;};
        console("系统已关闭消息发送功能\n") if $client->{debug};
    }
    elsif($msg->{content}=~/^-reactive$/){
        my $from_qq = $msg->from_qq;
        return unless $from_qq == 308165330;
        $client->{send_message_queue}->{callback_for_get} = 
            $client->{send_message_queue}->{callback_for_get_bak} ;
            console("系统已重新开启消息发送功能\n") if $client->{debug};
            $client->reply_message($msg,"系统已重新开启消息发送功能");
    }
}
1;
