#! perl

use 5.010.1;

package App::Music::ChordPro;

use App::Packager;

use App::Music::ChordPro::Version;
use App::Music::ChordPro::Utils;
use App::Music::ChordPro::Chords;
use App::Music::ChordPro::Output::Common;

our $VERSION = $App::Music::ChordPro::Version::VERSION;

=head1 NAME

App::Music::ChordPro - A lyrics and chords formatting program

=head1 SYNOPSIS

  perl -MApp::Music::Chordpro -e run -- [ options ] [ file ... ]

When the associated B<chordpro> program has been installed correctly:

  chordpro [ options ] [ file ... ]

=head1 DESCRIPTION

B<chordpro> will read one or more text files containing the lyrics of
one or many songs plus chord information. B<chordpro> will then
generate a photo-ready, professional looking, impress-your-friends
sheet-music suitable for printing on your nearest printer.

Typical ChordPro input:

    {title: Swing Low Sweet Chariot}
    {subtitle: Traditional}

    {start_of_chorus}
    Swing [D]low, sweet [G]chari[D]ot,
    Comin’ for to carry me [A7]home.
    Swing [D7]low, sweet [G]chari[D]ot,
    Comin’ for to [A7]carry me [D]home.
    {end_of_chorus}

    # Verse
    I [D]looked over Jordan, and [G]what did I [D]see,
    Comin’ for to carry me [A7]home.
    A [D]band of angels [G]comin’ after [D]me,
    Comin’ for to [A7]carry me [D]home.

    {c: Chorus}

B<chordpro> is a rewrite of the Chordii program.

For more information about the ChordPro file format, see
L<https://www.chordpro.org>.

=cut

################ Common stuff ################

use strict;
use warnings;
use Carp;
use Text::ParseWords ();

################ The Process ################

package main;

our $options;
our $config;

package App::Music::ChordPro;

sub ::run {
    binmode(STDERR, ':utf8');
    binmode(STDOUT, ':utf8');
    $options = app_setup( "ChordPro", $VERSION );
    $options->{trace}   = 1 if $options->{debug};
    $options->{verbose} = 1 if $options->{trace};
    $options->{verbose} = 9 if $options->{debug};
    main();
}

sub main {
    my ($opts) = @_;
    $options = { %$options, %$opts } if $opts;
    warn("ChordPro invoked: @{$options->{_argv}}\n") if $options->{debug};
    chordpro();

}

