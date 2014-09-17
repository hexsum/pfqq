使用perl语言编写的QQ机器人(采用webqq协议)
核心依赖模块:
    JSON
    Digest::MD5
    AnyEvent::UserAgent
    LWP::UserAgent

版本更新记录:
2014-09-17 Webqq::Client v1.4
1）修复图片和表情无法正常显示问题，现在图片和表情会被转为文本形式 [图片][系统表情]
2）改进发送群消息机制，需要获取群消息的group_code，找到group_code对应的gid再进行群消息发送
3）增加Webqq::Client::Cache模块，用于缓存一些经常需要使用的信息，避免时时查询
4）增加获取个人信息、好友信息、群信息、群成员信息功能
5）增加查询好友QQ号码功能
6）增加注销功能，程序运行后使用CTRL+C退出时，会自动完成注销
7）增加对强迫下线消息的处理
----
当前发现的一些BUG：
1）再一次消息接收中如果包含多个消息，可能会导致只处理第一个消息，其他消息丢失
2）偶尔会出现发送群消息提示成功，但对方无法接收到的问题（可能和JSON编码有关）


2014-09-14 Webqq::Client v1.3
1）添加一些代码注释
2）demo/*.pl示例代码为防止打印乱码，添加终端编码自适应
3）添加Webqq::Message::Queue消息队列，实现接收消息、处理消息、发送消息等函数解耦
client 
 | 
 ->login()
    |
    +->run() 
        +->_recv_message()-[put]-> Webqq::Message::Queue -[get]-> on_receive_message()
        +
    +---+->send_message() -[put]-                         +[get]-> _send_message() 
    |   +                        \ Webqq::Message::Queue /
    |   +                             /              \
    | +->send_group_message()-[put]-                -[get]-> _send_group_message()
    | |
    | +->msg->{cb}--->on_send_message()
    +--->msg->{cb}--/

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

