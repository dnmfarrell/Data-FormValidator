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

