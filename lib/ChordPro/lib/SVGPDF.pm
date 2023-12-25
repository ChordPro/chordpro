#! perl

use v5.26;
use Object::Pad;
use Carp;
use utf8;

class  SVGPDF;

our $VERSION = '0.083';

=head1 NAME

SVGPDF - Create PDF XObject from SVG data

=head1 SYNOPSIS

    my $pdf = PDF::API2->new;
    my $svg = SVGPDF->new($pdf);
    my $xof = $svg->process("demo.svg");

    # If all goes well, $xof is an array of hashes, each representing an
    # XObject corresponding to the <svg> elements in the file.
    # Get a page and graphics context.
    my $page = $pdf->page;
    $page->bbox( 0, 0, 595, 842 );
    my $gfx = $pdf->gfx;

    # Place the objects.
    my $y = 832;
    foreach my $xo ( @$xof ) {
	my @bb = @{$xo->{vbox}};
        my $h = $bb[3];
	$gfx->object( $xo->{xo}, 10, $y-$h, 1 );
	$y -= $h;
    }

    $pdf->save("demo.pdf");

=head1 DESCRIPTION

This module processes SVG data and produces one or more PDF XObjects
to be placed in a PDF document. This module is intended to be used
with L<PDF::Builder>, L<PDF::API2> and compatible PDF packages.

The main method is process(). It takes the SVG from an input source, see
L</INPUT>.

=head1 COORDINATES & UNITS

SVG coordinates run from top-left to bottom-right.

Dimensions without units are B<pixels>, at 96 pixels / inch. E.g.,
C<width="96"> means 96px (pixels) and is equal to 72pt (points) or 1in (inch).

For font sizes, CSS defines C<em> to be equal to the font size, and
C<ex> is half of the font size.

=head1 CONSTRUCTOR

In its most simple form, a new SVGPDF object can be created with a
single argument, the PDF document.

     $svg = SVGPDF->new($pdf);

There are a few optional arguments, these can be specified as
key/value pairs.

=over 8

=item C<fc>

A reference to a callback routine to handle fonts.
See L</FONT HANDLER CALLBACK>.

It may also be an array of routines which will be called in
sequence until one of them succeeds (returns a 'true' result).

=item C<fontsize>

The font size to be used for dimensions in 'ex' and 'em' units.

Note that CSS defines 'em' to be the font size, and 'ex' half of the
font size.

=item C<pagesize>

An array reference containing the maximum width and height of the
resultant image.

There is no widely accepted default for this, so we use C<[595,842]>
which corresponds to an ISO A4 page.

=item C<grid>

If not zero, a grid will be added to the image. This is mostly for
developing and debugging.

The value determines the grid spacing.

=item C<verbose>

Verbosity of informational messages. Set to zero to silence all but
fatal errors.

=item C<debug>

Internal use only.

=back

For convenience, the mandatory PDF argument can also be specified with
a key/value pair:

    $svg = SVGPDF->new( pdf => $pdf, grid => 1, fc => \&fonthandler );

=cut


field $pdf          :accessor :param;
field $atts         :accessor :param = undef;

# Callback for font and text handling.
field $fc           :accessor :param = undef;
field $tc           :accessor :param = undef;

# If an SVG file contains more than a single SVG, the CSS applies to all.
field $css          :accessor;

# Font manager.
field $fontmanager  :accessor;

field $xoforms      :accessor;
field $defs         :accessor;

# Defaults for rendering.
field $pagesize     :accessor;
field $fontsize     :accessor;
field $pxpi         :mutator  = 96; # pixels per inch
field $ptpi         :accessor = 72; # points per inch

# For debugging/development.
field $verbose      :accessor;
field $debug        :accessor;
field $grid         :accessor;
field $prog         :accessor;
field $debug_styles :accessor;
field $trace        :accessor;
field $wstokens     :accessor;

our $indent = "";

use SVGPDF::Parser;
use SVGPDF::Element;
use SVGPDF::CSS;
use SVGPDF::FontManager;
use SVGPDF::PAST;

