
use strict;

$^W = 1;

print "1..3\n";

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
if($@){
  warn "$@";
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
