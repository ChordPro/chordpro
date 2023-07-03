#! perl

package ChordPro::Utils;

use v5.26;
use utf8;
use Carp;
use feature qw( signatures );
no warnings "experimental::signatures";
use parent qw(Exporter);

our @EXPORT;

################ Platforms ################

use constant MSWIN => $^O =~ /MSWin|Windows_NT/i ? 1 : 0;

sub is_msw ()   { MSWIN }
sub is_macos () { $^O =~ /darwin/ }

push( @EXPORT, 'is_msw', 'is_macos' );

################ Filenames ################

use File::Glob ( ":bsd_glob" );
use File::Spec;

# Derived from Path::ExpandTilde.

use constant BSD_GLOB_FLAGS => GLOB_NOCHECK | GLOB_QUOTE | GLOB_TILDE | GLOB_ERR
  # add GLOB_NOCASE as in File::Glob
  | ($^O =~ m/\A(?:MSWin32|VMS|os2|dos|riscos)\z/ ? GLOB_NOCASE : 0);

# File::Glob did not try %USERPROFILE% (set in Windows NT derivatives) for ~ before 5.16
use constant WINDOWS_USERPROFILE => MSWIN && $] < 5.016;

sub expand_tilde ( $dir ) {

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

sub findexe ( $prog ) {
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

sub sys ( @cmd ) {
    warn("+ @cmd\n") if $::options->{trace};
    # Use outer defined subroutine, depends on Wx or not.
    my $res = ::sys(@cmd);
    warn( sprintf("=%02x=> @cmd", $res), "\n" ) if $res;
    return $res;
}

push( @EXPORT, 'sys' );

################ (Pre)Processing ################

sub make_preprocessor ( $prp ) {
    return unless $prp;

    my $prep;
    foreach my $linetype ( keys %{ $prp } ) {
	my @targets;
	my $code = "";
	foreach ( @{ $prp->{$linetype} } ) {
	    my $flags = $_->{flags} // "g";
	    $code .= "m\0" . $_->{select} . "\0 && "
	      if $_->{select};
	    if ( $_->{pattern} ) {
		$code .= "s\0" . $_->{pattern} . "\0"
		  . $_->{replace} . "\0$flags;\n";
	    }
	    else {
		$code .= "s\0" . quotemeta($_->{target}) . "\0"
		  . quotemeta($_->{replace}) . "\0$flags;\n";
	    }
	}
	if ( $code ) {
	    my $t = "sub { for (\$_[0]) {\n" . $code . "}}";
	    $prep->{$linetype} = eval $t;
	    die( "CODE : $t\n$@" ) if $@;
	}
    }
    $prep;
}

push( @EXPORT, 'make_preprocessor' );

################ Utilities ################

# Split (pseudo) command line into key/value pairs.

sub parse_kv ( @lines ) {

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

# Map true/false etc to true / false.

sub is_true ( $arg ) {
    return if !defined($arg) || $arg eq '';
    return if $arg =~ /^(false|null|no|none|off|\s+|0)$/i;
    return !!$arg;
}

push( @EXPORT, 'is_true' );

# Stricter form of true.
sub is_ttrue ( $arg ) {
    return if !defined($arg);
    $arg =~ /^(on|true|1)$/i;
}

push( @EXPORT, 'is_ttrue' );

# Fix apos -> quote.

sub fq ( $arg ) {
    $arg =~ s/'/\x{2019}/g;
    $arg;
}

push( @EXPORT, 'fq' );

# Quote a string if needed unless forced.

sub qquote ( $arg, $force = 0 ) {
    for ( $arg ) {
	s/([\\\"])/\\$1/g;
	s/([[:^print:]])/sprintf("\\u%04x", ord($1))/ge;
	return $_ unless /[\\\s]/ || $force;
	return qq("$_");
    }
}

push( @EXPORT, 'qquote' );

# Turn foo.bar.blech=blah into { foo => { bar => { blech ==> "blah" } } }.

sub prp2cfg ( $defs, $cfg ) {
    my $ccfg = {};
    $cfg //= {};
    while ( my ($k, $v) = each(%$defs) ) {
	my @k = split( /[:.]/, $k );
	my $c = \$ccfg;		# new
	my $o = $cfg;		# current
	my $lk = pop(@k);	# last key

	# Step through the keys.
	foreach ( @k ) {
	    $c = \($$c->{$_});
	    $o = $o->{$_};
	}

	# Final key. Merge array if so.
	if ( $lk =~ /^\d+$/ && ref($o) eq 'ARRAY' ) {
	    unless ( ref($$c) eq 'ARRAY' ) {
		# Only copy orig values the first time.
		$$c->[$_] = $o->[$_] for 0..scalar(@{$o})-1;
	    }
	    $$c->[$lk] = $v;
	}
	else {
	    $$c->{$lk} = $v;
	}
    }
    return $ccfg;
}

push( @EXPORT, 'prp2cfg' );

# Remove markup.
sub demarkup ( $t ) {
    return join( '', grep { ! /^\</ } splitmarkup($t) );
}
push( @EXPORT, 'demarkup' );

# Split into markup/nonmarkup segments.
sub splitmarkup ( $t ) {
    my @t = split( qr;(</?(?:[-\w]+|span\s.*?)>);, $t );
    return @t;
}
push( @EXPORT, 'splitmarkup' );

# For conditional filling of hashes.
sub maybe ( $key, $value, @rest ) {
    if (defined $key and defined $value) {
	return ( $key, $value, @rest );
    }
    else {
	( defined($key) || @rest ) ? @rest : ();
    }
}
push( @EXPORT, "maybe" );

1;
