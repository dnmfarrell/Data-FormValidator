#
#    Results.pm - Object which contains validation result.
#
#    This file is part of FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#    Maintainer: Mark Stosberg <mark@summersault.com>
#
#    Copyright (C) 2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
use strict;

package Data::FormValidator::Results;

use Symbol;
use Data::FormValidator::Filters qw/:filters/;
use Data::FormValidator::Constraints (qw/:validators :matchers/);
use vars qw/$AUTOLOAD $VERSION/;

$VERSION = 3.59;

=pod

=head1 NAME

Data::FormValidator::Results - results of form input validation.

=head1 SYNOPSIS

 	my $results = Data::FormValidator->check(\%input_hash, \%dfv_profile);

    # Print the name of missing fields
    if ( $results->has_missing ) {
	foreach my $f ( $results->missing ) {
	    print $f, " is missing\n";
	}
    }

    # Print the name of invalid fields
    if ( $results->has_invalid ) {
	foreach my $f ( $results->invalid ) {
	    print $f, " is invalid: ", $results->invalid( $f ) \n";
	}
    }

    # Print unknown fields
    if ( $results->has_unknown ) {
	foreach my $f ( $results->unknown ) {
	    print $f, " is unknown\n";
	}
    }

    # Print valid fields
    foreach my $f ( $results->valid() ) {
	print $f, " =  ", $result->valid( $f ), "\n";
    }

=head1 DESCRIPTION

This object is returned by the L<Data::FormValidator> C<check> method. 
It can be queried for information about the validation results.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my ($profile, $data) = @_;

    my $self = bless {}, $class;

    $self->_process( $profile, $data );

    $self;
}

