#! perl

# Ease the life of the CPAN testers.
BEGIN { exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.026000 }

use v5.26;

use ExtUtils::MakeMaker 7.24;	# comes with 5.26

my $master = 'lib/ChordPro/Version.pm';
my $version = MM->parse_version($master);
$master =~ s;/Version;;;

my @bins = qw( chordpro wxchordpro );

# Module/Version requirements.
my $mv =
  { 'File::LoadLines'		   => 1.047,
    'HarfBuzz::Shaper'		   => 0.026, # Text::Layout
    'String::Interpolate::Named'   => 1.060,
     # 'SVGPDF'			   => 0.089,
    'Text::Layout'		   => 0.045,

    'Data::Printer'		   => 1.001001,
    'File::Copy'		   => 2.32, # Core
    'File::HomeDir'		   => 1.004,
    'IPC::Run3'			   => 0.049,
    'Image::Info'		   => 1.41,
    'JSON::PP'			   => 2.27203,
    'JSON::XS'			   => 4.03,
    'JavaScript::QuickJS'	   => 0.18,
    'LWP::Protocol::https'	   => 6.14, # File::LoadLines
    'List::Util'		   => 1.46,
    'Mozilla::CA'		   => 20230801, # File::LoadLines
    'Object::Pad'		   => 0.818,
    'Pod::Usage'		   => 2.03, # Core
    'Ref::Util'			   => 0.204,
    'Scalar::Util'		   => 1.63,
    'Storable'			   => 3.08,
    'Unicode::Collate'		   => 1.31,
    'Unicode::Normalize'	   => 1.26,
  };

# PDF API.
$mv->{'PDF::API2'} = 2.045; # pref: 2.047
if ( my $a = $ENV{CHORDPRO_PDF_API} ) {
    if ( $a =~ /PDF::Builder/ ) {
	$mv->{'PDF::Builder'} = 3.025;
	delete $mv->{'PDF::API2'};
    }
    elsif ( $a =~ /PDF::API2/ ) {
    }
    else {
	$mv->{$a} = 0;
	delete $mv->{'PDF::API2'};
    }
}

# Windows
if ( $^O =~ /mswin/i ) {
    $mv->{'Win32::LongPath'} = 2.0;
}

# These are only used by the LaTeX backend
if ( 0 ) {
    $mv->{'Template'}      = 3.010;
    $mv->{'LaTeX::Encode'} = 0.092.0;
}

WriteMakefile
(
 NAME		  => 'App::Music::ChordPro',
 ABSTRACT         => "A lyrics and chords formatting program",
 VERSION	  => $version,
 AUTHOR	          => 'Johan Vromans <jvromans@squirrel.nl>',
 LICENSE	  => "perl_5",
 MIN_PERL_VERSION => 5.026000,
 INSTALLDIRS	  => 'site',
 EXE_FILES	  => [ map { "script/$_" } @bins ],
 PL_FILES	  => {
		       'script/ppchordpro.PL' => [ map { "script/$_" } @bins ]
		     },
 MAN3PODS	  => {
    'lib/ChordPro.pm'        => 'blib/man3/ChordPro.3pm',
    'lib/ChordPro/A2Crd.pm'  => 'blib/man3/ChordPro::A2Crd.3pm',
    'lib/ChordPro/Wx.pm'     => 'blib/man3/ChordPro::Wx.3pm',
		     },
 PREREQ_PM        => $mv,
 CONFIGURE_REQUIRES => {
		    'ExtUtils::MakeMaker'	  => 7.24,
		    },

 BUILD_REQUIRES   => $mv,
 TEST_REQUIRES    => $mv,

 META_MERGE => {
     'meta-spec'  => { version => 2, },
     resources    => {
       license    => [ "https://dev.perl.org/licenses/" ],
       homepage   => 'https://chordpro.org',
       repository => {
	 url => 'git://github.com/ChordPro/chordpro.git',
	 web => 'https://github.com/ChordPro/chordpro',
	 type => 'git',
       },
       bugtracker => {
	 web => "https://github.com/ChordPro/chordpro/issues",
	 mailto => 'info@chordpro.org',
       },
    },
     provides => {
	 chordpro => { file => "script/chordpro",
		       version => $version },
	 "App::Music::ChordPro"
		  => { file => "lib/ChordPro.pm",
		       version => $version },
     },
     no_index => {
         file => [
	    "lib/ChordPro/Songbook.pm",
	    "lib/ChordPro/Chords.pm",
	    "lib/ChordPro/Config.pm",
	    "lib/ChordPro/Testing.pm",
	    "lib/ChordPro/Utils.pm",
	    "lib/ChordPro/Version.pm",
	    "lib/ChordPro/Wx.pm",
	 ],
         directory => [
	    "lib/ChordPro/Chords",
	    "lib/ChordPro/Config",
	    "lib/ChordPro/Delegate",
	    "lib/ChordPro/Output",
	    "lib/ChordPro/Wx",
	    "lib/ChordPro/lib",
	    "lib/ChordPro/res",
	    "pp",
	 ],
     },
 },

);

# Note about the no_index: CPAN and MetaCPAN have differing opinions
# on how no_index must be interpreted, in particular in combination
# with provides.

sub MY::postamble {
    return <<'MAKE_FRAG';
config :: lib/ChordPro/Config/Data.pm
lib/ChordPro/Config/Data.pm : lib/ChordPro/res/config/chordpro.json
	perl script/cfgboot.pl $< > $@

MAKE_FRAG
}
