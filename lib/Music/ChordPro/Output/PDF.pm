#!/usr/bin/perl

use utf8;

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
my $chordscol = 0;		# chords in a separate column
my $chordscapo = 0;		# capo in a separate column

use constant SIZE_ITEMS => [ qw (chord text ) ];

sub vsp {
    my ( $ps, $extra ) = @_;
    $extra ||=  0;
    $ps->{linespace} * $ps->{lineheight} +
      $ps->{'vertical-space'} + $extra;
}

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
    $ps->{columns} = @{$ps->{offsets}}
      if $ps->{columns} > @{$ps->{offsets}};
    my $st = $s->{settings}->{titles} || "left";

    $single_space = $options->{'single-space'};
    $chordscol = $options->{'chords-column'};
    $lyrics_only = 2 * $options->{'lyrics-only'};
    $chordscapo = $s->{meta}->{capo};

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
    my $col = 0;

    my $newpage = sub {
	$ps->{pr}->newpage($ps);
	showlayout($ps);
	$x = $ps->{marginleft} + $ps->{offsets}->[$col = 0];
	$y0 = $y = $ps->{papersize}->[1] - $ps->{margintop} - $ps->{headspace};
    };

    my $checkspace = sub {
	my $vsp = $_[0];
	$newpage->() if $y - $vsp <= $ps->{marginbottom};
    };

    my @elts = @{$sb};
    my $elt;			# current element
    my $prev;			# previous element
    my @chorus;			# chorus elements, if any

    my $grid_cellwidth;
    my $grid_barwidth = 8;	# tentative
    $grid_barwidth *= 1.5;		#####

    while ( @elts ) {
	$elt = shift(@elts);
	$cskip = 0 unless $elt->{type} =~ /^comment/;

	if ( $elt->{type} eq "newpage" ) {
	    $newpage->();
	    next;
	}
	$checkspace->(0);

	if ( $elt->{type} eq "colb" ) {
	    if ( ++$col >= $ps->{columns}) {
		$newpage->();
	    }
	    else {
		$x = $ps->{marginleft} + $ps->{offsets}->[$col];
		$y = $y0;
	    }
	    next;
	}

	if ( $elt->{type} eq "empty" ) {
	    my $y0 = $y;
	    warn("***SHOULD NOT HAPPEN1***")
	      if $s->{structure} eq "structured";
	    $y -= vsp($ps,4);	# chordii
	    next;
	}

	# Collect chorus elements so they can be recalled.
	if ( $elt->{context} eq "chorus" ) {
	    @chorus = () unless $prev && $prev->{context} eq "chorus";
	    push( @chorus, $elt );
	}

	if ( $elt->{type} eq "songline" ) {

	    $checkspace->(songline_vsp( $elt, $ps ));

	    if ( $elt->{context} eq "chorus" ) {
		if ( $ps->{chorusindent} ) {
		    $y = songline( $elt, $x + $ps->{chorusindent}, $y, $ps );
		    next;
		}
		my $cy = $y + vsp($ps,-2);
		$cy -= $ps->{chordheight} if $chordscol;
		$y = songline( $elt, $x, $y, $ps );
		my $y1 = $y + vsp($ps,-2);
		$y1 -= $ps->{chordheight} if $chordscol;
		my $cx = $ps->{marginleft} + $ps->{offsets}->[$col] - 10;
		$ps->{pr}->{pdfgfx}
		  ->move( $cx, $cy+1 )
		    ->linewidth(1)
		      ->vline( $y1 )
			->stroke;
		next;
	    }

	    $y = songline( $elt, $x, $y, $ps );
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    my $cy = $y + vsp($ps,-2); # ####TODO????
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "songline" ) {
		    $y = songline( $e, $x, $y, $ps );
		    next;
		}
		elsif ( $e->{type} eq "empty" ) {
		    warn("***SHOULD NOT HAPPEN2***");
		    $y -= vsp($ps);
		    next;
		}
	    }
	    my $cx = $ps->{marginleft} + $ps->{offsets}->[$col] - 10;
	    $ps->{pr}->{pdfgfx}
	      ->move( $cx, $cy )
	      ->linewidth(1)
	      ->vline( $y + vsp($ps))
	      ->stroke;
	    $y -= vsp($ps,4); # chordii
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
		    $y -= vsp($ps);
		    next;
		}
	    }
	    $y -= vsp($ps,4);	# chordii
	    next;
	}

	if ( $elt->{type} eq "gridline" ) {

	    $checkspace->(songline_vsp( $elt, $ps ));

	    if ( $elt->{context} eq "chorus" ) {
		if ( $ps->{chorusindent} ) {
		    $y = gridline( $elt, $x + $ps->{chorusindent}, $y, $ps );
		    next;
		}
		my $cy = $y + vsp($ps,-2);
		$y = gridline( $elt, $x, $y,
			       $grid_cellwidth, $grid_barwidth, $ps );
		my $cx = $ps->{marginleft} + $ps->{offsets}->[$col] - 10;
		$ps->{pr}->{pdfgfx}
		  ->move( $cx, $cy+1 )
		    ->linewidth(1)
		      ->vline( $y + vsp($ps,-2) )
			->stroke;
		next;
	    }

	    $y = gridline( $elt, $x, $y,
			   $grid_cellwidth, $grid_barwidth, $ps );
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

	if ( $elt->{type} eq "comment"
	     or $elt->{type} eq "comment_box"
	     or $elt->{type} eq "comment_italic" ) {
	    $y += $ps->{'vertical-space'} if $cskip++;
	    my $font = $ps->{fonts}->{$elt->{type}} || $ps->{fonts}->{comment};
	    $ps->{pr}->setfont( $font );
	    my $text = $elt->{text};
	    my $w = $ps->{pr}->strwidth( $text );
	    my $y0 = $y;
	    my $y1 = $y0 + 0.8*($font->{size});
	    $y0 = $y1 - $font->{size};
	    my $x1 = $x + $w;
	    my $gfx = $ps->{pr}->{pdfpage}->gfx(1);

	    # Draw background.
	    my $bgcol = $font->{background};
	    $bgcol ||= "#E5E5E5" if $elt->{type} eq "comment";
	    if ( $bgcol ) {
		$gfx->save;
		$gfx->fillcolor($bgcol);
		$gfx->strokecolor($bgcol);
		$gfx
		  ->rectxy( $x, $y0, $x1, $y1 )
		    ->linewidth(3)
		      ->fillstroke;
		$gfx->restore;
	    }

	    # Draw box.
	    if ( $elt->{type} eq "comment_box" ) {
		$gfx->save;
		$gfx->strokecolor("#000000"); # black
		$gfx
		  ->rectxy( $x-1, $y0-1, $x1+1, $y1+1 )
		    ->linewidth(1)
		      ->stroke;
		$gfx->restore;
	    }

	    # Draw text.
	    $ps->{pr}->text( $text, $x, $y );
	    $y -= vsp($ps);
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
	    $y += vsp($ps) / 2;
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
	    $y -= 1.5 * vsp($ps);
	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    unshift( @elts, @chorus );
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
	    elsif ( $elt->{name} eq "chords-column" ) {
		$chordscol = $elt->{value}
		  unless $chordscol > 1;
	    }
	    elsif ( $elt->{name} eq "gridparams" ) {
		my @v = @{ $elt->{value} };
		my $cells;
		my $bars = 8;
		if ( $v[1] ) {
		    $cells = $v[0] * $v[1];
		    $bars = $v[0];
		}
		else {
		    $cells = $v[0];
		}
		$grid_cellwidth = ( $ps->{papersize}->[0]
				    - $ps->{marginleft}
				    - $ps->{marginright}
				    - (1+$bars)*$grid_barwidth
				  ) / $cells;
	    }
	}
    }
    continue {
	$prev = $elt;
    }
}

