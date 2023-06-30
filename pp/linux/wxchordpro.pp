# Packager settings for WxChordPro.

@../common/wxchordpro.pp

--module=Wx::WebView

# Explicitly link the wxGTK3 libraries.
--link=libwx_baseu-3.0.so.0
--link=libwx_baseu_net-3.0.so.0
--link=libwx_baseu_xml-3.0.so.0
--link=libwx_gtk3u_adv-3.0.so.0
--link=libwx_gtk3u_aui-3.0.so.0
--link=libwx_gtk3u_core-3.0.so.0
--link=libwx_gtk3u_html-3.0.so.0
--link=libwx_gtk3u_media-3.0.so.0
--link=libwx_gtk3u_propgrid-3.0.so.0
--link=libwx_gtk3u_ribbon-3.0.so.0
--link=libwx_gtk3u_richtext-3.0.so.0

# And more...
--link=libpng16.so.16
--link=libSDL-1.2.so.0
--link=libgconf-2.so.4
--link=libORBit-2.so.0
