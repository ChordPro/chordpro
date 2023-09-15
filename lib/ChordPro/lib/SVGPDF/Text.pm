#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Text :isa(SVGPDF::Element);

method process () {
    my $atts  = $self->atts;
    my $xo    = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    my ( $x, $y, $dx, $dy, $tf ) =
      $self->get_params( $atts, qw( x:s y:s dx:U dy:U transform:s ) );
    my $style = $self->style;
    $_ = 0+$self->u($_) for $style->{'font-size'};
    my $text = "";

    my $color = $style->{fill};
    $color = $style->{color} if $color && $color eq "currentColor";
    my $anchor = $style->{'text-anchor'} || "left";

    $self->_dbg( $self->name, " ",
		 defined($atts->{x}) ? ( " x=$x" ) : (),
		 defined($atts->{y}) ? ( " y=$y" ) : (),
		 defined($atts->{dx}) ? ( " dx=$dx" ) : (),
		 defined($atts->{dy}) ? ( " dy=$dy" ) : (),
		 defined($style->{"text-anchor"})
		 ? ( " anchor=\"$anchor\"" ) : (),
		 defined($style->{"transform"}) #???
		 ? ( " transform=\"$tf\"" ) : (),
		 );

    # We assume that if there is an x/y list, there is one single text
    # argument.

    my @c = $self->get_children;

    if ( $x =~ /,/ ) {
	if ( @c > 1 || ref($c[0]) ne "SVGPDF::TextElement" ) {
	    die("text: Cannot combine coordinate list with multiple elements\n");
	}
	$x = [ $self->getargs($x) ];
	$y = [ $self->getargs($y) ];
	$text = [ split( //, $c[0]->content ) ];
	die( "\"", $self->get_cdata, "\" ", 0+@$x, " ", 0+@$y, " ", 0+@$text )
	  unless @$x == @$y && @$y == @$text;
    }
    else {
	$x = [ $self->u($x||0) ];
	$y = [ $self->u($y||0) ];
    }

    $self->_dbg( "+ xo save" );
    $xo->save;
    my $ix = $x->[0];
    my $iy = $y->[0];
    my ( $ex, $ey );

    my $scalex = 1;
    my $scaley = 1;
    if ( $tf ) {
	( $dx, $dy ) = $self->getargs($1)
	  if $tf =~ /translate\((.*?)\)/;
	( $scalex, $scaley ) = $self->getargs($1)
	  if $tf =~ /scale\((.*?)\)/;
	$scaley ||= $scalex;
	$self->_dbg("TF: $dx, $dy, $scalex, $scaley")
    }
    # NOTE: rotate applies to the individual characters, not the text
    # as a whole.

    if ( $color ) {
	$xo->fill_color($color);
    }

    if ( @$x > 1 ) {
      for ( @$x ) {
	if ( $tf ) {
	    $self->_dbg( "X %.2f = %.2f + %.2f",
			 $dx + $_, $dx, $_ );
	    $self->_dbg( "Y %.2f = - %.2f - %.2f",
			 $dy + $y->[0], $dy, $y->[0] );
	}
	my $x = $dx + $_;
	my $y = $dy + shift(@$y);
	$self->_dbg( "txt* translate( %.2f, %.2f )%s %x",
		     $x, $y,
		     ( $scalex != 1 || $scaley != -1 )
		     ? sprintf(" scale( %.1f, %.1f )", $scalex, -$scaley ) : "",
		     ord($text->[0]));
	#	$xo-> translate( $x, $y );
	$xo->save;
	$xo->transform( translate => [ $x, $y ],
			($scalex != 1 || $scaley != -1 )
			? ( scale => [ $scalex, -$scaley ] ) : (),
		      );
	my %o = ();
	$o{align} = $anchor eq "end"
	  ? "right"
	  : $anchor eq "middle" ? "center" : "left";
	$xo->textstart;
	$self->set_font( $xo, $style );
	$xo->text( shift(@$text), %o );
	$xo->textend;
	$xo->restore;
      }
    }
    else {
	$_ = $x->[0];
	if ( $tf ) {
	    $self->_dbg( "X %.2f = %.2f + %.2f",
			 $dx + $_, $dx, $_ );
	    $self->_dbg( "Y %.2f = - %.2f - %.2f",
			 - $dy - $y->[0], $dy, $y->[0] );
	}
	my $x = $dx + $_;
	my $y = $dy + shift(@$y);
	$self->_dbg( "txt translate( %.2f, %.2f )%s",
		     $x, $y,
		     ($scalex != 1 || $scaley != -1 )
		     ? sprintf(" scale( %.2f %.2f )", $scalex, -$scaley ) : "" );
	my %o = ();
	$o{align} = $anchor eq "end"
	  ? "right"
	  : $anchor eq "middle" ? "center" : "left";
	my $tc = $self->root->tc;
	my $fc = $self->root->fc;
	for my $c ( @c ) {
	    if ( ref($c) eq 'SVGPDF::TextElement' ) {
		$self->_dbg( "+ xo save" );
		$xo->save;
		$xo->transform( translate => [ $x, $y ],
				($scalex != 1 || $scaley != -1 )
				? ( scale => [ $scalex, -$scaley ] ) : ()
			      );
		$scalex = $scaley = 1; # no more scaling.

		$xo->textstart;
		if ( $tc ) {
		    $x += $tc->( $self, $xo, $self->root->pdf,
				 $style, $c->content, %o );
		}
		else {
		    $self->set_font( $xo, $style );
		    $x += $xo->text( $c->content, %o );
		}
		$xo->textend;
		if ( $style->{'outline-style'} ) {
		    # BEEP BEEP TRICKERY.
		    my $fn = $xo->{" font"};
		    my $sz = $xo->{" fontsize"};
		    $xo->line_width( $self->u($style->{'outline-width'} || 1 ));
		    $xo->stroke_color( $style->{'outline-color'} || 'black' );
		    my $d = $self->u($style->{'outline-offset'}) || 1;
		    $xo->rectangle( -$d,
				    -$d+$sz*$fn->descender/1000,
				    $x-$ix+2*$d,
				    2*$d+$sz*$fn->ascender/1000 );
		    $xo->stroke;
		}
		$self->_dbg( "- xo restore" );
		$xo->restore;
		$ex = $x; $ey = $y;
	    }
	    elsif ( ref($c) eq 'SVGPDF::Tspan' ) {
		$self->_dbg( "+ xo save" );
		$xo->save;
		if ( defined($c->atts->{x}) ) {
		    $x = 0;
		}
		if ( defined($c->atts->{'y'}) ) {
		    $y = 0;
		}
		$xo->transform( translate => [ $x, $y ],
				( $scalex != 1 || $scaley != -1 )
				? ( scale => [ $scalex, -$scaley ] ) : (),
			      );
		$scalex = $scaley = 1; # no more scaling.
		my ( $x0, $y0 ) = $c->process();
		$x += $x0; $y += $y0;
		$self->_dbg("tspan moved to $x, $y");
		$self->_dbg( "- xo restore" );
		$xo->restore;
		$ex = $x; $ey = $y;
	    }
	    else {
		$self->nfi( $c->name . " in text" );
	    }
	}
    }

    $self->_dbg( "- xo restore" );
    $xo->restore;
    $self->css_pop;
}

1;
