#! perl

use ExtUtils::MakeMaker;

WriteMakefile
(
 NAME		=> 'App::Music::ChordPro',
 ABSTRACT_FROM  => 'lib/App/Music/ChordPro.pm',
 VERSION_FROM	=> 'lib/App/Music/ChordPro.pm',
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',

 INSTALLDIRS	=> 'site',
 EXE_FILES	=> [ 'script/chordpro' ],
 PL_FILES	=> { 'script/chordpro.PL' => 'script/chordpro' },

 PREREQ_PM      => {
		    'PDF::API2'   => 2.021,
		    'Font::TTF'   => 1.05,
		   },
 TEST_REQUIRES  => {
		    'Test::More'  => 0,
		   },

 META_MERGE => {
     release_status   => "unstable",
     license          => "perl_5",
     resources        => { homepage => "http://www.chordpro.org" },
     provides         => {
         chordpro => { file => "script/chordpro" }
     },
     no_index         => {
         namespace => [
	    "App::Music::ChordPro",
	 ],
     },
 },

);
