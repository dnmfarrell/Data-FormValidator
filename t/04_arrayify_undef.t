# checks for correct behavior when $input_profile->{'required'}
# is not specified; fails if _arrayify() does not return an empty list

use strict;

$^W = 1;

print "1..2\n";

use Data::FormValidator;

my $input_profile = {
		       optional => [ qw( email ) ],
                    };

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {email => 'bob@example.com',
                    };

my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
if($@){
  print "not ";
}
print "ok 1\n";

unless (not @$missings) {
  print "not ";
}
print "ok 2\n";
