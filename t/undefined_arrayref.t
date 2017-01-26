use Test::More tests => 1;
use Data::FormValidator;
use strict;

my ( $valid, $missing, $invalid, $unknown ) = Data::FormValidator->validate({}, {} );
ok(  (ref $invalid eq 'ARRAY'), "no invalid fields are returned as an arrayref");

