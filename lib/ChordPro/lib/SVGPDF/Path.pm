#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Path :isa(SVGPDF::Element);

use SVGPDF::Contrib::PathExtract qw( extract_path_info );

method process () {
    my $atts = $self->atts;
    my $xo   = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    if ( defined $atts->{id} ) {
	$self->root->defs->{ "#" . $atts->{id} } = $self;
	# MathJax uses curves to draw glyphs. These glyphs are filles
	# *and* stroked with a very small stroke-width. According to
	# the PDF specs, this should yield a 1-pixel (device pixel)
	# stroke, which results in fat glyphs on screen.
	# To avoid this, disable stroke when drawing MathJax glyphs.
	if ( $atts->{id} =~ /^MJX-/ ) {
	    $atts->{stroke} = 'none';
	}
    }

    my ( $d, $tf ) = $self->get_params( $atts, "d:!", "transform:s" );

    ( my $t = $d ) =~ s/\s+/ /g;
    $t = substr($t,0,20) . "..." if length($t) > 20;
    $self->_dbg( $self->name, " d=\"$t\"", $tf ? " tf=\"$tf\"" : "" );
    return unless $d;

    $self->_dbg( "+ xo save" );
    $xo->save;
    $self->set_transform($tf);
    $self->set_graphics;

    # Get path info, turning relative coordinates into absolute
    # and eliminate S and T curves.
    my @d = extract_path_info( $d, { absolute => 1, no_smooth => 1 } );

    my $open;			# path is open

    my $paint = $self->_paintsub;

    # Initial x,y for path, if open. See 'z'.
    my ( $ix, $iy );

    # Current point. Starting point of this path.
    # Since we're always use absolute coordinates, this is the
    # starting point for subpaths as well.
    my ( $cx, $cy ) = ( 0, 0 );

    # For debugging: collect control points.
    my @cp;

    my $id = -1;		# for diagnostics
    while ( @d ) {
	my $d = shift(@d);
	my $op = $d->{svg_key};
	$id++;

	# Reset starting point for the subpath.
	my ( $x, $y ) = ( 0, 0 );

	# Remember initial point of path.
	$ix = $cx, $iy = $cy unless $open++ || $op eq "Z";

	warn(sprintf("%s[%d] x=%.2f,y=%.2f cx=%.2f,cy=%.2f ix=%.2f,iy=%.2f\n",
		     $op, $id, $x, $y, $cx, $cy, $ix, $iy))
	  if 0 & ($x || $y || $ix || $iy);

	# MoveTo
	if ( $op eq "M" ) {
	    $x += $d->{point}->[0];
	    $y += $d->{point}->[1];
	    $self->_dbg( "xo move(%.2f,%.2f)", $x, $y );
	    $xo->move( $x, $y );
	}

	# Horizontal LineTo.
	elsif ( $op eq "H" ) {
	    $x += $d->{x};
	    $y = $cy;
	    $self->_dbg( "xo hline(%.2f)", $x );
	    $xo->hline($x);
	}

	# Vertical LineTo.
	elsif ( $op eq "V" ) {
	    $x = $cx;
	    $y += $d->{y};
	    $self->_dbg( "xo vline(%.2f)", $y );
	    $xo->vline($y);
	}

	# Generic LineTo.
	elsif ( $op eq "L" ) {
	    $x += $d->{point}->[0];
	    $y += $d->{point}->[1];
	    $self->_dbg( "xo line(%.2f,%.2f)", $x, $y );
	    $xo->line( $x, $y );
	}

	# Cubic Bézier curves.
	elsif ( $op eq "C" ) {
	    my @c = ( # control point 1
		      $x + $d->{control1}->[0],
		      $y + $d->{control1}->[1],
		      # control point 2
		      $x + $d->{control2}->[0],
		      $y + $d->{control2}->[1],
		      # end point
		      $x + $d->{end}->[0],
		      $y + $d->{end}->[1],
		    );
	    $self->_dbg( "xo curve(%.2f,%.2f %.2f,%.2f %.2f,%.2f)", @c );
	    $xo->curve(@c);
	    push( @cp, [ $cx, $cy, $c[0], $c[1] ] );
	    push( @cp, [ $c[4], $c[5], $c[2], $c[3] ] );
	    $x = $c[4]; $y = $c[5]; # end point
	}

	# Quadratic Bézier curves.
	elsif ( $op eq "Q" ) {
	    my @c = ( # control point 1
		      $x + $d->{control}->[0],
		      $y + $d->{control}->[1],
		      # end point
		      $x + $d->{end}->[0],
		      $y + $d->{end}->[1],
		    );
	    $self->_dbg( "xo spline(%.2f,%.2f %.2f,%.2f)", @c );
	    $xo->spline(@c);
	    push( @cp, [ $cx, $cy, $c[0], $c[1] ] );
	    push( @cp, [ $c[2], $c[3], $c[0], $c[1] ] );
	    $x = $c[2]; $y = $c[3]; # end point
	}

	# Arcs.
	elsif ( $op eq "A" ) {
	    my $rx    = $d->{rx};		# radius 1
	    my $ry    = $d->{ry};		# radius 2
	    my $rot   = $d->{x_axis_rotation};	# rotation
	    my $large = $d->{large_arc_flag};	# select larger arc
	    my $sweep = $d->{sweep_flag};	# clockwise
	    my $ex    = $x + $d->{x};		# end point
	    my $ey    = $y + $d->{y};
	    $self->_dbg( "xo arc(%.2f,%.2f %.2f %d,%d %.2f,%.2f)",
			 $rx, $ry, $rot, $large, $sweep, $ex, $ey );

	    # for circular arcs.
	    if ( $rx == $ry ) {
		$self->_dbg( "circular_arc(%.2f,%.2f %.2f,%.2f %.2f ".
			     "move=%d large=%d dir=%d rot=%.2f)",
			     $cx, $cy, $ex, $ey, $rx,
			     0, $large, $sweep, $rot );
		$self->circular_arc( $cx, $cy, $ex, $ey, $rx,
				     move   => 0,
				     large  => $large,
				     rotate => $rot,
				     dir    => $sweep );
	    }
	    else {
		$self->_dbg( "elliptic_arc(%.2f,%.2f %.2f,%.2f %.2f,%.2f ".
			     "move=%d large=%d dir=%d rot=%.2f)",
			     $cx, $cy, $ex, $ey, $rx, $ry,
			     0, $large, $sweep, $rot );
		$self->elliptic_arc( $cx, $cy, $ex, $ey,
				     $rx, $ry,
				     move   => 0,
				     large  => $large,
				     rotate => $rot,
				     dir    => $sweep );
	    }
	    ( $x, $y ) = ( $ex, $ey ); # end point
	}

	# Close path and paint.
	elsif ( $op eq "Z" ) {
	    $self->_dbg( "xo z" );
	    if ( $open ) {
		$xo->close;
		$open = 0;
		# currentpoint becomes the initial point.
		$x = $ix;
		$y = $iy;
	    }
	    if ( @d && $d[0]->{svg_key} eq 'M' ) {
		# Close is followed by a move -> do not paint yet.
	    }
	    else {
		$paint->();
	    }
	}

	# Unidenfied subpath element.
	else {
	    croak("Unidenfied subpath element[$id] $op");
	}

	( $cx, $cy ) = ( $x, $y ) unless $op eq "Z";
    }

    $paint->() if $open;
    $self->_dbg( "- xo restore" );
    $xo->restore;

    # Show collected control points.
    if ( 0 && $self->root->debug && @cp ) {
	$xo->save;
	$xo->stroke_color('lime');
	$xo->line_width(0.5);
	for ( @cp ) {
	    $self->_dbg( "xo line(%.2f %.2f %.2f %.2f)", @$_ );
	    $xo->move( $_->[0], $_->[1] );
	    $xo->line( $_->[2], $_->[3] );
	}
	$xo->stroke;
	$xo->restore;
    }

    $self->css_pop;
}

method curve ( @points ) {
    $self->_dbg( "+ xo curve( %.2f,%.2f %.2f,%.2f %.2f,%.2f )", @points );
    $self->xo->curve(@points);
    $self->_dbg( "-" );
}

method elliptic_arc( $x1,$y1, $x2,$y2, $rx,$ry, %opts) {
    require SVGPDF::Contrib::Bogen;

    SVGPDF::Contrib::Bogen::bogen_ellip
	( $self, $x1,$y1, $x2,$y2, $rx,$ry, %opts );
}

method circular_arc( $x1,$y1, $x2,$y2, $r, %opts) {
    require SVGPDF::Contrib::Bogen;

    SVGPDF::Contrib::Bogen::bogen
	( $self, $x1,$y1, $x2,$y2, $r,
	  $opts{move}, $opts{large}, $opts{dir} );
}

1;
