#!/usr/bin/perl

# ChordPro -- perl version of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified By: Johan Vromans
# Last Modified On: Fri Jun  3 14:25:51 2016
# Update Count    : 231
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

################ Setup  ################

use Music::ChordPro;

# Process command line options, config files, and such.
our $config;
my $options;
$options = app_setup( "ChordPro", $Music::ChordPro::VERSION )
  unless $::__EMBEDDED__;

################ Presets ################

$options->{trace} = 1   if $options->{debug};
$options->{verbose} = 1 if $options->{trace};

################ Activate ################

main($options) unless $::__EMBEDDED__;

################ The Process ################

sub main {
    my ($options) = @_;

    # Establish backend.
    my $of = $options->{output};
    if ( $of ) {
	if ( $of =~ /\.pdf$/i ) {
	    $options->{generate} ||= "PDF";
	}
	elsif ( $of =~ /\.ly$/i ) {
	    $options->{generate} ||= "LilyPond";
	}
	elsif ( $of =~ /\.(tex|ltx)$/i ) {
	    $options->{generate} ||= "LaTeX";
	}
	elsif ( $of =~ /\.cho$/i ) {
	    $options->{generate} ||= "ChordPro";
	}
	elsif ( $of =~ /\.(crd|txt)$/i ) {
	    $options->{generate} ||= "Text";
	}
	elsif ( $of =~ /\.(debug)$/i ) {
	    $options->{generate} ||= "Debug";
	}
    }

    $options->{generate} ||= "PDF";
    my $pkg = "Music::ChordPro::Output::".$options->{generate};
    eval "require $pkg;";
    die("No backend for ", $options->{generate}, "\n$@") if $@;
    $options->{backend} = $pkg;

    # One configurator to bind them all.
    use Music::ChordPro::Config;
    $::config = Music::ChordPro::Config::configurator($options);

    # Parse the input(s).
    use Music::ChordPro::Songbook;
    my $s = Music::ChordPro::Songbook->new;
    $s->parsefile( $_, $options ) foreach @ARGV;

    warn(Dumper($s), "\n") if $options->{debug};

    # Generate the songbook.
    my $res = $pkg->generate_songbook( $s, $options );

    # Some backends write output themselves, others return an
    # array of lines to be written.
    if ( $res && @$res > 0 ) {
	if ( $of && $of ne "-" ) {
	    open( STDOUT, '>', $of );
	}
	binmode( STDOUT, ":utf8" );
	print( join( "\n", @$res ) );
	close(STDOUT);
    }
}

################ Options and Configuration ################

use Getopt::Long 2.13 qw( :config no_ignorecase );
use File::Spec;
use Carp;

# Package name.
my $my_package;
# Program name and version.
my ($my_name, $my_version);
my %configs;

sub app_setup {
    my ($appname, $appversion, %args) = @_;
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Package name.
    $my_package = $args{package};
    # Program name and version.
    if ( defined $appname ) {
	($my_name, $my_version) = ($appname, $appversion);
    }
    else {
	($my_name, $my_version) = qw( MyProg 0.01 );
    }

    # Config files.
    my $app_lc = lc($my_name);
    if ( -d "/etc" ) {		# some *ux
	$configs{sysconfig} =
	  File::Spec->catfile( "/", "etc", "$app_lc.json" );
    }

    if ( $ENV{HOME} && -d $ENV{HOME} ) {
	if ( -d File::Spec->catfile( $ENV{HOME}, ".config" ) ) {
	    $configs{userconfig} =
	      File::Spec->catfile( $ENV{HOME}, ".config", $app_lc, "$app_lc.json" );
	}
	else {
	    $configs{userconfig} =
	      File::Spec->catfile( $ENV{HOME}, ".$app_lc", "$app_lc.json" );
	}
    }

    if ( -s ".$app_lc.json" ) {
	$configs{config} = ".$app_lc.json";
    }
    else {
	$configs{config} = "$app_lc.json";
    }

    my $options =
      {
       verbose		=> 0,		# verbose processing
       encoding		=> "",		# input encoding, default UTF-8

       ### ADDITIONAL CLI OPTIONS ###

       'vertical-space' => 0,		# extra vertical space between lines
       'lyrics-only'	=> 0,		# suppress all chords

       ### NON-CLI OPTIONS ###

       'chords-column'	=> 0,		# chords in a separate column

       # Development options (not shown with -help).
       debug		=> 0,		# debugging
       trace		=> 0,		# trace (show process)

       # Service.
       _package		=> $my_package,
       _name		=> $my_name,
       _version		=> $my_version,
       _stdin		=> \*STDIN,
       _stdout		=> \*STDOUT,
       _stderr		=> \*STDERR,
       _argv		=> [ @ARGV ],
      };

    # Colled command line options in a hash, for they will be needed
    # later.
    my $clo = {};

    # Sorry, layout is a bit ugly...
    if ( !GetOptions
	 ($clo,

	  ### Options ###

          "output|o=s",			# Saves the output to FILE
	  "lyrics-only",		# Suppress all chords
	  "generate=s",
	  "backend-option|bo=s\%",
	  "encoding=s",

	  ### Standard Chordii Options ###

          "about|A",			# About Chordii...
          "chord-font|C=s",		# Sets chord font
          "chord-grid-size|s=i",	# Sets chord grid size [30]
          "chord-grids-sorted|S",	# Prints chord grids alphabetically
          "chord-size|c=i",		# Sets chord size [9]
          "dump-chords|D",		# Dumps chords definitions (PostScript)
          "dump-chords-text|d",		# Dumps chords definitions (Text)
          "even-pages-number-left|L",	# Even pages numbers on left
          "lyrics-only|l",		# Only prints lyrics
          "chord-grids|G!",		# En[dis]ables printing of chord grids
          "easy-chord-grids|g!",	# Do[esn't] print grids for builtin "easy" chords.
          "page-number-logical|n",	# Numbers logical pages, not physical
          "page-size|P=s",		# Specifies page size [letter, a4 (default)]
          "single-space|a!",		# Automatic single space lines without chords
          "start-page-number|p=i",	# Starting page number [1]
          "text-size|t=i",		# Sets text size [12]
          "text-font|T=s",		# Sets text font
          "toc|i",			# Generates a table of contents
          "transpose|x=i",		# Transposes by N semi-tones
          "version|V",			# Prints Chordii version and exits
          "vertical-space|w=i",		# Extra vertical space between lines
          "2-up|2",			# 2 pages per sheet
          "4-up|4",			# 4 pages per sheet

	  # Configuration handling.
	  'config=s@',
	  'noconfig',
	  'sysconfig=s',
	  'nosysconfig',
	  'userconfig=s',
	  'nouserconfig',

	  # Standard options.
	  'ident'		=> \$ident,
	  'help|h|?'		=> \$help,
	  'verbose|v',
	  'trace',
	  'debug',
	 ) )
    {
	# GNU convention: message to STDERR upon failure.
	app_usage(\*STDERR, 2);
    }
    # GNU convention: message to STDOUT upon request.
    app_usage(\*STDOUT, 0) if $help;
    app_ident(\*STDOUT, 0) if $clo->{version};
    app_ident(\*STDOUT) if $ident;
    app_about(\*STDOUT, 0) if $clo->{about};

    # If the user specified a config, it must exist.
    # Otherwise, set to a default.
    for my $config ( qw(sysconfig userconfig) ) {
	for ( $clo->{$config} ) {
	    if ( defined($_) ) {
		die("$_: $!\n") unless -r $_;
		next;
	    }
	    $_ = $configs{$config};
	    undef($_) unless -r $_;
	}
    }
    for my $config ( qw(config) ) {
	for ( $clo->{$config} ) {
	    if ( defined($_) ) {
		foreach ( @$_ ) {
		    die("$_: $!\n") unless -r $_;
		}
		next;
	    }
	    $_ = [ $configs{$config} ];
	    undef($_) unless -r $_->[0];
	}
    }
    # If no config was specified, and no default is available, force no.
    for my $config ( qw(sysconfig userconfig config) ) {
	$clo->{"no$config"} = 1 unless $clo->{$config};
    }

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;

    # Return result.
    $options;
}

