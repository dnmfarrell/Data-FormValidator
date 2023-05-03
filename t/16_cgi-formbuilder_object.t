#!/usr/bin/env perl
use strict;
use warnings;
use lib ( '.', '../t' );
use Test::More;
use Data::FormValidator;

# This script tests whether a CGI::FormBuilder.pm object can be used to provide the input data
# cngarrison - 2021-09-14

eval { require CGI::FormBuilder;CGI::FormBuilder->VERSION(3.08); };
plan skip_all => 'CGI::FormBuilder 3.08 or higher not found' if $@;

my $input_profile = {
	required           => ['my_zipcode_field'],
	constraint_methods => {
		my_zipcode_field => qr/^[A-Za-z]+\ [A-Za-z]+$/,
	}
};

my $validator = new Data::FormValidator( { default => $input_profile } );

my $fb;
eval {
	$fb = CGI::FormBuilder->new(
		fields   => [qw(my_zipcode_field)],
		values   => { my_zipcode_field => 'big brown' },
		#validate => $validator,
	);
};
ok( not $@ );

my ( $valids, $missings, $invalids, $unknowns );
eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $fb, 'default' );
};

is( $valids->{my_zipcode_field}, 'big brown' );
done_testing;
