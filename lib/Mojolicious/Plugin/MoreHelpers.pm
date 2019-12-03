package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Scalar::Util qw/looks_like_number/;

## no critic
our $VERSION = '1.05_002';
$VERSION = eval $VERSION;
## use critic

sub register {
  my ($self, $app, $conf) = @_;

  #
  # Helpers
  #

  $app->helper('reply.bad_request' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.validation_failed';
    $c->message_header($message)->render(status => 400);
  });

  $app->helper('reply.unauthorized' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.authorization_failed';
    $c->message_header($message)->render(status => 401);
  });

  $app->helper('reply.forbidden' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.access_denied';
    $c->message_header($message)->render(status => 403);
  });

  $app->helper('reply.unprocessable' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.unprocessable_entity';
    $c->message_header($message)->render(status => 422);
  });

  $app->helper('reply.locked' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.temporary_locked';
    $c->message_header($message)->render(status => 423);
  });

  $app->helper('reply.rate_limit' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.too_many_requests';
    $c->message_header($message)->render(status => 429);
  });

  $app->helper('reply.catch' => sub {
    my ($c, $message, $status) = @_;

    my %hash = (
      bad_request   => sub { $c->reply->bad_request(@_)   },
      unauthorized  => sub { $c->reply->unauthorized(@_)  },
      forbidden     => sub { $c->reply->forbidden(@_)     },
      not_found     => sub { $c->reply->not_found(@_)     },
      unprocessable => sub { $c->reply->unprocessable(@_) },
      locked        => sub { $c->reply->locked(@_)        },
      rate_limit    => sub { $c->reply->rate_limit(@_)    },
      exception     => sub { $c->reply->exception(@_)     }
    );

    $hash{$status ||= 'exception'}
      ? $hash{$status}->($message)
      : $hash{exception}->("Wrong catch status '$status'");
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

  $app->helper(message_header => sub {
    my ($c, $message) = @_;

    my $h = $c->res->headers;

    $h->header('X-Message' => $message);

    return $c;
  });

  $app->helper(useragent_string => sub {
    substr shift->req->headers->user_agent || '', 0, 1024
  });

  $app->helper(custom_headers => sub {
    my ($c, %headers) = @_;

    my $h = $c->res->headers;

    for my $name (keys %headers) {
      next unless defined $headers{$name};
      $h->header($name => $headers{$name});
    }

    return $c;
  });

  #
  # Routes
  #

  $app->routes->add_type(str => qr/[0-9a-z-]{4,64}/i);

  #
  # Validators
  #

  $app->validator->add_check(range => sub {
    my ($validate, $name, $value, $min, $max) = @_;

    return 1 unless looks_like_number $value;
    return int $value < $min || int $value > $max ? 1 : 0;
  });

  $app->validator->add_check(boolean => sub {
    shift->in(0, 1)->has_error(shift)
  });

  #
  # Logs
  #

  $app->log->format(sub {
    my $time  = sprintf "%-10.10s", shift;
    my $level = sprintf "%-5.5s", shift;

    return sprintf "$time [$level] %s", join "\n", @_, "";
  });
}

1;
