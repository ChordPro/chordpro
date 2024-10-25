# Packager settings for WxChordPro.

@chordpro.pp
--cachedeps=wxchordpro.pp.deps

# Explicitly include the Wx modules.
--module=ChordPro::Wx::Config
--module=ChordPro::Wx::EditorPanel
--module=ChordPro::Wx::EditorPanel_wxg
--module=ChordPro::Wx::Main
--module=ChordPro::Wx::Main_wxg
--module=ChordPro::Wx::PanelRole
--module=ChordPro::Wx::PreferencesDialog
--module=ChordPro::Wx::PreferencesDialog_wxg
--module=ChordPro::Wx::Preview
--module=ChordPro::Wx::RenderDialog
--module=ChordPro::Wx::RenderDialog_wxg
--module=ChordPro::Wx::SongbookExportPanel
--module=ChordPro::Wx::SongbookExportPanel_wxg
--module=ChordPro::Wx::Utils

# Explicitly include the demand-loaded Wx modules.
--module=Wx::AUI
--module=Wx::Calendar
--module=Wx::DND
--module=Wx::DataView
--module=Wx::DocView
--module=Wx::FS
--module=Wx::Grid
--module=Wx::Help
--module=Wx::Html
--module=Wx::MDI
--module=Wx::Media
--module=Wx::Print
--module=Wx::PropertyGrid
--module=Wx::Ribbon
--module=Wx::RichText
--module=Wx::Socket