sub songline {
    my ( $elt, $x, $y, $ps ) = @_;

    # songline draws text in boxes as follows:
    #
    # +------------------------------
    # |  C   F    G
    # |
    # +------------------------------
    # |  Lyrics text
    # +------------------------------
    #
    # Variants are:
    #
    # +------------------------------
    # |  Lyrics text (lyrics-only, or single-space and no chords)
    # +------------------------------
    #
    # And:
    #
    # +-----------------------+-------
    # |  Lyrics text          | C F G
    # +-----------------------+-------
    #
    # Problem is that we are dealing with baselines, and that chords
    # may have a different height than lyrics.
    #
    # To find the upper/lower extents, the ratio
    #
    #  $font->ascender / $font->descender
    #
    # can be used. E.g., a font of size 16 with descender -250 and
    # ascender 750 will get to 4 points below the baseline.



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
    my $chordsx = $x + $ps->{chordscolumn};
    if ( $chordsx < 0 ) {
	($x, $chordsx) = (-$chordsx, $x);
    }
    my @chords;
    foreach ( 0..$#{$elt->{chords}} ) {
	my $chord = $elt->{chords}->[$_];
	my $phrase = $elt->{phrases}->[$_];

	if ( $fchord->{background} && $chord ne "" && !$chordscol ) {
	    # Draw background.
	    my $w = $ps->{pr}->strwidth( $chord." ", $fchord );
#	    my $w = $ps->{pr}->strwidth( $chord, $fchord );
	    my $y0 = $y;
	    my $y1 = $y0 + 0.8*($fchord->{size});
	    $y0 = $y1 - $fchord->{size};
	    my $bgcol = $fchord->{background};
	    my $x1 = $x + $w - $ps->{pr}->strwidth(" ")/2;
	    my $x = $x - $ps->{pr}->strwidth(" ")/2;
#	    my $x1 = $x + $w;
	    my $gfx = $ps->{pr}->{pdfpage}->gfx(1);
	    $gfx->save;
	    $gfx->fillcolor($bgcol);
	    $gfx->strokecolor($bgcol);
	    $gfx->rectxy( $x, $y0, $x1, $y1 )
		->fill;
	    $gfx->restore;
	}

	if ( $chordscol && $chord ne "" ) {
	    my $y = $y - $ps->{lineheight};

	    if ( $chordscapo ) {
		$ps->{pr}->text("Capo: " . $chordscapo,
				$chordsx, $y + $ps->{lineheight},
				$ps->{fonts}->{chord} );
		undef $chordscapo
	    }

	    # Underline the first word of the phrase, to indicate
	    # the actual chord position.
	    $phrase = " " if $phrase eq "";
	    my ( $pre, $word, $rest ) = $phrase =~ /^([^[:alpha:]]*)(.[[:alpha:]]*)(.+)?/;
	    $word = $phrase unless defined $rest;
	    my $x0 = $x;
	    my $w = $ps->{pr}->strwidth( $word, $ftext );
	    $w *= 0.75 unless defined($rest);
	    my $x1 = $x0 = $ps->{pr}->text( $pre, $x0, $y, $ftext ) if defined($pre);
#	    $x0 = $ps->{pr}->textu( $word, $x0, $y, $ftext );
	    $x0 = $ps->{pr}->text( $word, $x0, $y, $ftext );
	    my $gfx = $ps->{pr}->{pdfpage}->gfx;
	    $gfx->save;
	    $gfx->strokecolor("#000000"); # black
	    $gfx->linewidth(0.25);
	    $gfx->move( $x, $y +
			$ps->{pr}->_getfont($ps->{fonts}->{text})->underlineposition/1024*$ftext->{size} );
	    $gfx->hline( $x + $w );
	    $gfx->stroke;
	    $gfx->restore;

	    $x0 = $ps->{pr}->text( $rest, $x0, $y, $ftext ) if defined($rest);
	    $x = $x0;

	    # Chords at the right.
	    push(@chords, $chord);
	}
	else {
	    my $xt0 = $ps->{pr}->text( $chord." ", $x, $y, $fchord );
	    my $xt1 = $ps->{pr}->text( $phrase, $x, $y-$ps->{lineheight}, $ftext );
	    $x = $xt0 > $xt1 ? $xt0 : $xt1;
	}
    }
    $ps->{pr}->text( join(",  ", @chords),
		     $chordsx, $y - $ps->{lineheight}, $fchord )
      if @chords;
    return $y - $vsp->() - ($chordscol ? 0 : $ps->{chordheight});
}

