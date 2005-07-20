shift(@ARGV) if $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall
#arch-tag: Mark_Stosberg_<mark@summersault.com>--2004-03-20_18:34:25
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
    create_makefile_pl  => 'traditional', 
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
	module_name => 'Data::FormValidator',
	license => 'perl',
	requires => {
		'Image::Size' 	 => 0,
		'Test::More'  	 => 0,
		'Date::Calc'	 => 0,
		'File::MMagic'   => 1.17,
		'MIME::Types'	 => 1.005,
		'Regexp::Common' => 0,
        'overload'       => 0,
	},
)->create_build_script;

