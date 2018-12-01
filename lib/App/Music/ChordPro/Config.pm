#! perl

package App::Music::ChordPro::Config;

use strict;
use warnings;
use utf8;
use App::Packager;
use Carp;
use App::Music::ChordPro;

=head1 NAME

App::Music::ChordPro::Config - Built-in configuration

=head1 DESCRIPTION

The configurations files are 'relaxed' JSON files. This means that
they may contain comments and trailing comma's.

Currently, most settings in the configuration files are for the PDF
backend.

This is the current built-in configuration file, showing all settings.

  // Configuration for ChordPro.
  //
  // This is a relaxed JSON document, so comments are possible.
  
  {
      // Includes. These are processed first, before the rest of
      // the config file.
      //
      // "include" takes a list of either filenames or preset names.
      // "include" : [ "modern1", "lib/mycfg.json" ],
      "include" : [ "guitar" ],
  
      // General settings, to be changed by legacy configs and
      // command line.
      "settings" : {
  	// Titles flush: default center.
  	"titles" : "center",
  	// Columns, default one.
  	"columns" : 1,
  	// Suppress empty chord lines.
  	// Overrides the -a (--single-space) command line options.
  	"suppress-empty-chords" : true,
  	// Suppress chords.
  	// Overrides --lyrics-only command line option.
  	"lyrics-only" : false,
	// Memorize chords in sections, to be recalled by [^].
	"memorize" : false,
  	// Chords inline.
  	// May be a string containing pretext %s posttext.
  	// Defaults to "[%s]" if true.
  	"inline-chords" : false,
  	// Chords under the lyrics.
  	"chords-under" : false,
        // Transcoding.
        "transcode" : null,
	// Always decapoize.
	"decapo" : false,
      },
  
      // Metadata.
      // For these keys you can use {meta key ...} as well as {key ...}.
      // If strict is nonzero, only the keys named here are allowed.
      // If strict is zero, {meta ...} will accept any key.
      // Important: "title" and "subtitle" must always be in this list.
      // The separator is used to concatenate multiple values.
      "metadata" : {
        "keys" : [ "title", "subtitle",
                   "artist", "composer", "lyricist", "arranger",
                   "album", "copyright", "year",
                   "key", "time", "tempo", "capo", "duration" ],
        "strict" : true,
        "separator" : "; ",
      },
  
      // Instrument settings. These are usually set by a separate
      // config file.
      //
      "instrument" : null,
  
      // Note (chord root) names.
      // Strings and tuning.
      "tuning" : [ "E2", "A2", "D3", "G3", "B3", "E4" ],

      // In case of alternatives, the first one is used for output.
      "notes" : {
  
  	"system" : "common",
  
  	"sharp" : [ "C", [ "C#", "Cis", "C♯" ],
  		    "D", [ "D#", "Dis", "D♯" ],
  		    "E",
  		    "F", [ "F#", "Fis", "F♯" ],
  		    "G", [ "G#", "Gis", "G♯" ],
  		    "A", [ "A#", "Ais", "A♯" ],
  		    "B",
  		  ],
  
  	"flat" :  [ "C",
  		    [ "Db", "Des",        "D♭" ], "D",
  		    [ "Eb", "Es",  "Ees", "E♭" ], "E",
  		    "F",
  		    [ "Gb", "Ges",        "G♭" ], "G",
  		    [ "Ab", "As",  "Aes", "A♭" ], "A",
  		    [ "Bb", "Bes",        "B♭" ], "B",
    		  ],
      },
  
      // User defined chords.
      // "base" defaults to 1.
      // Use 0 for an empty string, and -1 for a muted string.
      // "fingers" is optional.
      "chords" : [
        //  {
  	//    "name"  : "Bb",
  	//    "base"  : 1,
  	//    "frets" : [ 1, 1, 3, 3, 3, 1 ],
  	//    "fingers" : [ 1, 1, 2, 3, 4, 1 ],
  	//  },
      ],
  
      // Printing chord diagrams.
      // "auto": automatically add unknown chords as empty diagrams.
      // "show": prints the chords used in the song.
      //         "all": all chords used.
      //         "user": only prints user defined chords.
      // "sorted": order the chords by key.
      "diagrams" : {
          "auto"     :  false,
          "show"     :  "all",
          "sorted"   :  false,
      },
  
      // Diagnostig messages.
      "diagnostics" : {
	  "format" : "\"%f\", line %n, %m\n\t%l",
      },
  
      // Table of contents.
      "toc" : {
  	  // Title for ToC.
  	  "title" : "Table of Contents",
	  // Sorting order.
	  // Currently only sorting by page number and alpha is implemented.
	  "order" : "page",
      },
  
      // Layout definitions for PDF output.
  
      "pdf" : {
  
  	// Papersize, 'a4' or [ 595, 842 ] etc.
  	"papersize" : "a4",
  
  	// Space between columns, in pt.
  	"columnspace"  :  20,
  
  	// Page margins.
  	// Note that top/bottom exclude the head/footspace.
  	"margintop"    :  80,
  	"marginbottom" :  40,
  	"marginleft"   :  40,
  	"marginright"  :  40,
  	"headspace"    :  60,
  	"footspace"    :  20,
  
  	// Special: head on first page only, add the headspace to
	// the other pages so they become larger.
  	"head-first-only" : false,
  
  	// Spacings.
  	// Baseline distances as a factor of the font size.
  	"spacing" : {
  	    "title"  : 1.2,
  	    "lyrics" : 1.2,
  	    "chords" : 1.2,
  	    "grid"   : 1.2,
  	    "tab"    : 1.0,
  	    "toc"    : 1.4,
	    "empty"  : 1.0,
  	},
  	// Note: By setting the font size and spacing for empty lines to
	// smaller values, you get a fine(r)-grained control over the
	// spacing between the various parts of the song.
  
  	// Style of chorus.
  	"chorus" : {
	    "indent"     :  0,
  	    // Chorus side bar.
	    // Suppress by setting offset and/or width to zero.
  	    "bar" : {
		"offset" :  8,
		"width"  :  1,
		"color"  : "black",
	    },
	    "tag" : "Chorus",
            // Recall style: Print the tag using the type.
            // Alternatively quote the lines of the preceding chorus.
            "recall" : {
                 "tag"   : "Chorus",
                 "type"  : "comment",
                 "quote" : false,
            },
	},
  
	// Markup for sections (in progress).
  	// Define what to do with begin_of_XXX directives.
  	// Use fallback as fallback.
  	// Default is to ignore them.
  	"section" : {
  	    // "fallback" : "comment",
  	},
  
	// This opens a margin for margin labels.
	"labels" : {
	    // Margin width. Default is 0 (no margin labels).
            // "auto" will automatically reserve a margin if labels are used.
	    "width" : "auto",
	    // Alignment for the labels. Default is left.
	    "align" : "left",
	},
  
  	// Alternative songlines with chords in a side column.
  	// Value is the column position.
  	// "chordscolumn" : 400,
  	"chordscolumn" :  0,
	"capoheading" : "%{capo|Capo: %{}}",
  
	// A {titles: left} may conflict with customized formats.
	// Set to non-zero to ignore the directive.
	"titles-directive-ignore" : false,
  
    	// Chord diagrams.
  	// A chord diagram consists of a number of cells.
  	// Cell dimensions are specified by "width" and "height".
  	// The horizontal number of cells depends on the number of strings.
  	// The vertical number of cells is "vcells", which should
	// be 4 or larger to accomodate most chords.
  	// The horizontal distance between diagrams is "hspace" cells.
  	// The vertical distance is "vspace" cells.
	// "linewidth" is the thickness of the lines as a fraction of "width".
	// Diagrams for all chords of the song can be shown at the
  	// "top", "bottom" or "right" side of the first page,
	// or "below" the last song line.
  	"diagrams" : {
	    "show"     :  "bottom",
	    "width"    :  6,
  	    "height"   :  6,
  	    "hspace"   :  3.95,
  	    "vspace"   :  3,
  	    "vcells"   :  4,
	    "linewidth" : 0.1,
  	},
  
  	// Even/odd pages. A value of -1 denotes odd/even pages.
  	"even-odd-pages" : 1,
  
  	// Formats.
  	"formats" : {
  	    // Titles/Footers.

  	    // Titles/footers have 3 parts, which are printed left,
  	    // centered and right.
  	    // For even/odd printing, the order is reversed.

  	    // By default, a page has:
  	    "default" : {
  	        // No title/subtitle.
  	    	"title"     : null,
  	    	"subtitle"  : null,
  		// Footer is title -- page number.
  	    	"footer"    : [ "%{title}", "", "%{page}" ],
  	    },
  	    // The first page of a song has:
  	    "title" : {
  	        // Title and subtitle.
  	    	"title"     : [ "", "%{title}", "" ],
  	    	"subtitle"  : [ "", "%{subtitle}", "" ],
  		// Footer with page number.
  	    	"footer"    : [ "", "", "%{page}" ],
  	    },
  	    // The very first output page is slightly different:
  	    "first" : {
  	    	// It has title and subtitle, like normal 'first' pages.
  		// But no footer.
  	    	"footer"    : null,
  	    },
  	},
  
  	// Fonts.
  	// Fonts can be specified by name (for the corefonts)
  	// or a filename (for TrueType/OpenType fonts).
  	// Relative filenames are looked up in the fontdir.
	// "fontdir" : [ "/usr/share/fonts/liberation", "/home/me/fonts" ],
  	"fontdir" : null,
  
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
  		"size" : 12
  	    },
  	    "chord" : {
  		"name" : "Helvetica-Oblique",
  		"size" : 10
  	    },
  	    "comment" : {
  		"name" : "Helvetica",
  		"size" : 12,
		"background" : "#E5E5E5"
  	    },
  	    "comment_italic" : {
  		"name" : "HelveticaOblique",
  		"size" : 12,
  	    },
  	    "comment_box" : {
  		"name" : "Helvetica",
  		"size" : 12,
		"frame" : 1
  	    },
  	    "tab" : {
  		"name" : "Courier",
  		"size" : 10
  	    },
  	    "toc" : {
  		"name" : "Times-Roman",
  		"size" : 11
  	    },
  	    "grid" : {
  		"name" : "Helvetica",
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
  	// grid_margin	  --> comment
  	// footer         --> subtitle @ 60%
  	// empty          --> text
	// diagram	  --> comment
	// diagram_base	  --> text (but at a small size)
  
  	// This will show the page layout if non-zero.
  	"showlayout" : false,
      },
  
      // Settings for ChordPro backend.
      "chordpro" : {
  	  // Style of chorus.
  	  "chorus" : {
  	      // Recall style: Print the tag using the type.
  	      // Alternatively quote the lines of the preceding chorus.
	      // If no tag+type or quote: use {chorus}.
	      // Note: Variant 'msp' always uses {chorus}.
  	      "recall" : {
  		   // "tag"   : "Chorus", "type"  : "comment",
  		   "tag"   : "", "type"  : "",
  		   // "quote" : false,
  		   "quote" : false,
  	      },
  	  },
      }
  }
  // End of config.

