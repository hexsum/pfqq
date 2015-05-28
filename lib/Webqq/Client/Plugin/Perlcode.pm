package Webqq::Client::Plugin::Perlcode;
use File::Temp qw/tempfile/;
use Webqq::Client::Util qw(console_stderr);
use File::Path qw/mkpath rmtree/;
use IPC::Run qw(run timeout start pump finish harness);
use POSIX qw(strftime);

if($^O !~ /linux/){
    console_stderr "Webqq::Client::App::Perlcode只能运行在linux系统上\n";
    exit;
}
chomp(my $PERL_COMMAND = `/bin/env which perl`);
mkpath "/tmp/webqq/log/",{owner=>"nobody",group=>"nobody",mode=>0555};
mkpath "/tmp/webqq/bin/",{owner=>"nobody",group=>"nobody",mode=>0555};
mkpath "/tmp/webqq/src/",{owner=>"nobody",group=>"nobody",mode=>0555};
chown +(getpwnam("nobody"))[2,3],"/tmp/webqq/";
chown +(getpwnam("nobody"))[2,3],"/tmp/webqq/log";
chown +(getpwnam("nobody"))[2,3],"/tmp/webqq/bin";
chown +(getpwnam("nobody"))[2,3],"/tmp/webqq/src";

open LOG,">>/tmp/webqq/log/exec.log" or die $!;
sub call{
    my ($client,$msg,$perl_path) = @_;
    return 1 if time - $msg->{msg_time} > 10;
    $PERL_COMMAND = $perl_path if defined $perl_path;
    if($msg->{content} =~/(?:>>>)(.*?)(?:__END__|$)/s or $msg->{content} =~/perl\s+-e\s+'([^']+)'/s){
        $msg->{allow_plugin} = 0;
        my $doc = '';
        my $code = $1;
        $code=~s/^\s+|\s+$//g;
        $code=~s/CORE:://g;
        $code=~s/CORE::GLOBAL:://g;
        if($code){
            $code = q#use feature qw(say);BEGIN{use File::Path;use BSD::Resource;setrlimit(RLIMIT_NOFILE,10,10);setrlimit(RLIMIT_CPU,8,8);setrlimit(RLIMIT_FSIZE,1024,1024);setrlimit(RLIMIT_NPROC,5,5);setrlimit(RLIMIT_STACK,1024*1024*10,1024*1024*10);setrlimit(RLIMIT_DATA,1024*1024*10,1024*1024*10);*CORE::GLOBAL::fork=sub{};}$|=1;use POSIX qw(setuid setgid);{my($u,$g)= (getpwnam("nobody"))[2,3];mkpath('/tmp/webqq/bin/',{owner=>$u,group=>$g,mode=>0555}) unless -e '/tmp/webqq/bin';chdir '/tmp/webqq/bin';chroot '/tmp/webqq/bin' or die "chroot fail: $!";chdir "/";setuid($u);setgid($g);%ENV=();}# .  $code;
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
        return 0;
    }

    return 1;
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
