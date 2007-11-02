shift(@ARGV) if $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall
use Module::Build;

my $class = Module::Build->subclass(
	 class => 'Data::FormValidator::Builder',
	 code => q{
	 	sub ACTION_dist {
			my $self = shift;
			`perldoc -t lib/Data/FormValidator.pm>README`;
			$self->SUPER::ACTION_dist;
	 	}

        sub ACTION_cover {
            my $self = shift;
            $self->depends_on('build');

            system qw( cover -delete );

            # sometimes we get failing tests, which makes Test::Harness
            # die.  catch that
            eval {
                local $ENV{PERL5OPT} = "-MDevel::Cover=-summary,0";
                $self->ACTION_test(@_);
            };
            system qw( cover -report html );
        }
 	},
);


$class->new(
    # Makefile.PL is maintained manually now because the 5.8 requirement wasn't getting
    # translated automatically. 
    # create_makefile_pl  => 'traditional', 
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
	module_name => 'Data::FormValidator',
	license => 'perl',
	requires => {
         # In 5.6, t/upload* was failing.
         # rjbs says "It relies on CGI relying on 5.008 glob stringification behavior"
         # A patch to make it compatible with 5.6 again would be welcome. 
         perl             => '5.008',
		'Image::Size' 	  => 0,
		'Test::More'  	  => 0,
		'Date::Calc'	  => 5.0,
		'File::MMagic'    => 1.17,
		'MIME::Types'	  => 1.005,
		'Regexp::Common'  => 0,
        'overload'        => 0,
        'Perl6::Junction' => 1.10, 
        'Scalar::Util'    => 0,
	},
)->create_build_script;

