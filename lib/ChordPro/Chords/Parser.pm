#! perl

use v5.26;
use utf8;
use Carp;
use feature qw( signatures );
no warnings "experimental::signatures";

# package ParserWatch;
#
# require Tie::Hash;
# our @ISA = qw( Tie::StdHash );
#
# sub STORE {
#     if ( $_[1] !~ /^[[:alpha:]]+$/ ) {
# 	Carp::cluck("STORE $_[1] " . $_[2]);
# 	::dump($_[2]);
#     }
#     $_[0]->{$_[1]} = $_[2];
# }

use ChordPro;

my %parsers;

# tie %parsers => 'ParserWatch';

package ChordPro::Chords::Parser;

# The parser analyses a chord and returns an object with the following
# attributes:
#
#  name		name as passed to the parser (e.g. Cism7)
#
#  root		textual decomposition: root part (e.g. Cis)
#  qual		textual decomposition: quality part (e.g. m)
#  ext		textual decomposition: extension part (e.g. 7)
#  bass		textual decomposition: bass part (a root)
#
#  system	notation system (common, nashville, user defined)
#  root_canon	canonical root (e.g. Cis => C#)
#  root_ord	root ordinal (e.g. Cis => 1)
#  root_mod	root modifier (e.g. is => # => +1)
#  qual_canon	canonical qualifier (e.g. m => -)
#  ext_canon	canonical extension (e.g. sus => sus4)
#  bass_canon	like root, for bass note
#  bass_ord	like root, for bass note
#  bass_mod	like root, for bass note
#
# The parsers are one of
#  ChordPro::Chords::Parser::Common
#  ChordPro::Chords::Parser::Nashville
#  ChordPro::Chords::Parser::Roman
#
# The objects are one of
#  ChordPro::Chord::Common
#  ChordPro::Chord::Nashville
#  ChordPro::Chord::Roman

# Creates a parser based on the current (optionally augmented)
# context.
# Note that the appropriate way is to call
# ChordPro::Chords::Parser->get_parser.

