package Webqq::Client::Plugin::Openqq;
use Plack::App::URLMap;
use Plack::App::robots;
use Plack::Builder;
use Plack::App::Openqq::SendMessage;
use Plack::App::Openqq::SendGroupMessage;
use Plack::App::Openqq::SendSessMessage;
use Plack::App::Openqq::SendDiscussMessage;
use Plack::App::Openqq::GetUserInfo;
use Plack::App::Openqq::GetFriendInfo;
use Plack::App::Openqq::GetGroupInfo;
use Plack::App::Openqq::GetDiscussInfo;
use Plack::App::Openqq::GetRecentInfo;
use Plack::Middleware::Openqq::SelfTalkForbid;
use Twiggy::Server;
my $server;
sub call{
    my $client = shift;
    my $new = {client => $client};
    my %p = @_;
    my $host = $p{host} || '0.0.0.0'; 
    my $port = $p{port} || 5000; 
    my $app = 
    builder {
        enable "Header",set => ['Server',"Openqq-Server-$client->{client_version}"];
        enable "Openqq::SelfTalkForbid",client=>$client;
        builder{
            #mount "//"           => builder {
            #    
            #};
            mount "/openqq/get_user_info" => builder {
                Plack::App::Openqq::GetUserInfo->new($new)->to_app;
            };
            mount "/openqq/get_friend_info" => builder {
                Plack::App::Openqq::GetFriendInfo->new($new)->to_app;
            };
            mount "/openqq/get_group_info" => builder {
                Plack::App::Openqq::GetGroupInfo->new($new)->to_app;
            };
            mount "/openqq/get_discuss_info" => builder {
                Plack::App::Openqq::GetDiscussInfo->new($new)->to_app;
            };
            mount "/openqq/get_recent_info" => builder {
                Plack::App::Openqq::GetRecentInfo->new($new)->to_app;
            };
            mount "/openqq/send_message" => builder {
                Plack::App::Openqq::SendMessage->new($new)->to_app;
            };
            mount "/openqq/send_group_message" => builder {
                Plack::App::Openqq::SendGroupMessage->new($new)->to_app;
            };
            mount "/openqq/send_discuss_message" => builder {
                Plack::App::Openqq::SendDiscussMessage->new($new)->to_app;
            };
            mount "/openqq/send_sess_message"  => builder {
                Plack::App::Openqq::SendSessMessage->new($new)->to_app;
            };
            mount "/robots.txt"  => builder {
                enable "Header",set => ['Cache-Control','max-age=31536000'];
                Plack::App::robots->new->to_app;
            };
        };
    };
    $server = Twiggy::Server->new(
        host => $host,
        port => $port,
    );
    return unless defined $server;
    $server->register_service($app);
}
1;
