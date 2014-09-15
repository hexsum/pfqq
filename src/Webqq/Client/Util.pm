package Webqq::Client::Util;
use Exporter 'import';
use Encode;
use Encode::Locale;
our @EXPORT_OK = qw(console console_stderr) ;
sub console{
    my $bytes = join "",@_;
    print encode("locale",decode("utf8",$bytes));
}
sub console_stderr{
    my $bytes = join "",@_;
    print STDERR encode("locale",decode("utf8",$bytes));
}
1;
