#
#    Filters.pm - Common filters for use in Data::FormValidator.
#
#    This file is part of Data::FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#

package Data::FormValidator::Filters;
use strict;
use vars qw/$AUTOLOAD @ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = '3.50';

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    filter_alphanum
	filter_decimal
	filter_digit
	filter_dollars
	filter_integer
	filter_lc
	filter_neg_decimal
	filter_neg_integer
	filter_phone
	filter_pos_decimal
	filter_pos_integer
	filter_quotemeta
	filter_sql_wildcard
	filter_strip
	filter_trim
	filter_uc
	filter_ucfirst
);

%EXPORT_TAGS = (
    filters => \@EXPORT_OK,
);

sub DESTROY {}

=pod

=head1 NAME

Data::FormValidator::Filters - Basic set of filters available in an Data::FormValidator profile.


=head1 SYNOPSIS

    use Data::FormValidator;

    my $validator = new Data::FormValidator( "/home/user/input_profiles.pl" );
    my $results = $validator->check(  \%fdat, "customer_infos" );

=head1 DESCRIPTION

These are the builtin filters which may be specified as a name in the
I<filters> and I<field_filters> parameters of the input profile. You may
also call these functions directly through the procedural interface by 
either importing them directly or importing the whole I<:filters> group. For
example, if you want to access the I<trim> function directly, you could either do:

    use Data::FormValidator::Filters (qw/filter_trim/);
    or
    use Data::FormValidator::Filters (:filters);

    $string = filter_trim($string);

Notice that when you call filters directly, you'll need to prefix the filter name with
"filter_".

=over

=item trim

Remove white space at the front and end of the fields.

=cut

sub filter_trim {
    my $value = shift;
	return unless defined $value;

    # Remove whitespace at the front
    $value =~ s/^\s+//o;

    # Remove whitespace at the end
    $value =~ s/\s+$//o;

    return $value;
}

=pod

=item strip

Runs of white space are replaced by a single space.

=cut

sub filter_strip {
    my $value = shift;
	return unless defined $value;

    # Strip whitespace
    $value =~ s/\s+/ /g;

    return $value;
}

=pod

=item digit

Remove non digits characters from the input.

=cut

sub filter_digit {
    my $value = shift;
	return unless defined $value;

    $value =~ s/\D//g;

    return $value;
}

=pod

=item alphanum

Remove non alphanumerical characters from the input.

=cut

sub filter_alphanum {
    my $value = shift;
	return unless defined $value;
    $value =~ s/\W//g;
    return $value;
}

=pod

=item integer

Extract from its input a valid integer number.

=cut

sub filter_integer {
    my $value = shift;
	return unless defined $value;
    $value =~ tr/0-9+-//dc;
    ($value) =~ m/([-+]?\d+)/;
    return $value;
}

=pod

=item pos_integer

Extract from its input a valid positive integer number.

=cut

sub filter_pos_integer {
    my $value = shift;
	return unless defined $value;
    $value =~ tr/0-9+//dc;
    ($value) =~ m/(\+?\d+)/;
    return $value;
}

=pod

=item neg_integer

Extract from its input a valid negative integer number.

=cut

sub filter_neg_integer {
    my $value = shift;
	return unless defined $value;
    $value =~ tr/0-9-//dc;
    ($value) =~ m/(-\d+)/;
    return $value;
}

=pod

=item decimal

Extract from its input a valid decimal number.

=cut

sub filter_decimal {
    my $value = shift;
	return unless defined $value;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.+-//dc;
    ($value) =~ m/([-+]?\d+\.?\d*)/;
    return $value;
}

=pod

=item pos_decimal

Extract from its input a valid positive decimal number.

=cut

sub filter_pos_decimal {
    my $value = shift;
	return unless defined $value;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.+//dc;
    ($value) =~ m/(\+?\d+\.?\d*)/;
    return $value;
}

=pod

=item neg_decimal

Extract from its input a valid negative decimal number.

=cut

sub filter_neg_decimal {
    my $value = shift;
	return unless defined $value;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.-//dc;
    ($value) =~ m/(-\d+\.?\d*)/;
    return $value;
}

=pod

=item dollars

Extract from its input a valid number to express dollars like currency.

=cut

sub filter_dollars {
    my $value = shift;
	return unless defined $value;
    $value =~ tr/,/./;
    $value =~ tr/0-9.+-//dc;
    ($value) =~ m/(\d+\.?\d?\d?)/;
    return $value;
}

=pod

=item phone

Filters out characters which aren't valid for an phone number. (Only
accept digits [0-9], space, comma, minus, parenthesis, period and pound [#].)

=cut

sub filter_phone {
    my $value = shift;
	return unless defined $value;
    $value =~ s/[^\d,\(\)\.\s,\-#]//g;
    return $value;
}

=pod

=item sql_wildcard

Transforms shell glob wildcard (*) to the SQL like wildcard (%).

=cut

sub filter_sql_wildcard {
    my $value = shift;
	return unless defined $value;
    $value =~ tr/*/%/;
    return $value;
}

=pod

=item quotemeta

Calls the quotemeta (quote non alphanumeric character) builtin on its
input.

=cut

sub filter_quotemeta {
	return unless defined $_[0];
    quotemeta $_[0];
}

=pod

=item lc

Calls the lc (convert to lowercase) builtin on its input.

=cut

sub filter_lc {
	return unless defined $_[0];
    lc $_[0];
}

=pod

=item uc

Calls the uc (convert to uppercase) builtin on its input.

=cut

sub filter_uc {
	return unless defined $_[0];
    uc $_[0];
}

=pod

=item ucfirst

Calls the ucfirst (Uppercase first letter) builtin on its input.

=cut

sub filter_ucfirst {
	return unless defined $_[0];
    ucfirst $_[0];
}


1;

__END__

=pod

=back

=head1 SEE ALSO

Data::FormValidator(3) Data::FormValidator::Constraints(3)

=head1 AUTHOR

Author:  Francis J. Lacoste <francis.lacoste@iNsu.COM>
Maintainer: Mark Stosberg <mark@summersault.com>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut

