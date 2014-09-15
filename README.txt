使用perl语言编写的QQ机器人(采用webqq协议)
核心依赖模块:
    JSON
    Digest::MD5
    AnyEvent::UserAgent
    LWP::UserAgent

版本更新记录:
2014-09-14 Webqq::Client v1.3
1）添加一些代码注释
2）demo/*.pl示例代码为防止打印乱码，添加终端编码自适应
3）添加Webqq::Message::Queue消息队列，实现接收消息、处理消息、发送消息等函数解耦
client 
 + 
 ->login()
    +-run() 
       +->_recv_message()-[put]-> Webqq::Message::Queue -[get]-> on_receive_message()
       +
       +->send_message() -[put]-                         +[get]->_send_message() 
       +                        \ Webqq::Message::Queue /
       +                             /              \
       +->send_group_message()-[put]-                -[get]-> $send_group_message()

2014-09-14 Webqq::Client v1.2
1）源码改为UTF8编写，git commit亦采用UTF8字符集，以兼容github显示
2）优化JSON数据和perl内部数据格式之间转换，更好的兼容中文
3）修复debug下的打印错误（感谢 @卖茶叶perl高手 的bug反馈）
4）新增demo/console_message.pl示例代码，把接收到的普通消息和群消息打印到终端的简单程序

2014-09-12 Webqq::Client v1.1
1）debug模式下支持打印send_message，send_group_message的POST提交数据，方便调试
2）修复了无法正常发送中文问题
3）修复了无法正常发送包含换行符的内容
4) on_receive_message/on_send_message属性改为是lvalue方法，可以支持getter和setter使用方式

