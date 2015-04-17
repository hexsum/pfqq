package Plack::Middleware::Openqq::SelfTalkForbid;
use parent qw(Plack::Middleware);
sub call{
    my($self,$env) = @_;
    my $client = $self->{client};
    my %query_string;
    for my $query_string (split(/&/,$env->{QUERY_STRING} )){
        my($key,$value) = split /=/,$query_string;
        $query_string{$key} = $value;
    }
    if(defined $query_string{qq}){
        return ['403',[],[]] if $query_string{qq} eq $client->{qq_database}{user}{qq};
    }
    elsif(defined $query_string{uin}){
        return ['403',[],[]] if $query_string{uin} eq $client->{qq_database}{user}{uin};
    }
    my $res = $self->app->($env);
    return $res;
}
1;
