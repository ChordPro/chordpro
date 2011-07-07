#!/usr/bin/perl

use strict;
use warnings;

#use open qw<:std :encoding(UTF-8)>;

use FindBin;

use lib "$FindBin::Bin/lib";
use Music::ChordPro::Songbook;

my $s = Music::ChordPro::Songbook->new;

#$s->parsefile("svn/trunk/examples/everybody-hurts.crd");
#$s->parsefile("../examples/love-me-tender.cho");
#$s->parsefile("s.crd");

$s->parsefile( shift );
#$s->transpose(-2);		# NYI

use Data::Dumper;
warn(Dumper($s), "\n");

#use Music::ChordPro::Output::ChordPro;
#print(join("\n",@{Music::ChordPro::Output::ChordPro::generate_songbook($s, { neat => 1 })}),"\n");

#use Music::ChordPro::Output::LaTeX;
#print(join("\n",@{Music::ChordPro::Output::LaTeX::generate_songbook($s)}),"\n");

use Music::ChordPro::Output::PDF;
Music::ChordPro::Output::PDF::generate_songbook($s, { a => 1 });

#use Music::ChordPro::Output::LilyPond;
#print(join("\n",@{Music::ChordPro::Output::LilyPond::generate_songbook($s)}),"\n");
