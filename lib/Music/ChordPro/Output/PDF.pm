#!/usr/bin/perl

package Music::ChordPro::Output::PDF;

use strict;
use warnings;
use Data::Dumper;

sub generate_songbook {
    my ($self, $sb, $options) = @_;

    my $ps = page_settings( $options );
    $ps->{pr} = PDFWriter->new( $ps, $options->{output} || "__new__.pdf" );
    $ps->{pr}->{pdf}->mediabox( $ps->{papersize}->[0],
				$ps->{papersize}->[1] );
    my @tm = gmtime(time);
    $ps->{pr}->info( Title => $sb->{songs}->[0]->{title},
		     Creator => "pChord [$options->{_name} $options->{_version}]",
		     CreationDate =>
		     sprintf("D:%04d%02d%02d%02d%02d%02d+00'00'",
			     1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]),
		   );

    my @book;
    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    $ps->{pr}->newpage($ps);
	    push(@book, "{new_song}");
	}
	showlayout($ps);
	generate_song( $song, { ps => $ps, $options ? %$options : () } );
    }
    $ps->{pr}->finish;
    []
}

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chord lines

use constant SIZE_ITEMS => [ qw (chord text ) ];

sub generate_song {
    my ($s, $options) = @_;

    my $ps = $options->{ps};
    my $x = $ps->{marginleft} + $ps->{offsets}->[0];
    my $y = $ps->{papersize}->[1] - $ps->{margintop};
    $s->structurize
      if ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';

    my $sb = $s->{body};
    $ps->{column} = 0;
    $ps->{columns} = $s->{settings}->{columns} || 1;
    my $st = $s->{settings}->{titles} || "left";

    $single_space = $options->{'single-space'};
    $lyrics_only = 2 * $options->{'lyrics-only'};

    for my $item ( @{ SIZE_ITEMS() } ) {
	for ( $options->{"$item-font"} ) {
	    next unless $_ && m;/;;
	    $ps->{fonts}->{$item}->{file} = $_;
	}
	for ( $options->{"$item-size"} ) {
	    next unless $_;
	    $ps->{fonts}->{$item}->{size} = $_;
	}
    }

    my $set_sizes = sub {
	$ps->{lineheight} = $ps->{fonts}->{text}->{size} - 1; # chordii
	$ps->{chordheight} = $ps->{fonts}->{chord}->{size};
    };
    $set_sizes->();
    $ps->{'vertical-space'} = $options->{'vertical-space'};
    for ( @{ SIZE_ITEMS() } ) {
	$ps->{fonts}->{$_}->{_size} = $ps->{fonts}->{chord}->{size};
    }

    my $show = sub {
	my ( $text, $font ) = @_;
	my $x = $x;
	if ( $st eq "right" ) {
	    $ps->{pr}->setfont($font);
	    $x = $ps->{papersize}->[0]
		 - $ps->{marginright}
		 - $ps->{pr}->strwidth($text);
	}
	elsif ( $st eq "center" || $st eq "centre" ) {
	    $ps->{pr}->setfont($font);
	    $x = $ps->{marginleft} +
	         ( $ps->{papersize}->[0]
		   - $ps->{marginright}
		   - $ps->{marginleft}
		   - $ps->{pr}->strwidth($text) ) / 2;
	}
	$ps->{pr}->text( $text, $x, $y, $font );
	$y -= $font->{size};
    };

    my $do_size = sub {
	my ( $tag, $value ) = @_;
	if ( $value =~ /^(.+)\%$/ ) {
	    $ps->{fonts}->{$tag}->{size} =
	      ( $1 / 100 ) * $ps->{fonts}->{$tag}->{_size};
	}
	else {
	    $ps->{fonts}->{$tag}->{size} =
	      $ps->{fonts}->{$tag}->{_size} = $value;
	}
	$set_sizes->();
    };

    if ( $s->{title} ) {
	$show->( $s->{title}, $ps->{fonts}->{title} );
    }

    if ( $s->{subtitle} ) {
	for ( @{$s->{subtitle}} ) {
	    $show->( $_, $ps->{fonts}->{subtitle} );
	}
    }

    if ( $s->{title} or $s->{subtitle} ) {
	$y -= $ps->{headspace};
    }

    my $y0 = $y;
    my $cskip = 0;

    my $newpage = sub {
	$ps->{pr}->newpage($ps);
	showlayout($ps);
	$x = $ps->{marginleft} + $ps->{offsets}->[$ps->{column} = 0];
	$y0 = $y = $ps->{papersize}->[1] - $ps->{margintop} - $ps->{headspace};
    };

    my $vsp = sub {
	my $extra = $_[0] || 0;
	$ps->{linespace} * $ps->{lineheight} +
	  $ps->{'vertical-space'} + $extra;
    };

    my $checkspace = sub {
	my $vsp = $_[0];
	$newpage->() if $y - $vsp <= $ps->{marginbottom};
    };

    foreach my $elt ( @{$sb} ) {

	$cskip = 0 unless $elt->{type} =~ /^comment/;

	if ( $elt->{type} eq "newpage" ) {
	    $newpage->();
	    next;
	}
	$checkspace->(0);

	if ( $elt->{type} eq "colb" ) {
	    if ( ++$ps->{column} >= $ps->{columns}) {
		$ps->{pr}->newpage;
		showlayout($ps);
		$x = $ps->{marginleft} + $ps->{offsets}->[$ps->{column} = 0];
		$y = $ps->{papersize}->[1] - $ps->{margintop};
	    }
	    else {
		$x = $ps->{marginleft} + $ps->{offsets}->[$ps->{column}];
		$y = $y0;
	    }
	    next;
	}

	if ( $elt->{type} eq "empty" ) {
	    my $y0 = $y;
	    warn("***SHOULD NOT HAPPEN1***")
	      if $s->{structure} eq "structured";
	    $y -= $vsp->(4);	# chordii
	    next;
	}

	if ( $elt->{type} eq "songline" ) {
	    $checkspace->(songline_vsp( $elt, $ps ));
	    if ( $elt->{context} eq "chorus" ) {
		if ( $ps->{chorusindent} ) {
		    $y = songline( $elt, $x + $ps->{chorusindent}, $y, $ps );
		    next;
		}
		my $cy = $y + $vsp->(-2);
		$y = songline( $elt, $x, $y, $ps );
		my $cx = $ps->{marginleft} + $ps->{offsets}->[0] - 10;
		$ps->{pr}->{pdfgfx}
		  ->move( $cx, $cy+1 )
		  ->linewidth(1)
		  ->vline( $y + $vsp->(-2) )
		  ->stroke;
	    }
	    else {
		$y = songline( $elt, $x, $y, $ps );
	    }
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    my $cy = $y + $vsp->(-2); # ####TODO????
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "songline" ) {
		    $y = songline( $e, $x, $y, $ps );
		    next;
		}
		elsif ( $e->{type} eq "empty" ) {
		    warn("***SHOULD NOT HAPPEN2***");
		    $y -= $vsp->();
		    next;
		}
	    }
	    my $cx = $ps->{marginleft} + $ps->{offsets}->[0] - 10;
	    $ps->{pr}->{pdfgfx}
	      ->move( $cx, $cy )
	      ->linewidth(1)
	      ->vline( $y + $vsp->())
	      ->stroke;
	    $y -= $vsp->(4); # chordii
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "songline" ) {
		    $checkspace->(songline_vsp( $e, $ps ));
		    $y = songline( $e, $x, $y, $ps );
		    next;
		}
		elsif ( $e->{type} eq "empty" ) {
		    warn("***SHOULD NOT HAPPEN2***");
		    $y -= $vsp->();
		    next;
		}
	    }
	    $y -= $vsp->(4);	# chordii
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    $ps->{pr}->setfont( $ps->{fonts}->{tab} );
	    my $dy = $ps->{fonts}->{tab}->{size};
	    foreach my $e ( @{$elt->{body}} ) {
		next unless $e->{type} eq "tabline";
		$ps->{pr}->text( $e->{text}, $x, $y );
		$y -= $dy;
	    }
	    next;
	}

	if ( $elt->{type} eq "tabline" ) {
	    $ps->{pr}->setfont( $ps->{fonts}->{tab} );
	    my $dy = $ps->{fonts}->{tab}->{size};
	    $ps->{pr}->text( $elt->{text}, $x, $y );
	    $y -= $dy;
	    next;
	}

	if ( $elt->{type} eq "comment" ) {
	    $y += $ps->{'vertical-space'} if $cskip++;
	    my $font = $ps->{fonts}->{comment} || $ps->{fonts}->{text};
	    $ps->{pr}->setfont( $font );
	    my $text = $elt->{text};
	    my $w = $ps->{pr}->strwidth( $text );
	    my $y0 = $y;
	    my $y1 = $y0 + 0.8*($font->{size});
	    $y0 = $y1 - $font->{size};
	    my $x1 = $x + $w;

	    # Draw background.
	    my $gfx = $ps->{pr}->{pdfpage}->gfx(1);
	    my $bgcol = $font->{background} || "#E5E5E5";
	    $gfx->save;
	    $gfx->fillcolor($bgcol);
	    $gfx->strokecolor($bgcol);
	    $gfx
	      ->rectxy( $x, $y0, $x1, $y1 )
		->linewidth(3)
		  ->fillstroke;
	    $gfx->restore;

	    # Draw text.
	    $ps->{pr}->text( $text, $x, $y );
	    $y -= $vsp->();
	    next;
	}

	if ( $elt->{type} eq "comment_italic" ) {
	    my $font = $ps->{fonts}->{comment_italic} || $ps->{fonts}->{chord};
	    $ps->{pr}->setfont( $font );
	    $ps->{pr}->text( $elt->{text}, $x, $y );
	    $y -= $vsp->();
	    next;
	}

	if ( $elt->{type} eq "image" ) {
	    my $opts = $elt->{opts};
	    my $img = $ps->{pr}->{pdf}->image_png($elt->{uri});
	    my $pw = $ps->{papersize}->[0] - $ps->{marginleft} - $ps->{marginright};
	    my $ph = $ps->{papersize}->[1] - $ps->{margintop} - $ps->{marginbottom};
	    # First shot...
	    my $scale = 1;
	    my ( $w, $h ) = ( $opts->{width}  || $img->width,
			      $opts->{height} || $img->height );
	    if ( defined $opts->{scale} ) {
		$scale = $opts->{scale} || 1;
	    }
	    else {
		if ( $w > $pw ) {
		    $scale = $pw / $w;
		}
		if ( $h*$scale > $ph ) {
		    $scale = $ph / $h;
		}
	    }
	    $h *= $scale;
	    $w *= $scale;

	    my $x = $x;
	    $x += ($pw - $w) / 2 if $opts->{center} // 1;
	    $y += $vsp->() / 2;
	    if ( $y - $h < $ps->{marginbottom} ) {
		$newpage->();
	    }
	    my $gfx = $ps->{pr}->{pdfpage}->gfx(1);
	    $gfx->save;
	    $gfx->image( $img, $x, $y-$h, $w, $h );
	    if ( $opts->{border} ) {
		$gfx->rect( $x, $y-$h, $w, $h )
		  ->linewidth($opts->{border})
		    ->stroke;
	    }
	    $gfx->restore;
	    $y -= $h;
	    $y -= 1.5 * $vsp->();
	    next;
	}

	if ( $elt->{type} eq "control" ) {
	    if ( $elt->{name} eq "text-size" ) {
		$do_size->( "text", $elt->{value} );
	    }
	    elsif ( $elt->{name} eq "chord-size" ) {
		$do_size->( "chord", $elt->{value} );
	    }
	    elsif ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	}
    }
}

