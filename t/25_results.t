use Test::More tests => 4;

use Data::FormValidator; 

my %FORM = (
	stick  => 'big',
	speak  => 'softly',
    mv     => ['first','second'],  
);

my $results = Data::FormValidator->check(\%FORM, 
    { 
        required => 'stick',
        optional => 'mv',

    }
);

ok($results->valid('stick') eq 'big','using check() as class method');

is($results->valid('stick'),$FORM{stick}, 'valid() returns single value in scalar context');

my @mv = $results->valid('mv');
is_deeply(\@mv,$FORM{mv}, 'valid() returns multi-valued results');

my @stick = $results->valid('stick');
is_deeply(\@stick,[ $FORM{stick} ], 'valid() returns single value in array context');



