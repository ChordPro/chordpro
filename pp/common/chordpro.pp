# Packager settings for ChordPro/WxChordPro.

--lib=../../CPAN
--lib=../../lib
--lib=../../lib/ChordPro/lib
--lib=../common

--cachedeps=chordpro.pp.deps

# Since not all modules are statically required, enumerate.
--module=ChordPro_Bundle

# Same for PDF::API2 and Font::TTF.
# By explicitly including the main module we are pretty sure the
# package is actually installed and available.
# PAR::Packer has the nasty habit to silently ignore missing modules.
--module=PDF::API2
--module=Font::TTF
--module=PDF_API2_Bundle
--module=SVGPDF

# Same for PerlIO
--module=PerlIO
--module=PerlIO::encoding

# Same for Ref::Util
--module=Ref::Util
--module=Ref::Util::XS

# Same for Text::Layout
--module=Text::Layout
--module=Text_Layout_Bundle
--module=HarfBuzz::Shaper

# Same for String::Interpolate::Named
--module=String::Interpolate::Named

# Same for File::LoadLines
--module=File::LoadLines

# Same for Object::Pad
--module=Object::Pad
--module=XS::Parse::Keyword
--module=XS::Parse::Sublike

# Same for JavaScript::QuickJS
--module=JavaScript::QuickJS
--module=JavaScript::QuickJS::Function
--module=JavaScript::QuickJS::Date
--module=JavaScript::QuickJS::RegExp

# Same for Data::Printer
--module=Data::Printer
--module=Data::Printer::Theme::Material
--module=Data::Printer::Theme::Zellner

# Resources.
--addfile=../../lib/ChordPro/res;res

# Filtering
#--modfilter=Null=Config\.pm$
--modfilter=Null
