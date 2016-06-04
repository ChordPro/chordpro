#!/usr/bin/perl

package App::Music::ChordPro::Output::LilyPond;

use strict;
use warnings;
use feature 'switch';

sub generate_songbook {
    my ($self, $sb, $options) = @_;
    my @book;
    my $tmpl = std_template();
    @book = split( /\n/, $tmpl );

    foreach my $song ( @{$sb->{songs}} ) {
	generate_song(\@book, $song, $options);
    }
    \@book;
}

sub generate_song {
    my ($book, $s, $options) = @_;

    my (@h, @l, @m, @c);	# heading, lyrics, melody, chords

    push( @h,
	  "\\header {",
	  "  title = \"" . ($s->{title}||"") . "\"" );
    if ( defined $s->{subtitle} ) {
	push(@h, map { +"  subtitle = \"$_\"" } @{$s->{subtitle}});
    }

    push(@h, "}");

    foreach my $elt ( @{$s->{body}} ) {

	if ( $elt->{type} eq "song" ) {
	    songline( \(@l, @m, @c), $elt);
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    # push(@s, "\\begin{chorus}");
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "song" ) {
		    songline( \(@l, @m, @c), $e );
		    next;
		}
	    }
	    # push(@s, "\\end{chorus}");
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    next;
	    push(@h, "");
	    push(@h, "\\begin{verbatim}");
	    push(@h, @{$elt->{body}});
	    push(@h, "\\end{verbatim}");
	    push(@h, "");
	    next;
	}

	if ( $elt->{type} eq "comment" ) {
	    next;
	    push(@h, "");
	    push(@h, "\\comment{" . ltx($elt->{text}) . "}");
	    push(@h, "");
	    next;
	}
    }

    # Process template.
    my @res;
    foreach my $line ( @$book ) {
	next unless $line =~ /^%\[%\s*(\S+)\s*%\]/;
	given ( $1 ) {
	    when ( 'header' ) {
		$line = join( "\n", @h );
	    }
	    when ( 'lyrics' ) {
		$line = join( "\n", "theLyrics = \\lyricmode {", @l, "}" );
	    }
	    when ( 'melody' ) {
		$line = join( "\n", "theMelody = \\relative c' {", @m, "}" );
	    }
	    when ( 'chords' ) {
		$line = join( "\n", "theChords = \\chordmode {", @c, "}" );
	    }
	}
    }

}

my $pchord;

sub songline {
    my ( $l, $m, $c, $elt) = @_;

    my $lline = "  ";
    my $cline = "  ";
    my $mline = "  ";

    for ( my $i = 0; $i < @{$elt->{chords}}; $i++ ) {
	my $phrase = $elt->{phrases}->[$i];
	unless ( $lline =~ /\s$/ || $phrase =~ /^\s/ ) {
	    $lline .= " -- ";
	}
	$lline .= $phrase;
	my $t = scalar( split ( ' ', $phrase ) );
	$mline .= ( "c4 " x $t );
	$pchord = $elt->{chords}->[$i] || $pchord || 'r';
	$cline .= lp($pchord, $t) . " ";
    }

    push( @$l, $lline );
    $lline =~ s/^./%/;
    push( @$c, $lline );
    push( @$c, $cline );
    push( @$m, $lline );
    push( @$m, $mline . " \\break" );
}

sub lp {
    my $txt = lc(shift);
    my $dur = shift;
    my $res = "";

    # Break long durations.
    while ( $dur > 4 ) {
	$res .= lp( $txt, 4 ) . " ";
	$dur -= 4;
    }

    # Chord analysis and rendering.
    my ($cname, $rest) = $txt =~ /^([a-hr](?:(?:e|i)?s)?)(.*)/;

    $cname =~ s/^(.)s/${1}es/;	# as -> aes, es -> ees

    $res .= $cname;

    if ( $dur ) {
	$dur = qw( x 4 2 2. 1 )[$dur];
	$res .= $dur if $dur;
    }

    given ( $rest ) {
	when ( '7' ) { $res .= ':7'; }
	when ( 'm' ) { $res .= ':m'; }
    }

    return $res;
}

sub std_template {

    return <<'EOD';
\version "2.12.3"

\layout {
  indent = #0
  ragged-right = ##t
  ragged-last = ##t
  ragged-bottom = ##t
}

%[% header %]

%[% lyrics %]

%[% melody %]

%[% chords %]

\score {
  <<
    \new ChordNames {
       \set chordChanges = ##t
       \theChords
    }
    \new Devnull = "vocal" { \theMelody }
    \new Lyrics \lyricsto "vocal" \theLyrics
  >>
  \layout {
    \context {
      \Score
      \remove Bar_number_engraver
    }
  }
}
EOD

}

1;

__END__
# An alternative approach:

\version "2.18"

the_words = \lyricmode {
  "Swing"1
  "low, sweet"
  "chari-"
  "ot, coming for to carry me"
  "home."
  \break
  "Swing"
  "low, sweet"
  "chari-"
  "ot, coming for to"
  "carry me"
  "home."
}

the_chords = \chordmode {
  s1
  c
  f
  c
  g
  s
  c
  f
  c
  g
  c
}

\score {
  <<
    \new ChordNames \the_chords
    %\new FretBoards \the_chords
    \new Lyrics \the_words
  >>
  \layout {
    indent = 0
    ragged-right = ##t
    \override LyricText.self-alignment-X = #LEFT
    \context { \Score \remove "Bar_number_engraver" }
  }
}
