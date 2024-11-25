#! /bin/make -f

WXGLADE := wxglade --generate-code=perl --use-config=dot.wxglade/wxgladerc
WXG2TXT := perl wxg2txt.pl

all :: 	Main_wxg.pm \
	EditorPanel_wxg.pm \
	NewSongDialog_wxg.pm \
	SettingsDialog_wxg.pm \
	RenderDialog_wxg.pm \
	SongbookExportPanel_wxg.pm \
	WxUpdateRequired.pm

Main_wxg.pm : Main.wxg
	${WXGLADE} --output=$@ $<
	${WXG2TXT} $<

EditorPanel_wxg.pm : EditorPanel.wxg
	${WXGLADE} --output=$@ $<
	${WXG2TXT} $<

NewSongDialog_wxg.pm : NewSongDialog.wxg
	${WXGLADE} --output=$@ $<
	${WXG2TXT} $<

SettingsDialog_wxg.pm : SettingsDialog.wxg
	${WXGLADE} --output=$@ $<
	${WXG2TXT} $<

RenderDialog_wxg.pm : RenderDialog.wxg
	${WXGLADE} --output=$@ $<
	${WXG2TXT} $<

SongbookExportPanel_wxg.pm : SongbookExportPanel.wxg
	${WXGLADE} --output=$@ $<
	${WXG2TXT} $<

WxUpdateRequired.pm : WxUpdateRequired.wxg
	${WXGLADE} --output=$@ $<
	${WXG2TXT} $<

clean ::
	rm -f *~ \#*\# -r __pycache__
