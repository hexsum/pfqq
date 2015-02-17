package Plack::App::robots;
use strict;
use parent qw(Plack::Component);
sub call {
    my($self,$env) = @_;
    return [
        '200',
        ['Content-Type','text/plain'],
        ["User-agent: *\r\nDisallow: /"]
    ];
}
1;
