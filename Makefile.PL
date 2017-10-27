#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010000;

use ExtUtils::MakeMaker;

my $master = 'lib/App/Music/ChordPro/Wx.pm';
my $version = MM->parse_version($master);

WriteMakefile
(
 NAME		=> 'App::Music::ChordPro::Wx',
 ABSTRACT       => 'Simple Wx-based GUI wrapper for ChordPro.',
 VERSION	=> $version,
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',

 INSTALLDIRS	=> 'site',
 EXE_FILES	=> [ 'script/wxchordpro' ],
 PL_FILES	=> {
		    'script/pp.PL' => [ 'script/wxchordpro' ]
		   },

 PREREQ_PM      => {
		    'App::Music::ChordPro'   => $version,
		    'Wx' => 0.9912,
		   },
 TEST_REQUIRES  => {
		    'Test::More'  => 0,
		   },

 META_MERGE => {
     license          => "perl_5",
     resources        =>
		{
		 homepage   => "http://www.chordpro.org",
		 repository => "https://github.com/sciurius/wxchordpro",
		 bugtracker => "https://github.com/sciurius/wxchordpro/issues",
		},
     provides         => {
	 wxchordpro => { file => "script/wxchordpro",
		         version => $version },
	 "App::Music::ChordPro::Wx"
		  => { file => "lib/App/Music/ChordPro/Wx.pm",
		       version => $version },
     },
     no_index         => {
         directory => [
	    "lib/App/Music/ChordPro/Wx",
	 ],
     },
 },

);

# Note about the no_index: CPAN and MetaCPAN have differing opinions
# on how no_index must be interpreted, in particular in combination
# with provides.

