#########################

use Test::More tests => 18;
use strict;
BEGIN { 
    use_ok('CGI');
    use_ok('Data::FormValidator::Constraints::Upload') 
};

#########################

%ENV = (
	%ENV,
          'SCRIPT_NAME' => '/test.cgi',
          'SERVER_NAME' => 'perl.org',
          'HTTP_CONNECTION' => 'TE, close',
          'REQUEST_METHOD' => 'POST',
          'SCRIPT_URI' => 'http://www.perl.org/test.cgi',
          'CONTENT_LENGTH' => 3129,
          'SCRIPT_FILENAME' => '/home/usr/test.cgi',
          'SERVER_SOFTWARE' => 'Apache/1.3.27 (Unix) ',
          'HTTP_TE' => 'deflate,gzip;q=0.3',
          'QUERY_STRING' => '',
          'REMOTE_PORT' => '1855',
          'HTTP_USER_AGENT' => 'Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)',
          'SERVER_PORT' => '80',
          'REMOTE_ADDR' => '127.0.0.1',
          'CONTENT_TYPE' => 'multipart/form-data; boundary=xYzZY',
          'SERVER_PROTOCOL' => 'HTTP/1.1',
          'PATH' => '/usr/local/bin:/usr/bin:/bin',
          'REQUEST_URI' => '/test.cgi',
          'GATEWAY_INTERFACE' => 'CGI/1.1',
          'SCRIPT_URL' => '/test.cgi',
          'SERVER_ADDR' => '127.0.0.1',
          'DOCUMENT_ROOT' => '/home/develop',
          'HTTP_HOST' => 'www.perl.org'
);

diag "testing with CGI.pm version: $CGI::VERSION";

open(IN,'<t/upload_post_text.txt') || die 'missing test file';
binmode(IN);

*STDIN = *IN;
my $q = new CGI;

use Data::FormValidator;
my $default = {
		required=>[qw/hello_world does_not_exist_gif 100x100_gif 300x300_gif/],
		validator_packages=> 'Data::FormValidator::Constraints::Upload',
		constraints => {
			'hello_world' => {
				constraint_method => 'file_format',
				params=>[],
			},
			'does_not_exist_gif' => {
				constraint_method => 'file_format',
				params=>[],
			},
			'100x100_gif' => [
				{
					constraint_method => 'file_format',
					params=>[],
				},
				{
					constraint_method => 'file_max_bytes',
					params=>[],
				}
			],
			'300x300_gif' => {
				constraint_method => 'file_max_bytes',
				params => [\100],
			},
		},
	};

my $dfv = Data::FormValidator->new({ default => $default});
my ($results);
eval {
	$results = $dfv->check($q, 'default');
};
ok(not $@) or diag $@;

my $valid   = $results->valid;
my $invalid = $results->invalid; # as hash ref
my @invalids = $results->invalid;
my $missing = $results->missing;


# Test to make sure hello world fails because it is the wrong type
ok((grep {m/hello_world/} @invalids), 'expect format failure');

# should fail on empty/missing source file data
ok((grep {m/does_not_exist_gif/} @invalids), 'expect non-existent failure');


# Make sure 100x100 passes because it is the right type and size
ok(exists $valid->{'100x100_gif'});

my $meta = $results->meta('100x100_gif');
is(ref $meta, 'HASH', 'meta() returns hash ref');

ok($meta->{extension}, 'setting extension meta data');
ok($meta->{mime_type}, 'setting mime_type meta data');

# 300x300 should fail because it is too big
ok((grep {m/300x300/} @invalids), 'max_bytes');

ok($results->meta('100x100_gif')->{bytes}>0, 'setting bytes meta data');


# Revalidate to usefully re-use the same fields
my $profile_2  = {
	required=>[qw/hello_world 100x100_gif 300x300_gif/],
	validator_packages=> 'Data::FormValidator::Constraints::Upload',
	constraints => {
		'100x100_gif' => {
			constraint_method => 'image_max_dimensions',
			params => [\200,\200],
		},
		'300x300_gif' => {
			constraint_method => 'image_max_dimensions',
			params => [\200,\200],
		},
	},
};

$dfv = Data::FormValidator->new({ profile_2 => $profile_2});
eval {
	$results = $dfv->check($q, 'profile_2');
};
ok(not $@) or diag $@;

$valid   = $results->valid;
$invalid = $results->invalid; # as hash ref
@invalids = $results->invalid;
$missing = $results->missing;

ok(exists $valid->{'100x100_gif'}, 'expecting success with max_dimensions');
ok((grep /300x300/, @invalids), 'expecting failure with max_dimensions');

ok( $results->meta('100x100_gif')->{width} > 0, 'setting width as meta data');
ok( $results->meta('100x100_gif')->{width} > 0, 'setting height as meta data');

# Now test trying constraint_regxep_map
my $profile_3  = {
	required=>[qw/hello_world 100x100_gif 300x300_gif/],
	validator_packages=> 'Data::FormValidator::Constraints::Upload',
	constraint_regexp_map => {
		'/[13]00x[13]00_gif/'	=> {
			constraint_method => 'image_max_dimensions',
			params => [\200,\200],
		}
	}
};

$dfv = Data::FormValidator->new({ profile_3 => $profile_3});
($valid,$missing,$invalid) = $dfv->validate($q, 'profile_3');

ok(exists $valid->{'100x100_gif'}, 'expecting success with max_dimensions using constraint_regexp_map');

#use Data::Dumper;
#warn Dumper ($invalid);

ok((grep {m/300x300/} @$invalid), 'expecting failure with max_dimensions using constraint_regexp_map');


