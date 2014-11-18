package Webqq::Client::App::Perldoc;
use Exporter 'import';
use Webqq::Client::Util qw(console_stderr);
@EXPORT = qw(Perldoc);
if($^O !~ /linux/){
    console_stderr "Webqq::Client::App::Perldoc只能运行在linux系统上\n";
    exit;
}
chomp(my $PERLDOC_COMMAND = `/bin/env which perldoc`);

sub Perldoc{
    my $msg = shift;
    return if time - $msg->{msg_time} > 10;
    my $client = shift; 
    my $perldoc_path = shift;
    $PERLDOC_COMMAND = $perldoc_path if defined $perldoc_path;
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
