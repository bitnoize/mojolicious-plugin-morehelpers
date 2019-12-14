package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base 'Mojolicious::Plugin';

## no critic
our $VERSION = '1.05_016';
$VERSION = eval $VERSION;
## use critic

sub register {
  my ($self, $app, $conf) = @_;

  #
  # Helpers
  #

  $app->helper('reply.bad_request' => sub {
    my ($c, $message) = @_;

    $c->render_error(status => 400,
      message => $message // "error.validation_failed");
  });

  $app->helper('reply.unauthorized' => sub {
    my ($c, $message) = @_;

    $c->render_error(status => 401,
      message => $message // "error.authorization_failed");
  });

  $app->helper('reply.forbidden' => sub {
    my ($c, $message) = @_;

    $c->render_error(status => 403,
      message => $message // "error.access_denied");
  });

  $app->helper('reply.not_exist' => sub {
    my ($c, $message) = @_;

    $c->render_error(status => 404,
      message => $message // "error.resource_not_exist");
  });

  $app->helper('reply.not_acceptable' => sub {
    my ($c, $message) = @_;

    $c->render_error(status => 406,
      message => $message // "error.not_acceptable");
  });

  $app->helper('reply.unprocessable' => sub {
    my ($c, $message) = @_;

    $c->render_error(status => 422,
      message => $message // "error.unprocessable_entity");
  });

  $app->helper('reply.locked' => sub {
    my ($c, $message) = @_;

    $c->render_error(status => 423,
      message => $message // "error.temporary_locked");
  });

  $app->helper('reply.rate_limit' => sub {
    my ($c, $message) = @_;

    $c->render_error(status => 429,
      message => $message // "error.too_many_requests");
  });

  $app->helper('reply.catch' => sub {
    my ($c, $message, $status) = @_;

    my %dispatch = (
      bad_request   => sub { $c->reply->bad_request(@_)   },
      unauthorized  => sub { $c->reply->unauthorized(@_)  },
      forbidden     => sub { $c->reply->forbidden(@_)     },
      not_exist     => sub { $c->reply->not_exist(@_)     },
      unprocessable => sub { $c->reply->unprocessable(@_) },
      locked        => sub { $c->reply->locked(@_)        },
      rate_limit    => sub { $c->reply->rate_limit(@_)    },
      exception     => sub { $c->reply->exception(@_)     }
    );

    $dispatch{$status //= 'exception'}
      ? $dispatch{$status}->($message)
      : $dispatch{exception}->("Wrong catch status: '$status'");
  });

  $app->helper(validation_json => sub {
    my ($c) = @_;

    my $v = $c->validation;

    my $json = $c->req->json || {};
    $json = {} unless ref $json eq 'HASH';

    for my $key (keys %$json) {
      my $success = 0;

      if (not ref $json->{$key}) { $success = 1 }

      elsif (ref $json->{$key} eq 'ARRAY') {
        # Success only if there are no any refs in array
        $success = 1 unless grep { ref $_ } @{$json->{$key}};
      }

      $v->input->{$key} = $json->{$key} if $success;
    }

    return $v;
  });

  $app->helper(render_error => sub {
    my ($c, %opts) = @_;

    $c->stash(status  => $opts{status}  //= 520);
    $c->stash(message => $opts{message} //= "error.unknown_error");

    $c->res->headers->header('X-Message' => $opts{message});
    $c->render(json => $opts{json} //= {});
  });

  $app->helper(useragent_string => sub {
    substr shift->req->headers->user_agent || '', 0, 1024
  });

  $app->helper(onward_headers => sub {
    my ($c, %headers) = @_;

    my $h = $c->res->headers;

    for my $name (keys %headers) {
      next unless defined $headers{$name};
      $h->header($name => $headers{$name});
    }

    return $c;
  });

  #
  # Logs
  #

  $app->log->format(sub {
    my $time  = sprintf "%-10.10s", shift;
    my $level = sprintf "%-5.5s", shift;

    return sprintf "$time [$level] %s", join "\n", @_, '';
  });
}

1;
