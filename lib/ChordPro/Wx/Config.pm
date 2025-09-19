#! perl

use v5.26;
use Object::Pad;

class ChordPro::Wx::Config;

our %state;
our %preferences;

use Ref::Util qw( is_hashref is_arrayref );
use List::Util qw(uniq);

use Exporter 'import';
our @EXPORT = qw( %state %preferences );

my $cb;

use Wx qw(:everything);
use Wx::Locale gettext => '_T';
use ChordPro::Files;
use ChordPro::Paths;
use ChordPro::Utils qw( json_load );

use constant FONTSIZE => 12;
use constant SETTINGS_VERSION => 3;

# Legacy font numbers.
my @fonts =
  ( # Monospace
    Wx::Font->new( FONTSIZE, wxFONTFAMILY_TELETYPE,
		   wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL ),
    # Serif
    Wx::Font->new( FONTSIZE, wxFONTFAMILY_ROMAN,
		   wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL ),

    # Sans serif
    Wx::Font->new( FONTSIZE, wxFONTFAMILY_SWISS,
		   wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL ),
    # Modern
    Wx::Font->new( FONTSIZE, wxFONTFAMILY_MODERN,
		   wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL ),
  );

my %prefs =
  (
   # (Old) config version.
   settings_version => SETTINGS_VERSION - 1,

   # Skip default (system, user, song) configs.
   skipstdcfg  => 1,

   # Presets.
   # Title as defined by or derived from the JSON file.
   preset_instrument => "",
   preset_style	     => "",
   # When multiple presets are possible, a list of titles separated by TABs.
   preset_stylemods  => "",

   # Presets.
   cfgpreset      => [],

   # Custom config file.
   enable_configfile => 0,
   configfile        => "",

   # Custom library.
   enable_customlib => defined($ENV{CHORDPRO_LIB}),
   customlib        => $ENV{CHORDPRO_LIB},

   # New song template.
   enable_tmplfile => 0,
   tmplfile        => "",

   # Editor.
   editfont	   => 0,	# inital, later "Monospace 10" etc.
   editsize	   => FONTSIZE,
   editortheme	   => "auto",

   # Mostly for STC. TextCtrl fallback uses fg and bg only.
   editcolour_light_fg	   => "#000000",
   editcolour_light_bg	   => "#ffffff",
   editcolour_light_s1	   => "#b1b1b1",
   editcolour_light_s2	   => "#b1b1b1",
   editcolour_light_s3	   => "#b1b1b1",
   editcolour_light_s4	   => "#ff3c31",
   editcolour_light_s5	   => "#0068d0",
   editcolour_light_s6	   => "#ef6c2a",
   editcolour_light_annfg  => "#ff0000",
   editcolour_light_annbg  => "#ffffa0",
   editcolour_light_numfg  => "#303030",
   editcolour_light_numbg  => "#e8e8e8",
   editcolour_dark_fg	   => "#ffffff",
   editcolour_dark_bg	   => "#000000",
   editcolour_dark_s1	   => "#b1b1b1",
   editcolour_dark_s2	   => "#b1b1b1",
   editcolour_dark_s3	   => "#b1b1b1",
   editcolour_dark_s4	   => "#ff3c31",
   editcolour_dark_s5	   => "#0068d0",
   editcolour_dark_s6	   => "#ef6c2a",
   editcolour_dark_annfg   => "#ff0000",
   editcolour_dark_annbg   => "#ffffa0",
   editcolour_dark_numfg   => "#e8e8e8",
   editcolour_dark_numbg   => "#303030",

   editorwrap       => 1,
   editorwrapindent => 2,

   # Messages.
   msgsfont	   => 0,	# inital, later "Monospace 10" etc.

   # Notation.
   notation	   => "",

   # Transpose.
   enable_xpose => 0,
   xpose_from   => 0,
   xpose_to     => 0,
   xpose_acc    => 0,

   # Transcode.
   enable_xcode	   => 0,
   xcode	   => "",

   # PDF Viewer.
   enable_pdfviewer   => undef,
   pdfviewer   => "",

   # HTML Viewer.
   enable_htmlviewer => undef,

   # Insert spec chars.
   enable_insert_symbols => 0,

   # Preferences w/o UI.
   chordproext	=> ".chordpro",	# for Nick
   dumpstate	=> 0,
   expert	=> 0,
   advanced	=> 0,
  );

