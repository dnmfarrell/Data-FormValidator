# We use $^X to make it easier to test with different versions of Perl. -mls
system($^X.' -Iblib/lib -T ./t/12_untaint.pl Jim Beam jim@foo.bar james@bar.foo 132.10.10.2 Monroe Rufus 12345 oops 0');
