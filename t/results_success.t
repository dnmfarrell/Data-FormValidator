use Test::More tests => 2;
use Data::FormValidator;

my %FORM = (
    good    => '1',
    extra   => '2',
);

my $results = Data::FormValidator->check(\%FORM,
    {
        required => 'good',
    }
);

ok($results->success, 'success with unknown');

# test an unsuccessful success
$FORM{bad} = -1;
$results = Data::FormValidator->check(
    \%FORM,
    {
        required    => [qw(good bad)],
        optional    => [qw(extra)],
        constraints => {
            good => sub { return shift > 0 },
            bad  => sub { return shift > 0 },
        },
    },
);

ok(!$results->success, 'not success()');

