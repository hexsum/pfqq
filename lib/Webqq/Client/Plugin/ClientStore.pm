package Webqq::Client::Plugin::ClientStore;
use Storable;
sub call{
    my $client = shift;     
    my $path = shift;
    store($client->{qq_database},$path);
    return 1;
}
1;
