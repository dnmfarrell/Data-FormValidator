# checks for correct behavior when $input_profile->{'required'}
# is not specified; fails if _arrayify() does not return an empty list

use strict;

$^W = 1;

use Test::More tests => 2;

use Data::FormValidator;

my $input_profile = {
		       optional => [ qw( email ) ],
                    };

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {email => 'bob@example.com',
                    };

my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
ok(not $@);
is(@$missings, 0);
