#! perl

use ExtUtils::MakeMaker;

WriteMakefile
(
 'PL_FILES' => { 'script/chordpro.PL' => 'script/chordpro' },
 'INSTALLDIRS' => 'site',
 'NAME' => 'App::Music::ChordPro',
 'EXE_FILES' => [
		 'script/chordpro',
		],
 'ABSTRACT_FROM' => 'lib/App/Music/ChordPro.pm',
 'VERSION_FROM' => 'lib/App/Music/ChordPro.pm',
 'AUTHOR' => 'Johan Vromans <jvromans@squirrel.nl>',
 'PREREQ_PM' => {
		 'PDF::API2' => 2.021,
		 'Font::TTF' => 1.05,
		 'IO::String' => 1.08,
		 'Test::More' => 0,
		},
 'META_MERGE' => {
		  'release-status' => "alpha",
		  'license' => "perl_5",
		  resources => {
				homepage => "http://www.chordpro.org",
			       },
		  provides => {
			       ChordPro => {
					    file => "lib/App/Music/ChordPro.pm",
					   },
			      },
		  no_index => {
			       directory => [
					     "lib/App/Music/ChordPro",
					    ],
			      },
		 },
);
