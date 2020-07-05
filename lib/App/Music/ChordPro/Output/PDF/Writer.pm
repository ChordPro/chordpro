#! perl

package App::Music::ChordPro::Output::PDF::Writer;

use strict;
use warnings;
use Encode;
use PDF::API2;
use Text::Layout;
use IO::String;

# For regression testing, run perl with PERL_HASH_SEED set to zero.
# This eliminates the arbitrary order of font definitions and triggers
# us to pinpoint some other data that would otherwise be varying.
my $regtest = defined($ENV{PERL_HASH_SEED}) && $ENV{PERL_HASH_SEED} == 0;
my $faketime = 1465041600;

my %fontcache;			# speeds up 2 seconds per song

sub new {
    my ( $pkg, $ps, $pdfapi ) = @_;
    my $self = bless { ps => $ps }, $pkg;
    $self->{pdf} = $pdfapi->new;
    $self->{pdf}->{forcecompress} = 0 if $regtest;
    $self->{pdf}->mediabox( $ps->{papersize}->[0],
			    $ps->{papersize}->[1] );
    $self->{layout} = Text::Layout->new( $self->{pdf} );
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
#    print STDERR ("T: @_\n");
    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->{layout}->set_font_description($font->{fd});
    $self->{layout}->set_font_size($size);
    if ( $font->{color} && $font->{color} ne "black" ) {
	$text = "<span color='" . $font->{color} . "'>" . $text . "</span>";
    }
    $self->{layout}->set_markup($text);
    $y -= $self->{layout}->get_baseline;
    $self->{layout}->show( $x, $y, $self->{pdftext} );

    my $e = ($self->{layout}->get_pixel_extents)[1];

    # Handle decorations (background, box).
    my $bgcol = $font->{background};
    undef $bgcol if $bgcol && $bgcol =~ /^no(?:ne)?$/i;
    my $debug = $ENV{CHORDPRO_DEBUG_TEXT} ? "magenta" : undef;
    my $frame = $font->{frame} || $debug;
    undef $frame if $frame && $frame =~ /^no(?:ne)?$/i;
    if ( $bgcol || $frame ) {
	#printf("BB: %.2f %.2f %.2f %.2f\n", @{$e}{qw( x y width height ) } );
	# Draw background and.or frame.
	my $d = $debug ? 0 : 1;
	$frame = $debug || $font->{color} || "black" if $frame;
	$self->rectxy( $x + $e->{x} - $d,
		       $y + $e->{y} + $d,
		       $x + $e->{x} + $e->{width} + $d,
		       $y - $e->{height} - $d,
		       0.5, $bgcol, $frame);
    }

    $x += $e->{width};
#    print STDERR ("TX: $x\n");
    return $x;
}

# Identical copy of text, but without baseline correction.
sub text_nobl {
    my ( $self, $text, $x, $y, $font, $size ) = @_;
#    print STDERR ("T: @_\n");
    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->{layout}->set_font_description($font->{fd});
    $self->{layout}->set_font_size($size);
    if ( $font->{color} && $font->{color} ne "black" ) {
	$text = "<span color='" . $font->{color} . "'>" . $text . "</span>";
    }
    $self->{layout}->set_markup($text);
    $self->{layout}->show( $x, $y, $self->{pdftext} );

    my $e = ($self->{layout}->get_pixel_extents)[1];

    # Handle decorations (background, box).
    my $bgcol = $font->{background};
    undef $bgcol if $bgcol && $bgcol =~ /^no(?:ne)?$/i;
    my $debug = "blue";
    my $frame = $font->{frame} || $debug;
    undef $frame if $frame && $frame =~ /^no(?:ne)?$/i;
    if ( $bgcol || $frame ) {
	#printf("BB: %.2f %.2f %.2f %.2f\n", @{$e}{qw( x y width height ) } );
	# Draw background and.or frame.
	my $d = $debug ? 0 : 1;
	$frame = $debug || $font->{color} || "black" if $frame;
	$self->rectxy( $x + $e->{x} - $d,
		       $y + $e->{y} + $d,
		       $x + $e->{x} + $e->{width} + $d,
		       $y - $e->{height} - $d,
		       0.5, $bgcol, $frame);
    }

    $x += $e->{width};
#    print STDERR ("TX: $x\n");
    return $x;
}

