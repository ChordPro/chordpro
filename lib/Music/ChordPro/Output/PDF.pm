#!/usr/bin/perl

use utf8;

package Music::ChordPro::Output::PDF;

use strict;
use warnings;
use Data::Dumper;

use constant DEBUG_SPACING => 0;

sub generate_songbook {
    my ($self, $sb, $options) = @_;

    my $ps = page_settings( $options );
    my $pr = PDFWriter->new( $ps, $options->{output} || "__new__.pdf" );
    $ps->{pr} = $pr;
    $pr->init_fonts();
    $pr->{pdf}->mediabox( $ps->{papersize}->[0],
			  $ps->{papersize}->[1] );
    my @tm = gmtime(time);
    $pr->info( Title => $sb->{songs}->[0]->{title},
	       Creator => "ChordPro [$options->{_name} $options->{_version}]",
	       CreationDate =>
	       sprintf("D:%04d%02d%02d%02d%02d%02d+00'00'",
		       1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]),
	     );

    my @book;
    my $page = 1;
    foreach my $song ( @{$sb->{songs}} ) {

	$options->{startpage} = $page;
	push( @book, [ $song->{title}, $page ] );
	$page += generate_song( $song, { pr => $pr, $options ? %$options : () } );
    }

    if ( $options->{toc} ) {
	$options->{startpage} = $page;
	my $song =
	  { title => "Contents",
	    structure => "linear",
	    body => [
		     map { +{ type    => "tocline",
			      context => "toc",
			      title   => $_->[0],
			      page    => $_->[1],
			    } } @book,
	    ],
	    meta => {},
	  };
	$page += generate_song( $song, { pr => $pr, $options ? %$options : () } );     }

    $pr->finish;

    []
}

my $structured = 0;		# structured data
my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chord lines
my $chordscol = 0;		# chords in a separate column
my $chordscapo = 0;		# capo in a separate column

use constant SIZE_ITEMS => [ qw (chord text tab grid) ];

