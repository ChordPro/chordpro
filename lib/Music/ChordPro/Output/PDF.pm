#!/usr/bin/perl

package Music::ChordPro::Output::PDF;

use strict;
use warnings;
use Data::Dumper;

sub generate_songbook {
    my ($self, $sb, $options) = @_;

    my $ps = page_settings();
    $ps->{pr} = PDFWriter->new( $ps );
    $ps->{pr}->file( "chordout.pdf" );

    my @book;
    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    $ps->{pr}->newpage;
	    push(@book, "{new_song}");
	}
	generate_song( $song, { ps => $ps, $options ? %$options : () } );
    }
    $ps->{pr}->finish;
    []
}

*Music::ChordPro::Songbook::generate_pdf = \&generate_songbook;

sub generate_song {
    my ($s, $options) = @_;

    my $ps = $options->{ps};
    my $x = $ps->{marginleft} + $ps->{offsets}->[0];
    my $y = $ps->{papersize}->[1] - $ps->{margintop};
    my $sb = $s->{body};

    if ( $s->{title} ) {
	$ps->{pr}->text( $s->{title}, $x, $y, $ps->{fonts}->{title} );
	$y -= $ps->{fonts}->{title}->{size};
    }

    if ( $s->{subtitle} ) {
	for ( @{$s->{subtitle}} ) {
	    $ps->{pr}->text( $_, $x, $y, $ps->{fonts}->{text} );
	    $y -= $ps->{fonts}->{text}->{size};
	}
    }

    if ( $s->{title} or $s->{subtitle} ) {
	$y -= $ps->{headspace};
    }

    foreach my $elt ( @{$sb} ) {

	if ( $elt->{type} eq "colb" ) {
	    $ps->{pr}->newpage;
	    $x = $ps->{marginleft} + $ps->{offsets}->[0];
	    $y = $ps->{papersize}->[1] - $ps->{margintop};
	    next;
	}

	if ( $elt->{type} eq "empty" ) {
	    $y -= $ps->{lineheight};
	    next;
	}

	if ( $elt->{type} eq "song" ) {
	    my $haschords = 1;
	    if ( $options->{a} ) { # TODO: better name :)
		$haschords = 0
		  unless join( "", @{ $elt->{chords} } ) =~ /\S/;
	    }
	    $y += $ps->{lineheight} unless $haschords;
	    songline( $elt, $x, $y, $ps );
	    $y -= $ps->{lineheight} * 2;
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    my $cy = $y + $ps->{lineheight} - 2;
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "song" ) {
		    songline( $e, $x, $y, $ps );
		    $y -= $ps->{lineheight} * 2;
		    next;
		}
		elsif ( $e->{type} eq "empty" ) {
		    $y -= $ps->{lineheight};
		    next;
		}
	    }
	    my $cx = $ps->{marginleft} + $ps->{offsets}->[0] - 10;
	    $ps->{pr}->add( sprintf("%d %d m %d %d l S",
				    $cx, $cy, $cx, $y+$ps->{lineheight} ) );
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    next;
	}

	if ( $elt->{type} eq "comment" ) {
	    my $font = $ps->{fonts}->{comment};
	    $ps->{pr}->setfont( $font );
	    my $text = $elt->{text};
	    my $w = $ps->{pr}->strwidth( $text );
	    my $y0 = $y;
	    my $y1 = $y0 + 0.8*($font->{size});
	    $y0 -= 0.2*($font->{size});
	    my $grey = "0.9";
	    my $x1 = $x + $w;
	    $ps->{pr}->add("q",
			   "$grey $grey $grey rg $grey $grey $grey RG",
			   "3 w",
			   "$x $y0 m $x $y1 l $x1 $y1 l $x1 $y0 l b",
			   "Q");
	    $ps->{pr}->text( $text, $x, $y );
	    $y -= $ps->{lineheight};
	    next;
	}
    }
}

sub songline {
    my ( $elt, $x, $y, $ps ) = @_;
    my $ftext = $ps->{fonts}->{text};
    my $fchord = $ps->{fonts}->{chord};
    my $w = 0;
    foreach ( 0..$#{$elt->{chords}} ) {
	my $chord = $elt->{chords}->[$_];
	my $phrase = $elt->{phrases}->[$_];
	$ps->{pr}->text( $chord, $x+$w, $y, $fchord );
	my $xto = $ps->{pr}->text( $phrase, $x+$w, $y-$ps->{lineheight}+2, $ftext );
	$w = $xto - $x;
    }
}

sub page_settings {
  # Pretty hardwired for now.
  { papersize     => [ 595, 840 ],	# A4, portrait
    marginleft    => 40,
    margintop     => 40,
    marginbottom  => 40,
    marginright   => 40,
    headspace     => 20,
    offsets       => [ 0, 0 ],		# col 1, col 2
    lineheight    => 14,
    fonts      => {
	title   => { name => 'Times-Bold',
		     size => 14 },
	text    => { name => 'Times-Roman',
		     size => 12 },
        chord   => { name => 'Helvetica-Oblique',
		     size => 12 },
        comment => { name => 'Times-Roman',
		     size => 12 },
    },
    xxfonts         => {
        text =>  { file => $ENV{HOME}.'/.fonts/DejaVuSerif.ttf',
		   size => 12 },
        chord => { file => $ENV{HOME}.'/.fonts/GillSans-Italic.ttf',
		   size => 12 },
    },
  };
}

package PDFWriter;

use strict;
use warnings;
use PDF::Reuse;
use Data::Dumper;
use Encode;

sub new {
    my ( $pkg, $ps ) = @_;
    bless { ps => $ps }, $pkg;
}

sub text {
    my ( $self, $text, $x, $y, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};

    $font->{file} ? prTTFont( $font->{file} ) : prFont( $font->{name} );
    prFontSize( $font->{size} );
    $text = encode( "cp1250", $text ) unless $font->{file};
    my ( undef, $xto ) = prText( $x, $y, $text );
    return $xto;
}

sub setfont {
    my ( $self, $font, $size ) = @_;
    $self->{font} = $font;
    $self->{fontsize} = $size || $font->{size};
    $font->{file} ? prTTFont( $font->{file} ) : prFont( $font->{name} );
    prFontSize( $self->{fontsize} );
}

sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};
    prStrWidth( $text,
		$font->{file} || $font->{name},
		$font->{size} );
}

sub newpage {
    my ( $self ) = @_;
    prPage();
}

sub add {
    my ( $self, @text ) = @_;
    prAdd( "@text" );
}

sub file {
    my ( $self, @args ) = @_;
    prFile( @args );
}

sub finish { prEnd() }

1;