=cut

use File::Spec;
use JSON::PP ();

sub hmerge($$$);
sub clone($);

my $default_config;

sub config_defaults {

    # We cannot read DATA more than once, so cache it.
    return $default_config if $default_config;

    if ( $App::Packager::PACKAGED ) {
	my $defs = App::Packager::GetResourcePath() .
	  "/config/chordpro.json";
	open( my $fd, "<:raw", $defs )
	  or die("$defs: $!\n");
	local $/;
	return $default_config = <$fd>;
    }

    # To avoid duplication of data, get the defaults from the POD section.

    my @lines;
    my $copy;
    my $pfx;
    seek(DATA,0,0);
    binmode( DATA, ':raw' );
    while ( <DATA> ) {
	if ( !$copy && m;^(\s+)// Configuration; ) {
	    $pfx = length($1);
	    $copy = 1;
	}
	if ( $copy ) {
	    s/[\r\n]+$//;
	    $_ = ( " " x $pfx ) . $_ if $_ =~ /^\t/;
	    push( @lines, /\W/ ? substr( $_, $pfx ) : "" );
	    last if $_ =~ m;^(\s+)// End of config\.;;
	}
    }
    close(DATA);
    return $default_config = join( "\n", @lines ) . "\n";
}

sub configurator {
    my ( $options ) = @_;

    my $pp = JSON::PP->new->relaxed;

    # Load defaults.
    warn("Config: <builtin>\n") if $options && $options->{verbose};
    my $cfg = $pp->decode( config_defaults() );

    # Only tests call configurator without options arg.
    unless ( $options ) {
	# Finish minimal config.
	process_config( $cfg, "<builtin>", $options );
	return $cfg;
    }

    # If there are includes, add them.
    if ( exists $cfg->{include} ) {
	foreach my $c ( @{ delete $cfg->{include} } ) {
	    # Check for resource names.
	    if ( $c !~ m;[/.]; ) {
		$c = ::rsc_or_file($c);
	    }
	    else {
		die("$c: Not a resource name\n");
	    }
	    $cfg = add_config( $cfg, $options, $c, $pp );
	}
    }

    # Add some extra entries to prevent warnings.
    for ( qw(title subtitle footer) ) {
	next if exists($cfg->{pdf}->{formats}->{first}->{$_});
	$cfg->{pdf}->{formats}->{first}->{$_} = "";
    }
    for my $ff ( qw(chord
		    diagram diagram_capo
		    comment comment_box comment_italic
		    tab text toc
		    empty footer grid grid_margin subtitle title) ) {
	for ( qw(name file size color background) ) {
	    $cfg->{pdf}->{fonts}->{$ff}->{$_} //= undef;
	}
    }

    my $backend_configurator =
      UNIVERSAL::can( $options->{backend}, "configurator" );

    # Apply config files

    my $add_config = sub {
	$cfg = add_config( $cfg, $options, shift, $pp );
    };
    my $add_legacy = sub {
	# Legacy parser may need a ::config...
	$::config = $cfg;
	$cfg = add_legacy( $cfg, $options, shift, $pp );
    };

    foreach my $config ( qw( sysconfig legacyconfig userconfig config ) ) {
	next if $options->{"no$config"};
	if ( ref($options->{$config}) eq 'ARRAY' ) {
	    $add_config->($_) foreach @{ $options->{$config} };
	}
	elsif ( $config eq "legacyconfig" ) {
	    $add_legacy->( $options->{$config} );
	}
	else {
	    warn("Adding config for $config\n") if $options->{verbose};
	    $add_config->( $options->{$config} );
	}
    }

    # Handle defines from the command line.
    my $ccfg = {};
    while ( my ($k, $v) = each( %{ $options->{define} } ) ) {
	my @k = split( /[:.]/, $k );
	my $c = \$ccfg;
	foreach ( @k ) {
	    $c = \($$c->{$_});
	}
	$$c = $v;
    }
    $cfg = hmerge( $cfg, $ccfg, "" );

    if ( $cfg->{settings}->{transcode} ) {
	my $xc = $cfg->{settings}->{transcode};
	unless ( App::Music::ChordPro::Chords::Parser->get_parser($xc, 1) ) {
	    die("No transcoder for ", $xc, "\n");
	}
    }

    # Sanitize added extra entries.
    for ( qw(title subtitle footer) ) {
	delete($cfg->{pdf}->{formats}->{first}->{$_})
	  if ($cfg->{pdf}->{formats}->{first}->{$_} // 1) eq "";
	for my $class ( qw(title first default) ) {
	    my $t = $cfg->{pdf}->{formats}->{$class}->{$_};
	    next unless $t;
	    die("Config error in pdf.formats.$class.$_: not an array\n")
	      unless ref($t) eq 'ARRAY';
	    die("Config error in pdf.formats.$class.$_: ",
		 scalar(@$t), " fields instead of 3\n")
	      unless @$t == 3;
	}
    }

    if ( $cfg->{pdf}->{fontdir} ) {
	my @a;
	if ( ref($cfg->{pdf}->{fontdir}) eq 'ARRAY' ) {
	    @a = @{ $cfg->{pdf}->{fontdir} };
	}
	else {
	    @a = ( $cfg->{pdf}->{fontdir} );
	}
	$cfg->{pdf}->{fontdir} = [];
	my $split = $^O =~ /^MS*/ ? qr(;) : qr(:);
	foreach ( @a ) {
	    push( @{ $cfg->{pdf}->{fontdir} }, split( $split, $_ ) );
	}
    }
    else {
	$cfg->{pdf}->{fontdir} = [];
    }

    my @allfonts = keys(%{$cfg->{pdf}->{fonts}});
    for my $ff ( @allfonts ) {
	unless ( $cfg->{pdf}->{fonts}->{$ff}->{name}
		 || $cfg->{pdf}->{fonts}->{$ff}->{file} ) {
	    delete( $cfg->{pdf}->{fonts}->{$ff} );
	    next;
	}
	for ( qw(name file size color background) ) {
	    delete( $cfg->{pdf}->{fonts}->{$ff}->{$_} )
	      unless defined( $cfg->{pdf}->{fonts}->{$ff}->{$_} );
	}
    }

    if ( defined $options->{diagrams} ) {
	warn( "Invalid value for diagrams: ",
	      $options->{diagrams}, "\n" )
	  unless $options->{diagrams} =~ /^(all|none|user)$/i;
	$cfg->{diagrams}->{show} = lc $options->{'diagrams'};
    }
    elsif ( defined $options->{'user-chord-grids'} ) {
	$cfg->{diagrams}->{show} =
	  $options->{'user-chord-grids'} ? "user" : 0;
    }
    elsif ( defined $options->{'chord-grids'} ) {
	$cfg->{diagrams}->{show} =
	  $options->{'chord-grids'} ? "all" : 0;
    }
    if ( defined $options->{'chord-grids-sorted'} ) {
	$cfg->{diagrams}->{sorted} = $options->{'chord-grids-sorted'};
    }
    if ( $options->{'lyrics-only'} ) {
	$cfg->{settings}->{'lyrics-only'} = $options->{'lyrics-only'};
    }
    if ( $options->{transcode} ) {
	$cfg->{settings}->{transcode} = $options->{transcode};
    }
    if ( $options->{decapo} ) {
	$cfg->{settings}->{decapo} = $options->{decapo};
    }
    return $cfg if $options->{'cfg-print'};

    # Backend specific configs.
    $backend_configurator->( $cfg, $options ) if $backend_configurator;

    # For convenience...
    bless( $cfg, __PACKAGE__ );;

    # Locking the hash is mainly for development.
    if ( $] >= 5.018000 ) {
	require Hash::Util;
	Hash::Util::lock_hash_recurse($cfg);
    }

    return $cfg;
}

