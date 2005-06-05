# This test is a for a bug where a value doesn't get filtered when it should
# The bug was discovered by Jeff Till, and he contributed this test, too. 

use strict;
use Test::More tests => 1;
use lib ('.','../t');
      
# Verify that multiple params passed to a constraint are being filtered

$^W = 1;
                         
  
use Data::FormValidator;
                   
my $validator = new Data::FormValidator({
   default =>
   {
      filters    =>  [ 'trim' ],
      required => [ qw/my_junk_field my_other_field/],
         constraints => {
                 my_junk_field => {
                         constraint =>  \&letters_2_var,
                         name       =>  'zipcode',
   
                 },
                 my_other_field => \&letters,
         }, 
 },
});
   
sub letters_2_var {
  if ($_[0] =~ /^[a-z]+$/i) {
    return 1;
  }
  return 0;
}
   
sub letters{
  if($_[0] =~ /^[a-z]+$/i){
    return 1;
  }
  return 0;
}

my $input_hashref =
  {
   my_junk_field => 'foo',
   my_other_field   => ' bar',
  };
            
my ($valids, $missings, $invalids, $unknowns) =
    $validator->validate($input_hashref, 'default');
   
is($invalids, undef, "all fields are valid");
