#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class ChordPro::Paths;

my $instance;

method get :common ( $reset = 0 ) {
    undef $instance if $reset;
    $instance //= $class->new;
}

use Cwd qw(realpath);
use File::Spec::Functions qw( catfile catdir splitpath catpath file_name_is_absolute );
use File::HomeDir;

field $home      :reader;	# dir
field $configdir :reader;	# dir
field $privlib   :reader;	# dir
field $resdirs   :reader;	# [ dir, ... ]
field $configs   :reader;	# { config => dir, ... }
field $pathsep   :reader;	# : or ;

field $packager  :reader;

# Cwd::realpath always returns forward slashes.
# On Windows, Cwd::realpath always returns a volume.

BUILD {
    my $app = "ChordPro";
    my $app_lc = lc($app);

    $pathsep = $self->is_msw ? ';' : ':';

    $home     = realpath( $ENV{HOME} = File::HomeDir->my_home );

#    $desktop  = File::HomeDir->my_desktop;
#    $docs     = File::HomeDir->my_documents;
#    $music    = File::HomeDir->my_music;
#    $pics     = File::HomeDir->my_pictures;
#    $videos   = File::HomeDir->my_videos;
#    $data     = File::HomeDir->my_data;
#    $dist     = File::HomeDir->my_dist_data('ChordPro');
#    $dist     = File::HomeDir->my_dist_config('ChordPro');

    # Establish config files. Global config is easy.
    for ( $self->normalize("/etc/$app_lc.json") ) {
	next unless $_ && -f;
	$configs->{sysconfig} = $_;
    }

    $configs = {};
    # The user specific config requires some alternatives.
    # -d $XDG_CONFIG_HOME/$app_lc
    # -d ~/.config/$app_lc
    # -d ~/.$app_lc
    # -d my_dist_config
    my @try;
    if ( defined( $ENV{XDG_CONFIG_HOME} ) && $ENV{XDG_CONFIG_HOME} ne "" ) {
	push( @try,
	      # See https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
	      # catdir( $ENV{XDG_CONFIG_HOME}, ".config", $app_lc ),
	      # catdir( $ENV{XDG_CONFIG_HOME}, ".config" ),
	      # catdir( $ENV{XDG_CONFIG_HOME}, ".$app_lc" ) );
	      catdir( $ENV{XDG_CONFIG_HOME}, "$app_lc" ) );
    }
    else {
	push( @try,
	      catdir( $home, ".config", $app_lc ),
	      catdir( $home, ".$app_lc" ),
	      File::HomeDir->my_dist_config($app) );
    }

    for ( @try ) {
	next unless $_ && -d $_;
	my $path = $self->normalize($_);
	warn("Paths: configdir try $_ => $path\n") if $self->debug > 1;
	next unless $path && -d $path;
	$configdir = $path;
	for ( $self->normalize( catfile( $path, "$app_lc.prp" ) ),
	      $self->normalize( catfile( $path, "$app_lc.json" ) ) ) {
	    next unless $_ && -f $_;
	    $configs->{userconfig} = $_;
	    last;
	}
	last if $configdir;
    }
    warn("Paths: configdir = ", $configdir // "<undef>", "\n") if $self->debug;

    for ( $self->normalize(".$app_lc.json"),
	  $self->normalize("$app_lc.json") ) {
	    next unless $_ && -f $_;
	$configs->{config} = $_;
	last;
    }
    if ( $self->debug ) {
	for ( qw( sysconfig userconfig config ) ) {
	    warn(sprintf("Paths: %-10s = %s\n",
			 $_, $configs->{$_} // "<undef>" ) );
	}
    }

    # Private lib.
    $privlib = $INC{'ChordPro.pm'} =~ s/\.pm$/\/lib/r;

    # Now for the resources.
    $self->setup_resdirs;

    # Check for packaged image.
    for ( qw( Docker AppImage PPL ) ) {
	next unless exists $ENV{uc($_)."_PACKAGED"}
	  && $ENV{uc($_)."_PACKAGED"};
	$packager = $_;
	last;
    }

};

# We need this to be able to re-establish the resdirs, e.g. after a change
# of CHORDPRO_LIB.
method setup_resdirs {
    $resdirs = [];
    my @try = ();
    push( @try, $self->path($ENV{CHORDPRO_LIB}) )
      if defined($ENV{CHORDPRO_LIB});
    push( @try, $configdir ) if $configdir;
    push( @try, $INC{'ChordPro.pm'} =~ s/\.pm$/\/res/r );

    for ( @try ) {
	next unless $_;
	my $path = $self->normalize($_);
	warn("Paths: resdirs try $_ => $path\n") if $self->debug > 1;
	next unless $path && -d $path;
	push( @$resdirs, $path );
    }

    if ( $self->debug ) {
	for ( 0..$#{$resdirs} ) {
	    warn("Paths: resdirs[$_] = $resdirs->[$_]\n");
	}
    }

    unless ( @$resdirs ) {
	warn("Paths: Cannot find resources, prepare for disaster\n");
    }
}

method debug {
    # We need to take an env var into account, since the Paths
    # singleton is created far before any config processing.
    $ENV{CHORDPRO_DEBUG_PATHS} || $::config->{debug}->{paths} || 0;
}

method is_msw {
    $^O =~ /mswin/i;
}

# Is absolute.

method is_absolute ( $p ) {
    File::Spec->file_name_is_absolute( $p );
}

# Is bare (no volume/dir).

method is_here ( $p ) {
    my ( $v, $d, $f ) = splitpath($p);
    $v eq '' && $d eq '';
}

# Normalize - full path, forward slashes, ~ expanded.

method normalize ( $p, %opts ) {
    $p = $home . "/$1" if $p =~ /~[\\\/](.*)/;
    realpath($p)
}

# This is only used in ::runtimeinfo for display purposes.

method display ( $p ) {
    return "<undef>" unless defined $p;
    $p = $self->normalize($p);
    if ( index( $p, $home ) == 0 ) {
	substr( $p, 0, length($home), '~' );
    }
    return $p;
}

method path ( $p = undef ) {
    if ( defined($p) ) {
	local $ENV{PATH} = $p;
	my @p = File::Spec->path();
	# On MSWindows, '.' is always prepended.
	shift(@p) if $self->is_msw;
	return @p;
    }
    return File::Spec->path();
}

# Prepend dirs in front of path.

method pathprepend( @d ) {
    $ENV{PATH} = join( $pathsep, @d, $ENV{PATH} );
}

method pathcombine( @d ) {
    join( $pathsep, @d );
}

# Locate an executable file (program) using PATH.

method findexe ( $p, %opts ) {
    my $try = $p;
    my $found;
    if ( $self->is_msw ) {
	$try .= ".exe";
    }
    for ( $self->path ) {
	my $e = catfile( $_, $try );
	$found = realpath($e), last if -f -x $e;
    }
    warn("Paths: findexe $p => ", $self->display($found), "\n")
      if $self->debug;
    return $found;
}

# Locate a config file (prp or json) using respath.

method findcfg ( $p ) {
    my $found;
    my @p;
    if ( $p =~ /\.\w+$/ ) {
	$found = realpath($p) if -f -s $p;
	@p = ( $p );
    }
    else {
	$p =~ s/:+/\//g;
	@p = ( "$p.prp", "$p.json" );
    }
    unless ( $found ) {
	for ( @$resdirs ) {
	    for my $cfg ( @p ) {
		my $f = catfile( $_, "config", $cfg );
		$found = realpath($f), last if -f -s $f;
	    }
	}
    }
    warn("Paths: findcfg $p => ", $self->display($found), "\n")
      if $self->debug;
    return $found;
}

# Locate a resource file (optionally classified) using respath.

method findres ( $p, %opts ) {
    my $try = $p;
    my $found;
    if ( file_name_is_absolute($p) ) {
	$found = realpath($p);
    }
    else {
	if ( defined $opts{class} ) {
	    $try = catfile( $opts{class}, $try );
	}
	for ( @$resdirs ) {
	    my $f = catfile( $_, $try );
	    $found = realpath($f), last if -f -s $f;
	}
    }
    warn("Paths: findres", $opts{class} ? " [$opts{class}]" : "",
	 " $p => ", $self->display($found), "\n")
      if $self->debug;
    return $found;
}

# Locate resource directories (optionally classified) using respath.

method findresdirs ( $p, %opts ) {
    my $try = $p;
    my @found;
    if ( defined $opts{class} ) {
	$p = catdir( $opts{class}, $p );
    }
    for ( @$resdirs ) {
	my $d = catdir( $_, $p );
	push( @found, realpath($d) ) if -d $d;
    }
    if ( $self->debug ) {
	my $i = 0;
	@found = ( "<none>" ) unless @found;
	warn("Paths: findresdirs[",
	     $opts{class} ? "$opts{class}:" : "",
	     $i++, "]",
	     " $p => ", $self->display($_), "\n") for @found;
    }
    return \@found;
}

# Return the name of a sibling (i.e., same place, different name
# and/or extension).

method sibling ( $orig, %opts ) {
    # Split.
    my ( $v, $d, $f ) = splitpath($orig);
    my $res;
    if ( $opts{name} ) {
	$res = catpath( $v, $d, $opts{name} );
    }
    else {
	# Get base and extension.
	my ( $b, $e ) = $f =~ /^(.*)(?:\.(\w+))$/;
	# Adjust.
	$b = $opts{base} if defined $opts{base};
	$e = $opts{ext}  if defined $opts{ext};
	# New file name.
	$f = $b;
	$f .= $e if defined $e;
	# Join with path.
	$res = catpath( $v, $d, $f );
    }
    warn("Paths: sibling $orig => ", $self->display($res), "\n")
      if $self->debug;
    return $res;
}

# Given a file and a name, try name as a sibling, otherwise look it up.

method siblingres ( $orig, $name, %opts ) {
    return unless defined $orig;
    my $try = $self->sibling( $orig, name => $name );
    my $found = ( $try && -s $try )
      ? $try
      : $self->findres( $name, class => $opts{class} );
    return $found;
}

method packager_version {
    return unless $packager;
    $ENV{uc($packager)."_PACKAGED"};
}

################ Export ################

# For convenience.

use Exporter 'import';
our @EXPORT;

sub CP() { __PACKAGE__->get }

push( @EXPORT, 'CP' );

1;
