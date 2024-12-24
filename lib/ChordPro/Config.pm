#! perl

package main;

our $options;
our $config;

package ChordPro::Config;

use v5.26;
use utf8;
use Carp;
use feature qw( signatures state );
no warnings "experimental::signatures";

use ChordPro;
use ChordPro::Paths;
use ChordPro::Utils;
use File::LoadLines;
use File::Spec;
use Scalar::Util qw(reftype);
use List::Util qw(any);
use Storable 'dclone';
use Hash::Util;
use Ref::Util qw( is_arrayref is_hashref );

#sub hmerge($$;$);
#sub clone($);
#sub default_config();

sub new ( $pkg, $cf = {} ) {
    bless $cf => $pkg;
}

sub pristine_config {
    use ChordPro::Config::Data;
    __PACKAGE__->new(ChordPro::Config::Data::config());
}

sub configurator ( $opts = undef ) {

    # Test programs call configurator without options.
    # Prepare a minimal config.
    unless ( $opts ) {
        my $cfg = pristine_config();
        $config = $cfg;
	$cfg->split_fc_aliases;
        $options = { verbose => 0 };
        process_config( $cfg, "<builtin>" );
        $cfg->{settings}->{lineinfo} = 0;
        return $cfg;
    }
    if ( keys(%$opts) ) {
        $options = { %{$options//{}}, %$opts };
    }

    my @cfg;
    my $verbose = $options->{verbose} //= 0;

    # Load defaults.
    warn("Reading: <builtin>\n") if $verbose > 1;
    my $cfg = pristine_config();

    # Default first.
    @cfg = prep_configs( $cfg, "<builtin>" );
    # Bubble default config to be the first.
    unshift( @cfg, pop(@cfg) ) if @cfg > 1;

    # Collect other config files.
    my $add_config = sub {
        my $fn = shift;
        $cfg = get_config( $fn );
        push( @cfg, $cfg->prep_configs($fn) );
    };

    foreach my $c ( qw( sysconfig userconfig config ) ) {
        next if $options->{"no$c"};
        if ( ref($options->{$c}) eq 'ARRAY' ) {
            $add_config->($_) foreach @{ $options->{$c} };
        }
        else {
            warn("Adding config for $c\n") if $verbose;
            $add_config->( $options->{$c} );
        }
    }

    # Now we have a list of all config files. Weed out dups.
    for ( my $a = 0; $a < @cfg; $a++ ) {
        if ( $a && $cfg[$a]->{_src} eq $cfg[$a-1]->{_src} ) {
            splice( @cfg, $a, 1 );
            redo;
        }
        warn("Config[$a]: ", $cfg[$a]->{_src}, "\n" )
          if $verbose;
    }

    $cfg = shift(@cfg);
    warn("Process: $cfg->{_src}\n") if $verbose > 1;

    # Presets.
    if ( $options->{reference} ) {
        $cfg->{user}->{name} = "chordpro";
        $cfg->{user}->{fullname} = ::runtimeinfo("short");
    }
    else {
        $cfg->{user}->{name} =
          lc( $ENV{USER} || $ENV{LOGNAME}
              || getlogin() || getpwuid($<) || "chordpro" );
        $cfg->{user}->{fullname} = eval { (getpwuid($<))[6] } || "";
    }

    # Add some extra entries to prevent warnings.
    for ( qw(title subtitle footer) ) {
        next if exists($cfg->{pdf}->{formats}->{first}->{$_});
        $cfg->{pdf}->{formats}->{first}->{$_} = "";
    }

    my $backend_configurator =
      UNIVERSAL::can( $options->{backend}, "configurator" );

    # Apply config files
    foreach my $new ( @cfg ) {
        my $file = $new->{_src}; # for diagnostics
        # Handle obsolete keys.
        if ( exists $new->{pdf}->{diagramscolumn} ) {
            $new->{pdf}->{diagrams}->{show} //= "right";
            delete $new->{pdf}->{diagramscolumn};
            warn("$file: pdf.diagramscolumn is obsolete, use pdf.diagrams.show instead\n");
        }
        if ( exists $new->{pdf}->{formats}->{default}->{'toc-title'} ) {
            $new->{toc}->{title} //= $new->{pdf}->{formats}->{default}->{'toc-title'};
            delete $new->{pdf}->{formats}->{default}->{'toc-title'};
            warn("$file: pdf.formats.default.toc-title is obsolete, use toc.title instead\n");
        }

        # Process.
        local $::config = dclone($cfg);
        process_config( $new, $file );
        # Merge final.
        $cfg = hmerge( $cfg, $new );
#	die("PANIC! Config merge error")
#	  unless UNIVERSAL::isa( $cfg->{settings}->{strict}, 'JSON::Boolean' );
    }

    # Handle defines from the command line.
    # $cfg = hmerge( $cfg, prp2cfg( $options->{define}, $cfg ) );
    prpadd2cfg( $cfg, %{$options->{define}} );

    # Sanitize added extra entries.
    for my $format ( qw(title subtitle footer) ) {
        delete($cfg->{pdf}->{formats}->{first}->{$format})
          if ($cfg->{pdf}->{formats}->{first}->{$format} // 1) eq "";
        for my $c ( qw(title first default filler) ) {
	    for my $class ( $c, $c."-even" ) {
		my $t = $cfg->{pdf}->{formats}->{$class}->{$format};
		# Allowed: null, false, [3], [[3], ...].
		next unless defined $t;
		$cfg->{pdf}->{formats}->{$class}->{$format} = ["","",""], next
		  unless $t;
		die("Config error in pdf.formats.$class.$format: not an array\n")
		  unless is_arrayref($t);
		$t = [ $t ] unless is_arrayref($t->[0]);
		for ( @$t) {
		    die("Config error in pdf.formats.$class.$format: ",
			scalar(@$_), " fields instead of 3\n")
		      if @$_ && @$_ != 3;
		}
		$cfg->{pdf}->{formats}->{$class}->{$format} = $t;
	    }
        }
    }

    if ( $cfg->{pdf}->{fontdir} ) {
        my @a;
        if ( ref($cfg->{pdf}->{fontdir}) eq 'ARRAY' ) {
            @a = @{ $cfg->{pdf}->{fontdir} };
        }
        else {
            @a = ( $cfg->{pdf}->{fontdir} );
        }
        $cfg->{pdf}->{fontdir} = [];
        my $split = $^O =~ /^MS*/ ? qr(;) : qr(:);
        foreach ( @a ) {
            push( @{ $cfg->{pdf}->{fontdir} },
                  map { expand_tilde($_) } split( $split, $_ ) );
        }
    }
    else {
        $cfg->{pdf}->{fontdir} = [];
    }

    my @allfonts = keys(%{$cfg->{pdf}->{fonts}});
    for my $ff ( @allfonts ) {
	# Derived chords can have size or color only. Disable
	# this test for now.
        unless ( 1 || $cfg->{pdf}->{fonts}->{$ff}->{name}
                 || $cfg->{pdf}->{fonts}->{$ff}->{description}
                 || $cfg->{pdf}->{fonts}->{$ff}->{file} ) {
            delete( $cfg->{pdf}->{fonts}->{$ff} );
            next;
        }
        $cfg->{pdf}->{fonts}->{$ff}->{color}      //= "foreground";
        $cfg->{pdf}->{fonts}->{$ff}->{background} //= "background";
        for ( qw(name file description size) ) {
            delete( $cfg->{pdf}->{fonts}->{$ff}->{$_} )
              unless defined( $cfg->{pdf}->{fonts}->{$ff}->{$_} );
        }
    }

    if ( defined $options->{diagrams} ) {
        warn( "Invalid value for diagrams: ",
              $options->{diagrams}, "\n" )
          unless $options->{diagrams} =~ /^(all|none|user)$/i;
        $cfg->{diagrams}->{show} = lc $options->{'diagrams'};
    }
    elsif ( defined $options->{'user-chord-grids'} ) {
        $cfg->{diagrams}->{show} =
          $options->{'user-chord-grids'} ? "user" : 0;
    }
    elsif ( defined $options->{'chord-grids'} ) {
        $cfg->{diagrams}->{show} =
          $options->{'chord-grids'} ? "all" : 0;
    }

    for ( qw( transpose transcode decapo lyrics-only strict ) ) {
        next unless defined $options->{$_};
        $cfg->{settings}->{$_} = $options->{$_};
    }

    for ( "front-matter", "back-matter" ) {
        next unless defined $options->{$_};
        $cfg->{pdf}->{$_} = $options->{$_};
    }

    if ( defined $options->{'chord-grids-sorted'} ) {
        $cfg->{diagrams}->{sorted} = $options->{'chord-grids-sorted'};
    }

    # For convenience...
    bless( $cfg, __PACKAGE__ );

    return $cfg if $options->{'cfg-print'};

    # Backend specific configs.
    $backend_configurator->($cfg) if $backend_configurator;

    # Locking the hash is mainly for development.
    $cfg->lock;

    if ( $options->{verbose} > 1 ) {
        my $cp = ChordPro::Chords::get_parser() // "";
        warn("Parsers:\n");
        while ( my ($k, $v) = each %{ChordPro::Chords::Parser->parsers} ) {
            warn( "  $k",
                  $v eq $cp ? " (active)": "",
                  "\n");
        }
    }

    return $cfg;
}

# Get the decoded contents of a single config file.
sub get_config ( $file ) {
    Carp::confess("FATAL: Undefined config") unless defined $file;
    my $verbose = $options->{verbose};
    warn("Reading: $file\n") if $verbose > 1;
    $file = expand_tilde($file);

    if ( $file =~ /\.json$/i ) {
        if ( open( my $fd, "<:raw", $file ) ) {
            my $new = json_load( loadlines( $fd, { split => 0 } ), $file );
            precheck( $new, $file );
            close($fd);
            return __PACKAGE__->new($new);
        }
        else {
            die("Cannot open config $file [$!]\n");
        }
    }
    elsif ( $file =~ /\.prp$/i ) {
        if ( -e -f -r $file ) {
            require ChordPro::Config::Properties;
            my $cfg = Data::Properties->new;
            $cfg->parse_file($file);
            return __PACKAGE__->new($cfg->data);
        }
        else {
            die("Cannot open config $file [$!]\n");
        }
    }
    else {
        Carp::confess("Unrecognized config type: $file\n");
    }
}

# Check config for includes, and prepend them.
sub prep_configs ( $cfg, $src ) {
    $cfg->{_src} = $src;

    my @res;

    # If there are includes, add them first.
    my ( $vol, $dir, undef ) = File::Spec->splitpath($cfg->{_src});
    foreach my $c ( @{ $cfg->{include} } ) {
        # Check for resource names.
        if ( $c !~ m;[/.]; ) {
            $c = CP->findcfg($c);
        }
        elsif ( $dir ne ""
                && !File::Spec->file_name_is_absolute($c) ) {
            # Prepend dir of the caller, if needed.
            $c = File::Spec->catpath( $vol, $dir, $c );
        }
        my $cfg = get_config($c);
        # Recurse.
        push( @res, $cfg->prep_configs($c) );
    }

    # Push this and return.
    $cfg->split_fc_aliases;
    $cfg->expand_font_shortcuts;
    push( @res, $cfg );
    return @res;
}

sub process_config ( $cfg, $file ) {
    my $verbose = $options->{verbose};

    warn("Process: $file\n") if $verbose > 1;

    if ( $cfg->{tuning} ) {
        my $res =
          ChordPro::Chords::set_tuning( $cfg );
        warn( "Invalid tuning in config: ", $res, "\n" ) if $res;
        $cfg->{_tuning} = $cfg->{tuning};
        $cfg->{tuning} = [];
    }

    ChordPro::Chords::reset_parser;
    ChordPro::Chords::Parser->reset_parsers;
    local $::config = dclone(hmerge( $::config, $cfg ));
    if ( $cfg->{chords} ) {
        ChordPro::Chords::push_parser($cfg->{notes}->{system});
        my $c = $cfg->{chords};
        if ( @$c && $c->[0] eq "append" ) {
            shift(@$c);
        }
        foreach ( @$c ) {
            my $res =
              ChordPro::Chords::add_config_chord($_);
            warn( "Invalid chord in config: ",
                  $_->{name}, ": ", $res, "\n" ) if $res;
        }
        if ( $verbose > 1 ) {
            warn( "Processed ", scalar(@$c), " chord entries\n");
            warn( "Totals: ",
                  ChordPro::Chords::chord_stats(), "\n" );
        }
        $cfg->{_chords} = delete $cfg->{chords};
        ChordPro::Chords::pop_parser();
    }
    $cfg->split_fc_aliases;
    $cfg->expand_font_shortcuts;
}

# Expand pdf.fonts.foo: bar to pdf.fonts.foo { description: bar }.

sub expand_font_shortcuts ( $cfg ) {
    return unless exists $cfg->{pdf}->{fonts};
    for my $f ( keys %{$cfg->{pdf}->{fonts}} ) {
	next if ref($cfg->{pdf}->{fonts}->{$f}) eq 'HASH';
	for ( $cfg->{pdf}->{fonts}->{$f} ) {
	    my $v = $_;
	    my $i = {};
	    # Break out size.
	    if ( $v =~ /(.*?)(?:\s+(\d+(?:\.\d+)?))?$/ ) {
		$i->{size} = $2 if $2;
		$v = $1;
	    }
	    # Check for filename.
	    if ( $v =~ /^.*\.(ttf|otf)$/i ) {
		$i->{file} = $v;
	    }
	    # Check for corefonts.
	    elsif ( is_corefont($v) ) {
		$i->{name} = is_corefont($v);
	    }
	    else {
		$i->{description} = $v;
		$i->{description} .= " " . delete($i->{size})
		  if $i->{size};
	    }
	    $_ = $i;
	}
    }
}

use Storable qw(dclone);

# Split fontconfig aliases into separate entries.

sub split_fc_aliases ( $cfg ) {

    if ( $cfg->{pdf}->{fontconfig} ) {
	# Orig.
	my $fc = $cfg->{pdf}->{fontconfig};
	# Since we're going to delete/insert keys, we need a copy.
	my %fc = %$fc;
	while ( my($k,$v) = each(%fc) ) {
	    # Split on comma.
	    my @k = split( /\s*,\s*/, $k );
	    if ( @k > 1 ) {
		# We have aliases. Delete the original.
		delete( $fc->{$k} );
		# And insert individual entries.
		$fc->{$_} = dclone($v) for @k;
	    }
	}
    }
}

# Reverse of config_expand_font_shortcuts.

sub simplify_fonts( $cfg ) {

    return $cfg unless $cfg->{pdf}->{fonts};

    foreach my $font ( keys %{$cfg->{pdf}->{fonts}} ) {
	for ( $cfg->{pdf}->{fonts}->{$font} ) {
	    next unless is_hashref($_);

	    delete $_->{color}
	      if $_->{color} && $_->{color} eq "foreground";
	    delete $_->{background}
	      if $_->{background} && $_->{background} eq "background";

	    if ( exists( $_->{file} ) ) {
		delete $_->{description};
		delete $_->{name};
	    }
	    elsif ( exists( $_->{description} ) ) {
		delete $_->{name};
		if ( $_->{size} && $_->{description} !~ /\s+[\d.]+$/ ) {
		    $_->{description} .= " " . $_->{size};
		}
		delete $_->{size};
		$_ = $_->{description} if keys %$_ == 1;
	    }
	    elsif ( exists( $_->{name} )
		    && exists( $_->{size})
		    && keys %$_ == 2
		  ) {
		$_ = $_->{name} .= " " . $_->{size};
	    }
	}
    }
}

sub config_final ( %args ) {
    my $delta   = $args{delta} || 0;
    my $default = $args{default} || 0;
    $options->{'cfg-print'} = 1;

    my $defcfg;			# pristine config
    my $cfg;			# actual config
    if ( $default || $delta ) {
	local $options->{nosysconfig} = 1;
	local $options->{nouserconfig} = 1;
	local $options->{noconfig} = 1;
	$defcfg = pristine_config();
	split_fc_aliases($defcfg);
	expand_font_shortcuts($defcfg);
	if ( $delta ) {
	    delete $defcfg->{chords};
	    delete $defcfg->{include};
	}
	bless $defcfg => __PACKAGE__;
	$cfg = $defcfg if $default;
    }

    $cfg //= configurator($options);

    # Remove unwanted data.
    $cfg->unlock;
    $cfg->{tuning} = delete $cfg->{_tuning};
    if ( $delta ) {
	for ( qw( tuning ) ) {
	    delete($cfg->{$_}) unless defined($cfg->{$_});
	}
	for my $f ( keys( %{$cfg->{pdf}{fonts}} ) ) {
	    for ( qw( background color ) ) {
		next if defined($defcfg->{pdf}{fonts}{$f}{$_});
		delete($cfg->{pdf}{fonts}{$f}{$_});
		delete($defcfg->{pdf}{fonts}{$f}{$_});
	    }
	}
    }
    delete $cfg->{_chords};
    delete $cfg->{chords};
    delete $cfg->{_src};

    my $parser = JSON::Relaxed::Parser->new( key_order => 1 );

    # Load schema.
    my $schema = do {
	my $schema = CP->findres( "config.schema", class => "config" );
	my $data = loadlines( $schema, { split => 0 } );
	$parser->decode($data);
    };

    # Delta cannot handle reference config yet.
    if ( $delta ) {
	$defcfg->unlock;
	$cfg->reduce( $defcfg );
	return $parser->encode( data => {%$cfg},
				pretty => 1, schema => $schema );
    }

    my $config = do {
	my $config = CP->findres( "chordpro.json", class => "config" );
	my $data = loadlines( $config, { split => 0 } );
	$parser->decode($data);
    };

    #    $cfg = hmerge( $config, $cfg );
    $cfg->simplify_fonts;
    return $parser->encode( data => {%{$cfg}},
			    pretty => 1, schema => $schema );
}

sub convert_config ( $from, $to ) {
    # This is a completely independent function.

    # Establish a key order retaining parser.
    my $parser = JSON::Relaxed::Parser->new( key_order => 1 );

    # First find and process the schema.
    my $schema = CP->findres( "config.schema", class => "config" );
    my $o = { split => 0, fail => 'soft' };
    my $data = loadlines( $schema, $o );
    die("$schema: ", $o->{error}, "\n") if $o->{error};
    $schema = $parser->decode($data);

    # Then load the config to be converted.
    my $new;
    $o = { split => 0, fail => 'soft' };
    $data = loadlines( $from, $o );
    die("Cannot open config $from [", $o->{error}, "]\n") if $o->{error};

    if ( $data =~ /^\s*#/m ) {	# #-comments -> prp
	require ChordPro::Config::Properties;
	my $cfg = Data::Properties->new;
	$cfg->parse_file($from);
	$new = $cfg->data;
    }
    else {			# assume JSON, RJSON, RRJSON
	$new = $parser->decode($data);
    }

    # And re-encode it using the schema.
    my $res = $parser->encode( data => $new, pretty => 1,
			       nounicodeescapes => 1, schema => $schema );

    # Add trailer.
    $res .= "\n// End of Config.\n";

    # Write if out.
    if ( $to && $to ne "-" ) {
	open( my $fd, '>', $to )
	  or die("$to: $!\n");
	print $fd $res;
	$fd->close;
    }
    else {
	print $res;
    }

    1;
}

# Config in properties format.

sub cfg2props ( $o, $path = "" ) {
    $path //= "";
    my $ret = "";
    if ( !defined $o ) {
        $ret .= "$path: undef\n";
    }
    elsif ( is_hashref($o) ) {
        $path .= "." unless $path eq "";
        for ( sort keys %$o ) {
            $ret .= cfg2props( $o->{$_}, $path . $_  );
        }
    }
    elsif ( is_arrayref($o) ) {
        $path .= "." unless $path eq "";
        for ( my $i = 0; $i < @$o; $i++ ) {
            $ret .= cfg2props( $o->[$i], $path . "$i" );
        }
    }
    elsif ( $o =~ /^\d+$/ ) {
        $ret .= "$path: $o\n";
    }
    else {
        $o =~ s/\\/\\\\/g;
        $o =~ s/"/\\"/g;
        $o =~ s/\n/\\n/;
        $o =~ s/\t/\\t/;
        $o =~ s/([^\x00-\xff])/sprintf("\\x{%x}", ord($1))/ge;
        $ret .= "$path: \"$o\"\n";
    }

    return $ret;
}

# Locking/unlocking. Locking the hash is mainly for development, to
# trap accidental modifications and typos.

sub lock ( $self ) {
    Hash::Util::lock_hashref_recurse($self);
}

sub unlock ( $self ) {
    Hash::Util::unlock_hashref_recurse($self);
}

sub is_locked ( $self ) {
    Hash::Util::hashref_locked($self);
}

# Augment / Reduce.

sub augment ( $self, $hash ) {

    my $locked = $self->is_locked;
    $self->unlock if $locked;

    $self->_augment( $hash, "" );

    $self->lock if $locked;

    $self;
}


sub _augment ( $self, $hash, $path ) {

    for my $key ( keys(%$hash) ) {

        warn("Config augment error: unknown item $path$key\n")
          unless exists $self->{$key}
            || $path =~ /^pdf\.(?:info|fonts|fontconfig)\./
            || $path =~ /^pdf\.formats\.\w+-even\./
            || $path =~ /^meta\./
            || $key =~ /^_/;

        # Hash -> Hash.
        # Hash -> Array.
        if ( ref($hash->{$key}) eq 'HASH' ) {
            if ( ref($self->{$key}) eq 'HASH' ) {

                # Hashes. Recurse.
                _augment( $self->{$key}, $hash->{$key}, "$path$key." );
            }
            elsif ( ref($self->{$key}) eq 'ARRAY' ) {

                # Hash -> Array.
                # Update single array element using a hash index.
                foreach my $ix ( keys(%{$hash->{$key}}) ) {
                    die unless $ix =~ /^\d+$/;
                    $self->{$key}->[$ix] = $hash->{$key}->{$ix};
                }
            }
            else {
                # Overwrite.
                $self->{$key} = $hash->{$key};
            }
        }

        # Array -> Array.
        elsif ( ref($hash->{$key}) eq 'ARRAY'
                and ref($self->{$key}) eq 'ARRAY' ) {

            # Arrays. Overwrite or append.
            if ( @{$hash->{$key}} ) {
                my @v = @{ $hash->{$key} };
                if ( $v[0] eq "append" ) {
                    shift(@v);
                    # Append the rest.
                    push( @{ $self->{$key} }, @v );
                }
                elsif ( $v[0] eq "prepend" ) {
                    shift(@v);
                    # Prepend the rest.
                    unshift( @{ $self->{$key} }, @v );
                }
                else {
                    # Overwrite.
                    $self->{$key} = $hash->{$key};
                }
            }
            else {
                # Overwrite.
                $self->{$key} = $hash->{$key};
            }
        }

        else {
            # Overwrite.
            $self->{$key} = $hash->{$key};
        }
    }

    $self;
}

use constant DEBUG => 0;

sub reduce ( $self, $hash ) {

    my $locked = $self->is_locked;

    warn("O: ", qd($hash,1), "\n") if DEBUG > 1;
    warn("N: ", qd($self,1), "\n") if DEBUG > 1;
    my $state = _reduce( $self, $hash, "" );

    $self->lock if $locked;

    warn("== ", qd($self,1), "\n") if DEBUG > 1;
    return $self;
}

sub _ref ( $self ) {
    reftype($self) // ref($self);
}

sub _reduce ( $self, $orig, $path ) {

    my $state;

    if ( _ref($self) eq 'HASH' && _ref($orig) eq 'HASH' ) {

        warn("D: ", qd($self,1), "\n")  if DEBUG && !%$orig;
        return 'D' unless %$orig;

        my %hh = map { $_ => 1 } keys(%$self), keys(%$orig);
        for my $key ( sort keys(%hh) ) {

            warn("Config reduce error: unknown item $path$key\n")
              unless exists $self->{$key}
                || $key =~ /^_/
                || $path =~ /^pdf\/\.fonts\./;

            unless ( exists $orig->{$key} ) {
                warn("D: $path$key\n") if DEBUG;
                delete $self->{$key};
                $state //= 'M';
                next;
            }

            # Hash -> Hash.
            if (     _ref($orig->{$key}) eq 'HASH'
                 and _ref($self->{$key}) eq 'HASH'
                 or
                     _ref($orig->{$key}) eq 'ARRAY'
                 and _ref($self->{$key}) eq 'ARRAY' ) {
                # Recurse.
                my $m = _reduce( $self->{$key}, $orig->{$key}, "$path$key." );
                delete $self->{$key} if $m eq 'D' || $m eq 'I';
                $state //= 'M' if $m ne 'I';
            }

            elsif ( ($self->{$key}//'') eq ($orig->{$key}//'') ) {
                warn("I: $path$key\n") if DEBUG;
                delete $self->{$key};
            }
            elsif (     !defined($self->{$key})
                    and _ref($orig->{$key}) eq 'ARRAY'
                    and !@{$orig->{$key}}
                    or
                        !defined($orig->{$key})
                    and _ref($self->{$key}) eq 'ARRAY'
                    and !@{$self->{$key}} ) {
                # Properties input [] yields undef.
                warn("I: $path$key\n") if DEBUG;
                delete $self->{$key};
            }
            else {
                # Overwrite.
                warn("M: $path$key => $self->{$key}\n") if DEBUG;
                $state //= 'M';
            }
        }
        return $state // 'I';
    }

    if ( _ref($self) eq 'ARRAY' && _ref($orig) eq 'ARRAY' ) {

        # Arrays.
        if ( any { _ref($_) } @$self ) {
            # Complex arrays. Recurse.
            for ( my $key = 0; $key < @$self; $key++ ) {
                my $m = _reduce( $self->[$key], $orig->[$key], "$path$key." );
                #delete $self->{$key} if $m eq 'D'; # TODO
                $state //= 'M' if $m ne 'I';
            }
            return $state // 'I';
        }

        # Simple arrays (only scalar values).
        if ( my $dd = @$self - @$orig ) {
            $path =~ s/\.$//;
            if ( $dd > 0 ) {
                # New is larger. Check for prepend/append.
                # Deal with either one, not both. Maybe later.
                my $t;
                for ( my $ix = 0; $ix < @$orig; $ix++ ) {
                    next if $orig->[$ix] eq $self->[$ix];
                    $t++;
                    last;
                }
                unless ( $t ) {
                    warn("M: $path append @{$self}[-$dd..-1]\n") if DEBUG;
                    splice( @$self, 0, $dd, "append" );
                    return 'M';
                }
                undef $t;
                for ( my $ix = $dd; $ix < @$self; $ix++ ) {
                    next if $orig->[$ix-$dd] eq $self->[$ix];
                    $t++;
                    last;
                }
                unless ( $t ) {
                    warn("M: $path prepend @{$self}[0..$dd-1]\n") if DEBUG;
                    splice( @$self, $dd );
                    unshift( @$self, "prepend" );
                    return 'M';
                }
                warn("M: $path => @$self\n") if DEBUG;
                $state = 'M';
            }
            else {
                warn("M: $path => @$self\n") if DEBUG;
                $state = 'M';
            }
            return $state // 'I';
        }

        # Equal length arrays with scalar values.
        my $t;
        for ( my $ix = 0; $ix < @$orig; $ix++ ) {
            next if $orig->[$ix] eq $self->[$ix];
            warn("M: $path$ix => $self->[$ix]\n") if DEBUG;
            $t++;
            last;
        }
        if ( $t ) {
            warn("M: $path\n") if DEBUG;
            return 'M';
        }
        warn("I: $path\[]\n") if DEBUG;
        return 'I';
    }

    # Two scalar values.
    $path =~ s/\.$//;
    if ( $self eq $orig ) {
        warn("I: $path\n") if DEBUG;
        return 'I';
    }

    warn("M $path $self\n") if DEBUG;
    return 'M';
}

sub hmerge( $left, $right, $path = "" ) {

    # Merge hashes. Right takes precedence.
    # Based on Hash::Merge::Simple by Robert Krimen.

    my %res = %$left;

    for my $key ( keys(%$right) ) {

        warn("Config error: unknown item $path$key\n")
          unless exists $res{$key}
            || $path eq "pdf.fontconfig."
            || $path =~ /^pdf\.(?:info|fonts)\./
            || $path =~ /^pdf\.formats\.\w+-even\./
            || $path =~ /^meta\./
            || $path =~ /^delegates\./
            || $path =~ /^parser\.preprocess\./
            || $path =~ /^debug\./
            || $key =~ /^_/;

        if ( ref($right->{$key}) eq 'HASH'
             and
             ref($res{$key}) eq 'HASH' ) {
            # Hashes. Recurse.
            $res{$key} = hmerge( $res{$key}, $right->{$key}, "$path$key." );
        }
        elsif ( ref($right->{$key}) eq 'ARRAY'
                and
                ref($res{$key}) eq 'ARRAY' ) {
            warn("AMERGE $key: ",
                 join(" ", map { qq{"$_"} } @{ $res{$key} }),
                 " + ",
                 join(" ", map { qq{"$_"} } @{ $right->{$key} }),
                 " \n") if 0;
            # Arrays. Overwrite or append.
            if ( @{$right->{$key}} ) {
                my @v = @{ $right->{$key} };
                if ( $v[0] eq "append" ) {
                    shift(@v);
                    # Append the rest.
                    warn("PRE: ",
                         join(" ", map { qq{"$_"} } @{ $res{$key} }),
                         " + ",
                         join(" ", map { qq{"$_"} } @v),
                         "\n") if 0;
                    push( @{ $res{$key} }, @v );
                    warn("POST: ",
                         join(" ", map { qq{"$_"} } @{ $res{$key} }),
                         "\n") if 0;
                }
                elsif ( $v[0] eq "prepend" ) {
                    shift(@v);
                    # Prepend the rest.
                    unshift( @{ $res{$key} }, @v );
                }
                else {
                    # Overwrite.
                    $res{$key} = $right->{$key};
                }
            }
            else {
                # Overwrite.
                $res{$key} = $right->{$key};
            }
        }
        else {
            # Overwrite.
            $res{$key} = $right->{$key};
        }
    }

    return \%res;
}

sub clone ( $source ) {

    return if not defined($source);

    use Storable;
    my $clone = Storable::dclone($source);
    $clone->unlock;
    return $clone;

}

sub precheck ( $cfg, $file ) {

    my $verbose = $options->{verbose};
    warn("Verify config \"$file\"\n") if $verbose > 1;
    my $p;
    $p = sub {
        my ( $o, $path ) = @_;
        $path //= "";
        if ( is_hashref($o) ) {
            $path .= "." unless $path eq "";
            for ( sort keys %$o ) {
                $p->( $o->{$_}, $path . $_  );
            }
        }
        elsif ( is_arrayref($o) ) {
            $path .= "." unless $path eq "";
            for ( my $i = 0; $i < @$o; $i++ ) {
                $p->( $o->[$i], $path . "$i" );
            }
        }
    };

    $p->($cfg);
}


## Data::Properties compatible API.
#
# Note: Lookup always takes the context into account.
# Note: Always signals undefined values.

my $prp_context = "";

sub get_property ( $p, $prp, $def = undef ) {
    for ( split( /\./,
                 $prp_context eq ""
                 ? $prp
                 : "$prp_context.$prp" ) ) {
        if ( /^\d+$/ ) {
            die("No config $prp\n") unless _ref($p) eq 'ARRAY';
            $p = $p->[$_];
        }
        else {
            die("No config $prp\n") unless _ref($p) eq 'HASH';
            $p = $p->{$_};
        }
    }
    $p //= $def;
    die("No config $prp\n") unless defined $p;
    $p;
}

*gps = \&get_property;

sub set_property  {
    ...;
}

sub set_context ( $self, $ctx = "" ) {
    $prp_context = $ctx;
}

sub get_context () {
    $prp_context;
}

# For testing
use Exporter 'import';
our @EXPORT = qw( _c );
sub _c ( @args ) { $::config->gps(@args) }

# For convenience.
sub diagram_strings ( $self ) {
    # tuning is usually removed from the config.
    # scalar( @{ $self->{tuning} } );
    ChordPro::Chords::strings();
}

sub diagram_keys ( $self ) {
    $self->{kbdiagrams}->{keys};
}

# For debugging messages.
sub qd ( $val, $compact = 0 ) {
    use Data::Dumper qw();
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deparse   = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Trailingcomma = !$compact;
    local $Data::Dumper::Useperl = 1;
    local $Data::Dumper::Useqq     = 0; # I want unicode visible
    my $x = Data::Dumper::Dumper($val);
    if ( $compact ) {
        $x =~ s/^bless\( (.*), '[\w:]+' \)$/$1/s;
        $x =~ s/\s+/ /gs;
    }
    defined wantarray ? $x : warn($x,"\n");
}

1;
