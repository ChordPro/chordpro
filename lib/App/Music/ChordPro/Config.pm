#! perl

package main;

our $options;
our $config;

package App::Music::ChordPro::Config;

use feature ':5.10';		# for state
use strict;
use warnings;
use utf8;

use App::Packager;
use App::Music::ChordPro;
use App::Music::ChordPro::Utils;
use File::LoadLines;
use File::Spec;
use JSON::PP ();

=head1 NAME

App::Music::ChordPro::Config - Configurator.

=head1 DESCRIPTION

This module first establishes a well-defined (builtin) configuration.

Then it processes the config files specified by the envitronment and
adds the information to the global $config hash.

The configurations files are 'relaxed' JSON files. This means that
they may contain comments and trailing comma's.

This module can be run standalone and will print the default config.

=encoding utf8

=cut

sub hmerge($$;$);
sub clone($);

sub default_config();

sub configurator {
    my ( $opts ) = @_;
    my $pp = JSON::PP->new->relaxed;

    # Test programs call configurator without options.
    # Prepare a minimal config.
    unless ( $opts ) {
	my $cfg = $pp->decode( default_config() );
	$config = $cfg;
	$options = { verbose => 0 };
	process_config( $cfg, "<builtin>" );
	$cfg->{settings}->{lineinfo} = 0;
	return $cfg;
    }
    if ( keys(%$opts) ) {
	$options = { %{$options//{}}, %$opts };
	$options->{verbose} //= 0;
    }

    my @cfg;
    my $verbose = $options->{verbose};

    # Load defaults.
    warn("Reading: <builtin>\n") if $verbose > 1;
    my $cfg = $pp->decode( default_config() );

    # Default first.
    @cfg = prep_configs( $cfg, "<builtin>" );
    # Bubble default config to be the first.
    unshift( @cfg, pop(@cfg) ) if @cfg > 1;

    # Collect other config files.
    my $add_config = sub {
	my $fn = shift;
	$cfg = get_config( $fn );
	push( @cfg, prep_configs( $cfg, $fn ) );
    };
    my $add_legacy = sub {
	my $fn = shift;
	warn("Warning: Legacy config $fn ignored (####TODO####)\n");
	return;
	# Legacy parser may need a ::config...
	local $::config = $cfg;
	my $cfg = get_legacy( $fn );
	push( @cfg, prep_configs( $cfg, $fn ) );
    };

    foreach my $c ( qw( sysconfig legacyconfig userconfig config ) ) {
	next if $options->{"no$c"};
	if ( ref($options->{$c}) eq 'ARRAY' ) {
	    $add_config->($_) foreach @{ $options->{$c} };
	}
	elsif ( $c eq "legacyconfig" ) {
	    $add_legacy->( $options->{$c} );
	}
	else {
	    warn("Adding config for $c\n") if $verbose;
	    $add_config->( $options->{$c} );
	}
    }

    # Now we have a list of all config files. Weed out dups.
    for ( my $a = 0; $a < @cfg; $a++ ) {
	if ( $a && $cfg[$a]->{_src} eq $cfg[$a-1]->{_src} ) {
	    splice( @cfg, $a, 1 );
	    redo;
	}
	print STDERR ("Config[$a]: ", $cfg[$a]->{_src}, "\n" )
	  if $verbose;
    }

    $cfg = shift(@cfg);
    warn("Process: $cfg->{_src}\n") if $verbose > 1;

    # Add some extra entries to prevent warnings.
    for ( qw(title subtitle footer) ) {
	next if exists($cfg->{pdf}->{formats}->{first}->{$_});
	$cfg->{pdf}->{formats}->{first}->{$_} = "";
    }
    for my $ff ( qw(chord
		    diagram diagram_capo chordfingers
		    comment comment_box comment_italic
		    tab text toc annotation label
		    empty footer grid grid_margin subtitle title) ) {
	for ( qw(name file description size color background) ) {
	    $cfg->{pdf}->{fonts}->{$ff}->{$_} //= undef;
	}
    }

    my $backend_configurator =
      UNIVERSAL::can( $options->{backend}, "configurator" );

    # Apply config files
    foreach my $new ( @cfg ) {
	my $file = $new->{_src}; # for diagnostics
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

	# Process.
	local $::config = $cfg;
	process_config( $new, $file );
	# Merge final.
	$cfg = hmerge( $cfg, $new );
    }

    # Handle defines from the command line.
    my $ccfg = {};
    while ( my ($k, $v) = each( %{ $options->{define} } ) ) {
	my @k = split( /[:.]/, $k );
	my $c = \$ccfg;		# new
	my $o = $cfg;		# current
	my $lk = pop(@k);	# last key

	# Step through the keys.
	foreach ( @k ) {
	    $c = \($$c->{$_});
	    $o = $o->{$_};
	}

	# Final key. Merge array if so.
	if ( $lk =~ /^\d+$/ && ref($o) eq 'ARRAY' ) {
	    unless ( ref($$c) eq 'ARRAY' ) {
		# Only copy orig values the first time.
		$$c->[$_] = $o->[$_] for 0..scalar(@{$o})-1;
	    }
	    $$c->[$lk] = $v;
	}
	else {
	    $$c->{$lk} = $v;
	}
    }
    $cfg = hmerge( $cfg, $ccfg );

    if ( $cfg->{settings}->{transcode} //= $options->{transcode} ) {
	my $xc = $cfg->{settings}->{transcode};
	# Load the appropriate notes config, but retain the current parser.
	unless ( App::Music::ChordPro::Chords::Parser->have_parser($xc) ) {
	    my $file = getresource("notes/$xc.json");
	    my $new = hmerge( $cfg, get_config($file) );
	    local $::config = $new;
	    App::Music::ChordPro::Chords::Parser->new($new);
	}
	unless ( App::Music::ChordPro::Chords::Parser->have_parser($xc) ) {
	    die("No transcoder for ", $xc, "\n");
	}
	warn("Got transcoder for $xc\n") if $::options->{vebose};
	#warn("Parsers: ", ::dump(App::Music::ChordPro::Chords::Parser::parsers()));
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
	    push( @{ $cfg->{pdf}->{fontdir} },
		  map { expand_tilde($_) } split( $split, $_ ) );
	}
    }
    else {
	$cfg->{pdf}->{fontdir} = [];
    }

    my @allfonts = keys(%{$cfg->{pdf}->{fonts}});
    for my $ff ( @allfonts ) {
	unless ( $cfg->{pdf}->{fonts}->{$ff}->{name}
		 || $cfg->{pdf}->{fonts}->{$ff}->{description}
		 || $cfg->{pdf}->{fonts}->{$ff}->{file} ) {
	    delete( $cfg->{pdf}->{fonts}->{$ff} );
	    next;
	}
	for ( qw(name file description size color background) ) {
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
	# Already handled.
	# $cfg->{settings}->{transcode} = $options->{transcode};
    }
    if ( $options->{decapo} ) {
	$cfg->{settings}->{decapo} = $options->{decapo};
    }
    return $cfg if $options->{'cfg-print'};

    # Backend specific configs.
    $backend_configurator->($cfg) if $backend_configurator;

    # For convenience...
    bless( $cfg, __PACKAGE__ );;

    # Locking the hash is mainly for development.
    if ( $] >= 5.018000 ) {
	require Hash::Util;
	Hash::Util::lock_hash_recurse($cfg);
    }

    if ( $options->{verbose} > 1 ) {
	my $cp = App::Music::ChordPro::Chords::get_parser() // "";
	warn("Parsers:\n");
	while ( my ($k, $v) = each %{App::Music::ChordPro::Chords::Parser::parsers()} ) {
	    warn( "  $k",
		  $v eq $cp ? " (active)": "",
		  "\n");
	}
    }

    return $cfg;
}

# Get the decoded contents of a single config file.
sub get_config {
    my ( $file ) = @_;
    Carp::confess("FATAL: Insufficient config") unless @_ == 1;
    Carp::confess("FATAL: Undefined config") unless defined $file;
    my $verbose = $options->{verbose};
    warn("Reading: $file\n") if $verbose > 1;
    $file = expand_tilde($file);

    if ( open( my $fd, "<:raw", $file ) ) {
	my $pp = JSON::PP->new->relaxed;
	my $new = $pp->decode( loadlines( $fd, { split => 0 } ) );
	close($fd);
	return $new;
    }
    else {
	die("Cannot open config $file [$!]\n");
    }
}

# Check config for includes, and prepend them.
sub prep_configs {
    my ( $cfg, $src ) = @_;
    $cfg->{_src} = $src;

    my @res;

    # If there are includes, add them first.
    my ( $vol, $dir, undef ) = File::Spec->splitpath($cfg->{_src});
    foreach my $c ( @{ $cfg->{include} } ) {
	# Check for resource names.
	if ( $c !~ m;[/.]; ) {
	    $c = ::rsc_or_file($c);
	}
	elsif ( $dir ne ""
		&& !File::Spec->file_name_is_absolute($c) ) {
	    # Prepend dir of the caller, if needed.
	    $c = File::Spec->catpath( $vol, $dir, $c );
	}
	my $cfg = get_config($c);
	# Recurse.
	push( @res, prep_configs( $cfg, $c ) );
    }

    # Push this and return.
    push( @res, $cfg );
    return @res;
}

sub process_config {
    my ( $cfg, $file ) = @_;
    my $verbose = $options->{verbose};

    warn("Process: $file\n") if $verbose > 1;

    if ( $cfg->{tuning} ) {
	my $res =
	  App::Music::ChordPro::Chords::set_tuning( $cfg );
	warn( "Invalid tuning in config: ", $res, "\n" ) if $res;
	$cfg->{_tuning} = $cfg->{tuning};
	$cfg->{tuning} = [];
    }

    App::Music::ChordPro::Chords->reset_parser;
    App::Music::ChordPro::Chords::Parser->reset_parsers;
    local $::config = hmerge( $::config, $cfg );
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
	if ( $verbose > 1 ) {
	    warn( "Processed ", scalar(@$c), " chord entries\n");
	    warn( "Totals: ",
		  App::Music::ChordPro::Chords::chord_stats(), "\n" );
	}
	$cfg->{_chords} = delete $cfg->{chords};
    }
}

