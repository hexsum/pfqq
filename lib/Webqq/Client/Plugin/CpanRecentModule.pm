package Webqq::Client::Plugin::CpanRecentModule;
use AE;
use Encode;
use XML::Simple;
use POSIX qw(mktime);
use Storable qw(store retrieve);
use Webqq::Client::Util qw(console);
my %data;
sub call{
    my $client = shift;
    my $path = shift;
    $client->{watchers}{rand()} = AE::timer 600,600,sub{
        print "GET https://metacpan.org/feed/recent?f=n\n" if $client->{debug};
        $client->{asyn_ua}->get('https://metacpan.org/feed/recent?f=n',(),sub{
            my $res  = shift;
            return unless $res->is_success;
            my $xml;
            eval{
                $xml = XMLin($res->content,KeepRoot=>1); 
            };
            if($@){
                console "[Webqq::Client::Plugin::CpanRecentModule]$@\n" if $client->{debug};
                return;
            }
            unless(%data){
                for my $item (@{ $xml->{'rdf:RDF'}{item} } ){
                    $data{$item->{title}} = {
                        author      =>  $item->{'dc:creator'},
                        'link'      =>  $item->{'link'},
                        desc        =>  $item->{'description'},
                        date        =>  $item->{'dc:date'},
                    };
                }
            }
            else{
                my @module;
                for my $item (@{ $xml->{'rdf:RDF'}{item} } ){
                    next if exists $data{$item->{title}};
                    my $link = $client->get_dwz($item->{'link'});
                    $link = $item->{'link'} unless defined $link;
                    push @module,{
                        author      =>  $item->{'dc:creator'},
                        name        =>  $item->{title},
                        'link'      =>  $link,
                        desc        =>  $item->{description},
                    };
                    $data{$item->{title}} = {
                        author      =>  $item->{'dc:creator'},
                        'link'      =>  $item->{'link'},
                        desc        =>  $item->{'description'},
                        date        =>  $item->{'dc:date'},  
                    };
                }
            
                if(@module){
                    my @msg;
                    for(@module){
                        push @msg ,
                            "模块：$_->{name}\n" . 
                            "描述：$_->{desc}\n" .
                            "链接: $_->{link}\n" 
                        ;
                    }
                    my $msg = "Hi, CPAN有新模块发布:\n" . join("\n",@msg);
                    $msg = encode("utf8",$msg);
                    for my $g (@{ $client->{qq_database}{group} }){
                        $client->send_group_message(to_uin=>$g->{ginfo}{gid},content=>$msg);
                    }
                }
            }
        });
    };
}

1;
