use ExtUtils::MakeMaker;
WriteMakefile
(
          'PL_FILES' => { 'script/chordii.PL' => 'script/chordii' },
          'INSTALLDIRS' => 'site',
          'NAME' => 'Music::ChordPro',
          'EXE_FILES' => [
                           'script/chordii',
                         ],
          'VERSION_FROM' => 'lib/Music/ChordPro.pm',
          'PREREQ_PM' => {
                           'Test::More' => 0,
                         }
        )
;
