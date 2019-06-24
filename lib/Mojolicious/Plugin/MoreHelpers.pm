package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base "Mojolicious::Plugin";

use Scalar::Util qw/looks_like_number/;

our $VERSION = "1.02_010";
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  #
  # Helpers
  #

  $app->helper('reply.bad_request' => sub {
    my ($c, $message) = @_;
    $message ||= "error.validation_failed";

    $c->message_header($message);
    $c->render(status => 400);
  });

  $app->helper('reply.unauthorized' => sub {
    my ($c, $message) = @_;
    $message ||= "error.authorization_failed";

    $c->message_header($message);
    $c->render(status => 401);
  });

  $app->helper('reply.forbidden' => sub {
    my ($c, $message) = @_;
    $message ||= "error.access_denied";

    $c->message_header($message);
    $c->render(status => 403);
  });

# $app->helper('reply.not_found' => sub {
#   my ($c, $message) = @_;
#   $message ||= "error.resource_not_found";
#
#   $c->message_header($message);
#   $c->render(status => 404);
# });

  $app->helper('reply.not_acceptable' => sub {
    my ($c, $message) = @_;
    $message ||= "error.not_acceptable";

    $c->message_header($message);
    $c->render(status => 406);
  });

  $app->helper('reply.unprocessable' => sub {
    my ($c, $message) = @_;
    $message ||= "error.unprocessable";

    $c->message_header($message);
    $c->render(status => 422);
  });

  $app->helper( 'reply.locked' => sub {
    my ($c, $message) = @_;
    $message ||= "error.resource_locked";

    $c->message_header($message);
    $c->render(status => 423);
  });

  $app->helper('reply.rate_limit' => sub {
    my ($c, $message) = @_;
    $message ||= "error.too_many_requests";

    $c->message_header($message);
    $c->render(status => 429);
  });

  $app->helper('reply.catch' => sub {
    my ($c, $message, $status) = @_;

    my %dispatch = (
      bad_request     => sub { $c->reply->bad_request(@_)     },
      unauthorized    => sub { $c->reply->unauthorized(@_)    },
      forbidden       => sub { $c->reply->forbidden(@_)       },
      not_found       => sub { $c->reply->not_found(@_)       },
      not_acceptable  => sub { $c->reply->not_acceptable(@_)  },
      unprocessable   => sub { $c->reply->unprocessable(@_)   },
      locked          => sub { $c->reply->locked(@_)          },
      rate_limit      => sub { $c->reply->rate_limit(@_)      },
      exception       => sub { $c->reply->exception(@_)       }
    );

    $dispatch{$status ||= 'exception'}
      ? $dispatch{$status}->($message)
      : $dispatch{exception}->("Unknown catch status '$status'");
  });

  $app->helper(validation_json => sub {
    my ($c) = @_;

    my $json = $c->req->json || {};
    $json = {} unless ref $json eq 'HASH';
    $c->validation->input($json);
  });

  $app->helper(header_first => sub {
    my ($c, @names) = @_;

    for my $name (@names) {
      my @values = split /,\s*/, $c->req->headers->header($name) || "";
      return $values[0] if $values[0];
    }
  });

  $app->helper(message_header => sub {
    my ($c, $message) = @_;

    my $h = $c->res->headers;

    $c->stash(message => $message || "error.unknown");
    $h->header("X-Message" => $c->stash('message'));

    $h->append("Access-Control-Expose-Headers" => "X-Message")
      if $c->stash('cors_strict');

    return $c;
  });

  $app->helper(pager_headers => sub {
    my ($c, @values) = @_;

    my $h = $c->res->headers;

    my @headers = qw/
      X-Pager-Order
      X-Pager-Page
      X-Pager-Start
      X-Pager-Limit
      X-Pager-Size
      X-Pager-First
      X-Pager-Last
    /;

    for my $header (@headers) {
      my $value = shift @values;
      last unless defined $value;

      $h->header($header => $value);
    }

    $h->append("Access-Control-Expose-Headers" => join ", ", @headers)
      if $c->stash('cors_strict');

    return $c;
  });

  $app->helper(useragent_strict => sub {
    substr shift->req->headers->user_agent || "Uknown", 0, 1024
  });

  #
  # Validators
  #

  $app->validator->add_check(range => sub {
    my ($validate, $name, $value, $min, $max) = @_;

    return 1 unless looks_like_number $value;
    return int $value < $min || int $value > $max ? 1 : 0;
  });

  $app->validator->add_check(boolean => sub {
    my ($validate, $name, $value) = @_;

    return ($value =~ /^(0|1)$/) ? 0 : 1;
  });

  #
  # Logs
  #

  $app->log->format(sub {
    my $time  = sprintf "%-10.10s", shift;
    my $level = sprintf "%-5.5s", shift;

    return "$time [$level] " . join("\n", @_, "");
  });
}

1;
