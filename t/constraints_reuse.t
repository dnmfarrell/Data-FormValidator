#!/usr/bin/perl

# This test is to confirm that values are preserved
# for input data when used with multiple constraints
# as 'params'

use Test::More tests => 2;
use Data::FormValidator;
use strict;

my %data = (
  'depart_date'         => '2004',
  'return_date'         => '2005',
);

my %profile = (
  required => [qw/
    depart_date
    return_date
    /],
  filters => ['trim'],
  constraints => {
      depart_date => {
        name       => 'expected_to_succeed',
        constraint => sub {
            my ($depart,$return) = @_;
            return ($depart < $return);
        },
        params     => [qw/depart_date return_date/],
      },
      return_date => {
        name       => 'built_to_fail',
        constraint => sub {
            my ($depart,$return) = @_;
            return ($depart > $return);
        },
        params     => [qw/depart_date return_date/],
      },
  },
  missing_optional_valid => 1,
  msgs => {
    format => 'error(%s)',
    constraints => {
        'valid_date' => 'bad date',
        'depart_le_return' => 'depart is greater than return',
      },
  },
);


my $results = Data::FormValidator->check(\%data, \%profile);

ok(!$results->valid('return_date'), 'first constraint applied intentionally fails');
ok($results->valid('depart_date'),  
    'second constraint still has access to value of field used in first failed constraint.');

