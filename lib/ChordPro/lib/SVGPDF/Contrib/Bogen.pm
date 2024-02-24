#! perl

use v5.26;
use strict;
use warnings;

package SVGPDF::Contrib::Bogen;

=head1 NAME

SVGPDF::Contrib::Bogen - Circular and elliptic curves

=head1 SYNOPSIS

    $context->bogen( $x1,$y1, $x2,$y2, $r, @opts);
    $context->bogen_ellip( $x1,$y1, $x2,$y2, $rx,$ry, @opts);

=head1 DESCRIPTION

This package contains functions to draw circular and elliptic curves.

This code is developed by Phil Perry, based on old PDF::API2 code and
friendly contributed to the SVGPDF project.

=cut

use Math::Trig;

=over

=item $context->bogen_ellip($x1,$y1, $x2,$y2, $rx,$ry, @opts)

This is a variant of the original C<bogen()> call from PDF::Builder, which 
drew a segment (arc) of a circle, which was adapted here by Phil Perry to draw 
an elliptical arc. 

(German for I<bow>, as in a segment (arc) of an ellipse), this is a 
segment of an ellipse defined by the intersection of two ellipses of given x 
and y radii, with the two intersection points as inputs. There are four 
possible resulting arcs, which can be selected with opts C<large> and C<dir>.

This extends the path along an arc of an ellipse of the specified x and y radii
between C<[$x1,$y1]> to C<[$x2,$y2]>. The current position is then set
to the endpoint of the arc (C<[$x2,$y2]>).

Options (C<@opts>)

=over

=item 'move' => move_flag

Set C<move> to a I<true> value if this arc is the beginning of a new
path instead of the continuation of an existing path. Note that the default 
(C<move> => I<false>) is
I<not> a straight line to I<P1> and then the arc, but a blending into the curve
from the current point. It will often I<not> pass through I<P1>! Set to 
I<true>, there will be a jump (move) from the current point to I<P1>, to where
the arc will start.

=item 'large' => larger_arc_flag

Set C<large> to a I<true> value to draw the larger ("outer") arc between the 
two points, instead of the smaller one. Both arcs are
drawn I<clockwise> from I<P1> to I<P2>. The default value of I<false> draws
the smaller arc.

=item 'dir' => draw_direction

Set C<dir> to a I<true> value to draw the mirror image of the specified arc 
(flip it over, so that its center point is on the other side of the line 
connecting the two points). Both arcs (small or large) are drawn 
I<counter-clockwise> from I<P1> to I<P2>. The default (I<false>) draws 
clockwise arcs.

=item 'rotate' => axis_rotation

A non-zero value is the degrees to rotate the axes of the ellipse (in a
counter-clockwise manner). For example, C<'rotate'=E<gt>45> will have the 
ellipse's +X axis pointing "northeast" and the +Y axis pointing "northwest". 
The default value is 0 (no rotation).

=item 'full' => color_spec

If given (no default), draw the full ellipse (not just the arc) 
in this color, with a dot at its center. This may be useful 
for diagnostic and development purposes, to show the ellipse from which 
the arc is obtained.

=back

B<Note:>

If the given radii C<$rx> and C<$ry> are too small for the points 
I<P1> and I<P2> to fit on the specified ellipse, they will be proportionately
scaled up untilthe points fit on the ellipse.
This is a silent error, as due to rounding, given points (even if correct) 
may not exactly fit on the ellipse. Further note that the algorithm only
enlarges the radii until a sweep of 180 degrees is obtained, so it is possible
that the ellipse will be smaller than your intended one!

=back

=cut