sub get_legacy {
    my ( $file ) = @_;
    my $verbose = $options->{verbose};
    warn("Config: $file (legacy)\n") if $verbose;

    my $cfg = { _src => $file };

    require App::Music::ChordPro::Songbook;
    my $s = App::Music::ChordPro::Songbook->new;
    $s->parse_legacy_file($file);

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
		$prop = "file";
		$cfg->{pdf}->{fonts}->{$name}->{name} = undef;
		$cfg->{pdf}->{fonts}->{$name}->{description} = undef;
	    }
	    else {
		$cfg->{pdf}->{fonts}->{$name}->{name} = undef;
		$cfg->{pdf}->{fonts}->{$name}->{file} = undef;
		$prop = "description";
	    }
	}
	$cfg->{pdf}->{fonts}->{$name}->{$prop} = $value;
    }

    return $cfg;
}

sub config_final {
    $options->{'cfg-print'} = 1;
    my $cfg = configurator($options);
    $cfg->{tuning} = delete $cfg->{_tuning};
    $cfg->{chords} = delete $cfg->{_chords};
    delete $cfg->{chords};
    delete $cfg->{_src};

    if ( $ENV{CHORDPRO_CFGPROPS} ) {
	cfg2props($cfg);
    }
    else {
	my $pp = JSON::PP->new->canonical->indent(4)->pretty;
	$pp->encode($cfg);
    }
}

