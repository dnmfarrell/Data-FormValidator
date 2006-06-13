#!/usr/bin/perl -w

# This tests for some constraint related bugs found by Chris Spiegel

use lib ('.','../t');

$^W = 1;

use Test::More tests => 4;

use strict;
use Data::FormValidator;

my $input_profile =
{
  required => [ qw( email subroutine ) ],
  constraints =>
  {
    subroutine => sub { 0 },
  }
};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = { subroutine => 'anything' };

my ($valids, $missings, $invalids, $unknowns) = ({},[],[],[]);

($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');

# We need to make sure we do not get a reference back here
ok(not ref $invalids->[0]);

$input_profile =
{
  required => [ qw( email) ],
  constraints =>
  {
    email =>
      [
        {
          constraint => 'email',
          name => 'Your email address is invalid.',
        }
      ],
  }
};

$validator = new Data::FormValidator({default => $input_profile});

eval {
($valids, $missings, $invalids, $unknowns) = $validator->validate({ email => 'invalid'}, 'default');
};
is($@,'','survived eval');

is($invalids->[0]->[0], 'email');
is($invalids->[0]->[1], 'Your email address is invalid.');



