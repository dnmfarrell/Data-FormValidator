
use strict;

$^W = 1;

use Test::More tests => 8;

use Data::FormValidator;

my $input_profile = {
		       required => [ qw( email phone likes ) ],
		       optional => [ qq( toppings ) ],
		       constraints => {
				       email => "email",
				       phone => "phone",
				      likes => { constraint => sub {return 1;},
						 params => [ qw( likes email ) ],
						},
				      },
               dependencies => {
                    animal => [qw( species no_legs )],
                    plant  => {
                        tree   => [qw( trunk root )],
                        flower => [qw( petals stem )],
                    },
               },
			field_filters => {
					email => sub {return $_[0];},
				},
			};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {email => 'invalidemail',
			phone => '201-999-9999',
			likes => ['a','b'],
			toppings => 'foo',
            animal => 'goat',
            plant => 'flower'};

my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
ok(not $@);

ok(exists $valids->{'phone'});

is($invalids->[0], 'email');

my %missings;
@missings{@$missings} = ();
#print "@$missings\n";
ok(exists $missings{$_}) for (qw(species no_legs petals stem));
is(@$missings, 4);

