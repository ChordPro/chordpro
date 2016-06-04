#!/usr/bin/perl

use utf8;

package App::Music::ChordPro::Output::PDF;

use strict;
use warnings;
use Data::Dumper;

use constant DEBUG_SPACING => 0;

sub generate_songbook {
    my ($self, $sb, $options) = @_;

    my $ps = $::config->{pdf};
    my $pr = PDFWriter->new( $ps, $options->{output} || "__new__.pdf" );
    $pr->info( Title => $sb->{songs}->[0]->{title},
	       Creator => "ChordPro [$options->{_name} $options->{_version}]",
	     );

    my @book;
    my $page = $options->{"start-page-number"} || 1;
    foreach my $song ( @{$sb->{songs}} ) {

	$options->{startpage} = $page;
	push( @book, [ $song->{title}, $page ] );
	$page += generate_song( $song,
				{ pr => $pr, $options ? %$options : () } );
    }

    if ( $options->{toc} ) {

	$pr->newpage($ps), $page++
	  if $ps->{'even-pages-number-left'} && $page % 2 == 0;

	# Create a pseudo-song for the table of contents.
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
	$page += generate_song( $song,
				{ pr => $pr, $options ? %$options : () } );     }

    $pr->finish;

    []
}

my $structured = 0;		# structured data
my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chord lines
my $chordscol = 0;		# chords in a separate column
my $chordscapo = 0;		# capo in a separate column

use constant SIZE_ITEMS => [ qw (chord text tab grid toc title footer) ];