sub chordpro {

    # Establish backend.
    my $of = $options->{output};

    if ( defined($of) && $of ne "" ) {
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
        elsif ( $of =~ /\.msp$/i ) {
            $options->{generate} ||= "ChordPro";
            $options->{'backend-option'}->{variant} = "msp";
        }
        elsif ( $of =~ /\.(crd|txt)$/i ) {
            $options->{generate} ||= "Text";
        }
        elsif ( $of =~ /\.html?$/i ) {
            $options->{generate} ||= "HTML";
        }
        elsif ( $of =~ /\.mma?$/i ) {
            $options->{generate} ||= "MMA";
        }
        elsif ( $of =~ /\.(md|markdown)$/i ) {
            $options->{generate} ||= "Markdown";
        }
        elsif ( $of =~ /\.(debug)$/i ) {
            $options->{generate} ||= "Debug";
        }
    }
    elsif ( -t STDOUT ) {
	# No output, and stdout is terminal.
	# Derive output name from input name.
	if ( @ARGV > 1 || ( $options->{'dump-chords'} && !@ARGV ) ) {
	    # No default if more than one input document.
	    die("Please use \"--output\" to specify the output file name\n");
	}
	my $f = $ARGV[0];
	$f =~ s/\.\w+$/.pdf/;
	$f .= ".pdf" if $f eq $ARGV[0];
	$options->{output} = $f;
	warn("Writing output to $f\n") if $options->{verbose};
    }
    else {
	# Write output to stdout.
	$options->{output} = "-";
    }

    $options->{generate} ||= "PDF";
    my $pkg = "App::Music::ChordPro::Output::".$options->{generate};
    eval "require $pkg;";
    die("No backend for ", $options->{generate}, "\n$@") if $@;
    $options->{backend} = $pkg;
    $pkg->version if $options->{verbose} && $pkg->can("version");

    # One configurator to bind them all.
    use App::Music::ChordPro::Config;
    $config = App::Music::ChordPro::Config::configurator({});

    # Parse the input(s).
    use App::Music::ChordPro::Songbook;
    my $s = App::Music::ChordPro::Songbook->new;
    my $res;

    # Shortcut a2crd conversion.
    if ( $options->{a2crd} ) {
	require App::Music::ChordPro::A2Crd;
	$res = App::Music::ChordPro::A2Crd::a2crd();
	push( @$res, '' );
	goto WRITE_OUTPUT;
    }

    # Check for metadata in filelist. Actually, this works on the
    # command line as well, but don't tell anybody.
    foreach my $file ( @ARGV ) {
	my $opts;
	if ( $file =~ /(^|\s)--(?:meta|config)\b/ ) {
	    # Break into words.
	    my @w = Text::ParseWords::shellwords($file);
	    my %meta;
	    my @cfg;
	    die("Error in filelist: $file\n")
	      unless Getopt::Long::GetOptionsFromArray
	      ( \@w, 'config=s@' => \@cfg, 'meta=s%' => \%meta )
	      && @w == 1;
	    $file = $w[0];
	    $opts = { meta => { map { $_, [ $meta{$_} ] } keys %meta } };
	    if ( @cfg ) {
		$opts->{meta}->{__config} = \@cfg;
	    }
	}
	$s->parse_file( $file, $opts );
    }

    if ( $options->{'dump-chords'} ) {
	my $d = App::Music::ChordPro::Song->new;
	$d->{title} = "ChordPro $VERSION Built-in Chords";
	$d->{subtitle} = [ "https://www.chordpro.org" ];
	my @body;
	my @chords;

	my $prev = "";
	foreach my $c ( @{ App::Music::ChordPro::Chords::chordnames() } ) {
	    next if $c =~ /^n\.?c\.?$/i;
	    if ( $c =~ /^(.[b#]?)/ and $1 ne $prev )  {
		$prev = $1;
		push( @body, { type => "diagrams",
			       context => "",
			       origin => "__CLI__",
			       chords => [ @chords ]
			     } ) if @chords;
		@chords = ();
	    }
	    push( @chords, $c );
	    $d->{chordsinfo}->{$c} = App::Music::ChordPro::Chords::_known_chord($c);
	}

	push( @body, { type => "diagrams",
		       context => "",
		       origin => "__CLI__",
		       chords => [ @chords ]
		     } ) if @chords;

	$d->{body} = \@body;
	if ( @{ $s->{songs} } == 1
	     && !exists $s->{songs}->[0]->{body} ) {
	    $s->{songs} = [ $d ];
	}
	else {
	    push( @{ $s->{songs} }, $d );
	}
    }

    # Try interpolations.
    if ( $of ) {
	my $f = fmt_subst( $s->{songs}->[0], $of );
	if ( $f ne $of ) {
	    # Replace most non-alpha by underscore (but keep the extension).
	    $f =~ s;(?!\.\w+$)[^\w/-];_;g;
	    warn("Writing output to $f\n") if $options->{verbose};
	    $options->{output} = $f;
	}
    }

    # Call backend to produce output.
    $res = $pkg->generate_songbook($s);
    return $res if $options->{output} eq '*';

  WRITE_OUTPUT:
    # Some backends write output themselves, others return an
    # array of lines to be written.
    if ( $res && @$res > 0 ) {
        if ( $of && $of ne "-" ) {
            open( my $fd, '>', $of );
	    binmode( $fd, ":utf8" );
	    print { $fd } ( join( "\n", @$res ) );
	    close($fd);
        }
	else {
	    binmode( STDOUT, ":utf8" );
	    print( join( "\n", @$res ) );
	}
	# Don't close STDOUT!
    }
}

sub ::dump {
    use Data::Dumper qw();
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deparse   = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Trailingcomma = 1;
    local $Data::Dumper::Useperl = 1;
    local $Data::Dumper::Useqq     = 0; # I want unicode visible

    my $s = Data::Dumper::Dumper @_;
    defined wantarray or warn $s;
    return $s;
}

################ Options and Configuration ################

=head1 COMMAND LINE OPTIONS

=over 4

=item B<--about> (short: B<-A>)

Prints version information about the ChordPro program. No other
processing will be done.

=item B<--back-matter=>I<FILE>

Appends the contents of the named PDF document to the output. This can
be used to produce documents with back matter pages.

=item B<--config=>I<JSON> (shorter: B<--cfg>)

A JSON file that defines the behaviour of the program and the layout
of the output. See L<App::Music::ChordPro::Config> for details.

This option may be specified more than once. Each additional config
file overrides the corresponding definitions that are currently
active.

=item B<--cover=>I<FILE>

See B<--front-matter>.

=item B<--csv>

When generating PDF output, also write a CSV file with titles and page
numbers. Some tools, e.g., MobileSheets, can use the CSV to process
the PDF as a collection of independent songs.

The CSV has the same name  as the PDF, with extension C<.pdf> replaced
by C<.csv>.

=item B<--decapo>

Eliminate capo settings by transposing the song.

=item B<--diagrams=>I<WHICH>

Prints diagrams of chords used in a song.

I<WHICH> can be C<all> to print all chords used, C<user> to only print
the user-defined chords, and C<none> to suppress printing of chord
diagrams.

=item B<--encoding=>I<ENC>

Specify the encoding for input files. Default is UTF-8.
ISO-8859.1 (Latin-1) encoding is automatically sensed.

=item B<--filelist=>I<FILE>

Read the names of the files to be processed from the named file.

This option may be specified multiple times.

Song file names listed on the command line are processed I<after> the
files from the filelist arguments.

=item B<--front-matter=>I<FILE> B<--cover=>I<FILE>

Prepends the contents of the named PDF document to the output. This can
be used to produce documents with front matter (cover) pages.

=item B<--lyrics-only> (short: B<-l>)

Only prints lyrics. All chords are suppressed.

Useful to make prints for singers and other musicians that do not
require chords.

=item B<--no-csv>

Suppresses generating the CSV file. See B<--toc>.

=item B<--no-strict>

Enables liberal interpretation of the input with regard to the
ChordPro standard. Most notably, unknown directives will not
not flagged as warnings but silently ignored.

This makes it more convenient to process ChordPro files have custom
directives.

=item B<--no-toc>

Suppresses the table of contents. See B<--toc>.

=item B<--output=>I<FILE> (short: B<-o>)

Designates the name of the output file where the results are written
to.

The filename extension determines the type of the output. It should
correspond to one of the backends that are currently supported:

=over 6

=item pdf

Portable document format (PDF).

=item txt

A textual representation of the input, mostly for visual inspection.

=item cho

A functional equivalent version of the ChordPro input.

=back

=item B<--start-page-number=>I<N> (short: B<-p>)

Sets the starting page number for the output.

=item B<--strict>

Requires the input to be strictly compliant to the ChordPro standard.

This is enabled by default. See also B<--nostrict>.

=item B<--toc> (short: B<-i>)

Includes a table of contents.

By default a table of contents is included in the PDF output when
it contains more than one song.

=item B<--transpose=>I<N> (short: -x)

Transposes all songs by I<N> semi-tones. Note that I<N> may be
specified as B<+>I<N> to transpose upward, using sharps, or as
B<->I<N> to transpose downward, using flats.

=item B<--version> (short: B<-V>)

Prints the program version and exits.

=back

=head2 Chordii compatibility options

The following Chordii command line options are recognized. Note that
not all of them actually do something.

Options marked with * are better specified in the config file.

B<Note:> Chordii used the term _grid_ for chord diagrams. It
should not be confused with ChordPro grids.

=over 4

=item B<--text-font=>I<FONT> (short: B<-T>) *

Sets the font used to print lyrics and comments.

I<FONT> can be either a full path name to a TrueType font file, or the
name of one of the standard fonts. See section L</FONTS> for more
details.

=item B<--text-size=>I<N> (short: B<-t>) *

Sets the font size for lyrics and comments.

=item B<--chord-font=>I<FONT> (short: B<-C>) *

Sets the font used to print the chord names.

I<FONT> can be either a full path name to a TrueType font file, or the
name of one of the standard fonts. See section L</FONTS> for more
details.

=item B<--chord-size=>I<N> (short: B<-c>) *

Sets the font size for the chord names.

=item B<--chord-grid-size=>I<N> (short: B<-s>) *

Sets the total width of a chord diagram.

=item B<--chord-grids>

Prints chord diagrams of all chords used in a song.

=item B<--no-chord-grids> (short: B<-G>) *

Disables printing of chord diagrams of the chords used in a song.

=item B<--easy-chord-grids>

Not supported.

=item B<--no-easy-chord-grids> (short: B<-g>)

Not supported.

=item B<--chord-grids-sorted> (short: B<-S>) *

Prints chord diagrams of the chords used in a song, ordered by key and
type.

=item B<--no-chord-grids-sorted> *

Prints chord diagrams in the order they appear in the song.

=item B<--user-chord-grids> *

Prints chord diagrams of all user defined chords used in a song.

=item B<--even-pages-number-left> (short B<-L>)

Prints even/odd pages with pages numbers left on even pages.

=item B<--odd-pages-number-left>

Prints even/odd pages with pages numbers left on odd pages.

=item B<--page-size=>I<FMT> (short: B<-P>) *

Specifies the page size for the PDF output, e.g. C<a4> (default), C<letter>.

=item B<--single-space> (short B<-a>)) *

When a lyrics line has no chords associated, suppresses the vertical
space normally occupied by the chords.

=item B<--vertical-space=>I<N> (short: B<-w>) *

Adds some extra vertical space between the lines.

=item B<--2-up> (short: B<-2>)

Not supported.

=item B<--4-up> (short: B<-4>)

Not supported.

=item B<--page-number-logical> (short: B<-n>)

Not supported.

=item B<--dump-chords> (short: B<-D>)

Dumps a list of built-in chords in a form dependent of the backend used.
The PDF backend will produce neat pages of chord diagrams.
The ChordPro backend will produce a list of C<define> directives.

=item B<--dump-chords-text> (short: B<-d>)

Dumps a list of built-in chords in the form of C<define> directives,
and exits.

=back

=head2 Configuration options

See L<App::Music::ChordPro::Config> for details about the configuration
files.

Note that missing default configuration files are silently ignored.
Also, B<chordpro> will never create nor write configuration files.

=over

=item B<--nosongconfig>

Don't use song specific config files, even if they exist.

=item B<--sysconfig=>I<CFG>

Designates a system specific config file.

The default system config file depends on the operating system and user
environment. A common value is C</etc/chordpro.json> on Linux systems.

This is the place where the system manager can put settings like the
paper size, assuming that all printers use the same size.

=item B<--nosysconfig>

Don't use the system specific config file, even if it exists.

=item B<--userconfig=>I<CFG>

Designates the config file for the user.

The default user config file depends on the operating system and user
environment. Common values are C<$HOME/.config/chordpro/chordpro.json>
and C<$HOME/.chordpro/chordpro.json>, where C<$HOME> indicates the
user home directory.

Here you can put settings for your preferred fonts and other layout
parameters that you want to apply to all B<chordpro> runs.

=item B<--nouserconfig>

Don't use the user specific config file, even if it exists.

=item B<--config=>I<CFG> (shorter: B<--cfg>)

Designates the config file specific for this run.

Default is a file named C<chordpro.json> in the current directory.

Here you can put settings that apply to the files in this
directory only.

You can specify multiple config files. The settings are accumulated.

=item B<--noconfig>

Don't use the specific config file, even if it exists.

=item B<--define=>I<item>

Sets a configuration item. I<item> must be in the format of
colon-separated configuration keys, an equal sign, and the value. For
example, the equivalent of B<--diagrams=none> is
B<--define=diagrams:show=0>.

B<--define> may be used multiple times to set multiple items.

=item B<--no-default-configs> (short: B<-X>)

Do not use any config files except the ones mentioned explicitly on
the command line.

This guarantees that the program is running with the default
configuration.

=item B<--print-default-config>

Prints the default configuration to standard output, and exits.

The default configuration is commented to explain its contents.

=item B<--print-final-config>

Prints the final configuration (after processing all system, user and
other config files)  to standard output, and exits.

The final configuration is not commented. Sorry.

=back

=head2 Miscellaneous options

=over

=item B<--help> (short: -h)

Prints a help message. No other output is produced.

=item B<--manual>

Prints the manual page. No other output is produced.

=item B<--ident>

Shows the program name and version.

=item B<--verbose>

Provides more verbose information of what is going on.

=back

=cut

use Getopt::Long 2.13 qw( :config no_ignorecase );
use File::Spec;
use File::LoadLines;

# Package name.
my $my_package;
# Program name and version.
my ($my_name, $my_version);
my %configs;

sub app_setup {
    my ($appname, $appversion, %args) = @_;
    my $help = 0;               # handled locally
    my $manual = 0;             # handled locally
    my $ident = 0;              # handled locally
    my $about = 0;              # handled locally
    my $version = 0;            # handled locally
    my $defcfg = 0;		# handled locally
    my $fincfg = 0;		# handled locally
    my $deltacfg = 0;		# handled locally
    my $dump_chords = 0;	# handled locally

    # Package name.
    $my_package = $args{package};
    # Program name and version.
    if ( defined $appname ) {
        ($my_name, $my_version) = ($appname, $appversion);
    }
    else {
        ($my_name, $my_version) = qw( MyProg 0.01 );
    }

    my $app_lc = lc($my_name);
    if ( $app_lc eq "a2crd" ) {
	$app_lc = "chordpro";
	unshift( @ARGV, "--a2crd" );
    }

    # Config files.
    if ( -d "/etc" ) {          # some *ux
        $configs{sysconfig} =
          File::Spec->catfile( "/", "etc", "$app_lc.json" );
    }

    if ( $ENV{XDG_CONFIG_HOME} && -d $ENV{XDG_CONFIG_HOME} ) {
	$configs{userconfig} =
	  File::Spec->catfile( $ENV{XDG_CONFIG_HOME}, $app_lc, "$app_lc.json" );
	$ENV{CHORDPRO_LIB} ||= File::Spec->catfile( $ENV{XDG_CONFIG_HOME}, $app_lc);
    }
    elsif ( $ENV{HOME} && -d $ENV{HOME} ) {
	my $dir = File::Spec->catfile( $ENV{HOME}, ".config" );
        if ( -d $dir ) {
            $configs{userconfig} =
              File::Spec->catfile( $dir, $app_lc, "$app_lc.json" );
	    $ENV{CHORDPRO_LIB} ||= File::Spec->catfile( $dir, $app_lc );
        }
        else {
	    $dir = File::Spec->catfile( $ENV{HOME}, ".$app_lc" );
            $configs{userconfig} =
              File::Spec->catfile( $dir, "$app_lc.json" );
	    $ENV{CHORDPRO_LIB} ||= $dir;
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
       verbose          => 0,           # verbose processing
       encoding         => "",          # input encoding, default UTF-8

       ### ADDITIONAL CLI OPTIONS ###

       'vertical-space' => 0,           # extra vertical space between lines

       ### NON-CLI OPTIONS ###

       'chords-column'  => 0,           # chords in a separate column

       # Development options (not shown with -help).
       debug            => 0,           # debugging
       trace            => 0,           # trace (show process)

       # Service.
       _package         => $my_package,
       _name            => $my_name,
       _version         => $my_version,
       _stdin           => \*STDIN,
       _stdout          => \*STDOUT,
       _stderr          => \*STDERR,
       _argv            => [ @ARGV ],
      };

    # Colled command line options in a hash, for they will be needed
    # later.
    my $clo = {};

    # When running in reference mode, we carefully defeat everything
    # the user could change to the built-in default config.
    my $reference = 0;

    # Sorry, layout is a bit ugly...
    my $ok =
      GetOptions
         ($clo,

          ### Options ###

	  "a2crd!",			# perform ascii to cho
	  "crd",			# input is ascii, not cho
          "output|o=s",                 # Saves the output to FILE
          "generate=s",
          "backend-option|bo=s\%",
	  "diagrams=s",			# Prints chord diagrams
          "encoding=s",
	  "csv!",			# Generates contents CSV
	  "front-matter|cover=s",	# Front matter page(s)
	  "back-matter=s",		# Back matter page(s)
	  "filelist=s@",		# List of input files
	  "meta=s\%",			# Command line meta data
	  "decapo",			# remove capo
	  "fragment|F",			# partial (incomplete) song
	  "strict!",			# strict conformance

          ### Standard Chordii Options ###

          "about|A" => \$about,         # About...
          "chord-font|C=s",             # Sets chord font
          "chord-grid-size|s=f",        # Sets chord diagram size [30]
          "chord-grids-sorted|S!",      # Prints chord diagrams ordered
          "chord-size|c=i",             # Sets chord size [9]
          "dump-chords|D",              # Dumps chords definitions (PostScript)
          "dump-chords-text|d" => \$dump_chords,  # Dumps chords definitions (Text)
          "dump-chords-json" => sub { $dump_chords = 2},  # Dumps instrument defs (json).
          "even-pages-number-left|L",   # Even pages numbers on left
          "odd-pages-number-left",      # Odd pages numbers on left
          "lyrics-only|l",              # Only prints lyrics
          "G" => sub { $clo->{'chord-grids'} = 0 },
          "chord-grids!",               # En[dis]ables printing of chord diagrams
          "easy-chord-grids|g!",        # Do[esn't] print diagrams for built-in "easy" chords. Ignored.
          "page-number-logical|n",      # Numbers logical pages, not physical
          "page-size|P=s",              # Specifies page size [letter, a4 (default)]
          "single-space|a!",            # Automatic single space lines without chords
          "start-page-number|p=i",      # Starting page number [1]
          "text-size|t=i",              # Sets text size [12]
          "text-font|T=s",              # Sets text font
          "i" => sub { $clo->{toc} = 1 },
          "toc!",                       # Generates a table of contents
          "transpose|x=i",              # Transposes by N semi-tones
          "transcode|xc=s",             # Transcodes to another notation
          "user-chord-grids!",          # Do[esn't] print diagrams for user defined chords.
          "version|V" => \$version,     # Prints version and exits
          "vertical-space|w=f",         # Extra vertical space between lines
          "2-up|2",                     # 2 pages per sheet
          "4-up|4",                     # 4 pages per sheet

          ### Configuration handling ###

          'config|cfg=s@',
          'noconfig|no-config',
          'sysconfig=s',
          'nosysconfig|no-sysconfig',
          'nolegacyconfig|no-legacyconfig',	# legacy
          'userconfig=s',
          'nosongconfig|no-songconfig',
          'nouserconfig|no-userconfig',
	  'nodefaultconfigs|no-default-configs|X',
	  'define=s%',
	  'print-default-config' => \$defcfg,
	  'print-final-config'   => \$fincfg,
	  'print-delta-config'   => \$deltacfg,

	  # This aborts option scanning.
	  'reference|R'		 => sub { $reference++; die("!FINISH!"); },

          ### Standard options ###

          'ident'               => \$ident,
          'help|h|?'            => \$help,
          'help-config'         => sub { $manual = 2 },
          'manual'              => \$manual,
          'verbose|v+',
          'trace',
          'debug+',

         );

    # If --reference was encountered, retry with a very restricted set
    # of options.
    if ( $reference ) {
	@ARGV = @{ $options->{_argv} };
	warn("Running in reference mode.\n");
	$ok =
	  GetOptions
	  ($clo,

	  ### Options for reference run ###

	  "output|o=s",                 # Saves the output to FILE
	  "strict!",			# strict conformance
          "about|A" => \$about,         # About...
          "version|V" => \$version,     # Prints version and exits
	  'reference|R',

          ### Standard options ###

          'ident'               => \$ident,
          'help|h|?'            => \$help,
          'verbose|v+',
          'trace',
          'debug+',

	  );
	$clo->{nodefaultconfigs} = 1;
	$clo->{nosongconfig} = 1;
	$::options->{reference} = 1;
    }

    $clo->{trace} ||= $clo->{debug};
    $clo->{verbose} ||= $clo->{trace};

    unless ( $ok ) {
        # GNU convention: message to STDERR upon failure.
        app_usage(\*STDERR, 2);
    }

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
	my $f = $manual == 2 ? "pod/Config.pod" : "pod/ChordPro.pod";
        unshift( @_, -input => getresource($f) );
        &pod2usage;
    };

    # GNU convention: message to STDOUT upon request.
    app_ident(\*STDOUT) if $ident || $clo->{verbose} || $help || $manual;
    if ( $manual or $help ) {
        app_usage(\*STDOUT, 0) if $help;
        $pod2usage->(VERBOSE => 2) if $manual;
    }
    app_ident(\*STDOUT, 0) if $version;
    app_about(\*STDOUT, 0) if $about;

    # If the user specified a config, it must exist.
    # Otherwise, set to a default.
    for my $config ( qw(sysconfig userconfig) ) {
        for ( $clo->{$config} ) {
            if ( defined($_) ) {
                die("$_: $!\n") unless -r $_;
                next;
            }
	    # Use default.
	    next if $clo->{nodefaultconfigs};
	    next unless $configs{$config};
            $_ = $configs{$config};
            undef($_) unless -r $_;
        }
    }
    for my $config ( qw(config) ) {
        for ( $clo->{$config} ) {
            if ( defined($_) ) {
                foreach my $c ( @$_ ) {
		    # Check for resource names.
		    if ( $c !~ m;[/.]; ) {
			$c = ::rsc_or_file( $c, "config" );
		    }
                    die("$c: $!\n") unless -r $c;
                }
                next;
            }
	    # Use default.
	    next if $clo->{nodefaultconfigs};
	    next unless $configs{$config};
            $_ = [ $configs{$config} ];
            undef($_) unless -r -f $_->[0];
        }
    }
    # If no config was specified, and no default is available, force no.
    for my $config ( qw(sysconfig userconfig config ) ) {
        $clo->{"no$config"} = 1 unless $clo->{$config};
    }
    $clo->{nosongconfig} ||= $clo->{nodefaultconfigs};

    # Decode command line strings.
    # File names are dealt with elsewhere.
    for ( qw(transcode) ) {
	next unless defined $clo->{$_};
	$clo->{$_} = decode_utf8($clo->{$_});
    }
    ####TODO: Should decode all, and remove filename exception.
    for ( keys %{ $clo->{define} } ) {
	$clo->{define}->{$_} = decode_utf8($clo->{define}->{$_});
    }

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;
    $::options = $options;
    # warn(::dump($options), "\n") if $options->{debug};

    if ( $defcfg || $fincfg || $deltacfg ) {
	print App::Music::ChordPro::Config::config_default()
	  if $defcfg;
	print App::Music::ChordPro::Config::config_final($deltacfg)
	  if $fincfg || $deltacfg;
	exit 0;
    }

    if ( $dump_chords ) {
	$::config = App::Music::ChordPro::Config::configurator($options);
	require App::Music::ChordPro::Chords;
	App::Music::ChordPro::Chords::dump_chords($dump_chords);
	exit 0;
    }

    if ( $clo->{filelist} ) {
	my @files;
	foreach ( @{ $clo->{filelist} } ) {
	    my $list = loadlines( $_, $clo );
	    foreach ( @$list ) {
		next unless /\S/;
		next if /^#/;
		s/[\r\n]+$//;
		push( @files, encode_utf8($_) );
	    }
	}
	unshift( @ARGV, @files );
    }

    # At this point, there should be filename argument(s)
    # unless we're embedded or just dumping chords.
    app_usage(\*STDERR, 1)
      unless $::__EMBEDDED__ || $clo->{'dump-chords'} || @ARGV;

    # Return result.
    $options;
}

sub app_ident {
    my ($fh, $exit) = @_;
    print {$fh} ("This is ", ::runtimeinfo("short"), "\n");
    exit $exit if defined $exit;
}

sub app_about {
    my ($fh, $exit) = @_;
    print ${fh} <<EndOfAbout;

ChordPro: A lyrics and chords formatting program.

ChordPro will read a text file containing the lyrics of one or many
songs plus chord information. ChordPro will then generate a
photo-ready, professional looking, impress-your-friends sheet-music
suitable for printing on your nearest printer.

To learn more about ChordPro, look for the man page or do
"chordpro --help" for the list of options.

For more information, see https://www.chordpro.org .

Run-time information:
@{[::runtimeinfo()]}
EndOfAbout
    exit $exit if defined $exit;
}

use Cwd qw(realpath);

sub ::runtimeinfo {
    my $short = shift;

    my $fmt   = "  %-22.22s %s\n";
    my $fmtv  = defined($Wx::VERSION) ? "  %s version %s\n" : $fmt;
    my $fmtvv = defined($Wx::VERSION) ? "  %s %s\n" : $fmt;

    # Sometimes version numbers are localized...
    my $dd = sub { my $v = $_[0]; $v =~ s/,/./g; $v };

    my $msg = sprintf( $fmtv, "ChordPro core", $dd->($VERSION) );
    $msg =~ s/core/reference/ if $::options->{reference};
    if ( $VERSION =~ /_/ ) {
	$msg =~ s/\n$/ (Unsupported development snapshot)\n/;
    }

    if ( $short ) {
	$msg =~ s/^\s+//;
	$msg =~ s/\s+/ /g;
	$msg =~ s/\s*\n//;
	return $msg;
    }

    $msg .= sprintf( $fmtv, "Perl", $^V );
    $msg =~ s/\n$/ ($^X)\n/;
    if ( $App::Packager::PACKAGED ) {
	my $p = App::Packager::Packager();
	$p .= " Packager" unless $p =~ /packager/i;
	$msg .= sprintf( $fmtv, $p, $dd->(App::Packager::Version()) );
    }

    # Determine resource path.
    my @p;
    if ( $ENV{CHORDPRO_LIB} ) {
	$msg .= sprintf( $fmtv, "CHORDPRO_LIB", $ENV{CHORDPRO_LIB} );
	@p = splitpath($ENV{CHORDPRO_LIB});
    }
    push( @p, realpath( App::Packager::GetResourcePath() ) );
    my $tag = "Resource path";
    for ( @p ) {
	$msg .= sprintf( $fmtvv, $tag, $_ );
	$tag = "";
    }

    $msg .= "\nModules and libraries:\n";
    if ( defined $Wx::VERSION ) {
	no strict 'subs';
	$msg .= sprintf( $fmtv, "wxPerl", $dd->($Wx::VERSION) );
	$msg .= sprintf( $fmtv, "wxWidgets", $dd->(Wx::wxVERSION) );
    }

    local $SIG{__WARN__} = sub {};
    local $SIG{__DIE__} = sub {};
    $msg .= sprintf( $fmtv, "Storable", $dd->($Storable::VERSION) );
    eval { require Text::Layout;
	$msg .= sprintf( $fmtv, "Text::Layout", $dd->($Text::Layout::VERSION) );
    };
    eval { require HarfBuzz::Shaper;
	$msg .= sprintf( $fmtv, "HarfBuzz::Shaper", $dd->($HarfBuzz::Shaper::VERSION) );
	$msg .= sprintf( $fmtv, "HarfBuzz library", $dd->(HarfBuzz::Shaper::hb_version_string()) );
    };
    $msg .= sprintf( $fmtv, "File::LoadLines", $dd->($File::LoadLines::VERSION) );
    eval { require PDF::Builder;
	$msg .= sprintf( $fmtv, "PDF::Builder", $dd->($PDF::Builder::VERSION) );
    }
    or
    eval { require PDF::API2;
	$msg .= sprintf( $fmtv, "PDF::API2", $dd->($PDF::API2::VERSION) );
    };
    eval { require Font::TTF;
	$msg .= sprintf( $fmtv, "Font::TTF", $dd->($Font::TTF::VERSION) );
    };
    eval { require Image::Magick;
	$msg .= sprintf( $fmtv, "Image::Magick",
			 $dd->( $Image::Magick::VERSION ||
				$Image::Magick::Q16::VERSION ||
				$Image::Magick::Q8::VERSION || "6.x?" ) );
    };
    return $msg;
}

sub splitpath {
    my ( $path ) = @_;
    return () unless $path;
    if ( $^O =~ /Win/ ) {
	return split( /;/, $path );
    }
    return split( /;/, $path );
}

sub app_usage {
    my ($fh, $exit) = @_;
    my %cfg;
    for ( qw( config userconfig sysconfig) ) {
	$cfg{$_} = $configs{$_} || "no default";
    }
    print ${fh} <<EndOfUsage;
Usage: $0 [ options ] [ file ... ]

Options:
    --a2crd                       Perform text to ChordPro conversion only
    --noa2crd                     Do not auto-sense text to ChordPro conversion
    --about  -A                   About ChordPro...
    --config=JSON  --cfg          Config definitions (multiple)
    --cover=FILE                  Add cover pages from PDF document
    --crd                         Input is text, not ChordPro
    --decapo                      Eliminate capo settings
    --diagrams=WHICH		  Prints chord diagrams
    --encoding=ENC                Encoding for input files (UTF-8)
    --filelist=FILE               Reads song file names from FILE
    --fragment -F                 Partial (incomplete) song
    --lyrics-only  -l             Only prints lyrics
    --output=FILE  -o             Saves the output to FILE
    --[no]strict                  Strict conformance
    --start-page-number=N  -p     Starting page number [1]
    --toc --notoc -i              Generates/suppresses a table of contents
    --transcode=SYS  -xc          Transcodes to notation system
    --transpose=N  -x             Transposes by N semi-tones
    --version  -V                 Prints version and exits

Chordii compatibility.
Options marked with * are better specified in the config file.
Options marked with - are ignored.
    --chord-font=FONT  -C         *Sets chord font
    --chord-grid-size=N  -s       *Sets chord diagram size [30]
    --chord-grids-sorted  -S      *Prints chord diagrams ordered by key
    --chord-size=N  -c            *Sets chord size [9]
    --dump-chords  -D             Dumps chords definitions (PostScript)
    --dump-chords-text  -d        Dumps chords definitions (Text)
    --even-pages-number-left  -L  *Even pages numbers on left
    --odd-pages-number-left       *Odd pages numbers on left
    --no-chord-grids  -G          *Disables printing of chord diagrams
    --no-easy-chord-grids  -g     Not supported
    --page-number-logical  -n     -Numbers logical pages, not physical
    --page-size=FMT  -P           *Specifies page size [letter, a4 (default)]
    --single-space  -a            *Automatic single space lines without chords
    --text-size=N  -t             *Sets text size [12]
    --text-font=FONT  -T          *Sets text font
    --user-chord-grids		  *Prints the user defined chords in the song
    --vertical-space=N  -w        *Extra vertical space between lines
    --2-up  -2                    Not supported
    --4-up  -4                    Not supported

Configuration options:
    --config=CFG        Project specific config file ($cfg{config})
    --noconfig          Don't use a project specific config file
    --nosongconfig      Don't use song specific configs
    --userconfig=CFG    User specific config file ($cfg{userconfig})
    --nouserconfig      Don't use a user specific config file
    --sysconfig=CFG     System specific config file ($cfg{sysconfig})
    --nosysconfig       Don't use a system specific config file
    --nodefaultconfigs  -X  Don't use any default config files
    --define=XXX=YYY	Sets config item XXX to value YYY
    --print-default-config   Prints the default config and exits
    --print-final-config   Prints the resultant config and exits
    --print-delta-config   Prints the diffs for the resultant config and exits
Missing default configuration files are silently ignored.

Miscellaneous options:
    --help  -h          This message
    --help-config       Help for ChordPro configuration
    --manual            The full manual.
    --ident             Show identification
    --verbose           Verbose information
EndOfUsage
    exit $exit if defined $exit;
}

################ Resources ################

use Encode qw(decode decode_utf8 encode_utf8);

sub ::rsc_or_file {
    my ( $c, $cfg ) = @_;
    my $f = $c;
    $cfg .= "/" if $cfg;

    # Check for resource names.
    if ( $f !~ m;[/.]; ) {
	if ( $c =~ /^(.+):(.*)/ ) {
	    $f = $cfg . lc($1) . "/" . lc($2) . ".json";
	}
	else {
	    $f = $cfg . lc($c) . ".json";
	}
    }
    if ( $ENV{CHORDPRO_LIB} ) {
	my @libs = splitpath($ENV{CHORDPRO_LIB});
	foreach my $lib ( @libs ) {
	    $lib = expand_tilde($lib);
	    warn("RSC1: $lib/$f\n") if $options->{debug};
	    return $lib . "/" . $f if -r $lib . "/" . $f;
	}
    }

    warn("RSC3: $f\n") if $options->{debug};
    my $t = getresource($f);
    return defined($t) ? $t : $c;
}

use lib ( grep { defined } getresource("CPAN") );

=head1 FONTS

There are two ways to specify fonts: with a font filename, and a
built-in font name.

A font filename must be either and absolute filename, or a relative
filename which is interpreted relative to the I<font path>, which
consists of configuration setting C<fontdir>, the C<fonts> resource
dir, and the contents of environment variable C<FONTDIR>. In any case,
the filename should point to a valid TrueType (C<.ttf>) or OpenType
(C<.otf>) font.

If it is not a filename, it must be the name one of the built-in fonts.

Built-in 'Adobe Core Fonts':

  Courier                             Symbol
  Courier-Bold                        Times-Bold
  Courier-BoldOblique                 Times-BoldItalic
  Courier-Oblique                     Times-Italic
  Helvetica                           Times-Roman
  Helvetica-Bold                      ZapfDingbats
  Helvetica-BoldOblique
  Helvetica-Oblique

Built-in 'Windows Fonts':

  Georgia                             Webdings
  Georgia,Bold                        Wingdings
  Georgia,BoldItalic
  Georgia,Italic
  Verdana
  Verdana,Bold
  Verdana,BoldItalic
  Verdana,Italic

=head1 MOTIVATION

Why a rewrite of Chordii?

Chordii is the de facto reference implementation of the ChordPro file
format standard. It implements ChordPro version 4.

ChordPro version 5 adds a number of new features, and this was pushing
the limits of the very old program. Unicode support would have been
very hard to add, and the whole program centered around PostScript
generation, while nowadays PDF would be a much better alternative.

So I decided to create a new reference implementation from the ground
up. I chose a programming language that is flexible and very good at
handling Unicode data. And that is fun to program in.

=head1 CURRENT STATUS

This program implements ChordPro version 5. It
supports most of the features of Chordii, and a lot more:

* Native PDF generation

* Unicode support (all input is UTF8)

* User defined chords and tuning, not limited to 6 strings.

* Support for Nashville Numbering and Roman Numbering.

* Support for external TrueType and OpenType fonts

* Font kerning (with external TrueType fonts)

* Fully customizable layout, fonts and sizes

* Customizable backends for PDF, ChordPro, LilyPond*, LaTeX* and HTML*.

(* = under development)

=head1 AUTHOR

Johan Vromans C<< <jv at CPAN dot org > >>

=head1 SUPPORT

ChordPro (the program) development is hosted on GitHub, repository
L<https://github.com/ChordPro/chordpro>.

Please report any bugs or feature requests to the GitHub issue tracker,
L<https://github.com/ChordPro/chordpro/issues>.

A user community discussing ChordPro can be found at
L<https://groups.google.com/forum/#!forum/chordpro>.

=head1 LICENSE

Copyright (C) 2010,2018 Johan Vromans,

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
