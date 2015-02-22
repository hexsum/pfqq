package Plack::App::Openqq::GetUserInfo;
use parent qw(Plack::Component);
use URI::Escape qw(uri_unescape);
use JSON;
sub call{
    my $self = shift;
    my $client = $self->{client};
    my $env  = shift;
    return [
        200,
        ['Content-Type' => 'text/plain'],
        [JSON->new->encode($client->{qq_database}{discuss})],
    ];
}
1;