sub _process {
    my ($self, $profile, $data) = @_;

 	# Copy data and assumes that all is valid to start with
 		
	my %data        = $self->_get_data($data);
    my %valid	    = %data;
    my @missings    = ();
    my @unknown	    = ();

	# msgs() method will need access to the profile
	$self->{profile} = $profile;

	my %imported_validators;

    # import valid_* subs from requested packages
	foreach my $package (_arrayify($profile->{validator_packages})) {
		if ( !exists $imported_validators{$package} ) {
			eval "require $package";
			if ($@) {
				die "Couldn't load validator package '$package': $@";
			}

			# Perl will die with a nice error message if the package can't be found
			# No need to go through extra effort here. -mls :)
			my $package_ref = qualify_to_ref("${package}::");
			my @subs = grep(/^(valid_|match_|filter_)/,
			                keys(%{*{$package_ref}}));
			foreach my $sub (@subs) {
				# is it a sub? (i.e. make sure it's not a scalar, hash, etc.)
				my $subref = *{qualify_to_ref("${package}::$sub")}{CODE};
				if (defined $subref) {
					*{qualify_to_ref($sub)} = $subref;
				}
			}
			$imported_validators{$package} = 1;
		}
	}

	# Apply inconditional filters
    foreach my $filter (_arrayify($profile->{filters})) {
		if (defined $filter) {
			# Qualify symbolic references
			$filter = (ref $filter eq 'CODE' ? $filter : *{qualify_to_ref("filter_$filter")}{CODE}) ||
				die "No filter found named: '$filter'";
			foreach my $field ( keys %valid ) {
				# apply filter, modifying %valid by reference, skipping undefined values
				_filter_apply(\%valid,$field,$filter);
			}
		}	
    }

    # Apply specific filters
    while ( my ($field,$filters) = each %{$profile->{field_filters} }) {
		foreach my $filter ( _arrayify($filters)) {
			if (defined $filter) {
				# Qualify symbolic references
				$filter = (ref $filter eq 'CODE' ? $filter : *{qualify_to_ref("filter_$filter")}{CODE}) ||
					die "No filter found named '$filter'";
				
				# apply filter, modifying %valid by reference
				_filter_apply(\%valid,$field,$filter);
			}	
		}
    }   

	# add in specific filters from the regexp map
	while ( my ($re,$filters) = each %{$profile->{field_filter_regexp_map} }) {
		my $sub = _create_sub_from_RE($re);

		foreach my $filter ( _arrayify($filters)) {
			if (defined $filter) {
				# Qualify symbolic references
				$filter = (ref $filter eq 'CODE' ? $filter : *{qualify_to_ref("filter_$filter")}{CODE}) ||
					die "No filter found named '$filter'";

				no strict 'refs';

				# find all the keys that match this RE and apply filters to them
				for my $field (grep { $sub->($_) } (keys %valid)) {
					# apply filter, modifying %valid by reference
					_filter_apply(\%valid,$field,$filter);
				}
			}	
		}
	}
 
    my %required    = map { $_ => 1 } _arrayify($profile->{required});
    my %optional    = map { $_ => 1 } _arrayify($profile->{optional});

    # loop through and add fields to %required and %optional based on regular expressions   
    my $required_re = _create_sub_from_RE($profile->{required_regexp});
    my $optional_re = _create_sub_from_RE($profile->{optional_regexp});

    foreach my $k (keys %valid) {
       if ($required_re && $required_re->($k)) {
		  $required{$k} =  1;
       }
       
       if ($optional_re && $optional_re->($k)) {
		  $optional{$k} =  1;
       }
    }

	# handle "require_some"
	my %require_some;
 	while ( my ( $field, $deps) = each %{$profile->{require_some}} ) {
        foreach my $dep (_arrayify($deps)){
             $require_some{$dep} = 1;
        }
    }

	
	# Remove all empty fields
	foreach my $field (keys %valid) {
		if (ref $valid{$field}) {
			if ( ref $valid{$field} eq 'ARRAY' ) {
				for (my $i = 0; $i < scalar @{ $valid{$field} }; $i++) {
					$valid{$field}->[$i] = undef unless (defined $valid{$field}->[$i] and length $valid{$field}->[$i]);
			    }	
                # If all fields are empty, we delete it.
                delete $valid{$field} unless grep { defined $_ } @{$valid{$field}};

			}
		}
		else {
			delete $valid{$field} unless (defined $valid{$field} and length $valid{$field});
		}
	}

    # Check if the presence of some fields makes other optional fields required.
    while ( my ( $field, $deps) = each %{$profile->{dependencies}} ) {
        if ($valid{$field}) {
			if (ref($deps) eq 'HASH') {
				foreach my $key (keys %$deps) {
                    # Handle case of a key with a single value given as an arrayref
                    # There is probably a better, more general soution to this problem.
                    my $val_to_compare;
                    if ((ref $valid{$field} eq 'ARRAY') and (scalar @{ $valid{$field} } == 1)) {
                        $val_to_compare = $valid{$field}->[0];
                    }
                    else {
                        $val_to_compare = $valid{$field}
                    }

					if($val_to_compare eq $key){
						foreach my $dep (_arrayify($deps->{$key})){
							$required{$dep} = 1;
						}
					}
				}
			}
            else {
                foreach my $dep (_arrayify($deps)){
                    $required{$dep} = 1;
                }
            }
        }
    }

    # check dependency groups
    # the presence of any member makes them all required
    foreach my $group (values %{ $profile->{dependency_groups} }) {
       my $require_all = 0;
       foreach my $field (_arrayify($group)) {
	  		$require_all = 1 if $valid{$field};
       }
       if ($require_all) {
	  		map { $required{$_} = 1 } _arrayify($group); 
       }
    }

    # Find unknown
    @unknown =
      grep { not (exists $optional{$_} or exists $required{$_} or exists $require_some{$_} ) } keys %valid;
    # and remove them from the list
	foreach my $field ( @unknown ) {
		delete $valid{$field};
	}

    # Fill defaults
	while ( my ($field,$value) = each %{$profile->{defaults}} ) {
		$valid{$field} = $value unless exists $valid{$field};
	}

    # Check for required fields
    foreach my $field ( keys %required ) {
        push @missings, $field unless exists $valid{$field};
    }

	# Check for the absence of require_some fields
	while ( my ( $field, $deps) = each %{$profile->{require_some}} ) {
		my $enough_required_fields = 0;
		my @deps = _arrayify($deps);
		# num fields to require is first element in array if looks like a digit, 1 otherwise. 
		my $num_fields_to_require = ($deps[0] =~ m/^\d+$/) ? $deps[0] : 1;
		foreach my $dep (@deps){
			$enough_required_fields++ if exists $valid{$dep};
		}
		push @missings, $field unless ($enough_required_fields >= $num_fields_to_require);
	}

    # add in the constraints from the regexp map 
	foreach my $re (keys %{ $profile->{constraint_regexp_map} }) {
		my $sub = _create_sub_from_RE($re);

		# find all the keys that match this RE and add a constraint for them
		for my $key (keys %valid) {
			if ($sub->($key)) {
					my $cur = $profile->{constraints}{$key};
					my $new = $profile->{constraint_regexp_map}{$re};
					# If they already have an arrayref of constraints, add to the list
					if (ref $cur eq 'ARRAY') {
						push @{ $profile->{constraints}{$key} }, $new;
					} 
					# If they have a single constraint defined, create an array ref with with this plus the new one
					elsif ($cur) {
						$profile->{constraints}{$key} = [$cur,$new];
					}
					# otherwise, a new constraint is created with this as the single constraint
					else {
						$profile->{constraints}{$key} = $new;
					}

					warn "constraint_regexp_map: $key matches\n" if $profile->{debug};
						
				}
			}
	}
 
    # Check constraints

    #Decide which fields to untaint
    my ($untaint_all, %untaint_hash);
	if (defined($profile->{untaint_constraint_fields})) {
		if (ref $profile->{untaint_constraint_fields} eq "ARRAY") {
			foreach my $field (@{$profile->{untaint_constraint_fields}}) {
				$untaint_hash{$field} = 1;
			}
		}
		elsif ($valid{$profile->{untaint_constraint_fields}}) {
			$untaint_hash{$profile->{untaint_constraint_fields}} = 1;
		}
	}
    elsif ((defined($profile->{untaint_all_constraints}))
	   && ($profile->{untaint_all_constraints} == 1)) {
	   $untaint_all = 1;
    }
    
	while ( my ($field,$constraint_list) = each %{$profile->{constraints}} ) {

		next unless exists $valid{$field};

		my $is_constraint_list = 1 if (ref $constraint_list eq 'ARRAY');
		my $untaint_this =  ($untaint_all || $untaint_hash{$field} || 0);

		my @invalid_list;
		foreach my $constraint_spec (_arrayify($constraint_list)) {
			# set current constraint field for use by get_current_constraint_field
			$self->{__CURRENT_CONSTRAINT_FIELD} = $field;

			my $c = $self->_constraint_hash_build($field,$constraint_spec,$untaint_this);

			my $is_value_list = 1 if (ref $valid{$field} eq 'ARRAY');
			if ($is_value_list) {
				foreach (my $i = 0; $i < scalar @{ $valid{$field}} ; $i++) {
					my @params = $self->_constraint_input_build($c,$valid{$field}->[$i],\%valid);

					# set current constraint field for use by get_current_constraint_value
					$self->{__CURRENT_CONSTRAINT_VALUE} = $valid{$field}->[$i];

					my ($match,$failed) = _constraint_check_match($c,\@params,$untaint_this);
					if ($failed) {
						push @invalid_list, $failed;
					}
					else {
						 $valid{$field}->[$i] = $match if $untaint_this;
					}
				}
			}
			else {
				my @params = $self->_constraint_input_build($c,$valid{$field},\%data);

				# set current constraint field for use by get_current_constraint_value
				$self->{__CURRENT_CONSTRAINT_VALUE} = $valid{$field};

				my ($match,$failed) = _constraint_check_match($c,\@params,$untaint_this);
				if ($failed) {
					push @invalid_list, $failed
				}
				else {
					$valid{$field} = $match if $untaint_this;
				}
			}
	   }

		if (@invalid_list) {
			my @failed = map { $_->{name} } @invalid_list;
			push @{ $self->{invalid}{$field}  }, @failed;
            # the older interface to validate returned things differently
			push @{ $self->{validate_invalid} }, $is_constraint_list ? [$field, @failed] : $field;
		}
	}

    # all invalid fields are removed from valid hash
	foreach my $field (keys %{ $self->{invalid} }) {
		delete $valid{$field};
	}

    # add back in missing optional fields from the data hash if we need to
	foreach my $field ( keys %data ) {
		if ($profile->{missing_optional_valid} and $optional{$field} and (not exists $valid{$field})) {
			$valid{$field} = undef;
		}
	}

	my ($missing,$invalid);

	$self->{valid} ||= {};
    $self->{valid}	=  { %valid , %{$self->{valid}} };
    $self->{missing}	= { map { $_ => 1 } @missings };
    $self->{unknown}	= { map { $_ => $data{$_} } @unknown };

}

