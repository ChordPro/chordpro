#! perl

package App::Music::ChordPro::Output::PDFPango::PDFWriter;

use strict;
use warnings;
use Encode;
use Cairo;
use Pango;

# For regression testing, run perl with PERL_HASH_SEED set to zero.
# This eliminates the arbitrary order of font definitions and triggers
# us to pinpoint some other data that would otherwise be varying.
my $regtest = defined($ENV{PERL_HASH_SEED}) && $ENV{PERL_HASH_SEED} == 0;
my $faketime = 1465041600;
my $TWOPI = 8*atan2(1,1);

my %fontcache;			# speeds up 2 seconds per song

sub new {
    my ( $pkg, $ps, $output ) = @_;
    my $self = bless { ps => $ps }, $pkg;
    $self->{surface} = Cairo::PdfSurface->create( $output,
						  $ps->{papersize}->[0],
						  $ps->{papersize}->[1] );
    $self->{cr} = Cairo::Context->create( $self->{surface} );
    $self->{layout} = Pango::Cairo::create_layout($self->{cr});
    $self->{_pages} = 0;
    %fontcache = () if $::__EMBEDDED__;
    $self;
}

sub info {
    my ( $self, %info ) = @_;
    return unless $self->{surface}->can("set_metadata");
    unless ( $info{CreationDate} ) {
	my @tm = gmtime( $regtest ? $faketime : time );
	$info{CreationDate} =
	  sprintf("%04d-%02d-%02dT%02d:%02d:%02d'",
		  1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]);
    }
    while ( my ( $k, $v ) = each %info ) {
	eval {
	    $k = "create-date" if $k eq "CreationDate";
	    $self->{surface}->set_metadata( lc $k => $v );
	};
	warn($@) if $@;		# should not happen
    }
}


sub wrap {
    my ( $self, $text, $m ) = @_;
    #TODO: FAILS WHEN markup is used!
    my $ex = "";
    my $sp = "";
    #warn("TEXT: |$text| ($m)\n");
    while ( $self->strwidth($text) > $m ) {
	my ( $l, $s, $r ) = $text =~ /^(.+)([-_,.:;\s])(.+)$/;
	return ( $text, $ex ) unless defined $s;
	#warn("WRAP: |$text| -> |$l|$s|$r$sp$ex|\n");
	if ( $s =~ /\S/ ) {
	    $l .= $s;
	    $s = "";
	}
	$text = $l;
	$ex = $r . $sp . $ex;
	$sp = $s;
    }

    return ( $text, $ex );
}

sub text {
    my ( $self, $text, $x, $y, $font, $size, $color ) = @_;
    return $x unless length($text);

    $font ||= $self->{font};
    my $fdesc = $font->{font};
    $size ||= $font->{size};
    $color ||= $font->{color} || "black";
    #warn("TEXT: \"$text\" $x $y ", $font->{font}->to_string, " $size $color\n")
      ;

    # Note the 1.33 scaling is to map Pango points (96dpi) to PDF
    # points (72dpi). There should be a better way to do this.
    $fdesc->set_size($size*1024/1.33);

    my $layout = $self->{layout};
    $layout->set_font_description($fdesc);

    # It would be nice if we could use this for background,
    # but pango background does not match the bounding box (frame).
    $text = "<span color='$color'>$text</span>";
    $layout->set_markup( $text );

    # Handle decorations (background, box).
    my $bgcol = $font->{background};
    undef $bgcol if $bgcol && $bgcol =~ /^no(?:ne)?$/i;
    my $frame = $font->{frame};
    undef $frame if $frame && $frame =~ /^no(?:ne)?$/i;
    if ( $bgcol || $frame ) {
	my $e = ($layout->get_pixel_extents)[1]; # 0 = ink, 1 = bb
	$self->rectxy( $x + $e->{x} - 1, $y + $e->{y},
		       $x + $e->{width} + 1, $y + $e->{height},
		       0.5, $bgcol,
		       $frame ? $font->{color} || "black" : undef );
    }

    $self->{cr}->move_to( $x, $y);# - ($layout->get_pixel_extents)[1]->{y});
    Pango::Cairo::show_layout( $self->{cr}, $layout );
    # For unknown reasons, a stroke is needed...???
    $self->{cr}->stroke;
    $x += ($layout->get_pixel_extents)[1]->{width};
    return $x;
}

