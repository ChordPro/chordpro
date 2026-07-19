# Packager settings for WxChordPro.

@../common/wxchordpro.pp

--module=Wx::WebView
--module=Wx::STC

# Explicitly link the wxGTK3 libraries.
--link=libwx_baseu_unofficial-3.2.so.0
--link=libwx_baseu_unofficial_net-3.2.so.0
--link=libwx_baseu_unofficial_xml-3.2.so.0
--link=libwx_gtk3u_unofficial_adv-3.2.so.0
--link=libwx_gtk3u_unofficial_aui-3.2.so.0
--link=libwx_gtk3u_unofficial_core-3.2.so.0
--link=libwx_gtk3u_unofficial_html-3.2.so.0
--link=libwx_gtk3u_unofficial_media-3.2.so.0
--link=libwx_gtk3u_unofficial_propgrid-3.2.so.0
--link=libwx_gtk3u_unofficial_ribbon-3.2.so.0
--link=libwx_gtk3u_unofficial_richtext-3.2.so.0
--link=libwx_gtk3u_unofficial_stc-3.2.so.0
--link=libwx_gtk3u_unofficial_webview-3.2.so.0

# And more...
-l deflate
-l jbig
-l jpeg
-l libpng16.so.16.37.0
-l SDL2-2.0
-l tiff
-l webp
