#!/usr/bin/perl -w

# This tests to make sure that we can use hashrefs and code refs as OK values in the input hash
# inspired by a patch from Boris Zentner

use lib ('.','../t');

$^W = 1;

print "1..2\n";

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
print "not " if  (defined $valids->{arrayref}->[0]);
print "ok 1\n";

# hash refs and code refs should be ok.
print "not " unless ((ref $valids->{hashref} eq 'HASH') and (ref $valids->{coderef} eq 'CODE'));
print "ok 2\n";