use constant MAXRECENTS => 10;
my $config_root = "/";

# Establish a connection with the persistent data store.

#method Setup :common ($options) {
sub Setup( $class, $options ) {

    if ( $options->{config} ) {
	Wx::ConfigBase::Set
	    ( $cb = Wx::FileConfig->new
	     ( "WxChordPro",
	       "ChordPro_ORG",
	       $options->{config},
	       '',
	       wxCONFIG_USE_LOCAL_FILE,
	     ));
    }
    elsif ( $^O =~ /^mswin/i ) {
	$cb = Wx::ConfigBase::Get;
	$config_root = "/wxchordpro";
	$cb->SetPath($config_root);
    }
    else {
	my $file;
	if ( $ENV{XDG_CONFIG_HOME} && fs_test( d => $ENV{XDG_CONFIG_HOME} ) ) {
	    $file =
	      $ENV{XDG_CONFIG_HOME} . "/wxchordpro/wxchordpro";
	}
	elsif ( -d "$ENV{HOME}/.config" ) {
	    $file = "$ENV{HOME}/.config/wxchordpro/wxchordpro";
	    mkdir("$ENV{HOME}/.config/wxchordpro");
	}
	else {
	    $file = "$ENV{HOME}/.wxchordpro";
	}
	unless ( fs_test( f => $file ) ) {
	    my $fd = fs_open( $file, '>' );
	}
	Wx::ConfigBase::Set
	    ( $cb = Wx::FileConfig->new
	     ( "WxChordPro",
	       "ChordPro_ORG",
	       $file,
	       '',
	       wxCONFIG_USE_LOCAL_FILE,
	     ));
    }

    unless ( $cb->Exists("preferences") ) { # new
	$cb->Write("/preferences/settings_version", SETTINGS_VERSION );
    }
}

method Ok :common {
    $preferences{settings_version} == SETTINGS_VERSION;
}
method SetOk :common {
    $preferences{settings_version} = SETTINGS_VERSION;
}

# Load all data from the persistent data store into %state.
# Adds information collected from the environment (e.g. config files).
# Try to compensate for incompatibilities (legacy).

