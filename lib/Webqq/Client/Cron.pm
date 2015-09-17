package Webqq::Client::Cron;
use AE;
use Webqq::Client::Util qw(console_stderr console);
use POSIX qw(mktime);
use Time::Piece;
use Time::Seconds;
sub add_job{
    my $self = shift;
    #AE::now_update;
    my($type,$t,$callback) = @_;
    if(ref $callback ne 'CODE'){ 
        console_stderr("Webqq::Client::Cron->add_job()设置的callback无效\n");
        exit;
    }
    my($hour,$minute) = split /:/,$t;
    my $time = {hour => $hour,minute => $minute,second=>0};
    my $delay;
    #my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    my @now = localtime;
    my $now = mktime(@now);
    my @next = @{[@now]};
    for my $k (keys %$time){
          $k eq 'year'        ? ($next[5]=$time->{$k}-1900)
        : $k eq 'month'       ? ($next[4]=$time->{$k}-1)
        : $k eq 'day'         ? ($next[3]=$time->{$k})
        : $k eq 'hour'        ? ($next[2]=$time->{$k})
        : $k eq 'minute'      ? ($next[1]=$time->{$k})
        : $k eq 'second'      ? ($next[0]=$time->{$k})
        : next;
    } 

    my $next = mktime(@next);
    $now = localtime($now);
    $next = localtime($next);

    if($now >= $next){
        if( $time->{month} ) {
            $next->add_years(1);
        }
        elsif( $time->{day} ) {
            $next->add_months(1);
        }
        elsif( $time->{hour} ) {
            $next += ONE_DAY;
        }
        elsif( $time->{minute} ) {
            $next += ONE_HOUR;
        }
        elsif( $time->{second} ) {
            $next += ONE_MINUTE;
        }        
    }    
    
    console "[$type]下一次触发时间为：" . $next->strftime("%Y/%m/%d %H:%M:%S\n") if $self->{debug}; 
    $delay = $next - $now;
    my $rand_watcher_id = rand();
    $self->{watchers}{$rand_watcher_id} = AE::timer $delay,0,sub{
        delete $self->{watchers}{$rand_watcher_id};
        eval{
            $callback->();
        };
        console $@ if $@;
        $self->add_job($type,$t,$callback);
    };
}
1;
