# Packager settings for WxChordPro.

# Strawberry Perl + wxWidgets 3.0.

@../common/wxchordpro.pp
--gui

# Explicitly link the wxmsw libraries.
--link=wxbase30u_gcc_custom.dll
--link=wxbase30u_net_gcc_custom.dll
--link=wxbase30u_xml_gcc_custom.dll
--link=wxmsw30u_adv_gcc_custom.dll
--link=wxmsw30u_aui_gcc_custom.dll
--link=wxmsw30u_core_gcc_custom.dll
--link=wxmsw30u_html_gcc_custom.dll
--link=wxmsw30u_media_gcc_custom.dll
--link=wxmsw30u_propgrid_gcc_custom.dll
--link=wxmsw30u_ribbon_gcc_custom.dll
--link=wxmsw30u_richtext_gcc_custom.dll
--link=wxmsw30u_webview_gcc_custom.dll
