package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base "Mojolicious::Plugin";

use Data::Validate::IP;
use Parse::HTTP::UserAgent;

our $VERSION = "1.01";
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  #
  # Helpers
  #

  $app->helper(is_ipv4 => sub { is_ipv4 $_[1] });
  $app->helper(is_ipv6 => sub { is_ipv6 $_[1] });

  $app->helper(parse_useragent => sub {
    my ($c, $ua) = @_;

    $ua ||= $c->req->headers->user_agent;
    Parse::HTTP::UserAgent->new($ua, { extended => 0 });
  });

  $app->helper('reply.bad_request' => sub {
    my ($c, $message) = @_;

    $c->message_header($message ||= "error.validation_failed");
    $c->render(status => 400) && undef;
  });

  $app->helper('reply.unauthorized' => sub {
    my ($c, $message) = @_;

    $c->message_header($message ||= "error.authorization_failed");
    $c->render(status => 401) && undef;
  });

  $app->helper('reply.forbidden' => sub {
    my ($c, $message) = @_;

    $c->message_header($message ||= "error.access_denied");
    $c->render(status => 403) && undef;
  });

# $app->helper('reply.not_found' => sub {
#   my ($c, $message) = @_;
#
#   $c->message_header($message ||= "error.resource_not_found");
#   $c->render(status => 404) && undef;
# });

  $app->helper('reply.not_acceptable' => sub {
    my ($c, $message) = @_;

    $c->message_header($message ||= "error.not_acceptable");
    $c->render(status => 406) && undef;
  });

  $app->helper('reply.unprocessable' => sub {
    my ($c, $message) = @_;

    $c->message_header($message ||= "error.unprocessable");
    $c->render(status => 422) && undef;
  });

  $app->helper( 'reply.locked' => sub {
    my ($c, $message) = @_;

    $c->message_header($message ||= "error.resource_locked");
    $c->render(status => 423) && undef;
  });

  $app->helper('reply.rate_limit' => sub {
    my ($c, $message) = @_;

    $c->message_header($message ||= "error.too_many_requests");
    $c->render(status => 429) && undef;
  });

# $app->helper('reply.exception' => sub {
#   my ($c, $message) = @_;
#
#   $c->app->log->error($message) if $message;
#   $c->render(status => 500) && undef;
# });

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
      ? $dispatch{ $status }->($message)
      : $dispatch{exception}->("Unknown catch status '$status'");
  });

  $app->helper(validation_json => sub {
    my ($c) = @_;

    my $json = $c->req->json || {};
    $json = {} unless ref $json eq 'HASH';
    $c->validation->input($json);
  });

  $app->helper(message_header => sub {
    my ($c, $message) = @_;

    my $h = $c->res->headers;

    $c->stash(message => $message || "error.unknown");
    $h->header("X-Message" => $c->stash('message'));

    return unless $c->stash('cors_strict');
    $h->append("Access-Control-Expose-Headers" => "X-Message");
  });

  $app->helper(pager_headers => sub {
    my ($c, @values) = @_;

    my $h = $c->res->headers;

    my @headers = qw/
      X-Pager-Order
      X-Pager-Page
      X-Pager-Start
      X-Pager-Limit
      X-Pager-Items
      X-Pager-First
      X-Pager-Last
    /;

    for my $header (@headers) {
      my $value = shift @values;
      last unless defined $value;

      $h->header($header => $value);
    }

    return unless $c->stash('cors_strict');
    $h->append("Access-Control-Expose-Headers" => join ", ", @headers);
  });

  #
  # Validators
  #

  $app->validator->add_check(range => sub {
    my ($validate, $name, $value, $min, $max) = @_;

    return 1 unless $value =~ /^\d+$/ and $value eq $value + 0;
    return int $value < $min || int $value > $max ? 1 : 0;
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
