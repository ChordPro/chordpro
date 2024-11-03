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

my @fonts =
  ( { name => "Monospace",
      font => Wx::Font->new( FONTSIZE, wxFONTFAMILY_TELETYPE,
			     wxFONTSTYLE_NORMAL,
			     wxFONTWEIGHT_NORMAL ),
    },
    { name => "Serif",
      font => Wx::Font->new( FONTSIZE, wxFONTFAMILY_ROMAN,
			     wxFONTSTYLE_NORMAL,
			     wxFONTWEIGHT_NORMAL ),
    },
    { name => "Sans serif",
      font => Wx::Font->new( FONTSIZE, wxFONTFAMILY_SWISS,
			     wxFONTSTYLE_NORMAL,
			     wxFONTWEIGHT_NORMAL ),
    },
    { name => "Modern",
      font => Wx::Font->new( FONTSIZE, wxFONTFAMILY_MODERN,
			     wxFONTSTYLE_NORMAL,
			     wxFONTWEIGHT_NORMAL ),
    },
  );

my %prefs =
  (
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
   editfont	   => 0,
   editsize	   => FONTSIZE,
   editcolour	   => wxWHITE,

   # Notation.
   notation	   => "",

   # Transpose.
   xpose_from => 0,
   xpose_to   => 0,
   xpose_acc  => 0,

   # Transcode.
   xcode	   => "",

   # PDF Viewer.
   enable_pdfviewer   => 0,
   pdfviewer   => "",

  );

use constant MAXRECENTS => 10;

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

method Load :common {
    use Hash::Util qw( lock_keys unlock_keys );
    unlock_keys(%preferences);
    %preferences = ( %prefs );
    %state = ( preferences => \%preferences,
	       fonts => [ @fonts ],
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
		if ( exists $pp{$entry} ) {
		    delete $pp{$entry};
		}
		else {
		    warn("Preferences: unknown key: $entry");
		}
		if ( $entry eq "cfgpreset" ) {
		    $preferences{$entry} = [ split( /,\s*/, $value ) ];
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
	    ( $goon, $entry, $index ) = $cb->GetNextEntry($index);
	}
	$cb->SetPath($cp);
	( $ggoon, $group, $gindex ) = $cb->GetNextGroup($gindex);
    }
    lock_keys(%preferences);

    if ( $preferences{editfont} =~ /^\d+$/ ) {
	$preferences{editfont} = $fonts[$preferences{editfont}]->{font}->GetNativeFontInfoDesc;
    }
    delete $ENV{CHORDPRO_LIB};

    CP->setup_resdirs;
    _setup_styles();
    _setup_notations();
    _setup_tasks();

    my @ext = qw( cho crd chopro chord chordpro pro );
    my $lst = "*." . join(",*.",@ext);
    $state{ffilters} = "ChordPro files ($lst)|" . $lst =~ s/,/;/gr .
      (is_macos ? ";*.txt" : "|All files|*.*");
}

method Store :common {

    my $cp = $cb->GetPath;
    my %pp = %prefs;
    while ( my ( $group, $v ) = each %state ) {

	next if $group =~ /^(fonts|styles|notations|tasks|panel)$/;
	if ( $group eq "recents" && is_arrayref($v) ) {
	    $cb->DeleteGroup("/$group");
	    $cb->SetPath("/$group");
	    for ( my $i = 0; $i < @$v; $i++ ) {
		last if $i >= MAXRECENTS;
		$cb->Write( "$i", $v->[$i] );
	    }
	    next;
	}
	next unless is_hashref($v);

	$cb->SetPath("/$group");
	while ( my ( $k, $v ) = each %$v ) {
	    if ( $group eq "preferences" ) {
		if ( exists $pp{$k} ) {
		    delete $pp{$k};
		}
		else {
		    warn("Preferences: unknown key: $k");
		}
		if ( $k eq "editcolour" && ref($v) ) {
		    $v = $preferences{editcolour} = $v->GetAsString(wxC2S_HTML_SYNTAX);
		}
		elsif ( $k eq "cfgpreset" ) {
		    $v = join( ",", @$v );
		}
	    }
	    $cb->Write( $k, $v );
	}
    }
    $cb->Flush;
    if ( %pp ) {
	warn( "Preferences: excess keys: " . join( " ", sort keys %pp ) );
    }
}

################

# List of available config presets (styles).
sub _setup_styles {
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
sub _setup_notations {
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
	    push( @$notationlist, $base )
	}
    }
    $state{notations} = $notationlist;
}

# List of available tasks.
sub _setup_tasks {
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
