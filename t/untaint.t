# A gift from Andy Lester, this trick shows me where eval's die. 
use Carp;
$SIG{__WARN__} = \&carp;
$SIG{__DIE__} = \&confess;

# We use $^X to make it easier to test with different versions of Perl. -mls
system($^X.' -I./lib -T ./t/untaint.pl Jim Beam jim@foo.bar james@bar.foo 132.10.10.2 Monroe Rufus 12345 oops 0');
