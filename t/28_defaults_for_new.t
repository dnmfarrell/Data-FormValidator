# testing passing defaults to the new constructor. -mls 05/03/03 

use Test::More tests => 3;
use strict;

use Data::FormValidator; 

my %FORM = (
	bad_email  => 'oops',
	good_email => 'great@domain.com',

	'short_name' => 'tim',
);

my $dfv = Data::FormValidator->new({},{ missing_optional_valie => 1 });

eval {
	my $results = $dfv->check(\%FORM, {});
};
like($@,qr/Invalid input profile/, 'defaults are checked for syntax');


$dfv = Data::FormValidator->new({},{ missing_optional_valid=>1 });
my $results = $dfv->check(\%FORM, {});
ok ($results->{profile}->{missing_optional_valid}, 'testing defaults appearing in profile');

$results = $dfv->check(\%FORM, { missing_optional_valid=>0});

ok (!$results->{profile}->{missing_optional_valid}, 'testing overriding defaults');





