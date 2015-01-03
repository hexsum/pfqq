package Webqq::Client::Plugin::CpanRecentModule;
use AE;
use XML::Simple;
use POSIX qw(mktime);
use Webqq::Client::Util qw(console);
sub call{
    my $client = shift;
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
            my @module;
            my ($S2,$M2,$H2,$d2,$m2,$y2) = gmtime;
            $y2 = $y2+1900;
            $m2 = $m2+1;
            map {$_=sprintf "%02d",$_} ($S2,$M2,$H2,$d2,$m2);
            map {$_=sprintf "%04d",$_} ($y2);

            for my $item (@{ $xml->{'rdf:RDF'}{item} } ){
                my ($y1,$m1,$d1,$H1,$M1,$S1) = $item->{'dc:date'}=~/(\d{4})\-(\d{2})\-(\d{2})T(\d{2}):(\d{2}):(\d{2})/;
                #my ($y1,$m1,$d1,$H1,$M1,$S1) = split /-|T|Z|:/,$item->{'dc:date'};
                map {$_ = substr($_,0,1)} ($M1,$M2);
                next if "$y2-$m2-$d2-$H2-$M2" ne "$y1-$m1-$d1-$H1-$M1";
                my @tmp = split /-/,$item->{title};
                my $link = $client->get_dwz($item->{'link'});
                $link = $item->{'link'} unless defined $link;
                push @module,{
                    author      =>  $item->{'dc:creator'},
                    name        =>  $item->{title},
                    'link'      =>  $link,
                    desc        =>  $item->{description},
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
                for my $g (@{ $client->{qq_database}{group} }){
                    $client->send_group_message(to_uin=>$g->{ginfo}{gid},content=>$msg);
                }
            }
        });
    };
}
1;
