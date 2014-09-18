package Webqq::Client::Util;
use Exporter 'import';
use Encode;
use Encode::Locale;
our @EXPORT_OK = qw(console console_stderr hash) ;
sub console{
    my $bytes = join "",@_;
    print encode("locale",decode("utf8",$bytes));
}
sub console_stderr{
    my $bytes = join "",@_;
    print STDERR encode("locale",decode("utf8",$bytes));
}

#腾讯hash函数js代码 http://pidginlwqq.sinaapp.com/hash.js
#感谢 @小狼 贡献代码
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
1;
