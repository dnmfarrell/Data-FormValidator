
use strict;
use lib ('.','../t');

$^W = 1;

print "1..5\n";

use Data::FormValidator;

my $input_profile = {
	required => ['my_zipcode_field'],
	constraints => {
		my_zipcode_field => [
			'zip',
			{ 
				constraint =>  '/^406/', 
				name 	   =>  'starts_with_406',
			}
		],
	},
};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {
	my_zipcode_field => '402015', # <!- born to lose
};

my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};

if ($@) {
	print "not ok 1\n";
	warn "eval error: $@";
}
else {
	print "ok 1\n";
}

# Test that invalids array includes arrayref
#use Data::Dumper;
#warn Dumper ($invalids);

if (grep { (ref $_) eq 'ARRAY' } @$invalids) { 
	print "ok 2\n";
}
else { 
	print "not ok 2\n";
}

# Test that the array ref in the invalids array contains three elements,
my @zip_failures;
for (@$invalids) {
	if (ref $_ eq 'ARRAY') {
		if (scalar @$_ == 3) {	 
			@zip_failures = @$_;	
			print "ok 3\n";
			last;
		}
	}
	use Data::Dumper;
	warn Dumper('invalid',$invalids);
	print "not ok 3\n";
}

# Test that the first element of the array is 'my_zipcode_field'
my $t = shift @zip_failures;
print "not " unless $t eq 'my_zipcode_field';
print "ok 4\n";

# Test that the two elements are 'zip' and 'starts_with_406'
for (@zip_failures) {
	($_ eq 'zip') or ($_ eq 'starts_with_406') or 
		(print "not " && last);
}

print "ok 5\n";


