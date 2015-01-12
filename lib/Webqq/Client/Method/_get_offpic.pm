use strict;
use File::Temp qw/:seekable/;
use Webqq::Client::Util qw(console);
sub Webqq::Client::_get_offpic {
    my $self = shift;
    return if $self->{type} ne 'smartqq';
    my $file_path = shift;
    my $from_uin  = shift;
    my $cb = shift;
    my $api = 'http://w.qq.com/d/channel/get_offpic2';
    if(ref $cb eq 'CODE'){
        my @query_string = (
            file_path   =>  $file_path,
            f_uin       =>  $from_uin,
            clientid    =>  $self->{qq_param}{clientid},  
            psessionid  =>  $self->{qq_param}{psessionid},
        );
        my $callback = sub{
            my $response = shift;
            if($response->is_success){
                return unless $response->header("content-type") =~/^image\/(.*)/;
                my $type =      $1=~/jpe?g/i        ?   ".jpg"
                            :   $1=~/png/i          ?   ".png"
                            :   $1=~/bmp/i          ?   ".bmp"
                            :   $1=~/gif/i          ?   ".gif"
                            :                           undef
                ;
                return unless defined $type; 
                my $tmp = File::Temp->new(
                        TEMPLATE    => "webqq_offpic_XXXX",    
                        SUFFIX      => $type,
                        TMPDIR      => 1,
                        UNLINK      => 1,
                );
                binmode $tmp;
                print $tmp $response->content();    
                close $tmp;
                eval{
                    open(my $fh,"<:raw",$tmp->filename) or die $!;
                    $cb->($fh,$tmp->filename);    
                    close $fh;
                };
                console "[Webqq::Client::_get_offpic] $@" if $@;
            }
        };
        require URI;
        my $uri = URI->new('http:');
        $uri->query_form(\@query_string);
        print "GET $api?" . $uri->query() . "\n" if $self->{debug};
        $self->{asyn_ua}->get($api ."?". $uri->query(),$callback);
    }
};
1;
