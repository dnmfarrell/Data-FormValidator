package Data::FormValidator::Constraints::Upload;

use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::FormValidator::Constraints::Upload ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

@EXPORT = qw(
	valid_file_format		
	valid_image_max_dimensions
	valid_file_max_bytes	
);

$VERSION = '0.71';

sub valid_file_format {
	my $self = shift;
	$self->isa('Data::FormValidator::Results') ||
		die "valid_file_format: first argument is not a Data::FormValidator::Results object.
			Check that you used 'constraint_method' and not 'constraint'";
	my $params = shift || {};
	if (ref $params ne 'HASH' ) {
		die "valid_file_format: hash reference expected. Make sure you have
		included 'params => []' in your constraint definition, even if there
		are no additional arguments";
	}

	my $q = $self->get_input_data;

    require UNIVERSAL;
	$q->UNIVERSAL::can('param')||
		die 'valid_file_format: data object missing param() method';

	my $field = $self->get_current_constraint_field;

   my $img = $q->upload($field);
   if (!$img && $q->cgi_error) {
   		warn $q->cgi_error && return undef;
	}
    my $tmp_file = $q->tmpFileName($q->param($field)) || 
	 (warn "$0: can't find tmp file for field named $field" and return undef);

	require File::MMagic;	
	my $mm = File::MMagic->new; 
	my $fm_mt = $mm->checktype_filename($tmp_file);

   my $uploaded_mt = '';
      $uploaded_mt = $q->uploadInfo($img)->{'Content-Type'} if $q->uploadInfo($img);

   # XXX perhaps this should be in a global variable so it's easier
   # for other apps to change the defaults;	
   $params->{mime_types} ||= [qw!image/jpeg  image/pjpeg image/gif image/png!];
   my %allowed_types = map { $_ => 1 } @{ $params->{mime_types} };

   # try the File::MMagic, then the uploaded field, then return undef we find neither
   my $mt = ($fm_mt || $uploaded_mt) or return undef;

   # figure out an extension

   use MIME::Types;
   my $mimetypes = MIME::Types->new;
   my MIME::Type $t = $mimetypes->type($mt);
   my @mt_exts = $t ? $t->extensions : ();

   my ($uploaded_ext) = ($img =~ m/\.([\w\d]*)?$/);

   my $ext;
   if (scalar @mt_exts) {
   		# If the upload extension is one recognized by MIME::Type, use it.
		if (grep {/^$uploaded_ext$/} @mt_exts) 	 {
			$ext = $uploaded_ext;
		}
		# otherwise, use one from MIME::Type, just to be safe
		else {
			$ext = $mt_exts[0];
		}
   }
   else {
   	   # If is a provided extension but no MIME::Type extension, use that.
	   # It's possible that there no extension uploaded or found)
	   $ext = $uploaded_ext;
   }


   # Add the mime_type and extension to the valid data set
   my $info = $self->meta($field) || {};
   $info = { %$info, mime_type => $uploaded_mt, extension => ".$ext" };
   $self->meta($field,$info);

   return $allowed_types{$mt};
}

sub valid_image_max_dimensions {
	my $self = shift;
	$self->isa('Data::FormValidator::Results') ||
		die "image_max_dimensions: first argument is not a Data::FormValidator::Results object.
			Check that you used 'constraint_method' and not 'constraint'";
	my $max_width_ref  = shift || die 'image_max_dimensions: missing maximum width value';
	my $max_height_ref = shift || die '_image_max_dimensions: missing maximum height value';
	my $max_width  = $$max_width_ref;
	my $max_height = $$max_height_ref;
	($max_width > 0) || die 'image_max_dimensions: maximum width must be > 0';
	($max_height > 0) || die 'image_max_dimensions: maximum height must be > 0';

	my $q = $self->get_input_data;
    require UNIVERSAL;
	$q->UNIVERSAL::can('param')||
		die 'valid_image_max_dimensions: data object missing param() method';

	my $field = $self->get_current_constraint_field;

   my $img = $q->upload($field);
   if (!$img && $q->cgi_error) {
   		warn $q->cgi_error && return undef;
	}

	require Image::Size;
	import Image::Size;

    my $tmp_file = $q->tmpFileName($q->param($field)) || 
	 (warn "$0: can't find tmp file for field named $field" and return undef);

    my ($width,$height,$err) = imgsize($tmp_file);
	unless ($width) {
		warn "$0: imgsize test failed: $err";
		return undef;
	}

   
   # Add the dimensions to the valid hash
   my $info = $self->meta($field) || {};
   $info = { %$info, width => $width, height => $height };
   $self->meta($field,$info);

    return (($width <= $$max_width_ref) and ($height <= $$max_height_ref));
}