method Load :common {
    use Hash::Util qw( lock_keys unlock_keys );
    unlock_keys(%preferences);
    %preferences = ( %prefs );
    while ( my ( $k, $v ) = each %prefs ) {
	next unless $k =~ /^(editcolour)_(\w+)_(\w+)/;
	$preferences{$1}{$2}{$3} = $v;
    }
    while ( my ( $k, $v ) = each %preferences ) {
	delete $preferences{$k} if $k =~ /^(editcolour)_/;
    }
    %state = ( preferences => \%preferences,
	       recents => [],
	     );

    $cb->SetPath($config_root);
    my ( $ggoon, $group, $gindex ) = $cb->GetFirstGroup;
    my %pp = $ggoon ? %prefs : ();
    while ( $ggoon ) {
	my $cp = $cb->GetPath;
	$cb->SetPath($group);

	$state{$group} = [] if $group eq "recents";

	my ( $goon, $entry, $index ) = $cb->GetFirstEntry;
	while ( $goon ) {
	    my $value = $cb->Read($entry);
	    # printf STDERR ( "$group.$entry:\t%s\n", $value );
	    if ( $group eq "preferences" ) {
		my $o;
		if ( exists $pp{$entry} ) {
		    $o = delete $pp{$entry};
		}
		else {
		    warn("Preferences: unknown key: $entry");
		    $cb->DeleteEntry($entry);
		    next;
		}
		if ( $entry eq "preset_stylemods" ) {
		    $preferences{$entry} = [ split( /\t+/, $value ) ];
		}
		elsif ( $entry eq "editcolours" ) {
		    my @c = split( /,\s*/, $value );
		    if ( @c <= 1 ) {
			...;
		    }
		    else {
			$preferences{editcolour}{light}{fg} = $c[0];
			$preferences{editcolour}{light}{bg} = $c[1];
			$preferences{editcolour}{light}{s1} = $c[2];
			$preferences{editcolour}{light}{s2} = $c[3];
			$preferences{editcolour}{light}{s3} = $c[4];
			$preferences{editcolour}{light}{s4} = $c[5];
			$preferences{editcolour}{light}{s5} = $c[6];
			$preferences{editcolour}{light}{annbg} = $c[7];
			$preferences{editcolour}{light}{annfg} = "#ff0000";
			$preferences{editcolour}{light}{numbg} =
			  $preferences{editcolour}{dark}{numfg} = "#e8e8e8";
			$preferences{editcolour}{light}{numfg} =
			  $preferences{editcolour}{dark}{numbg} = "#303030";
		    }
		}
		elsif ( $entry =~ /^(editcolour)_(\w+)_(\w+)$/ ) {
		    $cb->DeleteEntry($entry), next if $2 eq "auto";
		    $preferences{$1}{$2}{$3} = $value;
		}
		else {
		    $preferences{$entry} = $value;
		}
	    }
	    elsif ( $group eq "recents" ) {
		push( @{$state{$group}}, $value )
		  if fs_test( 's', $value );
	    }
	    else {
		$state{$group}->{$entry} = $value;
	    }
	}
	continue {
	    ( $goon, $entry, $index ) = $cb->GetNextEntry($index);
	}
	$cb->SetPath($cp);
	( $ggoon, $group, $gindex ) = $cb->GetNextGroup($gindex);
    }

    # Catch mistakes and abuse.
    lock_keys(%preferences);

    # Legacy font number -> font desc.
    for ( qw( editfont msgsfont ) ) {
	next unless $preferences{$_} =~ /^\d+$/;
	$preferences{$_} = $fonts[$preferences{$_}]->GetNativeFontInfoDesc;
    }
    delete $ENV{CHORDPRO_LIB};

    if ( $preferences{settings_version} < SETTINGS_VERSION ) {
	for ( qw( windows sash ) ) {
	    delete $state{$_};
	    $cb->DeleteGroup($_);
	}
    }
    $preferences{enable_pdfviewer} //= 0;
    $preferences{enable_htmlviewer} //= 0;
    $cb->Flush;

    # Collect from the environment.
    CP->setup_resdirs;
    setup_styles();

    # For convenience.
    setup_filters();

    if ( $preferences{dumpstate} ) {
	use DDP; p %state;
    }
}

# Store the preferences and other persistent state.

method Store :common {

    my $cp = $config_root;
    $preferences{settings_version} = SETTINGS_VERSION;
    $cb->DeleteAll;
    $cb->SetPath($cp);

    while ( my ( $group, $v ) = each %state ) {

	next unless $group =~ m{ ^(?:
				     preferences | messages | recents |
				     sash | songbookexport | windows
				 )$ }x;
	$cb->SetPath($cp);

	# Re-write the recents. Array.
	if ( $group eq "recents" && is_arrayref($v) ) {
	    # $cb->DeleteGroup($group);
	    $cb->SetPath($group);
	    for ( my $i = 0; $i < @$v; $i++ ) {
		last if $i >= MAXRECENTS;
		$cb->Write( "$i", $v->[$i] );
	    }
	    next;
	}

	# Everything else are hash refs.
	next unless is_hashref($v);

	$cb->SetPath($group);
	while ( my ( $k, $v ) = each %$v ) {
	    if ( $group eq "preferences" ) {
		if ( $k eq "editcolour" && is_hashref($v) ) {
		    while ( my ( $k, $v ) = each %$v ) {
			my $p = "editcolour_$k";
			while ( my ( $k, $v ) = each %$v ) {
			    $cb->Write($p."_$k", $v );
			}
		    }
		    next;
		}
		if ( $k eq "preset_stylemods" && is_arrayref($v) ) {
		    $v = join( "\t", @$v );
		}
		next if $k eq "editcolours";
		$v = join( ",", @$v ) if is_arrayref($v);
	    }
	    if ( defined $v ) {
		$cb->Write( $k, $v );
	    }
	    else {
		warn("Preferences: Undefined value for $k\n");
		# $cb->DeleteEntry($k);
	    }
	}
    }
    $cb->Flush;
}

