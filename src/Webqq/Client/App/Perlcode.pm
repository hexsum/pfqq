package Webqq::Client::App::Perlcode;
use File::Temp qw/tempfile/;
use File::Path qw/mkpath rmtree/;
use IPC::Run qw(run timeout start pump finish harness);
use POSIX qw(strftime);
use Exporter 'import';
@EXPORT = qw(Perlcode);

my $PERL_COMMAND = '/usr/local/perfi/bin/perl';
mkpath "/tmp/webqq/log/",{owner=>"nobody",group=>"nobody",mode=>0711};
mkpath "/tmp/webqq/bin/",{owner=>"nobody",group=>"nobody",mode=>0711};
mkpath "/tmp/webqq/src/",{owner=>"nobody",group=>"nobody",mode=>0711};
chown +(getpwnam("nobody"))[2,3],"/tmp/webqq/";
chown +(getpwnam("nobody"))[2,3],"/tmp/webqq/log";
chown +(getpwnam("nobody"))[2,3],"/tmp/webqq/bin";
chown +(getpwnam("nobody"))[2,3],"/tmp/webqq/src";
chdir "/tmp/webqq/" or die $!;

open LOG,">>/tmp/webqq/log/exec.log" or die $!;
sub Perlcode{
    my ($msg,$client) = @_;
    if($msg->{content} =~/^(?::code|:c|perlcode|__CODE__)(?:\n|[\t ]+)(.*?)(?:\n^|[\t ]+)(?::end|:e|__END__|end)$/ms){
        my $doc = '';
        my $code = $1;
        unless($code=~/^\s+$/s){
            $code = q#$|=1;use POSIX qw(setuid setgid);{my($u,$g)= (getpwnam("nobody"))[2,3];chdir '/tmp/webqq/bin';chroot '/tmp/webqq/bin' or die "chroot fail: $!";chdir "/";setuid($u);setgid($g);%ENV=();}# .  $code;
            my ($fh, $filename) = tempfile("webqq_perlcode_XXXXXXXX",SUFFIX =>".pl",DIR => "/tmp/webqq/src");
            print $code,"\n",$filename,"\n" if $client->{debug};
            print $fh $code;
            close $fh;
            chomp(my $syntax_check = `$PERL_COMMAND -Ttc '$filename' 2>&1`);
            if($syntax_check =~/syntax OK/){
                my $out_and_err = '';
                my $h;
                eval{
                    my ($line,$len) = (0,0);
                    my @cmd = ($PERL_COMMAND,"-Tt",$filename);
                    $h= harness 
                        \@cmd,'>&',\$out_and_err,timeout(5) or $doc="@灰灰 run perlcode fail";
                    while($len<=200 and $line <=10){
                        $h->pump;
                        $out_and_err=~s/\Q$filename\E/CODE/g;
                        $len = length($out_and_err);
                        $line = ()=$out_and_err=~m/\n/g;
                        select undef,undef,undef,0.01;
                    }
                    $h->kill_kill;
                };

                if($@=~/^IPC::Run: timeout on timer/){
                    $doc .= "代码执行结果:\n". &truncate($out_and_err) . "\n(代码执行超时)" ;
                    $h->kill_kill;
                }
                elsif($@=~/^process ended prematurely/){
                    $doc = "代码执行结果:\n". &truncate($out_and_err);
                }   
                else{ $doc = "代码执行结果:\n". &truncate($out_and_err);}
            }
    
            else{$doc = "代码语法检查错误:\n" . $syntax_check;}
            $doc=~s/\Q$filename\E/CODE/g;
            unlink $filename;
            print LOG strftime("%Y-%m-%d %H:%M:%S",localtime()),"\n",$code,"\n",$doc,"\n";    

            $client->reply_message($msg,$doc) if $doc;
        }
    }
}
sub truncate {
    my $out_and_err = shift;
    my $is_truncated = 0;
    if(length($out_and_err)>200){
        $out_and_err = substr($out_and_err,0,200);
        $is_truncated = 1;
    }
    my @l =split /\n/,$out_and_err,11;
    if(@l>10){
        $out_and_err = join "\n",@l[0..9];
        $is_truncated = 1;
    }
    return $out_and_err. ($is_truncated?"\n(已截断)":"");
}
1;
