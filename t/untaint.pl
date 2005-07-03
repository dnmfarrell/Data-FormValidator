#!/usr/bin/perl -wT

use strict;

use Test::More qw/no_plan/;
use Data::FormValidator;
use Data::FormValidator::Constraints qw/:closures/;

# A gift from Andy Lester, this trick shows me where eval's die. 
use Carp;
$SIG{__WARN__} = \&carp;
$SIG{__DIE__} = \&confess;

$ENV{PATH} = "/bin/";

sub is_tainted {
    my $val = shift;
    # What does kill do here? -mls
    return !eval { $val++, kill 0; 1; };
}

my $data1 = { 
    firstname  => $ARGV[0], #Jim
};

my $data2 = {
    lastname   => $ARGV[1], #Beam
    email1     => $ARGV[2], #jim@foo.bar
    email2     => $ARGV[3], #james@bar.foo
};

my $data3 = {
    ip_address => $ARGV[4], #132.10.10.2
    cats_name  => $ARGV[5], #Monroe
    dogs_name  => $ARGV[6], #Rufus
};

my $data4 = {
	zip_field1 => [$ARGV[7],$ARGV[7]],  #12345 , 12345
	zip_field2 => [$ARGV[7],$ARGV[8]],  #12345 , oops
};


my $profile = 
{
    rules1 => {
		untaint_constraint_fields => "firstname",
		required => "firstname",
		constraints => {
			firstname => '/^\w{1,15}$/'
		},
	},
    rules2 => {
		untaint_constraint_fields => [ qw( lastname email1 )],
		required     =>
		[ qw( lastname email1 email2) ],
		constraints  => {
			lastname => '/^\w{1,10}$/',
			email1 => "email",
			email2 => "email",
		}   
	},   
    rules2_closure => {
		untaint_constraint_fields => [ qw( email1  )],
		required     => [ qw( email1 email2) ],
		constraint_methods  => {
            email1 => email(),
			email2 => email(),
		}   
	},   
    rules3 => {
		untaint_all_constraints => 1,
		required => 
		[ qw(ip_address cats_name dogs_name) ],
		constraints => {
			ip_address => "ip_address",
			cats_name  => '/^Felix$/',
			dogs_name  => 'm/^rufus$/i',
	    }
    },
	rules4 => {
		untaint_constraint_fields=> ['zip_field1','zip_field2'],
		required=>[qw/zip_field1 zip_field2/],
		constraints=> {
			zip_field1=>'zip',
		},
	},
};

my $validator = new Data::FormValidator($profile);

#Rules #1
my ( $valid, $missing, $invalid, $unknown );
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data1, "rules1"); };

is($@,'','avoided eval error');
ok($valid->{firstname}, 'found firstname'); 
ok(! is_tainted($valid->{firstname}), 'firstname is untainted');
is($valid->{firstname},$data1->{firstname}, 'firstname has expected value');




#Rules #2
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data2, "rules2"); };   

is($@,'','avoided eval error');
ok($valid->{lastname});
ok(!is_tainted($valid->{lastname}));
is($valid->{lastname},$data2->{lastname});

ok($valid->{email1});
ok(!is_tainted($valid->{email1}));
is($valid->{email1},$data2->{email1});

ok($valid->{email2});
ok(is_tainted($valid->{email2}), 'email2 is tainted');
is($valid->{email2},$data2->{email2});

# Rules2 with closures 
{
    my ($result,$valid);
    eval { $result = $validator->check(  $data2, "rules2_closure"); };   
    is($@,'', 'survived eval');
    $valid = $result->valid();

    ok($valid->{email1}, "found email1 in \%valid") || warn Dumper ($data2,$result);
    ok(!is_tainted($valid->{email1}), "email one is not tainted");
    is($valid->{email1},$data2->{email1}, "email1 identity");
}


#Rules #3
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data3, "rules3"); };   

ok(!$@);

ok($valid->{ip_address});
ok(!is_tainted($valid->{ip_address}));
is($valid->{ip_address},$data3->{ip_address});

#in this case we're expecting no match
ok(!(exists $valid->{cats_name}), 'cats_name is not valid');
is($invalid->[0], 'cats_name', 'cats_name fails constraint');

ok($valid->{dogs_name});
ok(!is_tainted($valid->{dogs_name}));
is($valid->{dogs_name},$data3->{dogs_name});

# Rules # 4
eval {  ( $valid, $missing, $invalid, $unknown ) = $validator->validate(  $data4, "rules4"); };   
ok(!$@, 'avoided eval error');

ok(!is_tainted($valid->{zip_field1}->[0]),
        'zip_field1 should be untainted');

ok(is_tainted($valid->{zip_field2}->[0]),
    'zip_field2 should be tainted');


my $results = Data::FormValidator->check(
    {
    qr_re_no_parens => $ARGV[9], # 0
    qr_re_parens    => $ARGV[9], # 0

    },
    {
            required => [qw/qr_re_no_parens qr_re_parens/],
             constraints=>{
                 qr_re_no_parens => qr/^.*$/,
                 qr_re_parens    => qr/^(.*)$/,
             },
             untaint_all_constraints =>1
         });

is($results->valid('qr_re_no_parens'),0,'qr RE without parens in untainted');
is($results->valid('qr_re_parens')   ,0,'qr RE with    parens in untainted');
