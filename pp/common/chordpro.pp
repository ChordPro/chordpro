# Packager settings for ChordPro/WxChordPro.

--lib=../../CPAN
--lib=../../lib
--lib=../common

--cachedeps=chordpro.pp.deps

# Since not all modules are statically required, enumerate.
--module=App::Music::ChordPro::Bundle

# Same for PDF::API2 and Font::TTF.
# By explicitly including the main module we are pretty sure the
# package is actually installed and available.
# PAR::Packer has the nasty habit to silently ignore missing modules.
--module=PDF::API2
--module=Font::TTF
--module=PDF_API2_Bundle

# Same for Text::Layout
--module=Text::Layout
--module=Text_Layout_Bundle

# Same for String::Interpolate::Named
--module=String::Interpolate::Named

# Same for File::LoadLines
--module=File::LoadLines

# Resources.
--addfile=../../lib/App/Music/ChordPro/res;res

# Filtering
#--modfilter=Null=Config\.pm$
--modfilter=Null
