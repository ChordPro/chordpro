#! perl

package main;

our $config;

package App::Music::ChordPro::Output::PDF::Writer;

use strict;
use warnings;
use Encode;
use PDF::API2;
use Text::Layout;
use IO::String;
use Carp;

use App::Music::ChordPro::Utils qw( expand_tilde );
use App::Music::ChordPro::Output::Common qw( fmt_subst prep_outlines demarkup );

# For regression testing, run perl with PERL_HASH_SEED set to zero.
# This eliminates the arbitrary order of font definitions and triggers
# us to pinpoint some other data that would otherwise be varying.
my $regtest = defined($ENV{PERL_HASH_SEED}) && $ENV{PERL_HASH_SEED} == 0;
my $faketime = 1465041600;

my %fontcache;			# speeds up 2 seconds per song

sub new {
    my ( $pkg, $ps, $pdfapi ) = @_;
    my $self = bless { ps => $ps }, $pkg;
    $self->{pdfapi} = $pdfapi;
    $self->{pdf} = $pdfapi->new;
    $self->{pdf}->{forcecompress} = 0 if $regtest;
    $self->{pdf}->mediabox( $ps->{papersize}->[0],
			    $ps->{papersize}->[1] );
    $self->{layout} = Text::Layout->new( $self->{pdf} );
    $self->{tmplayout} = undef;

    %fontcache = ();

    $self;
}

sub info {
    my ( $self, %info ) = @_;
    unless ( $info{CreationDate} ) {
	my @tm = gmtime( $regtest ? $faketime : time );
	$info{CreationDate} =
	  sprintf("D:%04d%02d%02d%02d%02d%02d+01'00",
		  1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]);
    }
    if ( $self->{pdf}->can("info_metadata") ) {
	for ( keys(%info) ) {
	    $self->{pdf}->info_metadata( $_, $info{$_} );
	}
    }
    else {
	$self->{pdf}->info(%info);
    }
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

sub _fgcolor {
    my ( $self, $col ) = @_;
    if ( !defined($col) || $col =~ /^foreground(?:-medium|-light)?$/ ) {
	$col = $self->{ps}->{theme}->{$col//"foreground"};
    }
    elsif ( $col eq "background" ) {
	$col = $self->{ps}->{theme}->{background};
    }
    elsif ( !$col ) {
	Carp::confess("Undefined fgcolor: $col");
    }
    $col;
}

sub _bgcolor {
    my ( $self, $col ) = @_;
    if ( !defined($col) || $col eq "background" ) {
	$col = $self->{ps}->{theme}->{background};
    }
    elsif ( $col =~ /^foreground(?:-medium|-light)?$/ ) {
	$col = $self->{ps}->{theme}->{$col};
    }
    elsif ( !$col ) {
	Carp::confess("Undefined bgcolor: $col");
    }
    $col;
}

sub _yflip {
    #warn("Text::Layout = $Text::Layout::VERSION\n" );
    $Text::Layout::VERSION gt "0.027";
}

my $yflip;

sub text {
    my ( $self, $text, $x, $y, $font, $size, $nomarkup ) = @_;
#    print STDERR ("T: @_\n");
    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->{layout}->set_font_description($font->{fd});
    $self->{layout}->set_font_size($size);
    # We don't have set_color in the API.
    $self->{layout}->{_currentcolor} = $self->_fgcolor($font->{color});
    # Watch out for regression... May have to do this in the nomarkup case only.
    if ( $nomarkup ) {
	$self->{layout}->set_text($text);
    }
    else {
	$self->{layout}->set_markup($text);
    }
    $y -= $self->{layout}->get_baseline;
    $self->{layout}->show( $x, $y, $self->{pdftext} );

    my $e = $self->{layout}->get_pixel_extents;
    if ( ref($e) eq 'ARRAY' ) { # Text::Layout <= 0.026
	$e = $e->[1];
    }
    elsif ( $yflip //= _yflip() ) {
	$e->{y} += $e->{height};
    }

    # Handle decorations (background, box).
    my $bgcol = $self->_bgcolor($font->{background});
    undef $bgcol if $bgcol && $bgcol =~ /^no(?:ne)?$/i;
    my $debug = $ENV{CHORDPRO_DEBUG_TEXT} ? "magenta" : undef;
    my $frame = $font->{frame} || $debug;
    undef $frame if $frame && $frame =~ /^no(?:ne)?$/i;
    if ( $bgcol || $frame ) {
	printf("BB: %.2f %.2f %.2f %.2f\n", @{$e}{qw( x y width height ) } )
	  if $debug;
	# Draw background and.or frame.
	my $d = $debug ? 0 : 1;
	$frame = $debug || $font->{color} || $self->{ps}->{theme}->{foreground} if $frame;
	# $self->crosshair( $x, $y, 20, 0.2, "magenta" );
	$self->rectxy( $x + $e->{x} - $d,
		       $y + $e->{y} + $d,
		       $x + $e->{x} + $e->{width} + $d,
		       $y + $e->{y} - $e->{height} - $d,
		       0.5, $bgcol, $frame);
    }

    $x += $e->{width};
#    print STDERR ("TX: $x\n");
    return $x;
}

sub setfont {
    my ( $self, $font, $size ) = @_;
    $self->{font} = $font;
    warn("PDF: Font ", $font->{_ff}, " should have a size!\n")
      unless $size ||= $font->{size};
    $self->{fontsize} = $size ||= $font->{size} || $font->{fd}->{size};
    $self->{pdftext}->font( $font->{fd}->{font}, $size );
}

sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
    $self->{tmplayout} //= Text::Layout->new( $self->{pdf} );
    $self->{tmplayout}->set_font_description($font->{fd});
    $self->{tmplayout}->set_font_size($size);
    $self->{tmplayout}->set_markup($text);
    $self->{tmplayout}->get_pixel_size->{width};
}