sub add_config {
    my ( $cfg, $options, $file, $pp ) = @_;
    Carp::confess("FATAL: Insufficient config") unless @_ == 4;
    Carp::confess("FATAL: Undefined config") unless defined $file;
    warn("Config: $file\n") if $options->{verbose};

    if ( open( my $fd, "<:raw", $file ) ) {
	my $new = $pp->decode( ::loadfile ($fd, { %$options, donotsplit => 1 } ) );

	# Handle obsolete keys.
	if ( exists $new->{pdf}->{diagramscolumn} ) {
	    $new->{pdf}->{diagrams}->{show} //= "right";
	    delete $new->{pdf}->{diagramscolumn};
	    warn("$file: pdf.diagramscolumn is obsolete, use pdf.diagrams.show instead\n");
	}
	if ( exists $new->{pdf}->{formats}->{default}->{'toc-title'} ) {
	    $new->{toc}->{title} //= $new->{pdf}->{formats}->{default}->{'toc-title'};
	    delete $new->{pdf}->{formats}->{default}->{'toc-title'};
	    warn("$file: pdf.formats.default.toc-title is obsolete, use toc.title instead\n");
	}

	# If there are includes, process these first.
	if ( exists $new->{include} ) {
	    my ( $vol, $dir, undef ) = File::Spec->splitpath($file);
	    foreach my $c ( @{ delete $new->{include} } ) {
		# Check for resource names.
		if ( $c !~ m;[/.]; ) {
		    $c = ::rsc_or_file($c);
		}
		elsif ( $dir ne ""
			&& !File::Spec->file_name_is_absolute($c) ) {
		    # Prepend dir of the caller, if needed.
		    $c = File::Spec->catpath( $vol, $dir, $c );
		}
		$cfg = add_config( $cfg, $options, $c, $pp );
	    }
	}

	# Process.
	process_config( $new, $file, $options );
	# Merge final.
	$cfg = hmerge( $cfg, $new, "" );
	close($fd);
    }
    else {
	### Should not happen -- it's been checked in app_setup.
	die("Cannot open $file [$!]\n");
    }
    return $cfg;
}

