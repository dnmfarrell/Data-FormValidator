use strict;
use Test;
use lib ('.','../t');

# Verify that multiple params passed to a constraint are being handled correctly

$^W = 1;

BEGIN { plan tests => 4 }

use Data::FormValidator;

my $validator = new Data::FormValidator({
   default =>
   {
    required => [ qw/my_zipcode_field my_other_field/],
	 constraints => { 
		 my_zipcode_field => { 
			 constraint =>  \&zipcode_check,
			 name       =>  'zipcode',
			 params     =>  [ 'my_zipcode_field', 'my_other_field' ],
		 },
	 },
 },
  });

my @args_for_check;		# to control which args were given

sub zipcode_check {
  @args_for_check = @_;
  if ($_[0] == 402015 and $_[1] eq 'mapserver_rulez') {
    return 1;
  }
  return 0;
}

my $input_hashref =
  {
   my_zipcode_field => '402015',
   my_other_field   => 'mapserver_rulez',
  };

my ($valids, $missings, $invalids, $unknowns);

eval{
  ($valids, $missings, $invalids, $unknowns) =
    $validator->validate($input_hashref, 'default');
};

if ($@) {
  print "not ok 1\n";
  warn "eval error: $@";
}
else {
  print "ok 1\n";
}

unless (grep { (ref $_) eq 'ARRAY' } @$invalids) {
  print "ok 2\n";
}
else {
  print "not ok 2\n";
  warn $#{$invalids};
}

if ($#args_for_check == 1 and
    $args_for_check[0] == 402015 and
    $args_for_check[1] eq 'mapserver_rulez') {
  print "ok 3\n";
} else {
  warn "\nwaited for 402015 mapserver_rulez
got        @args_for_check\n";
  print "not ok 3\n";
}

print "ok 4\n";

# Local variables:
# compile-command: "cd .. && make test"
# End:
