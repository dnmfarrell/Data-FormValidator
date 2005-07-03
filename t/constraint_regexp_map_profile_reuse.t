use Test::More (qw/no_plan/);
use Data::FormValidator;
use Data::Dumper;

my $profile = {
    required => [qw( test1 )],
    constraint_regexp_map => {
        qr/^test/ => 'email',
    },
};

my $data = {
    test1 => 'not an email',
};

my $results1 = Data::FormValidator->check($data, $profile);
my $c1 = {%{ $profile->{constraints} }};
my $results2 = Data::FormValidator->check($data, $profile);
my $c2 = {%{ $profile->{constraints} }};

is_deeply($results1,$results2, "constraints aren't duped when profile with constraint_regexp_map is reused");
is_deeply($c1,$c2, "constraints aren't duped when profile with constraint_regexp_map is reused");

