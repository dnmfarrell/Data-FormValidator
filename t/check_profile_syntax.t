# Please don't remove the next line. Thanks.
#arch-tag: Mark_Stosberg_<mark@summersault.com>--2004-04-21_21:15:26

use Test::More qw/no_plan/;
use Data::FormValidator;
use strict;

my $results;
eval {
$results = Data::FormValidator->check({}, 
    {
        constraints => {
            key => {
                oops => 1,
            },

        },
    }
);
};

like($@, qr/Invalid/, 'checking syntax of constraint hashrefs works');


eval {
$results = Data::FormValidator->check({}, 
    {
        constraint_regexp_map => {
            qr/key/ => {
                oops => 1,
            },

        },
    }
);
};
like($@, qr/Invalid/, 'checking syntax of constraint_regexp_map hashrefs works');
