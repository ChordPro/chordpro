#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.026000;

use ExtUtils::MakeMaker 7.24;	# comes with 5.26

my $master = 'lib/ChordPro/Version.pm';
my $version = MM->parse_version($master);
$master =~ s;/Version;;;

my @bins = qw( chordpro wxchordpro );

my @pdfapi = ( 'PDF::API2' => 2.043 ); # default
if ( my $a = $ENV{CHORDPRO_PDF_API} ) {
    if ( $a =~ /PDF::Builder/ ) {
	@pdfapi = ( 'PDF::Builder' => 3.025 );
    }
    elsif ( $a =~ /PDF::API2/ ) {
    }
    else {
	@pdfapi = ( $a => 0 );
    }
}

=for later

# Extract ABC files from (included) ABC dist kit.
ExtractABCFiles( abckit  => "abc2svg-1f1e9ecb65",
		 version => "1.22.13",
		 vdate   => '2024-01-30',
		 verbose => 0 );

=cut

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
    'lib/ChordPro/Config.pm' => 'blib/man3/ChordPro::Config.3pm',
    'lib/ChordPro/Wx.pm'     => 'blib/man3/ChordPro::Wx.3pm',
		     },
 # Always require PDF::API2 or PDF::Builder and Text::Layout.
 PREREQ_PM      => {
		    @pdfapi,
		    'Text::Layout'		  => 0.032,
		    'JSON::PP'			  => 2.27203,
		    'String::Interpolate::Named'  => 1.030,
		    'File::LoadLines'		  => 1.044,
		    'File::HomeDir'		  => 1.004,
		    'Image::Info'		  => 1.41,
		    'List::Util'		  => 1.46,
		    'Data::Printer'		  => 1.001001,
		    'Storable'			  => 3.08,
		    'Object::Pad'                 => 0.78,
		    'JavaScript::QuickJS'         => 0.18,
		   # Some distro's have removed this from the core.
		    'Pod::Usage'		  => 2.03,
		   # These are only used by the LaTeX backend
		   # 'Template'			  => 3.010,
		   # 'LaTeX::Encode'		  => 0.092.0,
		   },

 CONFIGURE_REQUIRES => {
		    'ExtUtils::MakeMaker'	  => 7.24,
		    },

# BUILD_REQUIRES => {
# },

 TEST_REQUIRES  => {
		    'Test::More'                  => 0,
		    'JSON::PP'	                  => 2.27203,
		    'String::Interpolate::Named'  => 1.01,
		    'Storable'			  => 3.08,
		    'Object::Pad'		  => 0.78,
		    @pdfapi,
		   },

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
	 mailto => "info@chordpro.org",
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