sub songline {
    my ( $elt, $x, $y, $ps ) = @_;
    my $ftext = $ps->{fonts}->{text};

    my $vsp = sub {
	if ( $ps->{linespace} ) {
	    return $ps->{linespace} * $ps->{lineheight};
	}
	$ps->{lineheight} + $ps->{'vertical-space'};
    };

    if ( $lyrics_only
	 or
	 $single_space && ! ( $elt->{chords} && join( "", @{ $elt->{chords} } ) =~ /\S/ )
       ) {
	$ps->{pr}->text( join( "", @{ $elt->{phrases} } ), $x, $y+2, $ftext );
	return $y - $vsp->();
    }

    $elt->{chords} //= [ '' ];

    my $fchord = $ps->{fonts}->{chord};
    foreach ( 0..$#{$elt->{chords}} ) {
	my $chord = $elt->{chords}->[$_];
	my $phrase = $elt->{phrases}->[$_];

	if ( $fchord->{background} && $chord ne "" ) {
	    # Draw background.
	    my $w = $ps->{pr}->strwidth($chord." ");
	    my $y0 = $y;
	    my $y1 = $y0 + 0.8*($fchord->{size});
	    $y0 = $y1 - $fchord->{size};
	    my $bgcol = $fchord->{background};
	    my $x1 = $x + $w - $ps->{pr}->strwidth(" ")/2;
	    my $gfx = $ps->{pr}->{pdfpage}->gfx(1);
	    $gfx->save;
	    $gfx->fillcolor($bgcol);
	    $gfx->strokecolor($bgcol);
	    $gfx->rectxy( $x, $y0, $x1, $y1 )
	      ->linewidth(3)
		->fillstroke;
	    $gfx->restore;
	}

	my $xt0 = $ps->{pr}->text( $chord." ", $x, $y, $fchord );
	my $xt1 = $ps->{pr}->text( $phrase, $x, $y-$ps->{lineheight}, $ftext );
	$x = $xt0 > $xt1 ? $xt0 : $xt1;
    }
    return $y - $vsp->() - $ps->{chordheight};
}

