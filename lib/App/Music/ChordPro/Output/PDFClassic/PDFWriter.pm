#! perl

package App::Music::ChordPro::Output::PDFClassic::PDFWriter;

my $pdfapi;
BEGIN {
    eval { require PDF::Builder; $pdfapi = "PDF::Builder"; }
      or
    eval { require PDF::API2; $pdfapi = "PDF::API2"; }
      or
    die("Missing PDF::API package\n");
}

# For regression testing, run perl with PERL_HASH_SEED set to zero.
# This eliminates the arbitrary order of font definitions and triggers
# us to pinpoint some other data that would otherwise be varying.
my $regtest = defined($ENV{PERL_HASH_SEED}) && $ENV{PERL_HASH_SEED} == 0;

use strict;
use warnings;
use Encode;
use IO::String;

my $faketime = 1465041600;

my %fontcache;			# speeds up 2 seconds per song

sub new {
    my ( $pkg, $ps ) = @_;
    my $self = bless { ps => $ps }, $pkg;
    $self->{pdf} = $pdfapi->new;
    $self->{pdf}->{forcecompress} = 0 if $regtest;
    $self->{pdf}->mediabox( $ps->{papersize}->[0],
			    $ps->{papersize}->[1] );
    %fontcache = () if $::__EMBEDDED__;
    $self;
}

sub info {
    my ( $self, %info ) = @_;
    unless ( $info{CreationDate} ) {
	my @tm = gmtime( $regtest ? $faketime : time );
	$info{CreationDate} =
	  sprintf("D:%04d%02d%02d%02d%02d%02d+00'00'",
		  1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]);
    }
    $self->{pdf}->info( %info );
}


sub wrap {
    my ( $self, $text, $m ) = @_;

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
    my ( $self, $text, $x, $y, $font, $size ) = @_;
    return $x unless length($text);

    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->setfont($font, $size);

    # Handle decorations (background, box).
    my $bgcol = $font->{background};
    my $frame = $font->{frame};
    if ( $bgcol || $frame ) {
	my $w = $self->strwidth( $text );
	my $vsp = $size * 1.1;
	# Adjust for baseline.
	my $y = $y + ( $size / ( 1 - $font->{font}->descender / $font->{font}->ascender ) );

	# Draw background.
	if ( $bgcol && $bgcol !~ /^no(?:ne)?$/i ) {
	    $self->rectxy( $x - 2, $y + 2,
			   $x + $w + 2, $y - $vsp, 3, $bgcol );
	}

	# Draw box.
	if ( $frame && $frame !~ /^no(?:ne)?$/i ) {
	    my $x0 = $x;
	    $x0 -= 0.25;	# add some offset for the box
	    $self->rectxy( $x0, $y + 1,
			   $x0 + $w + 1, $y - $vsp + 1,
			   0.5, undef,
			   $font->{color} || "black" );
	}
    }

    if ( $font->{color} ) {
	$self->{pdftext}->strokecolor( $font->{color} );
	$self->{pdftext}->fillcolor( $font->{color} );
    }
    else {
	$self->{pdftext}->strokecolor("black");
	$self->{pdftext}->fillcolor("black");
    }
    $self->{pdftext}->translate( $x, $y );
    $x += $self->{pdftext}->text($text);
    if ( $font->{color} ) {
	$self->{pdftext}->strokecolor("black");
	$self->{pdftext}->fillcolor("black");
    }
    return $x;
}

sub setfont {
    my ( $self, $font, $size ) = @_;
    $self->{font} = $font;
    $self->{fontsize} = $size ||= $font->{size};
    $self->{pdftext}->font( $font->{font}, $size );
}

sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
    $self->setfont( $font, $size );
    $self->{pdftext}->advancewidth($text);
}

