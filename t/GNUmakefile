#! /bin/make -f

PROVE := prove -lv

default :
	cd ..; make -f t/GNUmakefile all

all : passed todo

passed :
	${PROVE} t/01_prereq.t
	${PROVE} t/02_load.t
	${PROVE} t/15_subst.t
	${PROVE} t/100_basic.t
	${PROVE} t/101_empty.t
	${PROVE} t/102_new_song.t
	${PROVE} t/103_title.t
	${PROVE} t/104_subtitles.t
	${PROVE} t/105_chords.t
	${PROVE} t/107_chords_latin_dash.t
	${PROVE} t/107_chords_latin_o.t
	${PROVE} t/107_chords_latin.t
	${PROVE} t/108_chords_solfege_dash.t
	${PROVE} t/108_chords_solfege_o.t
	${PROVE} t/108_chords_solfege.t
	${PROVE} t/109_chords_nashville.t
	${PROVE} t/110_chords_roman.t
	${PROVE} t/112_comment.t
	${PROVE} t/113_comment.t
	${PROVE} t/114_songline.t
	${PROVE} t/115_songline.t
	${PROVE} t/116_chorus.t
	${PROVE} t/117_rechorus.t
	${PROVE} t/118_tab.t
	${PROVE} t/119_verse.t
	${PROVE} t/120_meta.t
	${PROVE} t/122_memorize.t
	${PROVE} t/130_image.t
	${PROVE} t/131_image.t
	${PROVE} t/140_chords.t
	${PROVE} t/150_fonts.t
	${PROVE} t/151_fonts.t
	${PROVE} t/160_diagrams.t
	${PROVE} t/161_titles.t
	${PROVE} t/162_newpage.t
	${PROVE} t/163_columns.t
	${PROVE} t/164_pagesize.t
	${PROVE} t/169_custom.t
	${PROVE} t/141_chords.t
	${PROVE} t/142_chords.t
	${PROVE} t/170_transpose.t
	${PROVE} t/171_transpose.t
	${PROVE} t/172_transpose.t
	${PROVE} t/175_transpose.t
	${PROVE} t/177_transcode.t
	${PROVE} t/178_transcode.t
	${PROVE} t/180_grids.t
	${PROVE} t/190_outlines.t
	${PROVE} t/191_outlines.t
	${PROVE} t/192_outlines.t
	${PROVE} t/193_outlines.t
	${PROVE} t/200_markup.t
	${PROVE} t/210_configs.t
	${PROVE} t/211_config.t
	${PROVE} t/310_basic.t
	${PROVE} t/311_keys.t
	${PROVE} t/312_context.t
	${PROVE} t/313_null.t
	${PROVE} t/314_data.t
	${PROVE} t/315_escape.t
	${PROVE} t/316_array.t
	${PROVE} t/317_empty.t
	${PROVE} t/320_subst.t
	${PROVE} t/321_subst.t
	${PROVE} t/322_subst.t
	${PROVE} t/323_null.t
	${PROVE} t/380_roundtrip.t
	${PROVE} t/400_kv.t
	${PROVE} t/20_basic01_crd.t
	${PROVE} t/21_basic02_crd.t
	${PROVE} t/30_basic01_cho.t
	${PROVE} t/31_basic02_cho.t
	${PROVE} t/40_basic01_html.t
	${PROVE} t/50_encodings.t
	${PROVE} t/70_a2crd.t
	${PROVE} t/72_mma.t

todo :
	- ${PROVE} t/173_transpose.t
	- ${PROVE} t/60_transpose.t
	- ${PROVE} t/71_cho.t