=pod

=head1  valid( [[field] [, value]] );

In an array context with no arguments, it returns the list of fields which 
contain valid values:

 @all_valid_field_names = $r->valid;

In a scalar context with no arguments, it returns an hash reference which 
contains the valid fields as keys and their input as values:

 $all_valid_href = $r->valid;

If called with one argument in scalar context, it returns the value of that
C<field> if it contains valid data, C<undef> otherwise. The value will be an
array ref if the field had multiple values:

 $value = $r->valid('field');

If called with one argument in array conect, it returns the values of C<field> 
as an array:

 @values = $r->valid('field');

If called with two arguments, it sets C<field> to C<value> and returns C<value>.
This form is useful to alter the results from within a C<constraint_method>.
See the L<Data::FormValidator::Constraints> documentation.

 $new_value = $r->valid('field',$new_value);

=cut

sub valid {
	my $self = shift;
	my $key = shift;
	my $val = shift;
	$self->{valid}{$key} = $val if defined $val;

    if (defined $key) {
        return wantarray ? _arrayify($self->{valid}{$key}) : $self->{valid}{$key};
    }

    # If we got this far, there were no arguments passed. 
	return wantarray ? keys %{ $self->{valid} } : $self->{valid};
}


=pod

=head1 has_missing()

This method returns true if the results contains missing fields.