sub line {
    my ( $self, $x0, $y0, $x1, $y1, $lw, $color ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($color ||= "black");
    $gfx->linecap(1);
    $gfx->linewidth($lw||1);
    $gfx->move( $x0, $y0 );
    $gfx->line( $x1, $y1 );
    $gfx->stroke;
    $gfx->restore;
}

sub hline {
    my ( $self, $x, $y, $w, $lw, $color ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($color ||= "black");
    $gfx->linecap(2);
    $gfx->linewidth($lw||1);
    $gfx->move( $x, $y );
    $gfx->hline( $x + $w );
    $gfx->stroke;
    $gfx->restore;
}

sub vline {
    my ( $self, $x, $y, $h, $lw, $color ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($color ||= "black");
    $gfx->linecap(2);
    $gfx->linewidth($lw||1);
    $gfx->move( $x, $y );
    $gfx->vline( $y - $h );
    $gfx->stroke;
    $gfx->restore;
}

sub rectxy {
    my ( $self, $x, $y, $x1, $y1, $lw, $fillcolor, $strokecolor ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($strokecolor) if $strokecolor;
    $gfx->fillcolor($fillcolor) if $fillcolor;
    $gfx->linecap(2);
    $gfx->linewidth($lw||1);
    $gfx->rectxy( $x, $y, $x1, $y1 );
    $gfx->close;
    $gfx->fill if $fillcolor;
    $gfx->stroke if $strokecolor;
    $gfx->restore;
}

sub circle {
    my ( $self, $x, $y, $r, $lw, $fillcolor, $strokecolor ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($strokecolor) if $strokecolor;
    $gfx->fillcolor($fillcolor) if $fillcolor;
    $gfx->linewidth($lw||1);
    $gfx->circle( $x, $y, $r );
    $gfx->fill if $fillcolor;
    $gfx->stroke if $strokecolor;
    $gfx->restore;
}

sub cross {
    my ( $self, $x, $y, $r, $lw, $strokecolor ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($strokecolor) if $strokecolor;
    $gfx->linewidth($lw||1);
    $r = 0.9 * $r;
    $gfx->move( $x-$r, $y-$r );
    $gfx->line( $x+$r, $y+$r );
    $gfx->stroke if $strokecolor;
    $gfx->move( $x-$r, $y+$r );
    $gfx->line( $x+$r, $y-$r );
    $gfx->stroke if $strokecolor;
    $gfx->restore;
}

sub get_image {
    my ( $self, $uri ) = @_;

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

    my $gfx = $self->{pdfgfx};

    $gfx->save;
    $gfx->image( $img, $x, $y-$h, $w, $h );
    if ( $border ) {
	$gfx->rect( $x, $y-$h, $w, $h )
	  ->linewidth($border)
	    ->stroke;
    }
    $gfx->restore;
}

sub newpage {
    my ( $self, $ps, $page ) = @_;
    #$self->{pdftext}->textend if $self->{pdftext};
    $self->{pdfpage} = $self->{pdf}->page($page);
    $self->{pdfpage}->mediabox( $ps->{papersize}->[0],
				$ps->{papersize}->[1] );
    $self->{pdfgfx}  = $self->{pdfpage}->gfx;
    $self->{pdftext} = $self->{pdfpage}->text;
}

sub finish {
    my ( $self, $file ) = @_;

    if ( $file && $file ne "-" ) {
	$self->{pdf}->saveas($file);
    }
    else {
	binmode(STDOUT);
	print STDOUT ( $self->{pdf}->stringify );
	close(STDOUT);
    }
}

sub init_fonts {
    my ( $self ) = @_;
    my $ps = $self->{ps};
    my $fail;

    foreach my $ff ( keys( %{ $ps->{fonts} } ) ) {
	next unless $ps->{fonts}->{$ff}->{name} || $ps->{fonts}->{$ff}->{file};
	$self->init_font($ff) or $fail++;
    }
    die("Unhandled fonts detected -- aborted\n") if $fail;
}

sub init_font {
    my ( $self, $ff ) = @_;
    my $ps = $self->{ps};

    my $font = $ps->{fonts}->{$ff};
    if ( $font->{file} ) {
	if ( $font->{file} =~ /\.[ot]tf$/ ) {
	    eval {
		$font->{font} =
		  $fontcache{$font->{file}} ||=
		    $self->{pdf}->ttfont( $font->{file},
					  -dokern => 1 );
	    }
	    or warn("Cannot load font: ", $font->{file}, "\n");
	}
	elsif ( $font->{file} =~ /\.pf[ab]$/ ) {
	    eval {
		$font->{font} =
		  $fontcache{$font->{file}} ||=
		    $self->{pdf}->psfont( $font->{file},
					  -afmfile => $font->{metrics},
					  -dokern  => 1 );
	    }
	    or warn("Cannot load font: ", $font->{file}, "\n");
	}
	else {
	    $font->{font} =
	      $fontcache{"__default__"} ||=
	      $self->{pdf}->corefont( 'Courier' );
	}
    }
    else {
	eval {
	    $font->{font} =
	      $fontcache{"__core__".$font->{name}} ||=
		$self->{pdf}->corefont( $font->{name}, -dokern => 1 );
	}
	or warn("Cannot load font: ", $font->{file}, "\n");
    }

    unless ( $font->{font} ) {
	warn( "Unhandled $ff font: ",
	      $font->{file}
	      || $font->{name}
	      || Dumper($font), "\n" );
    }
    $font->{font}->{Name}->{val} =~ s/~.*/~$faketime/ if $regtest;
    $font->{font};
}

sub show_vpos {
    my ( $self, $y, $w ) = @_;
    $self->{pdfgfx}->move(100*$w,$y)->linewidth(0.25)->hline(100*(1+$w))->stroke;
}

1;
