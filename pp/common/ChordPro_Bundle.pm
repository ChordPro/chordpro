#! perl

# Dummy for the packager, to get all output drivers included.

use ChordPro::Output::Common;
use ChordPro::Output::PDF;
use ChordPro::Output::PDF::PDFWriter;
use ChordPro::Output::PDF::StringDiagram;
use ChordPro::Output::PDF::KeyboardDiagram;
use ChordPro::Output::Debug;
use ChordPro::Output::ChordPro;
use ChordPro::Output::Text;
use ChordPro::Output::HTML;
use ChordPro::Delegate::ABC;
use ChordPro::Delegate::Lilypond;
use ChordPro::Delegate::SVG;
use ChordPro::Delegate::TextBlock;

1;
