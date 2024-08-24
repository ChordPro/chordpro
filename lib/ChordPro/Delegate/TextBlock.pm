#! perl

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

package ChordPro::Delegate::TextBlock;

# Combine one or more text lines into a single xforms object.
#
# Attributes:
#
#  width:      Width of the resultant object.
#              Defaults to the actual width (tight fit) of the texts.
#  height:     Height of the resultant object.
#              Defaults to the actual height of the text, including
#              the advance of the last line (non-tight fit).
#              When height or padding is set, a tight fit is used.
#  padding:    Provide padding between the object and the inner text.
#              When height or padding is set, a tight fit is used.
#  flush:      Horizontal text flush (left, center, right).
#  vflush:     Vertical text flush (top, middle, bottom).
#  textstyle:  Style (font) to be used. Must be one of "text", "chords",
#              "comment" etc.
#  textsize:   Initial value for the text size.
#  textspacing: Text spacing. A factor (e.g. 1.2) or "flex".
#  textcolor:  Initial color for the text.
#  background: Background color of the object.
#
# Common attributes:
#
#  id:         Make asset instead of image.
#  align:      Image alignment (left, center, right)
#  border:     Draw border around the image.

use ChordPro::Utils;

sub DEBUG() { $::config->{debug}->{txtblk} }

sub txt2xform( $self, %args ) {
    my $elt = $args{elt};

    my $ps = $self->{_ps};
    my $pr = $ps->{pr};
    my $opts = { %{$elt->{opts}} };

    # Text style must be one of the known styles (text, chord, comment, ...).
    my $style = delete($opts->{textstyle}) // "text";
    unless ( defined($ps->{fonts}->{$style} ) ) {
	warn("TextBlock: Unknown font style \"$style\", using \"text\"\n");
	$style = "text";
    }
    my $font  = $ps->{fonts}->{$style};
    my $bgcol = $pr->_bgcolor($font->{background});
    $bgcol = "" if $bgcol eq "none";
    my $vsp = delete($opts->{textspacing}) // "flex";
    my $sp = $vsp eq "flex"
      ? ($font->{leading} || $ps->{spacing}->{$style} || 1) : $vsp;
    my $size   = fontsize( delete($opts->{textsize}), $font->{size} );
    my $color  = delete($opts->{textcolor});
    my $flush  = delete($opts->{flush})  // "left";
    my $vflush = delete($opts->{vflush}) // "top";

    my $data = $elt->{data};
    if ( $color || $bgcol ) {
	my $span = "";
	$span .= " color='$color'" if $color;
	$span .= " background='$bgcol'" if $bgcol;
	$data = [ map { "<span$span>$_</span>" } @$data ];
    }
    my $padding  = delete($opts->{padding});

    # New xo, and put it in text mode.
    my $xo = $pr->{pdf}->xo_form;
    $xo->textstart;

    # Pre-pass to establish the actual width/height.
    my ( $awidth, $aheight ) = ( 0, undef );
    my ( $w, $h );
    for ( @$data ) {
	( $w, $h ) = $pr->strwidth( $_, $font, $size );
	$awidth = $w if $w > $awidth;
	if ( defined($aheight) ) {
	    $aheight += $vsp eq "flex" ? ($h||$size)*$sp : $size*$vsp;
	}
	else {
	    $aheight = ($h||$size);
	}
    }

    # Desired width (includes padding).
    my ( $width, $height );
    if ( $width = delete($opts->{width}) ) {
	# Note that using dimension is not yet operational.
	$width = dimension( $width, width => $size ) - 2*($padding||0);
    }
    else {
	$width = $awidth;
    }

    # Correction for tight y-fit.
    my $ycorr = ($vsp eq "flex" ? $h||$size : $size) * ($sp - 1);

    # Desired height (includes padding).
    if ( $height = delete($opts->{height}) ) {
	# Note that using dimension is not yet operational.
	$height = dimension( $height, width => $size ) - 2*($padding||0);
    }
    else {
	$height = $aheight - $ycorr;
	$ycorr = 0 unless defined($padding);
    }
    # Width and height are now the 'inner' box (w/o padding).

    # With padding, we cancel the leading after the last line.
    if ( defined $padding ) {
	$ycorr = 0;
    }
    else {
	$padding = 0;
    }
    # Note that the padding will be dealt with in the bbox.

    # Draw background.
    $xo->bbox( -$padding, -$padding, $width+$padding, $height+$padding );
    if ( my $bg = delete($opts->{background}) ) {
	$xo->rectangle( $xo->bbox );
	$xo->fill_color($bg);
	$xo->fill;
    }

    my $y = $height - $ycorr;

    if ( $flush eq "right" || $flush eq "center"
	 || $vflush eq "middle" || $vflush eq "bottom" ) {

	if ( $vflush eq "middle" ) {
	    $y += ($aheight-$height)/2;
	}
	elsif ( $vflush eq "bottom" ) {
	    $y += $aheight - $height;
	}

	for ( @$data ) {
	    my $h = $pr->strheight( $_, $font, $size ) || $size;
	    $pr->{tmplayout}->set_width($width);
	    $pr->{tmplayout}->set_alignment($flush);
	    $pr->{tmplayout}->show( 0, $y, $xo );
	    $y -= ($vsp eq "flex" ? $h : $size) * $sp;
	}
    }
    else {			# assume top/left
	for ( @$data ) {
	    my $h = $pr->strheight( $_, $font, $size ) || $size;
	    $pr->{tmplayout}->set_alignment($flush);
	    $pr->{tmplayout}->show( 0, $y, $xo );
	    $y -= ($vsp eq "flex" ? $h : $size) * $sp;
	}
    }

    # Finish.
    $xo->textend;

    return
      { type      => "image",
	subtype   => "xoform",
	line      => $elt->{line},
	data      => $xo,
	width     => $width  + 2*$padding,
	height    => $height + 2*$padding,
	opts      => { align => "left", %$opts },
      };
}

# Pre-scan.
sub options( $data ) { {} }

1;
