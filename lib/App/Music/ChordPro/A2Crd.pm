#! perl

use 5.010;

package App::Music::ChordPro::A2Crd;

use App::Packager;

use App::Music::ChordPro::Version;
use App::Music::ChordPro::Chords;

our $VERSION = $App::Music::ChordPro::Version::VERSION;

=head1 NAME

App::Music::ChordPro::A2Crd - convert lyrics and chords to ChordPro

=head1 SYNOPSIS

  perl -MApp::Music::Chordpro::A2Crd -e run -- [ options ] [ file ... ]

(But noone does that.)

When the associated B<chordpro> program has been installed correctly:

  chordpro --a2crd [ options ] [ file ... ]

=head1 DESCRIPTION

B<This program>, referred to as B<a2crd>, will read a text file
containing the lyrics of one or many songs with chord information
written visually above the lyrics. This is often referred to as I<crd>
data. B<a2crd> will then generate equivalent ChordPro output.

Typical a2crd input:

    Title: Swing Low Sweet Chariot

	  D          G    D
    Swing low, sweet chariot,
			   A7
    Comin’ for to carry me home.
	  D7         G    D
    Swing low, sweet chariot,
		  A7       D
    Comin’ for to carry me home.

      D                       G          D
    I looked over Jordan, and what did I see,
			   A7
    Comin’ for to carry me home.
      D              G            D
    A band of angels comin’ after me,
		  A7       D
    Comin’ for to carry me home.

Note that the output from the conversion will generally need some
additional editing to be useful as input to ChordPro.

B<a2crd> is a wrapper around L<App::Music::ChordPro::A2Crd>, which
does all of the work.

B<chordpro> will read one or more text files containing the lyrics of
one or many songs plus chord information. B<chordpro> will then
generate a photo-ready, professional looking, impress-your-friends
sheet-music suitable for printing on your nearest printer.

B<chordpro> is a rewrite of the Chordii program.

For more information about the ChordPro file format, see
L<https://www.chordpro.org>.

=cut

################ Common stuff ################

use strict;
use warnings;
use utf8;
use Carp;

################ The Process ################

package main;

our $options;
our $config;

package App::Music::ChordPro::A2Crd;

use App::Music::ChordPro::Config;

use File::LoadLines;
use Encode qw(decode decode_utf8 encode_utf8);

# API: Main entry point.
sub a2crd {
    my ($opts) = @_;
    $options = { %$options, %$opts } if $opts;

    # One configurator to bind them all.
    $config = App::Music::ChordPro::Config::configurator({});

    # Process input.
    my $lines = loadlines( @ARGV ? $ARGV[0] : \*STDIN);

    return [ a2cho($lines) ];
}

################ Subroutines ################

# Replace tabs with blanks, retaining layout.
my $tabstop;
sub expand {
    my ( $line ) = @_;
    return $line unless $line;
    $tabstop //= $::config->{a2crd}->{tabstop};
    return $line unless $tabstop > 0;

    my ( @l ) = split( /\t/, $line, -1 );
    return $l[0] if @l == 1;

    $line = shift(@l);
    $line .= " " x ($tabstop-length($line)%$tabstop) . shift(@l) while @l;

    return $line;
}

# API: Produce ChordPro data from AsciiCRD lines.
sub a2cho {
    my ( $lines ) = @_;
    my $map = "";
    my @lines_with_tabs_replaced ;
    foreach ( @$lines ) {
        if(/\t/) {
	    $_ = expand($_) ;
        }
        push @lines_with_tabs_replaced, $_ ;
        $map .= classify($_);
    }
    maplines( $map, \@lines_with_tabs_replaced );

}

