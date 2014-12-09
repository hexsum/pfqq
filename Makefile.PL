use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Webqq::Client',
    VERSION_FROM      => 'lib/Webqq/Client.pm', # finds $VERSION
    DISTNAME            => 'Webqq-Client',
    LICENSE             => "perl",
    PREREQ_PM         => {
        "JSON"                  => 0,
        "Digest::MD5"           => 0,
        "AnyEvent::UserAgent"   => 0,
        "LWP::UserAgent"        => 0,
        "LWP::Protocol::https"  => 0,
        "DateTime"    =>        => 0,
    }, # e.g., Module::Name => 1.1
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Webqq-Client-*' },
    META_MERGE => {
        resources => {     
            repository=>{
                type    => 'git',
                url     => 'git://github.com/sjdy521/Webqq-Client.git',
                web     =>  'https://github.com/sjdy521/Webqq-Client',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       #ABSTRACT_FROM  => 'lib/Webqq/Client.pm', # retrieve abstract from module
       ABSTRACT       => 'A webqq client in Perl Language',
       AUTHOR         => 'Perfi <sjdy521@163.com>') : ()),
);
