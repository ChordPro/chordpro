#! perl

package main;

our $options;
our $config;

package ChordPro::Config;

use v5.26;
use utf8;
use Carp;
use feature qw( signatures );
no warnings "experimental::signatures";

use ChordPro;
use ChordPro::Paths;
use ChordPro::Utils;
use File::LoadLines;
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(reftype);
use List::Util qw(any);
use Hash::Util;

=head1 NAME

ChordPro::Config - Configurator.

=head1 DESCRIPTION

This module first establishes a well-defined (builtin) configuration.

Then it processes the config files specified by the environment and
adds the information to the global $config hash.

The configurations files are 'relaxed' JSON files. This means that
they may contain comments and trailing comma's.

This module can be run standalone and will print the default config.

=encoding utf8

=cut

#sub hmerge($$;$);
#sub clone($);
#sub default_config();

sub configurator ( $opts = undef ) {
    my $pp = JSON::PP->new->relaxed;

    # Test programs call configurator without options.
    # Prepare a minimal config.
    unless ( $opts ) {
        my $cfg = $pp->decode( default_config() );
        $config = $cfg;
	config_split_fc_aliases($cfg);
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
    my $cfg = $pp->decode( default_config() );

    # This is easier than splitting out manually :)
    config_split_fc_aliases($cfg);

    # Default first.
    @cfg = prep_configs( $cfg, "<builtin>" );
    # Bubble default config to be the first.
    unshift( @cfg, pop(@cfg) ) if @cfg > 1;

    # Collect other config files.
    my $add_config = sub {
        my $fn = shift;
        $cfg = get_config( $fn );
        push( @cfg, prep_configs( $cfg, $fn ) );
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
        print STDERR ("Config[$a]: ", $cfg[$a]->{_src}, "\n" )
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
        local $::config = $cfg;
        process_config( $new, $file );
        # Merge final.
        $cfg = hmerge( $cfg, $new );
    }

    # Handle defines from the command line.
    $cfg = hmerge( $cfg, prp2cfg( $options->{define}, $cfg ) );

    # Sanitize added extra entries.
    for ( qw(title subtitle footer) ) {
        delete($cfg->{pdf}->{formats}->{first}->{$_})
          if ($cfg->{pdf}->{formats}->{first}->{$_} // 1) eq "";
        for my $class ( qw(title first default) ) {
            my $t = $cfg->{pdf}->{formats}->{$class}->{$_};
            next unless $t;
            die("Config error in pdf.formats.$class.$_: not an array\n")
              unless ref($t) eq 'ARRAY';
            if ( ref($t->[0]) ne 'ARRAY' ) {
                $t = [ $t ];
            }
            my $tt = $_;
            for ( @$t) {
                die("Config error in pdf.formats.$class.$tt: ",
                    scalar(@$_), " fields instead of 3\n")
                  if @$_ && @$_ != 3;
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
        unless ( $cfg->{pdf}->{fonts}->{$ff}->{name}
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
            my $pp = JSON::PP->new->relaxed;
            my $new = $pp->decode( loadlines( $fd, { split => 0 } ) );
            precheck( $new, $file );
            close($fd);
            return $new;
        }
        else {
            die("Cannot open config $file [$!]\n");
        }
    }
    elsif ( $file =~ /\.prp$/i ) {
        if ( -e -f -r $file ) {
            require ChordPro::Config::Properties;
            my $cfg = new Data::Properties;
            $cfg->parse_file($file);
            return $cfg->data;
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
        push( @res, prep_configs( $cfg, $c ) );
    }

    # Push this and return.
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
    local $::config = hmerge( $::config, $cfg );
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
    config_split_fc_aliases($cfg);
}

sub config_split_fc_aliases ( $cfg ) {
    # Split fontconfig aliases into individual entries.
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
		$fc->{$_} = $v for @k;
	    }
	}
    }
}

sub config_final ( $delta ) {
    $options->{'cfg-print'} = 1;
    my $cfg = configurator($options);

    if ( $delta ) {
        my $pp = JSON::PP->new->relaxed;
        my $def = $pp->decode( default_config() );
        $cfg->reduce($def);
    }
    $cfg->unlock;
    $cfg->{tuning} = delete $cfg->{_tuning};
    delete($cfg->{tuning}) if $delta && !defined($cfg->{tuning});
    $cfg->{chords} = delete $cfg->{_chords};
    delete $cfg->{chords};
    delete $cfg->{_src};
    $cfg->lock;

    if ( $ENV{CHORDPRO_CFGPROPS} ) {
        cfg2props($cfg);
    }
    else {
        my $pp = JSON::PP->new->canonical->indent(4)->pretty;
        $pp->encode({%$cfg});
    }
}

sub config_default () {
    if ( $ENV{CHORDPRO_CFGPROPS} ) {
        my $pp = JSON::PP->new->relaxed;
        my $cfg = $pp->decode( default_config() );
        cfg2props($cfg);
    }
    else {
        default_config();
    }
}

# Config in properties format.

sub cfg2props ( $o, $path = "" ) {
    $path //= "";
    my $ret = "";
    if ( !defined $o ) {
        $ret .= "$path: undef\n";
    }
    elsif ( UNIVERSAL::isa( $o, 'HASH' ) ) {
        $path .= "." unless $path eq "";
        for ( sort keys %$o ) {
            $ret .= cfg2props( $o->{$_}, $path . $_  );
        }
    }
    elsif ( UNIVERSAL::isa( $o, 'ARRAY' ) ) {
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

    warn("O: ", qd($hash,1), "\n") if DEBUG;
    warn("N: ", qd($self,1), "\n") if DEBUG;
    my $state = _reduce( $self, $hash, "" );

    $self->lock if $locked;

    warn("== ", qd($self,1), "\n") if DEBUG;
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
                || $key =~ /^_/;

            unless ( defined $orig->{$key} ) {
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
        if ( !defined $o ) {
            warn("$file: Undefined config \"$path\" (using 'false')\n");
            $_[0] = '';
        }
        elsif ( UNIVERSAL::isa( $o, 'HASH' ) ) {
            $path .= "." unless $path eq "";
            for ( sort keys %$o ) {
                $p->( $o->{$_}, $path . $_  );
            }
        }
        elsif ( UNIVERSAL::isa( $o, 'ARRAY' ) ) {
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

# Get the raw contents of the builtin (default) config.
sub default_config () {
    return <<'End_Of_Config';
// Configuration for ChordPro.
//
// This is a relaxed JSON document, so comments are possible.

{
    // Includes. These are processed first, before the rest of
    // the config file.
    //
    // "include" takes a list of either filenames or preset names.
    // "include" : [ "modern1", "lib/mycfg.json" ],
    "include" : [ "guitar" ],

    // General settings, often changed by configs and command line.
    "settings" : {
      // Strict behaviour.
      "strict" : true,
      // Obsolete -- lineinfo is always included.
      "lineinfo" : true,
      // Titles flush: default center.
      "titles" : "center",
      // Columns, default one.
      "columns" : 1,
      // Suppress empty chord lines.
      // Overrides the -a (--single-space) command line options.
      "suppress-empty-chords" : true,
      // Suppress blank lyrics lines.
      "suppress-empty-lyrics" : true,
      // Suppress chords.
      // Overrides --lyrics-only command line option.
      "lyrics-only" : false,
      // Memorize chords in sections, to be recalled by [^].
      "memorize" : false,
      // Chords inline.
      // May be a string containing pretext %s posttext.
      // Defaults to "[%s]" if set to a value that doesn't contain "%s".
      "inline-chords" : false,
      // Same, for annotations. Ignored unless inline-chords is set.
      // Must be a string containing pretext %s posttext.
      // Default is "%s".
      "inline-annotations" : "%s",
      // Chords under the lyrics.
      "chords-under" : false,
      // Transposing.
      "transpose" : 0,
      // Transcoding.
      "transcode" : "",
      // Always decapoize.
      "decapo" : false,
      // Chords parsing strategy.
      // Strict (only known) or relaxed (anything that looks sane).
      "chordnames": "strict",
      // Allow note names in [].
      "notenames" : false,
      // Always replace chords by their canonical form.
      "chords-canonical" : false,
      // If false, chorus labels are used as tags.
      "choruslabels" : true,
      // Substitute Unicode sharp/flats in chord names.
      // Will fallback to ChordProSymbols the font doesn't have the glyphs.
      "truesf" : false,
      // Amount of indent for wrapped lines. Actual indent is the stringwidth.
      "wrapindent" : "x",
      // Flow text. Do not use.
      "flowtext" : false,
    },

    // Metadata.
    // For these keys you can use {meta key ...} as well as {key ...}.
    // If strict is nonzero, only the keys named here are allowed.
    // If strict is zero, {meta ...} will accept any key.
    // Important: "title" and "subtitle" must always be in this list.
    // The separator is used to concatenate multiple values.
    // If autosplit is true, the separator is also used to split
    // values upon input.
    "metadata" : {
      "keys" : [ "title", "subtitle",
                 "artist", "composer", "lyricist", "arranger",
                 "album", "copyright", "year",
                 "sorttitle",
                 "key", "time", "tempo", "capo", "duration" ],
      "strict" : true,
      "separator" : "; ",
      "autosplit" : true,
    },
    // Globally defined (added) meta data,
    // This is explicitly NOT intended for the metadata items above.
    "meta" : {
        // Do not remove or change this one.
        "_configversion" : [ "6.031" ],
    },

    // Assets.
    "assets" : {
    },

    // Dates. Format is a strftime template.
    "dates" : {
        "today" : {
            "format" : "%A, %B %e, %Y"
        }
    },

    // User settings. These are usually set by a separate config file.
    //
    "user" : {
        "name"     : "",
        "fullname" : "",
    },

    // Instrument settings. These are usually set by a separate
    // config file.
    //
    "instrument" : {
        "type"     : "",
        "description" : "",
    },

    // Note (chord root) names.
    // Strings and tuning.
    "tuning" : [ "E2", "A2", "D3", "G3", "B3", "E4" ],

    // In case of alternatives, the first one is used for output.
    // Note that it is tempting to use real sharps and flats for output,
    // but most fonts don't have the glyphs :(.
    "notes" : {

      "system" : "common",

      "sharp" : [ "C", [ "C#", "Cis", "C♯" ],
                  "D", [ "D#", "Dis", "D♯" ],
                  "E",
                  "F", [ "F#", "Fis", "F♯" ],
                  "G", [ "G#", "Gis", "G♯" ],
                  "A", [ "A#", "Ais", "A♯" ],
                  "B",
                ],

      "flat" :  [ "C",
                  [ "Db", "Des",        "D♭" ], "D",
                  [ "Eb", "Es",  "Ees", "E♭" ], "E",
                  "F",
                  [ "Gb", "Ges",        "G♭" ], "G",
                  [ "Ab", "As",  "Aes", "A♭" ], "A",
                  [ "Bb", "Bes",        "B♭" ], "B",
                ],

       // Movable means position independent (e.g. nashville).
       "movable" : false,
    },

    // User defined chords.
    // "base" defaults to 1.
    // Use 0 for an empty string, and -1 for a muted string.
    // "fingers" is optional.
    // "display" (optional) can be used to change the way the chord is displayed. 
    "chords" : [
      //  {
      //    "name"  : "Bb",
      //    "base"  : 1,
      //    "frets" : [ 1, 1, 3, 3, 3, 1 ],
      //    "fingers" : [ 1, 1, 2, 3, 4, 1 ],
      //    "display" : "B<sup>\u266d</sup>",
      //  },
      // If the name of the first entry is "defaults" its properties may
      // be used as defaults for the rest of the chords.
    ],

      // Format to show chord names. May contain markup.
      // "chord-format" : "%{root}%{qual|%{}}%{ext|<sup>%{}</sup>}%{bass|/%{}}",
    "chord-formats" : {
        "common" :    "%{root|%{}%{qual|%{}}%{ext|%{}}%{bass|/%{}}|%{name}}",
        "roman" :     "%{root|%{}%{qual|<sup>%{}</sup>}%{ext|<sup>%{}</sup>}%{bass|/<sub>%{}</sub>}|%{name}}",
        "nashville" : "%{root|%{}%{qual|<sup>%{}</sup>}%{ext|<sup>%{}</sup>}%{bass|/<sub>%{}</sub>}|%{name}}",
    },

    // Printing chord diagrams.
    // "show": prints the chords used in the song.
    //         "all": all chords used.
    //         "user": only prints user defined chords.
    // "sorted": order the chords by key.
    // "suppress": a series of chord (names) that will not generate
    //         diagrams, e.g. if they are considered trivial.
    // Note: The type of diagram (string or keyboard) is determined
    // by the value of "instrument.type".
    "diagrams" : {
        "show"     :  "all",
        "sorted"   :  false,
        "suppress" :  [],
    },

    // Diagnostic messages.
    "diagnostics" : {
        "format" : "\"%f\", line %n, %m\n\t%l",
    },

    // Table of contents.
    "contents" : [
        { "fields"   : [ "songindex" ],
          "label"    : "Table of Contents",
          "line"     : "%{title}",
          "pageno"   : "%{page}",
          "fold"     : false,
          "omit"     : false,
          "template" : "stdtoc",
        },
        { "fields"   : [ "sorttitle", "artist" ],
          "label"    : "Contents by Title",
          "line"     : "%{title}%{artist| - %{}}",
          "pageno"   : "%{page}",
          "fold"     : false,
          "omit"     : false,
          "template" : "stdtoc",
        },
        { "fields"   : [ "artist", "sorttitle" ],
          "label"    : "Contents by Artist",
          "line"     : "%{artist|%{} - }%{title}",
          "pageno"   : "%{page}",
          "fold"     : false,
          "omit"     : true,
          "template" : "stdtoc",
        },
    ],
    // Table of contents, old style.
    // This will be ignored when new style contents is present.
    "toc" : {
        // Title for ToC.
        "title" : "Table of Contents",
        "line" : "%{title}",
        // Sorting order.
        // Currently only sorting by page number and alpha is implemented.
        "order" : "page",
    },

    // Delegates.
    // Basically a delegate is a section {start_of_XXX} which content is
    // collected and handled later by the delegate module.
    // Note: type = "none" treats the section as a generic section,
    // type = "omit" ignores the section.

    "delegates" : {
        "abc" : {
            "type"     : "image",
            "module"   : "ABC",
            "handler"  : "abc2svg",
            // No longer used -- ./default.abc will always be used if present
            "config"   : "default", // or "none", or "myformat.fmt"
            // The preamble is a list of lines inserted before the ABC data,
            // and after the delegate supplied preamble.
            // DO NOT MODIFY unless you know what you are doing!
            "preamble" : [
               // Use ChordPro fonts for lyrics and chords.
               "%%textfont pdf.fonts.text",
               "%%vocalfont pdf.fonts.text",
               "%%gchordfont pdf.fonts.chord",
            ],
            "preprocess" : { "abc" : [] },
        },
        "ly" : {
            "type"     : "image",
            "module"   : "Lilypond",
            "handler"  : "ly2svg",
            "config"   : "default", // or "none", or ...
            // The preamble is a list of lines inserted before the lilipond data.
            // This is a good place to set the version and global customizations.
            "preamble" : [
                "\\version \"2.21.0\"",
                "\\header { tagline = ##f }",
            ],
        },
        "svg" : {
            "type"     : "image",
            "module"   : "SVG",
            "handler"  : "svg2svg",
        },
        "textblock" : {
            "type"     : "image",
            "module"   : "TextBlock",
            "handler"  : "txt2xform",
        },
     },

    // Definitions for PDF output.

    "pdf" : {

      // Choose a PDF::API2 compatible library, or leave empty to
      // have ChordPro choose one for you.
      "library" : "",   // or "PDF::API2", or "PDF::Builder"

      // PDF Properties. Arbitrary key/values may be added.
      // Note that the context for substitutions is the first song.
      "info" : {
          "title"    : "%{title}",
          "author"   : "",
          "subject"  : "",
          "keywords" : "",
      },

      // Papersize, 'a4' or [ 595, 842 ] etc.
      "papersize" : "a4",

      "theme" : {
          // Forgeround color. Usually black.
          "foreground"        : "black",
          // Shades of grey.
          // medium is used for pressed keys in keyboard diagrams.
          "foreground-medium" : "grey70",
          // light is used as background for comments, cell bars, ...
          "foreground-light"  : "grey90",
          // Background color. Usually none or white.
          "background"        : "none",
      },

      // Space between columns, in pt.
      "columnspace"  :  20,

      // Page margins.
      // Note that top/bottom exclude the head/footspace.
      "margintop"    :  80,
      "marginbottom" :  40,
      "marginleft"   :  40,
      "marginright"  :  40,
      "headspace"    :  60,
      "footspace"    :  20,

      // Special: head on first page only, add the headspace to
      // the other pages so they become larger.
      "head-first-only" : false,

      // Spacings.
      // Baseline distances as a factor of the font size.
      "spacing" : {
          "title"  : 1.2,
          "lyrics" : 1.2,
          "chords" : 1.2,
          "diagramchords" : 1.2,
          "grid"   : 1.2,
          "tab"    : 1.0,
          "toc"    : 1.4,
          "empty"  : 1.0,
      },
      // Note: By setting the font size and spacing for empty lines to
      // smaller values, you get a fine(r)-grained control over the
      // spacing between the various parts of the song.

      // Style of chorus.
      "chorus" : {
          "indent"     :  0,
          // Chorus side bar.
          // Suppress by setting offset and/or width to zero.
          "bar" : {
              "offset" :  8,
              "width"  :  1,
              "color"  : "foreground",
          },
          "tag" : "Chorus",
          // Recall style: Print the tag using the type.
          // Alternatively quote the lines of the preceding chorus.
          "recall" : {
              "choruslike" : false,
              "tag"   : "Chorus",
              "type"  : "comment",
              "quote" : false,
          },
      },

      // This opens a margin for margin labels.
      "labels" : {
          // Margin width. Default is 0 (no margin labels).
          // "auto" will automatically reserve a margin if labels are used.
          "width" : "auto",
          // Alignment for the labels. Default is left.
          "align" : "left",
          // Alternatively, render labels as comments.
          "comment" : ""        // "comment", "comment_italic" or "comment_box",
      },

      // Alternative songlines with chords in a side column.
      // Value is the column position.
      // "chordscolumn" : 400,
      "chordscolumn" :  0,
      "capoheading" : "%{capo|Capo: %{}}",

      // A {titles: left} may conflict with customized formats.
      // Set to non-zero to ignore the directive.
      "titles-directive-ignore" : false,

      // Chord diagrams.
      // A chord diagram consists of a number of cells.
      // Cell dimensions are specified by "width" and "height".
      // The horizontal number of cells depends on the number of strings.
      // The vertical number of cells is "vcells", which should
      // be 4 or larger to accomodate most chords.
      // The horizontal distance between diagrams is "hspace" cells.
      // The vertical distance is "vspace" cells.
      // "linewidth" is the thickness of the lines as a fraction of "width".
      // Diagrams for all chords of the song can be shown at the
      // "top", "bottom" or "right" side of the first page,
      // or "below" the last song line.
      "diagrams" : {
          "show"     :  "bottom",
          "width"    :  6,      // width of a cell
          "height"   :  6,      // height of a cell
          "vcells"   :  4,      // vertical cells
          "linewidth" : 0.1,    // fraction of cell width
          "nutwidth" :  5,      // width (in linewidth) of the top nut
          "hspace"   :  3.95,   // fraction of width
          "vspace"   :  3,      // fraction of height
          "dotsize"  :  0.8,    // fraction of a cell
          "barwidth" :  0.8,    // fraction of a dot
          "fingers"  :  true,   // show fingering if available (or "below")
      },

      // Keyboard diagrams.
      // A keyboard diagram consists of a number of keys.
      // Dimensions are specified by "width" (a key) and "height".
      // The horizontal distance between diagrams is "hspace" * keys * width.
      // The vertical distance is "vspace" * height.
      // "linewidth" is the thickness of the lines as a fraction of "width".
      // Diagrams for all chords of the song can be shown at the
      // "top", "bottom" or "right" side of the first page,
      // or "below" the last song line.
      "kbdiagrams" : {
          "show"     :  "bottom",
          "width"    :   4,     // of a single key
          "height"   :  20,     // of the diagram
          "keys"     :  14,     // or 7, 10, 14, 17, 21
          "base"     :  "C",    // or "F"
          "linewidth" : 0.1,    // fraction of a single key width
          "pressed"  :  "foreground-medium",    // colour of a pressed key
          "hspace"   :  3.95,   // ??
          "vspace"   :  0.3,    // fraction of height
      },

      // Grid section lines.
      // Suppress when "show" is false, e.g. for singers.
      // The width and colour of the cell bar lines can be specified.
      // Enable by setting the width to the desired width.
      "grids" : {
          "cellbar" : {
              "width" : 0,
              "color" : "foreground-medium",
          },
          "show": true,
          "symbols" : {
              "color" : "blue",
          },
          "volta" : {
              "span" : 0.7,
              "color" : "blue",
          },
      },

      // Even/odd pages. A value of -1 denotes odd/even pages.
      "even-odd-pages" : 1,
      // Align songs to even/odd pages. When greater than 1, force alignment.
      "pagealign-songs" : 1,
      // PDF file to add as front matter.
      "front-matter" : "",
      // PDF file to add as back matter.
      "back-matter" : "",

      // Formats.
      // Pages have two title elements and one footer element. They also
      // can have a page of an existing PDF file as underlay (background).
      // Topmost is "title". It uses the "title" font as defined further below.
      // Second is "subtitle". It uses the "subtitle" font.
      // The "footer" uses the "footer" font.
      // All elements can have three fields, that are placed to the left side,
      // centered, and right side of the page.
      // The contents of all fields is defined below. You can use metadata
      // items in the fields as shown. By default, the "title" element shows the
      // value of metadata item "title", centered on the page. Likewise
      // "subtitle".
      // NOTE: The "title" and "subtitle" page elements have the same names
      // as the default metadata values which may be confusing. To show
      // metadata item, e.g. "artist", add its value to one of the
      // title/subtitle fields. Don't try to add an artist page element.

      "formats" : {
          // Titles/Footers.

          // Titles/footers have 3 parts, which are printed left,
          // centered and right.
          // For odd/even printing, the 1st background page is used
          // for left pages and the next page (if it exists) for right pages.
          // For even/odd printing, the order is reversed.

          // By default, a page has:
          "default" : {
              // No title/subtitle.
              "title"     : [ "", "", "" ],
              "subtitle"  : [ "", "", "" ],
              // Footer is title -- page number.
              "footer"    : [ "%{title}", "", "%{page}" ],
              // Background page.
              "background" : "",
          },
          // The first page of a song has:
          "title" : {
              // Title and subtitle.
              "title"     : [ "", "%{title}", "" ],
              "subtitle"  : [ "", "%{subtitle}", "" ],
              // Footer with page number.
              "footer"    : [ "", "", "%{page}" ],
              // Background page.
              "background" : "",
          },
          // The very first output page is slightly different:
          "first" : {
              // It has title and subtitle, like normal 'first' pages.
              // But no footer.
              "footer"    : [ "", "", "" ],
              // Background page.
              "background" : "",
          },
      },

      // Split marker for syllables that are smaller than chord width.
      // split-marker is a 3-part array: 'start', 'repeat', and 'final'.
      // 'final' is always printed, last.
      // 'start' is printed if there is enough room.
      // 'repeat' is printed repeatedly to fill the rest.
      // If split-marker is a single string, this is 'start'.
      // All elements may be left empty strings.
      "split-marker" : [ "", "", "" ],

      // Font families and properties.
      // "fontconfig" maps members of font families to physical fonts.
      // Optionally, additional properties of the fonts can be specified.
      // Physical fonts can be the names of TrueType/OpenType fonts,
      // or names of built-in fonts (corefonts).
      // Relative filenames are looked up in the fontdir.
      // "fontdir" : [ "/usr/share/fonts/liberation", "/home/me/fonts" ],

      "fontdir" : [],
      "fontconfig" : {
          "times, serif" : {
              ""            : "Times-Roman",
              "bold"        : "Times-Bold",
              "italic"      : "Times-Italic",
              "bolditalic"  : "Times-BoldItalic",
          },
          "helvetica" : {
              ""            : "Helvetica",
              "bold"        : "Helvetica-Bold",
              // Only helvetica uses oblique, use italic for all other fonts
              "oblique"     : "Helvetica-Oblique",
              "boldoblique" : "Helvetica-BoldOblique",
          },
          "sans, sans-serif" : {
              ""            : "Helvetica",
              "bold"        : "Helvetica-Bold",
              "italic"      : "Helvetica-Oblique",
              "bolditalic"  : "Helvetica-BoldOblique",
          },
          "courier, mono, monospace" : {
              ""            : "Courier",
              "bold"        : "Courier-Bold",
              "italic"      : "Courier-Italic",
              "bolditalic"  : "Courier-BoldItalic",
          },
          "dingbats" : {
              ""            : "ZapfDingbats",
          },
      },

      // "fonts" maps output elements to fonts as defined in "fontconfig".
      // The elements can have a background colour associated.
      // Colours are "#RRGGBB" or predefined names like "black", "white",
      // and lots of others.
      // NOTE: In the built-in config we use only "name" since that can
      // be overruled with user settings.

      "fonts" : {
          "title" : {
              "name" : "Times-Bold",
              "size" : 14
          },
          "text" : {
              "name" : "Times-Roman",
              "size" : 12
          },
          "chord" : {
              "name" : "Helvetica-Oblique",
              "size" : 10
          },
          "chordfingers" : {
              "file" : "ChordProSymbols.ttf",   // do not change
              "numbercolor" : "background",
          },
          "comment" : {
              "name" : "Helvetica",
              "size" : 12,
              "background" : "foreground-light"
          },
          "comment_italic" : {
              "name" : "Helvetica-Oblique",
              "size" : 12,
          },
          "comment_box" : {
              "name" : "Helvetica",
              "size" : 12,
              "frame" : 1
          },
          "tab" : {
              "name" : "Courier",
              "size" : 10
          },
          "toc" : {
              "name" : "Times-Roman",
              "size" : 11
          },
          "grid" : {
              "name" : "Helvetica",
              "size" : 10
          },
      },

      // Element mappings that can be specified, but need not since
      // they default to other elements.
      // subtitle       --> text
      // chorus         --> text
      // comment        --> text
      // comment_italic --> chord
      // comment_box    --> chord
      // annotation     --> chord
      // toc            --> text
      // grid           --> chord
      // grid_margin    --> comment
      // footer         --> subtitle @ 60%
      // empty          --> text
      // diagram        --> comment
      // diagram_base   --> text (but at a small size)

      // Bookmarks (PDF outlines).
      // fields:   primary and (optional) secondary fields.
      // label:    outline label (omitted if there's only one outline)
      // line:     text of the outline element
      // collapse: initial display is collapsed
      // letter:   sublevel with first letters if more
      // fold:     group by primary (NYI)
      // omit:     ignore this
      "outlines" : [
          { "fields"   : [ "sorttitle", "artist" ],
            "label"    : "By Title",
            "line"     : "%{title}%{artist| - %{}}",
            "collapse" : false,
            "letter"   : 5,
            "fold"     : false,
          },
          { "fields"   : [ "artist", "sorttitle" ],
            "label"    : "By Artist",
            "line"     : "%{artist|%{} - }%{title}",
            "collapse" : false,
            "letter"   : 5,
            "fold"     : false,
          },
      ],

      // This will show the page layout if non-zero.
      "showlayout" : false,

      // CSV generation for MobileSheetsPro. Adapt for other tools.
      // Note that the resultant file will conform to RFC 4180.
      "csv" : {
          "fields" : [
              { "name" : "title",        "meta" : "title"      },
              { "name" : "pages",        "meta" : "pagerange"  },
              { "name" : "sort title",   "meta" : "sorttitle"  },
              { "name" : "artists",      "meta" : "artist"     },
              { "name" : "composers",    "meta" : "composer"   },
              { "name" : "collections",  "meta" : "collection" },
              { "name" : "keys",         "meta" : "key_actual" },
              { "name" : "years",        "meta" : "year"       },
              // Add "omit" : true to omit a field.
              // To add fields with fixed values, use "value":
              { "name" : "my_field", "value" : "text", "omit" : true },
          ],
          // Field separator.
          "separator" : ";",
          // Values separator.
          "vseparator" : "|",
          // Restrict CSV to song pages only (do not include matter pages).
          "songsonly" : true,
      },
    },

    // Settings for ChordPro backend.
    "chordpro" : {
        // Style of chorus.
        "chorus" : {
            // Recall style: Print the tag using the type.
            // Alternatively quote the lines of the preceding chorus.
            // If no tag+type or quote: use {chorus}.
            // Note: Variant 'msp' always uses {chorus}.
            "recall" : {
                 // "tag"   : "Chorus", "type"  : "comment",
                 "tag"   : "", "type"  : "",
                 // "quote" : false,
                 "quote" : false,
            },
        },
        // Retain # comments -- we'll output them.
        "comments" : "retain",
    },

    // Settings for HTML backend.
    "html" : {
        // Stylesheet links.
        "styles" : {
            "display" : "chordpro.css",
            "print"   : "chordpro_print.css",
        },
    },

    // Settings for LaTeX backend.
    "latex" : {
        "template_include_path" : [ ],
        "templates" :  {
            "songbook" : "songbook.tt",
            "comment" : "comment.tt",
            "image"   : "image.tt"
        }
    },

    // Settings for Text backend.
    "text" : {
        // Style of chorus.
        "chorus" : {
            // Recall style: Print the tag using the type.
            // Alternatively quote the lines of the preceding chorus.
            // If no tag+type or quote: use {chorus}.
            // Note: Variant 'msp' always uses {chorus}.
            "recall" : {
                 // "tag"   : "Chorus", "type"  : "comment",
                 "tag"   : "", "type"  : "",
                 // "quote" : false,
                 "quote" : false,
            },
        },
    },

    // Settings for A2Crd.
    "a2crd" : {
        // Treat leading lyrics lines as title/subtitle lines.
        "infer-titles" : true,
        // Classification algorithm.
        "classifier" : "pct_chords",
        // Tab stop width for tab expansion. Set to zero to disable.
        "tabstop" : 8,
    },

    // Settings for the parser/preprocessor.
    // For selected lines, you can specify a series of 
    // { "target" : "xxx", "replace" : "yyy" }
    // Every occurrence of "xxx" will be replaced by "yyy".
    // Use wisely.
    "parser" : {
        "preprocess" : {
            // All lines.
            "all" : [],
            // Directives.
            "directive" : [],
            // Song lines (lyrics) only.
            "songline" : [],
        },
    },

    // For (debugging (internal use only)).
    "debug" : {
        "runtimeinfo" : 1,
        "a2crd"     : 0,
        "assets"    : 0,
        "chords"    : 0,
        "config"    : 0,
        "echo"	    : 0,
        "fonts"	    : 0,
        "images"    : 0,
        "layout"    : 0,
        "meta"	    : 0,
        "mma"	    : 0,
        "paths"	    : 0,
        "spacing"   : 0,
        "song"	    : 0,
        "songfull"  : 0,
        "ops"	    : 0,
        "csv"	    : 0,
        "abc"	    : 0,
        "ly"	    : 0,
        "svg"	    : 0,
        "txtblk"    : 0,
        // For temporary use.
        "x1"	    : 0,
        "x2"	    : 0,
        "x3"	    : 0,
    },

}
// End of config.
End_Of_Config
}

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

unless ( caller ) {
    binmode STDOUT => ':utf8';
    print( default_config() );
    exit;
}

1;

=head1 DEFAULT CONFIGURATION

The default configuration as built in. User and system
configs go on top of this one.

See L<https://www.chordpro.org/chordpro/chordpro-configuration/> for
extensive details and examples.


