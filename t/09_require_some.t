
use strict;

$^W = 1;

print "1..3\n";

use Data::FormValidator;

my $input_profile = {
			   require_some => {
					testing_default_to_1 => [qw/one missing1 missing2/],
					'2_of_3_success'   => [2,qw/blue green red/],
					'2_of_3_fail'      => [2,qw/foo bar zar/],
				},
			};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {
	one  => 1,
	blue => 1,
	green => 1,
};

my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};

print "not " unless ($valids->{blue} and $valids->{green});
print "ok 1\n";

print "not " unless ($valids->{one});
print "ok 2\n";

#use Data::Dumper;
#warn Dumper ($missings,[grep {/2_of_3_fail/} @$missings]);

print "not " unless (grep {/2_of_3_fail/} @$missings); 
print "ok 3\n";


