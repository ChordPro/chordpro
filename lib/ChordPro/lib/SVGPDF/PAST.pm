#! perl

use v5.26;
use Object::Pad;
use Carp;
use utf8;

# Use this package as an intermediate to trace the actual operations.

class SVGPDF::PAST;

use Carp;

field $pdf :param;
field $xo  :accessor;

field $indent;
field $prog :accessor;

method xdbg ( $fmt, @args ) {
    if ( $fmt =~ /\%/ ) {
	$prog .= $indent . sprintf( $fmt, @args) . "\n";
    }
    else {
	$prog .= $indent . join( "", $fmt, @args ) . "\n";
    }
}

BUILD {
    $indent = $prog = "";
    $xo = $pdf->xo_form;
}

#### Coordinates

method bbox ( @args ) {
    $self->xdbg( "\$page->bbox( ", join(", ", @args ), " );" );
    $xo->bbox( @args );
}

method transform ( %args ) {
    my $tag = "\$xo->transform(";
    while ( my ($k,$v) = each %args ) {
	$tag .= " $k => ";
	if ( ref($v) eq 'ARRAY' ) {
	    $tag .= "[ " . join(", ", @$v) . " ]";
	}
	else {
	    $tag .= "\"$v\"";
	}
	$tag .= ", ";
    }
    substr( $tag, -2, 2, " );" );
    $self->xdbg($tag);
    $xo->transform( %args );
}

method matrix ( @args ) {
    $self->xdbg( "\$xo->matrix( ", join(", ", @args ), " );" );
    $xo->matrix(@args);
}

#### Graphics.

method fill ( @args ) {
    die if @args;
    $self->xdbg( "\$xo->fill();" );
    $xo->fill( @args );
}

method fill_color ( @args ) {
    Carp::confess("currentColor") if $args[0] eq 'currentColor';
    $self->xdbg( "\$xo->fill_color( \"@args\" );" );
    $xo->fill_color( @args );
}

method line_cap ( @args ) {
    $self->xdbg( "\$xo->line_cap( ", join(", ", @args ), " );" );
    $xo->line_cap( @args );
}

method line_dash_pattern ( @args ) {
    $self->xdbg( "\$xo->line_dash_pattern( ", join(", ", @args ), " );" );
    $xo->line_dash_pattern( @args );
}

method line_join ( @args ) {
    $self->xdbg( "\$xo->line_join( ", join(", ", @args ), " );" );
    $xo->line_join( @args );
}

method line_width ( @args ) {
    $self->xdbg( "\$xo->line_width( ", join(", ", @args ), " );" );
    $xo->line_width( @args );
}

method paint ( @args ) {
    die if @args;
    $self->xdbg( "\$xo->paint();" );
    $xo->paint( @args );
}

method restore ( @args ) {
    die if @args;
    $indent = substr( $indent, 2 );
    $self->xdbg( "\$xo->restore();" );
    $xo->restore;
}

method save ( @args ) {
    die if @args;
    $self->xdbg( "\$xo->save();" );
    $indent = "$indent  ";
    $xo->save;
}

method stroke ( @args ) {
    die if @args;
    $self->xdbg( "\$xo->stroke();" );
    $xo->stroke( @args );
}

method stroke_color ( @args ) {
    $self->xdbg( "\$xo->stroke_color( \"@args\" );" );
    $xo->stroke_color( @args );
}

#### Texts,

method font ( $font, $size, $name = "default" ) {
    $self->xdbg( "\$xo->font( \$font, $size );\t# $name" );
    $xo->font( $font, $size );
}

method text ( $text, %opts ) {
    my $t = $text;
    if ( length($t) == 1 && ord($t) > 255 ) {
	$t = sprintf("\\x{%04x}", ord($t));
    }
    else {
	$t =~ s/(["\\\x{0}-\x{1f}\x{ff}-\x{ffff}])/sprintf("\\x{%x}", ord($1))/ge;
    }
    $self->xdbg( "\$xo->text( \"$t\", ",
	  join( ", ", map { "$_ => \"$opts{$_}\"" } keys %opts ),
	  " );" );
    $xo->text( $text, %opts );
}

method textstart ( @args ) {
    die if @args;
    $self->xdbg( "\$xo->textstart();" );
    $xo->textstart( @args );
}

method textend ( @args ) {
    die if @args;
    $self->xdbg( "\$xo->textend();" );
    $xo->textend( @args );
}

#### Basic shapes.

method circle ( @args ) {
    $self->xdbg( "\$xo->circle( ", join(", ",@args), " );" );
    $xo->circle( @args );
}

method ellipse ( @args ) {
    $self->xdbg( "\$xo->ellipse( ", join(", ",@args), " );" );
    $xo->ellipse( @args );
}

method image( @args ) {
    my $image = shift(@args);
    $self->xdbg( "\$xo->image(<img>, ", join(", ",@args), " );" );
    $xo->image( $image, @args );
}

method line ( @args ) {
    $self->xdbg( "\$xo->line( ", join(", ",@args), " );" );
    $xo->line( @args );
}

# Note: polygon is a closed polyline.
method polyline ( @args ) {
    $self->xdbg( "\$xo->polyline( ", join(", ",@args), " );" );
    $xo->polyline( @args );
}

method rect ( @args ) {
    $self->xdbg( "\$xo->rect( ", join(", ",@args), " );" );
    $xo->rect( @args );
}

method rectangle ( @args ) {
    $self->xdbg( "\$xo->rectangle( ", join(", ",@args), " );" );
    $xo->rectangle( @args );
}

#### Paths.

#### NOT USED.
method bogen ( @args ) {
    $self->xdbg( "\$xo->bogen( ", join(", ",@args), " );" );
    $xo->bogen( @args );
}

#### NOT USED.
method bogen_ellip ( @args ) {
    $self->xdbg( "\$xo->bogen_ellip( ", join(", ",@args), " );" );
    $xo->bogen_ellip( @args );
}

method close ( @args ) {
    die if @args;
    $self->xdbg( "\$xo->close();" );
    $xo->close( @args );
}

method curve ( @args ) {
    $self->xdbg( "\$xo->curve( ", join(", ",@args), " );" );
    $xo->curve( @args );
}

method hline ( @args ) {
    $self->xdbg( "\$xo->hline( @args );" );
    $xo->hline( @args );
}

method move ( @args ) {
    $self->xdbg( "\$xo->move( ", join(", ",@args), " );" );
    $xo->move( @args );
}

method pie ( @args ) {
    $self->xdbg( "\$xo->pie( ", join(", ",@args), " );" );
    $xo->pie( @args );
}

method spline ( @args ) {
    $self->xdbg( "\$xo->spline( ", join(", ",@args), " );" );
    $xo->spline( @args );
}

method vline ( @args ) {
    $self->xdbg( "\$xo->vline( @args );" );
    $xo->vline( @args );
}

1;
