
use strict;

$^W = 1;

use Test::More tests => 3;

use Data::FormValidator;

my $input_profile = {
		       required => [ qw( email phone likes ) ],
		       optional => [ qq( toppings ) ],
		       constraints => {
				       email => "email",
				       phone => "phone",
				      }
			};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {email => 'invalidemail',
			phone => '201-999-9999',
			likes => ['a','b'],
			toppings => 'foo'};

my ($valids, $missings, $invalids, $unknowns) = ({},[],[],[]);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
ok(not $@) or
  diag $@;

ok(exists $valids->{'phone'});

is($invalids->[0], 'email');
