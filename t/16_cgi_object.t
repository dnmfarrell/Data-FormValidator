# This script tests whether a CGI.pm object can be used to provide the input data
# Mark Stosberg 02/16/03 

use strict;
use lib ('.','../t');

$^W = 1;

print "1..2\n";

my $q;
eval {
	use CGI;
	$q = new CGI  ({ my_zipcode_field => 'big brown' });
};
print "not " if $@;
print "ok 1\n";

use Data::FormValidator;

my $input_profile = {
	required => ['my_zipcode_field'],
};

my $validator = new Data::FormValidator({default => $input_profile});

my ($valids, $missings, $invalids, $unknowns);
eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($q, 'default');
};

print "not " unless $valids->{my_zipcode_field} eq 'big brown';
print "ok 2\n";


