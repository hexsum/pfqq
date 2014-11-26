package Webqq::Client::Util;
use Exporter 'import';
use Encode;
use Encode::Locale;
our @EXPORT_OK = qw(console console_stderr hash truncate) ;
sub console{
    my $bytes = join "",@_;
    print encode("locale",decode("utf8",$bytes));
}
sub console_stderr{
    my $bytes = join "",@_;
    print STDERR encode("locale",decode("utf8",$bytes));
}

#腾讯hash函数js代码 http://pidginlwqq.sinaapp.com/hash.js
#感谢[PERL学习交流 @小狼]贡献代码
sub hash {
    my $ptwebqq = shift;
    my $uin = shift;
    my $a = $ptwebqq  . "password error";
    my $i = "";
    my @E = ();
    while(1){
        if(length($i)<= length($a) ){
            $i .= $uin;
            last if length($i) == length($a);
        }
        else{
            $i = substr($i,0,length($a)); 
            last;   
        }
    }   

    for(my $c=0;$c<length($i);$c++){
        $E[$c] = ord(substr($i,$c,1)) ^ ord(substr($a,$c,1));
    }
    my @a= ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F");
    $i = "" ;
    for(my $c=0;$c<@E;$c++){
        $i .= $a[  $E[$c] >>4 & 15  ];
        $i .= $a[  $E[$c]     & 15  ];  
    }
    return $i;
}

sub truncate {
    my $out_and_err = shift;
    my %p = @_;
    my $max_bytes = $p{max_bytes} || 200;
    my $max_lines = $p{max_lines} || 10;
    my $is_truncated = 0;
    if(length($out_and_err)>$max_bytes){
        $out_and_err = substr($out_and_err,0,$max_bytes);
        $is_truncated = 1;
    }
    my @l =split /\n/,$out_and_err,$max_lines+1;
    if(@l>$max_lines){
        $out_and_err = join "\n",@l[0..$max_lines-1];
        $is_truncated = 1;
    }
    return $out_and_err. ($is_truncated?"\n(已截断)":"");
}
1;
