#! perl

package main;

our $config;

package ChordPro::Output::PDF::Writer;

use strict;
use warnings;
use Encode;
use Text::Layout;
use IO::String;
use Carp;
use utf8;

use ChordPro::Paths;
use ChordPro::Utils qw( expand_tilde demarkup min is_corefont );
use ChordPro::Output::Common qw( fmt_subst prep_outlines );
use File::LoadLines qw(loadlines);

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

    # Patches and enhancements to PDF library.
    no strict 'refs';
    *{$pdfapi . '::Resource::XObject::Form::width' } = \&_xo_width;
    *{$pdfapi . '::Resource::XObject::Form::height'} = \&_xo_height;
    if ( $pdfapi eq 'PDF::API2' ) {
	no warnings 'redefine';
	*{$pdfapi . '::_is_date'} = sub { 1 };
    }

    %fontcache = ();

    $self;
}

sub info {
    my ( $self, %info ) = @_;

    $info{CreationDate} //= pdf_date();

    if ( $self->{pdf}->can("info_metadata") ) {
	for ( keys(%info) ) {
	    $self->{pdf}->info_metadata( $_, demarkup($info{$_}) );
	}
	if ( $config->{debug}->{runtimeinfo} ) {
	    $self->{pdf}->info_metadata( "RuntimeInfo",
					 "Runtime Info:\n" . ::runtimeinfo() );
	}
    }
    else {
	$self->{pdf}->info(%info);
    }
}