sub songline_vsp {
    my ( $elt, $ps ) = @_;
    my $ftext = $ps->{fonts}->{text};

    my $vsp = sub {
	if ( $ps->{linespace} ) {
	    return $ps->{linespace} * $ps->{lineheight};
	}
	$ps->{lineheight} + $ps->{'vertical-space'};
    };

    if ( $lyrics_only
	 or
	 $single_space && ! ( $elt->{chords} && join( "", @{ $elt->{chords} } ) =~ /\S/ )
       ) {
	return $vsp->();
    }

    $vsp->() + $ps->{chordheight};
}

sub page_settings {
    my ( $options ) = @_;

    use JSON qw(decode_json);

    my $ret = {};
    if ( open( my $fd, "<:utf8", $options->{pagedefs} || "pagedefs.json" ) ) {
	local $/;
	$ret = decode_json( scalar( <$fd> ) );
	$fd->close;
    }
    elsif ( $options->{pagedefs} ) {
	die("Cannot open ", $options->{pagedefs}, " [$!]\n");
    }

    # Add font dirs.
    my $fontdir = $ret->{pdf}->{fontdir} || $ENV{FONTDIR};
    if ( $fontdir ) {
	if ( -d $fontdir ) {
	    PDF::API2::addFontDirs($fontdir);
	}
	else {
	    warn("PDF: Ignoring fontdir $fontdir [$!]\n");
	    undef $fontdir;
	}
    }
    else {
	undef $fontdir;
    }

    $ret = $ret->{pdf};
    my $def =
      { papersize     => [ 595, 842 ],	# A4, portrait
	marginleft    => 130,
	margintop     =>  66,
	marginbottom  =>  40,
	marginright   =>  40,
	headspace     =>  20,
	offsets       => [ 0, 250 ],	# col 1, col 2
	linespace     =>   1,
      };

    # Use fallback values, if necessary.
    $ret->{$_} ||= $def->{$_} foreach keys(%$def);

    my $stdfonts =
      { title   => { name => 'Times-Bold',        size => 14 },
	text    => { name => 'Times-Roman',       size => 14 },
	chord   => { name => 'Helvetica-Oblique', size => 10 },
	tab     => { name => 'Courier',           size => 10 },
      };

    # Use fallback fonts, if necessary.
    $ret->{fonts}->{$_} ||= $stdfonts->{$_} foreach keys(%$stdfonts);

    # Sanitize, if necessary.
    $ret->{fonts}->{subtitle}       ||= $ret->{fonts}->{text};
    $ret->{fonts}->{comment_italic} ||= $ret->{fonts}->{chord};
    $ret->{fonts}->{comment}        ||= $ret->{fonts}->{text};

    return $ret;
}

