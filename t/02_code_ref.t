
use strict;

$^W = 1;

print "1..4\n";

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
if($@){
  print "not ";
}
print "ok 1\n";

unless (exists $valids->{'phone'}){
  print "not ";
}
print "ok 2\n";

unless ($invalids->[0] eq 'email'){
  print "not ";
}
print "ok 3\n";

my %missings;
@missings{@$missings} = ();
#print "@$missings\n";
unless (exists $missings{'species'} && exists $missings{'no_legs'} && exists $missings{'petals'} && exists $missings{'stem'} && @$missings == 4) {
  print "not ";
}
print "ok 4\n";
