#! perl

package App::Music::ChordPro::Utils;

use strict;
use warnings;
use utf8;
use parent qw(Exporter);

our @EXPORT;

################ Filenames ################

use File::Glob ( $] >= 5.016 ? ":bsd_glob" : ":glob" );
use File::Spec;
use constant MSWIN => $^O =~ /MSWin|Windows_NT/i ? 1 : 0;

# Derived from Path::ExpandTilde.

use constant BSD_GLOB_FLAGS => GLOB_NOCHECK | GLOB_QUOTE | GLOB_TILDE | GLOB_ERR
  # add GLOB_NOCASE as in File::Glob
  | ($^O =~ m/\A(?:MSWin32|VMS|os2|dos|riscos)\z/ ? GLOB_NOCASE : 0);

# File::Glob did not try %USERPROFILE% (set in Windows NT derivatives) for ~ before 5.16
use constant WINDOWS_USERPROFILE => MSWIN && $] < 5.016;

sub expand_tilde {
    my ( $dir ) = @_;

    return undef unless defined $dir;
    return File::Spec->canonpath($dir) unless $dir =~ m/^~/;

    # Parse path into segments.
    my ( $volume, $directories, $file ) = File::Spec->splitpath( $dir, 1 );
    my @parts = File::Spec->splitdir($directories);
    my $first = shift( @parts );
    return File::Spec->canonpath($dir) unless defined $first;

    # Expand first segment.
    my $expanded;
    if ( WINDOWS_USERPROFILE and $first eq '~' ) {
	$expanded = $ENV{HOME} || $ENV{USERPROFILE};
    }
    else {
	( my $pattern = $first ) =~ s/([\\*?{[])/\\$1/g;
	($expanded) = bsd_glob( $pattern, BSD_GLOB_FLAGS );
	croak( "Failed to expand $first: $!") if GLOB_ERROR;
    }
    return File::Spec->canonpath($dir)
      if !defined $expanded or $expanded eq $first;

    # Replace first segment with new path.
    ( $volume, $directories ) = File::Spec->splitpath( $expanded, 1 );
    $directories = File::Spec->catdir( $directories, @parts );
    return File::Spec->catpath($volume, $directories, $file);
}

push( @EXPORT, 'expand_tilde' );

sub is_msw   { MSWIN }
sub is_macos { $^O =~ /darwin/ }

push( @EXPORT, 'is_msw', 'is_macos' );

sub findexe {
    my ( $prog ) = @_;
    my @path;
    if ( MSWIN ) {
	$prog .= ".exe";
	@path = split( ';', $ENV{PATH} );
	unshift( @path, '.' );
    }
    else {
	@path = split( ':', $ENV{PATH} );
    }
    foreach ( @path ) {
	my $try = "$_/$prog";
	if ( -f -x $try ) {
	    #warn("Found $prog in $_\n");
	    return $try;
	}
    }
    warn("Could not find $prog in ",
	 join(" ", map { qq{"$_"} } @path), "\n");
    return;
}

push( @EXPORT, 'findexe' );

sub sys {
    my ( @cmd ) = @_;
    warn("+ @cmd\n") if $::options->{trace};
    # Use outer defined subroutine, depends on Wx or not.
    my $res = ::sys(@cmd);
    warn( sprintf("=%02x=> @cmd", $res), "\n" ) if $res;
    return $res;
}

push( @EXPORT, 'sys' );

1;
