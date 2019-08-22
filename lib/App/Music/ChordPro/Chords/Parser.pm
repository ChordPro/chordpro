#! perl

use strict;
use warnings;
use utf8;
use Carp;

my $parsers = {};

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

sub new {
    my ( $pkg, $init ) = @_;
    my $self = bless { chord_cache => {} } => $pkg;
    return App::Music::ChordPro::Chords::Parser->default
      unless $init && $init->{notes};

    my $notes = $init->{notes};
    my $system = $notes->{system};
    Carp::croak("Missing notes system in parser creation")
	unless $system;

    if ( $system eq "nashville" ) {
	return App::Music::ChordPro::Chords::Parser::Nashville->new($init);
    }
    if ( $system eq "roman" ) {
	return App::Music::ChordPro::Chords::Parser::Roman->new($init);
    }

    # Custom parser.
    bless $self => 'App::Music::ChordPro::Chords::Parser::Common';
    $self->load_notes($notes);
    $self->{system} = $system;
    $self->{target} = 'App::Music::ChordPro::Chord::Common';
    $self->{movable} = $notes->{movable};
    $parsers->{$self->{system}} = $self;
    return $self;
}

# The default parser has built-in support for common (dutch) note
# names.

sub default {
    my ( $pkg ) = @_;
    return $parsers->{common} //=
      App::Music::ChordPro::Chords::Parser::Common->new
      ( { "notes" =>
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
    my ( $self, $chord ) = @_;
    $self->{chord_cache}->{$chord} //= $self->parse_chord($chord);
}

# Virtual.
sub parse_chord {
    Carp::confess("Virtual method 'parse_chord' not defined");
}

# Fetch a parser for a known system, with fallback.
sub get_parser {
    my ( $self, $system, $nofallback ) = @_;
    return $parsers->{$system} if $parsers->{$system};
    return if $nofallback;
    warn("No parser for $system, falling back to default\n");
    return $self->default;
}

# The list of instantiated parsers.
sub parsers { return { %$parsers } }

# The number of intervals for this note system.
sub intervals { $_[0]->{intervals} }

################ Parsing Common notated chords ################

package App::Music::ChordPro::Chords::Parser::Common;

our @ISA = qw( App::Music::ChordPro::Chords::Parser );

sub parse_chord {
    my ( $self, $chord ) = @_;

    my $bass;
    if ( $chord =~ m;^(.*)/(.*); ) {
	$chord = $1;
	$bass = $2;
    }

    my $c_pat = $self->{c_pat};
    my $n_pat = $self->{n_pat};

    return unless $chord =~ /^$c_pat$/;
    return unless my $r = $+{root};

    my $info = { system => $self->{system},
		 parser => $self,
		 name => $_[1],
		 root => $r };
    bless $info => $self->{target};

    my $q = $+{qual} // "";
    $info->{qual} = $q;
    $q = "-" if $q eq "m" || $q eq "min";
    $q = "+" if $q eq "aug";
    $q = "0" if $q eq "dim";
    $info->{qual_canon} = $q;

    my $x = $+{ext} // "";
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
    };

    $ordmod->("root");

    return $info unless $bass;
    return unless $bass =~ /^$n_pat$/;
    $info->{bass} = $bass;
    $ordmod->("bass");

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
   "7sus",
   "7susadd3",
   "7\\+",			# REGEXP!!!
   "9",
   "9\\+",			# REGEXP!!!
   "911",
   "9#11",
   "9#5",
   "9b5",
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
   ( map { "add$_"   }     "2", "4", "9" ),
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
    my ( $self, $n ) = @_;

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
    foreach ( sort keys %ns_tbl ) {
	$n_pat .= "$_|";
    }
    foreach ( sort keys %nf_tbl ) {
	next if $ns_tbl{$_};
	$n_pat .= "$_|";
    }
    substr( $n_pat, -1, 1, ")" );

    # Pattern to match chord names.
    my $c_pat = "(?<root>" . $n_pat . ")";
    $c_pat .= "(?:";
    $c_pat .= "(?<qual>-|min|m(?!aj))".
      "(?<ext>" . join("|", keys(%$additions_min)) . ")|";
    $c_pat .= "(?<qual>\\+|aug)".
      "(?<ext>" . join("|", keys(%$additions_aug)) . ")|";
    $c_pat .= "(?<qual>0|dim)".
      "(?<ext>" . join("|", keys(%$additions_dim)) . ")|";
    $c_pat .= "(?<qual>)".
      "(?<ext>" . join("|", keys(%$additions_maj)) . ")";
    $c_pat .= ")";
    $c_pat = qr/$c_pat/;
    $n_pat = qr/$n_pat/;

    # Store in the object.
    $self->{n_pat}    = $n_pat;
    $self->{c_pat}    = $c_pat;
    $self->{ns_tbl}   = \%ns_tbl;
    $self->{nf_tbl}   = \%nf_tbl;
    $self->{ns_canon} = \@ns_canon;
    $self->{nf_canon} = \@nf_canon;
    $self->{intervals} = @ns_canon;
}

sub root_canon {
    my ( $self, $root, $sharp ) = @_;
    ( $sharp ? $self->{ns_canon} : $self->{nf_canon} )->[$root];
}

# Has chord diagrams.
sub has_diagrams { !$_[0]->{movable} }

# Movable notes system.
sub movable { $_[0]->{movable} }

################ Parsing Nashville notated chords ################

package App::Music::ChordPro::Chords::Parser::Nashville;

our @ISA = qw(App::Music::ChordPro::Chords::Parser::Common);

$parsers->{nashville} = __PACKAGE__->new;

sub new {
    my ( $pkg, $init ) = @_;
    my $self = bless { chord_cache => {} } => $pkg;
    $self->{system} = "nashville";
    $self->{target} = 'App::Music::ChordPro::Chord::Nashville';
    return $self;
}

my $n_pat = qr/(?<shift>[b#]?)(?<root>[1-7])/;

my %nmap = ( 1 => 0, 2 => 2, 3 => 4, 4 => 5, 5 => 7, 6 => 9, 7 => 11 );
my @nmap = ( 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6, 7, 1 );

sub parse_chord {
    my ( $self, $chord ) = @_;

    $chord =~ tr/\x{266d}\x{266f}\x{0394}\x{f8}\x{b0}/b#^h0/;

    my $bass;
    if ( $chord =~ m;^(.*)/(.*); ) {
	$chord = $1;
	$bass = $2;
    }

    return unless $chord =~ /^$n_pat(?<qual>-|\+|0|aug|m(?!aj)|dim)?(?<ext>.*)$/;

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
    my ( $self, $root, $sharp ) = @_;
    no warnings 'qw';
    $sharp
      ? qw( 1 #1 2 #2 3 4 #4 5 #5 6 #6 7 )[$root]
      : qw( 1 b2 2 b3 3 4 b5 5 b6 6 b7 7 )[$root]
}

# Has chord diagrams.
sub has_diagrams { 0 }

# Movable notes system.
sub movable { 1 }

################ Parsing Roman notated chords ################

package App::Music::ChordPro::Chords::Parser::Roman;

our @ISA = qw(App::Music::ChordPro::Chords::Parser::Common);

$parsers->{roman} = __PACKAGE__->new;

sub new {
    my ( $pkg, $init ) = @_;
    my $self = bless { chord_cache => {} } => $pkg;
    $self->{system} = "roman";
    $self->{target} = 'App::Music::ChordPro::Chord::Roman';
    return $self;
}

my $r_pat = qr/(?<shift>[b#]?)(?<root>(?i)iii|ii|iv|i|viii|vii|vi|v)/;

my %rmap = ( I => 0, II => 2, III => 4, IV => 5, V => 7, VI => 9, VII => 11 );

sub parse_chord {
    my ( $self, $chord ) = @_;

    $chord =~ tr/\x{266d}\x{266f}\x{0394}\x{f8}\x{b0}/b#^h0/;

    my $bass;
    if ( $chord =~ m;^(.*)/(.*); ) {
	$chord = $1;
	$bass = $2;
    }

    return unless $chord =~ /^$r_pat(?<qual>\+|0|aug|dim|h)?(?<ext>.*)$/;

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
    my ( $self, $root, $sharp, $minor ) = @_;
    return lc( $self->root_canon( $root, $sharp ) ) if $minor;
    no warnings 'qw';
    $sharp
      ? qw( I #I II #II III IV #IV V #V VI #VI VII )[$root]
      : qw( I bII II bIII III IV bV V bVI VI bVII VII )[$root]
}

# Has chord diagrams.
sub has_diagrams { 0 }

# Movable notes system.
sub movable { 1 }

################ Chord objects: Common ################

package App::Music::ChordPro::Chord::Common;

sub clone {
    my ( $self ) = @_;
    bless { %$self } => ref($self);
}

sub show {
    my ( $self ) = @_;
    my $res = $self->{root} . $self->{qual} . $self->{ext};
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "/" . $self->{bass};
    }
    return $res;
}

# Returns a representation indepent of notation system.
sub agnostic {
    my ( $self ) = @_;
    join( " ", "",
	  $self->{root_ord}, $self->{qual_canon},
	  $self->{ext_canon}, $self->{bass_ord} // () );
}

sub transpose {
    my ( $self, $xpose ) = @_;
    return $self unless $xpose;
    my $info = $self->clone;
    my $p = $self->{parser};
    $info->{root_ord} = ( $self->{root_ord} + $xpose ) % $p->intervals;
    $info->{root_canon} = $info->{root} =
      $p->root_canon( $info->{root_ord},
		      $xpose > 0,
		      $info->{qual_canon} eq "-" );
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$info->{bass_ord} = ( $self->{bass_ord} + $xpose ) % $p->intervals;
	$info->{bass_canon} = $info->{bass} =
	  $p->root_canon($info->{bass_ord},$xpose > 0);
    }
    $info->{root_mod} = $info->{bass_mod} = $xpose <=> 0;
    $info;
}

sub transcode {
    my ( $self, $xcode ) = @_;
    return $self unless $xcode;
    return $self if $self->{system} eq $xcode;
    my $info = $self->clone;
    my $p = $self->{parser}->get_parser($xcode);
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
	  $p->root_canon($info->{bass_ord},$info->{bass_mod});
    }
    bless $info => $p->{target};
}

################ Chord objects: Nashville ################

package App::Music::ChordPro::Chord::Nashville;

our @ISA = 'App::Music::ChordPro::Chord::Common';

#my @nmap = ( 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6, 7, 1 );

sub intervals { 12 }

sub transpose { $_[0] }

################ Chord objects: Roman ################

package App::Music::ChordPro::Chord::Roman;

our @ISA = 'App::Music::ChordPro::Chord::Common';

my @rmap = qw( I I II II III IV IV V V VI VI VII );

sub intervals { 12 }

sub transpose { $_[0] }

################ Testing ################

package main;

unless ( caller ) {
    require DDumper;
    my $p = App::Music::ChordPro::Chords::Parser->default;
    binmode(STDOUT, ':utf8');
    foreach ( @ARGV ) {
	my $info = $p->parse($_);
	$info ||= $parsers->{nashville}->parse($_);
	$info ||= $parsers->{roman}->parse($_);
	print( "$_ => OOPS\n" ), next unless $info;
	print( "$_ ($info->{system}) =>" );
	print( " ", $info->transcode($_)->show, " ($_)" )
	  for sort keys %$parsers;
	print( " '", $info->agnostic, "' (agnostic)\n" );
	print( "$_ =>" );
	print( " ", $info->transpose($_)->show, " ($_)" ) for -2..2;
	print( "\n" );
	my $clone = $info->clone;
	delete($clone->{parser});
	print( DDumper($clone), "\n" );
    }
}

1;
