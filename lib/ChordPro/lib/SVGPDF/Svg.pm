#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Svg :isa(SVGPDF::Element);

method process () {
    my $atts = $self->atts;
    return if $atts->{omit};	# for testing/debugging.

    my $xo = $self->xo;
    my $xoforms = $self->root->xoforms;

    delete $atts->{$_} for qw( xmlns:xlink xmlns:svg xmlns version );
    my ( $x, $y, $vwidth, $vheight, $vbox, $par, $tf ) =
      $self->get_params( $atts, qw( x:U y:U width:s height:s viewBox preserveAspectRatio:s transform:s ) );
    $self->nfi("nested svg transform") if $tf;
    $self->nfi("preserveAspectRatio") if $par;
    my $style = $self->style;

    my $parent;
    for ( @{ $self->root->xoforms } ) {
	next unless $_->{xo} eq $xo;
	$parent = $_;
	last;
    }
    croak("I feel like a motherless child") unless $parent;

    my $pwidth  = $parent->{width};
    my $pheight = $parent->{height};
    for ( $vwidth ) {
	$_ = $self->u( $_ || $pwidth, width => $pwidth );
    }
    for ( $vheight ) {
	$_ = $self->u( $_ || $pheight, width => $pheight );
    }

    $self->_dbg("pp w=$pwidth h=$pheight vw=$vwidth vh=$vheight");

    my @vb;			# viewBox: llx lly width height
    my @bb;			# bbox:    llx lly urx ury

    my $width;			# width of the vbox
    my $height;			# height of the vbox
    if ( $vbox ) {
	@vb     = $self->getargs($vbox);
	$width  = $self->u( $vb[2],
			    width => $pwidth );
	$height = $self->u( $vb[3],
			    width => $height );
    }
    else {
	$width  = $vwidth;
	$height = $vheight;
	@vb     = ( 0, 0, $width, $height );
	$vbox = "@vb";
    }

    # Get llx lly urx ury bounding box rectangle.
    @bb = $self->root->vb2bb_noflip(@vb);
    $self->_dbg( "vb $vbox => bb %.2f %.2f %.2f %.2f", @bb );
    warn( sprintf("vb $vbox => bb %.2f %.2f %.2f %.2f\n", @bb ))
      if $self->root->verbose && !$self->root->debug;

    my $new_xo = $self->root->pdf->xo_form;
    $new_xo->bbox(@bb);

    # Set up result forms.
    push( @$xoforms,
	  { xo     => $new_xo,
	    # Design (desired) width and height.
	    vwidth  => $vwidth  || $vb[2],
	    vheight => $vheight || $vb[3],
	    # viewBox (SVG coordinates)
	    vbox    => [ @vb ],
	    width   => $vb[2],
	    height  => $vb[3],
	    diag    => sqrt( $vb[2]**2 + $vb[3]**2 ) / sqrt(2),
	    # bbox (PDF coordinates)
	    bbox    => [ @bb ],
	    yflip   => 0,
	  } );
    $self->_dbg("XObject #", scalar(@$xoforms) );

    $self->traverse;

    my $scalex = 1;
    my $scaley = 1;
    my $dx = 0;
    my $dy = 0;
    if ( $vbox ) {
	my @pbb = $xo->bbox;	# parent
	if ( $vwidth ) {
	    $scalex = $vwidth / $vb[2];
	}
	if ( $vheight ) {
	    $scaley = $vheight / $vb[3];
	}
#	warn("pbbx @pbb\n");
#	warn("bbox @bb scale=$scalex/$scaley\n");
	if ( $par =~ /none/i ) {
	    $par = "";
	}
	else {
	    # Uniform scale.
#	    $scalex = $scaley = min( $scalex, $scaley );
	}
	if ( $par =~ /xM(ax|id|in)/i && $scalex > $scaley ) {
	    if ( $1 eq "ax" ) {
		$dx = max($pbb[0],$pbb[2]) - max($bb[0],$bb[2]);
	    }
	    elsif ( $1 eq "id" ) {
		$dx = (($pbb[2]-$pbb[0])/2) - (($bb[2]-$bb[0])/2);
	    }
	    else {
		$dx = min($pbb[0],$pbb[2]) - min($bb[0],$bb[2]);
	    }
	}
	if ( $par =~ /yM(in|id|ax)/i && $scaley > $scalex ) {
	    if ( $1 eq "ax" ) {
		$dy = max($pbb[1],$pbb[3]) - max($bb[1],$bb[3]);
	    }
	    elsif ( $1 eq "id" ) {
		$dy =
		  ((max($pbb[1],$pbb[3])-min($pbb[1],$pbb[3]))/2)
		  - ((max($bb[1],$bb[3])-min($bb[1],$bb[3]))/2)
	    }
	    else {
		$dy = min($pbb[1],$pbb[3]) - min($bb[1],$bb[3]);
	    }
	}
	if ( $par ) {
	    $scalex = $scaley = min( $scalex, $scaley );
	    $dx *= $scalex;
	    $dy *= $scaley;
	    warn("disp dx=$dx, dy=$dy\n");
	}
    }
    $self->_dbg( "xo object( %.2f%+.2f %.2f%+.2f %.3f %.3f ) %s",
		 $x, $dx, $y, $dy, $scalex, $scaley, $par//"" );
    warn(sprintf("xo object( %.2f%+.2f %.2f%+.2f %.3f %.3f ) %s\n",
		 $x, $dx, $y, $dy, $scalex, $scaley, $par//"" ))
      if $self->root->verbose && !$self->root->debug;
    $xo->object( $new_xo, $x+$dx, $y+$dy, $scalex, $scaley );

    pop( @$xoforms );

    $self->css_pop;

}

sub min ( $x, $y ) { $x < $y ? $x : $y }
sub max ( $x, $y ) { $x > $y ? $x : $y }

1;
