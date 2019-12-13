package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base 'Mojolicious::Plugin';

## no critic
our $VERSION = '1.05_015';
$VERSION = eval $VERSION;
## use critic

sub register {
  my ($self, $app, $conf) = @_;

  #
  # Helpers
  #

  $app->helper('reply.success' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 200;
    $stash{message} //= "info.request_success";

    $c->render_reply(%stash);
  });

  $app->helper('reply.bad_request' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 400;
    $stash{message} //= "error.validation_failed";

    $c->render_reply(%stash);
  });

  $app->helper('reply.unauthorized' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 401;
    $stash{message} //= "error.authorization_failed";

    $c->render_reply(%stash);
  });

  $app->helper('reply.forbidden' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 403;
    $stash{message} //= "error.access_denied";

    $c->render_reply(%stash);
  });

  $app->helper('reply.not_exist' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 404;
    $stash{message} //= "error.resource_not_exist";

    $c->render_reply(%stash);
  });

  $app->helper('reply.not_acceptable' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 406;
    $stash{message} //= "error.not_acceptable";

    $c->render_reply(%stash);
  });

  $app->helper('reply.unprocessable' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 422;
    $stash{message} //= "error.unprocessable_entity";

    $c->render_reply(%stash);
  });

  $app->helper('reply.locked' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 423;
    $stash{message} //= "error.temporary_locked";

    $c->render_reply(%stash);
  });

  $app->helper('reply.rate_limit' => sub {
    my ($c, %stash) = @_;

    $stash{status}  //= 429;
    $stash{message} //= "error.too_many_requests";

    $c->render_reply(%stash);
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
      ? $dispatch{$status}->(message => $message)
      : $dispatch{exception}->(message => "Wrong catch status: '$status'");
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

  $app->helper(render_reply => sub {
    my ($c, %stash) = @_;

    $c->stash(
      json    => $stash{json}     //= {},
      status  => $stash{status}   //= 520,
      message => $stash{message}  //= "error.unknown_error"
    );

    $c->res->headers->header('X-Message' => $stash{message});

    $c->render;
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
