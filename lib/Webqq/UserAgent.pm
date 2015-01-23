package Webqq::UserAgent;
 
use AnyEvent::HTTP ();
use HTTP::Cookies ();
use HTTP::Request ();
use HTTP::Request::Common ();
use HTTP::Response ();
 
sub new {
    my $class = shift;
    my %p = @_;
    return bless {
        agent               =>  $p{agent} || $AnyEvent::HTTP::USERAGENT . ' AnyEvent-UserAgent/' . $VERSION ,
        cookie_jar          =>  $p{cookie_jar} || HTTP::Cookies->new,
        max_redirects       =>  $p{max_redirects} || 5,
        inactivity_timeout  =>  $p{inactivity_timeout} || 20,
        request_timeout     =>  $p{request_timeout} || 0
    },$class;
}
sub request {
        my $cb = pop();
        my ($self, $req, %opts) = @_;
        $self->_request($req, \%opts, sub {
                $self->_response($req, @_, $cb);
        });
}
 
sub get    { _make_request(GET    => @_) }
sub head   { _make_request(HEAD   => @_) }
sub put    { _make_request(PUT    => @_) }
sub delete { _make_request(DELETE => @_) }
sub post   { _make_request(POST   => @_) }
 
sub _make_request {
        my $cb   = pop();
        my $meth = shift();
        my $self = shift();
 
        no strict 'refs';
        $self->request(&{'HTTP::Request::Common::' . $meth}(@_), $cb);
}
 
sub _request {
        my ($self, $req, $opts, $cb) = @_;
 
        my $uri  = $req->uri;
        my $hdrs = $req->headers;
 
        unless ($hdrs->user_agent) {
                $hdrs->user_agent($self->{agent});
        }
 
        if ($uri->can('userinfo') && $uri->userinfo && !$hdrs->authorization) {
                $hdrs->authorization_basic(split(':', $uri->userinfo, 2));
        }
        if ($uri->scheme) {
                $self->{cookie_jar}->add_cookie_header($req);
        }
 
        for (qw(max_redirects inactivity_timeout request_timeout)) {
                $opts->{$_} = $self->{$_} unless exists($opts->{$_});
        }
 
        my ($grd, $tmr);
 
        if ($opts->{request_timeout}) {
                $tmr = AE::timer $opts->{request_timeout}, 0, sub {
                        undef($grd);
                        $cb->($opts, undef, {Status => 597, Reason => 'Request timeout'});
                };
        }
        $grd = AnyEvent::HTTP::http_request(
                $req->method,
                $req->uri,
                headers => {map { $_ => $hdrs->header($_) } $hdrs->header_field_names},
                body    => $req->content,
                recurse => 0,
                timeout => $opts->{inactivity_timeout},
                (map { $_ => $opts->{$_} } grep { exists($opts->{$_}) }
                        qw(proxy tls_ctx session timeout on_prepare tcp_connect on_header
                           on_body want_body_handle persistent keepalive handle_params)),
                sub {
                        undef($grd);
                        undef($tmr);
                        $cb->($opts, @_);
                }
        );
}
 
sub _response {
        my $cb = pop();
        my ($self, $req, $opts, $body, $hdrs, $prev, $count) = @_;
 
        my $res = HTTP::Response->new(delete($hdrs->{Status}), delete($hdrs->{Reason}));
 
        $res->request($req);
        $res->previous($prev) if $prev;
 
        delete($hdrs->{URL});
        if (defined($hdrs->{HTTPVersion})) {
                $res->protocol('HTTP/' . delete($hdrs->{HTTPVersion}));
        }
        if (my $hdr = $hdrs->{'set-cookie'}) {
                # Split comma-concatenated "Set-Cookie" values.
                # Based on RFC 6265, section 4.1.1.
                local @_ = split(/,([\w.!"'%\$&*+-^`]+=)/, ',' . $hdr);
                shift();
                my @val;
                push(@val, join('', shift(), shift())) while @_;
                $hdrs->{'set-cookie'} = \@val;
        }
        if (keys(%$hdrs)) {
                $res->header(%$hdrs);
        }
        if ($res->code >= 590 && $res->code <= 599 && $res->message) {
                if ($res->message eq 'Connection timed out') {
                        $res->message('Inactivity timeout');
                }
                unless ($res->header('client-warning')) {
                        $res->header('client-warning' => $res->message);
                }
        }
        if (defined($body)) {
                $res->content_ref(\$body);
        }
        $self->{cookie_jar}->extract_cookies($res);
 
        my $code = $res->code;
 
        if ($code == 301 || $code == 302 || $code == 303 || $code == 307 || $code == 308) {
                $self->_redirect($req, $opts, $code, $res, $count, $cb);
        }
        else {
                $cb->($res);
        }
}
 
sub _redirect {
        my ($self, $req, $opts, $code, $prev, $count, $cb) = @_;
 
        unless (defined($count) ? $count : ($count = $opts->{max_redirects})) {
                $prev->header('client-warning' => 'Redirect loop detected (max_redirects = ' . $opts->{max_redirects} . ')');
                $cb->($prev);
                return;
        }
 
        my $meth  = $req->method;
        my $proto = $req->uri->scheme;
        my $uri   = $prev->header('location');
 
        $req = $req->clone();
        $req->remove_header('cookie');
        if (($code == 302 || $code == 303) && !($meth eq 'GET' || $meth eq 'HEAD')) {
                $req->method('GET');
                $req->content('');
                $req->remove_content_headers();
        }
        {
                # Support for relative URL for redirect.
                # Not correspond to RFC.
                local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
                my $base = $prev->base;
                $uri = $HTTP::URI_CLASS->new(defined($uri) ? $uri : '', $base)->abs($base);
        }
        $req->uri($uri);
        if ($proto eq 'https' && $uri->scheme eq 'http') {
                # Suppress 'Referer' header for HTTPS to HTTP redirect.
                # RFC 2616, section 15.1.3.
                $req->remove_header('referer');
        }
 
        $self->_request($req, $opts, sub {
                $self->_response($req, @_, $prev, $count - 1, sub { return $cb->(@_); });
        });
}
 
 
1;
 
 
__END__
