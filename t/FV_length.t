#!/usr/bin/perl
use Test::More 'no_plan';
use strict;
BEGIN {
    use_ok('Data::FormValidator'); 
}

use Data::FormValidator::Constraints qw( 
    FV_max_length 
    FV_min_length 
    FV_length_between
);

my $result = Data::FormValidator->check({
         first_names => 'Too long',   
         keywords    => 'a',
         ok          => 'Good',
    },
    {
        required => [qw/first_names keywords ok/],
        constraint_methods => {
            first_names => FV_max_length(3),
            keywords    => FV_length_between(5,8),
            too_long    => FV_min_length(3),  
            ok          => {
                constraint_method => FV_length_between(3,6),
                name => 'ok_length',
            }

        },
        msgs => {
            constraints => {
                ok_length => 'Not an OK length',
                length    => 'Wrong Length',
            }
        },
    });

ok(defined $result);

# Test multi-line input: someone might be using this for a textarea or somesuch

my $multiline_result = Data::FormValidator->check(
    {
        alpha   => "apple\naeroplane\n",      # 16 char
        beta    => "bus\nbuffalo\n",          # 12 char
        charlie => "cat\ncoconut\ncoffee\n",  # 19 char
        delta   => "dog\ndinosaur\n",         # 13 char
        echo    => "egg\nelephant\nemu\n",    # 17 char
        foxtrot => "flan\nfrog\n",            # 10 char
        golf    => "giraffe\ngrapefruit\n",   # 19 char
    },
    {
        required => [qw/alpha beta charlie delta echo foxtrot golf/],
        constraint_methods => {
            alpha   => FV_max_length(16),           # max length
            beta    => FV_max_length(11),           # too long
            charlie => FV_min_length(19),           # just long enough
            delta   => FV_min_length(14),           # too short
            echo    => FV_length_between(16,18),    # just right 
            foxtrot => FV_length_between(11,13),    # too short
            golf    => FV_length_between(16,18),    # too long
        },
    },
);

ok( $multiline_result->valid('alpha'),     'multiline FV_max_length in bounds'    );
ok( $multiline_result->invalid('beta'),    'multiline FV_max_length too long'     );
ok( $multiline_result->valid('charlie'),   'multiline FV_min_length in bounds'    );
ok( $multiline_result->invalid('delta'),   'multiline FV_min_length too short'    );
ok( $multiline_result->valid('echo'),      'multiline FV_length_between in bounds');
ok( $multiline_result->invalid('foxtrot'), 'multiline FV_length_between too short');
ok( $multiline_result->invalid('golf'),    'multiline FV_length_between too long' );
