package Webqq::Client::Plugin::Perldoc;
use JSON;
use Webqq::Client::Util qw(console_stderr truncate);
if($^O !~ /linux/){
    console_stderr "Webqq::Client::App::Perldoc只能运行在linux系统上\n";
    exit;
}
chomp(my $PERLDOC_COMMAND = `/bin/env which perldoc`);

my %last_module_time ;

sub call{
    my $client = shift; 
    my $msg = shift;
    return 1 if time - $msg->{msg_time} > 10;
    my $perldoc_path = shift;
    $PERLDOC_COMMAND = $perldoc_path if defined $perldoc_path;
    if($msg->{content} =~/perldoc\s+-(v|f)\s+([^ ]+)/){
        $msg->{allow_plugin} = 0;
        my ($p,$v) = ($1,$2);
        my $doc = '';
        my $command;
        if($v eq q{$'}){
            $command = qq{$PERLDOC_COMMAND -Tt -$p "$v" 2>&1|};
        } 
        else{
            $command = qq{$PERLDOC_COMMAND -Tt -$p '$v' 2>&1|};
        }
        open PERLDOC,$command or $doc = '@灰灰 run perldoc fail';
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
        return 0;
    }  

    elsif($msg->{content} =~ /perldoc\s+((\w+::)*\w+)/ or $msg->{content} =~ /((\w+::)+\w+)/){
        $msg->{allow_plugin} = 0;
        my $module = $1;
        my $is_perldoc = $msg->{content}=~/perldoc/;
        if(!$is_perldoc and exists $last_module_time{$msg->{type}}{$msg->{from_uin}}{$module} and time - $last_module_time{$msg->{type}}{$msg->{from_uin}}{$module} < 1800){
            return 0;
        }
        my $metacpan_module_api = 'http://api.metacpan.org/v0/module/';
        my $metacpan_pod_api = 'http://api.metacpan.org/v0/pod/';

        my $cache = $client->{cache_for_metacpan}->retrieve($module);                
        if(defined $cache){
            $client->reply_message($msg,$cache->{doc});
            $last_module_time{$msg->{type}}{$msg->{from_uin}}{$module} = time;
            return 0;
        }
        $client->{asyn_ua}->get($metacpan_module_api . $module,(),sub{   
            my $response = shift;
            my $doc;
            my $json;
            my $code;
            if($client->{debug}){
                print "GET " . $metacpan_module_api . $module,"\n";
                #print $response->content;
            }
            eval{ $json = JSON->new->utf8->decode($response->content);};
            unless($@){ 
                if($json->{code} == 404){
                    return 0;
                    #$doc = "模块名称: $module ($json->{message})" ;
                    #$code = 404;

                    #$client->{cache_for_metacpan}->store($module,{code=>$code,doc=>$doc},604800);
                    #$client->reply_message($msg,$doc)  ;
                    #$last_module_time{$msg->{type}}{$msg->{from_uin}}{$module} = time;
                }
                else{
                    $code = 200;
                    my $author  =   $json->{author};
                    my $version =   $json->{version};
                    #my $date    =   $json->{date};
                    my $abstract=   $json->{abstract};
                    my $podlink     = 'https://metacpan.org/pod/' . $module;
                    $doc = 
                        "模块: $module\n" . 
                        "版本: $version\n" . 
                        "作者: $author\n" . 
                        "简述: $abstract\n" . 
                        "链接: $podlink\n"
                    ;
                    print "GET " . $metacpan_pod_api . $module,"\n" if $client->{debug};
                    $client->{asyn_ua}->get($metacpan_pod_api . $module,(Accept=>"text/plain"),sub{
                        my $res = shift;
                        my ($SYNOPSIS) = $res->content()=~/^SYNOPSIS$(.*?)^[A-Za-z]+$/ms;
                        if($SYNOPSIS){
                            $doc .= "用法概要: $SYNOPSIS\n" ;
                            $doc=~s/\n+$//;
                            $doc  = truncate($doc,max_bytes=>1000,max_lines=>30);                        
                        }
                        $client->{cache_for_metacpan}->store($module,{code=>$code,doc=>$doc},604800);
                        $client->reply_message($msg,$doc);
                        $last_module_time{$msg->{type}}{$msg->{from_uin}}{$module} = time;
                    });
                }
            }
        }); 
                
        return 0;
    }

    return 1;
}

1;
