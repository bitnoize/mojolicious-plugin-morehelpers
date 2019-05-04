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
    "Data::Validate::IP" => '0.27',
    'HTTP::BrowserDetect' => '3.14',
    "Mojolicious" => '8.12'
  },
  test => { TESTS => 't/*.t' }
);