sub generate_song {
    my ($s, $options) = @_;

    my $ps = page_settings( $options );
    my $pr = $options->{pr};
    $ps->{pr} = $pr;
    $pr->{ps} = $ps;
    $pr->init_fonts();
    my $fonts = $ps->{fonts};

    my $x = $ps->{marginleft} + $ps->{offsets}->[0];
    my $y = $ps->{papersize}->[1] - $ps->{margintop};

    $structured = ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';
    $s->structurize if $structured;

    my $sb = $s->{body};
    $ps->{column} = 0;
    $ps->{columns} = $s->{settings}->{columns} || 1;
    $ps->{columns} = @{$ps->{offsets}}
      if $ps->{columns} > @{$ps->{offsets}};
    my $st = $s->{settings}->{titles} || "left";

    $single_space = $options->{'single-space'} || $ps->{'suppress-empty-chords'};
    $chordscol = $options->{'chords-column'} || $ps->{chordscolumn};
    $lyrics_only = 2 * $options->{'lyrics-only'};
    $chordscapo = $s->{meta}->{capo};

    my $fail;
    for my $item ( @{ SIZE_ITEMS() } ) {
	for ( $options->{"$item-font"} ) {
	    next unless $_;
	    delete( $fonts->{$item}->{file} );
	    delete( $fonts->{$item}->{name} );
	    $fonts->{$item}->{ m;/; ? "file" : "name" } = $_;
	    $pr->init_font($item) or $fail++;
	}
	for ( $options->{"$item-size"} ) {
	    next unless $_;
	    $fonts->{$item}->{size} = $_;
	}
    }
    die("Unhandled fonts detected -- aborted\n") if $fail;

    my $set_sizes = sub {
	$ps->{lineheight} = $fonts->{text}->{size} - 1; # chordii
	$ps->{chordheight} = $fonts->{chord}->{size};
    };
    $set_sizes->();
    $ps->{'vertical-space'} = $options->{'vertical-space'};
    for ( @{ SIZE_ITEMS() } ) {
	$fonts->{$_}->{_size} = $fonts->{$_}->{size};
    }

    my $show = sub {
	my ( $text, $font ) = @_;
	my $x = $x;
	if ( $st eq "right" ) {
	    $pr->setfont($font);
	    $x = $ps->{papersize}->[0]
		 - $ps->{marginright}
		 - $pr->strwidth($text);
	}
	elsif ( $st eq "center" || $st eq "centre" ) {
	    $pr->setfont($font);
	    $x = $ps->{marginleft} +
	         ( $ps->{papersize}->[0]
		   - $ps->{marginright}
		   - $ps->{marginleft}
		   - $pr->strwidth($text) ) / 2;
	}
	$pr->text( $text, $x, $y-font_bl($font), $font );
	$y -= $font->{size} * $ps->{spacing}->{title};
    };

    my $do_size = sub {
	my ( $tag, $value ) = @_;
	if ( $value =~ /^(.+)\%$/ ) {
	    $fonts->{$tag}->{size} =
	      ( $1 / 100 ) * $fonts->{$tag}->{_size};
	}
	else {
	    $fonts->{$tag}->{size} =
	      $fonts->{$tag}->{_size} = $value;
	}
	$set_sizes->();
    };

    my $y0;
    my $col;
    my $vsp_ignorefirst;
    my $startpage = $options->{startpage} || 1;
    my $thispage = $startpage - 1;

    my $newpage = sub {
	$pr->newpage($ps);
	showlayout($ps) if $ps->{showlayout};
	$x = $ps->{marginleft} + $ps->{offsets}->[$col = 0];
	$y = $ps->{papersize}->[1] - $ps->{margintop} + $ps->{headspace};

	if ( ++$thispage == $startpage ) {
	    $show->( $s->{title}, $fonts->{title} )
	      if $s->{title};
	    if ( $s->{subtitle} ) {
		for ( @{$s->{subtitle}} ) {
		    $show->( $_, $fonts->{subtitle} );
		}
	    }
	}
	elsif ( $s->{title} ) {
	    $y = $ps->{marginbottom} - $ps->{footspace};
	    $pr->setfont( $fonts->{footer} );
	    $pr->text( $s->{title}, $ps->{marginleft}, $y );
	}
	if ( $thispage > 1 ) {
	    $y = $ps->{marginbottom} - $ps->{footspace};
	    my $t = "Page " . $thispage;
	    $pr->setfont( $fonts->{footer} );
	    $pr->text( $t, $ps->{papersize}->[0] - $ps->{marginright} - $pr->strwidth($t), $y );
	}

	$y0 = $y = $ps->{papersize}->[1] - $ps->{margintop};
	$col = 0;
	$vsp_ignorefirst = 1;
    };
    $newpage->();

    my $checkspace = sub {
	my $vsp = $_[0];
	$newpage->(), return if $y - $vsp <= $ps->{marginbottom};
	return 1;
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

	if ( $elt->{type} eq "newpage" ) {
	    $newpage->();
	    next;
	}

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
	    next if $vsp_ignorefirst--;
	    $pr->show_vpos( $y, 0 ) if DEBUG_SPACING;
	    my $vsp = text_vsp( $elt, $ps );
	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if DEBUG_SPACING;
	    next;
	}

	# Collect chorus elements so they can be recalled.
	if ( $elt->{context} eq "chorus" ) {
	    @chorus = () unless $prev && $prev->{context} eq "chorus";
	    push( @chorus, $elt );
	}

	if ( $elt->{type} eq "songline"
	     or $elt->{type} eq "tabline"
	     or $elt->{type} =~ /^comment(?:_box|_italic)?$/ ) {

	    my $fonts = $ps->{fonts};
	    my $type   = $elt->{type};

	    my $ftext;
	    if ( $type eq "songline" ) {
		$ftext = $fonts->{text};
	    }
	    elsif ( $type =~ /^comment/ ) {
		$ftext = $fonts->{$type} || $fonts->{comment};
	    }

	    # Get vertical space the songline will occupy.
	    my $vsp = songline_vsp( $elt, $ps );

	    # Add prespace if fit. Otherwise newpage.
	    $checkspace->($vsp);

	    $pr->show_vpos( $y, 0 ) if DEBUG_SPACING;

	    my $indent = 0;

	    # Handle decorations.

	    if ( $elt->{context} eq "chorus" ) {
		if ( $ps->{chorustype} eq "indent" ) {
		    $indent = $ps->{'chorus-indent'};
		}
		if ( $ps->{chorustype} eq "bar" ) {
		    my $cx = $ps->{marginleft}
		      + $ps->{offsets}->[$col]
			- $ps->{'chorus-bar-offset'};
		    $pr->{pdfgfx}
		      ->move( $cx, $y )
			->linewidth(1)
			  ->vline( $y - $vsp )
			    ->stroke;
		}
	    }

	    # Comment decorations.

	    my $font = $fonts->{$elt->{type}} || $fonts->{comment};
	    $pr->setfont( $font );
	    my $text = $elt->{text};
	    my $w = $pr->strwidth( $text );
	    my $x1 = $x + $w;
	    my $gfx = $pr->{pdfpage}->gfx(1); # under

	    # Draw background.
	    my $bgcol = $font->{background};
	    $bgcol ||= "#E5E5E5" if $elt->{type} eq "comment";
	    if ( $bgcol ) {
		$gfx->save;
		$gfx->fillcolor($bgcol);
		$gfx->strokecolor($bgcol);
		$gfx
		  ->rectxy( $x, $y, $x + $w, $y - $vsp )
		    ->linewidth(3)
		      ->fillstroke;
		$gfx->restore;
	    }

	    # Draw box.
	    if ( $elt->{type} eq "comment_box" ) {
		$gfx->save;
		$gfx->strokecolor("#000000"); # black
		$gfx
		  ->rectxy( $x - 1, $y - 1, $x + $w + 1, $y - $vsp + 1 )
		    ->linewidth(1)
		      ->stroke;
		$gfx->restore;
	    }

	    songline( $elt, $x, $y, $ps, indent => $indent );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if DEBUG_SPACING;

	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    warn("NYI: type => chorus\n");
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
	    my $cx = $ps->{marginleft} + $ps->{offsets}->[$col] - $ps->{'chorus-bar-offset'};
	    $pr->{pdfgfx}
	      ->move( $cx, $cy )
	      ->linewidth(1)
	      ->vline( $y + vsp($ps))
	      ->stroke;
	    $y -= vsp($ps,4); # chordii
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    warn("NYI: type => verse\n");
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

	    my $vsp = grid_vsp( $elt, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if DEBUG_SPACING;

	    gridline( $elt, $x, $y,
		      $grid_cellwidth, $grid_barwidth, $ps );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if DEBUG_SPACING;

	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    warn("NYI? tab\n");
	    $pr->setfont( $fonts->{tab} );
	    my $dy = $fonts->{tab}->{size};
	    foreach my $e ( @{$elt->{body}} ) {
		next unless $e->{type} eq "tabline";
		$pr->text( $e->{text}, $x, $y );
		$y -= $dy;
	    }
	    next;
	}

	if ( $elt->{type} eq "tabline" ) {

	    my $vsp = tab_vsp( $elt, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if DEBUG_SPACING;

	    songline( $elt, $x, $y, $ps );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if DEBUG_SPACING;

	    next;
	}

	if ( $elt->{type} eq "image" ) {
	    my $opts = $elt->{opts};

	    my $img;
	    for ( $elt->{uri} ) {
		$img = $pr->{pdf}->image_png($_)  if /\.png$/i;
		$img = $pr->{pdf}->image_jpeg($_) if /\.jpe?g$/i;
		$img = $pr->{pdf}->image_gif($_)  if /\.gif$/i;
	    }
	    unless ( $img ) {
		warn("Unhandled image type: ", $elt->{uri}, "\n");
		next;
	    }

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

	    $checkspace->($h);
	    $pr->show_vpos( $y, 0 ) if DEBUG_SPACING;

	    my $gfx = $pr->{pdfpage}->gfx(1); # under
	    $gfx->save;
	    $gfx->image( $img, $x, $y-$h, $w, $h );
	    if ( $opts->{border} ) {
		$gfx->rect( $x, $y-$h, $w, $h )
		  ->linewidth($opts->{border})
		    ->stroke;
	    }
	    $gfx->restore;

	    $y -= $h;
	    $pr->show_vpos( $y, 1 ) if DEBUG_SPACING;

	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    unshift( @elts, @chorus );
	    next;
	}

	if ( $elt->{type} eq "tocline" ) {
	    my $vsp = toc_vsp( $elt, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if DEBUG_SPACING;

	    tocline( $elt, $x, $y, $ps );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if DEBUG_SPACING;
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

    return $thispage - $startpage + 1;
}

sub font_bl {
    my ( $font ) = @_;
    $font->{size} / ( 1 - $font->{font}->descender / $font->{font}->ascender );
}

sub font_ul {
    my ( $font ) = @_;
    $font->{font}->underlineposition / 1024 * $font->{size};
}

sub songline {
    my ( $elt, $x, $ytop, $ps, %opts ) = @_;

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
    # Likewise comments and tabs (which may have different fonts /
    # decorations).
    #
    # And:
    #
    # +-----------------------+-------
    # |  Lyrics text          | C F G
    # +-----------------------+-------
    #
    # Note that printing text involves baselines, and that chords
    # may have a different height than lyrics.
    #
    # To find the upper/lower extents, the ratio
    #
    #  $font->ascender / $font->descender
    #
    # can be used. E.g., a font of size 16 with descender -250 and
    # ascender 750 must be drawn at 12 points under $ytop.

    my $pr    = $ps->{pr};
    my $fonts = $ps->{fonts};

    my $type   = $elt->{type};

    my $ftext;
    my $ytext;

    if ( $type =~ /^comment/ ) {
	$ftext = $fonts->{$type} || $fonts->{comment};
	$ytext  = $ytop - font_bl($ftext);
	$x += $opts{indent} if $opts{indent};
	$pr->text( $elt->{text}, $x, $ytext, $ftext );
	return;
    }
    if ( $type eq "tabline" ) {
	$ftext = $fonts->{tab};
	$ytext  = $ytop - font_bl($ftext);
	$x += $opts{indent} if $opts{indent};
	$pr->text( $elt->{text}, $x, $ytext, $ftext );
	return;
    }

    # assert $type eq "songline";
    $ftext = $fonts->{text};
    $ytext  = $ytop - font_bl($ftext); # unless lyrics AND chords

    my $fchord = $fonts->{chord};
    my $ychord = $ytop - font_bl($fchord);

    # Just print the lyrics if no chords.
    if ( $lyrics_only
	 or
	 $single_space && !has_visible_chords($elt)
       ) {
	my $x = $x;
	$x += $opts{indent} if $opts{indent};
	$pr->text( join( "", @{ $elt->{phrases} } ), $x, $ytext, $ftext );
	return;
    }

    if ( $chordscol ) {
	$ytext  = $ychord if $ytext  > $ychord;
	$ychord = $ytext;
    }
    else {
	# Adjust lyrics baseline for the chords.
	$ytext -= $ps->{fonts}->{chord}->{size}
	          * $ps->{spacing}->{chords}
    }

    $elt->{chords} //= [ '' ];

    my $chordsx = $x + $ps->{chordscolumn};
    if ( $chordsx < 0 ) {	#### EXPERIMENTAL
	($x, $chordsx) = (-$chordsx, $x);
    }
    $x += $opts{indent} if $opts{indent};

    my @chords;
    foreach ( 0..$#{$elt->{chords}} ) {

	my $chord = $elt->{chords}->[$_];
	my $phrase = $elt->{phrases}->[$_];

	if ( $fchord->{background} && $chord ne "" && !$chordscol ) {
	    # Draw background.
	    my $w = $pr->strwidth( $chord." ", $fchord );
	    my $y1 = $ytop - $fchord->{size};
	    my $bgcol = $fchord->{background};
	    my $x1 = $x + $w - $pr->strwidth(" ")/2;
	    my $x = $x - $pr->strwidth(" ")/2;
	    my $gfx = $pr->{pdfpage}->gfx(1); # under
	    $gfx->save;
	    $gfx->fillcolor($bgcol);
	    $gfx->strokecolor($bgcol);
	    $gfx->rectxy( $x, $ytop, $x1, $y1 );
	    $gfx->fill;
	    $gfx->restore;
	}

	if ( $chordscol && $chord ne "" ) {

	    if ( $chordscapo ) {
		$pr->text("Capo: " . $chordscapo,
			  $chordsx,
			  $ytext + $ftext->{size} *
			      $ps->{spacing}->{chords},
			  $fonts->{chord} );
		undef $chordscapo;
	    }

	    # Underline the first word of the phrase, to indicate
	    # the actual chord position. Skip leading non-letters.
	    $phrase = " " if $phrase eq "";
	    my ( $pre, $word, $rest ) = $phrase =~ /^(\W+)?(\w+)(.+)?$/;
	    my $ulstart = $x;
	    $ulstart += $pr->strwidth($pre) if defined($pre);
	    my $w = $pr->strwidth( $word, $ftext );
	    # Avoid running together of syllables.
	    $w *= 0.75 unless defined($rest);

	    my $gfx = $pr->{pdfpage}->gfx;
	    $gfx->save;
	    $gfx->strokecolor("#000000"); # black
	    $gfx->linewidth(0.25);
	    $gfx->move( $ulstart, $ytext + font_ul($ftext) );
	    $gfx->hline( $ulstart + $w );
	    $gfx->stroke;
	    $gfx->restore;

	    # Print the text.
	    $x = $pr->text( $phrase, $x, $ytext, $ftext );

	    # Collect chords to be printed in the side column.
	    push(@chords, $chord);
	}
	else {
	    my $xt0 = $pr->text( $chord." ", $x, $ychord, $fchord );
	    my $xt1 = $pr->text( $phrase, $x, $ytext, $ftext );
	    $x = $xt0 > $xt1 ? $xt0 : $xt1;
	}
    }

    # Print side column with chords, if any.
    $pr->text( join(",  ", @chords),
	       $chordsx, $ychord, $fchord )
      if @chords;

    return;
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

    my $pr = $ps->{pr};
    my $fonts = $ps->{fonts};

    my $smufl = 0;		# use SMUFL font

    $x += $barwidth/2;

    my $fchord = { %{ $fonts->{chord} } };
    delete($fchord->{background});
    my $schord = { %{ $fonts->{symbols} } };
    delete($schord->{background});
    $schord->{size} = $fchord->{size};

    $schord = $fchord unless $smufl;

    $y -= font_bl($fchord);

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
	    $pr->setfont($schord);
	    my @t = ( $t );
	    push( @t, $smufl{barlineSingle} ) if $t eq $smufl{repeat2Bars};
	    for my $t ( @t ) {
		my $w = $pr->strwidth($t);
		my $y = $y;
		$y += $schord->{size} / 2 if $t eq $smufl{repeat2Bars};
		if ( defined $firstbar ) {
		    my $x = $x;
		    $x -= $w/2 if $i > $firstbar;
		    $x -= $w/2 if $i == $lastbar;
		    $pr->text( $t, $x, $y );
		}
		else {
		    $pr->text( $t, $x + $barwidth/2 - $w/2, $y );
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
	    $pr->setfont($schord);
	    my $y = $y;
	    $y += $schord->{size} / 2 if $t eq $smufl{repeat1Bar};
	    my $w = $pr->strwidth($t);
	    $pr->text( $t,
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
	    $pr->text( $token, $x, $y, $fchord )
	      unless $token eq ".";
	    $x += $cellwidth;
	}
    }
    if ( $elt->{comment} ) {
	$pr->text( " " . $elt->{comment}, $x, $y, $fonts->{comment} );
    }
}

sub tocline {
    my ( $elt, $x, $y, $ps ) = @_;

    my $pr = $ps->{pr};
    my $fonts = $ps->{fonts};
    my $y0 = $y;

    my $ftoc = $fonts->{text};
    $y -= font_bl($ftoc);
    $pr->setfont($ftoc);
    $ps->{pr}->text( $elt->{title}, $x, $y );
    my $p = "" . $elt->{page};
    $ps->{pr}->text( $p,
		     $ps->{papersize}->[0]
		     - $ps->{marginleft}
		     - $pr->strwidth($p),
		     $y );

    my $ann = $pr->{pdfpage}->annotation;
    $ann->link($pr->{pdf}->openpage($elt->{page}));
    $ann->rect( $ps->{marginleft}, $y0 - $ftoc->{size},
		$ps->{papersize}->[0]-$ps->{marginright}, $y0 );
}

sub has_visible_chords {
    my ( $elt ) = @_;
    $elt->{chords} && join( "", @{ $elt->{chords} } ) =~ /\S/;
}

sub songline_vsp {
    my ( $elt, $ps ) = @_;

    # Calculate the vertical span of this songline.
    my $fonts = $ps->{fonts};

    if ( $elt->{type} =~ /^comment/ ) {
	my $ftext = $fonts->{$elt->{type}} || $fonts->{comment};
	return $ftext->{size} * $ps->{spacing}->{lyrics};
    }
    if ( $elt->{type} eq "tabline" ) {
	my $ftext = $fonts->{tab};
	return $ftext->{size} * $ps->{spacing}->{tab};
    }

    # Vertical span of the lyrics.
    my $vsp = $fonts->{text}->{size} * $ps->{spacing}->{lyrics};

    return $vsp if $lyrics_only || $chordscol;

    return $vsp if $single_space && ! has_visible_chords($elt);

    # We must show chords above lyrics, so add chords span.
    $vsp + $fonts->{chord}->{size} * $ps->{spacing}->{chords};
}

sub _vsp {
    my ( $eltype, $ps, $itype ) = @_;
    $itype ||= $eltype;

    # Calculate the vertical span of this element.

    my $font = $ps->{fonts}->{$eltype};
    $font->{size} * $ps->{spacing}->{$itype};
}

sub grid_vsp { _vsp( "grid", $_[1] ) }
sub tab_vsp  { _vsp( "tab",  $_[1] ) }
sub toc_vsp  { _vsp( "toc",  $_[1] ) }

sub text_vsp {
    my ( $elt, $ps ) = @_;

    # Calculate the vertical span of this line.

    return 0 if $elt->{type} eq "empty" && $structured;

    _vsp( "text", $ps, "lyrics" );
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
	marginleft    =>  60,		# pt
	margintop     =>  90,		# pt
	marginbottom  =>  40,		# pt
	marginright   =>  40,		# pt
	headspace     =>  50,		# pt
	footspace     =>  20,		# pt
	offsets       => [ 0, 250 ],	# col 1, col 2, pt
	chordscolumn  =>   0,		# pt
#	chordscolumn  => 300,		# pt

#	chorustype    => 'bar',
	chorustype    => 'indent',
	'chorus-bar-offset' => 8,
	'chorus-indent' => 20,

	# Spacings. Baseline distances as a factor of the font size.
	spacing => {
		    title   => 1.2,
		    lyrics  => 1.2,
		    chords  => 1.2,
		    tab	    => 1.0,
		    toc	    => 1.4,
		    grid    => 1.2,
	},

	'suppress-empty-chords' => 1,

	fonts => {
	    title   => { name => 'Times-Bold',        size => 14 },
	    text    => { name => 'Times-Roman',       size => 14 },
	    chord   => { name => 'Helvetica-Oblique', size => 10 },
	    symbols => { file => '/home/jv/src/Data-iRealPro/res/fonts/Bravura.ttf',
			 size => 10 },
	    tab     => { name => 'Courier',           size => 10 },
	},

	# For development.
#	showlayout => 1,
      };

    # Merge defaultvalues, if necessary.
    $ret = $pd->{pdf} = hmerge( $def, $ret );

    # Map papersize name to [ width, height ].
    unless ( eval { $ret->{papersize}->[0] } ) {
	require PDF::API2::Resource::PaperSizes;
	my %ps = PDF::API2::Resource::PaperSizes->get_paper_sizes;
	die("Unhandled paper size: ", $ret->{papersize}, "\n")
	  unless exists $ps{lc $ret->{papersize}};
	$ret->{papersize} = $ps{lc $ret->{papersize}}
    }

    # Sanitize, if necessary.
    $ret->{fonts}->{subtitle}       ||= { %{ $ret->{fonts}->{text}  } };
    $ret->{fonts}->{comment_italic} ||= { %{ $ret->{fonts}->{chord} } };
    $ret->{fonts}->{comment_box}    ||= { %{ $ret->{fonts}->{chord} } };
    $ret->{fonts}->{comment}        ||= { %{ $ret->{fonts}->{text}  } };
    $ret->{fonts}->{toc}	    ||= { %{ $ret->{fonts}->{text}  } };
    $ret->{fonts}->{grid}           ||= { %{ $ret->{fonts}->{chord} } };

    # Default footer is small subtitle.
    unless ( $ret->{fonts}->{footer} ) {
	$ret->{fonts}->{footer} = { %{ $ret->{fonts}->{subtitle} } };
	$ret->{fonts}->{footer}->{size}
	  = 0.6 * $ret->{fonts}->{subtitle}->{size};
    }

    # Write resultant pagedefs, if needed.
    my $pd_new = "pagedefs.new";
    if ( -e $pd_new && ! -s _ ) {
	open( my $fd, '>:utf8', $pd_new );
	$fd->print(JSON::PP->new->utf8->canonical->indent(4)->pretty->encode($pd));
	$fd->close;
    }

    return $ret;
}

sub showlayout {
    my ( $ps ) = @_;
    my $pr = $ps->{pr};

    $pr->{pdfgfx}
      ->linewidth(0.5)
	->rectxy( $ps->{marginleft},
		  $ps->{marginbottom},
		  $ps->{papersize}->[0]-$ps->{marginright},
		  $ps->{papersize}->[1]-$ps->{margintop} )
	  ->stroke;

    $pr->{pdfgfx}
      ->linewidth(0.5)
	->move( $ps->{marginleft},
		$ps->{papersize}->[1]-$ps->{margintop}+$ps->{headspace} )
	  ->hline( $ps->{papersize}->[0]-$ps->{marginright} )
	    ->stroke;

    $pr->{pdfgfx}
      ->linewidth(0.5)
	->move( $ps->{marginleft},
		$ps->{marginbottom}-$ps->{footspace} )
	  ->hline( $ps->{papersize}->[0]-$ps->{marginright} )
	    ->stroke;

    my @off = @{ $ps->{offsets} };
    @off = ( $ps->{chordscolumn} ) if $ps->{chordscolumn};
    foreach my $i ( 0 .. @off-1 ) {
	next unless $off[$i];
	$ps->{pr}->{pdfgfx}
	  ->linewidth(0.25)
	    ->move( $ps->{marginleft}+$off[$i],
		    $ps->{marginbottom} )
	      ->vline( $ps->{papersize}->[1]-$ps->{margintop} )
		->stroke;
    }
}

sub hmerge {

    # Merge hashes. Right takes precedence.
    # Based on Hash::Merge::Simple by Robert Krimen.

    my ( @hashes ) = @_;
    my $left = shift(@hashes);

    return $left unless @hashes;

    return merge( $left, hmerge(@hashes) ) if @hashes > 1;

    my $right = shift(@hashes);

    my %res = %$left;

    for my $key ( keys(%$right) ) {

        if ( ref($right->{$key}) eq 'HASH'
	     and
	     ref($left->{$key}) eq 'HASH' ) {

	    # Both hashes. Recurse.
            $res{$key} = hmerge( $left->{$key}, $right->{$key} );
        }
        else {
            $res{$key} = $right->{$key};
        }
    }

    return \%res;
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
#    $self->newpage($ps);
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
    $self->{pdftext}->font( $font->{font}, $size );
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

sub init_fonts {
    my ( $self ) = @_;
    my $ps = $self->{ps};
    my $fail;

    foreach my $ff ( keys( %{ $ps->{fonts} } ) ) {
	$self->init_font($ff) or $fail++;
    }
    die("Unhandled fonts detected -- aborted\n") if $fail;
}

my %fontcache;			# speeds up 2 seconds per song

sub init_font {
    my ( $self, $ff ) = @_;
    my $ps = $self->{ps};

    my $font = $ps->{fonts}->{$ff};
    if ( $font->{file} ) {
	if ( $font->{file} =~ /\.[ot]tf$/ ) {
	    $font->{font} =
	      $fontcache{$font->{file}} ||=
	      $self->{pdf}->ttfont( $font->{file},
				    -dokern => 1 );
	}
	elsif ( $font->{file} =~ /\.pf[ab]$/ ) {
	    $font->{font} =
	      $fontcache{$font->{file}} ||=
	      $self->{pdf}->psfont( $font->{file},
				    -afmfile => $font->{metrics},
				    -dokern  => 1 );
	}
	else {
	    $font->{font} =
	      $fontcache{"__default__"} ||=
	      $self->{pdf}->corefont( 'Courier' );
	}
    }
    else {
	$font->{font} =
	  $fontcache{"__core__".$font->{name}} ||=
	  $self->{pdf}->corefont( $font->{name}, -dokern => 1 );
    }

    unless ( $font->{font} ) {
	warn( "Unhandled $ff font: ",
	      $font->{file}
	      || $font->{name}
	      || Dumper($font), "\n" );
    }
    $font->{font};
}

sub show_vpos {
    my ( $self, $y, $w ) = @_;
    $self->{pdfgfx}->move(100*$w,$y)->linewidth(0.25)->hline(100*(1+$w))->stroke;
}

1;