################ Private Subroutines ################

# Fetch available config presets (styles, stylemods, ...).
sub setup_styles( $refresh = 0 ) {
    return if $state{presets}->{styles} && !$refresh;

    my %styles;			# new style
    my %stylemods;		# new style
    my %instruments;		# new style
    my %tasks;			# new style

    my $findopts = { filter => qr/^.*\.json$/i, recurse => 0 };

    # Collect standard style files (presets).
    my @cfglibs = @{ CP->findresdirs("config") };

    # At this point, we can have one or two libs. The last one is
    # the ChordPro standard library.
    # If there are two, the first one is the user config lib.
    # To this/these we prepend the custom lib.
    @cfglibs[-1] = { src => "std", lib => $cfglibs[-1] };
    if ( @cfglibs == 2 ) {
	my $t = shift(@cfglibs);
	push( @cfglibs, { src => "user", lib => $t } )
	  if $preferences{advanced} && !$preferences{skipstdcfg};
    }
    push( @cfglibs, { src => "custom",
		      lib => fn_catfile( $preferences{customlib}, "config" ) } )
      if $preferences{advanced} && $preferences{enable_customlib};
    $state{cfglibs} = \@cfglibs;
    use DDP; p @cfglibs, as => "cfglibs (for configs)";

    for ( @cfglibs ) {
	my $cfglib = $_;
	my $src = $cfglib->{src};
	$cfglib = $cfglib->{lib};
	next unless $cfglib && fs_test( d => $cfglib );
	next unless my $entries = fs_find( $cfglib, $findopts );

	foreach ( @$entries ) {
	    my $file = fn_catfile( $cfglib, $_->{name} );
#	    warn("try $file\n");
	    next unless fs_test( s => $file );

	    my $data = fs_blob( $file );
	    $data = json_load( $data, $file );

	    my $types;
	    my %meta = ( src => $src, file => $file );
	    if ( $data->{config}->{type} ) {
		$types = $data->{config}->{type};
		$types = [ $types ] unless is_arrayref($types);
		$meta{title}       = $data->{config}->{title};
		$meta{desc}        = $data->{config}->{description};
		$meta{exclude_id}  = $data->{config}->{exclude_id};
		$meta{preview}     = $data->{config}->{preview};
	    }
	    else {
		next unless $preferences{advanced};
		$types = [ "unknown" ];
		my $base = fn_basename( $_->{name}, ".json" );
		$meta{title} = $meta{desc}  = _neat($base);
	    }

	    for my $type ( @$types ) {
		$meta{type} = $type;

		if ( $type eq "style" ) {
		    $styles{$meta{title}} = { %$_, %meta };
		}
		elsif ( $type eq "stylemod" ) {
		    $stylemods{$meta{title}} = { %$_, %meta };
		}
		elsif ( $type eq "instrument" ) {
		    $instruments{$meta{title}} = { %$_, %meta };
		}
		elsif ( $type eq "task" ) {
		    $tasks{$meta{title}} = { %$_, %meta };
		}
		elsif ( $type eq "unknown" ) {
		    $stylemods{$meta{title}} = { %$_, %meta };
		}
	    }
	}
    }

    # Add the tasks and notations.
    _add_tasks( \%tasks );
    _add_notations( \my %notes );

    $state{presets} =
      { styles      => \%styles,
	tasks       => \%tasks,
	stylemods   => \%stylemods,
	instruments => \%instruments,
	notes       => \%notes,
      };

    # use DDP; warn np $state{presets}, as => "presets";

}