sub app_ident {
    my ($fh, $exit) = @_;
    print {$fh} ("This is ",
		 $my_package
		 ? "$my_package [$my_name $my_version]"
		 : "$my_name version $my_version",
		 "\n");
    exit $exit if defined $exit;
}

sub app_about {
    my ($fh, $exit) = @_;
    app_ident($fh);
    print ${fh} <<EndOfAbout;

ChordPro: A lyrics and chords formatting program.

ChordPro will read a text file containing the lyrics of one or many
songs plus chord information. ChordPro will then generate a
photo-ready, professional looking, impress-your-friends sheet-music
suitable for printing on your nearest printer.

To learn more about ChordPro, look for the man page or do
"chordpro --help" for the list of options.

For more information, see http://www.chordpro.org .
EndOfAbout
    exit $exit if defined $exit;
}

sub app_usage {
    my ($fh, $exit) = @_;
    app_ident($fh);
    print ${fh} <<EndOfUsage;
Usage: $0 [ options ] [ file ... ]

Options:
    --about  -A                   About ChordPro...
    --encoding=ENC		  Encoding for input files (UTF-8)
    --lyrics-only  -l             Only prints lyrics
    --output=FILE  -o             Saves the output to FILE
    --config=JSON  --cfg          Config definitions (multiple)
    --start-page-number=N  -p     Starting page number [1]
    --toc --notoc -i              Generates/suppresses a table of contents
    --transpose=N  -x             Transposes by N semi-tones
    --version  -V                 Prints version and exits

Chordii compatibility.
Options marked with * are better specified in the pagedefs file.
Options marked with - are ignored.
    --chord-font=FONT  -C         *Sets chord font
    --chord-grid-size=N  -s       *Sets chord grid size [30]
    --chord-grids-sorted  -S      *Prints chord grids alphabetically
    --chord-size=N  -c            *Sets chord size [9]
    --dump-chords  -D             -Dumps chords definitions (PostScript)
    --dump-chords-text  -d        -Dumps chords definitions (Text)
    --even-pages-number-left  -L  *Even pages numbers on left
    --no-chord-grids  -G          *Disables printing of chord grids
    --no-easy-chord-grids  -g     -Doesn't print grids for builtin "easy" chords.
    --page-number-logical  -n     -Numbers logical pages, not physical
    --page-size=FMT  -P           *Specifies page size [letter, a4 (default)]
    --single-space  -a            *Automatic single space lines without chords
    --text-size=N  -t             *Sets text size [12]
    --text-font=FONT  -T          *Sets text font
    --vertical-space=N  -w        *Extra vertical space between lines
    --2-up  -2                    -2 pages per sheet
    --4-up  -4                    -4 pages per sheet

Configuration options:
    --config=CFG	Project specific config file ($configs{config})
    --noconfig		Don't use a project specific config file
    --userconfig=CFG	User specific config file ($configs{userconfig})
    --nouserconfig	Don't use a user specific config file
    --sysconfig=CFG	System specific config file ($configs{sysconfig})
    --nosysconfig	Don't use a system specific config file
Missing default configuration files are silently ignored.

Miscellaneous options:
    --help  -h		This message
    --ident		Show identification
    --verbose		Verbose information
EndOfUsage
    exit $exit if defined $exit;
}

1;
