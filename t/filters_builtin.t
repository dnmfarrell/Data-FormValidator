use Test::More qw/no_plan/;

use Data::FormValidator::Filters (qw/:filters/);
$string = filter_dollars('There is $0.11e money in here somewhere');
is($string, '0.11', "filter_dollars works as expected");
