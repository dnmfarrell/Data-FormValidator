use Test::More tests => 6;
use strict;

$^W = 1;

use Data::FormValidator;

my $input_profile = {
		       required => [ qw( email_1  email_ok) ],
		       optional => ['filled','not_filled'],
		       constraint_regexp_map => {
				      '/^email/'  => "email",
			   },
			   constraints => {
				 not_filled   => 'phone',
			   },
				missing_optional_valid => 1,	   
			};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {
   email_1  => 'invalidemail',
   email_ok => 'mark@stosberg.com', 
   filled  => 'dog',
   not_filled => '',
   should_be_unknown => 1, 
};

my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};
ok (not $@);

# "not_filled" should appear valids now. 
ok (exists $valids->{'not_filled'});


# "should_be_unknown" should be still be unknown
ok($unknowns->[0] eq 'should_be_unknown');

eval {
	require CGI;
};
SKIP: {
 skip 'CGI.pm not found', 3 if $@;

 	my $q = new CGI($input_hashref);
	my ($valids, $missings, $invalids, $unknowns);
	eval{
	  ($valids, $missings, $invalids, $unknowns) = $validator->validate($q, 'default');
	};

	ok (not $@);

	# "not_filled" should appear valids now. 
	ok (exists $valids->{'not_filled'});

	# "should_be_unknown" should be still be unknown
	ok($unknowns->[0] eq 'should_be_unknown');

};

