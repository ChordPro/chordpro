#!/usr/bin/perl

use utf8;

package App::Music::ChordPro::Output::PDF;

use strict;
use warnings;
use Data::Dumper;
use Encode qw( encode_utf8 );

use App::Music::ChordPro::Output::Common;

use constant DEBUG_SPACING => 0;

# For regression testing, run perl with PERL_HASH_SEED set to zero.
# This eliminates the arbitrary order of font definitions and triggers
# us to pinpoint some other data that would otherwise be varying.
my $regtest = defined($ENV{PERL_HASH_SEED}) && $ENV{PERL_HASH_SEED} == 0;

sub generate_songbook {
    my ($self, $sb, $options) = @_;

    return [] unless $sb->{songs}->[0]->{body}; # no songs

    my $ps = $::config->{pdf};
    my $pr = PDFWriter->new($ps);
    $pr->info( Title => $sb->{songs}->[0]->{meta}->{title}->[0],
	       Creator =>
	       $regtest
	       ? "ChordPro [$options->{_name} (regression testing)]"
	       : "ChordPro [$options->{_name} $options->{_version}]",
	     );

    my @book;
    my $page = $options->{"start-page-number"} || 1;
    foreach my $song ( @{$sb->{songs}} ) {

	$options->{startpage} = $page;
	push( @book, [ $song->{meta}->{title}->[0], $page ] );
	$page += generate_song( $song,
				{ pr => $pr, $options ? %$options : () } );
    }

    if ( $options->{toc} ) {

	$pr->newpage($ps), $page++
	  if $ps->{'even-odd-pages'} && $page % 2 == 0;

	# Create a pseudo-song for the table of contents.
	$options->{startpage} = $page;
	my $song =
	  { title     => get_format( $ps, 1, "toc-title" ),
	    structure => "linear",
	    body      => [
		     map { +{ type    => "tocline",
			      context => "toc",
			      title   => $_->[0],
			      page    => $_->[1],
			    } } @book,
	    ],
	    meta      => {},
	  };
	push( @book, [ $song->{title}, $page ] );
	$page += generate_song( $song,
				{ pr => $pr, $options ? %$options : () } );
    }

    $pr->finish( $options->{output} || "__new__.pdf" );

    if ( $options->{toc} ) {

	# Create an MSPro compatible CSV for this PDF.
	( my $csv = $options->{output} ) =~ s/\.pdf$/.csv/i;
	open( my $fd, '>:utf8', encode_utf8($csv) )
	  or die( encode_utf8($csv), ": $!\n" );
	print $fd ( "title;pages;\n" );
	for ( my $p = 1; $p < @book-1; $p++ ) {
	    print $fd ( join(';',
			     $book[$p]->[0],
			     $book[$p+1]->[1] > $book[$p]->[1]+1
			     ? ( $book[$p]->[1] ."-". ($book[$p+1]->[1]-1) )
			     : $book[$p]->[1]),
			"\n" );
	}
	close($fd);
    }

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

    return 0 unless $s->{body};	# empty song

    $single_space = $::config->{settings}->{'suppress-empty-chords'};
    my $ps = $::config->clone->{pdf};
    my $pr = $options->{pr};
    $ps->{pr} = $pr;
    $pr->{ps} = $ps;
    $pr->init_fonts();
    my $fonts = $ps->{fonts};

    $structured = ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';
    $s->structurize if $structured;

    my $sb = $s->{body};

    set_columns( $ps,
		 $s->{settings}->{columns} || $::config->{settings}->{columns} );

    $chordscol    = $ps->{chordscolumn};
    $lyrics_only  = $::config->{settings}->{'lyrics-only'};
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

    $ps->{'even-odd-pages'} =  1 if $options->{'even-pages-number-left'};
    $ps->{'even-odd-pages'} = -1 if $options->{'odd-pages-number-left'};

    my $st = $s->{settings}->{titles} || $::config->{settings}->{titles};
    if ( defined($st)
	 && ! $pr->{'titles-directive-ignore'} ) {
	my $swap = sub {
	    my ( $from, $to ) = @_;
	    for my $class ( qw( default title first ) ) {
		for ( qw( title subtitle footer ) ) {
		    next unless exists $ps->{formats}->{$class}->{$_};
		    ( $ps->{formats}->{$class}->{$_}->[$from],
		      $ps->{formats}->{$class}->{$_}->[$to] ) =
			( $ps->{formats}->{$class}->{$_}->[$to],
			  $ps->{formats}->{$class}->{$_}->[$from] );
		}
	    }
	};

	if ( $st eq "left" ) {
	    $swap->(0,1);
	}
	if ( $st eq "right" ) {
	    $swap->(2,1);
	}
    }

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

    my $col;
    my $vsp_ignorefirst;
    my $startpage = $options->{startpage} || 1;
    my $thispage = $startpage - 1;

    # Physical newpage handler.
    my $newpage = sub {

	# Add page to the PDF.
	$pr->newpage($ps);

	# Prepare for printing.
	showlayout($ps) if $ps->{showlayout};

	# Put titles and footer.

	# If even/odd pages, leftpage signals whether the
	# header/footer parts must be swapped.
	my $leftpage;
	if ( $ps->{"even-odd-pages"} ) {
	    # Even/odd printing...
	    $leftpage = $thispage % 2 != 0;
	    # Odd/even printing...
	    $leftpage = !$leftpage if $ps->{'even-odd-pages'} < 0;
	}

	$thispage++;

	# Determine page class.
	my $class = 2;		# default
	if ( $thispage == 1 ) {
	    $class = 0;		# very first page
	}
	elsif ( $thispage == $startpage ) {
	    $class = 1;		# first of a song
	}
	$s->{page} = $thispage;

	# Three-part title handlers.
	my $tpt = sub { tpt( $ps, $class, $_[0], $leftpage, $x, $y, $s ) };

	$x = $ps->{marginleft};
	if ( $ps->{headspace} ) {
	    $y = $ps->{papersize}->[1] - $ps->{margintop} + $ps->{headspace};
	    $y -= font_bl($fonts->{title});
	    $tpt->("title");
	    $y -= ( - ( $fonts->{title}->{font}->descender / 1024 )
		      * $fonts->{title}->{size}
		    + ( $fonts->{subtitle}->{font}->ascender / 1024 )
		      * $fonts->{subtitle}->{size} )
		  * $ps->{spacing}->{title};
	    $y = $tpt->("subtitle");
	}

	if ( $ps->{footspace} ) {
	    $y = $ps->{marginbottom} - $ps->{footspace};
	    $tpt->("footer");
	}

	$y = $ps->{papersize}->[1] - $ps->{margintop};
	$y += $ps->{headspace} if $ps->{'head-first-only'} && $class == 2;
	$col = 0;
	$vsp_ignorefirst = 1;
    };

    # Get going.
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
	    $vsp_ignorefirst = 0;
	}
	else {
	    $x = $ps->{marginleft} + $ps->{columnoffsets}->[$col];
	    $y = $ps->{papersize}->[1] - $ps->{margintop};
	}

	return;
    };

    my @elts = @{$sb};
    my $elt;			# current element

    my $prev;			# previous element
    my @chorus;			# chorus elements, if any

    my $grid_cellwidth;
    my $grid_barwidth = 0.5 * $fonts->{chord}->{size};
    my $grid_margin;

    my %propstack;

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
	    my $vsp = empty_vsp( $elt, $ps );
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
	    elsif ( $type eq "tabline" ) {
		$ftext = $fonts->{tab};
	    }

	    # Get vertical space the songline will occupy.
	    my $vsp = songline_vsp( $elt, $ps );

	    # Add prespace if fit. Otherwise newpage.
	    $checkspace->($vsp);

	    $pr->show_vpos( $y, 0 ) if DEBUG_SPACING;

	    my $indent = 0;

	    # Handle decorations.

	    if ( $elt->{context} eq "chorus" ) {
		my $style = $ps->{chorus};
		$indent = $style->{indent};
		if ( $style->{bar}->{offset} && $style->{bar}->{width} ) {
		    my $cx = $ps->{marginleft}
		      + $ps->{columnoffsets}->[$col]
			- $style->{bar}->{offset}
			  + $indent;
		    $pr->vline( $cx, $y, $vsp,
				$style->{bar}->{width},
				$style->{bar}->{color} );
		}
	    }

	    # Substitute metadata in comments.
	    if ( $elt->{type} =~ /^comment/ ) {
		$elt = { %$elt };
		# Flatten chords/phrases.
		if ( $elt->{chords} ) {
		    $elt->{text} = "";
		    for ( 0..$#{ $elt->{chords} } ) {
			$elt->{text} .= $elt->{chords}->[$_] . $elt->{phrases}->[$_];
		    }
		}
		$elt->{text} = fmt_subst( $s, $elt->{text}, 1 );
	    }

	    # Comment decorations.

	    $pr->setfont( $ftext );
	    my $text = $elt->{text};
	    my $w = $pr->strwidth( $text );
	    my $x1 = $x + $w;

	    # Draw background.
	    my $bgcol = $ftext->{background};
	    $bgcol ||= "#E5E5E5" if $elt->{type} eq "comment";
	    if ( $bgcol ) {
		$pr->rectxy( $x + $indent - 2, $y + 2,
			     $x + $indent + $w + 2, $y - $vsp, 3, $bgcol );
	    }

	    # Draw box.
	    my $x0 = $x;
	    if ( $elt->{type} eq "comment_box" ) {
		$x0 += 0.25;	# add some offset for the box
		$pr->rectxy( $x0 + $indent, $y + 1,
			     $x0 + $indent + $w + 1, $y - $vsp + 1,
			     0.5, undef, "black" );
	    }

	    songline( $elt, $x0, $y, $ps, song => $s, indent => $indent );

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
	    my $style = $ps->{chorus};
	    my $cx = $ps->{marginleft}
	      + $ps->{columnoffsets}->[$col] - $style->{bar}->{offset};
	    $pr->vline( $cx, $cy, vsp($ps), 1, $style->{bar}->{color} );
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
		      $grid_cellwidth,
		      $grid_barwidth,
		      $grid_margin,
		      $ps );

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

	    # Images are slightly more complex.
	    # Only after establishing the desired height we can issue
	    # the checkspace call, and we must get $y after that.

	    my $gety = sub {
		my $h = shift;
		$checkspace->($h);
		$ps->{pr}->show_vpos( $y, 1 ) if DEBUG_SPACING;
		return $y;
	    };

	    my $vsp = imageline( $elt, $x, $ps, $gety );

	    # Turn error into comment.
	    unless ( $vsp =~ /^\d/ ) {
		unshift( @elts, { %$elt,
				  type => "comment_box",
				  text => $vsp,
				} );
		redo;
	    }

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if DEBUG_SPACING;

	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    my $t = $ps->{chorus}->{recall};
	    if ( $t->{quote} ) {
		unshift( @elts, @chorus );
	    }
	    if ( $t->{tag} && $t->{type} =~ /^comment(?:_(?:box|italic))?/ ) {
		unshift( @elts, { %$elt,
				  type => $t->{type},
				  text => $t->{tag},
				 } );
	    }
	    redo;
	}

	if ( $elt->{type} eq "tocline" ) {
	    my $vsp = toc_vsp( $elt, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if DEBUG_SPACING;

	    tocline( $elt, $x, $y, $ps );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if DEBUG_SPACING;
	    next;
	}

	if ( $elt->{type} eq "chord-grids" ) {

	    my @chords = @{ $elt->{chords} };

	    local $::config->{chordgrid}->{show} =
	      $elt->{show} || $::config->{chordgrid}->{show};

	    my $vsp = chordgrid_vsp( $elt, $ps );
	    my $hsp = chordgrid_hsp( $elt, $ps );
	    my $h = int( ( $ps->{papersize}->[0]
			   - $ps->{marginleft}
			   - $ps->{marginright}
			   + $ps->{chordgrid}->{hspace}
			     * $ps->{chordgrid}->{width} ) / $hsp );
	    while ( @chords ) {
		my $x = $x;
		$checkspace->($vsp);
		$pr->show_vpos( $y, 0 ) if DEBUG_SPACING;

		for ( 1..$h ) {
		    last unless @chords;
		    my $t = chordgrid( shift(@chords), $x, $y, $ps );
		    redo unless $t;
		    $x += $t;
		}

		$y -= $vsp;
		$pr->show_vpos( $y, 1 ) if DEBUG_SPACING;
	    }
	    next;
	}

	if ( $elt->{type} eq "control" ) {
	    $propstack{ $elt->{name} } //= [];
	    if ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-size$/ ) {
		if ( defined $elt->{value} ) {
		    push( @{ $propstack{ $elt->{name} } }, $fonts->{$1}->{size} );
		    $do_size->( $1, $elt->{value} );
		}
		elsif ( @{ $propstack{ $elt->{name} } } ) {
		    $do_size->( $1, pop( @{ $propstack{ $elt->{name} } } ) );
		}
		else {
		    warn("PDF: No saved value for property $1-size\n" );
		}
	    }
	    elsif ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-font$/ ) {
		my $f = $1;
		my $okey = $ps->{fonts}->{$f}->{file} ? "file" : "name";
		my $orig = $ps->{fonts}->{$f}->{$okey};
		if ( defined $elt->{value} ) {
		    push( @{ $propstack{ $elt->{name} } }, [ $okey => $orig ] );
		    if ( $elt->{value} =~ m;/; ) {
			$ps->{fonts}->{$f}->{file} = $elt->{value};
		    }
		    else {
			$ps->{fonts}->{$f}->{name} = $elt->{value};
		    }
		    $pr->init_font($f);
		}
		elsif ( @{ $propstack{ $elt->{name} } } ) {
		    my ( $k, $v ) = @{ pop( @{ $propstack{ $elt->{name} } } ) };
		    $ps->{fonts}->{$f}->{$k} = $v;
		    delete $ps->{fonts}->{$f}->{name} if $k eq "file";
		    $pr->init_font($f);
		}
		else {
		    warn("PDF: No saved value for property $1-font\n" );
		}
	    }
	    elsif ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-color$/ ) {
		if ( defined $elt->{value} ) {
		    push( @{ $propstack{ $elt->{name} } }, $fonts->{$1}->{color} );
		    $ps->{fonts}->{$1}->{color} = $elt->{value};
		}
		elsif ( @{ $propstack{ $elt->{name} } } ) {
		    $ps->{fonts}->{$1}->{color} = pop( @{ $propstack{ $elt->{name} } } );
		}
		else {
		    warn("PDF: No saved value for property $1-color\n" );
		}
	    }
	    next;
	}

	if ( $elt->{type} eq "set" ) {
	    if ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	    elsif ( $elt->{name} eq "gridparams" ) {
		my @v = @{ $elt->{value} };
		my $cells;
		my $bars = 8;
		$grid_margin = [ 0, 0 ];
		if ( $v[1] ) {
		    $cells = $v[0] * $v[1];
		    $bars = $v[0];
		}
		else {
		    $cells = $v[0];
		}
		$cells += $grid_margin->[0] = $v[2] if $v[2];
		$cells += $grid_margin->[1] = $v[3] if $v[3];
		$grid_cellwidth = ( $ps->{papersize}->[0]
				    - $ps->{marginleft}
				    - $ps->{marginright}
				    - ($cells)*$grid_barwidth
				  ) / $cells;
	    }
	    next;
	}
	if ( $elt->{type} eq "ignore" ) {
	    next;
	}

	warn("PDF: Unhandled operator: ", $elt->{type}, " (ignored)\n");
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
	my $song   = $opts{song};
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
	    my $w1 = $pr->strwidth( $chord." ", $fchord );
	    my $w2 = $pr->strwidth(" ") /  2;
	    $pr->rectxy( $x - $w2, $ytop, $x + $w1 - $w2,
			 $ytop - $fchord->{size}, 1,
			 $fchord->{background} );
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

	    $pr->hline( $ulstart, $ytext + font_ul($ftext), $w,
			0.25, "black" );

	    # Print the text.
	    $x = $pr->text( $phrase, $x, $ytext, $ftext );

	    # Collect chords to be printed in the side column.
	    push(@chords, $chord);
	}
	else {
	    my $info = App::Music::ChordPro::Chords::identify($chord);
	    my $xt0;
	    if ( $info && $info->{system} eq "R" ) {
		$xt0 = $pr->text( $info->{dproot}.$info->{qual},
				  $x, $ychord, $fchord );
		$xt0 = $pr->text( $info->{adds}, $xt0,
				   $ychord + $fchord->{size} * 0.2,
				   $fchord,
				   $fchord->{size} * 0.8
				 );
		$xt0 = $pr->text( " ", $xt0, $ychord, $fchord );
	    }
	    elsif ( $info && $info->{system} eq "N" ) {
		$xt0 = $pr->text( $info->{dproot}.$info->{qual},
				  $x, $ychord, $fchord );
#		if ( $info->{minor} ) {
#		    my $m = $info->{minor};
#		    # $m = "\x{0394}" if $m eq "^";
#		    $xt0 = $pr->text( $m, $xt0, $ychord, $fchord );
#		}
		$xt0 = $pr->text( $info->{adds}, $xt0,
				   $ychord + $fchord->{size} * 0.2,
				   $fchord,
				   $fchord->{size} * 0.8,
				 );
		$xt0 = $pr->text( " ", $xt0, $ychord, $fchord );
	    }
	    else {
		$xt0 = $pr->text( $chord." ", $x, $ychord, $fchord );
	    }
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

sub is_bar {
    exists( $_[0]->{class} ) && $_[0]->{class} eq "bar";
}

sub gridline {
    my ( $elt, $x, $y, $cellwidth, $barwidth, $margin, $ps ) = @_;

    # Grid context.

    my $pr = $ps->{pr};
    my $fonts = $ps->{fonts};

    $x += $barwidth;
    $cellwidth += $barwidth;

    # Use the chords font for the chords, and for the symbols size.
    my $fchord = { %{ $fonts->{grid} || $fonts->{chord} } };
    delete($fchord->{background});
    $y -= font_bl($fchord);

    $elt->{tokens} //= [ {} ];

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

    if ( $margin->[0] ) {
	$x -= $barwidth;
	if ( $elt->{margin} ) {
	    my $t = $elt->{margin};
	    if ( $t->{chords} ) {
		$t->{text} = "";
		for ( 0..$#{ $t->{chords} } ) {
		    $t->{text} .= $t->{chords}->[$_] . $t->{phrases}->[$_];
		}
	    }
	    $pr->text( $t->{text}, $x, $y, $fonts->{comment} );
	}
	$x += $margin->[0] * $cellwidth + $barwidth;
    }

    foreach my $i ( 0 .. $#tokens ) {
	my $token = $tokens[$i];
	if ( exists $token->{chord} ) {
	    $pr->text( $token->{chord}, $x, $y, $fchord )
	      unless $token eq ".";
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "space" ) {
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "bar" ) {
	    $x -= $barwidth;
	    $t = $token->{symbol};
	    if ( 0 ) {
		$t = "{" if $t eq "|:";
		$t = "}" if $t eq ":|";
		$t = "}{" if $t eq ":|:";
	    }
	    else {
		$t = "|:" if $t eq "{";
		$t = ":|" if $t eq "}";
		$t = ":|:" if $t eq "}{";
	    }

	    my $lcr = -1;	# left, center, right
	    $lcr = 0 if $i > $firstbar;
	    $lcr = 1 if $i == $lastbar;

	    my $sz = $fchord->{size};

	    if ( $t eq "|" ) {
		pr_barline( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq "||" ) {
		pr_dbarline( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq "|:" ) {
		pr_rptstart( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq ":|" ) {
		pr_rptend( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq ":|:" ) {
		pr_rptendstart( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq "|." ) {
		pr_endline( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq " %" ) { # repeat2Bars
		pr_repeat( $x+$sz/2, $y, 0, $sz, $pr );
	    }
	    else {
		die($t);	# can't happen
	    }
	    $x += $barwidth;
	    $prevbar = $i;
	}
	elsif ( $token->{class} eq "repeat1" ) {
	    $t = $token->{symbol};
	    my $k = $prevbar + 1;
	    while ( $k <= $#tokens
		    && !is_bar($tokens[$k]) ) {
		$k++;
	    }
	    pr_repeat( $x + ($k - $prevbar - 1)*$cellwidth/2, $y,
		       0, $fchord->{size}, $pr );
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "repeat2" ) {
	    # For repeat2Bars, change the next bar line to pseudo-bar.
	    my $k = $prevbar + 1;
	    while ( $k <= $#tokens
		    && !is_bar($tokens[$k]) ) {
		$k++;
	    }
	    $tokens[$k] = { symbol => " %", class => "bar" };
	    $x += $cellwidth;
	}
    }

    if ( $margin->[1] && $elt->{comment} ) {
	my $t = $elt->{comment};
	if ( $t->{chords} ) {
	    $t->{text} = "";
	    for ( 0..$#{ $t->{chords} } ) {
		$t->{text} .= $t->{chords}->[$_] . $t->{phrases}->[$_];
	    }
	}
	$pr->text( " " . $t->{text}, $x, $y, $fonts->{comment} );
    }
}

sub pr_barline {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = $w
    $x -= $w / 2 * ($lcr + 1);
    $pr->vline( $x, $y+0.9*$sz, $sz, $w );
}

sub pr_dbarline {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 1.5 * $w * ($lcr + 1);
    $pr->vline( $x, $y+0.9*$sz, $sz, $w );
    $x += 2 * $w;
    $pr->vline( $x, $y+0.9*$sz, $sz, $w );
}

sub pr_rptstart {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 1.5 * $w * ($lcr + 1);
    $pr->vline( $x, $y+0.9*$sz, $sz, $w );
    $x += 2 * $w;
    $y += 0.55 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w );
    $y -= 0.4 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w );
}

sub pr_rptend {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 1.5 * $w * ($lcr + 1);
    $pr->vline( $x + 2*$w, $y+0.9*$sz, $sz, $w );
    $y += 0.55 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w );
    $y -= 0.4 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w );
}

sub pr_rptendstart {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 5 * $w
    $x -= 2.5 * $w * ($lcr + 1);
    $pr->vline( $x + 2*$w, $y+0.9*$sz, $sz, $w );
    $y += 0.55 * $sz;
    $pr->line( $x,      $y, $x     , $y+$w, $w );
    $pr->line( $x+4*$w, $y, $x+4*$w, $y+$w, $w );
    $y -= 0.4 * $sz;
    $pr->line( $x,      $y, $x,      $y+$w, $w );
    $pr->line( $x+4*$w, $y, $x+4*$w, $y+$w, $w );
}

sub pr_repeat {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 3;		# glyph width = 3 * $w
    $x -= 1.5 * $w * ($lcr + 1);
    my $lw = $sz / 10;
    $x -= $w / 2;
    $pr->line( $x, $y+0.2*$sz, $x + $w, $y+0.7*$sz, $lw );
    $pr->line( $x, $y+0.6*$sz, $x + 0.07*$sz , $y+0.7*$sz, $lw );
    $x += $w;
    $pr->line( $x - 0.05*$sz, $y+0.2*$sz, $x + 0.02*$sz, $y+0.3*$sz, $lw );
}

sub pr_endline {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 2 * $w
    $x -= 0.75 * $w * ($lcr + 1);
    $pr->vline( $x, $y+0.85*$sz, 0.9*$sz, 2*$w );
}

sub imageline_vsp {
}

sub imageline {
    my ( $elt, $x, $ps, $gety ) = @_;

    my $opts = $elt->{opts};
    my $pr = $ps->{pr};

    unless ( -s $elt->{uri} ) {
	return "$!: " . $elt->{uri};
    }

    my $img = eval { $pr->get_image( $elt->{uri} ) };
    unless ( $img ) {
	return "Unhandled image type: " . $elt->{uri};
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
    $x += ($pw - $w) / 2 if $opts->{center};

    my $y = $gety->($h);	# may have been changed by checkspace

    $pr->add_image( $img, $x, $y, $w, $h, $opts->{border} || 0 );

    return $h;			# vertical size
}

sub tocline {
    my ( $elt, $x, $y, $ps ) = @_;

    my $pr = $ps->{pr};
    my $fonts = $ps->{fonts};
    my $y0 = $y;
    $x += 20;
    my $ftoc = $fonts->{toc};
    $y -= font_bl($ftoc);
    $pr->setfont($ftoc);
    $ps->{pr}->text( $elt->{title}, $x, $y );
    my $p = $elt->{page} . ".";
    $ps->{pr}->text( $p, $x - 5 - $pr->strwidth($p), $y );

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

    # No text printing if no text.
    $vsp = 0 if join( "", @{ $elt->{phrases} } ) eq "";

    # We must show chords above lyrics, so add chords span.
    $vsp + $fonts->{chord}->{size} * $ps->{spacing}->{chords};
}

sub _vsp {
    my ( $eltype, $ps, $sptype ) = @_;
    $sptype ||= $eltype;

    # Calculate the vertical span of this element.

    my $font = $ps->{fonts}->{$eltype};
    $font->{size} * $ps->{spacing}->{$sptype};
}

sub empty_vsp { _vsp( "empty", $_[1] ) }
sub grid_vsp  { _vsp( "grid",  $_[1] ) }
sub tab_vsp   { _vsp( "tab",   $_[1] ) }
sub toc_vsp   { _vsp( "toc",   $_[1] ) }

sub text_vsp {
    my ( $elt, $ps ) = @_;

    # Calculate the vertical span of this line.

    _vsp( "text", $ps, "lyrics" );
}

sub chordgrid_vsp {
    my ( $elt, $ps ) = @_;
    $ps->{fonts}->{chordgrid}->{size} * $ps->{spacing}->{chords}
      + 0.40 * $ps->{chordgrid}->{width}
	+ $ps->{chordgrid}->{vcells} * $ps->{chordgrid}->{height}
	  + $ps->{chordgrid}->{vspace} * $ps->{chordgrid}->{height};
}

sub chordgrid_hsp {
    my ( $elt, $ps ) = @_;
    App::Music::ChordPro::Chords::strings() * $ps->{chordgrid}->{width}
      + $ps->{chordgrid}->{hspace} * $ps->{chordgrid}->{width};
}

my @Roman = qw( I II III IV V VI VI VII VIII IX X XI XII );

sub chordgrid {
    my ( $name, $x, $y, $ps ) = @_;
    my $x0 = $x;

    my $gw = $ps->{chordgrid}->{width};
    my $gh = $ps->{chordgrid}->{height};
    my $dot = 0.80 * $gw;
    my $lw  = ($ps->{chordgrid}->{linewidth} || 0.10) * $gw;

    my $info = App::Music::ChordPro::Chords::chord_info($name);
    unless ( $info ) {
	warn("PDF: Skipping grid for unknown chord $name\n");
	return;
    }

    my $pr = $ps->{pr};

    my $strings = App::Music::ChordPro::Chords::strings();
    my $w = $gw * ($strings - 1);

    # Draw font name.
    my $font = $ps->{fonts}->{chordgrid};
    $pr->setfont($font);
    $name .= "*"
      unless $info->{origin} == 0 || $::config->{chordgrid}->{show} eq "user";
    $pr->text( $name, $x + ($w - $pr->strwidth($name))/2, $y - font_bl($font) );
    $y -= $font->{size} * $ps->{spacing}->{chords} + $dot/2 + $lw;

    if ( $info->{base} > 0 ) {
	my $i = @Roman[$info->{base}] . "  ";
	$pr->setfont( $ps->{fonts}->{chordgrid_capo}, $gh );
	$pr->text( $i, $x-$pr->strwidth($i), $y-$gh/2,
		   $ps->{fonts}->{chordgrid_capo}, $gh );
    }

    my $v = $ps->{chordgrid}->{vcells};
    my $h = $strings;
    $pr->hline( $x, $y - $_*$gh, $w, $lw ) for 0..$v;

    $x -= $gw/2;
    for my $sx ( 0 .. @{ $info->{strings} }-1 ) {
	my $fret = $info->{strings}->[$sx];
	my $fing;
	$fing = $info->{fingers}->[$sx] if $info->{fingers};
	if ( $fret > 0 ) {
	    my $glyph = "\x{6c}";
	    if ( $fing && $fing > 0 ) {
		# Note: circle must go under the text.
		$pr->circle( $x+$gw/2, $y-$fret*$gh+$gh/2, $dot/2, $lw,
			     "white", undef);
		$glyph = pack( "C", 0xca + $fing - 1 );
	    }
	    my $dot = $dot/0.7;
	    $pr->setfont( $ps->{fonts}->{chordfingers}, $dot );
	    $pr->text( $glyph,
		       $x+$gw/2-$pr->strwidth($glyph)/2,
		       $y-$fret*$gh+$gh/2-$pr->strwidth($glyph)/2+$lw/2,
		       $ps->{fonts}->{chordfingers}, $dot ) ;
	}
	elsif ( $fret < 0 ) {
	    $pr->cross( $x+$gw/2, $y+$lw+$gh/3, $dot/3, $lw, "black");
	}
	elsif ( $info->{base} >= 0 ) {
	    $pr->circle( $x+$gw/2, $y+$lw+$gh/3, $dot/3, $lw,
			 undef, "black");
	}
    }
    continue {
	$x += $gw;
    }
    # Note: vline must go under the circle.
    $pr->vline( $x0 + $_*$gw, $y, $gh*$v, $lw ) for 0..$h-1;

    return $gw * ( $ps->{chordgrid}->{hspace} + $strings );
}

sub set_columns {
    my ( $ps, $cols ) = @_;
    unless ( $cols ) {
	$cols = $ps->{columns} ||= 1;
    }
    else {
	$ps->{columns} = $cols ||= 1;
    }
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
    my $col = "black";
    my $lw = 0.5;

    $pr->rectxy( $ps->{marginleft},
		 $ps->{marginbottom},
		 $ps->{papersize}->[0]-$ps->{marginright},
		 $ps->{papersize}->[1]-$ps->{margintop},
		 $lw, undef, $col);

    $pr->hline( $ps->{marginleft},
		$ps->{papersize}->[1]-$ps->{margintop}+$ps->{headspace},
		$ps->{papersize}->[0]-$ps->{marginleft}-$ps->{marginright},
		$lw, $col );

    $pr->hline( $ps->{marginleft},
		$ps->{marginbottom}-$ps->{footspace},
		$ps->{papersize}->[0]-$ps->{marginleft}-$ps->{marginright},
		$lw, $col );

    my @off = @{ $ps->{columnoffsets} };
    @off = ( $ps->{chordscolumn} ) if $ps->{chordscolumn};
    foreach my $i ( 0 .. @off-1 ) {
	next unless $off[$i];
	$pr->vline( $ps->{marginleft}+$off[$i],
		    $ps->{marginbottom},
		    $ps->{margintop}-$ps->{papersize}->[1]+$ps->{marginbottom},
		    $lw, $col );
	$pr->vline( $ps->{marginleft}+$off[$i]-$ps->{columnspace},
		    $ps->{marginbottom},
		    $ps->{margintop}-$ps->{papersize}->[1]+$ps->{marginbottom},
		    $lw, $col );
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
	# by configs and {controls}.
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

    # Chord grid width.
    if ( $options->{'chord-grid-size'} ) {
	$pdf->{chordgrid}->{width} =
	  $pdf->{chordgrid}->{height} =
	    $options->{'chord-grid-size'} /
	      App::Music::ChordPro::Chords::strings();
    }

    # Add font dirs.
    for my $fontdir ( $pdf->{fontdir}, ::findlib("fonts"), $ENV{FONTDIR} ) {
	next unless $fontdir;
	if ( -d $fontdir ) {
	    PDF::API2::addFontDirs($fontdir);
	}
	else {
	    warn("PDF: Ignoring fontdir $fontdir [$!]\n");
	    undef $fontdir;
	}
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
    $fonts->{empty}	     ||= { %{ $fonts->{text}  } };
    $fonts->{grid}           ||= { %{ $fonts->{chord} } };
    $fonts->{chordgrid}      ||= { %{ $fonts->{comment} } };
    $fonts->{chordgrid_capo} ||= { %{ $fonts->{text} } };
    $fonts->{chordfingers}     = { name => 'ZapfDingbats' };
    $fonts->{subtitle}->{size}       ||= $fonts->{text}->{size};
    $fonts->{comment_italic}->{size} ||= $fonts->{text}->{size};
    $fonts->{comment_box}->{size}    ||= $fonts->{text}->{size};
    $fonts->{comment}->{size}        ||= $fonts->{text}->{size};

    # Default footer is small subtitle.
    unless ( $fonts->{footer} ) {
	$fonts->{footer} = { %{ $fonts->{subtitle} } };
	$fonts->{footer}->{size}
	  = 0.6 * $fonts->{subtitle}->{size};
    }
}

# Get a format string for a given page class and type.
# Page classes have fallbacks.
sub get_format {
    my ( $ps, $class, $type ) = @_;
    my @classes = qw( first title default );
    for ( my $i = $class; $i < @classes; $i++ ) {
	next unless exists($ps->{formats}->{$classes[$i]}->{$type});
	return $ps->{formats}->{$classes[$i]}->{$type};
    }
    return;
}

# Substitute %X sequences in title formats.
sub fmt_subst {
    goto \&App::Music::ChordPro::Output::Common::fmt_subst;
}

# Three-part titles.
# Note: baseline printing.
sub tpt {
    my ( $ps, $class, $type, $leftpage, $x, $y, $s ) = @_;
    my $fmt = get_format( $ps, $class, $type );
    return unless $fmt;

    # @fmt = ( left-fmt, center-fmt, right-fmt )

    my @fmt = @{$fmt};
    @fmt = @fmt[2,1,0] if $leftpage; # swap

    my $pr = $ps->{pr};
    my $font = $ps->{fonts}->{$type};

    $pr->setfont($font);
    my $rm = $ps->{papersize}->[0] - $ps->{marginright};

    # Left part. Easiest.
    $pr->text( fmt_subst( $s, $fmt[0] ), $x, $y ) if $fmt[0];

    # Center part.
    if ( $fmt[1] ) {
	my $t = fmt_subst( $s, $fmt[1] );
	$pr->text( $t, ($rm+$x-$pr->strwidth($t))/2, $y );
    }

    # Right part.
    if ( $fmt[2] ) {
	my $t = fmt_subst( $s, $fmt[2] );
	$pr->text( $t, $rm-$pr->strwidth($t), $y );
    }

    # Return updated baseline.
    return $y - $font->{size} * ($ps->{spacing}->{$type} || 1);
}

################################################################

package PDFWriter;

use strict;
use warnings;
use PDF::API2;
use Encode;

my $faketime = 1465041600;

my %fontcache;			# speeds up 2 seconds per song

sub new {
    my ( $pkg, $ps ) = @_;
    my $self = bless { ps => $ps }, $pkg;
    $self->{pdf} = PDF::API2->new;
    $self->{pdf}->{forcecompress} = 0 if $regtest;
    $self->{pdf}->mediabox( $ps->{papersize}->[0],
			    $ps->{papersize}->[1] );
#    $self->newpage($ps);
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

sub text {
    my ( $self, $text, $x, $y, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};

    $self->setfont($font, $size);

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
    my $gfx = $self->{pdfpage}->gfx;
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
    my $gfx = $self->{pdfpage}->gfx;
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
    my $gfx = $self->{pdfpage}->gfx(1); # under
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
    my $gfx = $self->{pdfpage}->gfx(1); # under
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
    my $gfx = $self->{pdfpage}->gfx(1); # under
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
    my $gfx = $self->{pdfpage}->gfx;
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
    for ( $uri ) {
	$img = $self->{pdf}->image_png($_)  if /\.png$/i;
	$img = $self->{pdf}->image_jpeg($_) if /\.jpe?g$/i;
	$img = $self->{pdf}->image_gif($_)  if /\.gif$/i;
    }
    return $img;
}

sub add_image {
    my ( $self, $img, $x, $y, $w, $h, $border ) = @_;

    my $gfx = $self->{pdfpage}->gfx(1); # under

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
    $font->{font}->{Name}->{val} =~ s/~.*/~$faketime/ if $regtest;
    $font->{font};
}

sub show_vpos {
    my ( $self, $y, $w ) = @_;
    $self->{pdfgfx}->move(100*$w,$y)->linewidth(0.25)->hline(100*(1+$w))->stroke;
}

1;