sub ExtractABCFiles {
    my %args = @_;
    my $verbose = $args{verbose} // 1;
    use Archive::Tar;

    my $abcroot = $args{abckit};
    my $tarkit  = $args{tar} // "ABC/$abcroot.tar.gz";
    my $dest    = "lib/ChordPro/res/abc/abc2svg";
    my $version = $args{version};
    my $vdate   = $args{vdate};
    my $major   = 1;

    my $tar = Archive::Tar->new($tarkit);

    my $target;
    for $target ( "$dest/abc2svg-$major.js" ) {
	warn("Creating $target...\n") if $verbose;
	open( my $fd, '>', $target )
	  or die( "$target: $!\n" );

	for my $mod ( qw( core/abc2svg.js core/deco.js core/draw.js
			  font.js core/format.js core/front.js core/music.js
			  core/parse.js core/subs.js core/svg.js core/tune.js
			  core/lyrics.js core/gchord.js core/tail.js
			  core/modules.js ) ) {
	    my $data = $tar->get_content("$abcroot/$mod");
	    die( "$abcroot/$mod: $!\n" ) unless $data;
	    warn("  adding $mod (", length($data), " bytes)...\n") if $verbose > 1;
	    $data .= "\n" unless $data =~ /\n$/;
	    print $fd $data;
	}
	warn("  fixing version...\n") if $verbose > 1;
	printf $fd ( 'abc2svg.version="%s";abc2svg.vdate="%s"'."\n",
		     $version, $vdate );
	$fd->close
	  or die( "$target: $!\n" );
    }

    for $target ( "$dest/page-$major.js" ) {
	warn("Creating $target...\n") if $verbose;
	open( my $fd, '>', $target )
	  or die( "$target: $!\n" );

	for my $mod ( qw( modules/page.js modules/strftime.js ) ) {
	    my $data = $tar->get_content("$abcroot/$mod");
	    die( "$abcroot/$mod: $!\n" ) unless $data;
	    warn("  adding $mod (", length($data), " bytes)...\n") if $verbose > 1;
	    $data .= "\n" unless $data =~ /\n$/;
	    print $fd $data;
	}
	$fd->close
	  or die( "$target: $!\n" );
    }

    for $target ( "$dest/psvg-$major.js" ) {
	warn("Creating $target...\n") if $verbose;
	open( my $fd, '>', $target )
	  or die( "$target: $!\n" );

	for my $mod ( qw( modules/wps.js modules/psvg.js ) ) {
	    my $data = $tar->get_content("$abcroot/$mod");
	    die( "$abcroot/$mod: $!\n" ) unless $data;
	    warn("  adding $mod (", length($data), " bytes)...\n") if $verbose > 1;
	    $data .= "\n" unless $data =~ /\n$/;
	    print $fd $data;
	}
	$fd->close
	  or die( "$target: $!\n" );
    }

    for my $mod ( qw( modules/ambitus.js
		      modules/break.js
		      modules/capo.js
		      modules/chordnames.js
		      modules/clair.js
		      modules/clip.js
		      modules/combine.js
		      modules/diag.js
		      modules/equalbars.js
		      modules/gamelan.js
		      modules/grid.js
		      modules/grid2.js
		      modules/grid3.js
		      modules/jazzchord.js
		      modules/jianpu.js
		      modules/mdnn.js
		      modules/nns.js
		      modules/MIDI.js
		      modules/pedline.js
		      modules/perc.js
		      modules/roman.js
		      modules/soloffs.js
		      modules/sth.js
		      modules/strtab.js
		      modules/temper.js
		      modules/tropt.js
		   ) ) {

	$mod =~ m;/(.*)\.js;;
	my $target = "$dest/$1-$major.js";

	warn("Creating $target...\n") if $verbose;
	open( my $fd, '>', "$target" )
	  or die( "$target: $!\n" );

	my $data = $tar->get_content("$abcroot/$mod");
	die( "$abcroot/$mod: $!\n" ) unless $data;
	warn("  adding $mod (", length($data), " bytes)...\n") if $verbose > 1;
	$data .= "\n" unless $data =~ /\n$/;
	print $fd $data;

	$fd->close
	  or die( "$target: $!\n" );
    }

    for my $mod ( qw( COPYING README.md tohtml.js ) ) {

	my $target = "$dest/$mod";

	warn("Creating $target...\n") if $verbose;
	open( my $fd, '>', "$target" )
	  or die( "$target: $!\n" );

	my $data = $tar->get_content("$abcroot/$mod");
	die( "$abcroot/$mod: $!\n" ) unless $data;
	warn("  adding $mod (", length($data), " bytes)...\n") if $verbose > 1;
	$data .= "\n" unless $data =~ /\n$/;
	print $fd $data;

	$fd->close
	  or die( "$target: $!\n" );
    }
}

sub MY::postamble {
    my $abckit  = "abc2svg-1f1e9ecb65";
    my $version = "1.22.13";
    my $vdate   = '2024-01-30';
    my $verbose => 1;
    my $dest    = "lib/ChordPro/res/abc/abc2svg";

    return <<EOD;
# Unpack and prepare ABC files from ABC kit.

config :: $dest/tohtml.js

$dest/tohtml.js : ABC/$abckit.tar.gz
\tperl ABC/build.pl --dest=$dest \\
\t  \$< --version=$version --vdate=$vdate
EOD
};
