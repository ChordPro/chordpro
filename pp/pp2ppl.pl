#!/usr/bin/perl -w

# Create portable tree out of PP package.

# Author          : Johan Vromans
# Created On      : Mon Apr 27 15:13:18 2020
# Last Modified By: 
# Last Modified On: Tue May 30 09:56:53 2023
# Update Count    : 43
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = qw( pp2ppl 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $dest;			# dest dir
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

# 1. extract embedded files to $dest/lib
# 2. process as ZIP:
#    - extract lib/ to $dest/lib
#    - extract shlib/ to $dest
#    - extract rest as is

use File::Spec::Functions;
use File::Basename;
use File::Path;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $exe = shift;

mkpath( $dest );

extract_embedded( $exe, catdir( $dest, "lib" ) );

extract_zip( $exe, $dest );

################ Subroutines ################

sub extract_zip {
    my ($exe, $extract) = @_;

    my $zip = Archive::Zip->new;
    unless ( $zip->read($exe) == AZ_OK ) {
	die("$exe [zip] open error\n");
    }

    foreach my $member ( $zip->members ) {
	next if $member->isDirectory;

	# Get file name.
	my $x = $member->fileName;
	# shlibs to root.
	$x =~ s;^shlib/.*?([^/]+)$;$1;;

	my $skip = -f catfile( $dest, $x );
	if ( $verbose ) {
	    print STDERR ( $skip ? "Skipping \"" : "Extracting \"",
			   $member->fileName);
	    print STDERR ("\" to \"$x") unless $x eq $member->fileName;
	    print STDERR ("\"\n");
	}
	next if $skip;

	my $file = catfile( $dest, $x );
	$zip->extractMember( $member, $file ) == AZ_OK
	  or die("Zip extract $x error\n");
	my @st = stat($file);
	warn("STAT $file: $!\n") unless @st;
	my $perm = $st[2] & 0777;
	chmod( $perm | 0220, $file );
    }

}

sub extract_embedded {

    # Code stolen from extract_embedded.pl, which is code stolen from
    # one of Roderich Schupp's mails to the PAR mailing list. He
    # attributes this to: code stolen from PAR script/parl.pl.

    my ( $exe, $extract ) = @_;

    open( my $fh, '<:raw', $exe) or die("$exe: $!\n");

    # Search for the "\nPAR.pm\n" signature backward from the end of the file.
    my $buf;
    my $size = -s $exe;
    my $offset = 512;
    my $idx = -1;
    while ( 1 ) {
	$offset = $size if $offset > $size;
	seek( $fh, -$offset, 2 ) or die("$exe: Seek failed: $!\n");
	my $nread = read( $fh, $buf, $offset );
	die("$exe: Read failed: $!\n") unless $nread == $offset;
	$idx = rindex( $buf, "\nPAR.pm\n" );
	last if $idx >= 0 || $offset == $size || $offset > 128 * 1024;
	$offset *= 2;
    }
    die("$exe: No PAR signature found\n") unless $idx >= 0;

    # Seek 4 bytes backward from the signature to get the offset
    # of the first embedded FILE, then seek to it.
    $offset -= $idx - 4;
    seek( $fh, -$offset, 2 );
    read( $fh, $buf, 4 );
    seek( $fh, -$offset - unpack("N", $buf), 2 );
    printf STDERR ( "$exe: Embedded files start at offset %d\n",
		    $exe, tell($fh) ) if $trace;

    read( $fh, $buf, 4 );
    while ( $buf eq "FILE" ) {
	read( $fh, $buf, 4 );
	read( $fh, $buf, unpack("N", $buf) );

	( my $fullname = $buf ) =~ s|^([a-f\d]{8})/||; # strip CRC

	read( $fh, $buf, 4 );
	read( $fh, $buf, unpack("N", $buf) );

	my $file = catdir( $extract, split(/\//, $fullname) );
	if ( -f $file ) {
	    warn("Skipping: \"$fullname\"\n") if $verbose;
	    next;
	}

	my $dir = dirname($file);
	unless ( -d $dir ) {
	    # print STDERR "Creating directory $dir...\n";
	    mkpath($dir);
	}

	print STDERR ("Extracting \"$file\"\n" ) if $verbose;
	open( my $out, '>:raw', $file )
	  or die("Error creating \"$file\": $!\n");
	print $out $buf;
	close($out)
	  or die("Error closing \"$file\": $!\n");
    }
    continue {
	read( $fh, $buf, 4 );
    }

    close $fh;
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
	GetOptions( 'dest=s'	=> \$dest,
		    'ident'	=> \$ident,
		    'verbose+'	=> \$verbose,
		    'quiet'	=> sub { $verbose = 0 },
		    'trace'	=> \$trace,
		    'help|?'	=> \$help,
		    'man'	=> \$man,
		    'debug'	=> \$debug)
	  or $pod2usage->(2);
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
    unless ( $dest && @ARGV == 1 ) {
	$pod2usage->(2);
    }
}

__END__

################ Documentation ################

=head1 NAME

pp2ppl - Create portable tree out of PP package.

=head1 SYNOPSIS

sample [options] package

 Options:
   --dest=XXX           destination folder
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

=head1 OPTIONS

=over 8

=item B<--dest=>I<XXX>

The folder where the tree will be unpacked.

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

=item I<package>

The package to process. This must be an archive file  created by L<PAR>.

=back

=head1 DESCRIPTION

B<This program> will read the archive file and unpack it into the
destination directory.

First the embedded files are extracted to $dest/lib.

Then the remainder of the PAR is processed as a ZIP archive:

=over 4

=item *

C<lib/> files are extracted to $dest/lib;

=item *

C<shlib/> files are extracted to $dest;

=item *

The rest is extracted I<as is>.

=back

The resultant file tree is suitable to build a ppl (Portable Perl Loader) kit.

=cut
