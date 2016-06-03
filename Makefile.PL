#! perl

use ExtUtils::MakeMaker;

WriteMakefile
(
 'PL_FILES' => { 'script/chordpro.PL' => 'script/chordpro' },
 'INSTALLDIRS' => 'site',
 'NAME' => 'Music::ChordPro',
 'EXE_FILES' => [
		 'script/chordpro',
		],
 'VERSION_FROM' => 'lib/Music/ChordPro.pm',
 'PREREQ_PM' => {
		 'PDF::API2' => 2.021,
		 'Font::TTF' => 1.05,
		 'IO::String' => 1.08,
		 'Test::More' => 0,
		}
)
;
