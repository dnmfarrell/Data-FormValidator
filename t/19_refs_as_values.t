#!/usr/bin/perl -w

# This tests to make sure that we can use hashrefs and code refs as OK values in the input hash
# inspired by a patch from Boris Zentner

use lib ('.','../t');

$^W = 1;

use Test::More tests => 3;

use strict;
use Data::FormValidator;

my $input_profile =
{
  required => [ qw( arrayref hashref coderef ) ],
};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = { 
	arrayref => ['', 1,2],
	hashref  => {tofu => 'good'},
	coderef  => sub { return 'the answer is 42' },
};

my ($valids, $missings, $invalids, $unknowns) = ({},[],[],[]);

($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');

# empty strings in arrays should be set to "undef"
ok(not defined $valids->{arrayref}->[0]);

# hash refs and code refs should be ok.
is(ref $valids->{hashref}, 'HASH');
is(ref $valids->{coderef}, 'CODE');