sub process_config {
    my ( $cfg, $file, $options ) = @_;

    warn("Process: $file\n") if $options && $options->{verbose};

    if ( $cfg->{tuning} ) {
	my $res =
	  App::Music::ChordPro::Chords::set_tuning( $cfg->{tuning},
						    $options );
	warn( "Invalid tuning in config: ", $res, "\n" ) if $res;
	$cfg->{tuning} = [];
    }

    if ( $cfg->{notes} ) {
	my $res =
	  App::Music::ChordPro::Chords::set_notes( $cfg->{notes},
						   $options );
	warn( "Invalid notes in config: ", $res, "\n" ) if $res;
	delete $cfg->{notes};
    }

    if ( $cfg->{chords} ) {
	my $c = $cfg->{chords};
	if ( @$c && $c->[0] eq "append" ) {
	    shift(@$c);
	}
	foreach ( @$c ) {
	    my $res =
	      App::Music::ChordPro::Chords::add_config_chord($_);
	    warn( "Invalid chord in config: ",
		  $_->{name}, ": ", $res, "\n" ) if $res;
	}
	if ( $options->{verbose} && $options->{verbose} > 1 ) {
	    warn( "Processed ", scalar(@$c), " chord entries\n");
	    warn( "Totals: ",
		  App::Music::ChordPro::Chords::chord_stats(), "\n" );
	}
	delete $cfg->{chords};
    }
}

