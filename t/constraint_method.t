#!/usr/bin/perl

use Test::More qw/no_plan/;

use Data::FormValidator;

my $result = Data::FormValidator->check({ field => 'value' }, {
        required => 'field',
        constraints => {
            field => {
                constraint_method => sub { 
                    my $dfv = shift;
                    my $name = $dfv->get_current_constraint_name;
                    is($name, 'test_name', "get_current_constraint_name works");
                },
                name => 'test_name',
            }
        },
    });

{
    my $result = Data::FormValidator->check({
            to_pass => 'value', 
            to_fail => 'value', 
        }, {
            required => [qw/to_pass to_fail/],
            constraint_methods => {
                to_pass =>  qr/value/,
                to_fail =>  qr/wrong/,
            }});

    ok ( $result->invalid('to_fail'), "using qr with constraint_method fails as expected");
    ok ( $result->valid('to_pass'), "using qr with constraint_method succeeds as expected");
}
