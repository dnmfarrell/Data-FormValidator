#
#    Constraints.pm - Standard constraints for use in Data::FormValidator.
#
#    This file is part of Data::FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@Contre.COM>
#    Maintainer: Mark Stosberg <mark@summersault.com>
#
#    Copyright (C) 1999,2000 iNsu Innovations Inc.
#    Copyright (C) 2001 Francis J. Lacoste
#    Parts Copyright 1996-1999 by Michael J. Heins <mike@heins.net>
#    Parts Copyright 1996-1999 by Bruce Albrecht  <bruce.albrecht@seag.fingerhut.com>
#
#    Parts of this module are based on work by
#    Bruce Albrecht, <bruce.albrecht@seag.fingerhut.com> contributed to
#    MiniVend.
#
#    Parts also based on work by Michael J. Heins <mikeh@minivend.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
package Data::FormValidator::Constraints;
use strict;
use vars qw/$AUTOLOAD @ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = 3.63;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	valid_american_phone
	valid_cc_exp
	valid_cc_number
	valid_cc_type
	valid_email
	valid_ip_address
	valid_phone
	valid_postcode
	valid_province
	valid_state
	valid_state_or_province
	valid_zip
	valid_zip_or_postcode
	match_american_phone
	match_cc_exp
	match_cc_number
	match_cc_type
	match_email
	match_ip_address
	match_phone
	match_postcode
	match_province
	match_state
	match_state_or_province
	match_zip
	match_zip_or_postcode	
);

%EXPORT_TAGS = (
    validators => [qw/
		valid_american_phone
		valid_cc_exp
		valid_cc_number
		valid_cc_type
		valid_email
		valid_ip_address
		valid_phone
		valid_postcode
		valid_province
		valid_state
		valid_state_or_province
		valid_zip
		valid_zip_or_postcode
/],
    matchers => [qw/
		match_american_phone
		match_cc_exp
		match_cc_number
		match_cc_type
		match_email
		match_ip_address
		match_phone
		match_postcode
		match_province
		match_state
		match_state_or_province
		match_zip
		match_zip_or_postcode
/],		
);


sub DESTROY {}

=pod

=head1 NAME

Data::FormValidator::Constraints - Basic sets of constraints on input profile.

=head1 SYNOPSIS

In an Data::FormValidator profile:

    constraints  =>
	{
	    email	=> "email",
	    fax		=> "american_phone",
	    phone	=> "american_phone",
	    state	=> "state",
	},

=head1 DESCRIPTION

Those are the builtin constraints that can be specified by name in the input
profiles. 

=cut

sub AUTOLOAD {
    my $name = $AUTOLOAD;

    # Since all the valid_* routines are essentially identical we're
    # going to generate them dynamically from match_ routines with the same names.
	if ($name =~ m/^(.*::)valid_(.*)/) {
		no strict qw/refs/;
		return defined &{$1.'match_' . $2}(@_);
    }
    else { 
		die "subroutine '$name' not found"; 
	}
}

=pod

=over 

=item email

Checks if the email LOOKS LIKE an email address. This checks if the
input contains one @, and a two level domain name. The address portion
is checked quite liberally. For example, all those probably invalid
address would pass the test :

    nobody@top.domain
    %?&/$()@nowhere.net
    guessme@guess.m

=cut

# Many of the following validators are taken from
# MiniVend 3.14. (http://www.minivend.com)
# Copyright 1996-1999 by Michael J. Heins <mike@heins.net>