sub bogen_ellip {
    my ($self, $x1,$y1, $x2,$y2, $rx,$ry, %opts) = @_;

    # set default values for options
    my $move = 0; # 0 = continue from present point, 1 = move to point 1
    my $larc = 0; # 0 = choose smaller arc, 1 = choose larger
    my $dir  = 0; # 0 = CW, 1 = CCW
    my $rotate = 0; # degrees rotated around center of ellipse (so rx isn't
                    # due left-right)
    if (defined $opts{'move'}) { $move = $opts{'move'}; }
    if (defined $opts{'large'}) { $larc = $opts{'large'}; }
    if (defined $opts{'dir'}) { $dir = $opts{'dir'}; }
    if (defined $opts{'rotate'}) { $rotate = $opts{'rotate'}; }

    my ($alpha,$beta);
    my ($cosR, $sinR, $x1P,$y1P, $xcP,$ycP, $xc,$yc, $lambda, $d,$k);
    my ($xm,$ym, $xM,$yM, $ux,$uy,$ulen, $vx,$vy,$vlen, $dp_uv);
    my ($cosTheta1,$theta1, $cosDeltaTheta,$deltaTheta);
    my $PI = 3.141593;

    # P1 and P2 need to be distinct
    if ($x1 == $x2 && $y1 == $y2) {
        print STDERR "bogen_ellip requires two distinct points. Skipping.\n";
	return $self;
    }

    # think of the SVG coordinates (where this algorithm comes from) as being 
    # like PDF's (conventional geometry), except mirrored about the x axis 
    # (horizontal line). y grows downwards, angles + = CW sweep, starting at
    # angle 0 degrees points due east (axis rotation applied).
    # just compute everything SVG's way, and when applied to PDF everything
    # will be right side up and turning the right way.
    # larc and dir need to be 0 or 1, not just false/true
    if ($larc) { $larc = 1; } else { $larc = 0; }
    if ($dir)  { $dir = 1; }  else { $dir = 0; }
    # fS (from dir) 1 if sweep is increasing angle (CCW in PDF, CW in SVG)
    # fA (larc) 1 is larger (> 180 degrees) arc

    # need to flip rotation direction, sweep direction to match
    # SVG algorithm. 
#   $dir = !$dir if $larc != $dir;
#   $dir = !$dir;
#   $rotate = -$rotate;
    $rotate = $rotate/180*$PI;

    # make both radii positive r = |r|
    if ($rx < 0) { $rx = -$rx; }
    if ($ry < 0) { $ry = -$ry; }

    # if either radius is 0, arc is a straight line from P1 to P2
    if (!$rx || !$ry) {
        $self->poly($x1,$y1, $x2,$y2); # degenerate case
	return $self;
    }

    # compute elliptical arc parameters per
    #  https://gitlab.gnome.org/GNOME/librsvg/-/blob/main/rsvg/src/path_builder.rs,
    #  based on https://www.w3.org/TR/SVG2/implnote.html#Introduction
    #  (code is more from the W3 math than the GNOME code, which it's not
    #  clear what the sign conventions are)
    # if the radii are too small, they will be corrected below.

    # midpoint distance of line from P1 to P2
    $xm = ($x1-$x2)/2.0;
    $ym = ($y1-$y2)/2.0;
    # actual midpoint of line from P1 to P2
    $xM = ($x1+$x2)/2.0;
    $yM = ($y1+$y2)/2.0;

    # P1'
    $cosR = cos($rotate);
    $sinR = sin($rotate);

    $x1P =  $cosR*$xm + $sinR*$ym;
    $y1P = -$sinR*$xm + $cosR*$ym;

    # increase radii if necessary
    $lambda = ($x1P/$rx)**2 + ($y1P/$ry)**2;
    if ($lambda > 1.0) {
	# a radius cannot be too large, but if too small (lambda > 1), 
	# preserve aspect ratio while increasing rx and ry
	$rx *= sqrt($lambda);
	$ry *= sqrt($lambda);
    }

    # C' (transformed center)
    $d = ($rx * $ry)**2 - ($rx * $y1P)**2 - ($ry * $x1P)**2;
    $d /= (($rx * $y1P)**2 + ($ry * $x1P)**2);
    # deal with rounding issues
    $d = 0 if $d < 0.0 && $d > -1.0e-10;
    if ($d < 0.0) {
	# failure, skip
	print STDERR "Unable to compute elliptical arc (1) d=$d. Skipping.\n";
	return $self;
    }
    $d = sqrt($d);
    # negate if small arc CW or large arc CCW (per normal PDF coordinates)
    $d = -$d if $larc == $dir;
    $xcP = $d *  $rx/$ry * $y1P;
    $ycP = $d * -$ry/$rx * $x1P;

    # C (actual center)
    $xc = $cosR * $xcP - $sinR * $ycP + $xM;
    $yc = $sinR * $xcP + $cosR * $ycP + $yM;

    # theta1 (start angle 0, sweep to P1'). 0 is due East, CW +
    # first, get unit vector for C'->P1'
    $ux = ($x1P - $xcP)/$rx; # "unstretch" ellipse into circle
    $uy = ($y1P - $ycP)/$ry;
    $ulen = sqrt(($ux**2 + $uy**2));
    if ($ulen == 0.0) {
	# failure, skip (shouldn't see 0 length C' to P1' vector)
	print STDERR "Unable to compute elliptical arc (2). Skipping.\n";
	return $self;
    }
    $cosTheta1 = $ux/$ulen; # unit vector x component = cos(theta1)

    # as rx and ry have already been corrected, is this ever needed?
    # better safe than sorry, especially if just past +/-1 due to rounding...
    $cosTheta1 = -1 if $cosTheta1 < -1.0;
    $cosTheta1 =  1 if $cosTheta1 >  1.0;
    $theta1 = acos($cosTheta1);

    # negate (flip) if on other side (up, negative y territory)
    $theta1 = -$theta1 if $uy < 0.0;

    # delta theta sweep P1 to P2. vector v is C' to P2'
    $vx = (-$x1P - $xcP)/$rx; # again, squash ellipse to circle
    $vy = (-$y1P - $ycP)/$ry;
    $vlen = sqrt($vx**2 + $vy**2);
    if ($vlen == 0.0) {
	# failure, skip (P1 == P2? vector can't be 0 length)
	print STDERR "Unable to compute elliptical arc (3). Skipping.\n";
	return $self;
    }
    $vx /= $vlen; $vy /= $vlen;

    # acos( u dot v / 1*1 ) is sweep angle
    $k = $ux*$vx + $uy*$vy;
    # again, better safe than sorry...
    $k = -1 if $k < -1.0;
    $k =  1 if $k >  1.0;
    $deltaTheta = acos($k);
    $deltaTheta = -$deltaTheta if $ux*$vy-$uy*$vx < 0.0;

    # convert sweep angles to PDF coordinates in degrees
    $alpha = $theta1*180/$PI;
    $beta  = $alpha + $deltaTheta*180/$PI;
    while ($beta >= 360.0) { $beta -= 360.0; }
    while ($beta  <   0.0) { $beta += 360.0; }

     # -------------------------------------------------------------------
     # if 'full' color ellipse requested, draw it now for angle 0 sweep 180
     # and angle 180 sweep 180 (for full ellipse)
     if (defined $opts{'full'}) {
	# save current location to return to
	my @saveloc = ($self->{' x'},$self->{' y'});
 	$self->save();
 
 	$self->stroke_color($opts{'full'});
	# move to P1, draw 180 arcs
	$self->move($x1,$y1);
        _arc2points($self, $rx,$ry, $alpha,$alpha+180, $x1,$y1, 2*$xc-$x1,2*$yc-$y1, 0, $rotate);
 	$self->move($x1,$y1);
        _arc2points($self, $rx,$ry, $alpha,$alpha+180, $x1,$y1, 2*$xc-$x1,2*$yc-$y1, 1, $rotate);
	$self->stroke();
 	
 	$self->restore();
	$self->move(@saveloc);
     }
    # -------------------------------------------------------------------

    # move to starting point (if specified), then output arc
    $self->move($x1,$y1) if $move;

    # PDF::Builder's arc() includes a 'dir' flag, but PDF::API doesn't.
    # so, need to calculate points (for Bezier curves).
    _arc2points($self, $rx,$ry, $alpha,$beta, $x1,$y1, $x2,$y2, $dir, $rotate);

    return $self;
}

