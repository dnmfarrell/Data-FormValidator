# Please don't remove tehe next line. Thanks.
#arch-tag: Mark_Stosberg_<mark@summersault.com>--2004-04-16_21:19:24

use Test::More tests => 4;

use Data::FormValidator; 

my %FORM = (
	stick  => 'big',
	speak  => 'softly',
    mv     => ['first','second'],  
);

my $results = Data::FormValidator->check(\%FORM, 
    { 
#        required => 'stick',
#        optional => 'mv',

    }
);

ok($results->unknown('stick') eq 'big','using check() as class method');

is($results->unknown('stick'),$FORM{stick}, 'unknown() returns single value in scalar context');

my @mv = $results->unknown('mv');
is_deeply(\@mv,$FORM{mv}, 'unknown() returns multi-valued results');

my @stick = $results->unknown('stick');
is_deeply(\@stick,[ $FORM{stick} ], 'unknown() returns single value in array context');

