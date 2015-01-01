package Webqq::Client::Plugin::CpanRecentModule;
use AE;
use XML::Simple;
use POSIX qw(mktime);
use Webqq::Client::Util qw(console);
sub call{
    my $client = shift;
    $client->{watchers}{rand()} = AE::timer 3600,3600,sub{
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
                next if "$y2-$m2-$d2-$H2" ne "$y1-$m1-$d1-$H1";
                my @tmp = split /-/,$item->{title};
                push @module,{
                    author  =>  $item->{'dc:creator'},
                    name    =>  join("::",@tmp[0..$#tmp-1]),
                    version =>  $tmp[-1],
                    desc    =>  $item->{description},
                };
            }

            if(@module){
                my $msg;
                for(@module){
                    $msg .= sprintf("%-10s -- %s\n",$_->{name},$_->{desc});
                }
                $msg = "CPAN有新模块发布:\n" . $msg;
                for my $g (@{ $client->{qq_database}{group} }){
                    $client->send_group_message(to_uin=>$g->{ginfo}{gid},content=>$msg);
                }
            }
        });
    };
}
1;
