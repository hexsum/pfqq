package Webqq::Client::Cron;
use Webqq::Client::Util qw(console_stderr console);
use POSIX qw(mktime);
use DateTime;
sub add_job{
    my $self = shift;
    AE::now_update;
    my($type,$t,$callback) = @_;
    if(ref $callback ne 'CODE'){ 
        console_stderr("Webqq::Client::Cron->add_job()设置的callback无效\n");
        exit;
    }
    my($hour,$minute) = split /:/,$t;
    my $time = {hour => $hour,minute => $minute,second=>0};
    my $now_epoch = AE::now;
    my $next_epoch;
    my $delay;

    my $now = DateTime->from_epoch( epoch => $now_epoch ,); 
    $now->set_time_zone("Asia/Shanghai");
    my $next = $now->clone;
    $next->set(%$time);
    if( DateTime->compare( $now, $next ) > -1 ) {
        if( $time->{month} ) {
            $next->add( years => 1 );
        }
        elsif( $time->{day} ) {
            $next->add( months => 1 );
        }
        elsif( $time->{hour} ) {
             $next->add( days => 1 );
        }
        elsif( $time->{minute} ) {
            $next->add( hours => 1 );
        }
        elsif( $time->{second} ) {
            $next->add( minutes => 1 );
        }
    }
    $next_epoch = $next->epoch();

    console "[$type]下一次触发时间为：" . $next->strftime("%Y/%m/%d %H:%M:%S\n")
        if $self->{debug}; 
    $delay = $next_epoch-$now_epoch;
    my $rand_watcher_id = rand();
    $self->{watchers}{$rand_watcher_id} = AE::timer $delay,0,sub{
        delete $self->{watchers}{$rand_watcher_id};
        $callback->();
        $self->add_job($type,$t,$callback);
    };
}
1;