sub setfont {
    my ( $self, $font, $size ) = @_;
    $self->{font} = $font;
    $self->{fontsize} = $size ||= $font->{size};
}

####NOTE: $self->{fontsize} overrules size....
sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
    my $layout = $self->{layout};
    my $fdesc = $font->{font};
    Carp::confess("FDESC") unless $fdesc;
    $fdesc->set_size($size*1024/1.33);
#    warn("SW: \"$text\" ", $fdesc->to_string, " $size\n");
    $layout->set_font_description($fdesc);
    $layout->set_markup( $text );
    my @e = $layout->get_pixel_size;
    $e[0];
}

sub strheight {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
    my $layout = $self->{layout};
    my $fdesc = $font->{font};
    Carp::confess("FDESC") unless $fdesc;
    $fdesc->set_size($size*1024/1.33);
#    warn("SW: \"$text\" ", $fdesc->to_string, " $size\n");
    $layout->set_font_description($fdesc);
    $layout->set_markup( $text );
    my @e = $layout->get_pixel_size;
    $e[1];
}

sub strbaseline {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
    my $layout = $self->{layout};
    my $fdesc = $font->{font};
    Carp::confess("FDESC") unless $fdesc;
    $fdesc->set_size($size*1024/1.33);
#    warn("SW: \"$text\" ", $fdesc->to_string, " $size\n");
    $layout->set_font_description($fdesc);
    $layout->set_markup( $text );
    return $layout->get_baseline / 1024;
}

sub line {
    my ( $self, $x0, $y0, $x1, $y1, $lw, $color ) = @_;
    my $cr = $self->{cr};
    $cr->save;
    $cr->setcolor($color || "black");
    $cr->set_line_cap('round');
    $cr->set_line_width($lw||1);
    $cr->move_to( $x0, $y0 );
    $cr->line_to( $x1, $y1 );
    $cr->stroke;
    $cr->restore;
}

sub hline {
    my ( $self, $x, $y, $w, $lw, $color ) = @_;
    my $cr = $self->{cr};
    $cr->save;
    $cr->setcolor($color || "black");
    $cr->set_line_cap('square');
    $cr->set_line_width($lw||1);
    $cr->move_to( $x, $y );
    $cr->line_to( $x + $w, $y );
    $cr->stroke;
    $cr->restore;
}

sub vline {
    my ( $self, $x, $y, $h, $lw, $color ) = @_;
    my $cr = $self->{cr};
    $cr->save;
    $cr->setcolor($color || "black");
    $cr->set_line_cap('square');
    $cr->set_line_width($lw||1);
    $cr->move_to( $x, $y );
    $cr->line_to( $x, $y + $h );
    $cr->stroke;
    $cr->restore;
}

sub rectwh {
    my ( $self, $x, $y, $w, $h, $lw, $fillcolor, $strokecolor ) = @_;
    my $cr = $self->{cr};
    $cr->save;
    $cr->set_line_cap('square');
    $cr->set_line_width($lw||1);
    $cr->rectangle( $x, $y, $w, $h );
    if ( $fillcolor ) {
	$cr->setcolor($fillcolor);
	$strokecolor ? $cr->fill_preserve : $cr->fill;
    }
    if ( $strokecolor ) {
	$cr->setcolor($strokecolor);
	$cr->stroke;
    }
    $cr->restore;
}

