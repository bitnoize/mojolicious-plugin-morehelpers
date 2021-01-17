package Mojolicious::Plugin::MoreHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Data::Validate::IP;
use Email::Address;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  $conf->{message_header} //= 'X-Message';

  # Route param by name
  $app->helper(route_param => sub {
    my ($c, $name) = @_;

    my $route = $c->match->endpoint;

    while ($route) {
      return $route->to->{$name}
        if exists $route->to->{$name};

      $route = $route->parent;
    }

    return undef;
  });

  # Simple onle-level depth object validation
  $app->helper(validation_json => sub {
    my ($c) = @_;

    my $v = $c->validation;

    my $json = $c->req->json // { };
    $json = { } unless ref $json eq 'HASH';

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

  $app->helper(justify_status => sub {
    my ($c, $strict, $message) = @_;

    $strict //= 'unknown';

    my $sub = sub {
      my ($status, $default_message) = @_;

      $message //= $default_message;

      $c->stash(status => $status, message => $message);
      $c->res->headers->header($conf->{message_header} => $message);
    };

    my %table = (
      bad_request     => sub { $sub->(400, "error.validation_failed")    },
      unauthorized    => sub { $sub->(401, "error.authorization_failed") },
      forbidden       => sub { $sub->(403, "error.access_denied")        },
      not_found       => sub { $sub->(404, "error.resource_not_found")   },
      not_acceptable  => sub { $sub->(406, "error.not_acceptable")       },
      unprocessable   => sub { $sub->(422, "error.unprocessable_entity") },
      locked          => sub { $sub->(423, "error.temporary_locked")     },
      rate_limit      => sub { $sub->(429, "error.too_many_requests")    },
      unavailable     => sub { $sub->(503, "error.service_unavailable")  },
    );

    die "Wrong response_error strict '$strict'\n"
      unless defined $table{$strict};

    $table{$strict}->();

    return $c;
  });

  $app->helper(custom_headers => sub {
    my ($c, %onward) = @_;

    my $custom_headers = $c->route_param('custom_headers') // { };
    $custom_headers->{message} = $conf->{message_header};

    my $h = $c->res->headers;
    map { $h->header($custom_headers->{$_} => $onward{$_}) }
      grep { defined $onward{$_} } keys %$custom_headers;

    return $c;
  });

  $app->validator->add_check(inet_address => sub {
    my ($v, $name, $value) = @_;

    return is_ip $value ? undef : 1;
  });

  $app->validator->add_check(email_address => sub {
    my ($validate, $name, $value) = @_;

    my ($email) = Email::Address->parse($value);
    return defined $email && $email->address ? undef : 1;
  });
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::MoreHelpers - More helpers lacking in Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $app->plugin('MoreHelpers');

  # Mojolicious::Lite
  plugin 'MoreHelpers';

=head1 DESCRIPTION

L<Mojolicious::Plugin::MoreHelpers> is a mingle of helpers lacking in
L<Mojolicious> Web framework for REST-like APIs.

=head1 HELPERS

L<Mojolicious::Plugin::MoreHelpers> implements the following helpers.

=head2 route_param

  my $value = $c->route_param('foo_bar');

Recursive collect current route param and his parents.

=head2 validation_json

  my $v = $c->validation_json;

Merge flat request JSON object with validation.

=head2 justify_status

  $c->response_error($strict, $message);

Dispatch with status and set properly error code.

=head2 custom_headers

  my $h = $c->custom_headers(%onward);

Set multiple reponse headers from route config map.

=head1 CHECKS

Validation checks.

=head2 inet_address

String value is a internet IPv4 or IPv6 address.

=head2 email_address

String value is a valie Email address.

=head1 METHODS

L<Mojolicious::Plugin::MoreHelpers> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Bugs should always be submitted via the GitHub bug tracker.

L<https://github.com/bitnoize/mojolicious-plugin-morehelpers/issues>

=head2 Source Code

Feel free to fork the repository and submit pull requests.

L<https://github.com/bitnoize/mojolicious-plugin-morehelpers>

=head1 AUTHOR

Dmitry Krutikov E<lt>monstar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Dmitry Krutikov.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