# Fetch available tasks. Called by setup_presets.
sub _add_tasks( $tasks ) {

    my @cfglibs;
    for ( my $i = 1; $i < @{ $state{cfglibs} }; $i++ ) {
	my $lib = $state{cfglibs}->[$i];
	push( @cfglibs,
	      { src => $lib->{src},
		lib => fn_catfile( fn_dirname($lib->{lib}), "tasks" ) } );
	pop( @cfglibs ) unless fs_test( d => $cfglibs[-1]->{lib} );
    }
    use DDP; p @cfglibs, as => "cfglibs (for tasks)";

    my $findopts = { filter => qr/^.*\.(?:json|prp)$/i, recurse => 0 };

    for ( @cfglibs ) {
	my $cfglib = $_;
	my $src = $cfglib->{src};
	$cfglib = $cfglib->{lib};
	next unless my $entries = fs_find( $cfglib, $findopts );

	foreach ( @$entries ) {
	    my $file = fn_catfile( $cfglib, $_->{name} );
#	    warn("try $file\n");
	    next unless fs_test( s => $file );

	    my $blob = fs_blob( $file );
	    my $data = json_load( $blob, $file );

	    my $types;
	    my %meta = ( src => $src, file => $file );
	    if ( $data->{config}->{type} ) {
		$types = $data->{config}->{type};
		$types = [ $types ] unless is_arrayref($types);
		$meta{title} = $data->{config}->{title};
		$meta{desc}  = $data->{config}->{description};
		for my $type ( @$types ) {
		    next unless $type eq "task";
		    $tasks->{$meta{title}} = { %$_, %meta };
		}
	    }
	    else {
		my $base = fn_basename( $_->{name}, ".json", ".prp" );

		# Tentative title (description).
		my $desc = _neat($base);

		# See if there's a title in the first line.
		# E.g. // ChordPro Task: Chords In-line
		if ( $blob =~ m;(?://|\#)\s*(?:chordpro\s*)?task:\s*(.*);i ) {
		    $desc = $1;
		}
		$meta{title} = $meta{desc}  = $desc;
		$tasks->{$desc} = { %$_, %meta };
	    }
	}
    }
}

# List of available notation systems.
sub _add_notations( $notes ) {

    my @cfglibs;
    for ( my $i = 0; $i < @{ $state{cfglibs} }; $i++ ) {
	my $lib = $state{cfglibs}->[$i];
	push( @cfglibs,
	      { src => $lib->{src},
		lib => fn_catfile( $lib->{lib}, "notes" ) } );
	pop( @cfglibs ) unless fs_test( d => $cfglibs[-1]->{lib} );
    }
    use DDP; p @cfglibs, as => "cfglibs (for notes)";

    my $findopts = { filter => qr/^.*\.json$/i, recurse => 0 };

    for ( @cfglibs ) {
	my $cfglib = $_;
	my $src = $cfglib->{src};
	$cfglib = $cfglib->{lib};
	next unless my $entries = fs_find( $cfglib, $findopts );

	foreach ( @$entries ) {
	    my $file = fn_catfile( $cfglib, $_->{name} );
#	    warn("try $file\n");
	    next unless fs_test( s => $file );

	    my $blob = fs_blob( $file );
	    my $data = json_load( $blob, $file );
	    my $types = $data->{config}->{type};
	    next unless $types;

	    my %meta = ( src => $src, file => $file );
	    $types = [ $types ] unless is_arrayref($types);
	    $meta{title} = $data->{config}->{title};
	    $meta{desc}  = $data->{config}->{description};
	    for my $type ( @$types ) {
		next unless $type eq "notes";
		$notes->{$meta{title}} = { %$_, %meta };
	    }
	}
    }
}

sub _neat {
    my ($t ) = @_;
    $t = ucfirst(lc($t));
    $t =~ s/_/ /g;
    $t =~ s/ (.)/" ".uc($1)/eg;
    $t;
}

sub setup_filters() {
    my $lst = "*." .
      join( ",*.",
	    uniq( substr($preferences{chordproext},1),
		  qw( cho crd chopro chord chordpro pro ) ) );
    $state{ffilters} = "ChordPro files ($lst)|" . $lst =~ s/,/;/gr .
      (is_macos ? ";*.txt" : "|All files|*.*");
}

1;
