#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.026000;

use ExtUtils::MakeMaker 7.24;	# comes with 5.26

my $master = 'lib/ChordPro/Version.pm';
my $version = MM->parse_version($master);
$master =~ s;/Version;;;

my @bins = qw( chordpro wxchordpro );

my @pdfapi = ( 'PDF::API2' => 2.043 ); # default
if ( my $a = $ENV{CHORDPRO_PDF_API} ) {
    if ( $a =~ /PDF::Builder/ ) {
	@pdfapi = ( 'PDF::Builder' => 3.025 );
    }
    elsif ( $a =~ /PDF::API2/ ) {
    }
    else {
	@pdfapi = ( $a => 0 );
    }
}

WriteMakefile
(
 NAME		  => 'App::Music::ChordPro',
 ABSTRACT         => "A lyrics and chords formatting program",
 VERSION	  => $version,
 AUTHOR	          => 'Johan Vromans <jvromans@squirrel.nl>',
 LICENSE	  => "perl",
 MIN_PERL_VERSION => 5.026000,
 INSTALLDIRS	  => 'site',
 EXE_FILES	  => [ map { "script/$_" } @bins ],
 PL_FILES	  => {
		       'script/ppchordpro.PL' => [ map { "script/$_" } @bins ]
		     },

 # Always require PDF::API2 or PDF::Builder and Text::Layout.
 PREREQ_PM      => {
		    'App::Packager'		  => 1.430,
		    @pdfapi,
		    'Text::Layout'		  => 0.031004,
		    'JSON::PP'			  => 2.27203,
		    'String::Interpolate::Named'  => 1.030,
		    'File::LoadLines'		  => 1.021,
		    'File::HomeDir'		  => 1.004,
		    'Image::Info'		  => 1.41,
		    'List::Util'		  => 1.46,
		    'Data::Printer'		  => 1.001001,
		    'Storable'			  => 3.08,
		    'Object::Pad'                 => 0.78,
		   # Some distro's have removed this from the core.
		    'Pod::Usage'		  => 2.03,
		   # These are only used by the LaTeX backend
		   # 'Template'			  => 3.010,
		   # 'LaTeX::Encode'		  => 0.092.0,
		   },

 CONFIGURE_REQUIRES => {
		    'ExtUtils::MakeMaker'	  => 7.24,
		    },

# BUILD_REQUIRES => {
# },

 TEST_REQUIRES  => {
		    'Test::More'                  => 0,
		    'JSON::PP'	                  => 2.27203,
		    'String::Interpolate::Named'  => 1.01,
		    'Storable'			  => 3.08,
		    'Object::Pad'		  => 0.78,
		    @pdfapi,
		   },

 META_MERGE => {
     resources => {
	 license    => "https://dev.perl.org/licenses/",
	 homepage   => "https://www.chordpro.org",
	 repository => "https://github.com/sciurius/chordpro",
	 bugtracker => "https://github.com/sciurius/chordpro/issues",
     },
     provides => {
	 chordpro => { file => "script/chordpro",
		       version => $version },
	 "App::Music::ChordPro"
		  => { file => "lib/ChordPro.pm",
		       version => $version },
     },
     no_index => {
         file => [
	    "lib/ChordPro/Songbook.pm",
	    "lib/ChordPro/Chords.pm",
	    "lib/ChordPro/Testing.pm",
	    "lib/ChordPro/Utils.pm",
	    "lib/ChordPro/Version.pm",
	    "lib/ChordPro/Wx.pm",
	 ],
         directory => [
	    "lib/ChordPro/Chords",
	    "lib/ChordPro/Config",
	    "lib/ChordPro/Delegate",
	    "lib/ChordPro/Output",
	    "lib/ChordPro/Wx",
	    "lib/ChordPro/lib",
	    "lib/ChordPro/res",
	    "pp",
	 ],
     },
 },

);

# Note about the no_index: CPAN and MetaCPAN have differing opinions
# on how no_index must be interpreted, in particular in combination
# with provides.
