package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  $app->helper('reply.success' => sub {
    my ($c, $json, %onward) = @_;

    my $h = $c->res->headers;

    $h->header('X-List-Cursor' => $onward{cursor})
      if defined $onward{cursor};

    $h->header('X-List-Limit' => $onward{limit})
      if defined $onward{limit};

    $h->header('X-List-Size' => $onward{size})
      if defined $onward{size};

    my $default_status = $c->req->method eq 'POST' ? 201 : 200;
    my $status = $onward{status} || $default_status;

    $c->render(json => $json || {}, status => $status);
  });

  $app->helper('reply.bad_request' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 400;
    my $message = $onward{message} || "error.validation_failed";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.unauthorized' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 401;
    my $message = $onward{message} || "error.authorization_failed";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.forbidden' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 403;
    my $message = $onward{message} || "error.access_denied";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.not_exists' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 404;
    my $message = $onward{message} || "error.resource_not_found";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.not_acceptable' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 406;
    my $message = $onward{message} || "error.not_acceptable";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.unprocessable' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 422;
    my $message = $onward{message} || "error.unprocessable_entity";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.locked' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 423;
    my $message = $onward{message} || "error.temporary_locked";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.rate_limit' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 429;
    my $message = $onward{message} || "error.too_many_requests";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.unavailable' => sub {
    my ($c, %onward) = @_;

    my $h = $c->res->headers;

    my $status  = $onward{status}  || 503;
    my $message = $onward{message} || "error.service_unavailable";

    $h->header('X-Message' => $message);
    $c->render(json => {}, status => $status);
  });

  $app->helper('reply.catch' => sub {
    my ($c, $message, $status, %onward) = @_;

    return $c->reply->exception($message) unless $status;

    my %reply = (
      bad_request   => sub { $c->reply->bad_request(@_)   },
      unauthorized  => sub { $c->reply->unauthorized(@_)  },
      forbidden     => sub { $c->reply->forbidden(@_)     },
      not_exists    => sub { $c->reply->not_exists(@_)    },
      unprocessable => sub { $c->reply->unprocessable(@_) },
      locked        => sub { $c->reply->locked(@_)        },
      rate_limit    => sub { $c->reply->rate_limit(@_)    },
      unavailable   => sub { $c->reply->unavailable(@_)   },
    );

    my $reply = $reply{$status};

    die "Wrong reply catch status '$status'"
      unless defined $reply;

    $reply->(%onward, message => $message);
  });

  # Onle-level object validation
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
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::MoreHelpers - REST-like helpers 

=head1 AUTHOR

Dmitry Krutikov E<lt>monstar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Dmitry Krutikov.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the README file.

=cut

