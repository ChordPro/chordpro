#!/usr/bin/perl

# pChord -- perl version of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified By: Johan Vromans
# Last Modified On: Mon May 23 13:58:33 2016
# Update Count    : 184
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use Data::Dumper;

################ Setup  ################

# Process command line options, config files, and such.
my $options;
$options = app_setup("pchord", "0.10") unless $::__EMBEDDED__;

################ Presets ################

$options->{trace} = 1   if $options->{debug};
$options->{verbose} = 1 if $options->{trace};

################ Activate ################

main($options) unless $::__EMBEDDED__;

################ The Process ################

sub main {
    my ($options) = @_;
    print Dumper($options) if $options->{debug};
    binmode( STDOUT, ':utf8' );

    use Music::ChordPro::Songbook;

    my $s = Music::ChordPro::Songbook->new;

    $s->parsefile( $_, $options ) foreach @ARGV;
    #$s->transpose(-2);		# NYI

    warn(Dumper($s), "\n") if $options->{debug};

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

    $options->{generate} ||= "ChordPro";
    my $pkg = "Music::ChordPro::Output::".$options->{generate};
    eval "require $pkg;";
    die("No backend for ", $options->{generate}, "\n$@") if $@;

    my $res = $pkg->generate_songbook( $s, $options );

    if ( $res && @$res > 0 ) {
	if ( $of && $of ne "-" ) {
	    open( STDOUT, '>', $of );
	}
	binmode( STDOUT, ":utf8" );
	print( join( "\n", @$res ) );
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

    %configs =
      ( sysconfig  => File::Spec->catfile ("/", "etc", lc($my_name) . ".conf"),
	userconfig => File::Spec->catfile($ENV{HOME}, ".".lc($my_name), "conf"),
	config     => "." . lc($my_name) .".conf",
#	config     => lc($my_name) .".conf",
      );

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

	  ### ADD OPTIONS HERE ###

	  "lyrics-only",		# Suppress all chords
	  "generate=s",
	  "backend-option|bo=s\%",
	  "encoding=s",
	  "pagedefs=s",

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
          "no-chord-grids|G",		# Disables printing of chord grids
          "no-easy-chord-grids|g",	# Doesn't print grids for builtin "easy" chords.
          "output|o=s",			# Saves the output to FILE
          "page-number-logical|n",	# Numbers logical pages, not physical
          "page-size|P=s",		# Specifies page size [letter, a4 (default)]
          "single-space|a",		# Automatic single space lines without chords
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
	  'config=s',
	  'noconfig',
	  'sysconfig=s',
	  'nosysconfig',
	  'userconfig=s',
	  'nouserconfig',
	  'define|D=s%' => sub { $clo->{$_[1]} = $_[2] },

	  # Standard options.
	  'ident'		=> \$ident,
	  'help|h|?'		=> \$help,
	  'verbose',
	  'trace',
	  'debug',
	 ) )
    {
	# GNU convention: message to STDERR upon failure.
	app_usage(\*STDERR, 2);
    }
    # GNU convention: message to STDOUT upon request.
    app_usage(\*STDOUT, 0) if $help;
    app_ident(\*STDOUT) if $ident;

    # If the user specified a config, it must exist.
    # Otherwise, set to a default.
    for my $config ( qw(sysconfig userconfig config) ) {
	for ( $clo->{$config} ) {
	    if ( defined($_) ) {
		croak("$_: $!\n") if ! -r $_;
		next;
	    }
	    $_ = $configs{$config};
	    undef($_) unless -r $_;
	}
	app_config($options, $clo, $config);
    }

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;

    $options;
}

sub app_ident {
    my ($fh) = @_;
    print {$fh} ("This is ",
		 $my_package
		 ? "$my_package [$my_name $my_version]"
		 : "$my_name version $my_version",
		 "\n");
}

sub app_usage {
    my ($fh, $exit) = @_;
    app_ident($fh);
    print ${fh} <<EndOfUsage;
Usage: $0 [ options ] [ file ... ]

Options:
    --about  -A                   About Chordii...
    --chord-font=FONT  -C         Sets chord font
    --chord-grid-size=N  -s       Sets chord grid size [30]
    --chord-grids-sorted  -S      Prints chord grids alphabetically
    --chord-size=N  -c            Sets chord size [9]
    --dump-chords  -D             Dumps chords definitions (PostScript)
    --dump-chords-text  -d        Dumps chords definitions (Text)
    --encoding=ENC		  Encoding for input files (UTF-8)
    --even-pages-number-left  -L  Even pages numbers on left
    --lyrics-only  -l             Only prints lyrics
    --no-chord-grids  -G          Disables printing of chord grids
    --no-easy-chord-grids  -g     Doesn't print grids for builtin "easy" chords.
    --output=FILE  -o             Saves the output to FILE
    --page-number-logical  -n     Numbers logical pages, not physical
    --page-size=FMT  -P           Specifies page size [letter, a4 (default)]
    --single-space  -a            Automatic single space lines without chords
    --start-page-number=N  -p     Starting page number [1]
    --text-size=N  -t             Sets text size [12]
    --text-font=FONT  -T          Sets text font
    --toc  -i                     Generates a table of contents
    --transpose=N  -x             Transposes by N semi-tones
    --version  -V                 Prints Chordii version and exits
    --vertical-space=N  -w        Extra vertical space between lines
    --2-up  -2                    2 pages per sheet
    --4-up  -4                    4 pages per sheet

Configuration options:
    --config=CFG	project specific config file ($configs{config})
    --noconfig		don't use a project specific config file
    --userconfig=CFG	user specific config file ($configs{userconfig})
    --nouserconfig	don't use a user specific config file
    --sysconfig=CFG	system specific config file ($configs{sysconfig})
    --nosysconfig	don't use a system specific config file
    --define key=value  define or override a configuration option
Missing default configuration files are silently ignored.

Miscellaneous options:
    --help  -h		this message
    --ident		show identification
    --verbose		verbose information
EndOfUsage
    exit $exit if defined $exit;
}

use Config::Tiny;

sub app_config {
    my ($options, $opts, $config) = @_;
    return if $opts->{"no$config"};
    my $cfg = $opts->{$config};
    return unless defined $cfg && -s $cfg;
    my $verbose = $opts->{verbose} || $opts->{trace} || $opts->{debug};
    warn("Loading $config: $cfg\n") if $verbose;

    my $c = Config::Tiny->read( $cfg, 'utf8' );

    # Process config data, filling $options ...

    foreach ( keys %$c ) {
	foreach ( keys %$_ ) {
	    s;^~/;$ENV{HOME}/;;
	}
    }

    my $store = sub {
	my ( $sect, $key, $opt ) = @_;
	eval {
	    $config->{$opt} = $c->{$sect}->{$key};
	};
    };

}

1;
