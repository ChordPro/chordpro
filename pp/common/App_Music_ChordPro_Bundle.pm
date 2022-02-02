#! perl

# Dummy for the packager, to get all output drivers included.

use App::Music::ChordPro::Output::Common;
use App::Music::ChordPro::Output::PDF;
use App::Music::ChordPro::Output::PDF::PDFWriter;
use App::Music::ChordPro::Output::PDF::StringDiagrams;
use App::Music::ChordPro::Output::Debug;
use App::Music::ChordPro::Output::ChordPro;
use App::Music::ChordPro::Output::Text;
use App::Music::ChordPro::Output::HTML;
use App::Music::ChordPro::Delegate::ABC;
use App::Music::ChordPro::Delegate::Lilypond;

1;
