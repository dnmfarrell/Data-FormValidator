use strict;

$^W = 1;

use Test::More tests => 23;
use Data::FormValidator;

# test profile
my $input_profile = {
	dependencies => {
		pay_type => {
			Check => [qw( cc_num )],
			Visa  => [qw( cc_num cc_exp cc_name )],
		},
	},
};
my $input_hashref = {pay_type=>'Visa'};


##
## Validate a complex dependency
##

##
## validate()

my ($valids, $missings, $invalids, $unknowns);
my $validator = Data::FormValidator->new({default => $input_profile});
eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
ok(!$@, "no eval problems");

my %missings = map {$_ => 1} @$missings;
ok($missings{cc_num},  "missing cc_num");
ok($missings{cc_exp},  "missing cc_exp");
ok($missings{cc_name}, "missing cc_name");


##
## check()

my $result;
eval {
  $result = $validator->check($input_hashref, 'default');
};

ok(!$@, "no eval problems");
isa_ok($result, "Data::FormValidator::Results", "returned object");

ok($result->has_missing, "has_missing returned true");
ok($result->missing('cc_num'),  "missing('cc_num')  returned true");
ok($result->missing('cc_exp'),  "missing('cc_exp')  returned true");
ok($result->missing('cc_name'), "missing('cc_name') returned true");



##
## validate()

$input_hashref = {pay_type=>'Check'
		 };

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
ok(!$@, "no eval problems");

%missings = map {$_ => 1} @$missings;
ok($missings{cc_num},   'missing cc_num');
ok(!$missings{cc_exp},  'not missing cc_exp');
ok(!$missings{cc_name}, 'not missing cc_name');


##
## check()

$result = undef;
eval {
  $result = $validator->check($input_hashref, 'default');
};

ok(!$@, "no eval problems");
isa_ok($result, "Data::FormValidator::Results", "returned object");

ok($result->has_missing,        "has_missing returned true");
ok($result->missing('cc_num'),  "missing('cc_num') returned true");
is($result->missing('cc_exp'),  undef, "missing('cc_exp') returned false");
is($result->missing('cc_name'), undef, "missing('cc_name') returned false");



## Now, some tests using a CGI.pm object as input
use CGI;
my $q = CGI->new('pay_type=Visa');
my $results;
eval {
    $results = $validator->check($q, 'default');
};
ok($results->missing('cc_num'), 'using CGI.pm object for input');
is($result->missing('cc_exp'),  undef, "missing('cc_exp') returned false");
is($result->missing('cc_name'), undef, "missing('cc_name') returned false");




