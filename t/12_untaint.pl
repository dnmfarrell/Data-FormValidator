#!/usr/bin/perl -wT

use strict;

use Data::FormValidator;

$ENV{PATH} = "/bin/";

print "1..12\n";

sub is_tainted {
    my $val = shift;
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

eval {  ( $valid, $missing, $invalid, $unknown )
	    = $validator->validate(  $data1, "rules1");
    };

if ($@ 
    or !$valid->{firstname} 
    or is_tainted($valid->{firstname})
    or ($valid->{firstname} ne $data1->{firstname})) {
    print "not " 
}
print "ok 1\n";

#Rules #2
eval {  ( $valid, $missing, $invalid, $unknown )
	    = $validator->validate(  $data2, "rules2");
    };   

if ($@) {
    print "not ";
}
print "ok 2\n";

if (!$valid->{lastname} 
    or is_tainted($valid->{lastname})
    or ($valid->{lastname} ne $data2->{lastname})) {
    print "not ";
}

print "ok 3\n";

if (!$valid->{email1} 
    or is_tainted($valid->{email1})
    or ($valid->{email1} ne $data2->{email1})) {
    print "not ";
}
print "ok 4\n";

#In this case we're testing to make sure email2 wasn't untainted
if (!$valid->{email2} 
    or !is_tainted($valid->{email2})
    or ($valid->{email2} ne $data2->{email2})) {
    print "not ";
}
print "ok 5\n";

#Rules #3
eval {  ( $valid, $missing, $invalid, $unknown )
	    = $validator->validate(  $data3, "rules3");
    };   

if ($@) {
    print "not ";
}
print "ok 6\n";

if (!$valid->{ip_address} 
    or is_tainted($valid->{ip_address})
    or ($valid->{ip_address} ne $data3->{ip_address})) {
    print "not ";
}
print "ok 7\n";

#in this case we're expecting no match
if ($valid->{cats_name} 
    or $invalid->[0] ne "cats_name") {
    print "not ";
}
print "ok 8\n";

if (!$valid->{dogs_name} 
    or is_tainted($valid->{dogs_name})
    or ($valid->{dogs_name} ne $data3->{dogs_name})) {
    print "not ";
}
print "ok 9\n";

# Rules # 4
eval {  ( $valid, $missing, $invalid, $unknown )
	    = $validator->validate(  $data4, "rules4");
    };   

if ($@) {
    print "not ";
}
print "ok 10\n";
# zip_field1 should be untainted
print "not " if is_tainted($valid->{zip_field1}->[0]);
print "ok 11\n";

# zip_field2 should be tainted
print "not " unless is_tainted($valid->{zip_field2}->[0]);
print "ok 12\n";