sub showlayout {
    my ( $ps ) = @_;
#    return;
    $ps->{pr}->{pdfgfx}
      ->linewidth(0.5)
      ->rectxy( $ps->{marginleft},
		$ps->{marginbottom},
		$ps->{papersize}->[0]-$ps->{marginright},
		$ps->{papersize}->[1]-$ps->{margintop} )
	->stroke;
    foreach my $i ( 0 .. @{ $ps->{offsets} }-1 ) {
	next unless $i;
	$ps->{pr}->{pdfgfx}
	  ->linewidth(0.25)
	    ->move( $ps->{marginleft}+$ps->{offsets}->[$i],
		    $ps->{marginbottom} )
	      ->vline( $ps->{papersize}->[1]-$ps->{margintop} )
		->stroke;
    }
}

package PDFWriter;

use strict;
use warnings;
use PDF::API2;
use Encode;

my %fonts;

sub new {
    my ( $pkg, $ps, @file ) = @_;
    my $self = bless { ps => $ps }, $pkg;
    $self->{pdf} = PDF::API2->new( -file => $file[0] );
    $self->{pdf}->{forcecompress} = 0;
    $self->newpage($ps);
    $self;
}

sub info {
    my ( $self, %info ) = @_;
    $self->{pdf}->info( %info );
}

