#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => "Mojolicious::Plugin::MoreHelpers",
  VERSION_FROM  => "lib/Mojolicious/Plugin/MoreHelpers.pm",
  ABSTRACT      => "More REST-like helpers for Mojolicious",
  LICENSE      => 'artistic_2',
  AUTHOR        => "Dmitry Krutikov <mitya\@whteam.net>",
  PREREQ_PM     => {
    'Data::Validate::IP'      => '0.27',
    'Parse::HTTP::UserAgent'  => '0.42',
    'Mojolicious'             => '8.12'
  },
  EXE_FILES => ["script/curl-api.sh"],
  test => { TESTS => 't/*.t' }
);
