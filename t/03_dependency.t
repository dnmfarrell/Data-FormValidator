
use strict;

$^W = 1;

use Test::More tests => 7;

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
ok(not $@);

my %missings = map {$_ => 1} @$missings;
ok($missings{'cc_num'});
ok($missings{'cc_exp'});

$input_hashref = {
			cc_type=>'Check'
			};

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
ok(not $@);

%missings = map {$_ => 1} @$missings;
ok($missings{'cc_num'});
ok(not $missings{'cc_exp'});

## Now, some tests using a CGI.pm object as input
use CGI;
my $q = CGI->new('cc_type=Visa');
my $results;
eval {
    $results = $validator->check($input_hashref,'default'); 
};
ok($results->missing('cc_num'), 'using CGI.pm object for input');