=cut

sub has_missing {
    return scalar keys %{$_[0]{missing}};
}

=pod

=head1 missing( [field] )

In an array context it returns the list of fields which are missing.
In a scalar context, it returns an array reference to the list of missing fields.

If called with an argument, it returns true if that C<field> is missing,
undef otherwise.

=cut

sub missing {
    return $_[0]{missing}{$_[1]} if (defined $_[1]);

    wantarray ? keys %{$_[0]{missing}} : [ keys %{$_[0]{missing}} ];
}


=pod

=head1 has_invalid()

This method returns true if the results contains fields with invalid
data.

=cut

sub has_invalid {
    return scalar keys %{$_[0]{invalid}};
}

=pod

=head1 invalid( [field] )

In an array context, it returns the list of fields which contains invalid value. 

In a scalar context, it returns an hash reference which contains the invalid
fields as keys, and references to arrays of failed constraints as values.

If called with an argument, it returns the reference to an array of failed 
constraints for C<field>.

=cut

sub invalid {
	my $self = shift;
	my $field = shift;
    return $self->{invalid}{$field} if defined $field;

    wantarray ? keys %{$self->{invalid}} : $self->{invalid};
}

=pod

=head1 has_unknown()

This method returns true if the results contains unknown fields.

=cut

sub has_unknown {
    return scalar keys %{$_[0]{unknown}};

}

=pod

=head1 unknown( [field] )

In an array context, it returns the list of fields which are unknown. 
In a scalar context, it returns an hash reference which contains the unknown 
fields and their values.

If called with an argument, it returns the value of that C<field> if it
is unknown, undef otherwise.

=cut

sub unknown {
    return (wantarray ? _arrayify($_[0]{unknown}{$_[1]}) : $_[0]{unknown}{$_[1]})
      if (defined $_[1]);

    wantarray ? keys %{$_[0]{unknown}} : $_[0]{unknown};
}


=pod

=head1 msgs([config parameters])

This method returns a hash reference to error messages. The exact format
is determined by parameters in the C<msgs> area of the validation profile,
described in the L<Data::FormValidator> documentation.

This method takes one possible parameter, a hash reference containing the same 
options that you can define in the validation profile. This allows you to seperate
the controls for message display from the rest of the profile. While validation profiles
may be different for every form, you may wish to format messages the same way
across many projects.

Controls passed into the <msgs> method will be applied first, followed by ones
applied in the profile. This allows you to keep the controls you pass to
C<msgs> as "global" and override them in a specific profile if needed. 

