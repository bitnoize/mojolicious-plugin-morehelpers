package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base 'Mojolicious::Plugin';

## no critic
our $VERSION = '1.05_012';
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
    $c->reply_message($message, 400);
  });

  $app->helper('reply.unauthorized' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.authorization_failed';
    $c->reply_message($message => 401);
  });

  $app->helper('reply.forbidden' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.access_denied';
    $c->reply_message($message => 403);
  });

  $app->helper('reply.not_exist' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.resource_not_exist';
    $c->reply_message($message => 404);
  });

  $app->helper('reply.not_acceptable' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.not_acceptable';
    $c->reply_message($message => 406);
  });

  $app->helper('reply.unprocessable' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.unprocessable_entity';
    $c->reply_message($message => 422);
  });

  $app->helper('reply.locked' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.temporary_locked';
    $c->reply_message($message => 423);
  });

  $app->helper('reply.rate_limit' => sub {
    my ($c, $message) = @_;

    $message ||= 'error.too_many_requests';
    $c->reply_message($message => 429);
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

    $dispatch{$status ||= 'exception'}
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

  $app->helper(reply_message => sub {
    my ($c, $message, $status) = @_;

    $c->stash(message => $message ||= 'error.unknown_error');
    $c->stash(status  => $status  ||= 520);

    $c->render(json => { message => $message });
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
