
use strict;
use lib ('.','../t');

$^W = 1;

print "1..1\n";

use Data::FormValidator;

my $input_profile = {
	required => ['my_zipcode_field'],
	constraints => {
		my_zipcode_field => {
			constraint => \&starts_with_402,
			params	   => ['my_zipcode_field', \'cow'],
		}, 
	},
	untaint_all_constraints=>1,

};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {
	my_zipcode_field => 'big brown', 
};

sub starts_with_402 {
	my ($zip, $cow) = @_;
	return "$zip $$cow";
}

my ($valids, $missings, $invalids, $unknowns);
eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};

# Test to make sure that the constraint receives a literal value of an element passed by reference
print "not " unless $valids->{my_zipcode_field} eq 'big brown cow';
print "ok 1\n";
#warn "actual vlaue: $valids->{my_zipcode_field}";