sub new ( $pkg, $init ) {

    Carp::confess("Missing config?") unless $::config;
    # Use current config, optionally augmented by $init.
    my $cfg = { %{$::config//{}}, %{$init//{}} };

    Carp::croak("Missing notes in parser creation")
	unless $cfg->{notes};
    my $system = $cfg->{notes}->{system};
    Carp::croak("Missing notes system in parser creation")
	unless $system;

    if ( $system eq "nashville" ) {
	return ChordPro::Chords::Parser::Nashville->new($cfg);
    }
    if ( $system eq "roman" ) {
	return ChordPro::Chords::Parser::Roman->new($cfg);
    }
    return ChordPro::Chords::Parser::Common->new($cfg);
}

# The default parser has built-in support for common (dutch) note
# names.

sub default ( $pkg ) {

    return $parsers{common} //=
      ChordPro::Chords::Parser::Common->new
	( { %{$::config},
	  "notes" =>
	  { "system" => "common",
	    "sharp" => [ "C", [ "C#", "Cis", "C♯" ],
			 "D", [ "D#", "Dis", "D♯" ],
			 "E",
			 "F", [ "F#", "Fis", "F♯" ],
			 "G", [ "G#", "Gis", "G♯" ],
			 "A", [ "A#", "Ais", "A♯" ],
			 "B",
		       ],
	    "flat"  => [                               "C",
			 [ "Db", "Des",        "D♭" ], "D",
			 [ "Eb", "Es",  "Ees", "E♭" ], "E",
		                                       "F",
			 [ "Gb", "Ges",        "G♭" ], "G",
			 [ "Ab", "As",  "Aes", "A♭" ], "A",
			 [ "Bb", "Bes",        "B♭" ], "B",
	       ],
	  },
	},
      );
}

# Cached version of the individual parser's parse_chord.
sub parse ( $self, $chord ) {
####    $self->{chord_cache}->{$chord} //=
      $self->parse_chord($chord);
}

# Virtual.
sub parse_chord ( $self, $chord ) {
    Carp::confess("Virtual method 'parse_chord' not defined");
}

# Fetch a parser for a known system, with fallback.
# Default is a parser for the current config.
sub get_parser ( $self, $system = undef, $nofallback = undef ) {

    $system //= $::config->{notes}->{system};
    return $parsers{$system} if $parsers{$system};

    if ( $system eq "nashville" ) {
	return $parsers{$system} //=
	  ChordPro::Chords::Parser::Nashville->new;
    }
    elsif ( $system eq "roman" ) {
	return $parsers{$system} //=
	  ChordPro::Chords::Parser::Roman->new;
    }
    elsif ( $system ne $::config->{notes}->{system} ) {
	my $p = ChordPro::Chords::Parser::Common->new
	  ( { notes => { system => $system } } );
	return $parsers{$system} = $p;
    }
    elsif ( $system ) {
	my $p = ChordPro::Chords::Parser::Common->new;
	$p->{system} = $system;
	return $parsers{$system} = $p;
    }
    elsif ( $nofallback ) {
	return;
    };

    Carp::confess("No parser for $system, falling back to default\n");
    return $parsers{common} //= $self->default;
}

sub have_parser ( $self, $system ) {
    exists $parsers{$system};
}

# The list of instantiated parsers.
sub parsers ( $self ) {
    \%parsers;
}

sub reset_parsers ( $self,  @which ) {
    @which = keys(%parsers) unless @which;
    delete $parsers{$_} for @which;
}

# The number of intervals for this note system.
sub intervals ( $self ) {
    $self->{intervals};
}

sub simplify ( $self ) {
    ref($self);
}

################ Parsing Common notated chords ################

package ChordPro::Chords::Parser::Common;

our @ISA = qw( ChordPro::Chords::Parser );

use Storable qw(dclone);

sub new ( $pkg, $cfg = $::config ) {
    my $self = bless { chord_cache => {} } => $pkg;
    bless $self => 'ChordPro::Chords::Parser::Common';
    my $notes = $cfg->{notes};
    $self->load_notes($cfg);
    $self->{system} = $notes->{system};
    $self->{target} = 'ChordPro::Chord::Common';
    $self->{movable} = $notes->{movable};
    warn("Chords: Created parser for ", $self->{system},
	 $cfg->{settings}->{chordnames} eq "relaxed"
	 ? ", relaxed" : "",
	 "\n") if $::options->{verbose} > 1;
    return $parsers{$self->{system}} = $self;
}

sub parse_chord ( $self, $chord ) {

    my $info = { system => $self->{system},
		 parser => $self,
		 name   => $chord };

    my $bass = "";
    if ( $chord =~ m;^(.*)/($self->{n_pat})$; ) {
	$chord = $1;
	$bass = $2;
    }

    my %plus;

    # Match chord.
    if ( $chord eq "" && $bass ne "" ) {
	$info->{rootless} = 1;
    }
    elsif ( $chord =~ /^$self->{c_pat}$/ ) {
	%plus = %+;
	$info->{root} = $plus{root};
    }
    # Retry with relaxed pattern if requested.
    elsif ( $self->{c_rpat}
	    && $::config->{settings}->{chordnames} eq "relaxed"
	    && $chord =~ /^$self->{c_rpat}$/ ) {
	%plus = %+;		# keep it outer
	return unless $info->{root} = $plus{root};
    }
    # Not a chord. Try note name.
    elsif ( $::config->{settings}->{notenames}
	    && ucfirst($chord) =~ /^$self->{n_pat}$/ ) {
	$info->{root} = $chord;
	$info->{isnote} = 1;
    }
    # Nope.
    else {
	return;
    }

    bless $info => $self->{target};

    my $q = $plus{qual} // "";
    $info->{qual} = $q;
    $q = "-" if $q eq "m" || $q eq "mi" || $q eq "min";
    $q = "+" if $q eq "aug";
    $q = "0" if $q eq "dim";
    $q = "0" if $q eq "o";
    $info->{qual_canon} = $q;

    my $x = $plus{ext} // "";
    if ( !$info->{qual} ) {
	if ( $x eq "maj" ) {
	    $x = "";
	}
    }
    $info->{ext} = $x;
    $x = "sus4" if $x eq "sus";
    $info->{ext_canon} = $x;

    my $ordmod = sub {
	my ( $pfx ) = @_;
	my $r = $info->{$pfx};
	$r = ucfirst($r) if $info->{isnote};
	if ( defined $self->{ns_tbl}->{$r} ) {
	    $info->{"${pfx}_ord"} = $self->{ns_tbl}->{$r};
	    $info->{"${pfx}_mod"} = defined $self->{nf_tbl}->{$r} ? 0 : 1;
	    $info->{"${pfx}_canon"} = $self->{ns_canon}->[$self->{ns_tbl}->{$r}];
	}
	elsif ( defined $self->{nf_tbl}->{$r} ) {
	    $info->{"${pfx}_ord"} = $self->{nf_tbl}->{$r};
	    $info->{"${pfx}_mod"} = -1;
	    $info->{"${pfx}_canon"} = $self->{nf_canon}->[$self->{nf_tbl}->{$r}];
	}
	else {
	    Carp::croak("CANT HAPPEN ($r)");
	    return;
	}
####	$info->{isflat} = $info->{"${pfx}_mod"} < 0;
    };

    $ordmod->("root") unless $info->is_rootless;

    cluck("BLESS info for $chord into ", $self->{target}, "\n")
      unless ref($info) =~ /ChordPro::Chord::/;

    if ( $info->{bass} = $bass ) {
	if ( $bass =~ /^$self->{n_pat}$/ ) {
	    $ordmod->("bass");
	    if ( $info->is_rootless ) {
		for ( qw( ord mod canon ) ) {
		    $info->{"root_$_"} = $info->{"bass_$_"};
		}
	    }
	}
    }

    if ( $::config->{settings}->{'chords-canonical'} ) {
	my $t = $info->{name};
	$info->{name_canon} = $info->canonical;
	warn("Parsing chord: \"$chord\" canon \"", $info->canonical, "\"\n" )
	  if $info->{name_canon} ne $t and $::config->{debug}->{chords};
    }

    return $info;
}

################ Chords ################

# The following additions are recognized for major chords.

my $additions_maj =
  {
   map { $_ => $_ }
   "",
   "11",
   "13",
   "13#11",
   "13#9",
   "13b9",
   "2",
   "3",
   "4",
   "5",
   "6",
   "69",
   "6add9",
   "7",
   "711",
   "7add11",
   "7#11",
   "7#5",
   "7#9",
   "7#9#11",
   "7#9#5",
   "7#9b5",
   "7alt",
   "7b13",
   "7b13sus",
   "7b5",
   "7b9",
   "7b9#11",
   "7b9#5",
   "7b9#9",
   "7b9b13",
   "7b9b5",
   "7b9sus",
   "7-13",
   "7-13sus",
   "7-5",
   "7\\+5",
   "7-9",
   "7-9#11",
   "7-9#5",
   "7-9#9",
   "7-9-13",
   "7-9-5",
   "7-9sus",
   "7sus",
   "7susadd3",
   "7\\+",			# REGEXP!!!
   "9",
   "9\\+",			# REGEXP!!!
   "911",
   "9#11",
   "9#5",
   "9b5",
   "9-5",
   "9sus",
   "9add6",
   ( map { ( "maj$_", "^$_" ) }
     "",
     "13",
     "7",
     "711",
     "7#11",
     "7#5",
     ( map { "7sus$_" } "", "2", "4" ),
     "9",
     "911",
     "9#11",
   ),
   "alt",
   "h",
   "h7",
   "h9",
   ( map { "add$_"   }     "2", "4", "9", "11" ),
   ( map { "sus$_"   } "", "2", "4", "9" ),
   ( map { "6sus$_"  } "", "2", "4" ),
   ( map { "7sus$_"  } "", "2", "4" ),
   ( map { "13sus$_" } "", "2", "4" ),
  };

# The following additions are recognized for minor chords.

my $additions_min =
  {
   map { $_ => $_ }
   "",
   "#5",
   "11",
   "13",
   "6",
   "69",
   "7b5",
   "7-5",
   "711",			# for George Kooymans
   ( map { ( "$_", "maj$_", "^$_" ) }
     "7",
     "9",
   ),
   "9maj7", "9^7",
   "add9",
   "b6",
   "#7",
   ( map { "sus$_" } "", "4", "9" ),
   ( map { "7sus$_" } "", "4" ),
  };

# The following additions are recognized for augmented chords.

my $additions_aug =
  {
   map { $_ => $_ }
   "",
   "7",
  };

# The following additions are recognized for diminished chords.

my $additions_dim =
  {
   map { $_ => $_ }
   "",
   "7",
  };

# Build tables and patterns from the "notes" element from the
# configuration.

sub load_notes ( $self, $init ) {
    my $cfg = { %{$::config//{}}, %{$init//{}} };
    my $n = $cfg->{notes};
    Carp::confess("No notes?") unless $n->{system};
    my ( @ns_canon, %ns_tbl, @nf_canon, %nf_tbl );

    my $rix = 0;
    foreach my $root ( @{ $n->{sharp} } ) {
	if ( UNIVERSAL::isa($root, 'ARRAY') ) {
	    $ns_canon[$rix] = $root->[0];
	    $ns_tbl{$_} = $rix foreach @$root;
	}
	else {
	    $ns_canon[$rix] = $root;
	    $ns_tbl{$root} = $rix;
	}
	$rix++;
    }
    $rix = 0;
    foreach my $root ( @{ $n->{flat} } ) {
	if ( UNIVERSAL::isa($root, 'ARRAY') ) {
	    $nf_canon[$rix] = $root->[0];
	    $nf_tbl{$_} = $rix foreach @$root;
	}
	else {
	    $nf_canon[$rix] = $root;
	    $nf_tbl{$root} = $rix;
	}
	$rix++;
    }

    # Pattern to match note names.
    my $n_pat = '(?:' ;
    my @n;
    foreach ( keys %ns_tbl ) {
	push( @n, $_ );
    }
    foreach ( sort keys %nf_tbl ) {
	next if $ns_tbl{$_};
	push( @n, $_ );
    }

    $n_pat = '(?:' . join( '|', sort { length($b) <=> length($a) } @n ) . ')';

    # Pattern to match chord names.
    my $c_pat;
    # Accept root, qual, and only known extensions.
    $c_pat = "(?<root>" . $n_pat . ")";
    $c_pat .= "(?:";
    $c_pat .= "(?<qual>-|min?|m(?!aj))".
      "(?<ext>" . join("|", keys(%$additions_min)) . ")|";
    $c_pat .= "(?<qual>\\+|aug)".
      "(?<ext>" . join("|", keys(%$additions_aug)) . ")|";
    $c_pat .= "(?<qual>0|o|dim|h)".
      "(?<ext>" . join("|", keys(%$additions_dim)) . ")|";
    $c_pat .= "(?<qual>)".
      "(?<ext>" . join("|", keys(%$additions_maj)) . ")";
    $c_pat .= ")";
    $c_pat = qr/$c_pat/;
    $n_pat = qr/$n_pat/;

    # In relaxed form, we accept anything for extension.
    my $c_rpat = "(?<root>" . $n_pat . ")";
    $c_rpat .= "(?:(?<qual>-|min?|m(?!aj)|\\+|aug|0|o|dim|)(?<ext>.*))";
    $c_rpat = qr/$c_rpat/;

    # Store in the object.
    $self->{n_pat}    = $n_pat;
    $self->{c_pat}    = $c_pat;
    $self->{c_rpat}   = $c_rpat;
    $self->{ns_tbl}   = \%ns_tbl;
    $self->{nf_tbl}   = \%nf_tbl;
    $self->{ns_canon} = \@ns_canon;
    $self->{nf_canon} = \@nf_canon;
    $self->{intervals} = @ns_canon;
}

sub root_canon ( $self, $root, $sharp = 0, $minor = 0 ) {
    ( $sharp ? $self->{ns_canon} : $self->{nf_canon} )->[$root];
}

# Has chord diagrams.
sub has_diagrams ( $self ) { !$self->{movable} }

# Movable notes system.
sub movable ( $self ) { $self->{movable} }

################ Parsing Nashville notated chords ################

package ChordPro::Chords::Parser::Nashville;

our @ISA = qw(ChordPro::Chords::Parser::Common);

use Storable qw(dclone);

sub new {
    my ( $pkg, $init ) = @_;
    my $self = bless { chord_cache => {} } => $pkg;
    $self->{system} = "nashville";
    $self->{target} = 'ChordPro::Chord::Nashville';
    $self->{intervals} = 12;
    warn("Chords: Created parser for ", $self->{system}, "\n")
      if $::options->{verbose} && $::options->{verbose} > 1;
    return $parsers{$self->{system}} = $self;
}

my $n_pat = qr/(?<shift>[b#]?)(?<root>[1-7])/;

my %nmap = ( 1 => 0, 2 => 2, 3 => 4, 4 => 5, 5 => 7, 6 => 9, 7 => 11 );
my @nmap = ( 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6, 7, 1 );

sub parse_chord {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $chord ) = @_;

    $chord =~ tr/\x{266d}\x{266f}\x{0394}\x{f8}\x{b0}/b#^h0/;

    my $bass = "";
    if ( $chord =~ m;^(.*)/(.*); ) {
	$chord = $1;
	$bass = $2;
    }

    return unless $chord =~ /^$n_pat(?<qual>-|\+|0|o|aug|m(?!aj)|dim)?(?<ext>.*)$/;

    my $info = { system => "nashville",
		 parser => $self,
		 name   => $_[1],
		 root   => $+{root},
	       };
    bless $info => $self->{target};

    my $q = $+{qual} // "";
    $info->{qual} = $q;
    $q = "-" if $q eq "m";
    $q = "+" if $q eq "aug";
    $q = "0" if $q eq "dim";
    $q = "0" if $q eq "o";
    $info->{qual_canon} = $q;

    my $x = $+{ext} // "";
    $info->{ext} = $x;
    $x = "sus4" if $x eq "sus";
    $info->{ext_canon} = $x;

    my $ordmod = sub {
	my ( $pfx ) = @_;
	my $r = 0 + $info->{$pfx};
	$info->{"${pfx}_ord"} = $nmap{$r};
	if ( $+{shift} eq "#" ) {
	    $info->{"${pfx}_mod"} = 1;
	    $info->{"${pfx}_ord"}++;
	    $info->{"${pfx}_ord"} = 0
	      if $info->{"${pfx}_ord"} >= 12;
	}
	elsif ( $+{shift} eq "b" ) {
	    $info->{"${pfx}_mod"} = -1;
	    $info->{"${pfx}_ord"}--;
	    $info->{"${pfx}_ord"} += 12
	      if $info->{"${pfx}_ord"} < 0;
	}
	else {
	    $info->{"${pfx}_mod"} = 0;
	}
	$info->{"${pfx}_canon"} = $r;
    };

    $ordmod->("root");

    $info->{bass} = $bass;
    return $info unless $bass;
    return unless $bass =~ /^$n_pat$/;
    $ordmod->("bass");

    return $info;
}

sub load_notes { Carp::confess("OOPS") }

sub root_canon {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $root, $sharp ) = @_;
    no warnings 'qw';
    $sharp
      ? qw( 1 #1 2 #2 3 4 #4 5 #5 6 #6 7 )[$root]
      : qw( 1 b2 2 b3 3 4 b5 5 b6 6 b7 7 )[$root]
}

# Has chord diagrams.
sub has_diagrams {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    0;
}

# Movable notes system.
sub movable {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    1;
}

################ Parsing Roman notated chords ################

package ChordPro::Chords::Parser::Roman;

use ChordPro;

our @ISA = qw(ChordPro::Chords::Parser::Common);

sub new {
    my ( $pkg, $init ) = @_;
    my $self = bless { chord_cache => {} } => $pkg;
    $self->{system} = "roman";
    $self->{target} = 'ChordPro::Chord::Roman';
    $self->{intervals} = 12;
    warn("Chords: Created parser for ", $self->{system}, "\n")
      if $::options->{verbose} && $::options->{verbose} > 1;
    return $parsers{$self->{system}} = $self;
}

my $r_pat = qr/(?<shift>[b#]?)(?<root>(?i)iii|ii|iv|i|viii|vii|vi|v)/;

my %rmap = ( I => 0, II => 2, III => 4, IV => 5, V => 7, VI => 9, VII => 11 );

sub parse_chord {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $chord ) = @_;

    $chord =~ tr/\x{266d}\x{266f}\x{0394}\x{f8}\x{b0}/b#^h0/;

    my $bass = "";
    if ( $chord =~ m;^(.*)/(.*); ) {
	$chord = $1;
	$bass = $2;
    }

    return unless $chord =~ /^$r_pat(?<qual>\+|0|o|aug|dim|h)?(?<ext>.*)$/;
    my $r = $+{shift}.$+{root};

    my $info = { system => "roman",
		 parser => $self,
		 name   => $_[1],
		 root   => $r };
    bless $info => $self->{target};

    my $q = $+{qual} // "";
    $info->{qual} = $q;
    $q = "-" if $r eq lc($r);
    $q = "+" if $q eq "aug";
    $q = "0" if $q eq "dim";
    $q = "0" if $q eq "o";
    $info->{qual_canon} = $q;

    my $x = $+{ext} // "";
    $info->{ext} = $x;
    $x = "sus4" if $x eq "sus";
    $x = "^7" if $x eq "7+";
    $info->{ext_canon} = $x;

    my $ordmod = sub {
	my ( $pfx ) = @_;
	my $r = $info->{$pfx};
	$info->{"${pfx}_ord"} = $rmap{uc $r};
	if ( $+{shift} eq "#" ) {
	    $info->{"${pfx}_mod"} = 1;
	    $info->{"${pfx}_ord"}++;
	    $info->{"${pfx}_ord"} = 0
	      if $info->{"${pfx}_ord"} >= 12;
	}
	elsif ( $+{shift} eq "b" ) {
	    $info->{"${pfx}_mod"} = -1;
	    $info->{"${pfx}_ord"}--;
	    $info->{"${pfx}_ord"} += 12
	      if $info->{"${pfx}_ord"} < 0;
	}
	else {
	    $info->{"${pfx}_mod"} = 0;
	}
	$info->{"${pfx}_canon"} = $r;
    };

    $ordmod->("root");

    $info->{bass} = uc $bass;
    return $info unless $bass;
    return unless $bass =~ /^$r_pat$/;
    $ordmod->("bass");

    return $info;
}

sub load_notes { Carp::confess("OOPS") }

sub root_canon {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $root, $sharp, $minor ) = @_;
    return lc( $self->root_canon( $root, $sharp ) ) if $minor;
    no warnings 'qw';
    $sharp
      ? qw( I #I II #II III IV #IV V #V VI #VI VII )[$root]
      : qw( I bII II bIII III IV bV V bVI VI bVII VII )[$root]
}

# Has chord diagrams.
sub has_diagrams {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    0;
}

# Movable notes system.
sub movable {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    1;
}

################ Chord objects: Common ################

package ChordPro::Chord::Base;

use Storable qw(dclone);

sub new {
    my ( $pkg, $data ) = @_;
    $pkg = ref($pkg) || $pkg;
    bless { %$data } => $pkg;
}

sub clone {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self ) = shift;
    dclone($self);
}

sub is_note { $_[0]->{isnote} };
sub is_flat { $_[0]->{isflat} };

sub is_nc {
    my ( $self ) = @_;
    # Keyboard...
    return 1 if defined($self->kbkeys) && !@{$self->kbkeys};
    # Strings...
    return unless @{ $self->frets // [] };
    for ( @{ $self->frets } ) {
	return unless $_ < 0;
    }
    return 1;			# all -1 => N.C.
}

# Can be transposed/transcoded.
sub is_xpxc {
    defined($_[0]->{root}) || defined($_[0]->{bass}) || $_[0]->is_nc;
}

sub has_diagram {
    my ( $self ) = @_;
    ( $::config->{instrument}->{type} eq "keyboard" )
      ? @{ $self->kbkeys // []}
      : @{ $self->frets  // []};
}

# For convenience.
sub is_chord      { defined $_[0]->{root_ord} }
sub is_rootless   { $_[0]->{rootless} }
sub is_annotation { 0 }
sub is_movable    { $_[0]->{movable} }
sub is_gridstrum  { 0 }

# Common accessors.
sub name          {
    my ( $self, $np ) = @_;
    Carp::confess("Double parens")
	if $self->{parens} && $self->{name} =~ /^\(.*\)$/;
    return $self->{name} if $np || !$self->{parens};
    "(" . $self->{name} . ")";
}

sub canon         { $_[0]->{name_canon} }
sub root          { $_[0]->{root} }
sub qual          { $_[0]->{qual} }
sub ext           { $_[0]->{ext} }
sub bass          { $_[0]->{bass} }
sub base          { $_[0]->{base} }
sub frets         { $_[0]->{frets} }
sub fingers       { $_[0]->{fingers} }
sub display       { $_[0]->{display} }
sub format        { $_[0]->{format} }
sub diagram       { $_[0]->{diagram} }
sub parser        { $_[0]->{parser} }

sub strings {
    $_[0]->{parser}->{intervals};
}

sub kbkeys {
    return $_[0]->{keys} if $_[0]->{keys} && @{$_[0]->{keys}};
    $_[0]->{keys} = ChordPro::Chords::get_keys($_[0]);
}

sub chord_display ( $self, $default ) {

    use String::Interpolate::Named;

    my $res = $self->name;
    my $args = {};
    $self->flat_copy( $args, $self->{display} // $self );

    if ( !$::config->{settings}->{'enharmonic-transpose'} && $args->{key} ) {
	$args->{root} = 'E#'
	  if $args->{root} eq 'F' && $args->{key} eq 'F#';
	$args->{root} = 'Cb'
	  if $args->{root} eq 'B' && $args->{key} eq 'Gb';
    }

    for my $fmt ( $default,
		  $self->{format},
		  $self->{chordformat} ) {
	next unless $fmt;
	$args->{root} = lc($args->{root}) if $self->is_note;
	$args->{formatted} = $res;
	$res = interpolate( { args => $args }, $fmt );
    }

    # Substitute musical symbols if wanted.
    $res = $self->fix_musicsyms($res)
      if $::config->{settings}->{truesf} || $::config->{settings}->{maj7delta};
    return $res;
}

sub flat_copy ( $self, $ret, $o, $pfx = "" ) {
    while ( my ( $k, $v ) = each %$o ) {
	if ( $k eq "orig" || $k eq "xc" || $k eq "xp" ) {
	    $self->flat_copy( $ret, $v, "$k.$pfx");
	    $ret->{"$k.${pfx}formatted"} = $v->chord_display;
	}
	else {
	    $ret->{"$pfx$k"} = $v;
	}
    }
    $ret;
}

sub fix_musicsyms ( $self, $str ) {

    use ChordPro::Utils qw( splitmarkup );

    my $sf = $::config->{settings}->{truesf};
    my $delta = $::config->{settings}->{maj7delta};
    $DB::single = 1 if $str =~ />bb</;
    my @c = splitmarkup($str);
    my $res = '';
    push( @c, '' ) if @c % 2;
    my $did = 0;		# TODO: not for roman
    while ( @c ) {
	for ( shift(@c) ) {
	    if ( $sf ) {
		if ( $did ) {
		    s/b/♭/g;
		}
		elsif ( length($_) ) {
		    s/(?<=[[:alnum:]])b/♭/g;
		    $did++;
		}
		s/#/♯/g;
	    }
	    if ( $delta ) {
		s/maj7/Δ/g;
	    }
	    $res .= $_ . shift(@c);
	}
    }
    $res;
}

sub simplify ( $self ) {
    my $c = {};
    for ( keys %$self ) {
	next unless defined $self->{$_};
	next if defined $c->{$_};
	if ( UNIVERSAL::can( $self->{$_}, "simplify" ) ) {
	    $c->{$_} = $self->{$_}->simplify;
	}
	elsif ( ref($self->{$_}) eq 'ARRAY' && @{$self->{$_}} ) {
	    $c->{$_} = "[ " . join(" ", @{$self->{$_}}) . " ]";
	}
	else {
	    $c->{$_} = $self->{$_};
	}
    }
    $c;
}

sub dump ( $self ) {
    ::dump($self->simplify);
}

package ChordPro::Chord::Common;

our @ISA = qw( ChordPro::Chord::Base );

# Show reconstructs the chord from its constituents.
# Result is canonical.
sub show {
    Carp::croak("call canonical instead of show");
}

sub canonical ( $self ) {
    my $res;

    $res =
      $self->is_rootless
      ? ""
	: $self->is_chord
	  ? $self->{parser}->root_canon( $self->{root_ord},
					 $self->{root_mod} >= 0,
					 $self->{qual} eq '-',
					 # !$self->is_flat ???
				       ) . $self->{qual} . $self->{ext}
	  : $self->{name};

    if ( $self->is_note ) {
	return lcfirst($res);
    }
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "/" .
	  ($self->{system} eq "roman" ? lc($self->{bass}) : $self->{bass});
    }
    return $res;
}

# Returns a representation indepent of notation system.
sub agnostic ( $self ) {
    return if $self->is_rootless || $self->is_note;
    join( " ", "",
	  $self->{root_ord},
	  $self->{root_mod},
	  $self->{qual_canon},
	  $self->{ext_canon},
	  $self->{bass_ord} // () );
}

sub transpose ( $self, $xpose, $dir = 0 ) {
    return $self unless $xpose;
    return $self unless $self->is_chord;
    $dir //= $xpose <=> 0;

    my $info = $self->clone;
    my $p = $self->{parser};

    my $dodir = sub( $root, $dir ) {
	return 0 if $root =~ /^(0|2|4|5|7|9|11)$/;
	$dir;
    };

    unless ( $self->{rootless} ) {
	$info->{root_ord} = ( $self->{root_ord} + $xpose ) % $p->intervals;
	$info->{root_canon} = $info->{root} =
	  $p->root_canon( $info->{root_ord},
			  $dir > 0,
			  $info->{qual_canon} eq "-" );
    }
    if ( $self->{bass} && $self->{bass} ne "" && $self->{bass} !~ /^\d+$/ ) {
	$info->{bass_ord} = ( $self->{bass_ord} + $xpose ) % $p->intervals;
	$info->{bass_canon} = $info->{bass} =
	  $p->root_canon( $info->{bass_ord}, $xpose > 0 );
	$info->{bass_mod} = $dodir->( $info->{bass_ord}, $dir );
    }
    $info->{root_mod} = $dodir->( $info->{root_ord}, $dir );
    $info->{name} = $info->{name_canon} = $info->canonical;

    delete $info->{$_} for qw( copy base frets fingers keys display );

    return $info;
}

sub transcode ( $self, $xcode, $key_ord = 0 ) {
    return $self unless $xcode;
    return $self unless $self->is_chord;
    return $self if $self->{system} eq $xcode;
    my $info = $self->dclone;
#warn("_>_XCODE = $xcode, _SELF = $self->{system}, CHORD = $info->{name}");
    $info->{system} = $xcode;
    my $p = $self->{parser}->get_parser($xcode);
    die("OOPS ", $p->{system}, " $xcode") unless $p->{system} eq $xcode;
    $info->{parser} = $p;
    if ( $key_ord && $p->movable ) {
	$info->{root_ord} -= $key_ord % $p->intervals;
    }
#    $info->{$_} = $p->{$_} for qw( ns_tbl nf_tbl ns_canon nf_canon );
    unless ( $self->{rootless} ) {
	$info->{root_canon} = $info->{root} =
	  $p->root_canon( $info->{root_ord},
			  $info->{root_mod} >= 0,
			  $info->{qual_canon} eq "-" );
    }
    if ( $p->{system} eq "roman" && $info->{qual_canon} eq "-" ) {
	# Minor quality is in the root name.
	$info->{qual_canon} = $info->{qual} = "";
    }
    if ( $self->{bass} && $self->{bass} ne "" ) {
	if ( $key_ord && $p->movable ) {
	    $info->{bass_ord} -= $key_ord % $p->intervals;
	}
	$info->{bass_canon} = $info->{bass} =
	  $p->root_canon( $info->{bass_ord}, $info->{bass_mod} >= 0 );
    }
    $info->{name} = $info->{name_canon} = $info->canonical;
    $info->{system} = $p->{system};
    bless $info => $p->{target};
#    ::dump($info);
#warn("_<_XCODE = $xcode, CHORD = ", $info->canonical);
    return $info;
}

sub chord_display ( $self ) {

    $self->SUPER::chord_display
      ( $::config->{"chord-formats"}->{common}
	// $::config->{settings}->{"chord-format"}
	// "%{name}" );
}

################ Chord objects: Nashville ################

package ChordPro::Chord::Nashville;

our @ISA = 'ChordPro::Chord::Base';

sub transpose ( $self, $dummy1, $dummy2=0 ) { $self }

sub show {
    Carp::croak("call canonical instead of show");
}

sub canonical ( $self ) {
    my $res = $self->{root_canon} . $self->{qual} . $self->{ext};
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "/" . lc($self->{bass});
    }
    return $res;
}

sub chord_display ( $self ) {

    $self->SUPER::chord_display
      ( $::config->{"chord-formats"}->{nashville}
	// "%{name}" );
}

################ Chord objects: Roman ################

package ChordPro::Chord::Roman;

our @ISA = 'ChordPro::Chord::Base';

sub transpose ( $self, $dummy1, $dummy2=0 ) { $self }

sub show {
    Carp::croak("call canonical instead of show");
}

sub canonical ( $self ) {
    my $res = $self->{root_canon} . $self->{qual} . $self->{ext};
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "/" . lc($self->{bass});
    }
    return $res;
}

sub chord_display ( $self ) {

    $self->SUPER::chord_display
      ( $::config->{"chord-formats"}->{roman}
	// "%{name}" );
}

################ Chord objects: Annotations ################

package ChordPro::Chord::Annotation;

use String::Interpolate::Named;

our @ISA = 'ChordPro::Chord::Base';

sub transpose ( $self, $dummy1, $dummy2=0 ) { $self }
sub transcode ( $self, $dummy1, $dummy2=0 ) { $self }

sub canonical ( $self ) {
    my $res = $self->{text};
    return $res;
}

sub chord_display ( $self ) {
    return interpolate( { args => $self }, $self->{text} );
}

# For convenience.
sub is_chord      ( $self ) { 0 };
sub is_annotation ( $self ) { 1 };

################ Chord objects: Strums ################

package ChordPro::Chord::Strum;

# Special 'chord'-like objects for strums in grids.
#
# Main purpose is to show an arrow from the ChordProSymbols font.

our @ISA = 'ChordPro::Chord::Base';

use ChordPro::Symbols qw( strum );

sub new( $pkg, $data ) {
    my $self = $pkg->SUPER::new( $data );
    my $fmt = strum( $data->{name} );
    unless ( defined $fmt ) {
	warn("Unknown strum: $data->{name}\n");
	$self->{format} = "";
    }
    else {
	$self->{format} = $fmt;
    }
    return $self;
}

sub chord_display ( $self, $default = undef ) {
    $self->{format};
}

sub transpose ( $self, $dummy1, $dummy2=0 ) { $self }
sub transcode ( $self, $dummy1, $dummy2=0 ) { $self }

sub canonical ( $self ) {
    my $res = $self->{text};
    return $res;
}

# For convenience.
sub is_chord      ( $self ) { 0 };
sub is_annotation ( $self ) { 1 };
sub is_nc         ( $self ) { 1 };
sub is_xpxc       ( $self ) { 0 };
sub has_diagram   ( $self ) { 0 };
sub is_gridstrum  ( $self ) { 1 };

################ Chord objects: NC ################

package ChordPro::Chord::NC;

use String::Interpolate::Named;

our @ISA = 'ChordPro::Chord::Base';

sub transpose ( $self, $dummy1, $dummy2=0 ) { $self }
sub transcode ( $self, $dummy1, $dummy2=0 ) { $self }

sub canonical ( $self ) {
    my $res = $self->{name};
    return $res;
}

sub chord_display ( $self ) {
    return interpolate( { args => $self }, $self->{name} );
}

# For convenience.
sub is_nc         ( $self ) { 1 };
sub is_chord      ( $self ) { 0 };
sub is_annotation ( $self ) { 0 };
sub has_diagram   ( $self ) { 0 };

################ Testing ################

package main;

unless ( caller ) {
    select(STDERR);
    binmode(STDERR, ':utf8');
    $::config = { settings => { chordnames => "strict" } };
    $::options = { verbose => 2 };
    foreach ( @ARGV ) {
	if ( $_ eq '-' ) {
	    $::config = { settings => { chordnames => "relaxed" } };
	    ChordPro::Chords::Parser->reset_parsers("common");
	    next;
	}
	my $p0 = ChordPro::Chords::Parser->default;
	my $p1 = ChordPro::Chords::Parser->get_parser("common", 1);
	die unless $p0 eq $p1;
	my $p2 = ChordPro::Chords::Parser->get_parser("nashville", 1);
	my $p3 = ChordPro::Chords::Parser->get_parser("roman", 1);
	my $info = $p1->parse($_);
	$info = $p2->parse($_) if !$info && $p2;
	$info = $p3->parse($_) if !$info && $p3;
	print( "$_ => OOPS\n" ), next unless $info;
	print( "$_ ($info->{system}) =>" );
	print( " ", $info->transcode($_)->canonical, " ($_)" )
	  for qw( common nashville roman );
	print( " '", $info->agnostic, "' (agnostic)\n" );
	print( "$_ =>" );
	print( " ", $info->transpose($_)->canonical, " ($_)" ) for -2..2;
	print( "\n" );
#	my $clone = $info->clone;
#	delete($clone->{parser});
#	print( ::dump($clone), "\n" );
    }
}

1;
