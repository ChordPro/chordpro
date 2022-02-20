#! perl

use strict;
use warnings;
use utf8;
use Carp;

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

use App::Music::ChordPro;

my %parsers;

# tie %parsers => 'ParserWatch';

package App::Music::ChordPro::Chords::Parser;

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
#  App::Music::ChordPro::Chords::Parser::Common
#  App::Music::ChordPro::Chords::Parser::Nashville
#  App::Music::ChordPro::Chords::Parser::Roman
#
# The objects are one of
#  App::Music::ChordPro::Chord::Common
#  App::Music::ChordPro::Chord::Nashville
#  App::Music::ChordPro::Chord::Roman

# Creates a parser based on the current (optionally augmented)
# context.
# Note that the appropriate way is to call
# App::Music::ChordPro::Chords::Parser->get_parser.

sub new {
    my ( $pkg, $init ) = @_;

    Carp::confess("Missing config?") unless $::config;
    # Use current config, optionally augmented by $init.
    my $cfg = { %{$::config//{}}, %{$init//{}} };

    Carp::croak("Missing notes in parser creation")
	unless $cfg->{notes};
    my $system = $cfg->{notes}->{system};
    Carp::croak("Missing notes system in parser creation")
	unless $system;

    if ( $system eq "nashville" ) {
	return App::Music::ChordPro::Chords::Parser::Nashville->new($cfg);
    }
    if ( $system eq "roman" ) {
	return App::Music::ChordPro::Chords::Parser::Roman->new($cfg);
    }
    return App::Music::ChordPro::Chords::Parser::Common->new($cfg);
}

# The default parser has built-in support for common (dutch) note
# names.

sub default {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $pkg ) = @_;

    return $parsers{common} //=
      App::Music::ChordPro::Chords::Parser::Common->new
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
sub parse {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $chord ) = @_;
####    $self->{chord_cache}->{$chord} //=
      $self->parse_chord($chord);
}

# Virtual.
sub parse_chord {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    Carp::confess("Virtual method 'parse_chord' not defined");
}

# Fetch a parser for a known system, with fallback.
# Default is a parser for the current config.
sub get_parser {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
#    my ( $self, $system, $nofallback ) = @_;
#    $system //= $::config->{notes}->{system};
#    my $p = $self->_get_parser( $system, $nofallback );
#    unless ( defined $p ) {
#	warn("No parser for $system\n");
#    }
#    ::dump($p),die unless $p->{system} eq $system;
#    return $p;
#}
#sub _get_parser {
    my ( $self, $system, $nofallback ) = @_;

    $system //= $::config->{notes}->{system};
    return $parsers{$system} if $parsers{$system};

    if ( $system eq "nashville" ) {
	return $parsers{$system} //=
	  App::Music::ChordPro::Chords::Parser::Nashville->new;
    }
    elsif ( $system eq "roman" ) {
	return $parsers{$system} //=
	  App::Music::ChordPro::Chords::Parser::Roman->new;
    }
    elsif ( $system ne $::config->{notes}->{system} ) {
	my $p = App::Music::ChordPro::Chords::Parser::Common->new
	  ( { notes => $system } );
	return $parsers{$system} = $p;
    }
    elsif ( $system ) {
	my $p = App::Music::ChordPro::Chords::Parser::Common->new;
	$p->{system} = $system;
	return $parsers{$system} = $p;
    }
    elsif ( $nofallback ) {
	return;
    };

    Carp::confess("No parser for $system, falling back to default\n");
    return $parsers{common} //= $self->default;
}

sub have_parser {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $system ) = @_;
    exists $parsers{$system};
}

# The list of instantiated parsers.
sub parsers {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    \%parsers;
}

sub reset_parsers {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self,  @which ) = @_;
    @which = keys(%parsers) unless @which;
    delete $parsers{$_} for @which;
}

# The number of intervals for this note system.
sub intervals {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    $_[0]->{intervals};
}

################ Parsing Common notated chords ################

package App::Music::ChordPro::Chords::Parser::Common;

our @ISA = qw( App::Music::ChordPro::Chords::Parser );

use Storable qw(dclone);

