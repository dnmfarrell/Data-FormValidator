# This script tests whether a CGI.pm object can be used to provide the input data
# Mark Stosberg 02/16/03 

use strict;
use lib ('.','../t');

$^W = 1;

use Test::More tests => 2;

my $q;
eval {
	use CGI;
	$q = new CGI  ({ my_zipcode_field => 'big brown' });
};
ok(not $@);

use Data::FormValidator;

my $input_profile = {
	required => ['my_zipcode_field'],
};

my $validator = new Data::FormValidator({default => $input_profile});

my ($valids, $missings, $invalids, $unknowns);
eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($q, 'default');
};

is($valids->{my_zipcode_field}, 'big brown');