# The SVG elements.
use SVGPDF::Circle;
use SVGPDF::Defs;
use SVGPDF::Ellipse;
use SVGPDF::G;
use SVGPDF::Image;
use SVGPDF::Line;
use SVGPDF::Path;
use SVGPDF::Polygon;
use SVGPDF::Polyline;
use SVGPDF::Rect;
use SVGPDF::Style;
use SVGPDF::Svg;
use SVGPDF::Text;
use SVGPDF::Tspan;
use SVGPDF::Use;

################ General methods ################


=head1 METHODS

=cut

# $pdf [ , fc => $callback ] [, atts => { ... } ] [, foo => bar ]
# pdf => $pdf [ , fc => $callback ] [, atts => { ... } ] [, foo => bar ]

sub BUILDARGS ( @args ) {
    my $cls = shift(@args);

    # Assume first is pdf if uneven.
    unshift( @args, "pdf" ) if @args % 2;

    my %args = @args;
    @args = ();
    push( @args, $_, delete $args{$_} ) for qw( pdf fc tc );

    # Flatten everything else into %atts.
    my %x = %{ delete($args{atts}) // {} };
    $x{$_} = $args{$_} for keys(%args);

    # And store as ref.
    push( @args, "atts", \%x );

    # Return new argument list.
    @args;
}

BUILD {
    $verbose      = $atts->{verbose}      // 1;
    $debug        = $atts->{debug}        || 0;
    $grid         = $atts->{grid}         || 0;
    $prog         = $atts->{prog}         || 0;
    $debug_styles = $atts->{debug_styles} || $debug > 1;
    $trace        = $atts->{trace}        || 0;
    $pagesize     = $atts->{pagesize}     || [ 595, 842 ];
    $fontsize     = $atts->{fontsize}     || 12;
    $wstokens     = $atts->{wstokens}     || 0;
    $indent       = "";
    $xoforms      = [];
    $defs         = {};
    $fontmanager  = SVGPDF::FontManager->new( svg => $self );
    $self;
}

=head2 process

    $xof = $svg->process( $data, %options )

This methods gets SVG data from C<$data> and returns an array reference
with rendered images. See L</OUTPUT> for details.

The input is read using File::LoadLines. See L</INPUT> for details.

Recognized attributes in C<%options> are:

=over 4

=item fontsize

The font size to be used for dimensions in 'ex' and 'em' units.

This value overrides the value set in the constructor.

=item combine

An SVG can produce multiple XObjects, but sometimes these should be
kept as a single image.

There are two ways to combine the image objects. This can be selected
by setting $opts{combine} to either C<"stacked"> or C<"bbox">.

Type C<"stacked"> (default) stacks the images on top of each other,
left sides aligned. The bounding box of each object is only used to
obtain the width and height.

Type C<"bbox"> stacks the images using the bounding box details. The
origins of the images are vertically aligned and images may protrude
other images when the image extends below the origin.

=item sep

When combining images, add additional vertical space between the
individual images.

=back

=cut

method process ( $data, %options ) {

    if ( $options{reset} ) {	# for testing, mostly
	$xoforms = [];
    }

    my $save_fontsize = $fontsize;
    $fontsize = $options{fontsize} if $options{fontsize};
    # TODO: Page size

    # Load the SVG data.
    my $svg = SVGPDF::Parser->new;
    my $tree = $svg->parse_file
      ( $data,
	whitespace_tokens => $wstokens||$options{whitespace_tokens} );
    return unless $tree;

    # CSS persists over svgs, but not over files.
    $css = SVGPDF::CSS->new;

    # Search for svg elements and process them.
    $self->search($tree);

    # Restore.
    $fontsize = $save_fontsize;

    my $combine = $options{combine} // "none";
    if ( $combine ne "none" && @$xoforms > 1 ) {
	my $sep = $options{sep} || 0;
	$xoforms = $self->combine_svg( $xoforms,
				       type => $combine, sep => $sep );
    }

    # Return (hopefully a stack of XObjects).
    return $xoforms;
}

method _dbg ( @args ) {
    return unless $debug;
    my $msg;
    if ( $args[0] =~ /\%/ ) {
	$msg = sprintf( $args[0], @args[1..$#args] );
    }
    else {
	$msg = join( "", @args );
    }
    if ( $msg =~ /^\+\s*(.*)/ ) {
	$indent = $indent . "  ";
	warn( $indent, $1, "\n") if $1;
    }
    elsif ( $msg =~ /^\-\s*(.*)/ ) {
	warn( $indent, $1, "\n") if $1;
confess("oeps") if length($indent) < 2;
	$indent = substr( $indent, 2 );
    }
    elsif ( $msg =~ /^\^\s*(.*)/ ) {
	$indent = "";
	warn( $indent, $1, "\n") if $1;
    }
    else {
	warn( $indent, $msg, "\n") if $msg;
    }
}

method search ( $content ) {

    # In general, we'll have an XHTML tree with one or more <sgv>
    # elements.

    for ( @$content ) {
	next if $_->{type} eq 't';
	my $name = $_->{name};
	if ( $name eq "svg" ) {
	    $indent = "";
	    $self->handle_svg($_);
	    # Adds results to $self->{xoforms}.
	}
	else {
	    # Skip recursively.
	    $self->_dbg( "$name (ignored)" ) unless $name eq "<>"; # top
	    $self->search($_->{content});
	}
    }
}

method handle_svg ( $e ) {

    $self->_dbg( "^ ==== start ", $e->{name}, " ====" );

    my $xo;
    if ( $prog ) {
	$xo = SVGPDF::PAST->new( pdf => $pdf );
    }
    else {
	$xo = $pdf->xo_form;
    }
    push( @$xoforms, { xo => $xo } );

    $self->_dbg("XObject #", scalar(@$xoforms) );
    my $svg = SVGPDF::Element->new
	( name    => $e->{name},
	  atts    => { map { lc($_) => $e->{attrib}->{$_} } keys %{$e->{attrib}} },
	  content => $e->{content},
	  root    => $self,
	);

    # If there are <style> elements, these must be processed first.
    my $cdata = "";
    for ( $svg->get_children ) {
	next unless ref($_) eq "SVGPDF::Style";
	# DDumper($_->get_children) unless scalar($_->get_children) == 1;
	croak("ASSERT: 1 child") unless scalar($_->get_children) == 1;
	for my $t ( $_->get_children ) {
	    croak("# ASSERT: non-text child in style")
	      unless ref($t) eq "SVGPDF::TextElement";
	    $cdata .= $t->content;
	}
    }
    if ( $cdata =~ /\S/ ) {
	$css->read_string($cdata);
    }

    my $atts   = $svg->atts;

    # The viewport, llx lly width height.
    my $vbox   = delete $atts->{viewbox};

    # Width and height are the display size of the viewport.
    # Resolve em, ex and percentages.
    my $vwidth  = delete $atts->{width} // 0;
    my $vheight = delete $atts->{height} // 0;
    for ( $vwidth ) {
	$_ = $svg->u( $_, width => $pagesize->[0],
		      fontsize => $fontsize );
    }
    for ( $vheight ) {
	$_ = $svg->u( $_, width => $pagesize->[1],
		      fontsize => $fontsize );
    }

    delete $atts->{$_} for qw( xmlns:xlink xmlns:svg xmlns version );
    my $style = $svg->css_push($atts);

    # If there is min-width the image must be scaled if the available
    # width is smaller. If the width is larger we render to the
    # available space.
    my $minw = $style->{'min-width'} // 0;
    $minw = $svg->u( $minw, width => $pagesize->[0],
		     fontsize => $fontsize ) if $minw;

    # vertical-align is needed later when the XObject is placed.
    my $valign = $style->{'vertical-align'} // 0;
    $valign = $svg->u( $valign, fontsize => $fontsize ) if $valign;

    my @vb;			# viewBox: llx lly width height
    my @bb;			# bbox:    llx lly urx ury

    # We rely on the <svg> to supply the correct viewBox.
    my $width;			# width of the vbox
    my $height;			# height of the vbox
    if ( $vbox ) {
	@vb     = $svg->getargs($vbox);
	$width  = $svg->u( $vb[2],
			   width => $pagesize->[0],
			   fontsize => $fontsize );
	$height = $svg->u( $vb[3],
			   width => $pagesize->[1],
			   fontsize => $fontsize );
	if ( $minw && $minw > $width ) {
	    $width  = $minw;
	    $vb[2] = $minw / $vheight * $height;
	    $self->_dbg("minw: ", $style->{'min-width'}, " ",
			"width -> $width, \$vb[2] -> $vb[2]\n");
	}
	if ( $valign ) {
	    # Verify valign against the vbox.
	    my $va = sprintf("%.2f", -$valign/$vheight);
	    my $vb = sprintf("%.2f", ($vb[3]+$vb[1])/$vb[3]);
	    warn("Vertical align = $va, but vbox says $vb\n")
	      unless $va eq $vb;
	}
	if ( $vwidth && !$vheight ) {
	    $vheight = $vwidth * $height / $width;
	}
	if ( $vheight && !$vwidth ) {
	    $vwidth = $vheight * $width / $height;
	}
    }
    else {
	# Use to width/height, falling back to pagesize.
	$width  = $svg->u( $vwidth  ||$pagesize->[0],
			   width => $pagesize->[0],
			   fontsize => $fontsize );
	$height = $svg->u( $vheight ||$pagesize->[1],
			   width => $pagesize->[1],
			   fontsize => $fontsize );
	if ( $minw && $minw > $width ) {
	    $width = $minw if $minw > $width;
	    $self->_dbg("minw: ", $style->{'min-width'}, " ",
			"width -> $width");
	}
	@vb     = ( 0, 0, $width, $height );
	if ( $valign ) {
	    $vb[1] = -( $vb[3] + $valign );
	    $self->_dbg("valign: ", $style->{'vertical-align'}, " ",
			"\$vb[1] -> $vb[1]");
	}
	$vbox = "@vb (inferred)";
    }

    $svg->nfi("disproportional vbox/width/height")
      if $vheight &&
      ( (( $width/$height) / ($vwidth/$vheight) > 1.05)
	|| (( $width/$height) / ($vwidth/$vheight) < 0.95) );

    # Get llx lly urx ury bounding box rectangle.
    @bb = $self->vb2bb(@vb);
    $self->_dbg( "vb $vbox => bb %.2f %.2f %.2f %.2f", @bb );
    warn( sprintf("vb $vbox => bb %.2f %.2f %.2f %.2f\n", @bb ))
      if $verbose && !$debug;
    $xo->bbox(@bb);

    if ( my $c = $style->{"background-color"} ) {
	$xo->fill_color($c);
	$xo->rectangle(@bb);
	$xo->fill;
    }

    # Set up result forms.
    $xoforms->[-1] =
      { xo      => $xo,
	# Design (desired) width and height.
	vwidth  => $vwidth  || $vb[2],
	vheight => $vheight || $vb[3],
	# viewBox (SVG coordinates)
	vbox    => [ @vb ],
	width   => $vb[2],
	height  => $vb[3],
	# See e.g. https://oreillymedia.github.io/Using_SVG/extras/ch05-percentages.html
	diag    => sqrt( $vb[2]**2 + $vb[3]**2 ) / sqrt(2),
	# bbox (PDF coordinates)
	bbox    => [ @bb ],
      };
    # Not sure if this is ever needed.
    $xoforms->[-1]->{valign} = $valign if $valign;

#    use DDumper; DDumper( { %{$xoforms->[-1]}, xo => 'XO' } );
    # <svg> coordinates are topleft down, so translate.
    $self->_dbg( "matrix( 1 0 0 -1 0 0)" );
    $xo->matrix( 1, 0, 0, -1, 0, 0 );

    if ( $debug ) {		# show bb
	$xo->save;
	$self->_dbg( "vb rect( %.2f %.2f %.2f %.2f)",
		        $vb[0], $vb[1], $vb[2]+$vb[0], $vb[1]+$vb[3]);
	$xo->rectangle( $vb[0], $vb[1], $vb[2]+$vb[0], $vb[1]+$vb[3]);
	$xo->fill_color("#ffffc0");
	$xo->fill;
	$xo->move(  $vb[0], 0 );
	$xo->hline( $vb[0]+$vb[2]);
	$xo->move( 0, $vb[1] );
	$xo->vline( $vb[1]+$vb[3] );
	$xo->line_width(0.5);
	$xo->stroke_color( "red" );
	$xo->stroke;
	$xo->restore;
    }
    $self->draw_grid( $xo, \@vb ) if $grid;


    # Establish currentColor.
    for ( $css->find("fill") ) {
	next if $_ eq 'none' or $_ eq 'transparent';
	$self->_dbg( "xo fill_color ",
		     $_ eq 'currentColor' ? 'black' : $_,
		     " (initial)");
	$xo->fill_color( $_ eq 'currentColor' ? 'black' : $_ );
    }
    for ( $css->find("stroke") ) {
	next if $_ eq 'none' or $_ eq 'transparent';
	$self->_dbg( "xo stroke_color ",
		     $_ eq 'currentColor' ? 'black' : $_,
		     " (initial)");
	$xo->stroke_color( $_ eq 'currentColor' ? 'black' : $_ );
    }
    $svg->traverse;

    $svg->css_pop;

    $self->_dbg( "==== end ", $e->{name}, " ====" );
}

sub min( $a, $b ) { $a < $b ? $a : $b }
sub max( $a, $b ) { $a > $b ? $a : $b }

method combine_svg( $forms, %opts ) {
    my $type = $opts{type} // "stacked";
    return $forms if $type eq "none";

    my ( $xmin, $ymin, $xmax, $ymax );
    my $y = 0;
    my $x = 0;
    my $sep = $opts{sep} || 0;
    my $nx;

    if ( $type eq "bbox" ) {
	warn("Combining ", scalar(@$forms), " XObjects\n")
	  if $verbose;
	...;
	$nx->bbox( $xmin, $ymax, $xmax, 0 );
    }
    else {
	my $i = 0;
	for my $xo ( @$forms ) {
	    $xo = $xo->{xo};
	    my @bb = $xo->bbox;
	    my $w = abs( $bb[2] - $bb[0] );
	    my $h = abs( $bb[3] - $bb[1] );

	    $nx //= $pdf->xo_form;
	    my @xy = ( $x - min($bb[0],$bb[2]), $y - max($bb[1],$bb[3]) );
	    warn(sprintf("Stack obj %2d: %.2f %.2f %.2f %.2f \@ %.2f %.2f\n",
			 ++$i, @bb, @xy ) ) if $verbose;
	    $nx->object( $xo, @xy );
	    $y -= $h;

	    if ( defined $xmax ) {
		$xmax = $w if $w > $xmax;
	    }
	    else {
		$xmax = $w;
		$xmin = 0;
	    }
	    $ymax = $y;
	    $y -= $sep;
	}
	warn("Stacked ", scalar(@$forms), " XObjects => bb",
	     ( map { sprintf(" %.2f", $_ ) } $xmin, $ymax, $xmax, 0 ),
	     "\n")
	  if $verbose;
	$nx->bbox( $xmin, $ymax, $xmax, 0 );
    }


    return [ { xo      => $nx,
	       width   => $xmax - $xmin,
	       height  => -$ymax,
	       vwidth  => $xmax - $xmin,
	       vheight => -$ymax,
	       bbox    => [ $xmin, $ymax, $xmax, 0 ],
	       vbox    => [ $xmin, -$ymax, $xmax-$xmin, $ymax ],
	     } ];
}

################ Service ################

method vb2bb( @vb ) {
    # Calculate bounding box from viewBox
    @vb = @{$vb[0]} if ref($vb[0]) eq 'ARRAY';
    my @bb = ( $vb[0],        -$vb[1]-$vb[3],
	       $vb[0]+$vb[2], -$vb[1]       );

    wantarray ? @bb : \@bb;
}

method vb2bb_noflip( @vb ) {
    # Calculate bounding box from viewBox
    @vb = @{$vb[0]} if ref($vb[0]) eq 'ARRAY';
    my @bb = ( $vb[0],        $vb[1],
	       $vb[2]-$vb[0], $vb[3]-$vb[1] );

    wantarray ? @bb : \@bb;
}

method draw_grid ( $xo, $vb ) {
    my $d = $grid >= 5 ? $grid : 10;
    my @bb = @$vb;

    # Note that this methos is called *after* the yflip.
    $bb[2] += $bb[0];
    $bb[3] += $bb[1];

    my $w = -$bb[0]+$bb[2];
    my $h = -$bb[1]+$bb[3];
    my $thick = 1;
    my $thin = 0.2;
    my $maxlines = 100;

    # Avoid too many grid lines.
    while ( $h/$d > $maxlines || $w/$d > $maxlines ) {
	$d += $d;
    }

    $xo->save;

    # Show boundary points.
    my $dd = $d/2;
    $xo->rectangle( $bb[0]-$dd, $bb[1]-$dd, $bb[0]+$dd, $bb[1]+$dd);
    $xo->fill_color("cyan");
    $xo->fill;
    $xo->rectangle( $bb[2]-$dd, $bb[3]-$dd, $bb[2]+$dd, $bb[3]+$dd);
    $xo->fill_color("magenta");
    $xo->fill;
    # Show origin. This will cover the bb corner unless it is offset.
    $xo->rectangle( -$dd, $dd, $dd, -$dd );
    $xo->fill_color("red");
    $xo->fill;

    $xo->stroke_color("#bbbbbb");

    # Draw the grid (thick lines).
    $xo->line_width($thick);
    for ( my $x = 0; $x <= $bb[2]; $x += 5*$d ) {
	$xo->move( $x, $bb[1] );
	$xo->vline($bb[3]);
	$xo->stroke;
    }
    for ( my $x = -5*$d; $x > $bb[0]; $x -= 5*$d ) {
	next;
	$xo->move( $x, $bb[1] );
	$xo->vline($bb[3]);
	$xo->stroke;
    }
    for ( my $y = 0; $y <= $bb[3]; $y += 5*$d ) {
	$xo->move( $bb[0], $y );
	$xo->hline($bb[2]);
	$xo->stroke;
    }
    for ( my $y = -5*$d; $y > $bb[0]; $y -= 5*$d ) {
	next;
	$xo->move( $bb[0], $y );
	$xo->hline($bb[2]);
	$xo->stroke;
    }
    # Draw the grid (thin lines).
    $xo->line_width($thin);
    for ( my $x = 0; $x <= $w; $x += $d ) {
	$xo->move( $x, $bb[1] );
	$xo->vline($bb[3]);
	$xo->stroke;
    }
    for ( my $x = -$d; $x > $bb[0]; $x -= $d ) {
	$xo->move( $x, $bb[1] );
	$xo->vline($bb[3]);
	$xo->stroke;
    }
    for ( my $y = 0; $y <= $h; $y += $d ) {
	$xo->move( $bb[0], $y );
	$xo->hline($bb[2]);
	$xo->stroke;
    }
    for ( my $y = -$d; $y > $bb[1]; $y -= $d ) {
	$xo->move( $bb[0], $y );
	$xo->hline($bb[2]);
	$xo->stroke;
    }
    $xo->restore;
}

=head1 INPUT

The input SVG data B<must> be correct XML data.
The data can be a single C<< <svg> >> element, or a container
element (e.g. C<< <html> >> or C<< <xml> >>) with one or more
C<< <svg> >> elements among its children.

The SVG data can come from several sources:

=over 4

=item *

An SVG document on disk, specified as the name of the document.

=item *

A file handle, openened on a SVG document, specified as a glob
reference. You can use C<\*DATA> to append the SVG data after a
C<__DATA__> separator at the end of the program.

=item *

A string containing SVG data, specified as a reference to a scalar.

=back

The input is read using L<File::LoadLines>. See its documentation for
details.

=head1 OUTPUT

The result from calling process() is a reference to an array
containing hashes that describe the XObjects. Each hash has the
following keys:

=over 8

=item C<vbox>

The viewBox as specified in the SVG element.

If no viewBox is specified it is set to C<0 0> I<W H>, where I<W> and
I<H> are the width and the height.

=item C<width>

The width of the XObject, as specified in the SVG element or derived
from its viewBox.

=item C<height>

The height of the XObject, as specified in the SVG element or derived
from its viewBox.

=item C<vwidth>

The desired width, as specified in the SVG element or derived
from its viewBox.

=item C<vheight>

The desired height, as specified in the SVG element or derived
from its viewBox.

=item C<xo>

The XObject itself.

=back

=head1 FONT HANDLER CALLBACK

In SVG fonts are designated by style attributes C<font-family>,
C<font-style>, C<font-weight>, and C<font-size>. How these translate
to a PDF font is system dependent. SVGPDF provides a callback
mechanism to handle this. As described at L<CONSTRUCTOR>, constructor
argument C<fc> can be set to designate a user routine.

When a font is required at the PDF level, SVGPDF first checks if a
C<@font-face> CSS rule has been set up with matching properties. If a
match is found, it is resolved and the font is set. If there is no
appropriate CSS rule for this font, the callback is called with the
following arguments:

    ( $self, $pdf, $style )

where C<$pdf> is de PDF document and C<$style> a hash reference that
contains values for C<font-family>, C<font-style>, C<font-weight>, and
C<font-size>. Don't touch C<$self>, it is undocumented for a reason.

The callback function can use the contents of C<$style> to select an
appropriate font and return it.

SVGPDF will try to call the font handler callback only once for each
combination of family, style and weight. If the callback function
returns a 'false' result SVGPDF will try other alternatives to find a
font.

Example of an (extremely simplified) callback:

    sub simple_font_handler {
        my ( $self, $pdf, $style ) = @_;

	my $family = $style->{'font-family'};

	my $font;
	if ( $family eq 'sans' ) {
	    $font = $pdf->font('Helvetica');
	}
	else {
	    $font = $pdf->font('Times-Roman');
	}

        return $font;
    }

If no callback function is set, SVGPDF will recognize the standard
PDF corefonts, and aliases C<serif>, C<sans> and C<mono>.

B<IMPORTANT: With the standard corefonts only characters of the
ISO-8859-1 set (Latin-1) can be used. No greek, no chinese, no cyrillic.
You have been warned.>

=head1 LIMITATIONS

The following SVG elements are implemented.

=over 3

=item *

C<svg>, but not nested.

=item *

C<style>, as a child of the outer C<svg>.

Many style attributes are understood, including but not limited to:

color,
stroke, stroke-width, stroke-linecap, stroke-linejoin, stroke-dasharray,
fill, stroke-width, stroke-linecap, stroke-linejoin,
transform (translate, scale, skewX, skewY, rotate, matrix)
font-family, font-style, font-weight, font-size,
text-anchor.

Partially implemented: @font-face (src url data and local file only).

=item *

circle,
ellipse,
g,
image,
line,
path,
polygon,
polyline,
rect (no rounded corners),
text and tspan (no white-space styles).

=item *

defs and use,

=back

The following SVG features are partially implemented.

=over 3

=item *

Percentage units. For most "y", "h" or "height" attributes the result
will be the percentage of the viewBox height.

Similar for "x", "w" and "width".

Everything else will result in a percentage of the viewBox diagonal
(according to the specs).

=item *

Embedded SVG elements and preserveAspectRatio.

=item *

Standalone T-path elements.

=back

The following SVG features are not (yet) implemented.

=over 3

=item *

title, desc elements

=back

The following SVG features are not planned to be implemented.

=over 3

=item *

Shades, gradients, patterns and animations.

=item *

Shape rendering attributes.

=item *

Transparency.

=item *

Text paths.

=item *

Clipping and masking.

=back

What is supported, then? Most SVG files generated by any of the
following tools seem to produce good if not perfect results:

=over 3

=item *

C<abc2svg> (ABC music notation tool)

=item *

MathJax, inline and display without tag

=item *

GNUplot

=item *

QRcode and barcode generating tools

=item *

XTerm SVG screen dumps

=back

=head1 AUTHOR

Johan Vromans C<< < jvromans at squirrel dot nl > >>

Code for circular and elliptic arcs donated by Phil Perry.

=head1 SUPPORT

SVGPDF development is hosted on GitHub, repository
L<https://github.com/sciurius/perl-SVGPDF>.

Please report any bugs or feature requests to the GitHub issue tracker,
L<https://github.com/sciurius/perl-SVGPDF/issues>.

=head1 LICENSE

Copyright (C) 2022.2023 Johan Vromans,

Redistribution and use in source and binary forms, with or without
modification, are permitted provided under the terms of the Simplified
BSD License.

=cut

1; # End of SVGPDF
