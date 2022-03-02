#! perl

package App::Music::ChordPro::Utils;

use strict;
use warnings;
use utf8;
use parent qw(Exporter);

our @EXPORT;

################ Platforms ################

use constant MSWIN => $^O =~ /MSWin|Windows_NT/i ? 1 : 0;

sub is_msw   { MSWIN }
sub is_macos { $^O =~ /darwin/ }

push( @EXPORT, 'is_msw', 'is_macos' );

################ Filenames ################

use File::Glob ( $] >= 5.016 ? ":bsd_glob" : ":glob" );
use File::Spec;

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

sub findexe {
    my ( $prog ) = @_;
    my @path;
    if ( MSWIN ) {
	$prog .= ".exe" unless $prog =~ /\.\w+$/;
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

################ (Pre)Processing ################

sub make_preprocessor {
    my ( $prp ) = @_;
    return unless $prp;

    my $prep;
    foreach my $linetype ( keys %{ $prp } ) {
	my @targets;
	my $code;
	foreach ( @{ $prp->{$linetype} } ) {
	    if ( $_->{pattern} ) {
		push( @targets, $_->{pattern} );
		# Subsequent targets override.
		$code->{$_->{pattern}} = $_->{replace};
	    }
	    else {
		push( @targets, quotemeta($_->{target}) );
		# Subsequent targets override.
		$code->{quotemeta($_->{target})} = quotemeta($_->{replace});
	    }
	}
	if ( @targets ) {
	    my $t = "sub { for (\$_[0]) {\n";
	    $t .= "s\0" . $_ . "\0" . $code->{$_} . "\0g;\n" for @targets;
	    $t .= "}}";
	    $prep->{$linetype} = eval $t;
	    die( "CODE : $t\n$@" ) if $@;
	}
    }
    $prep;
}

push( @EXPORT, 'make_preprocessor' );

################ Utilities ################

# Split (pseudo) command line into key/value pairs.

sub parse_kv {
    my ( @lines ) = @_;

    use Text::ParseWords qw(shellwords);
    my @words = shellwords(@lines);

    my $res = {};
    foreach ( @words ) {
	if ( /^(.*?)=(.+)/ ) {
	    $res->{$1} = $2;
	}
	elsif ( /^no[-_]?(.+)/ ) {
	    $res->{$1} = 0;
	}
	else {
	    $res->{$_}++;
	}
    }

    return $res;
}

push( @EXPORT, 'parse_kv' );

1;
