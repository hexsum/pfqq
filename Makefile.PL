use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Webqq::Client',
    VERSION_FROM      => 'src/Webqq/Client.pm', # finds $VERSION
    PREREQ_PM         => {
        "JSON"                  => 0,
        "Digest::MD5"           => 0,
        "AnyEvent::UserAgent"   => 0,
        "LWP::UserAgent"        => 0,
        "LWP::Protocol::https"  => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       #ABSTRACT_FROM  => 'src/Webqq/Client.pm', # retrieve abstract from module
       ABSTRACT       => 'A webqq robot in Perl Language',
       AUTHOR         => 'Perfi <sjdy521@163.com>') : ()),
);