# SMUFL mappings of common symbols.
my %smufl =
  ( brace		=> "\x{e000}",
    reversedBrace	=> "\x{e001}",
    barlineSingle	=> "\x{e030}",
    barlineDouble	=> "\x{e031}",
    barlineFinal	=> "\x{e032}",
    repeatLeft		=> "\x{e040}",
    repeatRight		=> "\x{e041}",
    repeatRightLeft	=> "\x{e042}",
    repeatDots		=> "\x{e043}",
    dalSegno		=> "\x{e045}",
    daCapo		=> "\x{e046}",
    segno		=> "\x{e047}",
    coda		=> "\x{e048}",
    timeSig0		=> "\x{e080}", # timeSig1, ...etc...
    flat		=> "\x{e260}",
    sharp		=> "\x{e262}",
    fermata		=> "\x{e4c0}",
    repeat1Bar		=> "\x{e500}",
    repeat2Bars		=> "\x{e501}",
    repeat4Bars		=> "\x{e502}",
    csymDiminished	=> "\x{e870}",
    csymHalfDiminished	=> "\x{e871}",
    csymAugmented	=> "\x{e872}",
    csymMajorSeventh	=> "\x{e873}",
    csymMinor		=> "\x{e874}",
  );

# Map ASCII bars (and pseudo-bar) to SMUFL code.
my %sbmap =
  ( "|"        => $smufl{barlineSingle},
    "||"       => $smufl{barlineDouble},
    "|."       => $smufl{barlineFinal},
    "|:"       => $smufl{repeatLeft},
    ":|"       => $smufl{repeatRight},
    ":|:"      => $smufl{repeatRightLeft},
    " %"       => $smufl{repeat2Bars},
  );