sub new {
    my ( $pkg, $cfg ) = @_;
    $cfg //= $::config;
    my $self = bless { chord_cache => {} } => $pkg;
    bless $self => 'App::Music::ChordPro::Chords::Parser::Common';
    my $notes = $cfg->{notes};
    $self->load_notes($cfg);
    $self->{system} = $notes->{system};
    $self->{target} = 'App::Music::ChordPro::Chord::Common';
    $self->{movable} = $notes->{movable};
    warn("Chords: Created parser for ", $self->{system},
	 $cfg->{settings}->{chordnames} eq "relaxed"
	 ? ", relaxed" : "",
	 "\n") if $::options->{verbose} > 1;
    return $parsers{$self->{system}} = $self;
}

sub parse_chord {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $chord ) = @_;

    my $bass;
    if ( $chord =~ m;^(.*)/(.*); ) {
	$chord = $1;
	$bass = $2;
    }

    my $info = { system => $self->{system},
		 parser => $self,
		 name => $_[1] };

    # Match chord.
    my %plus;
    if ( $chord =~ /^$self->{c_pat}$/ ) {
	%plus = %+;
	$info->{root} = $plus{root};
    }
    # Retry with relaxed pattern if requested.
    elsif ( $self->{c_rpat} && $::config->{settings}->{chordnames} eq "relaxed" ) {
	$chord =~ /^$self->{c_rpat}$/;
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
    $q = "-" if $q eq "m" || $q eq "min";
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

    $ordmod->("root");

    cluck("BLESS info for $chord into ", $self->{target}, "\n")
      unless ref($info) =~ /App::Music::ChordPro::Chord::/;

    if ( $bass ) {
	return unless $bass =~ /^$self->{n_pat}$/;
	$info->{bass} = $bass;
	$ordmod->("bass");
    }

    if ( $::config->{settings}->{'chords-canonical'} ) {
	my $t = $info->{name};
	$info->{name} = $info->show;
	warn("Parsing chord: \"$chord\" canon \"", $info->show, "\"\n" )
	  if $info->{name} ne $t and $::config->{debug}->{chords};
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
   "6",
   "69",
   "7b5",
   "7-5",
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

sub load_notes {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $init ) = @_;
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
    $c_pat .= "(?<qual>-|min|m(?!aj))".
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
    $c_rpat .= "(?:(?<qual>-|min|m(?!aj)|\\+|aug|0|o|dim|)(?<ext>.*))";
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

sub root_canon {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $root, $sharp ) = @_;
    ( $sharp ? $self->{ns_canon} : $self->{nf_canon} )->[$root];
}

# Has chord diagrams.
sub has_diagrams {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    !$_[0]->{movable};
}

# Movable notes system.
sub movable {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    $_[0]->{movable};
}

################ Parsing Nashville notated chords ################

package App::Music::ChordPro::Chords::Parser::Nashville;

our @ISA = qw(App::Music::ChordPro::Chords::Parser::Common);

use Storable qw(dclone);

sub new {
    my ( $pkg, $init ) = @_;
    my $self = bless { chord_cache => {} } => $pkg;
    $self->{system} = "nashville";
    $self->{target} = 'App::Music::ChordPro::Chord::Nashville';
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

    my $bass;
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

    return $info unless $bass;
    return unless $bass =~ /^$n_pat$/;
    $info->{bass} = $bass;
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

package App::Music::ChordPro::Chords::Parser::Roman;

use App::Music::ChordPro;

our @ISA = qw(App::Music::ChordPro::Chords::Parser::Common);

sub new {
    my ( $pkg, $init ) = @_;
    my $self = bless { chord_cache => {} } => $pkg;
    $self->{system} = "roman";
    $self->{target} = 'App::Music::ChordPro::Chord::Roman';
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

    my $bass;
    if ( $chord =~ m;^(.*)/(.*); ) {
	$chord = $1;
	$bass = $2;
    }

    return unless $chord =~ /^$r_pat(?<qual>\+|0|o|aug|dim|h)?(?<ext>.*)$/;

    my $info = { system => "roman",
		 parser => $self,
		 name   => $_[1],
		 root   => $+{root} };
    bless $info => $self->{target};

    my $r = $+{root};
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

    return $info unless $bass;
    return unless $bass =~ /^$r_pat$/;
    $info->{bass} = uc $bass;
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

package App::Music::ChordPro::Chord::Base;

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

sub id {
    my ( $self ) = @_;
    Carp::confess("Chord missing ID") unless $self->{id};
    $self->{id};
}

sub name    { $_[0]->show }
sub is_note { $_[0]->{isnote} };
sub is_flat { $_[0]->{isflat} };

sub is_nc {
    my ( $self ) = @_;
    return unless $self->{frets} && @{ $self->{frets} };
    for ( @{ $self->{frets} } ) {
	return unless $_ < 0;
    }
    return 1;			# all -1 => N.C.
}

# For convenience.
sub is_chord      { defined $_[0]->{root_ord} };
sub is_annotation { 0 };

sub strings {
    $_[0]->{parser}->{intervals};
}

sub dump {
    my ( $self ) = @_;
    my $c = dclone($self);
    for ( qw( frets fingers keys ) ) {
	$c->{$_} = "[ " . join(" ", @{$c->{$_}}) . " ]";
    }
    if ( ref($c->{parser}) ) {
	$c->{ns_canon} = "[ " . join(" ", @{$c->{parser}{ns_canon}}) . " ]"
	  if $c->{parser}{ns_canon};
	$c->{parser} = ref(delete($c->{parser}));
    }
    ::dump($c);
}

package App::Music::ChordPro::Chord::Common;

our @ISA = qw( App::Music::ChordPro::Chord::Base );
use String::Interpolate::Named;

sub show {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $np ) = @_;
    my $res = $self->is_chord
      ? $self->{parser}->root_canon( $self->{root_ord},
				     $self->{root_mod} >= 0,
				     $self->{qual} eq '-',
				     !$self->is_flat
				   ) . $self->{qual} . $self->{ext}
      : $self->{name};
    if ( $self->is_note ) {
	return lcfirst($res);
    }
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "/" .
	  ($self->{system} eq "roman" ? lc($self->{bass}) : $self->{bass});
    }
    return $np ? $res : $self->{parens} ? "($res)" : $res;
}

# Returns a representation indepent of notation system.
sub agnostic {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self ) = @_;
    return if $self->is_note;
    join( " ", "",
	  $self->{root_ord}, $self->{qual_canon},
	  $self->{ext_canon}, $self->{bass_ord} // () );
}

sub transpose {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $xpose, $dir ) = @_;
    return $self unless $xpose;
    return $self unless $self->is_chord;
    $dir //= $xpose <=> 0;

    my $info = $self->clone;
    my $p = $self->{parser};

    $info->{root_ord} = ( $self->{root_ord} + $xpose ) % $p->intervals;
    $info->{root_canon} = $info->{root} =
      $p->root_canon( $info->{root_ord},
		      $dir > 0,
		      $info->{qual_canon} eq "-" );
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$info->{bass_ord} = ( $self->{bass_ord} + $xpose ) % $p->intervals;
	$info->{bass_canon} = $info->{bass} =
	  $p->root_canon( $info->{bass_ord}, $xpose > 0 );
	$info->{bass_mod} = $dir;
    }
    $info->{root_mod} = $dir;

    delete $info->{$_} for qw( copy base frets fingers keys );

    return $info;
}

