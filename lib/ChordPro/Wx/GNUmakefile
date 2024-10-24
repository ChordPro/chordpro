#! /bin/make -f

WXGLADE := wxglade --generate-code=perl --use-config=dot.wxglade/wxgladerc

all :: 	Main_wxg.pm \
	EditorPanel_wxg.pm \
	PreferencesDialog_wxg.pm \
	RenderDialog_wxg.pm \
	SongbookExportPanel_wxg.pm

Main_wxg.pm : Main.wxg
	${WXGLADE} --output=$@ $<

EditorPanel_wxg.pm : EditorPanel.wxg
	${WXGLADE} --output=$@ $<

PreferencesDialog_wxg.pm : PreferencesDialog.wxg
	${WXGLADE} --output=$@ $<

RenderDialog_wxg.pm : RenderDialog.wxg
	${WXGLADE} --output=$@ $<

SongbookExportPanel_wxg.pm : SongbookExportPanel.wxg
	${WXGLADE} --output=$@ $<