# Return a PDF compliant date/time string.
sub pdf_date {
    my ( $t ) = @_;
    $t ||= $regtest ? $faketime : time;

    use POSIX qw( strftime );
    my $r = strftime( "%Y%m%d%H%M%S%z", localtime($t) );
    # Don't use s///r to keep PERL_MIN_VERSION low.
    $r =~ s/(..)$/'$1'/;	# +0100 -> +01'00'
    $r;
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

sub fix_musicsyms {
    my ( $text, $font ) = @_;

    for ( $text ) {
	if ( /♯/ ) {
	    unless ( $font->{has_sharp} //=
		     $font->{fd}->{font}->glyphByUni(ord("♯")) ne ".notdef" ) {
		s;♯;<span font="chordprosymbols">#</span>;g;
	    }
	}
	if ( /♭/ ) {
	    unless ( $font->{has_flat} //=
		     $font->{fd}->{font}->glyphByUni(ord("♭")) ne ".notdef" ) {
		s;♭;<span font="chordprosymbols">!</span>;g;
	    }
	}
    }
    return $text;
}

sub text {
    my ( $self, $text, $x, $y, $font, $size, $nomarkup ) = @_;
#    print STDERR ("T: @_\n");
    $font ||= $self->{font};
    $text = fix_musicsyms( $text, $font );
    $size ||= $font->{size};

    $self->{layout}->set_font_description($font->{fd});
    $self->{layout}->set_font_size($size);
    # We don't have set_color in the API.
    $self->{layout}->{_currentcolor} = $self->_fgcolor($font->{color});
    # Watch out for regression... May have to do this in the nomarkup case only.
    if ( $nomarkup ) {
	$text =~ s/'/\x{2019}/g;		# friendly quote
	$self->{layout}->set_text($text);
    }
    else {
	$self->{layout}->set_markup($text);
	for ( @{ $self->{layout}->{_content} } ) {
	    next unless $_->{type} eq "text";
	    $_->{text} =~ s/\'/\x{2019}/g;	# friendly quote
	}
    }
    $y -= $self->{layout}->get_baseline;
    $self->{layout}->show( $x, $y, $self->{pdftext} );

    my $e = $self->{layout}->get_pixel_extents;
    $e->{y} += $e->{height};

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
    $text = fix_musicsyms( $text, $font );
    $size ||= $self->{fontsize} || $font->{size};
    $self->{tmplayout} //= Text::Layout->new( $self->{pdf} );
    $self->{tmplayout}->set_font_description($font->{fd});
    $self->{tmplayout}->set_font_size($size);
    $self->{tmplayout}->set_markup($text);
    wantarray ? $self->{tmplayout}->get_pixel_size
      : $self->{tmplayout}->get_pixel_size->{width};
}

sub strheight {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $text = fix_musicsyms( $text, $font );
    $size ||= $self->{fontsize} || $font->{size};
    $self->{tmplayout} //= Text::Layout->new( $self->{pdf} );
    $self->{tmplayout}->set_font_description($font->{fd});
    $self->{tmplayout}->set_font_size($size);
    $self->{tmplayout}->set_markup($text);
    wantarray ? $self->{tmplayout}->get_pixel_size
      : $self->{tmplayout}->get_pixel_size->{height};
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
    $gfx->fill if $fillcolor && !$strokecolor;
    $gfx->fillstroke if $fillcolor && $strokecolor;
    $gfx->stroke if $strokecolor && !$fillcolor;
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

# Fetch an image or xform object.
# Source is $elt->{uri} (for files), $elt->{chord} (for chords).
# Result is delivered, and stored in $elt->{data};
sub get_image {
    my ( $self, $elt ) = @_;

    my $img;
    my $subtype = $elt->{subtype};
    my $data;

    if ( $subtype eq "delegate" ) {
	croak("delegated image in get_image()");
    }

    if ( $elt->{data} ) {	# have data
	$data = $elt->{data};
	warn("get_image($elt->{subtype}): data ", length($data), " bytes\n")
	  if $config->{debug}->{images};
	return $data;
    }

    my $uri = $elt->{uri};
    if ( !$subtype && $uri =~ /\.(\w+)$/ ) {
	$subtype //= $1;
    }

    if ( $subtype =~ /^(jpg|png|gif)$/ ) {
	$img = $self->{pdf}->image($uri);
	warn("get_image($subtype, $uri): img ", length($img), " bytes\n")
	  if $config->{debug}->{images};
    }
    elsif ( $subtype =~ /^(xform)$/ ) {
	$img = $data;
	warn("get_image($subtype): xobject (",
#	     join(" ", $img->bbox),
	     join(" ", @{$data->{bbox}}),
	     ")\n")
	  if $config->{debug}->{images};
    }
    else {
	croak("Unhandled image type: $subtype\n");
    }
    return $img;
}

sub _xo_width {
    my ( $self ) = @_;
    my @bb = $self->bbox;
    return abs($bb[2]-$bb[0]);
}
sub _xo_height {
    my ( $self ) = @_;
    my @bb = $self->bbox;
    return abs($bb[3]-$bb[1]);
}

sub add_object {
    my ( $self, $o, $x, $y, %options ) = @_;

    my $scale_x = $options{"xscale"} || $options{"scale"} || 1;
    my $scale_y = $options{"yscale"} || $options{"scale"} || $scale_x;

    my $va = $options{valign} // "bottom";
    my $ha = $options{align}  // "left";

    my $gfx = $self->{pdfgfx};
    my $w = $o->width  * $scale_x;
    my $h = $o->height * $scale_y;

    warn( sprintf("add_object x=%.1f y=%.1f w=%.1f h=%.1f scale=%.1f,%.1f) %s\n",
		  $x, $y, $w, $h, $scale_x, $scale_y, $ha,
		 ) ) if $config->{debug}->{images};

    $self->crosshairs( $x, $y, color => "lime" ) if $config->{debug}->{images};
    if ( $va eq "top" ) {
	$y -= $h;
    }
    elsif ( $va eq "middle" ) {
	$y -= $h/2;
    }
    if ( $ha eq "right" ) {
	$x -= $w;
    }
    elsif ( $ha eq "center" ) {
	$x -= $w/2;
    }

    $self->crosshairs( $x, $y, color => "red" ) if $config->{debug}->{images};
    $gfx->save;
    if ( ref($o) =~ /::Resource::XObject::Image::/ ) {
	# Image wants width and height.
	$gfx->object( $o, $x, $y, $w, $h );
    }
    else {
	# XO_Form wants xscale and yscale.
	my @bb = $o->bbox;
	$gfx->object( $o, $x-min($bb[0],$bb[2])*$scale_x,
		      $y-min($bb[1],$bb[3])*$scale_y, $scale_x, $scale_y );
    }

    if ( $options{border} ) {
	my $bc = $options{"bordercolor"} || $options{"color"};
	$gfx->stroke_color($bc) if $bc;
	$gfx->rectangle( $x, $y, $x+$w, $y+$h )
	  ->line_width( $options{border} )
	    ->stroke;
    }
    if ( $options{href} ) {
	my $a = $gfx->{' apipage'}->annotation;
	$a->url( $options{href}, -rect => [ $x, $y, $x+$w, $y+$h ] );
    }

    $gfx->restore;
}

# For convenience.
sub crosshairs {
    my ( $self, $x, $y, %options ) = @_;
    my $gfx = $self->{pdfgfx};
    my $col = $options{colour} || $options{color} || "black";
    my $lw  = $options{linewidth} || 0.1;
    my $w  = ( $options{width} || 40 ) / 2;
    my $h  = ( $options{width} || $options{height} || 40 ) / 2;
    for ( $gfx  ) {
	$_->save;
	$_->line_width($lw);
	$_->stroke_color($col);
	$_->move($x-$w,$y);
	$_->hline($x+$w);
	$_->move($x,$y+$h);
	$_->vline($y-$h);
	$_->stroke;
	$_->restore;
    }
}

sub add_image {
    my ( $self, $img, $x, $y, $w, $h, $border ) = @_;
    $self->add_object( $img, $x, $y,
		       xscale => $w/$img->width,
		       yscale => $h/$img->height,
		       valign => "bottom",
		       $border ? ( border => $border ) : () );
}

sub newpage {
    my ( $self, $ps, $page ) = @_;
    #$self->{pdftext}->textend if $self->{pdftext};
    $page ||= 0;

    # PDF::API2 says $page must refer to an existing page.
    # Set to 0 to append.
    $page = 0 if $page == $self->{pdf}->pages + 1;

    $self->{pdfpage} = $self->{pdf}->page($page);
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
    confess("Fatal: Page $page not found.") unless $self->{pdfpage};
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

sub importfile {
    my ( $self, $filename ) = @_;
    my $pdf = $self->{pdfapi}->open($filename);
    return unless $pdf;		# should have been checked
    for ( my $page = 1; $page <= $pdf->pages; $page++ ) {
	$self->{pdf}->import_page( $pdf, $page );
    }
    return { pages => $pdf->pages, $pdf->info_metadata };
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
	$c->( $self->{pdf}, $page+1, %$opts );
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
	my $needlh = 0;
	if ( $ctl->{letter} > 0 ) {
	    for ( @$book ) {
		# Group on first letter.
		# That's why we left the sort fields in...
		my $cur = uc(substr( $_->[0], 0, 1 ));
		$lh{$cur} //= [];
		# Last item is the song.
		push( @{$lh{$cur}}, $_->[-1] );
	    }
	    # Need letter hierarchy?
	    $needlh = keys(%lh) >= $ctl->{letter};
	}

	if ( $needlh ) {
	    my $cur_ol;
	    my $cur_let = "";
	    foreach my $let ( sort keys %lh ) {
		foreach my $song ( @{$lh{$let}} ) {
		    unless ( defined $cur_ol && $cur_let eq $let ) {
			# Intermediate level autoline.
			$cur_ol = $outline->outline;
			$cur_ol->title($let);
			$cur_let = $let;
		    }
		    # Leaf outline.
		    my $ol = $cur_ol->outline;
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
	else {
	    ####TODO: Why?
	    if ( @$book == 1 && ref($book->[0]) eq 'ChordPro::Song' ) {
		$book = [[ $book->[0] ]];
	    }
	    foreach my $b ( @$book ) {
		my $song = $b->[-1];
		# Leaf outline.
		my $ol = $outline->outline;
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

    my $fc = Text::Layout::FontConfig->new( debug => $config->{debug}->{fonts} > 1 );

    # Add font dirs.
    my @dirs;
    my @d = ( @{$ps->{fontdir}}, @{ CP->findresdirs("fonts") }, $ENV{FONTDIR} );
    # Avoid rsc result if dummy.
    splice( @d, -2, 1 ) if $d[-2] eq "fonts/";
    for my $fontdir ( @d ) {
	next unless $fontdir;
	$fontdir = expand_tilde($fontdir);
	if ( -d $fontdir ) {
	    $self->{pdfapi}->can("addFontDirs")->($fontdir);
	    $fc->add_fontdirs($fontdir);
	    push( @dirs, $fontdir );
	}
	else {
	    warn("PDF: Ignoring fontdir $fontdir [$!]\n");
	    undef $fontdir;
	}
    }

    # Make sure we have this one.
    $fc->register_font( "ChordProSymbols.ttf", "chordprosymbols", "", {} );

    # Remap corefonts if possible.
    my $remap = $ENV{CHORDPRO_COREFONTS_REMAP} // $ps->{corefonts}->{remap};
    # Packager adds the fonts.
    $remap //= "free" if CP->packager;

    unless ( defined $remap ) {

	# Not defined -- find the GNU Free Fonts.
	for my $dir ( @dirs ) {
	    my $have = 1;
	    for my $font ( qw( FreeSerif.ttf
			       FreeSerifBoldItalic.ttf
			       FreeSerifBold.ttf
			       FreeSerifItalic.ttf
			       FreeSans.ttf
			       FreeSansBoldOblique.ttf
			       FreeSansBold.ttf
			       FreeSansOblique.ttf
			       FreeMono.ttf
			       FreeMonoBoldOblique.ttf
			       FreeMonoBold.ttf
			       FreeMonoOblique.ttf
			    ) ) {
		$have = 0, last unless -f -s "$dir/$font";;
	    }
	    $remap = "free", last if $have;
	}
    }
    $fc->register_corefonts( remap => $remap ) if $remap;

    # Process the fontconfig.
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

    my $fc = Text::Layout::FontConfig->new( debug => $config->{debug}->{fonts} > 1 );
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

    my $fc = Text::Layout::FontConfig->new( debug => $config->{debug}->{fonts} > 1 );
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
    my $cf = is_corefont($font->{name});
    die("Config error: \"$font->{name}\" is not a built-in font\n")
      unless $cf;
    my $fc = Text::Layout::FontConfig->new( debug => $config->{debug}->{fonts} > 1 );
    eval {
	$font->{fd} = $fc->from_filename($cf);
	$font->{fd}->get_font($self->{layout}); # force load
	$font->{_ff} = $ff;
    };
    $font->{fd};
}

sub show_vpos {
    my ( $self, $y, $w ) = @_;
    $self->{pdfgfx}->move(100*$w,$y)->linewidth(0.25)->hline(100*(1+$w))->stroke;
}

sub embed {
    my ( $self, $file ) = @_;
    $file = encode_utf8($file);
    return unless -f $file;

    # Borrow some routines from PDF Api.
    *PDFNum = \&{$self->{pdfapi} . '::Basic::PDF::Utils::PDFNum'};
    *PDFStr = \&{$self->{pdfapi} . '::Basic::PDF::Utils::PDFStr'};

    # The song.
    # Apparently the 'hidden' flag does not hide it completely,
    # so give it a rect outside the page.
    my $a = $self->{pdfpage}->annotation();
    $a->text( loadlines( $file, { split => 0 } ),
	      -open => 0, -rect => [0,0,-1,-1] );
    $a->{T} = PDFStr("ChordProSong");
    $a->{F} = PDFNum(2);		# hidden

    # The config.
    $a = $self->{pdfpage}->annotation();
    $a->text( ChordPro::Config::config_final(),
	      -open => 0, -rect => [0,0,-1,-1]);
    $a->{T} = PDFStr("ChordProConfig");
    $a->{F} = PDFNum(2);		# hidden

    # Runtime info.
    $a = $self->{pdfpage}->annotation();
    $a->text( ::runtimeinfo(),
	      -open => 0, -rect => [0,0,-1,-1] );
    $a->{T} = PDFStr("ChordProRunTime");
    $a->{F} = PDFNum(2);		# hidden

    # Call.
    $a = $self->{pdfpage}->annotation();
    $a->text( join(" ", @{$::options->{_argv}}) . "\n",
	      -open => 0, -rect => [0,0,-1,-1] );
    $a->{T} = PDFStr("ChordProCall");
    $a->{F} = PDFNum(2);		# hidden
}

1;
