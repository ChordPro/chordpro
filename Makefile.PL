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

 PREREQ_PM      => {
		    'App::Packager' => 1.430,
		    'PDF::API2'   => 2.020,
		    'Font::TTF'   => 1.04,
		    'JSON::PP'	  => 2.27203,
		    'Text::Balanced' => 2.0.0
		   },

 CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => 6.5503,
 },

# BUILD_REQUIRES => {
# },

 TEST_REQUIRES  => {
		    'Test::More'  => 0,
		    'JSON::PP'	  => 2.27203,
		    'Text::Balanced' => 2.0.0
		   },

 META_MERGE => {
     license   => "perl_5",
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

sub MY::postamble {
    my $ret = <<'EOD';

# Actualize resources.

LIB = lib/App/Music/ChordPro
RES = ${LIB}/res
PODSELECT = podselect

resources : ${RES}/config/chordpro.json ${RES}/pod/ChordPro.pod ${RES}/pod/Config.pod ${RES}/notes/common.json

${RES}/config/chordpro.json : ${LIB}/Config.pm
	$(PERL) -Ilib $< > $@

${RES}/notes/common.json : ${RES}/notes/dutch.json
	$(CP) $< $@

${RES}/pod/ChordPro.pod : ${LIB}.pm
	${PODSELECT} $< > $@

${RES}/pod/Config.pod : ${LIB}/Config.pm
	${PODSELECT} $< > $@

# Verify JSON data

CFGLIB := ${LIB}/res/config

checkjson :
	for i in ${CFGLIB}/*.json ; \
	do \
	  echo "Verifying $$i..."; \
	  json_pp -json_opt relaxed < $$i | \
	  jsonschema -i /dev/stdin ${CFGLIB}/config.schema; \
	done
EOD
}
