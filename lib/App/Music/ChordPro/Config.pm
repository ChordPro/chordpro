#! perl

package App::Music::ChordPro::Config;

use strict;
use warnings;

use PDF::API2;
use JSON::PP ();
use Hash::Util qw(lock_hash_recurse unlock_hash_recurse);

sub hmerge($$);

sub config_defaults {

    # Using these defaults guarantees that the relevant configs are
    # defined and have a sensible value.

    return <<EndOfDefs
// Configuration (mostly layout definitions) for ChordPro.
//
// This is a relaxed JSON document, so comments are possible.

{
    // Layout definitions for PDF output.

    "pdf" : {

	// Papersize, 'a4' or [ 595, 842 ] etc.
	"papersize" : "a4",

	// Number of columns.
	// Can be overridden with {columns} directive.
	// "columns"   : 2,
	// Space between columns, in pt.
	"columnspace"  :  20,

	// Page margins.
	// Note that top/bottom exclude the head/footspace.
	"margintop"    :  90,
	"marginbottom" :  40,
	"marginleft"   :  40,
	"marginright"  :  40,
	"headspace"    :  50,
	"footspace"    :  20,

	// Spacings.
	// Baseline distances as a factor of the font size.
	"spacing" : {
	    "title"  : 1.2,
	    "lyrics" : 1.2,
	    "chords" : 1.2,
	    "grid"   : 1.2,
	    "tab"    : 1.0,
	    "toc"    : 1.4,
	},

	// Style of chorus indicator.
	"chorus-indent"     :  0,
	"chorus-bar-offset" :  8,
	"chorus-bar-width"  :  1,
	"chorus-bar-color"  : "black",

	// Alternative songlines with chords in a side column.
	// Value is the column position.
	// "chordscolumn" : 400,
	"chordscolumn" :  0,

	// Suppress empty chord lines.
	// Overrides the -a (--single-space) command line options.
	"suppress-empty-chords" : 1,

	// Flush titles.
	"titles-flush" : "center",

	// Right/Left page numbers.
	"even-pages-number-left" : 1,

	// Fonts.
	// Fonts can be specified by name (for the corefonts)
	// or a filename (for TrueType/OpenType fonts).
	// Relative filenames are looked up in the fontdir.
	// "fontdir" : "/home/jv/.fonts",

	// Fonts for chords and comments can have a background
	// colour associated.
	// Colours are "#RRGGBB" or predefined names like "black", "white",
	// and lots of others.

	"fonts" : {
	    "title" : {
		"name" : "Times-Bold",
		"size" : 14
	    },
	    "text" : {
		"name" : "Times-Roman",
		"size" : 14
	    },
	    "chord" : {
		"name" : "Helvetica-Oblique",
		"size" : 10
	    },
	    "comment" : {
		"name" : "Helvetica",
		"size" : 12
	    },
	    "tab" : {
		"name" : "Courier",
		"size" : 10
	    },
	},

	// Fonts that can be specified, but need not.
	// subtitle       --> text
	// comment        --> text
	// comment_italic --> chord
	// comment_box    --> chord
	// toc            --> text
	// grid           --> chord
	// footer         --> subtitle @ 60%

	// This will show the page layout.
	// "showlayout" : 1,
    }
}
EndOfDefs
}

sub configurator {
    my ( $options ) = @_;

    my $backend_configurator =
      UNIVERSAL::can( $options->{backend}, "configurator" );

    my $pp = JSON::PP->new->utf8->relaxed;

    # Load defaults.
    my $cfg = $pp->decode( config_defaults() );

    # Apply config files

    my $add_config = sub {
	my ( $file ) = @_;
	warn("Config: $file\n") if $options->{verbose};
	if ( open( my $fd, "<:utf8", $file ) ) {
	    local $/;
	    $cfg = hmerge( $cfg, $pp->decode( scalar( <$fd> ) ) );
	    $fd->close;
	}
	else {
	    ### Should not happen -- it's been checked in app_setup.
	    die("Cannot open $file [$!]\n");
	}
    };

    foreach my $config ( qw( sysconfig userconfig config ) ) {
	next if $options->{"no$config"};
	if ( ref($options->{$config}) eq 'ARRAY' ) {
	    $add_config->($_) foreach @{ $options->{$config} };
	}
	else {
	    $add_config->( $options->{$config} );
	}
    }

    # Backend specific configs.
    $backend_configurator->( $cfg, $options ) if $backend_configurator;

    # Write resultant config, if needed.
    my $cfg_new = "config.new";
    if ( -e $cfg_new && ! -s _ ) {
	open( my $fd, '>:utf8', $cfg_new );
	$fd->print(JSON::PP->new->utf8->canonical->indent(4)->pretty->encode($cfg));
	$fd->close;
    }

    # For convenience...
    bless( $cfg, __PACKAGE__ );
    lock_hash_recurse(%$cfg);
    return $cfg;
}

sub hmerge($$) {

    # Merge hashes. Right takes precedence.
    # Based on Hash::Merge::Simple by Robert Krimen.

    my ( $left, $right ) = @_;

    my %res = %$left;

    for my $key ( keys(%$right) ) {

        if ( ref($right->{$key}) eq 'HASH'
	     and
	     ref($left->{$key}) eq 'HASH' ) {

	    # Both hashes. Recurse.
            $res{$key} = hmerge( $left->{$key}, $right->{$key} );
        }
        else {
            $res{$key} = $right->{$key};
        }
    }

    return \%res;
}

use Clone ();

sub clone {
    my $self = shift;
    my $h = Clone::clone($self);
    bless( $h, ref($self) );
}

1;