sub match_email {
    my $email = shift;

    if ($email =~ /^(([a-z0-9_\.\+\-\=\?\^\#]){1,64}\@(([a-z0-9\-]){1,251}\.){1,252}[a-z0-9]{2,4})$/i) {
	    return $1;
    }
    else { 
        return undef; 
    }
}

my $state = <<EOF;
AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD
MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA PR RI
SC SD TN TX UT VT VA WA WV WI WY DC AP FP FPO APO GU VI
EOF

my $province = <<EOF;
AB BC MB NB NF NS NT ON PE QC SK YT YK
EOF

=pod

=item state_or_province

This one checks if the input correspond to an american state or a canadian
province.

=cut

sub match_state_or_province {
    my $match;
    if ($match = match_state(@_)) { return $match; }
    else {return match_province(@_); }
}

=pod

=item state

This one checks if the input is a valid two letter abbreviation of an 
american state.

=cut

sub match_state {
    my $val = shift;
    if ($state =~ /\b($val)\b/i) {
	return $1;
    }
    else { return undef; }
}

=pod

=item province

This checks if the input is a two letter canadian province
abbreviation.

=cut

sub match_province {
    my $val = shift;
    if ($province =~ /\b($val)\b/i) {
	return $1;
    }
    else { return undef; }
}

=pod

=item zip_or_postcode

This constraints checks if the input is an american zipcode or a
canadian postal code.

=cut

sub match_zip_or_postcode {
    my $match;
    if ($match = match_zip(@_)) { return $match; }
    else {return match_postcode(@_)};
}
=pod

=item postcode

This constraints checks if the input is a valid Canadian postal code.

=cut

sub match_postcode {
    my $val = shift;
    #$val =~ s/[_\W]+//g;
    if ($val =~ /^([ABCEGHJKLMNPRSTVXYabceghjklmnprstvxy][_\W]*\d[_\W]*[A-Za-z][_\W]*[- ]?[_\W]*\d[_\W]*[A-Za-z][_\W]*\d[_\W]*)$/) {
	return $1;
    }
    else { return undef; }
}

=pod

=item zip

This input validator checks if the input is a valid american zipcode :
5 digits followed by an optional mailbox number.

=cut

sub match_zip {
    my $val = shift;
    if ($val =~ /^(\s*\d{5}(?:[-]\d{4})?\s*)$/) {
	return $1;
    }
    else { return undef; }
}

=pod

=item phone

This one checks if the input looks like a phone number, (if it
contains at least 6 digits.)

=cut

sub match_phone {
    my $val = shift;

    if ($val =~ /^((?:\D*\d\D*){6,})$/) {
	return $1;
    }
    else { return undef; }
}

=pod

=item american_phone

This constraints checks if the number is a possible North American style
of phone number : (XXX) XXX-XXXX. It has to contains 7 or more digits.

=cut

sub match_american_phone {
    my $val = shift;

    if ($val =~ /^((?:\D*\d\D*){7,})$/) {
	return $1;
    }
    else { return undef; }
}


=pod

=item cc_number

This is takes two parameters, the credit card number and the credit cart
type. You should take the hash reference option for using that constraint.

The number is checked only for plausibility, it checks if the number could
be valid for a type of card by checking the checksum and looking at the number
of digits and the number of digits of the number.

This functions is only good at weeding typos and such. IT DOESN'T
CHECK IF THERE IS AN ACCOUNT ASSOCIATED WITH THE NUMBER.

=cut

# This one is taken from the contributed program to 
# MiniVend by Bruce Albrecht

sub match_cc_number {
    my ( $the_card, $card_type ) = @_;
    my $orig_card = $the_card; #used for return match at bottom
    my ($index, $digit, $product);
    my $multiplier = 2;        # multiplier is either 1 or 2
    my $the_sum = 0;

    return undef if length($the_card) == 0;

    # check card type
    return undef unless $card_type =~ /^[admv]/i;

    return undef if ($card_type =~ /^v/i && substr($the_card, 0, 1) ne "4") ||
      ($card_type =~ /^m/i && substr($the_card, 0, 1) ne "5") ||
	($card_type =~ /^d/i && substr($the_card, 0, 4) ne "6011") ||
	  ($card_type =~ /^a/i && substr($the_card, 0, 2) ne "34" &&
	   substr($the_card, 0, 2) ne "37");

    # check for valid number of digits.
    $the_card =~ s/\s//g;    # strip out spaces
    return undef if $the_card !~ /^\d+$/;

    $digit = substr($the_card, 0, 1);
    $index = length($the_card)-1;
    return undef if ($digit == 3 && $index != 14) ||
        ($digit == 4 && $index != 12 && $index != 15) ||
            ($digit == 5 && $index != 15) ||
                ($digit == 6 && $index != 13 && $index != 15);


    # calculate checksum.
    for ($index--; $index >= 0; $index --)
    {
        $digit=substr($the_card, $index, 1);
        $product = $multiplier * $digit;
        $the_sum += $product > 9 ? $product - 9 : $product;
        $multiplier = 3 - $multiplier;
    }
    $the_sum %= 10;
    $the_sum = 10 - $the_sum if $the_sum;

    # return whether checksum matched.
    if ($the_sum == substr($the_card, -1)) {
	if ($orig_card =~ /^([\d\s]*)$/) { return $1; }
	else { return undef; }
    }
    else {
	return undef;
    }
}

=pod

=item cc_exp

This one checks if the input is in the format MM/YY or MM/YYYY and if
the MM part is a valid month (1-12) and if that date is not in the past.

=cut

sub match_cc_exp {
    my $val = shift;
    my ($matched_month, $matched_year);

    my ($month, $year) = split('/', $val);
    return undef if $month !~ /^(\d+)$/;
    $matched_month = $1;

    return undef if  $year !~ /^(\d+)$/;
    $matched_year = $1;

    return undef if $month <1 || $month > 12;
    $year += ($year < 70) ? 2000 : 1900 if $year < 1900;
    my @now=localtime();
    $now[5] += 1900;
    return undef if ($year < $now[5]) || ($year == $now[5] && $month <= $now[4]);

    return "$matched_month/$matched_year";
}

=pod

=item cc_type

This one checks if the input field starts by M(asterCard), V(isa),
A(merican express) or D(iscovery).

=cut

sub match_cc_type {
    my $val = shift;
    if ($val =~ /^([MVAD].*)$/i) { return $1; }
    else { return undef; }
}

=pod

=item ip_address

This checks if the input is formatted like an IP address (v4)

=cut

# contributed by Juan Jose Natera Abreu <jnatera@net-uno.net>

sub match_ip_address {
   my $val = shift;
   if ($val =~ m/^((\d+)\.(\d+)\.(\d+)\.(\d+))$/) {
       if 
	   (($2 >= 0 && $2 <= 255) && ($3 >= 0 && $3 <= 255) && ($4 >= 0 && $4 <= 255) && ($5 >= 0 && $5 <= 255)) {
	       return $1;
	   }
       else { return undef; }
   }
   else { return undef; }
}

1;

__END__

=pod

=back

=head1 REGEXP::COMMON SUPPORT

Data::FormValidator also includes built-in support for using any of regular expressions
in L<Regexp::Common> as named constraints. Simply use the name of regular expression you want.
This works whether you want to untaint the data or not. For example:

 constraints => {
	my_ip_address => 'RE_net_IPv4',
 }

Some Regexp::Common regular expressions support additional flags that are
expected to be passed into the routine as arguments. We support this as well.
Just use hash style method of declaring a constraint, and the C<params> key:

 constraints => {
	my_ip_address => {
		constraint => 'RE_net_IPv4',
		params => [ \'-sep'=> \' ' ],
	}
 }

Yes, it's a bit strange that you have pass the values to param by reference using
the backslash ("\"). This is necessary to preserve some important backward compatibility
that I haven't figured out how to work around yet. 

Be sure to check out the L<Regexp::Common> syntax for how its syntax works. It will make
more sense to add future regular expressions to Regexp::Common rather than to
Data::FormValidator.

=head1 PROCEDURAL INTERFACE

You may also call these functions directly through the procedural
interface by either importing them directly or importing the whole
I<:validators> group. This is useful if you want to use the built-in validators
out of the usual profile specification interface. 


For example, if you want to access the I<email> validator
directly, you could either do:

    use Data::FormValidator::Constraints (qw/valid_email/);
    or
    use Data::FormValidator::Constraints (:validators);

    if (valid_email($email)) {
      # do something with the email address
    }

Notice that when you call validators directly, you'll need to prefix the
validator name with "valid_" 

Each validator also has a version that returns the untainted value if
the validation succeeded. You may call these functions directly
through the procedural interface by either importing them directly or
importing the I<:matchers> group. For example if you want to untaint a
value with the I<email> validator directly you may:

    if ($email = match_email($email)) {
        system("echo $email");
    }
    else {
        die "Unable to validate email";
    }

Notice that when you call validators directly and want them to return an
untainted value, you'll need to prefix the validator name with "match_" 

=pod

=head1 WRITING YOUR OWN CONSTRAINT ROUTINES

It's easy to create your own module of constraint routines. The easiest approach
to this may be to check the source code of the Data::FormValidator module for example
syntax. Also notice the C<validator_packages> option in the input profile.

You will find that constraint routines are named two ways. Some are named with
the prefix C<match_> while others start with C<valid_>. The difference is that the
C<match_> routines are built to untaint the data and return a safe version of
it if it validates, while C<valid_> routines simply return a true value if the
validation succeeds and false otherwise.

It is preferable to write C<match_> routines that untaint data for the extra security
benefits. Plus, Data::FormValidator will AUTOLOAD a C<valid_> version if anyone tries to
use it, so you only need to write one routine to cover both cases. 

Usually constraint routines only need one input, the value being specified. However,
sometimes more than one value is needed. For that, the following syntax is
recommended for calling the routines:

B<Example>:

		image_field  => {  
			constraint_method  => 'max_image_dimensions',
			params => [\100,\200],
		},

Using this syntax, the first parameter that will be passed to the routine is
the Data::FormValidator object. The remaining parameters will come from the
C<params> array. Strings will be replaced by the values of fields with the same names,
and references will be passed directly.

In addition to C<constraint_method>, there is also an older technique using
the name C<constraint> instead. Routines that are designed to work with
C<constraint> I<don't> have access to Data::FormValidator object, which
means users need to pass in the name of the field being validated. Besides
adding unnecessary syntax to the user interface, it won't work in conjunction
with C<constraint_regexp_map>.

A few useful methods to use on the Data::FormValidator::Results object are
available to you to use inside of your routine.

=over 4

=item get_input_data

Returns the raw input data. This may be a CGI object if that's what 
was used in the constraint routine. 

B<Example>

 my $data = $self->get_input_data;

=item get_current_constraint_field

Returns the name of the current field being tested in the constraint.

B<Example>:

 my $field = $self->get_current_constraint_field;

This reduces the number of parameters that need to be passed into the routine
and allows multi-valued constraints to be used with C<constraint_regexp_map>.

For complete examples of multi-valued constraints, see L<Data::FormValidator::Constraints::Upload>

=item get_current_constraint_value

Returns the name of the current value being tested in the constraint.

B<Example>:

 my $value = $self->get_current_constraint_value;

This reduces the number of parameters that need to be passed into the routine
and allows multi-valued constraints to be used with C<constraint_regexp_map>.

=item get_current_constraint_name

Returns the name of the current constraint being applied

B<Example>:

 my $value = $self->get_current_constraint_name;

This is useful for building a constraint on the fly based on it's name.
It's used internally as part of the interface to the L<Regexp::Commmon>
regular expressions.

=back

The C<meta()> method may also be useful to communicate meta data that
may have been found. See L<Data::FormValidator::Results> for documentation
of that method.


=head1 SEE ALSO

Data::FormValidator(3), Data::FormValidator::Filters(3),
Data::FormValidator::ConstraintsFactory(3),
L<Regexp::Common>

=head1 CREDITS

Some of those input validation functions have been taken from MiniVend
by Michael J. Heins <mike@heins.net>

The credit card checksum validation was taken from contribution by
Bruce Albrecht <bruce.albrecht@seag.fingerhut.com> to the MiniVend
program.

=head1 AUTHORS

    Francis J. Lacoste <francis.lacoste@iNsu.COM>
    Michael J. Heins <mike@heins.net>
    Bruce Albrecht  <bruce.albrecht@seag.fingerhut.com>

=head1 COPYRIGHT

Copyright (c) 1999 iNsu Innovations Inc.
All rights reserved.

Parts Copyright 1996-1999 by Michael J. Heins <mike@heins.net>
Parts Copyright 1996-1999 by Bruce Albrecht  <bruce.albrecht@seag.fingerhut.com>

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut
