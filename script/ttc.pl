#!/usr/bin/perl

# Author          : Johan Vromans
# Created On      : Wed Oct  8 14:18:07 2025
# Last Modified By: Johan Vromans
# Last Modified On: Wed Oct  8 15:24:54 2025
# Update Count    : 44
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my ($my_name, $my_version) = qw( ttc 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;
Getopt::Long::Configure( qw( no_ignore_case ) );

# Command line options.
my $with_filename;
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$with_filename //= @ARGV > 1;
$trace |= ($debug || $test);

################ Presets ################

use FindBin;

# @INC construction...
# Standard paths are lib and lib/ChordPro/lib relative to the parent
# of the script directory. This may fail if the ChordPro files are installed
# in another directory than next to the script.
# Directories in CHORDPRO_XLIBS follow, to augment the path.
# For example, to add custom delegates.
# Directories in CHORDPRO_XXLIBS are put in front, these can be used
# to overrule standard modules. For example, to provide a patches
# module to an installed kit. Caveat emptor.

my @inc;
BEGIN {
  for my $lib ( "$FindBin::Bin/../lib", "$FindBin::Bin/../lib/ChordPro/lib", @INC ) {
    next unless -d $lib;

    # Is our main module here?
    if ( -s "$lib/ChordPro.pm" ) {
	# Add ChordPro libs.
	push( @inc, $lib, "$lib/ChordPro/lib" );
    }
    else {
	# Copy.
	push( @inc, $lib );
    }
  }
}
use lib @inc;

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use Font::TTF::Font;
use Font::TTF::Ttc;

for my $font ( @ARGV ) {
    unless ( $font =~ /\.ttc$/i ) {
	die("$font: Does not look like a TTC\n");
    }

    my $ttc = Font::TTF::Ttc->open($font);
    my $index = 0;
    print( "$font:\n" ) if $with_filename;
    my $ll = -1;
    foreach my $d ( @{ $ttc->{directs} } ) {
	$d->{name}->read;
	$ll = length(find_name( $d->{name}, 6 ))
	  if $ll < length(find_name( $d->{name}, 6 ));
    }
    $ll += 2;
    foreach my $d ( @{ $ttc->{directs} } ) {
	$index++;
	printf( "%2d: PS=%-${ll}s fam=\"%s\" sub=\"%s\"\n",
		$index,
		'"'.find_name( $d->{name}, 6 ).'"',
		find_name( $d->{name}, 1 ),
		find_name( $d->{name}, 2 ),
	      );
    }
}

################ Subroutines ################

sub find_name {
    my ( $self, $nid ) = @_;
    my ( $res, $k );

    my @lookup = ( [3, 1, 1033], [3, 1, -1], [3, 0, 1033], [3, 0, -1],
		   [2, 1, -1], [2, 2, -1], [2, 0, -1],
		   [0, 0, 0], [1, 0, 0] );
    foreach my $look (@lookup) {
        my ( $pid, $eid, $lid ) = @$look;
        if ( $lid == -1 ) {
            foreach my $k ( keys %{$self->{strings}[$nid][$pid][$eid]} ) {
                if ( ( $res = $self->{strings}[$nid][$pid][$eid]{$k} ) ne '' ) {
                    $lid = $k;
                    last;
                }
            }
        }
	else {
	    $res = $self->{strings}[$nid][$pid][$eid]{$lid};
	}
        return $res if defined $res && $res ne '';
    }
    return '';
}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions( 'with-filename|H' => \$with_filename,
		    'ident'	=> \$ident,
		    'verbose+'	=> \$verbose,
		    'quiet'	=> sub { $verbose = 0 },
		    'trace'	=> \$trace,
		    'help|?'	=> \$help,
		    'man'	=> \$man,
		    'debug'	=> \$debug )
	  or $pod2usage->( -exitval => 2, -verbose => 0 );
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->( -exitval => 0, -verbose => $man ? 2 : 0 );
    }
}

__END__

################ Documentation ################

=head1 NAME

ttc - show fonts in a ttc

=head1 SYNOPSIS

ttc [options] [file ...]

 Options:
   --with-filename  -H  includes filename
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

=head1 OPTIONS

=over 8

=item B<--with-filename>  B<-H>

Include the filename in the output. This is default if there is
more than one file to process.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.
This option may be repeated to increase verbosity.

=item B<--quiet>

Suppresses all non-essential information.

=item I<file>

The input file(s) to process, if any.

=back

=head1 DESCRIPTION

B<This program> will read the given ttc file(s) and lists the fonts
contained.

The output contains per font:

 - the index of the font
 - PS= its PostScript name
 - fam= the family name
 - sub= the subfamily (style)

=head1 EXAMPLE

    ttc -H Times.ttc
    Times.ttc:
     1: PS="Times-Roman"      fam="Times" sub="Regular"
     2: PS="Times-Bold"       fam="Times" sub="Bold"
     3: PS="Times-Italic"     fam="Times" sub="Italic"
     4: PS="Times-BoldItalic" fam="Times" sub="Bold Italic"

=cut
