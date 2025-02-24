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
    ad = arpeggio down
    au = arpeggio up

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
    my $bpm = 4;
    if ( ($song->{meta}->{time}->[0] // "4/4") =~ /^\s*(\d+)\s*\/\s*(\d+)\s*$/ ) { 
	$bpm = $1;
    }

    if ( DEBUG > 1 ) {
	use DDP; p %args, as => "args";
	use DDP; p $elt,  as => "elt";
	use DDP; p $kv,   as => "opts";
    }

    my $xo = $pr->{pdfgfx}->{' apipage'}->{' api'}->xo_form;
    my @xo;
    my $txtfont = ($ps->{fonts}->{strum}//$ps->{fonts}->{text})->{fd};

    for ( @{ $elt->{data} } ) {

	my $s = Strum->new( data => $_ );

	push( @xo, $s->build( gfx     => $pr->{pdfgfx},
			      color   => $kv->{color} // $pr->_fgcolor,
			      txtfont => $txtfont,
			      size    => $kv->{size} || 30,
			      bpm     => $bpm,
			      tuplet  => $kv->{tuplet} || 1,
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
use ChordPro::Utils qw(maybe);

field $data    :param;

# These are initialized by 'build' method.
field $do;			# drawing object
field $size;
field $color;
field $tuplet;
field $bpm;

BUILD {
    if ( $data =~ /-(\d+)(t?)\s*$/ ) {
	$bpm = 4;
	$tuplet = 1;#$1/$bpm;
	$tuplet *= 3 if $2;
	my @d;
	while ( $data =~ m/([udUdMmAa r])/g ) {
	    my $c = $1;
	    push( @d, {       arrow  =>
			      ( $c =~ /[r ]/ ? " "
				: ( !!($c =~ /[uUma]/) ? "u" : "d" ) ),
			maybe mute   => !!( $c =~ /m/i ),
			maybe arpeggio => !!( $c =~ /a/i ),
		      } );
	}
	$data = \@d;
    }
    else {
	my @d;
	while ( $data =~ m/([x+]?)(a?)([ud]| )/g ) {
	    push( @d, {       arrow  => $3,
			maybe mute   => ($1 eq 'x'),
			maybe accent => ($1 eq '+'),
			maybe arpeggio => ($2 eq 'a'),
		      } );
	}
	$data = \@d;
    }
};

method build( %args ) {

    my $missing = "";
    for ( qw( gfx size ) ) {
	$missing .= "$_ " unless defined $args{$_};
    }
    die("Missing arguments to Strum::build: $missing\n") if $missing;

    my $gfx  = $args{gfx};
    $size = $args{size};
    my $x = 0;
    my $y = 0;
    $do = DrawingObject->new( gfx     => $gfx,
			      size    => $size,
			      txtfont => $args{txtfont},
			      color   => $color = $args{color} // "black",
			    );
    my $lw  = $do->lw;
    my $hw  = $do->hw;
    my $hhw = $do->hhw;
    my $xo  = $do->newxo;
    my $i   = 0;
    my ( $w, $h );

    while ( 1 ) {
	$i++;
	$x =
	$do->strum( $x, $y, $data,
		    bpm => $bpm || $args{bpm} || 4,
		    tuplet => $tuplet || $args{tuplet} || 1,
		  );
	last;
    }

    $xo->bbox( -$lw/2,
	       -$hw-$hhw-$lw/2,
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

method strum( $x, $y, $data, %args ) {

    my $tuplet = $args{tuplet} || 1;
    my $bpm    = $args{bpm}    || 4;
    $data = [ @$data ];

    while ( @$data ) {
	for my $beat ( 1 .. $bpm ) {
	    for my $tp ( 1 .. $tuplet ) {

		$_ = shift(@$data);
		my $arrow  = $_->{arrow}  || " ";
		my $mute   = $_->{mute}   || 0;
		my $accent = $_->{accent} || 0;
		my $arpeggio = $_->{arpeggio} || 0;

		# $args{x} = $x; $args{y} = $y; use DDP; p %args;

		$x += $hhw;

		if ( $arrow eq "u" ) {
		    $self->move( $x, $y );
		    if ( $arpeggio ) {
			#$self->gfx->line_dash_pattern(3);
			#$self->vline( $y+$size-$hhw )->stroke;
			#$self->gfx->line_dash_pattern();
			$self->vline(            $y +   $hhw );
			$self->curve( $x,        $y + 2*$hhw,
				      $x - $hhw, $y + 2*$hhw,
				      $x,        $y + 3*$hhw );
			$self->curve( $x + $hhw, $y + 4*$hhw,
				      $x,        $y + 4*$hhw,
				      $x,        $y + 5*$hhw );
			$self->vline(            $y+$size )->stroke;
		    }
		    else {
			$self->vline( $y + $size - $hhw );
		    }
		    $self->triangle( $x, $y + $size - $hhw, up => 1 );
		}
		elsif ( $arrow eq "d" ) {
		    $self->move( $x, $y + $hhw );
		    if ( $arpeggio ) {
			$self->vline(            $y + 3*$hhw );
			$self->curve( $x,        $y + 4*$hhw,
				      $x - $hhw, $y + 4*$hhw,
				      $x,        $y + 5*$hhw );
			$self->curve( $x + $hhw, $y + 6*$hhw,
				      $x,        $y + 6*$hhw,
				      $x,        $y + 7*$hhw );
			$self->vline(            $y+$size )->stroke;
		    }
		    else {
			$self->vline( $y+$size );
		    }
		    $self->triangle( $x, $y - $hw );
		}

		if ( $mute ) {
		    $self->move( $x - 0.8*$hhw, $y+$size + $hw )
		      ->line( $x + 0.8*$hhw, $y+$size + 0.2*$hw )->stroke;
		    $self->move( $x - 0.8*$hhw, $y+$size + 0.2*$hw )
		      ->line( $x + 0.8*$hhw, $y+$size + $hw )->stroke;
		}
		elsif ( $accent ) {
		    $self->move( $x - 0.8*$hhw, $y+$size + $hw )
		      ->line( $x + 0.8*$hhw, $y+$size + 0.6*$hw)
		      ->line( $x - 0.8*$hhw, $y+$size + 0.2*$hw )->stroke;
		}

		if ( $tp == 1 ) {
		    $self->set_txtfont($hw);
		    $self->cshow( $x, $y - $hhw/2, $beat );
		}
		else {
		    $self->set_txtfont($hw);
		    $self->cshow( $x, $y - $hhw/2, "&" );
		}
		if ( 0 and $tp < $tuplet ) {
		    my $dx = 2*$hw;
		    my $dy = $hw;
		    $self->move( $x, $y - $hhw - $hw )
		      ->vline( $y - 2*$hw )
		      ->hline( $x+$dx )
		      ->vline( $y - $hhw - $hw )
		      ->stroke;
		}
		$x += 3*$hhw;
	    }
	}
    }

    $x - $hw;
}

method triangle( $x, $y, %args ) {
    if ( $args{up} ) {
	$gfx->move( $x, $y-$hhw );
	$gfx->polyline( $x-0.8*$hhw,$y-$hhw, $x,$y+$hhw, $x+0.8*$hhw,$y-$hhw );
    }
    else {
	$gfx->move( $x, $hw );
	$gfx->polyline( $x-0.8*$hhw,$hw, $x,0, $x+0.8*$hhw,$hw );
    }
    $gfx->close->fillstroke;
    $self;
}

method curve( $cx1,$cy1, $cx2,$cy2, $x,$y ) {
    $gfx->curve($cx1,$cy1, $cx2,$cy2, $x,$y);
    $gfx;
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
    $layout->get_size;
}
method show( $x, $y, $markup = undef ) {
    $self->set_markup($markup) if defined $markup;
    $gfx->textstart;
    $layout->show( $x, $y, $gfx );
    $gfx->textend;
    $self;
}

method cshow( $x, $y, $markup = undef ) {
    $self->set_markup($markup) if defined $markup;
    my ( $w, $h ) = $layout->get_size;
    $gfx->textstart;
    $layout->show( $x - $w/2, $y, $gfx );
    $gfx->textend;
    $self;
}

1;
