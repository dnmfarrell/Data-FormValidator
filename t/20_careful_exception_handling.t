#!/usr/bin/perl -w

# This tests to make sure that when we test $@, we are testing the right thing.
# inspired by a patch from dom@semantico.com
use lib ('.','../t');

$^W = 1;

print "1..1\n";

use strict;
use Data::FormValidator;

# So as to not trigger a require later on in the code.
require UNIVERSAL;

my $input_profile =
{
	required => 'nothing',
};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = { 
	'1_required' => 1,
	'1_optional' => 1,
};

eval {
        # populate $@ to see if D::FV dies when it shouldn't
        $@ = 'exceptional value';
        my ($valids, $missings, $invalids, $unknowns) = ({},[],[],[]);
	($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};

print "not " if ($@ =~ /Error compiling regular expression/);
print "ok 1\n";

# vim: set ai et sw=8 syntax=perl :
