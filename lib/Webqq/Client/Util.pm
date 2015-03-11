package Webqq::Client::Util;
use Exporter 'import';
use Encode;
use Encode::Locale;
our @EXPORT_OK = qw(console console_stderr hash truncate code2state code2client) ;
sub console{
    my $bytes = join "",@_;
    print encode("locale",decode("utf8",$bytes));
}
sub console_stderr{
    my $bytes = join "",@_;
    print STDERR encode("locale",decode("utf8",$bytes));
}

#获取好友列表和群列表的hash函数
sub hash {
    my $ptwebqq = shift;
    my $uin = shift;

    $uin .= "";
    my @N;
    for(my $T =0;$T<length($ptwebqq);$T++){
        $N[$T % 4] ^= ord(substr($ptwebqq,$T,1));
    }
    my @U = ("EC", "OK");
    my @V;
    $V[0] =  $uin >> 24 & 255 ^ ord(substr($U[0],0,1));
    $V[1] =  $uin >> 16 & 255 ^ ord(substr($U[0],1,1));
    $V[2] =  $uin >> 8  & 255 ^ ord(substr($U[1],0,1));
    $V[3] =  $uin       & 255 ^ ord(substr($U[1],1,1));
    @U = ();
    for(my $T=0;$T<8;$T++){
        $U[$T] = $T%2==0?$N[$T>>1]:$V[$T>>1]; 
    }
    @N = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F");
    my $V = "";
    for($T=0;$T<@U;$T++){
        $V .= $N[$U[$T] >> 4 & 15];
        $V .= $N[$U[$T] & 15];
    }

    return $V;
            
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
sub code2state {
    my %c = qw(
        10  online
        20  offline
        30  away
        40  hidden
        50  busy
        60  callme
        70  silent
    );
    return $c{$_[0]} || "online";
}
sub code2client {
    my %c = qw(
        1   pc
        21  mobile
        24  iphone
        41  web
    );
    return $c{$_[0]} || 'unknown';
}

1;

__END__
#腾讯获取好友和群列表的hash函数会经常变动，历史版本的hash函数都放在__END__之后
sub hash {
    #感谢[PERL学习交流 @小狼]贡献代码
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