sub transcode {
    Carp::confess("NMC") unless UNIVERSAL::isa($_[0],__PACKAGE__);
    my ( $self, $xcode ) = @_;
    return $self unless $xcode;
    return $self unless $self->is_chord;
    return $self if $self->{system} eq $xcode;
    my $info = $self->dclone;
#warn("_>_XCODE = $xcode, _SELF = $self->{system}, CHORD = $info->{name}");
    $info->{system} = $xcode;
    my $p = $self->{parser}->get_parser($xcode);
    die("OOPS ", $p->{system}, " $xcode") unless $p->{system} eq $xcode;
    $info->{parser} = $p;
#    $info->{$_} = $p->{$_} for qw( ns_tbl nf_tbl ns_canon nf_canon );
    $info->{root_canon} = $info->{root} =
      $p->root_canon( $info->{root_ord},
		      $info->{root_mod} >= 0,
		      $info->{qual_canon} eq "-" );
    if ( $p->{system} eq "roman" && $info->{qual_canon} eq "-" ) {
	# Minor quality is in the root name.
	$info->{qual_canon} = $info->{qual} = "";
    }
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$info->{bass_canon} = $info->{bass} =
	  $p->root_canon( $info->{bass_ord}, $info->{bass_mod} >= 0 );
    }
    $info->{system} = $p->{system};
    bless $info => $p->{target};