sub rectxy {
    my ( $self, $x, $y, $x1, $y1, $lw, $fillcolor, $strokecolor ) = @_;
    $self->rectwh( $x, $y, $x1-$x, $y1-$y, $lw, $fillcolor, $strokecolor );
}

sub circle {
    my ( $self, $x, $y, $r, $lw, $fillcolor, $strokecolor ) = @_;
    my $cr = $self->{cr};
    $cr->save;
    $cr->set_line_width($lw||1);
    $cr->arc( $x, $y, $r, 0, $TWOPI );
    if ( $fillcolor ) {
	$cr->setcolor($fillcolor);
	$strokecolor ? $cr->fill_preserve : $cr->fill;
    }
    if ( $strokecolor ) {
	$cr->setcolor($strokecolor);
	$cr->stroke;
    }
    $cr->restore;
}

sub dot {
    my ( $self, $x, $y, $w, $lw, $digit ) = @_;
    $w *= 0.8;
    my $cr = $self->{cr};
    my $ly = $self->{layout};
    $cr->save;
    #$cr->setcolor("red");
    #$self->hline( $x-20, $y, 40, 0.25, "red" );
    #$self->vline( $x, $y-20, 40, 0.25, "red" );
    $cr->set_line_width($lw||1);
    $cr->arc( $x, $y, $w/2, 0, $TWOPI );
    $cr->setcolor("black");
    $cr->fill_preserve;
    $cr->stroke;
    if ( $digit && $digit ne "" ) {
	my $fdesc = $self->{ps}->{fonts}->{chordfingers}->{font};
	# Pixel units are integer, so scale a bit to get precision.
	$fdesc->set_size(1024*$w/0.9*1024/1.33);
	$ly->set_font_description($fdesc);
	$ly->set_markup("<span color='white'>$digit</span>");
	my $e = ($ly->get_pixel_extents)[0];
	$e->{$_} /= 1024 for keys %$e;
	$cr->translate( $x - ( $e->{width} /2 + $e->{x} ),
			$y - ( $e->{height}/2 + $e->{y} ) );
	$cr->scale( 1/1024, 1/1024 );
	Pango::Cairo::show_layout( $cr, $ly );
    }
    $cr->restore;
}

sub cross {
    my ( $self, $x, $y, $r, $lw, $strokecolor ) = @_;
    my $cr = $self->{cr};
    $cr->save;
    $cr->setcolor($strokecolor) if $strokecolor;
    $cr->set_line_width($lw||1);
    $r = 0.9 * $r;
    $cr->move_to( $x-$r, $y+$r );
    $cr->line_to( $x+$r, $y-$r );
    $cr->move_to( $x-$r, $y-$r );
    $cr->line_to( $x+$r, $y+$r );
    $cr->stroke;
    $cr->restore;
}

my %colours =
  ( black    => [ 0, 0, 0, 1 ],
    white    => [ 1, 1, 1, 1 ],
    red	     => [ 1, 0, 0, 1 ],
    green    => [ 0, 1, 0, 1 ],
    blue     => [ 0, 0, 1, 1 ],
    yellow   => [ 1, 1, 0, 1 ],
    magenta  => [ 1, 0, 1, 1 ],
    cyan     => [ 0, 1, 1, 1 ],
  );

