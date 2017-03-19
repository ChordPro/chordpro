#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010000;

use ExtUtils::MakeMaker;

my $master = 'lib/App/Music/ChordPro.pm';
my $version = MM->parse_version($master);

WriteMakefile
(
 NAME		=> 'App::Music::ChordPro',
 ABSTRACT_FROM  => $master,
 VERSION_FROM	=> $master,
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',

 INSTALLDIRS	=> 'site',
 EXE_FILES	=> [ 'script/chordpro', 'script/wxchordpro' ],
 PL_FILES	=> {
		    'script/ppchordpro.PL' => [ 'script/chordpro', 'script/wxchordpro' ]
		   },
 PREREQ_PM      => {
		    'PDF::API2'   => 2.020,
		    'Font::TTF'   => 1.04,
		   },
 TEST_REQUIRES  => {
		    'Test::More'  => 0,
		   },

 META_MERGE => {
     license          => "perl_5",
     resources        => { homepage => "http://www.chordpro.org" },
     provides         => {
	 chordpro => { file => "script/chordpro",
		       version => $version },
	 "App::Music::ChordPro"
		  => { file => "lib/App/Music/ChordPro.pm",
		       version => $version },
     },
     no_index         => {
         file => [
	    "lib/App/Music/ChordPro/Songbook.pm",
	    "lib/App/Music/ChordPro/Chords.pm",
	 ],
         directory => [
	    "lib/App/Music/ChordPro/Output",
	 ],
     },
 },

);

# Note about the no_index: CPAN and MetaCPAN have differing opinions
# on how no_index must be interpreted, in particular in combination
# with provides.

sub MY::postamble {
    my $ret = <<'EOD';

# Actualize resources.

resources : res/config/chordpro.json \
	    res/pod/ChordPro.pod \
	    res/pod/Config.pod

res/config/chordpro.json : lib/App/Music/ChordPro/Config.pm
	$(PERLRUN) $< > $@

res/pod/ChordPro.pod : lib/App/Music/ChordPro.pm
	podselect $< > $@

res/pod/Config.pod :lib/App/Music/ChordPro/Config.pm
	podselect $< > $@
EOD
}