sub setfont {
    my ( $self, $font, $size ) = @_;
    $self->{font} = $font;
    $self->{fontsize} = $size ||= $font->{size};
    $self->{pdftext}->font( $font->{fd}->{font}, $size );
}

my $tmplayout;

sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
    $tmplayout //= Text::Layout->new( $self->{pdf} );
    $tmplayout->set_font_description($font->{fd});
    $tmplayout->set_font_size($size);
    $tmplayout->set_markup($text);
    $tmplayout->get_pixel_size->{width};
}

sub strheight {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
    $tmplayout //= Text::Layout->new( $self->{pdf} );
    $tmplayout->set_font_description($font->{fd});
    $tmplayout->set_font_size($size);
    $tmplayout->set_markup($text);
    $tmplayout->get_pixel_size->{height};
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
    $gfx->fill if $fillcolor && !$strokecolor;
    $gfx->fillstroke if $fillcolor && $strokecolor;
    $gfx->stroke if $strokecolor && !$fillcolor;
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
    $self->{pdfpage} = $self->{pdf}->page($page||0);
    $self->{pdfpage}->mediabox( $ps->{papersize}->[0],
				$ps->{papersize}->[1] );
    $self->{pdfgfx}  = $self->{pdfpage}->gfx;
    $self->{pdftext} = $self->{pdfpage}->text;
}

sub pagelabel {
    my ( $self, $page, $style, $prefix ) = @_;
    my $opts = { -style => $style // 'arabic',
		 defined $prefix ? ( -prefix => $prefix ) : (),
		 -start => 1 };
    $self->{pdf}->pageLabel( $page, $opts );
}

# Substitute %X sequences in title formats.
sub fmt_subst {
    goto \&App::Music::ChordPro::Output::Common::fmt_subst;
}

# Prepare outlines.
sub prep_outlines {
    goto \&App::Music::ChordPro::Output::Common::prep_outlines;
}

sub make_outlines {
    my ( $self, $book, $start ) = @_;
    return unless $book && @$book; # unlikely

    my $pdf = $self->{pdf};
    $start--;			# 1-relative
    my $ol_root;

    # Process outline defs from config.
    foreach my $ctl ( @{ $self->{ps}->{outlines} } ) {
	my $book = prep_outlines( $book, $ctl );

	# Seems not to matter whether we re-use the root or create new.
	$ol_root //= $pdf->outlines;

	my $outline = $ol_root->outline;
	$outline->title( $ctl->{label} );
	$outline->closed if $ctl->{collapse};

	my %lh;			# letter hierarchy
	for ( @$book ) {
	    # Group on first letter.
	    # That's why we left the sort fields in...
	    my $cur = uc(substr( $_->[0], 0, 1 ));
	    $lh{$cur} //= [];
	    # Last item is the song.
	    push( @{$lh{$cur}}, $_->[-1] );
	}

	# Need letter hierarchy?
	my $needlh = keys(%lh) >= $ctl->{letter};
	my $cur_ol;
	my $cur_let = "";

	foreach my $let ( sort keys %lh ) {
	    foreach my $song ( @{$lh{$let}} ) {
		my $ol;
		if ( $needlh ) {
		    unless ( defined $cur_ol && $cur_let eq $let ) {
			# Intermediate level autoline.
			$cur_ol = $outline->outline;
			$cur_ol->title($let);
			$cur_let = $let;
		    }
		    # Leaf outline.
		    $ol = $cur_ol->outline;
		}
		else {
		    # Leaf outline.
		    $ol = $outline->outline;
		}
		# Display info.
		$ol->title( fmt_subst( $song, $ctl->{line} ) );
		$ol->dest($pdf->openpage( $song->{meta}->{tocpage} + $start ));
	    }
	}
    }
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

    my $fc = Text::Layout::FontConfig->new;

    if ( $ps->{fontdir} ) {
	$fc->add_fontdirs( @{ $ps->{fontdir} } );
    }

    foreach my $ff ( keys( %{ $ps->{fontconfig} } ) ) {
	my @fam = split( /\s*,\s*/, $ff );
	foreach my $s ( keys( %{ $ps->{fontconfig}->{$ff} } ) ) {
	    my $v = $ps->{fontconfig}->{$ff}->{$s};
	    if ( UNIVERSAL::isa( $v, 'HASH' ) ) {
		my $file = delete( $v->{file} );
		$fc->register_font( $file, $fam[0], $s, $v );
	    }
	    else {
		$fc->register_font( $v, $fam[0], $s );
	    }
	}
	$fc->register_aliases(@fam) if @fam > 1;
    }

    foreach my $ff ( keys( %{ $ps->{fonts} } ) ) {
	$self->init_font($ff) or $fail++;
    }

    die("Unhandled fonts detected -- aborted\n") if $fail;
}