sub strheight {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
    $self->{tmplayout} //= Text::Layout->new( $self->{pdf} );
    $self->{tmplayout}->set_font_description($font->{fd});
    $self->{tmplayout}->set_font_size($size);
    $self->{tmplayout}->set_markup($text);
    $self->{tmplayout}->get_pixel_size->{height};
}

sub line {
    my ( $self, $x0, $y0, $x1, $y1, $lw, $color ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor( $self->_fgcolor($color) );
    $gfx->linecap(1);
    $gfx->linewidth($lw||1);
    $gfx->move( $x0, $y0 );
    $gfx->line( $x1, $y1 );
    $gfx->stroke;
    $gfx->restore;
}

sub hline {
    my ( $self, $x, $y, $w, $lw, $color, $cap ) = @_;
    $cap //= 2;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor( $self->_fgcolor($color) );
    $gfx->linecap($cap);
    $gfx->linewidth($lw||1);
    $gfx->move( $x, $y );
    $gfx->hline( $x + $w );
    $gfx->stroke;
    $gfx->restore;
}

sub vline {
    my ( $self, $x, $y, $h, $lw, $color, $cap ) = @_;
    $cap //= 2;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor( $self->_fgcolor($color) );
    $gfx->linecap($cap);
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
    $gfx->strokecolor($self->_fgcolor($strokecolor)) if $strokecolor;
    $gfx->fillcolor($self->_fgcolor($fillcolor)) if $fillcolor;
    $gfx->linecap(2);
    $gfx->linewidth($lw||1);
    $gfx->rectxy( $x, $y, $x1, $y1 );
    $gfx->fill if $fillcolor && !$strokecolor;
    $gfx->fillstroke if $fillcolor && $strokecolor;
    $gfx->stroke if $strokecolor && !$fillcolor;
    $gfx->restore;
}

sub poly {
    my ( $self, $points, $lw, $fillcolor, $strokecolor ) = @_;
    undef $strokecolor unless $lw;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($self->_fgcolor($strokecolor)) if $strokecolor;
    $gfx->fillcolor($self->_fgcolor($fillcolor)) if $fillcolor;
    $gfx->linecap(2);
    $gfx->linewidth($lw);
    $gfx->poly( @$points );
    $gfx->close;
    $gfx->fill if $fillcolor && !$strokecolor;
    $gfx->fillstroke if $fillcolor && $strokecolor;
    $gfx->stroke if $strokecolor && !$fillcolor;
    $gfx->restore;
}

sub circle {
    my ( $self, $x, $y, $r, $lw, $fillcolor, $strokecolor ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($self->_fgcolor($strokecolor)) if $strokecolor;
    $gfx->fillcolor($self->_fgcolor($fillcolor)) if $fillcolor;
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
    $gfx->strokecolor($self->_fgcolor($strokecolor)) if $strokecolor;
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

sub crosshair {			# for debugging
    my ( $self, $x, $y, $r, $lw, $strokecolor ) = @_;
    my $gfx = $self->{pdfgfx};
    $gfx->save;
    $gfx->strokecolor($self->_fgcolor($strokecolor)) if $strokecolor;
    $gfx->linewidth($lw||1);
    $gfx->move( $x, $y - $r );
    $gfx->line( $x, $y + $r );
    $gfx->stroke if $strokecolor;
    $gfx->move( $x - $r, $y );
    $gfx->line( $x + $r, $y );
    $gfx->stroke if $strokecolor;
    $gfx->restore;
}

sub get_image {
    my ( $self, $elt ) = @_;

    my $img;
    my $uri = $elt->{uri};
    warn("get_image($uri)\n") if $config->{debug}->{images};
    if ( $uri =~ /^id=(.+)/ ) {
	my $a = $App::Music::ChordPro::Output::PDF::assets->{$1};

	if ( $a->{type} eq "abc" ) {
	    my $res = App::Music::ChordPro::Output::PDF::abc2image( undef, $self, $a );
	    return $self->get_image( { %$elt, uri => $res->{src} } );
	}
	elsif ( $a->{type} eq "jpg" ) {
	    $img = $self->{pdf}->image_jpeg(IO::String->new($a->{data}));
	}
	elsif ( $a->{type} eq "png" ) {
	    $img = $self->{pdf}->image_png(IO::String->new($a->{data}));
	}
	elsif ( $a->{type} eq "gif" ) {
	    $img = $self->{pdf}->image_gif(IO::String->new($a->{data}));
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
    unless ($ps->{theme}->{background} =~ /^white|none|#ffffff$/i ) {
	for ( $self->{pdfgfx} ) {
	    $_->save;
	    $_->fillcolor( $ps->{theme}->{background} );
	    $_->linewidth(0);
	    $_->rectxy( 0, 0, $ps->{papersize}->[0],
			$ps->{papersize}->[1] );
	    $_->fill;
	    $_->restore;
	}
    }
}

sub openpage {
    my ( $self, $ps, $page ) = @_;
    $self->{pdfpage} = $self->{pdf}->openpage($page);
    $self->{pdfgfx}  = $self->{pdfpage}->gfx;
    $self->{pdftext} = $self->{pdfpage}->text;
}

sub importpage {
    my ( $self, $fn, $pg ) = @_;
    my $bg = $self->{pdfapi}->open($fn);
    return unless $bg;		# should have been checked
    $pg = $bg->pages if $pg > $bg->pages;
    $self->{pdf}->import_page( $bg, $pg, $self->{pdfpage} );
    # Make sure the contents get on top of it.
    $self->{pdfgfx}  = $self->{pdfpage}->gfx;
    $self->{pdftext} = $self->{pdfpage}->text;
}

sub pagelabel {
    my ( $self, $page, $style, $prefix ) = @_;
    $style //= 'arabic';

    # PDF::API2 2.042 has some incompatible changes...
    my $c = $self->{pdf}->can("page_labels");
    if ( $c ) {			# 2.042+
	my $opts = { style => $style eq 'Roman' ? 'R' :
		              $style eq 'roman' ? 'r' :
                              $style eq 'Alpha' ? 'A' :
                              $style eq 'alpha' ? 'a' : 'D',
		     defined $prefix ? ( prefix => $prefix ) : (),
		     start => 1 };
	$c->( $self->{pdf}, $page, $opts );
    }
    else {
	my $opts = { -style => $style,
		     defined $prefix ? ( -prefix => $prefix ) : (),
		     -start => 1 };
	$self->{pdf}->pageLabel( $page, $opts );
    }
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
	next unless @$book;

	# Seems not to matter whether we re-use the root or create new.
	$ol_root //= $pdf->outlines;

	my $outline;

	# Skip level for a single outline.
	if ( @{ $self->{ps}->{outlines} } == 1 ) {
	    $outline = $ol_root;
	    $outline->closed if $ctl->{collapse}; # TODO?
	}
	else {
	    $outline = $ol_root->outline;
	    $outline->title( $ctl->{label} );
	    $outline->closed if $ctl->{collapse};
	}

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
		$ol->title( demarkup( fmt_subst( $song, $ctl->{line} ) ) );
		if ( my $c = $ol->can("destination") ) {
		    $c->( $ol, $pdf->openpage( $song->{meta}->{tocpage} + $start ) );
		}
		else {
		    $ol->dest($pdf->openpage( $song->{meta}->{tocpage} + $start ));
		}
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

    # Add font dirs.
    my @d = ( @{$ps->{fontdir}}, ::rsc_or_file("fonts/"), $ENV{FONTDIR} );
    # Avoid rsc result if dummy.
    splice( @d, -2, 1 ) if $d[-2] eq "fonts/";
    for my $fontdir ( @d ) {
	next unless $fontdir;
	$fontdir = expand_tilde($fontdir);
	if ( -d $fontdir ) {
	    $self->{pdfapi}->can("addFontDirs")->($fontdir);
	    $fc->add_fontdirs($fontdir);
	}
	else {
	    warn("PDF: Ignoring fontdir $fontdir [$!]\n");
	    undef $fontdir;
	}
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
    if ( $ps->{fonts}->{$ff}->{file} ) {
	$fd = $self->init_filefont($ff);
    }
    elsif ( $ps->{fonts}->{$ff}->{description} ) {
	$fd = $self->init_pangofont($ff);
    }
    elsif ( $ps->{fonts}->{$ff}->{name} ) {
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
	$font->{size} = $font->{fd}->get_size if $font->{fd}->get_size;
    };
    $font->{fd};
}

sub init_filefont {
    my ( $self, $ff ) = @_;

    my $ps = $self->{ps};
    my $font = $ps->{fonts}->{$ff};

    my $fc = Text::Layout::FontConfig->new;
    eval {
	my $t = $fc->from_filename(expand_tilde($font->{file}));
	$t->get_font($self->{layout}); # force load
	$t->{font}->{Name}->{val} =~ s/~.*/~$faketime/ if $regtest;
	$t->{_ff} = $ff;
	$font->{fd} = $t;
    };
    $font->{fd};
}

sub init_corefont {
    my ( $self, $ff ) = @_;

    my $ps = $self->{ps};
    my $font = $ps->{fonts}->{$ff};
    die("Config error: \"$font->{name}\" is not a built-in font\n")
      unless App::Music::ChordPro::Output::PDF::is_corefont($font->{name});
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
my $rname;
sub embed {
    my ( $self, $file ) = @_;
    return unless -f $file;
    my $a = $self->{pdfpage}->annotation();

    # The only reliable way currently is pretend it's a movie :) .
    $a->movie($file, "ChordPro" );
    $a->open(1);

    # Create/reuse temp file for (final) config and run time info.
    my $cf;
    if ( $cname ) {
	open( $cf, '>', $cname );
    }
    else {
	( $cf, $cname ) = File::Temp::tempfile( UNLINK => 0);
    }
    binmode( $cf, ':utf8' );
    print $cf App::Music::ChordPro::Config::config_final();
    close($cf);

    $a = $self->{pdfpage}->annotation();
    $a->movie($cname, "ChordProConfig" );
    $a->open(0);

    my $rf;
    if ( $rname ) {
	open( $rf, '>', $rname );
    }
    else {
	( $rf, $rname ) = File::Temp::tempfile( UNLINK => 0);
    }
    binmode( $rf, ':utf8' );
    open( $rf, '>', $rname );
    binmode( $rf, ':utf8' );
    print $rf (::runtimeinfo());
    close($rf);

    $a = $self->{pdfpage}->annotation();
    $a->movie($rname, "ChordProRunTime" );
    $a->open(0);
}

END {
    return unless $cname;
    unlink($cname);
    undef $cname;
    unlink($rname);
    undef $rname;
}

1;
