#! perl

use 5.010;

package App::Music::ChordPro::A2Crd;

use App::Packager;

use App::Music::ChordPro::Version;

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

B<chordpro> is a rewrite of the Chordii program, see
L<http://www.chordii.org>.

For more information about the ChordPro file format, see
L<http://www.chordpro.org>.

=cut

################ Common stuff ################

use strict;
use warnings;
use utf8;
use Carp;

package App::Music::ChordPro::A2Crd;

use File::LoadLines;

sub ::run {
    my $options = app_setup( "a2crd", $VERSION );
    binmode(STDERR, ':utf8');
    binmode(STDOUT, ':utf8');
    $options->{trace}   = 1 if $options->{debug};
    $options->{verbose} = 1 if $options->{trace};
    main($options);
}

sub main {
    my ( $options ) = @_;

    my $lines = loadlines( @ARGV ? $ARGV[0] : \*DATA);

    my $fd;
    if ( $options->{output} && $options->{output} ne '-' ) {
	open( $fd, '>:utf8', $options->{output} )
	  or croak("$options->{output}: $!\n");
    }
    else {
	$fd = \*STDOUT;
    }

    print $fd "$_\n"
      foreach a2cho($lines, $options);
}

################ Subroutines ################

# API: Produce ChordPro data from AsciiCRD lines.
sub a2cho {
    my ( $lines, $options ) = @_;
    my $map = "";
    foreach ( @$lines ) {
	$map .= classify($_);
    }
    maplines( $map, $lines );
}

# Classify the line and return a single-char token.
sub classify {
    my ( $line ) = @_;
    return '_' if $line =~ /^\s*$/;	# empty line
    return '{' if $line =~ /^\{.+/;	# directive

    # Lyrics or Chords heuristic.
    my $len = length($line);
    $line =~ s/\s+//g;
    return ( $len / length($line) - 1 ) < 1 ? 'l' : 'c';
}

# Process the lines via the map.
sub maplines {
    my ( $map, $lines ) = @_;
    my @out;

    # Preamble.
    while ( $map =~ s/^([l_{])// ) {
	push( @out, ($1 eq "l" ? "# " : "" ) . shift( @$lines ) );
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

sub app_setup {
    my ($appname, $appversion, %args) = @_;
    my $help = 0;               # handled locally
    my $manual = 0;             # handled locally
    my $ident = 0;              # handled locally
    my $version = 0;            # handled locally

    # Package name.
    $my_package = $args{package};
    # Program name and version.
    if ( defined $appname ) {
        ($my_name, $my_version) = ($appname, $appversion);
    }
    else {
        ($my_name, $my_version) = qw( MyProg 0.01 );
    }

    my $options =
      {
       verbose          => 0,           # verbose processing
       debug            => 0,           # debugging
       trace            => 0,           # trace (show process)
      };

    # Colled command line options in a hash, for they will be needed
    # later.
    my $clo = {};

    # Sorry, layout is a bit ugly...
    if ( !GetOptions
         ($clo,
          "output|o=s",                 # Saves the output to FILE
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

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;
    # warn(Dumper($options), "\n") if $options->{debug};

    # At this point, there should be filename argument(s)
    # unless we're embedded or just dumping chords.
    app_usage(\*STDERR, 1) unless @ARGV;

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