sub init_font {
    my ( $self, $ff ) = @_;
    my $ps = $self->{ps};
    my $fd;
    if ( !$fd && $ps->{fonts}->{$ff}->{file} ) {
	$fd = $self->init_filefont($ff);
    }
    if ( !$fd && $ps->{fonts}->{$ff}->{description} ) {
	$fd = $self->init_pangofont($ff);
    }
    if ( !$fd && $ps->{fonts}->{$ff}->{name} ) {
	$fd = $self->init_corefont($ff);
    }
    warn("No font found for \"$ff\"\n") unless $fd;
    $fd;
}

sub init_pangofont {
    my ( $self, $ff ) = @_;

    my $ps = $self->{ps};
    my $font = $ps->{fonts}->{$ff};

    my $fc = Text::Layout::FontConfig->new;
    eval {
	$font->{fd} = $fc->from_string($font->{description});
	$font->{fd}->get_font($self->{layout}); # force load
	$font->{fd}->{font}->{Name}->{val} =~ s/~.*/~$faketime/ if $regtest;
	$font->{_ff} = $ff;
	$font->{fd}->set_shaping( $font->{fd}->get_shaping || $font->{shaping}//0);
    };
    $font->{fd};
}

sub init_filefont {
    my ( $self, $ff ) = @_;

    my $ps = $self->{ps};
    my $font = $ps->{fonts}->{$ff};

    my $fc = Text::Layout::FontConfig->new;
    eval {
	$font->{fd} = $fc->from_filename($font->{file});
	$font->{fd}->get_font($self->{layout}); # force load
	$font->{fd}->{font}->{Name}->{val} =~ s/~.*/~$faketime/ if $regtest;
	$font->{_ff} = $ff;
    };
    $font->{fd};
}

sub init_corefont {
    my ( $self, $ff ) = @_;

    my $ps = $self->{ps};
    my $font = $ps->{fonts}->{$ff};

    my $fc = Text::Layout::FontConfig->new;
    eval {
	$font->{fd} = $fc->from_filename($font->{name});
	$font->{fd}->get_font($self->{layout}); # force load
	$font->{_ff} = $ff;
    };
    $font->{fd};
}

sub show_vpos {
    my ( $self, $y, $w ) = @_;
    $self->{pdfgfx}->move(100*$w,$y)->linewidth(0.25)->hline(100*(1+$w))->stroke;
}

use File::Temp;

my $cname;
sub embed {
    my ( $self, $file ) = @_;
    my $a = $self->{pdfpage}->annotation();

    # The only reliable way currently is pretend it's a movie :) .
    $a->movie($file, "ChordPro" );
    $a->open(1);

    # Create/reuse temp file for (final) config.
    my $cf;
    if ( $cname ) {
	open( $cf, '>:utf8', $cname );
    }
    else {
	( $cf, $cname ) = File::Temp::tempfile( UNLINK => 0);
    }

    my $pp = JSON::PP->new->canonical->indent(4)->pretty;
    print $cf $pp->encode( { %$::config } );
    close($cf);

    $a = $self->{pdfpage}->annotation();
    $a->movie($cname, "ChordProConfig" );
    $a->open(0);
}

END {
    return unless $cname;
    unlink($cname);
    undef $cname;
}

1;
