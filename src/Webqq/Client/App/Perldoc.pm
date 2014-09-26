package Webqq::Client::App::Perldoc;
use Exporter 'import';
@EXPORT = qw(Perldoc);
my $PERLDOC_COMMAND = '/usr/local/perfi/bin/perldoc';

sub Perldoc{
    my $msg = shift;
    my $client = shift; 
    if($msg->{content} =~/^perldoc -(v|f) ([^ &;]+)$/){
        my ($p,$v) = ($1,$2);
        my $doc = '';
        open PERLDOC,"$PERLDOC_COMMAND -Tt -$p '$v' 2>&1|" or $doc = '@灰灰 run perldoc fail';
        while(<PERLDOC>){
            last if $.>10;
            $doc .= $_;
        }
        close PERLDOC;
        $doc=~s/\n*$/...\n/;
        if($p eq 'f'){
            if($doc=~/^No documentation for perl function/){
                $doc .= "http://perldoc.perl.org/index-functions.html";
            }
            else{
                $doc .= "See More: http://perldoc.perl.org/functions/$v.html";
            }
        }
        elsif($p eq 'v'){
            $doc .= "See More: http://perldoc.perl.org/perlvar.html";
        }

        $client->reply_message($msg,$doc) if $doc;
    }  
}

1;