sub text {
    my ( $self, $text, $x, $y, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->setfont($font, $size);

    $text = encode( "cp1250", $text ) unless $font->{file};
    $self->{pdftext}->translate( $x, $y );
    return $x + $self->{pdftext}->text($text);
}

sub setfont {
    my ( $self, $font, $size ) = @_;
    $self->{font} = $font;
    $self->{fontsize} = $size ||= $font->{size};
    $self->{pdftext}->font( $self->_getfont($font), $size );
}

sub _getfont {
    my ( $self, $font ) = @_;
    $self->{font} = $font;
    if ( $font->{file} ) {
	if ( $font->{file} =~ /\.[ot]tf$/ ) {
	    return $fonts{$font->{file}} ||=
	      $self->{pdf}->ttfont( $font->{file},
				    -dokern => 1 );
	}
	elsif ( $font->{file} =~ /\.pf[ab]$/ ) {
	    return $fonts{$font->{file}} ||=
	      $self->{pdf}->psfont( $font->{file},
				    -afmfile => $font->{metrics},
				    -dokern  => 1 );
	}
	else {
	    return $self->{pdf}->corefont( 'Courier' );
	}
    }
    else {
	return $fonts{$font->{name}} ||=
	  $self->{pdf}->corefont( $font->{name} );
    }
}

sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};
    $self->setfont( $font, $size );
    $self->{pdftext}->advancewidth($text);
}

sub newpage {
    my ( $self, $ps ) = @_;
    #$self->{pdftext}->textend if $self->{pdftext};
    $self->{pdfpage} = $self->{pdf}->page;
    $self->{pdfpage}->mediabox( $ps->{papersize}->[0],
				$ps->{papersize}->[1] );
    $self->{pdftext} = $self->{pdfpage}->text;
    $self->{pdfgfx}  = $self->{pdfpage}->gfx;
}

sub add {
    my ( $self, @text ) = @_;
#    prAdd( "@text" );
}

sub finish {
    my $self = shift;
    $self->{pdf}->save;
}

1;
