
use strict;

$^W = 1;

use Test::More tests => 1;

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
               bad_key_which_should_trigger_error=>1,
               another_bad_key_which_should_trigger_error=>1,
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
#use Data::Dumper; warn Dumper   ($valids, $missings, $invalids, $unknowns);

ok(not $@ 
   or 
   $@ eq "Invalid input profile: keys not recognised [bad_key_which_should_trigger_error, another_bad_key_which_should_trigger_error]\n" 
   or
   $@ eq "Invalid input profile: keys not recognised [another_bad_key_which_should_trigger_error, bad_key_which_should_trigger_error]\n"
  ); 


