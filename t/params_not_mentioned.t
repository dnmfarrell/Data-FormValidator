use strict;
use Test::More;
use Data::FormValidator;
plan(tests => 5);

# Test that constrants can refer to fields that are not mentioned
# in 'required' or 'optional'

my $profile = {
    required    => [qw(foo)],
    optional    => [qw(bar)],
    constraints => {
        foo => {
            constraint  => sub {
                if( defined $_[0] && defined $_[1] ) {
                    return $_[0] eq $_[1];
                } else {
                    return;
                }
             },
            params      => [qw(foo baz)],
        },
    },
};
my $input = {
    foo => 'stuff',
    bar => 'other stuff',
    baz => 'stuff',
};

my $results = Data::FormValidator->check($input, $profile);
ok(! $results->has_invalid(), 'no_invalids' );
ok( $results->valid('foo'), 'foo valid');

{
    # with CGI object as input. 
    use CGI;
    my $q = CGI->new($input);
    my $results;
    eval { $results = Data::FormValidator->check($q, $profile); };
    is ($@, '', 'survived eval');
    ok(! $results->has_invalid(), 'no_invalids' );
    ok( $results->valid('foo'), 'foo valid');

}

