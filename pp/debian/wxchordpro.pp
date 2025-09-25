# Packager settings for WxChordPro.

@../common/wxchordpro.pp

--module=Wx::WebView
--module=Wx::STC

# Explicitly link the wxGTK3 libraries.
--link=libwx_baseu-3.2.so.0
--link=libwx_baseu_net-3.2.so.0
--link=libwx_baseu_xml-3.2.so.0
--link=libwx_gtk3u_adv-3.2.so.0
--link=libwx_gtk3u_aui-3.2.so.0
--link=libwx_gtk3u_core-3.2.so.0
--link=libwx_gtk3u_html-3.2.so.0
--link=libwx_gtk3u_media-3.2.so.0
--link=libwx_gtk3u_propgrid-3.2.so.0
--link=libwx_gtk3u_ribbon-3.2.so.0
--link=libwx_gtk3u_richtext-3.2.so.0
--link=libwx_gtk3u_webview-3.2.so.0

# And more...
--link=libdeflate.so.0
--link=libjbig.so.0
--link=libjpeg.so.8
--link=libpng16.so.16
--link=libSDL2-2.0.so.0
--link=libtiff.so.6
--link=libwebp.so.7