# Map ASCII and UTF8 measure repeats to SMUFL code.
my %smap =
  ( "%"        => $smufl{repeat1Bar},
    "%%"       => $smufl{repeat2Bars},
    "\x{2030}" => $smufl{repeat2Bars}, # permille
  );

sub is_bar {
#    $_[0] =~ /^(\||\|\||\\|:|:\||\|\.)$/
    $sbmap{$_[0]};
}

sub gridline {
    my ( $elt, $x, $y, $cellwidth, $barwidth, $ps ) = @_;

    # Grid context.

    my $smufl = 0;		# use SMUFL font

    $x += $barwidth/2;

    my $fchord = { %{ $ps->{fonts}->{chord} } };
    delete($fchord->{background});
    my $schord = { %{ $ps->{fonts}->{symbols} } };
    delete($schord->{background});
    $schord->{size} = $fchord->{size};

    $schord = $fchord unless $smufl;

    $elt->{tokens} //= [ '' ];

    my $firstbar;
    my $lastbar;
    foreach my $i ( 0 .. $#{ $elt->{tokens} } ) {
	next unless is_bar( $elt->{tokens}->[$i] );
	$lastbar = $i;
	$firstbar //= $i;
    }

    my $prevbar;
    my @tokens = @{ $elt->{tokens} };
    my $t;
    foreach my $i ( 0 .. $#tokens ) {
	my $token = $tokens[$i];
	if ( $t = is_bar($token) ) {
	    $t = $token unless $smufl;
	    $t = "{" if $t eq "|:";
	    $t = "}" if $t eq ":|";
	    $t = "}{" if $t eq ":|:";
	    my $y = $y;
	    $ps->{pr}->setfont($schord);
	    my @t = ( $t );
	    push( @t, $smufl{barlineSingle} ) if $t eq $smufl{repeat2Bars};
	    for my $t ( @t ) {
		my $w = $ps->{pr}->strwidth($t);
		my $y = $y;
		$y += $schord->{size} / 2 if $t eq $smufl{repeat2Bars};
		if ( defined $firstbar ) {
		    my $x = $x;
		    $x -= $w/2 if $i > $firstbar;
		    $x -= $w/2 if $i == $lastbar;
		    $ps->{pr}->text( $t, $x, $y );
		}
		else {
		    $ps->{pr}->text( $t, $x + $barwidth/2 - $w/2, $y );
		}
	    }
	    $x += $barwidth;
	    $prevbar = $i;
	}
	elsif ( ( $t = $smap{$token} || "" ) eq $smufl{repeat1Bar} ) {
	    $t = $token unless $smufl;
	    my $k = $prevbar + 1;
	    while ( $k <= $#tokens
		    && !is_bar($tokens[$k]) ) {
		$k++;
	    }
	    $ps->{pr}->setfont($schord);
	    my $y = $y;
	    $y += $schord->{size} / 2 if $t eq $smufl{repeat1Bar};
	    my $w = $ps->{pr}->strwidth($t);
	    $ps->{pr}->text( $t,
			     $x + ($k - $prevbar - 1)*$cellwidth/2 - $w/2,
			     $y );
	    $x += $cellwidth;
	}
	elsif ( ( $t = $smap{$token} || "" ) eq $smufl{repeat2Bars} ) {
	    # For repeat2Bars, change the next bar line to pseudo-bar.
	    my $k = $prevbar + 1;
	    while ( $k <= $#tokens
		    && !is_bar($tokens[$k]) ) {
		$k++;
	    }
	    $tokens[$k] = " %";
	    $x += $cellwidth;
	}
	else {
	    $ps->{pr}->setfont($fchord),
	    $ps->{pr}->text( $token, $x, $y )
	      unless $token eq ".";
	    $x += $cellwidth;
	}
    }
    if ( $elt->{comment} ) {
	my $c = $elt->{comment};
	$ps->{pr}->setfont($ps->{fonts}->{comment});
	$c = " " . $c;
	$ps->{pr}->text( $c, $x, $y );
    }
    return $y - $ps->{chordheight} * $ps->{linespace}
      - $ps->{'vertical-space'};
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

    use JSON::PP ();

    my $ret = {};
    if ( open( my $fd, "<:utf8", $options->{pagedefs} || "pagedefs.json" ) ) {
	local $/;
	$ret = JSON::PP->new->utf8->relaxed->decode( scalar( <$fd> ) );
	$fd->close;
    }
    elsif ( $options->{pagedefs} ) {
	die("Cannot open ", $options->{pagedefs}, " [$!]\n");
    }
    my $pd = $ret;

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

    $ret = $ret->{pdf} || {};
    my $def =
      { papersize     => 'a4',		# [w,h], or known name
	marginleft    => 130,		# pt
	margintop     =>  66,		# pt
	marginbottom  =>  40,		# pt
	marginright   =>  40,		# pt
	headspace     =>  20,		# pt
	offsets       => [ 0, 250 ],	# col 1, col 2, pt
	chordscolumn  => 400,		# pt
	linespace     =>   1,		# factor

	# Spacings. All as a factor of the font size * line spacing.
	# Spacing between lyrics lines.
	"inter-lyrics-spacing" => 1.2,
	# Spacing between chords and lyrics lines.
	"inter-chords-lyrics-spacing" => 1.2,
	# Spacing before/after verse.
	"before-verse-spacing" => 1.5,
	"after-verse-spacing" => 1.5,
	# Spacing before/after chorus.
	"before-chorus-spacing" => 1.5,
	"after-chorus-spacing" => 1.5,
	# Spacing before/after tab.
	"before-tab-spacing" => 1.5,
	"after-tab-spacing" => 1.5,
	"inter-tab-spacing" => 1.0,
	# Spacing before/after grid.
	"before-grid-spacing" => 1.5,
	"after-grid-spacing" => 1.5,
	"inter-grid-spacing" => 1.2,
      };

    # Merge fallback values, if necessary.
    # Use Hash::Merge::Simple if anything more complex is required.
    $ret->{$_} ||= $def->{$_} foreach keys(%$def);

    # Map papersize name to [ width, height ].
    unless ( eval { $ret->{papersize}->[0] } ) {
	require PDF::API2::Resource::PaperSizes;
	my %ps = PDF::API2::Resource::PaperSizes->get_paper_sizes;
	die("Unhandled paper size: ", $ret->{papersize}, "\n")
	  unless exists $ps{lc $ret->{papersize}};
	$ret->{papersize} = $ps{lc $ret->{papersize}}
    }

    my $stdfonts =
      { title   => { name => 'Times-Bold',        size => 14 },
	text    => { name => 'Times-Roman',       size => 14 },
	chord   => { name => 'Helvetica-Oblique', size => 10 },
	symbols => { file => '/home/jv/src/Data-iRealPro/res/fonts/Bravura.ttf',      size => 10 },
	tab     => { name => 'Courier',           size => 10 },
      };

    # Use fallback fonts, if necessary.
    $ret->{fonts}->{$_} ||= $stdfonts->{$_} foreach keys(%$stdfonts);

    # Sanitize, if necessary.
    $ret->{fonts}->{subtitle}       ||= $ret->{fonts}->{text};
    $ret->{fonts}->{comment_italic} ||= $ret->{fonts}->{chord};
    $ret->{fonts}->{comment_box}    ||= $ret->{fonts}->{chord};
    $ret->{fonts}->{comment}        ||= $ret->{fonts}->{text};

    # Set default font size.
    if ( $ret->{textsize} ) {
	$_->{size} ||= $ret->{textsize}
	  foreach values( %{ $ret->{fonts} } );
    }

    # Write resultant pagedefds, if needed.
    if ( 0 ) {
	open( my $fd, '>:utf8', 'pagedefs.new' );
	$fd->print(JSON::PP->new->utf8->canonical->indent(4)->pretty->encode($pd));
	$fd->close;
    }

    return $ret;
}

sub showlayout {
    my ( $ps ) = @_;
    return;
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

sub textu {
    my ( $self, $text, $x, $y, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->setfont($font, $size);

    $text = encode( "cp1250", $text ) unless $font->{file};
    $self->{pdftext}->translate( $x, $y );
    return $x + $self->{pdftext}->text($text,
				       -underline => [ 1.5, 0.25 ] );
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
	use Data::Dumper;
	warn(Dumper($font)) unless $font->{name};
	return $fonts{$font->{name}} ||=
	  $self->{pdf}->corefont( $font->{name}, -dokern => 1 );
    }
}

sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $self->{fontsize} || $font->{size};
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
