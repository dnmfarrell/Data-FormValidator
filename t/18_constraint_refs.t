#!/usr/bin/perl -w

# This tests for some constraint related bugs found by Chris Spiegel

use lib ('.','../t');

$^W = 1;

print "1..3\n";

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

# We need to make sure we don't get a reference back here
print "not " if (ref $invalids->[0]);
print "ok 1\n";

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
print "not " if ($@);
print "ok 2\n";

print "not " unless (($invalids->[0]->[0] eq 'email') and ($invalids->[0]->[1] eq 'Your email address is invalid.'));
print "ok 3\n";