sub config_default {
    if ( $ENV{CHORDPRO_CFGPROPS} ) {
	my $pp = JSON::PP->new->relaxed;
	my $cfg = $pp->decode( default_config() );
	cfg2props($cfg);
    }
    else {
	default_config();
    }
}

# Config in properties format.

sub cfg2props {
    my ( $o, $path ) = @_;
    $path //= "";
    my $ret = "";
    if ( !defined $o ) {
	$ret .= "$path: undef\n";
    }
    elsif ( UNIVERSAL::isa( $o, 'HASH' ) ) {
	$path .= "." unless $path eq "";
	for ( sort keys %$o ) {
	    $ret .= cfg2props( $o->{$_}, $path . $_  );
	}
    }
    elsif ( UNIVERSAL::isa( $o, 'ARRAY' ) ) {
	$path .= "." unless $path eq "";
	for ( my $i = 0; $i < @$o; $i++ ) {
	    $ret .= cfg2props( $o->[$i], $path . "$i" );
	}
    }
    elsif ( $o =~ /^\d+$/ ) {
	$ret .= "$path: $o\n";
    }
    else {
	$o =~ s/\\/\\\\/g;
	$o =~ s/"/\\"/g;
	$o =~ s/\n/\\n/;
	$o =~ s/\t/\\t/;
	$o =~ s/([^\x00-\xff])/sprintf("\\x{%x}", ord($1))/ge;
	$ret .= "$path: \"$o\"\n";
    }

    return $ret;
}

