#! perl

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

package ChordPro::Delegate::Strum;

=for docs

** EXPERIMENTAL ** EXPERIMENTAL ** EXPERIMENTAL ** EXPERIMENTAL **

Experimental delegate to produce a 'strum' image.

    bpm [ BPM ]
    time [ n/d ]

    d = down
    u = up
    xd = muted down
    xu = muted up
    +d = accented down
    +u = accented up

Config:

delegate.strum {
    type     : image
    module   : Strum
    handler  : strum2xo
    preamble : []
}

=cut

use ChordPro::Utils qw(dimension maybe);

sub DEBUG() { $::config->{debug}->{x2} }

sub strum2xo( $song, %args ) {
    my $elt = $args{elt};
    my $kv = { %{$elt->{opts}} };
    my $ps = $song->{_ps};
    my $pr = $ps->{pr};

    if ( DEBUG > 1 ) {
	use DDP; p %args, as => "args";
	use DDP; p $elt,  as => "elt";
	use DDP; p $kv,   as => "opts";
    }

    my $xo = $pr->{pdfgfx}->{' apipage'}->{' api'}->xo_form;
    my @xo;
    my $txtfont = $ps->{fonts}->{strum}->{fd};

    for ( @{ $elt->{data} } ) {

	my $s = Strum->new( data => $_ );

	push( @xo, $s->build( gfx     => $pr->{pdfgfx},
			      color   => "red",
			      txtfont => $txtfont,
			      size    => 30,
			      triplet => 3,
			    ) );
    }
    $xo = $xo[0];

    # Finish.
    my $scale;
    my $design_scale;
    $kv->{scale} = dimension( $kv->{scale}//1, width => 1 );
    if ( $kv->{scale} != 1 ) {
	if ( $kv->{id} ) {
	    $design_scale = $kv->{scale};
	}
	else {
	    $scale = $kv->{scale};
	}
    }
    return
	  { type    => "image",
	    line    => $elt->{line},
	    subtype => "xform",
	    data    => $xo,
	    width   => $xo->width,
	    height  => $xo->height,
	    opts => { maybe id           => $kv->{id},
		      maybe align        => $kv->{align},
		      maybe spread       => $kv->{spread},
		      maybe scale        => $scale,
		      maybe design_scale => $design_scale,
		    } };
}

# Pre-scan.
sub options( $data ) { {} }

use Object::Pad;

################

class Strum;

sub DEBUG() { $::config->{debug}->{x2} }
use Ref::Util qw( is_arrayref );

field $data    :param;

# These are initialized by 'build' method.
field $do;			# drawing object
field $size;
field $color;

method build( %args ) {

    my $missing = "";
    for ( qw( gfx size ) ) {
	$missing .= "$_ " unless defined $args{$_};
    }
    die("Missing arguments to Strum::build: $missing\n") if $missing;

    my $gfx  = $args{gfx};
    $size = $args{size};
    my $triplet = $args{triplet};
    my $x = 0;
    my $y = 0;
    $do = DrawingObject->new( gfx     => $gfx,
			      size    => $size,
			      txtfont => $args{txtfont},
			      color   => $color // "blue",
			    );
    my $lw = $do->lw;
    my $hw = $do->hw;
    my $hhw = $do->hhw;
    my $xo = $do->newxo;
    my $i = 0;
    my ( $w, $h );
    while ( $data =~ m/([x+]?)([ud]| )/g ) {
	$i++;
	warn( sprintf("%d: x = %6.2f, \"%s\"\n", $i, $x, $1.$2 ) );
	$do->strum( $x, $y,
		    up     => $2 eq 'u',
		    mute   => $1 eq 'x',
		    accent => $1 eq '+' ) if $2 ne " ";
	if ( $i == 3 ) {
	    $x -= $hw;
	    $i = 0;
	}
	else {
	    $do->grid( $x, $y - $hw - $hhw );
	    if ( $triplet && $i == 1) {
		$do->set_txtfont(10);
		$do->set_markup("3");
		( $w, $h ) = $do->get_size;
		$do->show( $x + 2*$hw + $w/2, $y - $h );
	    }
	}
	$x += 2*$hw;
    }

    $xo->bbox( -$lw/2, -$hw-$hhw-$lw/2 - ( $triplet ? $h : 0 ),
	       $x+$lw/2, $size+$hw+$lw/2 );
    return $xo;
}

################ Draw Object ################

class DrawingObject;

field $gfx	:accessor :param;
field $size     :accessor :param;
field $txtfont  :accessor :param;
field $color    :accessor :param = "lime";
field $lw       :accessor :param = undef;
field $hw	:accessor :param = undef;

field $pdf	:accessor;
field $hhw      :accessor;
field $layout;

ADJUST {
    $pdf = $gfx->{' apipage'}->{' api'};
    $lw //= $size / 40;
    $hw //= $size / 4;
    $hhw = $hw/2;
};

method newxo() {
    $gfx = $pdf->xo_form;
    $gfx->fill_color($color);
    $gfx->stroke_color($color);
    $gfx->line_width($lw);
    $gfx;
}

# Drawing methods. Most of them return self for call chaining.
method move( $x, $y ) {
    $gfx->move( $x, $y );
    $self;
}
method line( $x, $y ) {
    $gfx->line( $x, $y );
    $self;
}
method vline( $y ) {
    $gfx->vline( $y );
    $self;
}
method hline( $x ) {
    $gfx->hline( $x );
    $self;
}
method close() {
    $gfx->close;
    $self;
}
method fill() {
    $gfx->fill;
    $self;
}
method fillstroke() {
    $gfx->fillstroke;
    $self;
}
method stroke() {
    $gfx->stroke;
    $self;
}
method rectangle( $x1,$y1, $x2,$y2 ) {
    $gfx->rectangle( $x1,$y1, $x2,$y2 );
    $self;
}
method bboxlw( $x1,$y1, $x2,$y2 ) {
    my $lw2 = $lw/2;
    $gfx->bbox( $x1-$lw2, $y1+$lw2, $x2+$lw2, $y2-$lw2 );
    $self;
}

#### High level methods.

method strum( $x, $y, %args ) {
    my $up     = $args{up}     || 0;
    my $mute   = $args{mute}   || 0;
    my $accent = $args{accent} || 0;

#    $args{x} = $x; $args{y} = $y; use DDP; p %args;

    $x += $hhw;

    if ( $up ) {
	$self->move( $x, 0 );
	$self->vline( $y+$size-$hhw );
	$self->triangle( $x, $y+$size - $hhw, up => 1 );
    }
    else {
	$self->move( $x, $hhw );
	$self->vline( $y+$size );
	$self->triangle( $x, $y - $hw );
    }

    if ( $args{mute} ) {
	$self->move( $x - $hhw, $y+$size + $hw )
	  ->line( $x + $hhw, $y+$size )->stroke;
	$self->move( $x - $hhw, $y+$size )
	  ->line( $x + $hhw, $y+$size + $hw )->stroke;
    }
    elsif ( $args{accent} ) {
	$self->move( $x - $hhw, $y+$size + $hw )
	  ->line( $x + $hhw, $y+$size + $hhw)
	  ->line( $x - $hhw, $y+$size )->stroke;
    }
    $self;
}

method triangle( $x, $y, %args ) {
    if ( $args{up} ) {
	$gfx->move( $x, $y-$hhw );
	$gfx->polyline( $x-$hhw,$y-$hhw, $x,$y+$hhw, $x+$hhw,$y-$hhw );
    }
    else {
	$gfx->move( $x, $hw );
	$gfx->polyline( $x-$hhw,$hw, $x,0, $x+$hhw,$hw );
    }
    $gfx->close->fillstroke;
    $self;
}

method grid( $x, $y, %args ) {
    my $dx = 2*$hw;
    $x += $hhw;
    my $dy = $hw;
    $self->move( $x, $y+$dy )
      ->vline( $y )
      ->hline( $x+$dx )
      ->vline( $y+$dy )
      ->stroke;
}

# Text methods.
method set_txtfont( $sz = undef ) {
    $layout //= Text::Layout->new($pdf);
    $layout->set_font_description($txtfont);
    $layout->set_font_size( $sz || $size );
}
method set_font_size($sz) {
    $layout->set_font_size($sz);
    $self;
}
method set_markup($t) {
    $layout //= Text::Layout->new($pdf);
    $layout->set_markup("<span color='$color'>$t</span>");
#    $layout->set_markup($t);
    $self;
}
method get_size() {
    $layout->get_size();
}
method show( $x, $y ) {
    $gfx->textstart;
    $layout->show( $x, $y, $gfx );
    $gfx->textend;
    $self;
}
1;
