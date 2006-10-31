#!/usr/bin/perl
# 
# in response to bug report 2006/10/25 by Brian E. Lozier <brian@massassi.net>
# test script by Evan A. Zacks <zackse@cpan.org>
#
# The problem was that when specifying constraint_methods in a profile and
# using the name of a built-in (e.g., "zip") as the constraint, the built-in
# (match_zip or valid_zip) ended up being called as a method rather than a
# function.  So rather than having the input value as the first parameter, the
# function would receive both a DFV results object and the input value.

use strict;

use Test::More tests => 5;

use_ok('Data::FormValidator');

{
  my %profile = (
      required => ['zip'],
      constraint_methods => {
          zip => 'zip',
      }
  );

  my %data = (
      zip => 56567
  );

  my $r = Data::FormValidator->check(\%data, \%profile);

  ok( $r->valid('zip'),
      'constraint_method "zip" qualifies string to built-in function' );
}

{
  my %profile = (
      required => ['zip'],
      constraint_methods => {
          zip => ['zip'],
      }
  );

  my %data = (
      zip => 56567
  );

  my $r = Data::FormValidator->check(\%data, \%profile);

  ok( $r->valid('zip'), '... also works as a string in a list' );
}

{
  my %profile = (
      required => ['zip'],
      untaint_all_constraints => 1,
      constraint_methods => {
          zip => 'zip',
      }
  );

  my %data = (
      zip => 56567
  );

  my $r = Data::FormValidator->check(\%data, \%profile);

  ok( $r->valid('zip'), '... and works with untainting' );
}

{
  my %profile = (
      required => ['zip'],
      untaint_all_constraints => 1,
      constraint_methods => {
        zip => {
          name => "zipper",
          constraint => 'zip',
        },
      }
  );

  my %data = (
      zip => 56567
  );

  my $r = Data::FormValidator->check(\%data, \%profile);

  ok( $r->valid('zip'), '... and works with a hash declaration / constraint' );
}
