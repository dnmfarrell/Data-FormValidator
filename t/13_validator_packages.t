
use strict;
use lib ('.','../t','t/');

$^W = 1;

print "1..8\n";

use Data::FormValidator;

my $input_profile = {
			  validator_packages => 'ValidatorPackagesTest1',
			  required => ['required_1','required_2','required_3'],
			  constraints => {
				required_1 	=> 'single_validator_success_expected',
				required_2 	=> 'single_validator_failure_expected',
			  },
			    field_filters => {
			    required_3  => 'single_filter_remove_whitespace',
			  },
			};

my $validator = new Data::FormValidator({default => $input_profile});

my $input_hashref = {
	required_1  => 123,
	required_2	=> 'testing',
    required_3  => '  has whitespace  ',
};

my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};

if ($@) {
	warn "eval error: $@";
	print "not ";
}
print "ok 1\n";


print "not " unless (defined $valids->{required_1});
print "ok 2\n";

# Test to make sure that the field failed imported validator
print "not " unless (grep {/required_2/} @$invalids);
print "ok 3\n";

print "not " unless (defined $valids->{required_3});
print "ok 4\n";

print "not " unless $valids->{required_3} eq 'has whitespace';
print "ok 5\n";

#### Now test importing from multiple packages

$input_profile = {
			  validator_packages => ['ValidatorPackagesTest1','ValidatorPackagesTest2'],
			  required => ['required_1','required_2'],
			  constraints => {
				required_1 	=> 'single_validator_success_expected',
				required_2 	=> 'multi_validator_success_expected',
			  },
			};

$validator = new Data::FormValidator({default => $input_profile});

$input_hashref = {
	required_1  => 123,
	required_2	=> 'testing',
};

eval{
  ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
};


print "not " unless (defined $valids->{required_1});
print "ok 6\n";

print "not " unless (defined $valids->{required_2});
print "ok 7\n";

# Now test calling 'validate' as a class method
use Data::FormValidator;

eval {
my ($valid,$missing,$invalid) = Data::FormValidator->validate($input_hashref,{
        required=>[qw/required_1/],
        validator_packages=> 'Data::FormValidator',
    });
};
print "not " if $@;
print "ok 8\n";


