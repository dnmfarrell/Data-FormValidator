use Test::More tests => 11;
BEGIN { use_ok('Data::FormValidator::Constraints::Dates') };
use strict;

my $format = Data::FormValidator::Constraints::Dates::_prepare_date_format('MM/DD/YYYY hh?:mm:ss pp');

my ($date,$year, $month, $day, $hour, $min, $sec) = Data::FormValidator::Constraints::Dates::_parse_date_format($format, '12/02/2003 1:01:03 PM');
ok ($date eq '12/02/2003 1:01:03 PM','returning untainted date');
ok ($year == 2003, 'basic date prepare and parse test');
ok ($month == 12);
ok ($day == 2);
ok ($hour == 13);
ok ($min == 1);
ok ($sec == 3); 

use Data::FormValidator;

my $simple_profile = {
	required => [qw/date_and_time_field_bad date_and_time_field_good/],
	validator_packages => [qw/Data::FormValidator::Constraints::Dates/],
	constraints => {
		'date_and_time_field_good' => {
			constraint_method => 'date_and_time',
			params=>[\'MM/DD/YYYY hh:mm pp'],
		},
		'date_and_time_field_bad' => {
			constraint_method => 'date_and_time',
			params=>[\'MM/DD/YYYY hh:mm pp'],
		},
	},
	untaint_constraint_fields=>[qw/date_and_time_field/],
};

my $simple_data = {
	date_and_time_field_good => '12/04/2003 02:00 PM',
	date_and_time_field_bad  => 'slug',
};	


my $validator = new Data::FormValidator({
		simple  => $simple_profile,
	});

my ($valids, $missings, $invalids, $unknowns) = ({},[],{},[]);
eval{
	($valids, $missings, $invalids, $unknowns) = $validator->validate($simple_data, 'simple');
};
warn $@ unless ok ((not $@), 'eval');
ok ($valids->{date_and_time_field_good}, 'expecting date_and_time success');
ok ((grep {/date_and_time_field_bad/} @$invalids), 'expecting date_and_time failure');