sub valid_file_max_bytes {
	my $self = shift;

	$self->isa('Data::FormValidator::Results') ||
		die "valid_file_format: first argument is not a Data::FormValidator::Results object.
			Check that you used 'constraint_method' and not 'constraint'";
	my $max_bytes_ref = shift;
	
	my $max_bytes;
	if ((ref $max_bytes_ref) and defined $$max_bytes_ref) {
		$max_bytes = $$max_bytes_ref;
	}
	else {
		$max_bytes = 1024*1024; # default to 1 Meg
	}

	my $q = $self->get_input_data;
    require UNIVERSAL;
	$q->UNIVERSAL::can('param') ||
		die 'valid_file_max_bytes: object missing param() method';

	my $field = $self->get_current_constraint_field;

   my $img = $q->upload($field);
   if (!$img && $q->cgi_error) {
   		warn $q->cgi_error && return undef;
	}

   my $file_size = (stat ($img))[7];

   # Add the size to the valid hash
   my $info = $self->meta($field) || {};
   $info = { %$info, bytes => $file_size  };
   $self->meta($field,$info);

   return ($file_size <= $max_bytes);
}



1;
__END__

=head1 NAME

Data::FormValidator::Constraints::Upload - Validate File Uploads

=head1 SYNOPSIS

    # Be sure to use a CGI.pm object as the form input
    # when using this constraint
    my $q = new CGI;
    my $dfv = Data::FormValidator->check($q,$my_profile);

	# In a Data::FormValidator Profile:
	validator_packages => [qw(Data::FormValidator::Constraints::Upload)],
	constraints => {
		image_name => [
			{
				constraint_method => 'file_format',
				params => [],
			},
			{
				constraint_method => 'file_max_bytes',
				params => [\100],
			},
			{
				constraint_method => 'image_max_dimensions',
				params => [\200,\200],
			},

		 ],
	}


=head1 DESCRIPTION

B<Note:> This is a new module is a new addition to Data::FormValidator and is 
should be considered "Beta". 

These module is meant to be used in conjunction with the Data::FormValidator
module to automate the task of validating uploaded files. The following
validation routines are supplied.

To use any of them, the input data passed to Data::FormValidator must
be a CGI.pm object.

=over 4

=item file_format

This function checks the format of the file, based on the MIME type if it's
available, and a case-insensitive version of the file extension otherwise. By default, 
it tries to validate JPEG, GIF and PNG images. The params are:

 optional hash reference of parameters. A key named I<mime_types> points to
 array refererences of valid values.

	constraint_method => 'file_format',
	params => [{
		mime_types => [qw!image/jpeg image/gif image/png!],
	}],

Calling this function sets some meta data which can be retrieved through
the C<meta()> method of the Data::FormValidator::Results object.
The meta data added is C<extension> and C<mime_type>.

The MIME type of the file will first be tried to figured out by using the
<File::MMagic> module to examine the file. If that doesn't turn up a result,
we'll use a MIME type from the browser if one has been provided. Otherwise, we
give up. The extension we return is based on the MIME type we found, rather
than trusting the one that was uploaded.


=item file_max_bytes

This function checks the maximum size of an uploaded file. By default,
it checks to make sure files are smaller than 1 Meg. The params are:

 reference to max file size in bytes

	constraint_method => 'file_max_bytes',
	params => [\1024], # 1 k

Calling this function sets some meta data which can be retrieved through
the C<meta()> method of the Data::FormValidator::Results object.
The meta data added is C<bytes>.

=item image_max_dimensions

This function checks to make sure an uploaded image is no longer than
some maximum dimensions. The params are: 

 reference to max pixel width
 reference to max pixel height

	constraint_method => 'image_max_dimensions',
	params => [\200,\200],

Calling this function sets some meta data which can be retrieved through
the C<meta()> method of the Data::FormValidator::Results object.
The meta data added is C<width> and C<height>.

=back

=head1 SEE ALSO

L<FileMetadata>, L<Data::FormValidator>, L<CGI>, L<perl>

=head1 AUTHOR

Mark Stosberg, E<lt>mark@summersault.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mark Stosberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