sub add_legacy {
    my ( $cfg, $options, $file, $pp ) = @_;
    warn("Config: $file (legacy)\n") if $options->{verbose};

    $options->{_legacy} = 1;
    $::config = $cfg;

    require App::Music::ChordPro::Songbook;
    my $s = App::Music::ChordPro::Songbook->new;
    $s->parsefile( $file, $options );
    delete( $options->{_legacy} );

    my $song = $s->{songs}->[0];
    foreach ( keys( %{$song->{settings}} ) ) {
	if ( $_ eq "papersize" ) {
	    $cfg->{pdf}->{papersize} = $song->{settings}->{papersize};
	    next;
	}
	if ( $_ eq "titles" ) {
	    $cfg->{settings}->{titles} = $song->{settings}->{titles};
	    next;
	}
	if ( $_ eq "columns" ) {
	    $cfg->{settings}->{columns} = $song->{settings}->{columns};
	    next;
	}
	if ( $_ eq "diagrams" ) {
	    $cfg->{diagrams}->{show} = $song->{settings}->{diagrams};
	    next;
	}
	die("Cannot happen");
    }
    foreach ( @{$song->{body}} ) {
	next if $_->{type} eq "diagrams"; # added by parser
	next if $_->{type} eq "ignore"; # ignored
	unless ( $_->{type} eq "control" ) {
	    die("Cannot happen " . $_->{type} . " " . $_->{name});
	}
	my $name = $_->{name};
	my $value = $_->{value};
	unless ( $name =~ /^(text|chord|tab)-(font|size)$/ ) {
	    die("Cannot happen");
	}
	$name = $1;
	my $prop = $2;
	if ( $prop eq "font" ) {
	    if ( $value =~ /.+\.(?:ttf|otf)$/i ) {
		$prop = "file"
	    }
	    else {
		$prop = "name";
	    }
	}
	$cfg->{pdf}->{fonts}->{$name}->{$prop} = $value;
    }

    return $cfg;
}

