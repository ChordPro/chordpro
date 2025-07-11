#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Image :isa(SVGPDF::Element);

method process () {
    my $atts = $self->atts;
    my $xo   = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    my ( $x, $y, $w, $h, $link, $tf ) =
      $self->get_params( $atts, qw( x:H y:V width:H height:V href:! transform:s ) );

    $x ||= 0; $y ||= 0;
    $w ||= 0; $h ||= 0;

    unless ( $w && $h ) {
	$self->_dbg( $self->name, " x=$x y=$y w=$w h=$h  **skipped**" );
	return;
    }

    $self->_dbg( $self->name, " x=$x y=$y w=$w h=$h" );

    my $img;
    if ( $link =~ /^data:/ ) {
	# In-line image asset.
	my $info = $self->data_inline($link);
	if ( $info->{error} ) {
	    warn( "SVG: ", $info->{error}, "\n" );
	    $self->css_pop, return;
	}

	my $mimetype = $info->{mimetype};
	my $subtype  = $info->{subtype};

	unless ( $mimetype eq "image" ) {
	    warn("SVG: Unhandled mime type \"mimetype/$subtype\" in inline image\n");
	    $self->css_pop, return;
	}
	my $data = $info->{data};

	# Get info.
	require Image::Info;
	$info = Image::Info::image_info(\$data);
	if ( $info->{error} ) {
	    warn($info->{error});
	    $self->css_pop, return;
	}

	my $format = $info->{file_ext};
	$format = "jpeg" if $format eq "jpg";
	$format = "pnm"  if $format =~ /^p[bgp]m$/;
	$format = "pnm"  if $format =~ /^x[bp]m$/; # bonus
	$format = "tiff" if $format eq "tif";

	# Make the image. Silence missing library warnings.
	my $fh;
	# Also, do not use the fast IPL module, it cannot read from scalar.
	if ( $format eq "tiff" ) {
	    # TIFF can't read from scalar file handle.
	    use File::Temp;
	    ( my $fd, $fh ) = File::Temp::tempfile( UNLINK => 1 );
	    binmode $fd => ':raw';
	    print $fd $data;
	    close($fd);
	    # Yes, trickery... $fh is now a file name, not a handle.
	}
	else {
	    open( $fh, '<:raw', \$data );
	}
	$img = $self->root->pdf->image( $fh, format => $format,
					silent => 1, nouseIPL => 1 );
    }
    elsif ( $link =~ m!^.+\.(png|jpe?g|gif)$!i && -s $link ) {
	# Autodetected. Make the image.
	$img = $self->root->pdf->image( $link, silent => 1 );
    }
    elsif ( $link =~ m!^.+\.(tiff?|p[bgp]m|x[bp]m)$!i && -s $link ) {
	# Not autodetected, need format.
	# Note that xbm and xpm are bonus.
	my $format = $1 =~ /tif/i ? "tiff" : "pnm";
	# Make the image.
	$img = $self->root->pdf->image( $link, format => $format, silent => 1 );
    }
    else {
	warn("SVG: Unhandled or missing image link: ",
	     "\"$link\""//"<undef>", "\n");
	return;
    }

    $self->_dbg( "xo save" );
    $xo->save;

    # Place the image.
    $self->set_transform($tf) if $tf;
    $xo->transform( translate => [ $x, $y+$h ] );
    $xo->image( $img, 0, 0, $w, -$h );

    $self->_dbg( "xo restore" );
    $xo->restore;
    $self->css_pop;
}


1;
