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