sub hmerge($$;$) {

    # Merge hashes. Right takes precedence.
    # Based on Hash::Merge::Simple by Robert Krimen.

    my ( $left, $right, $path ) = @_;
    $path ||= "";

    my %res = %$left;

    for my $key ( keys(%$right) ) {

	warn("Config error: unknown item $path$key\n")
	  unless exists $res{$key}
	    || $path eq "pdf.fontconfig."
	    || $key =~ /^_/;

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

# Get the raw contents of the builtin (default) config.
sub default_config() {
    return <<'End_Of_Config';
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
      // Add line info for backend diagnostics.
      "lineinfo" : true,
      // Titles flush: default center.
      "titles" : "center",
      // Columns, default one.
      "columns" : 1,
      // Suppress empty chord lines.
      // Overrides the -a (--single-space) command line options.
      "suppress-empty-chords" : true,
      // Suppress blank lyrics lines.
      "suppress-empty-lyrics" : true,
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
      // Chords parsing strategy.
      // Strict (only known) or relaxed (anything that looks sane).
      "chordnames": "strict",
      // Allow note names in [].
      "notenames" : false,
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
		 "sorttitle",
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

       // Movable means position independent (e.g. nashville).
       "movable" : false,
    },

    // User defined chords.
    // "base" defaults to 1.
    // Use 0 for an empty string, and -1 for a muted string.
    // "fingers" is optional.
    // "display" (optional) can be used to change the way the chord is displayed. 
    "chords" : [
      //  {
      //    "name"  : "Bb",
      //    "base"  : 1,
      //    "frets" : [ 1, 1, 3, 3, 3, 1 ],
      //    "fingers" : [ 1, 1, 2, 3, 4, 1 ],
      //    "display" : "B<sup>\u266d</sup>",
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
    "contents" : [
	{ "fields"   : [ "songindex" ],
	  "label"    : "Table of Contents",
	  "line"     : "%{title}",
	  "fold"     : false,
	  "omit"     : false,
	},
	{ "fields"   : [ "sorttitle", "artist" ],
	  "label"    : "Contents by Title",
	  "line"     : "%{title}%{artist| - %{}}",
	  "fold"     : false,
	  "omit"     : false,
	},
	{ "fields"   : [ "artist", "sorttitle" ],
	  "label"    : "Contents by Artist",
	  "line"     : "%{artist|%{} - }%{title}",
	  "fold"     : false,
	  "omit"     : true,
	},
    ],
    // Table of contents, old style.
    // This will be ignored when new style contents is present.
    "toc" : {
	// Title for ToC.
	"title" : "Table of Contents",
	"line" : "%{title}",
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
      // Align songs to even/odd pages.
      "pagealign-songs" : 1,

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

      // Split marker for syllables that are smaller than chord width.
      // split-marker is a 3-part array: 'start', 'repeat', and 'final'.
      // 'final' is always printed, last.
      // 'start' is printed if there is enough room.
      // 'repeat' is printed repeatedly to fill the rest.
      // If split-marker is a single string, this is 'start'.
      // All elements may be left empty strings.
      "split-marker" : [ "", "", "" ],

      // Font families and properties.
      // "fontconfig" maps members of font families to physical fonts.
      // Optionally, additional properties of the fonts can be specified.
      // Physical fonts can be the names of TrueType/OpenType fonts,
      // or names of built-in fonts (corefonts).
      // Relative filenames are looked up in the fontdir.
      // "fontdir" : [ "/usr/share/fonts/liberation", "/home/me/fonts" ],

      "fontdir" : null,
      "fontconfig" : {
	  // alternatives: regular r normal <empty>
	  // alternatives: bold b strong
	  // alternatives: italic i oblique o emphasis
	  // alternatives: bolditalic bi italicbold ib boldoblique bo obliquebold ob
	  "times" : {
	      ""            : "Times-Roman",
	      "bold"        : "Times-Bold",
	      "italic"      : "Times-Italic",
	      "bolditalic"  : "Times-BoldItalic",
	  },
	  "helvetica" : {
	      ""            : "Helvetica",
	      "bold"        : "Helvetica-Bold",
	      "oblique"     : "Helvetica-Oblique",
	      "boldoblique" : "Helvetica-BoldOblique",
	  },
	  "courier" : {
	      ""            : "Courier",
	      "bold"        : "Courier-Bold",
	      "italic"      : "Courier-Italic",
	      "bolditalic"  : "Courier-BoldItalic",
	  },
	  "dingbats" : {
	      ""            : "ZapfDingbats",
	  },
      },

      // "fonts" maps output elements to fonts as defined in "fontconfig".
      // The elements can have a background colour associated.
      // Colours are "#RRGGBB" or predefined names like "black", "white",
      // and lots of others.
      // NOTE: In the built-in config we use only "name" since that can
      // be overruled with user settings.

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
	  "chordfingers" : {
	      "name" : "ZapfDingbats",
	      "size" : 10
	  },
	  "comment" : {
	      "name" : "Helvetica",
	      "size" : 12,
	      "background" : "#E5E5E5"
	  },
	  "comment_italic" : {
	      "name" : "Helvetica-Oblique",
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

      // Element mappings that can be specified, but need not since
      // they default to other elements.
      // subtitle       --> text
      // comment        --> text
      // comment_italic --> chord
      // comment_box    --> chord
      // annotation     --> chord
      // toc            --> text
      // grid           --> chord
      // grid_margin    --> comment
      // footer         --> subtitle @ 60%
      // empty          --> text
      // diagram        --> comment
      // diagram_base   --> text (but at a small size)

      // Bookmarks (PDF outlines).
      // fields:   primary and (optional) secondary fields.
      // label:    outline label
      // line:     text of the outline element
      // collapse: initial display is collapsed
      // letter:   sublevel with first letters if more
      // fold:     group by primary (NYI)
      // omit:     ignore this
      "outlines" : [
	  { "fields"   : [ "sorttitle", "artist" ],
	    "label"    : "By Title",
	    "line"     : "%{title}%{artist| - %{}}",
	    "collapse" : false,
	    "letter"   : 5,
	    "fold"     : false,
	  },
	  { "fields"   : [ "artist", "sorttitle" ],
	    "label"    : "By Artist",
	    "line"     : "%{artist|%{} - }%{title}",
	    "collapse" : false,
	    "letter"   : 5,
	    "fold"     : false,
	  },
      ],

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
    },

    // Settings for HTML backend.
    "html" : {
	// Stylesheet links.
	"styles" : {
	    "display" : "chordpro.css",
	    "print"   : "chordpro_print.css",
	},
    },

    // Settings for A2Crd.
    "a2crd" : {
	// Treat leading lyrics lines as title/subtitle lines.
	"infer-titles" : true,
	// Tab stop width.
	"tabstop" : 8,
    },

}
// End of config.
End_Of_Config
}

unless ( caller ) {
    print( default_config() );
    exit;
}

1;

=head1 DEFAULT CONFIGURATION

The default configuration as built in. User and system
configs go on top of this one.

See L<https://www.chordpro.org/chordpro/chordpro-configuration/> for
extensive details and examples.


