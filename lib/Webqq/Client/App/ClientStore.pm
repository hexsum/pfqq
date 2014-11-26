package Webqq::Client::App::ClientStore;
use Exporter 'import';
@EXPORT=qw(ClientStore);
use Storable;
sub ClientStore{
    my $client = shift;     
    my $path = shift;
    store($client->{qq_database},$path);
}
1;