# calculate the Bezier control points for an elliptical arc, given
#   self = graphics context
#   rx and ry = radii
#   alpha and beta = starting and ending sweeps (degrees)
#   x' and y' = P1'
#   x2 and y2 = last point (if needed)
#   dir = 1 CW, 0 CCW
#   rotate = axis rotation in radians
# returns nothing. curve called to output the curve to PDF
sub _arc2points {
    my ($self, $rx,$ry, $alpha,$beta, $x1,$y1, $x2,$y2, $dir, $rotate) = @_;
    my (@points, $x,$y, $p0_x,$p0_y, $p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
    $dir = !$dir;

    # @points is relative to starting point of arc
    @points = _arctocurve($rx,$ry, $alpha,$beta, $dir,$rotate);

    # counterrotate all start/end/control points around P1 by -rotate degrees
    if ($rotate) {
	my $r = $rotate; # already in radians
	my $cosR = cos($r);
	my $sinR = sin($r);
	my ($x,$y, $xr,$yr);
	for (my $i=0; $i<@points; $i+=2) {
	    $x = $points[$i]; $y = $points[$i+1];
	    $xr = $x1 + $cosR*($x-$x1) - $sinR*($y-$y1);
	    $yr = $y1 + $sinR*($x-$x1) + $cosR*($y-$y1);
	    $points[$i] = $xr; $points[$i+1] = $yr;
	}
    }

    $p0_x = shift @points;
    $p0_y = shift @points;
    $x = $x1 - $p0_x;
    $y = $y1 - $p0_y;

    while (scalar @points > 0) {
        $p1_x = $x + shift @points;
        $p1_y = $y + shift @points;
        $p2_x = $x + shift @points;
        $p2_y = $y + shift @points;
        # if we run out of data points, use the end point instead
        if (scalar @points == 0) {
            $p3_x = $x2;
            $p3_y = $y2;
        } else {
            $p3_x = $x + shift @points;
            $p3_y = $y + shift @points;
        }
        $self->curve($p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
        shift @points;
        shift @points;
    }

    return $self;
}
 
# input: x and y axis radii
#        sweep start and end angles (degrees)
#        sweep direction (0=CCW (default), or 1=CW)
#        axis rotation (radians, + = CCW, default = 0)
# output: two endpoints and two control points for
#           the Bezier curve describing the arc
# maximum 30 degrees of sweep: is broken up into smaller
#   arc segments if necessary
# if crosses 0 degree angle in either sweep direction, split there at 0
# if alpha=beta (0 degree sweep) or either radius <= 0, fatal error
sub _arctocurve {
    my ($rx,$ry, $alpha,$beta, $dir,$rot) = @_;

    if (!defined $rot) { $rot = 0; }  # default is no rotation
    if (!defined $dir) { $dir = 0; }  # default is CCW sweep
    # check for non-positive radius
    if ($rx <= 0 || $ry <= 0) {
	die "curve request with radius not > 0 ($rx, $ry)";
    }
    # check for zero degrees of sweep
    if ($alpha == $beta) {
	die "curve request with zero degrees of sweep ($alpha to $beta)";
    }

    # constrain alpha and beta to 0..360 range so 0 crossing check works
    while ($alpha < 0.0)   { $alpha += 360.0; }
    while ( $beta < 0.0)   {  $beta += 360.0; }
    while ($alpha > 360.0) { $alpha -= 360.0; }
    while ( $beta > 360.0) {  $beta -= 360.0; }

    # Note that there is a problem with the original code, when the 0 degree
    # angle is crossed. It especially shows up in arc() and pie(). Therefore, 
    # split the original sweep at 0 degrees, if it crosses that angle.
    if (!$dir && $alpha > $beta) { # CCW pass over 0 degrees
      if      ($alpha == 360.0 && $beta == 0.0) { # oddball case
        return (_arctocurve($rx,$ry, 0.0,360.0, 0,$rot));
      } elsif ($alpha == 360.0) { # alpha to 360 would be null
        return (_arctocurve($rx,$ry, 0.0,$beta, 0,$rot));
      } elsif ($beta == 0.0) { # 0 to beta would be null
        return (_arctocurve($rx,$ry, $alpha,360.0, 0,$rot));
      } else {
        return (
            _arctocurve($rx,$ry, $alpha,360.0, 0,$rot),
            _arctocurve($rx,$ry, 0.0,$beta, 0,$rot)
        );
      }
    }
    if ($dir && $alpha < $beta) { # CW pass over 0 degrees
      if      ($alpha == 0.0 && $beta == 360.0) { # oddball case
        return (_arctocurve($rx,$ry, 360.0,0.0, 1,$rot));
      } elsif ($alpha == 0.0) { # alpha to 0 would be null
        return (_arctocurve($rx,$ry, 360.0,$beta, 1,$rot));
      } elsif ($beta == 360.0) { # 360 to beta would be null
        return (_arctocurve($rx,$ry, $alpha,0.0, 1,$rot));
      } else {
        return (
            _arctocurve($rx,$ry, $alpha,0.0, 1,$rot),
            _arctocurve($rx,$ry, 360.0,$beta, 1,$rot)
        );
      }
    }

    # limit arc length to 30 degrees, for reasonable smoothness
    # none of the long arcs or short resulting arcs cross 0 degrees
    if (abs($beta-$alpha) > 30) {
        return (
            _arctocurve($rx,$ry, $alpha,($beta+$alpha)/2, $dir,$rot),
            _arctocurve($rx,$ry, ($beta+$alpha)/2,$beta, $dir,$rot)
        );
    } else {
	# calculate cubic Bezier points (start, two control, end)
        my ($p0_x,$p0_y, $p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
       # Note that we can't use deg2rad(), because closed arcs (circle() and 
       # ellipse()) are 0-360 degrees, which deg2rad treats as 0-0 radians!
        my $aa = $alpha * 3.141593 / 180;
        my $bb = $beta  * 3.141593 / 180;

        my $bcp = (4.0/3 * (1 - cos(($bb - $aa)/2)) / sin(($bb - $aa)/2));
        my $sin_alpha = sin($aa);
        my $sin_beta  = sin($bb);
        my $cos_alpha = cos($aa);
        my $cos_beta  = cos($bb);

        $p0_x = $rx * $cos_alpha;
        $p0_y = $ry * $sin_alpha;
        $p1_x = $rx * ($cos_alpha - $bcp * $sin_alpha);
        $p1_y = $ry * ($sin_alpha + $bcp * $cos_alpha);
        $p2_x = $rx * ($cos_beta  + $bcp * $sin_beta);
        $p2_y = $ry * ($sin_beta  - $bcp * $cos_beta);
        $p3_x = $rx * $cos_beta;
        $p3_y = $ry * $sin_beta;

        return ($p0_x,$p0_y, $p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
    }
}

# Circular arc ('bogen'), by PDF::API2 and anhanced by PDF::Builder.

=over

=item $content->bogen($x1,$y1, $x2,$y2, $radius, $move, $larger, $reverse)

=item $content->bogen($x1,$y1, $x2,$y2, $radius, $move, $larger)

=item $content->bogen($x1,$y1, $x2,$y2, $radius, $move)

=item $content->bogen($x1,$y1, $x2,$y2, $radius)

(I<bogen> is German for I<bow>, as in a segment (arc) of a circle. This is a 
segment of a circle defined by the intersection of two circles of a given 
radius, with the two intersection points as inputs. There are B<four> possible 
resulting arcs, which can be selected with C<$larger> and C<$reverse>.)

This extends the path along an arc of a circle of the specified radius
between C<[$x1,$y1]> to C<[$x2,$y2]>. The current position is then set
to the endpoint of the arc (C<[$x2,$y2]>).

Set C<$move> to a I<true> value if this arc is the beginning of a new
path instead of the continuation of an existing path. Note that the default 
(C<$move> = I<false>) is
I<not> a straight line to I<P1> and then the arc, but a blending into the curve
from the current point. It will often I<not> pass through I<P1>!

Set C<$larger> to a I<true> value to draw the larger ("outer") arc between the 
two points, instead of the smaller one. Both arcs are drawn I<clockwise> from 
I<P1> to I<P2>. The default value of I<false> draws the smaller arc.
Note that the "other" circle's larger arc is used (the center point is 
"flipped" across the line between I<P1> and I<P2>), rather than using the 
"remainder" of the smaller arc's circle (which would necessitate reversing the
direction of travel along the arc -- see C<$reverse>).

Set C<$reverse> to a I<true> value to draw the mirror image of the
specified arc (flip it over, so that its center point is on the other
side of the line connecting the two points). Both arcs are drawn
I<counter-clockwise> from I<P1> to I<P2>. The default (I<false>) draws 
clockwise arcs. An arc is B<always> drawn from I<P1> to I<P2>; the direction
(clockwise or counter-clockwise) may be chosen.

The C<$radius> value cannot be smaller than B<half> the distance from 
C<[$x1,$y1]> to C<[$x2,$y2]>. If it is too small, the radius will be set to
half the distance between the points (resulting in an arc that is a
semicircle). This is a silent error.

=back

=cut

sub bogen {
    my ($self, $x1,$y1, $x2,$y2, $r, $move, $larc, $spf) = @_;

    my ($p0_x,$p0_y, $p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
    my ($dx,$dy, $x,$y, $alpha,$beta, $alpha_rad, $d,$z, $dir, @points);

    if ($x1 == $x2 && $y1 == $y2) {
        die "bogen requires two distinct points";
    }
    if ($r <= 0.0) {
        die "bogen requires a positive radius";
    }
    $move = 0 if !defined $move;
    $larc = 0 if !defined $larc;
    $spf  = 0 if !defined $spf;

    $dx = $x2 - $x1;
    $dy = $y2 - $y1;
    $z = sqrt($dx**2 + $dy**2);
    $alpha_rad = asin($dy/$z); # |dy/z| guaranteed <= 1.0
    $alpha_rad = pi - $alpha_rad if $dx < 0;

    # alpha is direction of vector P1 to P2
    $alpha = rad2deg($alpha_rad);
    # use the complementary angle for flipped arc (arc center on other side)
    # effectively clockwise draw from P2 to P1
    $alpha -= 180 if $spf;

    $d = 2*$r;
    # z/d must be no greater than 1.0 (arcsine arg)
    if ($z > $d) { 
        $d = $z;  # SILENT error and fixup
        $r = $d/2;
    }

    $beta = rad2deg(2*asin($z/$d));
    # beta is the sweep P1 to P2: ~0 (r very large) to 180 degrees (min r)
    $beta = 360-$beta if $larc;  # large arc is remainder of small arc
    # for large arc, beta could approach 360 degrees if r is very large

    # always draw CW (dir=1)
    # note that start and end could be well out of +/-360 degree range
    @points = _arctocurve($r,$r, 90+$alpha+$beta/2,90+$alpha-$beta/2, 1);

    if ($spf) {  # flip order of points for reverse arc
        my @pts = @points;
        @points = ();
        while (@pts) {
            $y = pop @pts;
            $x = pop @pts;
            push(@points, $x,$y);
        }
    }

    $p0_x = shift @points;
    $p0_y = shift @points;
    $x = $x1 - $p0_x;
    $y = $y1 - $p0_y;

    $self->move($x1,$y1) if $move;

    while (scalar @points > 0) {
        $p1_x = $x + shift @points;
        $p1_y = $y + shift @points;
        $p2_x = $x + shift @points;
        $p2_y = $y + shift @points;
        # if we run out of data points, use the end point instead
        if (scalar @points == 0) {
            $p3_x = $x2;
            $p3_y = $y2;
        } else {
            $p3_x = $x + shift @points;
            $p3_y = $y + shift @points;
        }
        $self->curve($p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
        shift @points;
        shift @points;
    }

    return $self;
}

1;
