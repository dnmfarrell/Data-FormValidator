use strict;
#Check that the valid_* routines are nominally working.

$^W = 1;

print "1..26\n";

	use Data::FormValidator qw(:validators :matchers);



my $rv;
my $invalid = "fake value";

#For CC Exp test
my @time = localtime(time);

my %tests = ( 
    valid_american_phone => "555-555-5555",
    valid_cc_exp => "10/" . sprintf("%.2d", ($time[5] - 99)), 
    valid_cc_type => "MasterCard",
    valid_email => 'foo@domain.com',
    valid_ip_address => "64.58.79.230",
    valid_phone => "123-456-7890",
    valid_postcode => "T2N 0E6",
    valid_province => "NB",
    valid_state => "CA",
    valid_state_or_province => "QC",
    valid_zip => "94112",
    valid_zip_or_postcode => "50112",
);

my $i = 1;

foreach my $function (keys(%tests)) {
    my $rv;
    my $val = $tests{$function};
    my $is_valid = "\$rv = $function('$val');";
    my $not_valid = "\$rv = $function('$invalid');";
    
    eval $is_valid;
    if ($@ or $rv != 1) {
		warn $@;
		print "not ";
    }
    print "ok $i\n";
    print sprintf("# %-25s", $function)
	. " using"
	. sprintf("%-16s\n", " (valid value)");
    $i++;

    eval $not_valid;
    if ($@ or $rv) {
	print "not ";
    }
    print "ok $i\n";
    print sprintf("# %-25s", $function)
	. " using"
	. sprintf("%-16s\n", " (invalid value)");
    $i++;
}
    
#Test cc_number seperately since i don't know a valid cc number
my $rv;
eval "\$rv = valid_cc_number('$invalid', 'm')";

if ($@ or $rv) {
    print "not ";
}
print "ok $i\n";
print sprintf("# %-25s", "valid_cc_number")
    . " using"
    . sprintf("%-16s", " (invalid value)\n");

$i++;

#Test fake validation routine
eval "\$rv = valid_foobar('$invalid', 'm')";

if (!$@) {
    print "not ";
}
print "ok $i\n";
print sprintf("# %-25s\n", "Fake Valid Routine");