sub config_final {
    my ( $options ) = @_;
    $options->{'cfg-print'} = 1;
    my $cfg = configurator($options);

    my $pp = JSON::PP->new->utf8->canonical->indent(4)->pretty;
    $pp->encode($cfg);
}

sub hmerge($$$) {

    # Merge hashes. Right takes precedence.
    # Based on Hash::Merge::Simple by Robert Krimen.

    my ( $left, $right, $path ) = @_;
    $path ||= "";

    my %res = %$left;

    for my $key ( keys(%$right) ) {

	warn("Config error: unknown item $path$key\n")
	  unless exists $res{$key}
	    || $path.$key =~ /^pdf\.section\./;

	if ( ref($right->{$key}) eq 'HASH'
	     and
	     ref($res{$key}) eq 'HASH' ) {

	    # Hashes. Recurse.
            $res{$key} = hmerge( $res{$key}, $right->{$key}, "$path$key." );
        }
	elsif ( ref($right->{$key}) eq 'ARRAY'
		and
		ref($res{$key}) eq 'ARRAY' ) {

	    # Arrays. Overwrite or append.
	    if ( @{$right->{$key}} ) {
		my @v = @{ $right->{$key} };
		if ( $v[0] eq "append" ) {
		    shift(@v);
		    # Append the rest.
		    push( @{ $res{$key} }, @v );
		}
		elsif ( $v[0] eq "prepend" ) {
		    shift(@v);
		    # Prepend the rest.
		    unshift( @{ $res{$key} }, @v );
		}
		else {
		    # Overwrite.
		    $res{$key} = $right->{$key};
		}
	    }
	    else {
		# Overwrite.
		$res{$key} = $right->{$key};
	    }
        }
	else {
	    # Overwrite.
	    $res{$key} = $right->{$key};
	}
    }

    return \%res;
}

sub clone($) {
    my ( $source ) = @_;

    return if not defined($source);

    my $ref_type = ref($source);

    # Non-reference values are copied as is.
    return $source unless $ref_type;

    # Ignore blessed objects unless it's me.
    my $class;
    if ( "$source" =~ /^\Q$ref_type\E\=(\w+)\(0x[0-9a-f]+\)$/ ) {
	$class = $ref_type;
	$ref_type = $1;
	return unless $class eq __PACKAGE__;
    }

    my $copy;
    if ( $ref_type eq 'HASH' ) {
	$copy = {};
	%$copy = map { !ref($_) ? $_ : clone($_) } %$source;
    }
    elsif ( $ref_type eq 'ARRAY' ) {
	$copy = [];
	@$copy = map { !ref($_) ? $_ : clone($_) } @$source;
    }
    elsif ( $ref_type eq 'REF' or $ref_type eq 'SCALAR' ) {
	$copy = \( my $var = "" );
	$$copy = clone($$source);
    }
    else {
	# Plain copy anything else.
	$copy = $source;
    }
    bless( $copy, $class ) if $class;
    return $copy;
}

unless ( caller ) {
    print( config_defaults() );
    exit;
}

1;

__DATA__
