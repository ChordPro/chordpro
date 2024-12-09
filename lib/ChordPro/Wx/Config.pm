#! perl

use v5.26;
use Object::Pad;
use open ':std', IO => ':encoding(UTF-8)';

class ChordPro::Wx::Config;

our %state;
our %preferences;

use ChordPro::Utils qw( is_macos );
use Ref::Util qw( is_hashref is_arrayref );

use Exporter 'import';
our @EXPORT = qw( %state %preferences );

my $cb;

use Wx qw(:everything);
use Wx::Locale gettext => '_T';
use ChordPro::Paths;
use Encode qw( decode_utf8 );

use constant FONTSIZE => 12;

use constant SETTINGS_VERSION => 2;

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
   enable_presets => 1,
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

   # Preferences w/o UI.
   chordproext => ".chordpro",	# for Nick
   dumpstate => 0,
   expert => 0,

  );

use constant MAXRECENTS => 10;

# Establish a connection with the persistent data store.

method Setup :common ($options) {

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
	$cb->SetPath("/wxchordpro");
    }
    else {
	my $file;
	if ( $ENV{XDG_CONFIG_HOME} && -d $ENV{XDG_CONFIG_HOME} ) {
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
	unless ( -f $file ) {
	    open( my $fd, '>', $file );
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

    my ( $ggoon, $group, $gindex ) = $cb->GetFirstGroup;
    my %pp = $ggoon ? %prefs : ();
    while ( $ggoon ) {
	my $cp = $cb->GetPath;
	$cb->SetPath("/$group");

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
		if ( $entry eq "cfgpreset" ) {
		    $preferences{$entry} = [ split( /,\s*/, $value ) ];
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
		    }
		}
		elsif ( $entry =~ /^(editcolour)_(\w+)_(\w+)$/ ) {
		    $preferences{$1}{$2}{$3} = $value;
		}
		else {
		    $preferences{$entry} = $value;
		}
	    }
	    elsif ( $group eq "recents" ) {
		push( @{$state{$group}}, $value )
		  if -s $value;
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

    if ( $preferences{settings_version}||1 < SETTINGS_VERSION ) {
	for ( qw( windows sash ) ) {
	    delete $state{$_};
	    $cb->DeleteGroup("/$_");
	}
	if ( $preferences{pdfviewer} ) {
	    $preferences{enable_pdfviewer} //= 1;
	}
    }
    $cb->Flush;

    # Collect from the environment.
    CP->setup_resdirs;
    setup_styles();
    setup_notations();
    setup_tasks();

    # For convenience.
    my @ext = qw( cho crd chopro chord chordpro pro );
    my $lst = "*." . join(",*.",@ext);
    $state{ffilters} = "ChordPro files ($lst)|" . $lst =~ s/,/;/gr .
      (is_macos ? ";*.txt" : "|All files|*.*");

    if ( $preferences{dumpstate} ) {
	use DDP; p %state;
    }
}

# Store the preferences and other persistent state.

method Store :common {

    my $cp = $cb->GetPath;
    $preferences{settings_version} = SETTINGS_VERSION;

    while ( my ( $group, $v ) = each %state ) {

	next unless $group =~ m{ ^(?:
				     preferences | messages | recents |
				     sash | songbookexport | windows
				 )$ }x;

	# Re-write the recents. Array.
	if ( $group eq "recents" && is_arrayref($v) ) {
	    $cb->DeleteGroup("/$group");
	    $cb->SetPath("/$group");
	    for ( my $i = 0; $i < @$v; $i++ ) {
		last if $i >= MAXRECENTS;
		$cb->Write( "$i", $v->[$i] );
	    }
	    next;
	}

	# Everything else are hash refs.
	next unless is_hashref($v);

	$cb->SetPath("/$group");
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
		next if $k eq "editcolours";
		$v = join( ",", @$v ) if is_arrayref($v);
	    }
	    if ( defined $v ) {
		$cb->Write( $k, $v );
	    }
	    else {
		warn("Preferences: Undefined value for $k\n");
		$cb->DeleteEntry($k);
	    }
	}
    }
    $cb->Flush;
}

################ Private Subroutines ################

# List of available config presets (styles).
sub setup_styles {
    my $stylelist = $state{styles};
    return $stylelist if $stylelist && @$stylelist;

    my %stylelist;
    my @userstyles;

    # Collect standard style files (presets).
    for my $cfglib ( @{ CP->findresdirs("config") } ) {
	next unless $cfglib && -d $cfglib;
	opendir( my $dh, $cfglib );
	foreach ( readdir($dh) ) {
	    $_ = decode_utf8($_);
	    next unless /^(.*)\.json$/;
	    my $base = $1;
	    $stylelist{$base} = $_;
	}
    }

    # Add custom style presets. if appropriate.
    my $dir = $preferences{customlib};
    if ( $preferences{enable_customlib}
	 && $dir && -d ( my $cfglib = "$dir/config" ) ) {
	opendir( my $dh, $cfglib );
	foreach ( readdir($dh) ) {
	    $_ = decode_utf8($_);
	    next unless /^(.*)\.json$/;
	    my $base = $1;
	    push( @userstyles, $base );
	    delete $stylelist{$base};
	}
    }

    # No need for ChordPro style, it's default.
    delete $stylelist{chordpro};

    $state{styles}     = [ sort keys %stylelist ];
    $state{userstyles} = [ sort @userstyles ];
}

# List of available notation systems.
sub setup_notations {
    my $notationlist = $state{notations};
    return $notationlist if $notationlist && @$notationlist;
    $notationlist = [ undef ];
    for my $cfglib ( @{ CP->findresdirs( "notes", class => "config" ) } ) {
	next unless $cfglib && -d $cfglib;
	opendir( my $dh, $cfglib );
	foreach ( sort readdir($dh) ) {
	    $_ = decode_utf8($_);
	    next unless /^(.*)\.json$/;
	    my $base = $1;
	    $notationlist->[0] = "common", next
	      if $base eq "common";
	    push( @$notationlist, $base );
	}
    }
    $state{notations} = $notationlist;
}

# List of available tasks.
sub setup_tasks {
    my @tasks;
    my @libs = @{ CP->findresdirs("tasks") };
    my $dir = $preferences{customlib};
    push( @libs, "$dir/tasks" ) if $dir && -d "$dir/tasks";
    my $did;
    my %dups;
    for my $cfglib ( @libs ) {
	next unless $cfglib && -d $cfglib;
	opendir( my $dh, $cfglib );
	foreach ( readdir($dh) ) {
	    $_ = decode_utf8($_);
	    next unless /^(.*)\.(?:json|prp)$/;
	    my $base = $1;
	    my $file = File::Spec->catfile( $cfglib, $_ );

	    # Tentative title (description).
	    ( my $desc = $base ) =~ s/_/ /g;

	    # Peek in the first line.
	    my $line;
	    my $fd;
	    open( $fd, '<:utf8', $file ) and
	      $line = <$fd> and
	      close($fd);
	    if ( $line =~ m;(?://|\#)\s*(?:chordpro\s*)?task:\s*(.*);i ) {
		$desc = $1;
	    }
	    next if $dups{$desc}++;

	    push( @tasks, [ $desc, $file ] );
	}
    }
    $state{tasks} = \@tasks;
}

1;