=cut

sub msgs {
	my $self = shift;
	my $controls = shift || {};
	if (defined $controls and ref $controls ne 'HASH') {
		die "$0: parameter passed to msgs must be a hash ref";
	}


	# Allow msgs to be called more than one to accumulate error messages
	$self->{msgs} ||= {};
	$self->{profile}->{msgs} ||= {};
	$self->{msgs} = { %{ $self->{msgs} }, %$controls };

	my %profile = (
		prefix	=> '',
		missing => 'Missing',
		invalid	=> 'Invalid',
		invalid_seperator => ' ',
		format  => '<span style="color:red;font-weight:bold"><span class="dfv_errors">* %s</span></span>',
		%{ $self->{msgs} },
		%{ $self->{profile}->{msgs} },
	);
	my %msgs = ();

	# Add invalid messages to hash
		#  look at all the constraints, look up their messages (or provide a default)
		#  add field + formatted constraint message to hash
	if ($self->has_invalid) {
		my $invalid = $self->invalid;
		for my $i ( keys %$invalid ) {
			$msgs{$i} = join $profile{invalid_seperator}, map {
				_error_msg_fmt($profile{format},($profile{constraints}{$_} || $profile{invalid}))
				} @{ $invalid->{$i} };
		}
	}

	# Add missing messages, if any
	if ($self->has_missing) {
		my $missing = $self->missing;
		for my $m (@$missing) {
			$msgs{$m} = _error_msg_fmt($profile{format},$profile{missing});
		}
	}

	my $msgs_ref = prefix_hash($profile{prefix},\%msgs);

	$msgs_ref->{ $profile{any_errors} } = 1 if defined $profile{any_errors};

	return $msgs_ref;

}

=pod

=head1 meta()

In a few cases, a constraint may discover meta data that is useful
to access later. For example, when using L<Data::FormValidator::Constraints::Upload>, several bits of meta data are discovered about files in the process
of validating. These can include "bytes", "width", "height" and "extension".
The C<meta()> function is used by constraint methods to set this data. It's
also used to access this data. Here are some examples.

 # return all field names that have meta data
 my @fields = $results->meta();

 # To retrieve all meta data for a field:
 $meta_href = $results->meta('img');
 
 # Access a particular piece: 
 $width = $results->meta('img')->{width};
 
Here's how to set some meta data. This is useful to know if you are
writing your own complex constraint.

	$self->meta('img', {
		width  => '50',
		height => '60',
	});

This function does not currently multi-valued fields. If it 
does in the future, the above syntax will still work..

=cut

sub meta {
	my $self  = shift;
	my $field = shift;
	my $data  = shift;

	# initialize if it's the first call
	$self->{__META} ||= {};

	if ($data) {
		(ref $data eq 'HASH') or die 'meta: data passed not a hash ref'; 
        $self->{__META}{$field} = $data;
	}


	# If we are passed a field, return data for that field
	if ($field) {
		return $self->{__META}{$field};
	}
	# Otherwise return a list of all fields that have meta data
	else {
		return keys %{ $self->{__META} };
	}
}

# These are documented in ::Constraints, in the section
# on writing your own routines. It was more intuitive
# for the user to look there. 

sub get_input_data {
	my $self = shift;
	return $self->{__INPUT_DATA};
}

sub get_current_constraint_field {
	my $self = shift;
	return $self->{__CURRENT_CONSTRAINT_FIELD};
}

sub get_current_constraint_value {
	my $self = shift;
	return $self->{__CURRENT_CONSTRAINT_VALUE};
}

sub get_current_constraint_name {
	my $self = shift;
	return $self->{__CURRENT_CONSTRAINT_NAME};
}


# INPUT: prefix_string, hash reference
# Copies the hash and prefixes all keys with prefix_string
# OUTPUT: hash refence
sub prefix_hash {
	my ($pre,$href) = @_;
	die "prefix_hash: need two arguments" unless (scalar @_ == 2);
	die "prefix_hash: second argument must be a hash ref" unless (ref $href eq 'HASH');
	my %out; 
	for (keys %$href) {
		$out{$pre.$_} = $href->{$_};
	}
	return \%out;
}


