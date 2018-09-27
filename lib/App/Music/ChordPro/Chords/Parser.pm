#! perl

use strict;
use warnings;
use utf8;

my $parsers = {};

package App::Music::ChordPro::Chords::Parser;

sub new {
    my ( $pkg, $init ) = @_;
    my $self = bless { chord_cache => {} } => $pkg;
    $self->load_notes($init->{notes});
    $self->{system} = $init->{notes}->{system} if $init->{notes};
    $self->{system} //= "unknown";
    $parsers->{$self->{system}} = $self;
    return $self;
}

# The default parser has built-in support for common (dutch) note
# names.

my $default_parser;

sub default {
    my ( $pkg ) = @_;
    return $default_parser //=
      $pkg->new
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

sub parse {
    my ( $self, $chord ) = @_;
    $self->{chord_cache}->{$chord} //=
      $self->parse_chord($chord)
      || $parsers->{nashville}->parse_chord($chord)
      || $parsers->{roman}->parse_chord($chord);
}

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
    bless $info => 'App::Music::ChordPro::Chord';

    my $q = $+{qual} // "";
    $info->{qual_orig} = $q;
    $q = "-" if $q eq "m";
    $q = "+" if $q eq "aug";
    $q = "0" if $q eq "dim";
    $info->{qual} = $q;

    my $x = $+{ext} // "";
    $info->{ext_orig} = $x;
    $x = "sus4" if $x eq "sus";
    $info->{ext} = $x;

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
   "add9",
   "alt",
   "h",
   "h7",
   "h9",
   ( map { "sus$_" } "", "2", "4", "9" ),
   ( map { "6sus$_" } "", "2", "4" ),
   ( map { "7sus$_" } "", "2", "4" ),
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

sub get_parser {
    my ( $self, $system, $nofallback ) = @_;
    return $parsers->{$system} if $parsers->{$system};
    return if $nofallback;
    warn("No parser for $system, falling back to default\n");
    return $self->default;
}

sub parsers {
    my ( $self ) = @_;
    return {%$parsers};
}

sub intervals { $_[0]->{intervals} }

################ Parsing Nashville notated chords ################

package App::Music::ChordPro::Chords::Parser::Nashville;

$parsers->{nashville} = __PACKAGE__;

our @ISA = qw(App::Music::ChordPro::Chords::Parser);

my $n_pat = qr/(?<shift>[b#]?)(?<root>[1-7])/;

my %nmap = ( 1 => 0, 2 => 2, 3 => 4, 4 => 5, 5 => 7, 6 => 9, 7 => 11 );

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
		 name   => $_[1],
		 root   => $+{root},
	       };
    bless $info => 'App::Music::ChordPro::Chord::Nashville';

    my $q = $+{qual} // "";
    $info->{qual_orig} = $q;
    $q = "-" if $q eq "m";
    $q = "+" if $q eq "aug";
    $q = "0" if $q eq "dim";
    $info->{qual} = $q;

    my $x = $+{ext} // "";
    $info->{ext_orig} = $x;
    $x = "sus4" if $x eq "sus";
    $info->{ext} = $x;

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

################ Parsing Roman notated chords ################

package App::Music::ChordPro::Chords::Parser::Roman;

$parsers->{roman} = __PACKAGE__;

our @ISA = qw(App::Music::ChordPro::Chords::Parser);

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

    return unless $chord =~ /^$r_pat(?<qual>\+|0|aug|dim)?(?<ext>.*)$/;

    my $info = { system => "roman",
		 name   => $_[1],
		 root   => $+{root} };
    bless $info => 'App::Music::ChordPro::Chord::Roman';

    my $r = $+{root};
    my $q = $+{qual} // "";
    $info->{qual_orig} = $q;
    $q = "-" if $r eq lc($r);
    $q = "+" if $q eq "aug";
    $q = "0" if $q eq "dim";
    $info->{qual} = $q;

    my $x = $+{ext} // "";
    $info->{ext_orig} = $x;
    $x = "sus4" if $x eq "sus";
    $x = "^7" if $x eq "7+";
    $info->{ext} = $x;

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

################ Transformations ################

package App::Music::ChordPro::Chord;

sub clone {
    my ( $self ) = @_;
    bless { %$self } => ref($self);
}

sub reformat {
    my ( $self ) = @_;
    my $res = $self->{root_canon};
    $res .= $self->{qual_orig} if $self->{qual};
    $res .= $self->{ext_orig} if $self->{ext};
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$res .= "/" . $self->{bass_canon};
    }
    return $res;
}

sub transpose {
    my ( $self, $xpose ) = @_;
    return $self unless $xpose;
    my $info = $self->clone;
    my $p = $self->{parser};
    $info->{root_ord} = ( $self->{root_ord} + $xpose ) % $p->intervals;
    $info->{root_canon} = $p->root_canon($info->{root_ord},$xpose > 0);
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$info->{bass_ord} = ( $self->{bass_ord} + $xpose ) % $p->intervals;
	$info->{bass_canon} = $p->root_canon($info->{bass_ord},$xpose > 0);
    }
    $info->{root_mod} = $info->{bass_mod} = $xpose <=> 0;
    $info;
}

sub transcode {
    my ( $self, $xcode ) = @_;
    return $self unless $xcode;
    my $info = $self->clone;
    my $p = $self->{parser}->get_parser($xcode);
    $info->{root_canon} = $p->root_canon($info->{root_ord}, $info->{root_mod});
    if ( $self->{bass} && $self->{bass} ne "" ) {
	$info->{bass_canon} = $p->root_canon($info->{bass_ord},$info->{bass_mod});
    }
    $info;
}

package App::Music::ChordPro::Chord::Nashville;

our @ISA = 'App::Music::ChordPro::Chord';

my @nmap = ( 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6, 7, 1 );

sub reformat {
    my ( $self ) = @_;
    my $res = sprintf( "%s%d",
		       ("b","","#")[1+$self->{root_mod}],
		       $nmap[$self->{root_ord}-$self->{root_mod}]);
    $res .= $self->{qual_orig};
    $res .= $self->{ext_orig} if $self->{ext};
    $res .= "/" . sprintf( "%s%d",
			   ("b","","#")[1+$self->{bass_mod}],
			   @nmap[$self->{bass_ord}])
      if $self->{bass};
    return $res;
}

sub intervals { 12 }

sub transpose { $_[0] }

package App::Music::ChordPro::Chord::Roman;

our @ISA = 'App::Music::ChordPro::Chord';

my @rmap = qw( I I II II III IV IV V V VI VI VII );

sub reformat {
    my ( $self ) = @_;
    my $res = $rmap[$self->{root_ord}];
    if ( $self->{qual} ne '-' ) {
	$res .= $self->{qual_orig} if $self->{qual} ne '-';
    }
    else {
	$res = lc($res);
    }
    $res .= $self->{ext_orig} if $self->{ext_orig};
    $res .= "/" . $rmap[$self->{bass_ord}]
      if $self->{bass};
    return $res;
}

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
	print( "$_ => OOPS\n" ), next unless $info;
	my $clone = $info->clone;
	delete($clone->{parser});
	print( "$_ => ",
#	       $p->reformat($info),
#	       " ", $p->get_parser("roman")->reformat($info),
#	       " ", $p->get_parser("nashville")->reformat($info),
	       " ", DDumper($clone) );
	print( "$_ =>" );
	print( " ", $info->transpose($_)->reformat ) for -1..1;
	print( "\n" );
    }
}

1;
