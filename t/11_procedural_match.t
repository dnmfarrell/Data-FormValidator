use strict;
#Check that the match_* routines are nominally working.

$^W = 1;

print "1..25\n";



use Data::FormValidator qw(:validators :matchers);

my $rv;
my $invalid = "fake value";

#For CC Exp test
my @time = localtime(time);

my %tests = ( 
    match_american_phone => "555-555-5555",
    match_cc_exp => "10/" . sprintf("%.2d", ($time[5] - 99)), 
    match_cc_type => "MasterCard",
    match_email => 'foo@domain.com',
    match_ip_address => "64.58.79.230",
    match_phone => "123-456-7890",
    match_postcode => "T2N 0E6",
    match_province => "NB",
    match_state => "CA",
    match_state_or_province => "QC",
    match_zip => "94112",
    match_zip_or_postcode => "50112",
);

my $i = 1;

foreach my $function (keys(%tests)) {
    my $rv;
    my $val = $tests{$function};
    my $is_valid = "\$rv = $function('$val');";
    my $not_valid = "\$rv = $function('$invalid');";
    
    eval $is_valid;
    if ($@ or ($rv ne $val)) {
	print "NOT ";
    }
    print "ok $i\n";
    print sprintf("# %-25s", $function)
	. " using"
	. sprintf("%-16s\n", " valid value. ");
    $i++;

    eval $not_valid;
    if ($@ or $rv) {
	print "not ";
    }
    print "ok $i\n";
    print sprintf("# %-25s", $function)
	. " using"
	. sprintf("%-16s\n", " invalid value. ");
    $i++;
}
    
#Test cc_number seperately since i don't know a valid cc number
my $rv;
eval "\$rv = match_cc_number('$invalid', 'm')";

if ($@ or $rv) {
    print "not ";
}
print "ok $i\n";
print sprintf("%-25s", "match_cc_number")
    . " using"
    . sprintf("%-16s", " invalid value. ");