#    ::dump($info);
#warn("_<_XCODE = $xcode, CHORD = ", $info->show);
    return $info;
}

sub chord_display {
    my ( $self, $raw ) = @_;
    my $res =
      $self->{display}
      ? $raw
        ? $self->{display}
        : interpolate( { args => $self }, $self->{display} )
      : $self->show("np");
    if ( $::config->{settings}->{truesf} ) {
	$res =~ s/#/♯/g;
	pos($res) = 1;
	$res =~ s/b/♭/g;
    }
    return $self->{parens} ? "($res)" : $res;
}

################ Chord objects: Nashville ################

package App::Music::ChordPro::Chord::Nashville;

our @ISA = 'App::Music::ChordPro::Chord::Base';
use String::Interpolate::Named;

sub transpose { $_[0] }

sub show {
    my ( $self, $np ) = @_;
    my $res = $self->{root_canon} . $self->{qual} . $self->{ext};
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "/" . lc($self->{bass});
    }
    return $np ? $res : $self->{parens} ? "($res)" : $res;
}

sub chord_display {
    my ( $self, $raw ) = @_;
    if ( $self->{display} ) {
	if ( $raw ) {
	    return $self->{display};
	}
	else {
	    return interpolate( { args => $self }, $self->{display} );
	}
    }

    my $res = $self->{root_canon} .
      "<sup>" . $self->{qual} . $self->{ext} . "</sup>";
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "<sub>/" . lc($self->{bass}) . "</sub>";
    }
    return $self->{parens} ? "($res)" : $res;
}

################ Chord objects: Roman ################

package App::Music::ChordPro::Chord::Roman;

our @ISA = 'App::Music::ChordPro::Chord::Base';
use String::Interpolate::Named;

sub transpose { $_[0] }

sub show {
    my ( $self, $np ) = @_;
    my $res = $self->{root_canon} . $self->{qual} . $self->{ext};
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "/" . lc($self->{bass});
    }
    return $np ? $res : $self->{parens} ? "($res)" : $res;
}

sub chord_display {
    my ( $self, $raw ) = @_;
    if ( $self->{display} ) {
	if ( $raw ) {
	    return $self->{display};
	}
	else {
	    return interpolate( { args => $self }, $self->{display} );
	}
    }

    my $res = $self->{root_canon} .
      "<sup>" . $self->{qual} . $self->{ext} . "</sup>";
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "<sub>/" . lc($self->{bass}) . "</sub>";
    }
    return $self->{parens} ? "($res)" : $res;
}

################ Chord objects: Annotations ################

package App::Music::ChordPro::Chord::Annotation;

use String::Interpolate::Named;

our @ISA = 'App::Music::ChordPro::Chord::Base';

sub transpose { $_[0] }
sub transcode { $_[0] }

sub name { $_[0]->{name} }

sub show {
    my ( $self ) = @_;
    my $res = $self->{text};
    return $res;
}

sub chord_display {
    my ( $self, $raw ) = @_;
    if ( $raw ) {
	return $self->{text};
    }
    else {
	return interpolate( { args => $self }, $self->{text} );
    }
}

# For convenience.
sub is_chord      { 0 };
sub is_annotation { 1 };

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
	    App::Music::ChordPro::Chords::Parser->reset_parsers("common");
	    next;
	}
	my $p0 = App::Music::ChordPro::Chords::Parser->default;
	my $p1 = App::Music::ChordPro::Chords::Parser->get_parser("common", 1);
	die unless $p0 eq $p1;
	my $p2 = App::Music::ChordPro::Chords::Parser->get_parser("nashville", 1);
	my $p3 = App::Music::ChordPro::Chords::Parser->get_parser("roman", 1);
	my $info = $p1->parse($_);
	$info = $p2->parse($_) if !$info && $p2;
	$info = $p3->parse($_) if !$info && $p3;
	print( "$_ => OOPS\n" ), next unless $info;
	print( "$_ ($info->{system}) =>" );
	print( " ", $info->transcode($_)->show, " ($_)" )
	  for qw( common nashville roman );
	print( " '", $info->agnostic, "' (agnostic)\n" );
	print( "$_ =>" );
	print( " ", $info->transpose($_)->show, " ($_)" ) for -2..2;
	print( "\n" );
#	my $clone = $info->clone;
#	delete($clone->{parser});
#	print( ::dump($clone), "\n" );
    }
}

1;