# We tolerate two kinds of regular expression formats
# First, the preferred format made with "qr", matched using a learning paren
# Also, we accept the deprecated format given as strings: 'm/old/'
# (which must start with a slash or "m", not a paren)
sub _create_sub_from_RE {
	my $re = shift || return undef;
	my $untaint_this = shift;

	my $sub;
	# If it's "qr" style
	if (substr($re,0,1) eq '(') {
		$sub = sub { 
            my $val = shift;
			my ($match) = ($val =~ $re); 
			if ($untaint_this && defined $match) {
                # pass the value through a RE that matches anything to untaint it.
                my ($untainted) = ($&  =~ m/(.*)/s);
				return $untainted;
			}
			else {
				return $match;
			}
		};

	}
	else {
        my $return_code = ($untaint_this) ? '; return ($& =~ m/(.*)/s)[0] if defined($`);' : '';
		$sub = eval 'sub { $_[0] =~ '.$re.$return_code. '}';
	    die "Error compiling regular expression $re: $@" if $@;
	}
	return $sub;
}


sub _error_msg_fmt ($$) {
	my ($fmt,$msg) = @_;
	$fmt ||= 
			'<span style="color:red;font-weight:bold"><span class="dfv_errors">* %s</span></span>';
	($fmt =~ m/%s/) || die 'format must contain %s'; 
	return sprintf $fmt, $msg;
}



# takes string or array ref as input
# returns array
sub _arrayify {
   # if the input is undefined, return an empty list
   my $val = shift;
   defined $val or return ();

   if ( ref $val eq 'ARRAY' ) {
		# if it's a reference, return an array unless it points an empty array. -mls
                return (defined $val->[0]) ? @$val : ();
   } 
   else {
		# if it's a string, return an array unless the string is missing or empty. -mls
                return (length $val) ? ($val) : ();
   }
}

# apply filter, modifying %valid by reference
# We don't bother trying to filter undefined fields.
# This prevents warnings from Perl. 
sub _filter_apply {
	my ($valid,$field,$filter) = @_;
	die 'wrong number of arguments passed to _filter_apply' unless (scalar @_ == 3);
	if (ref $valid->{$field} eq 'ARRAY') {
		for (my $i = 0; $i < @{ $valid->{$field} }; $i++) {
			$valid->{$field}->[$i] = $filter->( $valid->{$field}->[$i] ) if defined $valid->{$field}->[$i];
		}
	}
	else {
		$valid->{$field} = $filter->( $valid->{$field} ) if defined $valid->{$field};
	}
}

sub _constraint_hash_build {
	my ($self,$field,$constraint_spec,$untaint_this) = @_;
	die "_constraint_apply received wrong number of arguments" unless (scalar @_ == 4);

	my	$c = {
			name 		=> $constraint_spec,
			constraint  => $constraint_spec, 
		};


   # constraints can be passed in directly via hash
	if (ref $c->{constraint} eq 'HASH') {
			$c->{constraint} = ($constraint_spec->{constraint_method} || $constraint_spec->{constraint});
			$c->{name}       = $constraint_spec->{name};
			$c->{params}     = $constraint_spec->{params};
			$c->{is_method}  = 1 if $constraint_spec->{constraint_method};
	}

	# Check for regexp constraint
	if ((ref $c->{constraint} eq 'Regexp')
			or ( $c->{constraint} =~ m@^\s*(/.+/|m(.).+\2)[cgimosx]*\s*$@ )) {
		$c->{constraint} = _create_sub_from_RE($c->{constraint},$untaint_this);
	}
	# check for code ref
	elsif (ref $c->{constraint} eq 'CODE') {
		# do nothing, it's already a code ref
	}
	else {
		# provide a default name for the constraint if we don't have one already
		$c->{name} ||= $c->{constraint};

		# Save the current constraint name for later
		$self->{__CURRENT_CONSTRAINT_NAME} = $c->{name};
		
		#If untaint is turned on call match_* sub directly. 
		if ($untaint_this) {
			my $routine = 'match_'.$c->{constraint};			
			my $match_sub = *{qualify_to_ref($routine)}{CODE};
			if ($match_sub) {
				$c->{constraint} = $match_sub; 
			}
			# If the constraint name starts with RE_, try looking for it in the Regexp::Common package
			elsif ($c->{constraint} =~ m/^RE_/) {
				$c->{is_method} = 1;
				$c->{constraint} = eval 'sub { &_create_regexp_common_constraint(@_)}' 
					|| die "could not create Regexp::Common constraint: $@";
			} else {
				die "No untainting constraint found named $c->{constraint}";
			}
		}
		else {
			# try to use match_* first
			my $routine = 'match_'.$c->{constraint};			
			if (defined *{qualify_to_ref($routine)}{CODE}) {
				$c->{constraint} = eval 'sub { no strict qw/refs/; return defined &{"match_'.$c->{constraint}.'"}(@_)}';
			}
			# match_* doesn't exist; if it is supposed to be from the
			# validator_package(s) there may be only valid_* defined
			elsif (my $valid_sub = *{qualify_to_ref('valid_'.$c->{constraint})}{CODE}) {
				$c->{constraint} = $valid_sub;
			}
			# Load it from Regexp::Common 
			elsif ($c->{constraint} =~ m/^RE_/) {
				$c->{is_method} = 1;
				$c->{constraint} = eval 'sub { return defined &_create_regexp_common_constraint(@_)}' ||
					die "could not create Regexp::Common constraint: $@";
			}
			else {
				die "No constraint found named '$c->{name}'";
			}
		}
	}

	return $c;

}