# Classify the line and return a single-char token.
my $classify;
sub classify {
    my ( $line ) = @_;
    return '_' if $line =~ /^\s*$/;	# empty line
    return '{' if $line =~ /^\{.+/;	# directive
    unless ( defined $classify ) {
	my $classifier = $::config->{a2crd}->{classifier};
	$classify = __PACKAGE__->can("classify_".$classifier);
	unless ( $classify ) {
	    warn("No such classifier: $classifier, using classic\n");
	    $classify = \&classify_classic;
	}
    }
    $classify->($line);
}

sub classify_classic {
    my ( $line ) = @_;
    # Lyrics or Chords heuristic.
    my @words = split ( /\s+/, $line );
    my $len = length($line);
    $line =~ s/\s+//g;
    my $type = ( $len / length($line) - 1 ) < 1 ? 'l' : 'c';
    my $p = App::Music::ChordPro::Chords::Parser->default;
    if ( $type eq 'l') {
        foreach (@words) {
            if (length $_ > 0) {
                if (!App::Music::ChordPro::Chords::parse_chord($_)) {
                    return 'l';
                }
            }
        }
        return 'c';
    }
    return $type;
}

# Alternative classifier by Jeff Welty.
# Strategy: Percentage of recognzied chords.
sub classify_pct_chords {
    my ( $line ) = @_;

    # Lyrics or Chords heuristic.
    my @words = split ( /\s+/, $line );

    my $linelen_total = length($line) ;
    $line =~ s/\s+//g ;
    my $linelen_nonblank = length($line) ;

    my $p = App::Music::ChordPro::Chords::Parser->default;

    my $n_chords=0 ;
    my $n_words=0 ;
    #print("CL:") ; # JJW, uncomment for debugging

    foreach (@words) {

	if (length $_ > 0) {
	    $n_words++ ;

	    my $is_chord = App::Music::ChordPro::Chords::parse_chord($_) ? 1 : 0  ;
	    $n_chords++ if $is_chord ;

	    #print(" \'$is_chord:$_\'") ; # JJW, uncomment for debugging
	}
    }

    my $type = $n_chords/$n_words > 0.4 ? 'c' : 'l' ;

    if($type eq 'l') {
	# is it likely the line had a lot of unknown chords, check
	# the ratio of total chars to nonblank chars , if it is large then
	# it's probably a chord line
	$type = 'c' if $n_words > 1 && $linelen_total/$linelen_nonblank > 2. ;
    }

    #print(" --- ($n_chords/$n_words) = $type\n") ; # JJW, uncomment for debugging

    return $type ;
}

# Process the lines via the map.
my $infer_titles;
sub maplines {
    my ( $map, $lines ) = @_;
    my @out;
    $infer_titles //= $::config->{a2crd}->{'infer-titles'};

    # Preamble.
    # Pass empty lines.
    while ( $map =~ s/^_// ) {
	push( @out, shift( @$lines ) );
    }

    # Infer title/subtitle.
    if ( $infer_titles && $map =~ s/^l// ) {
	push( @out, "{title: " . shift( @$lines ) . "}");
	if ( $map =~ s/^l// ) {
	    push( @out, "{subtitle: " . shift( @$lines ) . "}");
	}
    }

    # Pass lines until we have chords.
    while ( $map =~ s/^([l_{])// ) {
	if ( $1 eq "l" ) {
	    push( @out, "{comment: " . shift( @$lines ) ."}" );
	}
	else {
	    push( @out, shift( @$lines ) );
	}
    }

    # Process the lines using the map.
    while ( $map ) {
	# warn($map);

	# Blank line preceding chords: pass.
	if ( $map =~ s/^_c/c/ ) {
	    push( @out, '');
	    shift(@$lines);
	    # Fall through.
	}

	# The normal case: chords + lyrics.
	if ( $map =~ s/^cl// ) {
	    push( @out, combine( shift(@$lines), shift(@$lines), "cl" ) );
	}

	# Empty line preceding a chordless lyrics line.
	elsif ( $map =~ s/^__l// ) {
	    push( @out, '' );
	    shift( @$lines );
	    push( @out, combine( shift(@$lines), shift(@$lines), "__l" ) );
	}

	# Chordless lyrics line.
	elsif ( $map =~ s/^_l// ) {
	    push( @out, combine( shift(@$lines), shift(@$lines), "_l" ) );
	}

	# Lone lyrics or directives.
	elsif ( $map =~ s/^[l{]// ) {
	    push( @out, shift( @$lines ) );
	}

	# Lone chords.
	elsif ( $map =~ s/^c// ) {
	    push( @out, combine( shift(@$lines), '', "c" ) );
	}

	# Empty line.
	elsif ( $map =~ s/^_// ) {
	    push( @out, '' );
	    shift( @$lines );
	}

	# Can't happen.
	else {
	    croak("MAP: $map");
	}
    }
    return wantarray ? @out : \@out;
}

# Combine two lines (chords + lyrics) into lyrics with [chords].
sub combine {
    my ( $l1, $l2 ) = @_;
    my $res = "";
    while ( $l1 =~ /^(\s*)(\S+)(.*)/ ) {
	$res .= join( '',
		      substr( $l2, 0, length($1), '' ),
		      '[' . $2 . ']',
		      substr( $l2, 0, length($2), '' ) );
	$l1 = $3;
    }
    return $res.$l2;
}

################ Options and Configuration ################

=head1 COMMAND LINE OPTIONS

=over 4

=item B<--output=>I<FILE> (short: B<-o>)

Designates the name of the output file where the results are written
to. Default is standard output.

=item B<--version> (short: B<-V>)

Prints the program version and exits.

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

use Getopt::Long 2.13;

# Package name.
my $my_package;
# Program name and version.
my ($my_name, $my_version);
my %configs;

sub app_setup {
    goto &App::Music::ChordPro::app_setup;
    my ($appname, $appversion, %args) = @_;
    my $help = 0;               # handled locally
    my $manual = 0;             # handled locally
    my $ident = 0;              # handled locally
    my $version = 0;            # handled locally
    my $defcfg = 0;		# handled locally
    my $fincfg = 0;		# handled locally

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
    my $app_lc = lc("ChordPro"); # common config
    if ( -d "/etc" ) {          # some *ux
        $configs{sysconfig} =
          File::Spec->catfile( "/", "etc", "$app_lc.json" );
    }

    my $e = $ENV{CHORDIIRC} || $ENV{CHORDRC};
    if ( $ENV{HOME} && -d $ENV{HOME} ) {
        if ( -d File::Spec->catfile( $ENV{HOME}, ".config" ) ) {
            $configs{userconfig} =
              File::Spec->catfile( $ENV{HOME}, ".config", $app_lc, "$app_lc.json" );
        }
        else {
            $configs{userconfig} =
              File::Spec->catfile( $ENV{HOME}, ".$app_lc", "$app_lc.json" );
        }
	$e ||= File::Spec->catfile( $ENV{HOME}, ".chordrc" );
    }
    $e ||= "/chordrc";		# Windows, most likely
    $configs{legacyconfig} = $e if -s $e && -r _;

    if ( -s ".$app_lc.json" ) {
        $configs{config} = ".$app_lc.json";
    }
    else {
        $configs{config} = "$app_lc.json";
    }

    my $options =
      {
       verbose          => 0,           # verbose processing

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

    # Sorry, layout is a bit ugly...
    if ( !GetOptions
         ($clo,
          "output|o=s",                 # Saves the output to FILE

          ### Configuration handling ###

          'config|cfg=s@',
          'noconfig|no-config',
          'sysconfig=s',
          'nosysconfig|no-sysconfig',
          'userconfig=s',
          'nouserconfig|no-userconfig',
	  'nolegacyconfig|no-legacy-config',
	  'nodefaultconfigs|no-default-configs|X',
	  'define=s%',
	  'print-default-config' => \$defcfg,
	  'print-final-config'   => \$fincfg,

          ### Standard options ###

          "version|V" => \$version,     # Prints version and exits
          'ident'               => \$ident,
          'help|h|?'            => \$help,
          'manual'              => \$manual,
          'verbose|v+',
          'trace',
          'debug+',
         ) )
    {
        # GNU convention: message to STDERR upon failure.
        app_usage(\*STDERR, 2);
    }

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
	my $f = "pod/A2Crd.pod";
        unshift( @_, -input => getresource($f) );
        &pod2usage;
    };

    # GNU convention: message to STDOUT upon request.
    app_ident(\*STDOUT) if $ident || $help || $manual;
    if ( $manual or $help ) {
        app_usage(\*STDOUT, 0) if $help;
        $pod2usage->(VERBOSE => 2) if $manual;
    }
    app_ident(\*STDOUT, 0) if $version;

    # If the user specified a config, it must exist.
    # Otherwise, set to a default.
    for my $config ( qw(sysconfig userconfig legacyconfig) ) {
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
		    if ( ! -r $c && $c !~ m;[/.]; ) {
			$c = ::rsc_or_file($c);
		    }
                    die("$c: $!\n") unless -r $c;
                }
                next;
            }
	    # Use default.
	    next if $clo->{nodefaultconfigs};
	    next unless $configs{$config};
            $_ = [ $configs{$config} ];
            undef($_) unless -r $_->[0];
        }
    }
    # If no config was specified, and no default is available, force no.
    for my $config ( qw(sysconfig userconfig config legacyconfig) ) {
        $clo->{"no$config"} = 1 unless $clo->{$config};
    }

    ####TODO: Should decode all, and remove filename exception.
    for ( keys %{ $clo->{define} } ) {
	$clo->{define}->{$_} = decode_utf8($clo->{define}->{$_});
    }

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;
    # warn(Dumper($options), "\n") if $options->{debug};

    if ( $defcfg || $fincfg ) {
	print App::Music::ChordPro::Config::config_default()
	  if $defcfg;
	print App::Music::ChordPro::Config::config_final()
	  if $fincfg;
	exit 0;
    }

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

sub app_usage {
    my ($fh, $exit) = @_;
    my $cmd = $0;
    $cmd .= " --a2crd" if $cmd !~ m;(?:^|\/|\\)a2crd(?:\.\w+)$;;
    print ${fh} <<EndOfUsage;
Usage: $cmd [ options ] [ file ... ]

Options:
    --output=FILE  -o   Saves the output to FILE
    --version  -V       Prints version and exits
    --help  -h          This message
    --manual            The full manual
    --ident             Show identification
    --verbose           Verbose information
EndOfUsage
    exit $exit if defined $exit;
}

=head1 AUTHOR

Johan Vromans C<< <jv at CPAN dot org > >>

=head1 SUPPORT

A2Crd is part of ChordPro (the program). Development is hosted on
GitHub, repository L<https://github.com/ChordPro/chordpro>.

Please report any bugs or feature requests to the GitHub issue tracker,
L<https://github.com/ChordPro/chordpro/issues>.

A user community discussing ChordPro can be found at
L<https://groups.google.com/forum/#!forum/chordpro>.

=head1 LICENSE

Copyright (C) 2010,2018 Johan Vromans,

This program is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