sub generate_song {
    my ($s, $options) = @_;

    my $ps = $::config->clone->{pdf};
    my $pr = $options->{pr};
    $ps->{pr} = $pr;
    $pr->{ps} = $ps;
    $pr->init_fonts();
    my $fonts = $ps->{fonts};

    $structured = ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';
    $s->structurize if $structured;

    my $sb = $s->{body};
    my $st = $s->{settings}->{titles} || $ps->{"titles-flush"};

    set_columns( $ps, $s->{settings}->{columns} );

    $single_space = $ps->{'suppress-empty-chords'};
    $chordscol    = $ps->{chordscolumn};
    $lyrics_only  = $ps->{'lyrics-only'};
    $chordscapo   = $s->{meta}->{capo};

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

    my $x = $ps->{marginleft} + $ps->{columnoffsets}->[0];
    my $y = $ps->{papersize}->[1] - $ps->{margintop};

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
	$x = $ps->{marginleft} + $ps->{columnoffsets}->[$col = 0];
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
	    my $t = "" . $thispage;
	    $pr->setfont( $fonts->{footer} );
	    if ( $ps->{"even-pages-number-left"} && $thispage % 2 == 0 ) {
		$pr->text( $t, $x, $y );
	    }
	    else {
		$pr->text( $t, $ps->{papersize}->[0] - $ps->{marginright} - $pr->strwidth($t), $y );
	    }
	}

	$y0 = $y = $ps->{papersize}->[1] - $ps->{margintop};
	$col = 0;
	$vsp_ignorefirst = 1;
    };
    $newpage->();

    my $checkspace = sub {

	# Verify that the amount of space if still available.
	# If not, perform a column break or page break.
	# Use negative argument to force a break.
	# Returns true if there was space.

	my $vsp = $_[0];
	return 1 if $vsp >= 0 && $y - $vsp >= $ps->{marginbottom};

	if ( ++$col >= $ps->{columns}) {
	    $newpage->();
	}
	else {
	    $x = $ps->{marginleft} + $ps->{columnoffsets}->[$col];
	    $y = $y0;
	}

	return;
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
	    $checkspace->(-1);
	    next;
	}

	if ( $elt->{type} eq "empty" ) {
	    my $y0 = $y;
	    warn("***SHOULD NOT HAPPEN1***")
	      if $s->{structure} eq "structured";
	    $vsp_ignorefirst = 0, next if $vsp_ignorefirst;
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
		$indent = $ps->{'chorus-indent'};
		if ( $ps->{'chorus-bar-offset'} ) {
		    my $cx = $ps->{marginleft}
		      + $ps->{columnoffsets}->[$col]
			- $ps->{'chorus-bar-offset'}
			  + $indent;
		    my $gfx = $pr->{pdfgfx};
		    $gfx->save;
		    $gfx->linewidth($ps->{'chorus-bar-width'});
		    $gfx->strokecolor($ps->{'chorus-bar-color'});
		    $gfx
		      ->move( $cx, $y )
			->vline( $y - $vsp )
			  ->stroke;
		    $gfx->restore;
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
		$gfx->strokecolor("black");
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
	    my $cx = $ps->{marginleft}
	      + $ps->{columnoffsets}->[$col] - $ps->{'chorus-bar-offset'};
	    $pr->{pdfgfx}
	      ->save
	      ->move( $cx, $cy )
	      ->linewidth(1)
	      ->strokecolor($ps->{'chorus-bar-color'})
	      ->vline( $y + vsp($ps))
	      ->stroke
	      ->restore;
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

	    # Slightly more complex.
	    # Only after establishing the desired height we can issue
	    # the checkspace call, and we must get $y after that.

	    my $gety = sub {
		my $h = shift;
		$checkspace->($h);
		$ps->{pr}->show_vpos( $y, 1 ) if DEBUG_SPACING;
		return $y;
	    };

	    my $vsp = imageline( $elt, $x, $ps, $gety );

	    $y -= $vsp;
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
	    if ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-size$/ ) {
		$do_size->( $1, $elt->{value} );
	    }
	    elsif ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-font$/ ) {
		my $f = $1;
		if ( $elt->{value} =~ m;/; ) {
		    $ps->{fonts}->{$1}->{file} = $elt->{value};
		}
		else {
		    $ps->{fonts}->{$1}->{name} = $elt->{value};
		}
		$pr->init_font($ps->{fonts}->{$f});
	    }
	    elsif ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-color$/ ) {
		$ps->{fonts}->{$1}->{color} = $elt->{value};
	    }
	    elsif ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	    elsif ( $elt->{name} eq "chords-column" ) {
		$chordscol = $elt->{value}
		  unless $chordscol > 1; ####TODO
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
	    $gfx->strokecolor("black");
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

sub imageline_vsp {
}

sub imageline {
    my ( $elt, $x, $ps, $gety ) = @_;

    my $opts = $elt->{opts};
    my $pr = $ps->{pr};

    my $img;
    for ( $elt->{uri} ) {
	$img = $pr->{pdf}->image_png($_)  if /\.png$/i;
	$img = $pr->{pdf}->image_jpeg($_) if /\.jpe?g$/i;
	$img = $pr->{pdf}->image_gif($_)  if /\.gif$/i;
    }
    unless ( $img ) {
	warn("Unhandled image type: ", $elt->{uri}, "\n");
	return 0;
    }

    # Available width and height.
    my $pw;
    if ( @{$ps->{columnoffsets}} > 1 ) {
	$pw = $ps->{columnoffsets}->[1]
	  - $ps->{columnoffsets}->[0]
	    - $ps->{columnspace};
    }
    else {
	$pw = $ps->{papersize}->[0]
	  - $ps->{marginleft}
	    - $ps->{marginright};
    }

    my $ph = $ps->{papersize}->[1] - $ps->{margintop} - $ps->{marginbottom};

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
    $x += ($pw - $w) / 2 if $opts->{center} // 1;

    my $y = $gety->($h);	# may have been changed by checkspace

    my $gfx = $ps->{pr}->{pdfpage}->gfx(1); # under

    $gfx->save;
    $gfx->image( $img, $x, $y-$h, $w, $h );
    if ( $opts->{border} ) {
	$gfx->rect( $x, $y-$h, $w, $h )
	  ->linewidth($opts->{border})
	    ->stroke;
    }
    $gfx->restore;

    return $h;			# vertical size
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

sub set_columns {
    my ( $ps, $cols ) = @_;
    $ps->{columns} = $cols ||= 1;
    $ps->{columnoffsets} = [ 0 ];
    return unless $cols > 1;

    my $w = $ps->{papersize}->[0]
      - $ps->{marginright} - $ps->{marginleft};
    my $d = ( $w - ( $cols - 1 ) * $ps->{columnspace} ) / $cols;
    $d += $ps->{columnspace};
    for ( 1 .. $cols-1 ) {
	push( @{ $ps->{columnoffsets} }, $_ * $d );
    }
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

    my @off = @{ $ps->{columnoffsets} };
    @off = ( $ps->{chordscolumn} ) if $ps->{chordscolumn};
    foreach my $i ( 0 .. @off-1 ) {
	next unless $off[$i];
	$ps->{pr}->{pdfgfx}
	  ->linewidth(0.25)
	    ->move( $ps->{marginleft}+$off[$i],
		    $ps->{marginbottom} )
	      ->vline( $ps->{papersize}->[1]-$ps->{margintop} )
		->stroke;
	$ps->{pr}->{pdfgfx}
	  ->linewidth(0.25)
	    ->move( $ps->{marginleft}+$off[$i]-$ps->{columnspace},
		    $ps->{marginbottom} )
	      ->vline( $ps->{papersize}->[1]-$ps->{margintop} )
		->stroke;
    }
}

sub configurator {
    my ( $cfg, $options ) = @_;

    # From here, we're mainly dealing with the PDF settings.
    my $pdf   = $cfg->{pdf};
    my $fonts = $pdf->{fonts};

    # Apply Chordii command line compatibility.

    # Command line only takes text and chord fonts.
    for my $type ( qw( text chord ) ) {
	for ( $options->{"$type-font"} ) {
	    next unless $_;
	    if ( m;/; ) {
		$fonts->{$type}->{file} = $_;
	    }
	    else {
		$fonts->{$type}->{name} = $_;
	    }
	}
	for ( $options->{"$type-size"} ) {
	    $fonts->{$type}->{size} = $_ if $_;
	}
    }

    for ( $options->{"page-size"} ) {
	$pdf->{papersize} = $_ if $_;
    }
    for ( $options->{"vertical-space"} ) {
	next unless $_;
	$pdf->{spacing}->{lyrics} +=
	  $_ / $fonts->{text}->{size};
    }
    for ( $options->{"lyrics-only"} ) {
	next unless defined $_;
	# If set on the command line, it cannot be overridden
	# by pagedefs and {controls}.
	$pdf->{"lyrics-only"} = 2 * $_;
    }
    for ( $options->{"single-space"} ) {
	next unless defined $_;
	$pdf->{"suppress-empty-chords"} = $_;
    }
    for ( $options->{"even-pages-number-left"} ) {
	next unless defined $_;
	$pdf->{"even-pages-number-left"} = $_;
    }

    # Add font dirs.
    my $fontdir = $pdf->{fontdir} || $ENV{FONTDIR};
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

    # Map papersize name to [ width, height ].
    unless ( eval { $pdf->{papersize}->[0] } ) {
	require PDF::API2::Resource::PaperSizes;
	my %ps = PDF::API2::Resource::PaperSizes->get_paper_sizes;
	die("Unhandled paper size: ", $pdf->{papersize}, "\n")
	  unless exists $ps{lc $pdf->{papersize}};
	$pdf->{papersize} = $ps{lc $pdf->{papersize}}
    }

    # Sanitize, if necessary.
    $fonts->{subtitle}       ||= { %{ $fonts->{text}  } };
    $fonts->{comment_italic} ||= { %{ $fonts->{chord} } };
    $fonts->{comment_box}    ||= { %{ $fonts->{chord} } };
    $fonts->{comment}        ||= { %{ $fonts->{text}  } };
    $fonts->{toc}	     ||= { %{ $fonts->{text}  } };
    $fonts->{grid}           ||= { %{ $fonts->{chord} } };

    # Default footer is small subtitle.
    unless ( $fonts->{footer} ) {
	$fonts->{footer} = { %{ $fonts->{subtitle} } };
	$fonts->{footer}->{size}
	  = 0.6 * $fonts->{subtitle}->{size};
    }
}

package PDFWriter;

use strict;
use warnings;
use PDF::API2;
use Encode;

my %fontcache;			# speeds up 2 seconds per song

sub new {
    my ( $pkg, $ps, @file ) = @_;
    my $self = bless { ps => $ps }, $pkg;
    $self->{pdf} = PDF::API2->new( -file => $file[0] );
    $self->{pdf}->{forcecompress} = 0;
    $self->{pdf}->mediabox( $ps->{papersize}->[0],
			    $ps->{papersize}->[1] );
#    $self->newpage($ps);
    %fontcache = () if $::__EMBEDDED__;
    $self;
}

sub info {
    my ( $self, %info ) = @_;
    unless ( $info{CreationDate} ) {
	my @tm = gmtime( $::__EMBEDDED__ ? 1465041600 : time );
	$info{CreationDate} =
	  sprintf("D:%04d%02d%02d%02d%02d%02d+00'00'",
		  1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]);
    }
    $self->{pdf}->info( %info );
}

sub text {
    my ( $self, $text, $x, $y, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->setfont($font, $size);

    $text = encode( "cp1250", $text ) unless $font->{file};
    if ( $font->{color} ) {
	$self->{pdftext}->strokecolor( $font->{color} );
	$self->{pdftext}->fillcolor( $font->{color} );
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