sub _constraint_input_build {
	my ($self,$c,$value,$data) = @_;
	die "_constraint_input_build received wrong number of arguments" unless (scalar @_ == 4);

	my @params;
	if (defined $c->{params}) {
		foreach my $fname (_arrayify($c->{params})) {
			# If the value is passed by reference, we treat it literally
			push @params, (ref $fname) ? $fname : $data->{$fname}
		}
	}
	else {
		push @params, $value;
	}

	unshift @params, $self if $c->{is_method};
	return @params;
}

sub _constraint_check_match {
	my 	($c,$params,$untaint_this) = @_;
	die "_constraint_check_match received wrong number of arguments" unless (scalar @_ == 3);

    my $match = $c->{constraint}->( @$params );

    # We need to make this distinction when untainting,
    # to allow untainting values that are defined but not true,
    # such as zero.
    my $success =  defined $match;
    if (defined $match) {
       $success =  ($untaint_this) ? length $match : $match;
    }
    
	if ($success) { 
		return $match;
	}
	else {
		return 
		undef,	
		{
			failed  => 1,
			name	=> $c->{name},
		};
	}
}

# Figure out whether the data is a hash reference of a param-capable object and return it has a hash
sub _get_data {
	my ($self,$data) = @_;
	$self->{__INPUT_DATA} = $data;
	require UNIVERSAL;

    # This checks whether we have an object or not.
    if (UNIVERSAL::isa($data,'UNIVERSAL') ) {
		my %return;
		# make sure object supports param()
		defined($data->UNIVERSAL::can('param')) or
		die "Data::FormValidator->validate() or check() called with an object which lacks a param() method!";
		foreach my $k ($data->param()){
			# we expect param to return an array if there are multiple values
			my @v = $data->param($k);
			$return{$k} = scalar(@v)>1 ? \@v : $v[0];
		}
		return %return;
	}
	# otherwise, it's already a hash reference
	else {
		return %$data;	
	}
}


sub _create_regexp_common_constraint  {
	require Regexp::Common;
	import  Regexp::Common 'RE_ALL';
	my $self = shift;
	my $re_name = $self->get_current_constraint_name;
	# deference all input
	my @params = map {$_ = $$_ if ref $_ }  @_;

	no strict "refs";
	my $re = &$re_name(-keep=>1,@params) || die 'no matching Regexp::Common routine found';
	return ($self->get_current_constraint_value =~ qr/^$re$/) ? $1 : undef; 
}


1;

__END__

=pod

=head1 SEE ALSO

Data::FormValidator, Data::FormValidator::Filters,
Data::FormValidator::Constraints, Data::FormValidator::ConstraintsFactory

=head1 AUTHOR

Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
Maintainer: Mark Stosberg <mark@summersault.com> 

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut
