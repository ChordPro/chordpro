# Packager settings for WxChordPro.

# Strawberry Perl + wxWidgets 3.0.

@../common/wxchordpro.pp
--gui
--module=Wx::WebView

# Explicitly link the wxmsw libraries.
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxbase30u_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxbase30u_net_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxbase30u_xml_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_adv_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_aui_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_core_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_html_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_media_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_propgrid_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_ribbon_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_richtext_gcc_custom.dll
--link=C:/Strawberry/perl/site/lib/Alien/wxWidgets/msw_3_0_2_uni_gcc_3_4/lib/wxmsw30u_webview_gcc_custom.dll
