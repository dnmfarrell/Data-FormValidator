#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Data::FormValidator;

"unrelated match" =~ /match/;

my $result = Data::FormValidator->check(
    { a => 'invalid value' },    # input data
    {                            # validation profile
        untaint_all_constraints => 1,
        optional                => ['a'],
        constraints             => { a => qr/never matches/, },
    },
);

ok( not $result->success ) or diag( 'Valid: ', $result->valid );
ok( $result->has_invalid );
is_deeply( scalar($result->invalid), { 'a' => [ qr/never matches/ ] } );
