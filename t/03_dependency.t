
use strict;

$^W = 1;

print "1..6\n";

use Data::FormValidator;

my $input_profile = {
	required => [qw(bar)],
	optional => [qw(foo)],
	dependencies => {
		cc_type => {
			Check   => [qw( cc_num )],
			Visa => [qw( cc_num cc_exp cc_name )],
		},
	},
};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {
			cc_type=>'Visa'
			};
my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
if($@){
  print "not ";
}
print "ok 1\n";

my %missings = map {$_ => 1} @$missings;
unless($missings{'cc_num'}){
  print "not ";
}
print "ok 2\n";

unless($missings{'cc_exp'}){
  print "not ";
}
print "ok 3\n";

$input_hashref = {
			cc_type=>'Check'
			};

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
if($@){
  print "not ";
}
print "ok 4\n";

%missings = map {$_ => 1} @$missings;
unless($missings{'cc_num'}){
  print "not ";
}
print "ok 5\n";

if($missings{'cc_exp'}){
  print "not ";
}
print "ok 6\n";


