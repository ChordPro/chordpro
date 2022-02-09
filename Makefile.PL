#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010000;

# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

my $master = 'lib/App/Music/ChordPro/Version.pm';
my $version = MM->parse_version($master);
$master =~ s;/Version;;;

my @bins = qw( chordpro wxchordpro );

WriteMakefile
(
 NAME		=> 'App::Music::ChordPro',
 ABSTRACT_FROM  => $master,
 VERSION	=> $version,
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',
 LICENSE	=> "perl",
 MIN_PERL_VERSION => 5.010000,
 INSTALLDIRS	=> 'site',
 EXE_FILES	=> [ map { "script/$_" } @bins ],
 PL_FILES	=> {
		    'script/ppchordpro.PL' => [ map { "script/$_" } @bins ]
		   },

 # Always require PDF::API2 and Text::Layout.
 PREREQ_PM      => {
		    'App::Packager'		  => 1.430,
		    'PDF::API2'			  => 2.036,
		    'Text::Layout'		  => 0.028,
		    'JSON::PP'			  => 2.27203,
		    'String::Interpolate::Named'  => 1.01,
		    'File::LoadLines'		  => 1.02,
		    'File::HomeDir'		  => 1.004,,
		    'Image::Info'		  => 1.41,
		    'List::Util'		  => 1.33,
		    'Storable'			  => 3.08,
		   },

 CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => 6.5503,
 },

# BUILD_REQUIRES => {
# },

 TEST_REQUIRES  => {
		    'Test::More'                  => 0,
		    'JSON::PP'	                  => 2.27203,
		    'String::Interpolate::Named'  => 1.01,
		    'Storable'			  => 3.08,
		   },

 META_MERGE => {
     resources => {
	 license    => "http://dev.perl.org/licenses/",
	 homepage   => "http://www.chordpro.org",
	 repository => "https://github.com/sciurius/chordpro",
	 bugtracker => "https://github.com/sciurius/chordpro/issues",
     },
     provides => {
	 chordpro => { file => "script/chordpro",
		       version => $version },
	 "App::Music::ChordPro"
		  => { file => "lib/App/Music/ChordPro.pm",
		       version => $version },
     },
     no_index => {
         file => [
	    "lib/App/Music/ChordPro/Songbook.pm",
	    "lib/App/Music/ChordPro/Chords.pm",
	    "lib/App/Music/ChordPro/Version.pm",
	    "lib/App/Music/ChordPro/Wx.pm",
	 ],
         directory => [
	    "lib/App/Music/ChordPro/Output",
	    "lib/App/Music/ChordPro/Wx",
	 ],
     },
 },

);

# Note about the no_index: CPAN and MetaCPAN have differing opinions
# on how no_index must be interpreted, in particular in combination
# with provides.
