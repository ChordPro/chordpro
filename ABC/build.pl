#!/usr/bin/perl -w

# Build tool for ABC.

# Author          : Johan Vromans
# Created On      : Sun Feb 18 16:15:19 2024
# Last Modified By: Johan Vromans
# Last Modified On: Mon Dec 29 10:02:11 2025
# Update Count    : 27
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'ChordPro/ABC';
# Program name and version.
my ($my_name, $my_version) = qw( build 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $abcroot;
my $dest;
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use Archive::Tar;

my $kit = $ARGV[0];
my $major = 1;

my $tar = Archive::Tar->new($kit);

$abcroot //= $1 if $kit =~ m/([-\w_]+)\./;

my $target;
for $target ( "$dest/abc2svg-$major.js" ) {
    warn("Creating $target...\n") if $verbose;
    open( my $fd, '>', $target )
      or die( "$target: $!\n" );

    for my $mod ( qw( core/abc2svg.js core/deco.js core/draw.js
		      font.js core/format.js core/front.js core/music.js
		      core/parse.js core/subs.js core/svg.js core/tune.js
		      core/lyrics.js core/gchord.js core/tail.js
		      core/modules.js
		      version.txt ) ) {
	my $data = $tar->get_content("$abcroot/$mod");
	die( "$abcroot/$mod: $!\n" ) unless $data;
	warn("  adding $mod (", length($data), " bytes)...\n") if $verbose > 1;
	$data .= "\n" unless $data =~ /\n$/;
	print $fd $data;
    }
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
		  modules/fit2box.js
		  modules/gamelan.js
		  modules/grid.js
		  modules/grid2.js
		  modules/grid3.js
		  modules/jazzchord.js
		  modules/jianpu.js
		  modules/mdnn.js
		  modules/nns.js
		  modules/MIDI.js
		  modules/page.js
		  modules/pedline.js
		  modules/perc.js
		  modules/wps.js
		  modules/roman.js
		  modules/soloffs.js
		  modules/sth.js
		  modules/swing.js
		  modules/strtab.js
		  modules/temper.js
		  modules/tropt.js
		  modules/tunhd.js
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

for my $mod ( qw( COPYING.LESSER README.md tohtml.js ) ) {

    my $target = "$dest/$mod";

    warn("Creating $target...\n") if $verbose;
    open( my $fd, '>', "$target" )
      or die( "$target: $!\n" );

    my $data = $tar->get_content("$abcroot/$mod");
    die( "$abcroot/$mod: $!\n" ) unless $data;
    warn("  adding $mod (", length($data), " bytes)...\n") if $verbose > 1;
    $data .= "\n" unless $data =~ /\n$/;

    if ( $mod eq "tohtml.js" ) {
	$data =~ s;\Qabc2svg.print('</html>')\E;//$&;;
    }

    print $fd $data;

    $fd->close
      or die( "$target: $!\n" );
}

exit 0;

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
	GetOptions( 'abcroot=s' => \$abcroot,
		    'dest=s'	=> \$dest,
		    'ident'	=> \$ident,
		    'verbose+'	=> \$verbose,
		    'quiet'	=> sub { $verbose = 0 },
		    'trace'	=> \$trace,
		    'help|?'	=> \$help,
		    'debug'	=> \$debug )
	  or $pod2usage->( -exitval => 2, -verbose => 0 );
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->( -exitval => 0, -verbose => 0 );
    }
}

__END__

################ Documentation ################

=head1 NAME

build - tool to prepare ABC files for ChrdPro

=head1 SYNOPSIS

build [options] abckit

 Mandatory arguments:
   --dest=XXX		destination for the abc files in the ChordPro kit

 Options:
   --abcroot=XXX	root of the abc files in the source kit
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

=cut