sub Cairo::Context::setcolor {
    my ( $cr, $color ) = @_;

    my $rgba;
    if ( defined( $rgba = $colours{$color} ) ) {
    }
    elsif ( $color =~ /^\#?([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])?$/i ) {
	$rgba = [ map { hex($_)/255 } $1, $2, $3, $4//"ff" ];
    }

    unless ( $rgba ) {
	warn("Unhandled colour: $color, using cyan instead\n");
	$rgba = $colours{"cyan"};
    }
    $cr->set_source_rgba( @$rgba );
}

sub get_image {
    my ( $self, $uri ) = @_;
    return;			# TODO

    my $img;
    if ( $uri =~ /^id=(.+)/ ) {
	my $a = $App::Music::ChordPro::Output::PDF::assets->{$1};
	my $d = $a->{data};
	my $fh = IO::String->new($d);
	if ( $a->{type} eq "jpg" ) {
	    $img = $self->{pdf}->image_jpeg($fh);
	}
	elsif ( $a->{type} eq "png" ) {
	    $img = $self->{pdf}->image_png($fh);
	}
	elsif ( $a->{type} eq "gif" ) {
	    $img = $self->{pdf}->image_gif($fh);
	}
	return $img;
    }
    for ( $uri ) {
	$img = $self->{pdf}->image_png($_)  if /\.png$/i;
	$img = $self->{pdf}->image_jpeg($_) if /\.jpe?g$/i;
	$img = $self->{pdf}->image_gif($_)  if /\.gif$/i;
    }
    return $img;
}

sub add_image {
    my ( $self, $img, $x, $y, $w, $h, $border ) = @_;
    return;	# TODO

    my $gfx = $self->{pdfgfx};

    $gfx->save;
    $gfx->image( $img, $x, $y+$h, $w, $h );
    if ( $border ) {
	$gfx->rect( $x, $y+$h, $w, $h )
	  ->linewidth($border)
	    ->stroke;
    }
    $gfx->restore;
}

sub newpage {
    my ( $self, $ps, $page ) = @_;
    $self->{cr}->show_page if $self->{_pages}++;
    $self->link_set( $self->{_pages} );
    $self->link_end;
    $self;
}

sub finish {
    my ( $self ) = @_;
    $self->{cr}->show_page;
    return;
    
#    if ( $file && $file ne "-" ) {
#	$self->{pdf}->saveas($file);
#    }
#    else {
#	binmode(STDOUT);
#	print STDOUT ( $self->{pdf}->stringify );
#	close(STDOUT);
#    }
}

sub init_fonts {
    my ( $self ) = @_;
    my $ps = $self->{ps};
    my $fail;

    foreach my $ff ( keys( %{ $ps->{fonts} } ) ) {
	next unless $ps->{fonts}->{$ff}->{description}
	  || $ps->{fonts}->{$ff}->{pango};
	$self->init_font($ff) or $fail++;
    }
    die("Unhandled fonts detected -- aborted\n") if $fail;
}

sub init_font {
    my ( $self, $ff ) = @_;

    my $ps = $self->{ps};

    my $font = $ps->{fonts}->{$ff};
    my $pango = $font->{description} || $font->{pango};
    warn("No pango for font $ff?\n") unless $pango;
    if ( $pango !~ /\s+(\d+)$/ && $font->{size} ) {
	$pango .= " " . $font->{size};
    }
    $font->{font} = Pango::FontDescription->from_string($pango);
    # warn("Load font: ", $font->{font}->to_string, "\n");
    $font->{font};
}

sub show_vpos {
    my ( $self, $y, $w ) = @_;
    for ( $self->{cr} ) {
	$_->save;
	$_->move_to(100*$w,$y);
	$_->set_line_width(0.25);
	$_->line_to(100*$w+100*(1+$w), $y);
	$_->setcolor("blue");
	$_->stroke;
	$_->restore;
    }
}

# Hyperlinks (for Table of Contents).
# This requires a modified version of Cairo 1.106 (hopefully 1.107).
# For unmodified 1.106, the TOC is ok but no links.

my $_tag;

sub link_set {
    my ( $self, $page ) = @_;
    return unless $self->{cr}->can("tag_begin");
    $self->{cr}->tag_begin( $_tag = "cairo.dest", "name='page$page'" );
}

sub link_jump {
    my ( $self, $page ) = @_;
    return unless $self->{cr}->can("tag_begin");
    $self->{cr}->tag_begin( $_tag = "Link", "dest='page$page'" );
}

sub link_end {
    my ( $self ) = @_;
    return unless $self->{cr}->can("tag_end");
    $self->{cr}->tag_end( $_tag );
}

1;
