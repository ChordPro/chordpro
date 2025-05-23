#! perl

use v5.26;

package main;

use utf8;
our $config;
our $options;

package ChordPro::Output::PDF::Song;

use Storable qw(dclone);
use Ref::Util qw(is_hashref is_arrayref is_coderef);
use Carp;
use feature 'state';
use ChordPro::Output::Common qw( roman fmt_subst );
use feature 'signatures';
no warnings qw( experimental::signatures );

use ChordPro::Files;
use ChordPro::Paths;
use ChordPro::Utils;

#my $ps;

use Text::Layout;

my $source;			# song source
my $structured = 0;		# structured data
my $suppress_empty_chordsline = 0;	# suppress chords line when empty
my $suppress_empty_lyricsline = 0;	# suppress lyrics line when blank
my $lyrics_only = 0;		# suppress all chord lines
my $inlinechords = 0;		# chords inline
my $inlineannots;		# format for inline annots
my $chordsunder = 0;		# chords under the lyrics
my $chordscol = 0;		# chords in a separate column
my $chordscapo = 0;		# capo in a separate column
my $propitems_re = propitems_re();

# Page classes.
my @classes = qw( first title default filler );

my $i_tag;
sub pr_label_maybe {
    my ( $ps, $x, $y ) = @_;
    my $tag = $i_tag // "";
    $i_tag = undef;
    prlabel( $ps, $tag, $x, $y ) if $tag ne "";
}

my $assets;
sub assets {
    my ( $id ) = @_;
    $assets->{$id};
}
# Images that go on all pages.
my @allpages;

use constant SIZE_ITEMS => [ qw( chord text chorus tab grid diagram
				 toc title footer label ) ];

sub generate_song {
    my ( $s, $opts ) = @_;

    warn("Generate song \"", $s->{title}, "\", ",
	 "page ", $opts->{page_num}, " (", $opts->{page_idx}, ")\n")
      if $config->{debug}->{pages} & 0x01;

    my $pr = $opts->{pr};
    my $ps = $pr->{ps};
    if ( $pr->{layout}->can("register_element") ) {
	$pr->{layout}->register_element
	  ( TextLayoutImageElement->new( pdf => $pr->{pdf} ), "img" );
	$pr->{layout}->register_element
	  ( TextLayoutSymbolElement->new( pdf => $pr->{pdf} ), "sym" );
    }

    unless ( $s->{body} ) {	# empty song, or embedded
	return unless $s->{source}->{embedding};
	return unless $s->{source}->{embedding} eq "pdf";
	my $p = $pr->importfile($s->{source}->{file});
	$s->{meta}->{pages} = $p->{pages};

	# Copy the title of the embedded document, provided there
	# was no override.
	if ( $s->{meta}->{title}->[0] eq $s->{source}->{file}
	     and $p->{Title} ) {
	    $s->{meta}->{title} = [ $s->{title} = $p->{Title} ];
	}
	return $s->{meta}->{pages};
    }

    local $config = dclone( $s->{config} // $config );
    while ( my($k,$v) = each( %{$config->{markup}->{shortcodes}}) ) {
	unless ( $pr->{layout}->can("register_shortcode") ) {
	    warn("Cannot register shortcodes, upgrade Text::Layout module\n");
	    last;
	}
	$pr->{layout}->register_shortcode( $k, $v );
    }
    $source = $s->{source};

    $suppress_empty_chordsline = $::config->{settings}->{'suppress-empty-chords'};
    $suppress_empty_lyricsline = $::config->{settings}->{'suppress-empty-lyrics'};
    $inlinechords = $::config->{settings}->{'inline-chords'};
    $inlineannots = $::config->{settings}->{'inline-annotations'};
    $chordsunder  = $::config->{settings}->{'chords-under'};
    $ps = $::config->clone->{pdf};
    $ps->{pr} = $pr;
    $pr->{ps} = $ps;
    $ps->{_s} = $s;
    $pr->{_df} = {};
#    warn("X1: ", $ps->{fonts}->{$_}->{size}, "\n") for "text";
    $pr->init_fonts();
    my $fonts = $ps->{fonts};
    $pr->{_df}->{$_} = { %{$fonts->{$_}} } for qw( text chorus chord grid toc tab );
#    warn("X2: ", $pr->{_df}->{$_}->{size}, "\n") for "text";

    $structured = ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';
    $s->structurize if $structured;
    @allpages = ();

    # Diagrams drawer.
    my $dd;
    my $dctl;
    if ( $::config->{instrument}->{type} eq "keyboard" ) {
	require ChordPro::Output::PDF::KeyboardDiagram;
	$dd = ChordPro::Output::PDF::KeyboardDiagram->new( ps => $ps );
	$dctl = $ps->{kbdiagrams};
    }
    else {
	require ChordPro::Output::PDF::StringDiagram;
	$dd = ChordPro::Output::PDF::StringDiagram->new( ps => $ps );
	$dctl = $ps->{diagrams};
    }
    $dctl->{show} = $s->{settings}->{diagrampos}
      if defined $s->{settings}->{diagrampos};
    $ps->{dd} = $dd;
    my $sb = $s->{body};

    # set_columns needs these, set provisional values.
    $ps->{_leftmargin}  = $ps->{marginleft};
    $ps->{_rightmargin} = $ps->{marginright};
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
	    delete( $fonts->{$item}->{description} );
	    if ( m;/; ) {
		$fonts->{$item}->{file} = $_;
	    }
	    elsif ( is_corefont($_) ) {
		$fonts->{$item}->{name} = is_corefont($_);
	    }
	    else {
		$fonts->{$item}->{description} = $_;
	    }
	    $pr->init_font($item) or $fail++;
	}
	for ( $options->{"$item-size"} ) {
	    next unless $_;
	    $fonts->{$item}->{size} = $_;
	}
    }
    die("Unhandled fonts detected -- aborted\n") if $fail;

    if ( $ps->{labels}->{comment} ) {
	$ps->{_indent} = 0;
    }
    elsif ( $ps->{labels}->{width} eq "auto" ) {
	if ( $s->{labels} && @{ $s->{labels} } ) {
	    my $longest = 0;
	    my $ftext = $fonts->{label} || $fonts->{text};
	    my $size = $ftext->{size};
	    my $w = $pr->strwidth("    ", $ftext, $size);
	    for ( @{ $s->{labels} } ) {
		# Split on real newlines and \n.
		for ( split( /\\n|\n/, $_ ) ) {
		    my $t = $pr->strwidth( $_, $ftext, $size ) + $w;
		    $longest = $t if $t > $longest;
		}
	    }
	    $ps->{_indent} = $longest;
	}
	else {
	    $ps->{_indent} = 0;
	}
    }
    else {
	$ps->{_indent} = $ps->{labels}->{width};
    }

    my $set_sizes = sub {
	$ps->{lineheight} = $fonts->{text}->{size} - 1; # chordii
	$ps->{chordheight} = $fonts->{chord}->{size};
    };
    $set_sizes->();
    $ps->{'vertical-space'} = $options->{'vertical-space'};
    for ( @{ SIZE_ITEMS() } ) {
	$fonts->{$_}->{_size} = $fonts->{$_}->{size};
    }

    my $x;
    my $y = $ps->{papersize}->[1] - $ps->{margintop};

    $ps->{'even-odd-pages'} =  1 if $options->{'even-pages-number-left'};
    $ps->{'even-odd-pages'} = -1 if $options->{'odd-pages-number-left'};

    my $st = $s->{settings}->{titles} || $::config->{settings}->{titles};
    if ( defined($st)
	 && ! $ps->{'titles-directive-ignore'} ) {
	my $swap = sub {
	    my ( $from, $to ) = @_;
	    for my $class ( @classes ) {
		for ( qw( title subtitle footer ) ) {
		    next unless defined $ps->{formats}->{$class}->{$_};
		    unless ( is_arrayref($ps->{formats}->{$class}->{$_}) ) {
			warn("Oops -- pdf.formats.$class.$_ is not an array\n");
			next;
		    }
		    unless ( is_arrayref($ps->{formats}->{$class}->{$_}->[0]) ) {
			$ps->{formats}->{$class}->{$_} =
			  [ $ps->{formats}->{$class}->{$_} ];
		    }
		    for my $l ( @{$ps->{formats}->{$class}->{$_}} ) {
			( $l->[$from], $l->[$to] ) =
			  ( $l->[$to], $l->[$from] );
		    }
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
	    $fonts->{$tag}->{_size} //=
	      $::config->{pdf}->{fonts}->{$tag}->{size};
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
    my $spreadimage;

    my $col_adjust = sub {
	if ( $ps->{columns} <= 1 ) {
	    warn( "C=-",
		  pv( ", T=", $ps->{_top} ),
		  pv( ", L=", $ps->{__leftmargin} ),
		  pv( ", I=", $ps->{_indent} ),
		  pv( ", R=", $ps->{__rightmargin} ),
		  pv( ", S=?", $spreadimage ),
		  "\n") if $config->{debug}->{spacing};
	    return;
	}
	$x = $ps->{_leftmargin} + $ps->{columnoffsets}->[$col];
	$ps->{__leftmargin} = $x;
	$ps->{__rightmargin} =
	  $ps->{_leftmargin}
	    + $ps->{columnoffsets}->[$col+1];
	$ps->{__rightmargin} -= $ps->{columnspace}
	  if $col < $ps->{columns}-1;
	$y = $ps->{_top};
	warn( pv( "C=", $col ),
	      pv( ", T=", $ps->{_top} ),
	      pv( ", L=", $ps->{__leftmargin} ),
	      pv( ", I=", $ps->{_indent} ),
	      pv( ", R=", $ps->{__rightmargin} ),
	      pv( ", S=?", $spreadimage ),
	      "\n") if $config->{debug}->{spacing};
	$x += $ps->{_indent};
	$y -= $spreadimage if defined($spreadimage) && !ref($spreadimage);
    };

    my $vsp_ignorefirst;
    my $startpage = $opts->{page_num};
    # These are 1 smaller since they'll be incremented first.
    my $page_num = $startpage - 1; # page number
    my $page_idx = $opts->{page_idx}-1; # page # in PDF

    # Physical newpage handler.
    my $newpage = sub {
	$page_idx++;
	$page_num++;
	$s->{meta}->{page} =
	  [ $s->{page} = $opts->{roman}
	                 ? roman($page_num) : $page_num ];

	# Add page to the PDF.
	$pr->newpage( $opts->{prepend} ? $page_idx : () );
	warn("page: $page_idx(",$s->{page},") added\n")
	  if $config->{debug}->{pages} & 0x01;

	# Put titles and footer.

	# If even/odd pages, leftpage signals whether the
	# header/footer parts must be swapped.
	my $rightpage = 1;
	if ( $ps->{"even-odd-pages"} ) {
	    # Even/odd printing...
	    $rightpage = $page_num % 2;
	    # Odd/even printing...
	    $rightpage = !$rightpage if $ps->{'even-odd-pages'} < 0;
	}

	# margin* are offsets from the edges of the paper.
	# _*margin are offsets taking even/odd pages into account.
	# _margin* are physical coordinates, taking ...
	if ( $rightpage ) {
	    $ps->{_leftmargin}  = $ps->{marginleft};
	    $ps->{_marginleft}  = $ps->{marginleft};
	    $ps->{_rightmargin} = $ps->{marginright};
	    $ps->{_marginright} = $ps->{papersize}->[0] - $ps->{marginright};
	}
	else {
	    $ps->{_leftmargin}  = $ps->{marginright};
	    $ps->{_marginleft}  = $ps->{marginright};
	    $ps->{_rightmargin} = $ps->{marginleft};
	    $ps->{_marginright} = $ps->{papersize}->[0] - $ps->{marginleft};
	}
	$ps->{_marginbottom}  = $ps->{marginbottom};
	$ps->{_margintop}     = $ps->{papersize}->[1] - $ps->{margintop};
	$ps->{_bottommargin}  = $ps->{marginbottom};

	# Physical coordinates; will be adjusted to columns if needed.
	$ps->{__leftmargin}   = $ps->{_marginleft};
	$ps->{__rightmargin}  = $ps->{_marginright};
	$ps->{__topmargin}    = $ps->{_margintop};
	$ps->{__bottommargin} = $ps->{_marginbottom};

	# Determine page class and background.
	my $class = 2;		# default
	my $bgpdf = $ps->{formats}->{default}->{background};
	if ( $page_num == 1 ) {
	    $class = 0;		# very first page
	    $bgpdf = $ps->{formats}->{first}->{background}
	      || $ps->{formats}->{title}->{background}
	      || $bgpdf;
	}
	elsif ( $page_num == $startpage ) {
	    $class = 1;		# first of a song
	    $bgpdf = $ps->{formats}->{title}->{background}
	      || $bgpdf;
	}
	if ( $bgpdf ) {
	    my ( $fn, $pg ) = ( $bgpdf, 1 );
	    if ( $bgpdf =~ /^(.+):(\d+)$/ ) {
		( $bgpdf, $pg ) = ( $1, $2 );
	    }
	    $fn = CP->findres($bgpdf);
	    if ( $fn && fs_test( rs => $fn ) ) {
		$pg++ if $ps->{"even-odd-pages"} && !$rightpage;
		$pr->importpage( $fn, $pg );
	    }
	    else {
		warn( "PDF: Missing or empty background document: ",
		      $bgpdf, "\n" );
	    }
	}

	$x = $ps->{__leftmargin};
	$y = $ps->{_margintop};
	$y += $ps->{headspace} if $ps->{'head-first-only'} && $class == 2;
	$x += $ps->{_indent};
	$ps->{_top} = $y;
	$col = 0;
	$vsp_ignorefirst = 1;
	$col_adjust->();

	# Render the 'allpages' images.
	for ( @allpages ) {
	    my %imageinfo = %$_;
	    my $img = delete $imageinfo{img};
	    my $x   = delete $imageinfo{x};
	    my $y   = delete $imageinfo{y};
	    $pr->add_object( $img, $x, $y, %imageinfo );
	}
    };

    my $checkspace = sub {

	# Verify that the amount of space if still available.
	# If not, perform a column break or page break.
	# Use negative argument to force a break.
	# Returns true if there was space.

	my $vsp = $_[0];
	return 1 if $vsp >= 0 && $y - $vsp >= $ps->{_bottommargin};

	if ( ++$col >= $ps->{columns}) {
	    $newpage->();
	    $vsp_ignorefirst = 0;
	}
	$col_adjust->();
	return;
    };

    my $chorddiagrams = sub {
	my ( $chords, $show, $ldisp ) = @_;
	return if $lyrics_only || !$dctl->{show};
	my @chords;
	$chords = $s->{chords}->{chords}
	  if !defined($chords) && $s->{chords};
	$show //= $dctl->{show};
	if ( $chords ) {
	    for ( @$chords ) {
		if ( my $i = $s->{chordsinfo}->{$_} ) {
		    push( @chords, $i ) if $i->has_diagram;
		}
		else {
		    warn("PDF: Missing chord info for \"$_\"\n");
		}
	    }
	}
	return unless @chords;

	# Determine page class.
	my $class = 2;		# default
	if ( $page_num == 1 ) {
	    $class = 0;		# very first page
	}
	elsif ( $page_num == $startpage ) {
	    $class = 1;		# first of a song
	}
	warn( "page: ", $page_num, " ($startpage) cls=$class\n")
	  if $config->{debug}->{pages} & 0x01;

	# If chord diagrams are to be printed in the right column, put
	# them on the first page.
	if ( $show eq "right" && $class <= 1 ) {
	    my $vsp = $dd->vsp( undef, $ps );

	    my $v = int( ( $ps->{_margintop} - $ps->{marginbottom} ) / $vsp );
	    my $c = int( ( @chords - 1) / $v ) + 1;
	    # warn("XXX ", scalar(@chords), ", $c colums of $v max\n");
	    my $column =
	      $ps->{_marginright} - $ps->{_marginleft}
		- ($c-1) * $dd->hsp(undef,$ps)
		- $dd->hsp0(undef,$ps);

	    my $hsp = $dd->hsp(undef,$ps);
	    my $x = $x + $column - $ps->{_indent};
	    $ps->{_rightmargin} = $ps->{papersize}->[0] - $x + $ps->{columnspace};
	    $ps->{__rightmargin} = $x - $ps->{columnspace};
	    set_columns( $ps,
			 $s->{settings}->{columns} || $::config->{settings}->{columns} );
	    $col_adjust->();
	    my $y = $y;
	    while ( @chords ) {

		for ( 0..$c-1 ) {
		    last unless @chords;
		    $dd->draw( shift(@chords), $x + $_*$hsp, $y, $ps );
		}

		$y -= $vsp;
	    }
	}
	elsif ( ( $show eq "top" || $show eq "bottom" )
		&& $class <= 1 && $col == 0) {

	    my $ww = $ps->{_marginright} - $ps->{_marginleft};

	    my $dwidth = $dd->hsp0(undef,$ps); # diag
	    my $dadv   = $dd->hsp1(undef,$ps); # adv
	    my $hsp    = $dwidth + $dadv;      # diag + adv
	    my $vsp    = $dd->vsp( undef, $ps );

	    # Number of diagrams, based on minimal required interspace.
	    # Add one interspace (cuts off right)
	    my $h = int( ( $ww + $dadv ) / $hsp );
	    die("ASSERT: $h should be greater than 0") unless $h > 0;

	    # Spread evenly over multiple lines.
	    if ( $dctl->{align} eq "center" ) {
		my $lines = int((@chords-1)/$h) + 1;
		$h = int((@chords-1)/$lines) + 1;
	    }

	    my $y = $y;
	    if ( $show eq "bottom" ) {
		$y = $ps->{marginbottom} + (int((@chords-1)/$h) + 1) * $vsp;
		$ps->{_bottommargin} = $y;
		$y -= $dd->vsp1( undef, $ps ); # advance height
	    }

	    my $h0 = $h;
	    while ( @chords ) {
		my $x = $x - $ps->{_indent};
		$checkspace->($vsp);
		$pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

		if ( $dctl->{align} eq 'spread' && @chords == $h0  ) {
		    my $delta = $ww + $dadv - min( $h0, 0+@chords ) * $hsp;
		    $dadv = $dd->hsp1(undef,$ps) + $delta / ($h0-1);
		}
		elsif ( $dctl->{align} =~ /center|right|spread/ ) {
		    my $delta = $ww + $dadv - min( $h0, 0+@chords ) * $hsp;
		    $delta /= 2 if $dctl->{align} ne 'right';
		    $x += $delta;
		}

		for ( 1..$h ) {
		    last unless @chords;
		    $dd->draw( shift(@chords), $x, $y, $ps );
		    $x += $dwidth + $dadv;
		}

		$y -= $vsp;
		$pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
	    }
	    $ps->{_top} = $y if $show eq "top";
	}
	elsif ( $show eq "below" ) {
	    # Note that 'below' chords honour the label margin.
	    my $ww = $ps->{__rightmargin} - $ps->{__leftmargin} - $ps->{_indent};

	    my $dwidth = $dd->hsp0(undef,$ps); # diag
	    my $dadv   = $dd->hsp1(undef,$ps); # adv
	    my $hsp    = $dwidth + $dadv;      # diag + adv
	    my $vsp    = $dd->vsp( undef, $ps );

	    my $h = int( ( $ww + $dadv ) / $hsp );
	    die("ASSERT: $h should be greater than 0") unless $h > 0;

	    # Spread evenly over multiple lines.
	    if ( $dctl->{align} eq "center" ) {
		my $lines = int((@chords-1)/$h) + 1;
		$h = int((@chords-1)/$lines) + 1;
	    }

	    my $h0 = $h;
	    while ( @chords ) {
		$checkspace->($vsp);
		my $x = $x;
		$pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

		if ( $dctl->{align} eq 'spread' && @chords == $h0  ) {
		    my $delta = $ww + $dadv - min( $h0, 0+@chords ) * $hsp;
		    $dadv = $dd->hsp1(undef,$ps) + $delta / ($h0-1);
		}
		elsif ( $dctl->{align} =~ /center|right|spread/ ) {
		    my $delta = $ww + $dadv - min( $h0, 0+@chords ) * $hsp;
		    $delta /= 2 if $dctl->{align} ne 'right';
		    $x += $delta;
		}

		for ( 1..$h ) {
		    last unless @chords;
		    $dd->draw( shift(@chords), $x, $y, $ps );
		    $x += $hsp;
		}

		$y -= $vsp;
		$pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
	    }
	}
	$y = $ps->{_top} if $show eq "top";
    };

    my @elts;
    my $dbgop = sub {
	my ( $elts, $pb ) = @_;
	$elts //= $elts[-1];
	$elts = [ $elts ] unless is_arrayref($elts);
	for my $elt ( @$elts ) {
	    my $msg = sprintf("OP L:%2d %s (", $elt->{line},
			      $pb ? "pushback($elt->{type})" : $elt->{type} );
	    $msg .= " " . $elt->{subtype} if $elt->{subtype};
	    $msg .= " U:" . $elt->{uri} if $elt->{uri};
	    $msg .= " O:" . $elt->{orig} if $elt->{orig};
	    $msg .= " D:" . $elt->{delegate} if $elt->{delegate};
	    $msg .= " H:" . $elt->{handler} if $elt->{handler};
	    $msg .= " )";
	    $msg =~ s/\s+\(\s+\)//;
	    if ( $config->{debug}->{ops} > 1 ) {
		require ChordPro::Dumper;
		local *ChordPro::Chords::Appearance::_data_printer = sub {
		    my ( $self, $ddp ) = @_;
		    "ChordPro::Chords::Appearance('" . $self->key . "'" .
		      ($self->format ? (", '" . $self->format . "'") : "") .
		      ")";
		};

		ChordPro::Dumper::ddp( $elt, as => $msg );
	    }
	    else {
		warn( $msg, "\n" );
	    }
	}
    };

    #### CODE STARTS HERE ####

#    prepare_assets( $s, $pr );

    $spreadimage = $s->{spreadimage};

    # Get going.
    $newpage->();

    # Embed source and config for debugging;
    $pr->embed($source->{file})
      if $source->{file}
      && ( $options->{debug}
	   ||
	   $config->{debug}->{runtimeinfo}
	   && $ChordPro::VERSION =~ /_/ );

    my $prev;			# previous element

    my $grid_cellwidth;
    my $grid_barwidth = 0.5 * $fonts->{chord}->{size};
    my $grid_margin;
    my $did = 0;
    my $curctx = "";

    my $elt;			# current element
    @elts = @$sb;		# song elements
    while ( @elts ) {
	$elt = shift(@elts);

	if ( $config->{debug}->{ops} ) {
	    $dbgop->($elt);
	}

	if ( $elt->{type} eq "newpage" ) {
	    $newpage->();
	    showlayout($ps) if $ps->{showlayout} || $config->{debug}->{spacing};
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    $checkspace->(-1);
	    next;
	}

	if ( $elt->{type} ne "set" && !$did++ ) {
	    # Insert top/left/right/bottom chord diagrams.
 	    $chorddiagrams->() unless $dctl->{show} eq "below";

	    # Prepare the assets now we know the page width.
	    prepare_assets( $s, $pr );

	    # Spread image.
            if ( $spreadimage ) {
                if (ref($spreadimage) eq 'HASH' ) {
                    # Spread image doesn't indent.
                    $spreadimage = imagespread( $spreadimage, $x-$ps->{_indent}, $y, $ps );
                }
                $y -= $spreadimage;
            }

	    showlayout($ps) if $ps->{showlayout} || $config->{debug}->{spacing};
	}

	if ( $elt->{type} eq "empty" ) {
	    my $y0 = $y;
	    warn("***SHOULD NOT HAPPEN1***")
	      if $s->{structure} eq "structured";
	    if ( $vsp_ignorefirst ) {
		if ( @elts && $elts[0]->{type} !~ /empty|ignore/ ) {
		    $vsp_ignorefirst = 0;
		}
		next;
	    }
	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};
	    my $vsp = empty_vsp( $elt, $ps );
	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
	    next;
	}

	unless ( $elt->{type} =~ /^(?:control|set|ignore)$/ ) {
	    $vsp_ignorefirst = 0;
	}

	if ( $elt->{type} eq "songline"
	     or $elt->{type} eq "tabline"
	     or $elt->{type} =~ /^comment(?:_box|_italic)?$/ ) {

	    if ( $elt->{context} ne $curctx ) {
		$curctx = $elt->{context};
	    }

	    my $fonts = $ps->{fonts};
	    my $type   = $elt->{type};

	    my $ftext;
	    if ( $type eq "songline" ) {
		$ftext = $curctx eq "chorus" ? $fonts->{chorus} : $fonts->{text};
	    }
	    elsif ( $type =~ /^comment/ ) {
		$ftext = $fonts->{$type} || $fonts->{comment};
	    }
	    elsif ( $type eq "tabline" ) {
		$ftext = $fonts->{tab};
	    }

	    # Get vertical space the songline will occupy.
	    my $vsp = songline_vsp( $elt, $ps );
	    if ( $elt->{type} eq "songline" && !$elt->{indent} ) {
		my $e = wrap( $pr, $elt, $x );
		if ( @$e > 1 ) {
		    $checkspace->($vsp * scalar( @$e ));
		    $elt = shift( @$e );
		    unshift( @elts, @$e );
		}
	    }

	    # Add prespace if fit. Otherwise newpage.
	    $checkspace->($vsp);

	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

	    my $indent = 0;

	    # Handle decorations.

	    if ( $elt->{context} eq "chorus" ) {
		my $style = $ps->{chorus};
		$indent = $style->{indent};
		if ( $style->{bar}->{offset} && $style->{bar}->{width} ) {
		    my $cx = $ps->{__leftmargin} + $ps->{_indent}
		      - $style->{bar}->{offset}
			+ $indent;
		    $pr->vline( $cx, $y, $vsp,
				$style->{bar}->{width},
				$style->{bar}->{color} );
		}
		$curctx = "chorus";
		$i_tag = "" unless $config->{settings}->{choruslabels};
	    }

	    # Substitute metadata in comments.
	    if ( $elt->{type} =~ /^comment/ && !$elt->{indent} ) {
		$elt = { %$elt };
		# Flatten chords/phrases.
		if ( $elt->{chords} ) {
		    $elt->{text} = "";
		    for ( 0..$#{ $elt->{chords} } ) {
			$elt->{text} .= $elt->{chords}->[$_] . $elt->{phrases}->[$_];
		    }
		}
		$elt->{text} = fmt_subst( $s, $elt->{text} );
	    }

	    # Comment decorations.

	    $pr->setfont( $ftext );

=begin xxx

	    my $text = $elt->{text};
	    my $w = $pr->strwidth( $text );

	    # Draw background.
	    my $bgcol = $ftext->{background};
	    if ( $elt->{type} eq "comment" ) {
		# Default to grey.
		$bgcol ||= "#E5E5E5";
		# Since we default to grey, we need a way to cancel it.
		undef $bgcol if $bgcol eq "none";
	    }
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
			     0.5, undef,
			     $ftext->{color} || $ps->{theme}->{foreground} );
	    }

=cut

	    my $r = songline( $elt, $x, $y, $ps, song => $s, indent => $indent );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    unshift( @elts, $r ) if $r;
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
	    my $cx = $ps->{__leftmargin} - $style->{bar}->{offset};
	    $pr->vline( $cx, $cy, vsp($ps), 1, $style->{bar}->{color} );
	    $y -= vsp($ps,4); # chordii
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    warn("NYI: type => verse\n");
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "songline" ) {
		    my $h = songline_vsp( $e, $ps );
		    $checkspace->($h);
		    songline( $e, $x, $y, $ps );
		    $y -= $h;
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

	if ( $elt->{type} eq "gridline" || $elt->{type} eq "strumline" ) {

	    $vsp_ignorefirst = 1, next if $lyrics_only || !$ps->{grids}->{show};

	    my $vsp = grid_vsp( $elt, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

	    my $cells = $grid_margin->[2];
	    $grid_cellwidth = ( $ps->{__rightmargin}
				- $ps->{_indent}
				- $ps->{__leftmargin}
				- ($cells)*$grid_barwidth
			      ) / $cells;
	    warn("L=", $ps->{__leftmargin},
		 ", I=", $ps->{_indent},
		 ", R=", $ps->{__rightmargin},
		 ", C=$cells, GBW=$grid_barwidth, W=", $grid_cellwidth,
		 "\n") if $config->{debug}->{spacing};

	    require ChordPro::Output::PDF::Grid;
	    ChordPro::Output::PDF::Grid::gridline
		( $elt, $x, $y,
		  $grid_cellwidth,
		  $grid_barwidth,
		  $grid_margin,
		  $ps, song => $s, type => $elt->{type},
		  maybe subtype => $elt->{subtype},
		);

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

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
	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

	    songline( $elt, $x, $y, $ps );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    next;
	}

	if ( $elt->{type} eq "image" ) {
	    next if defined $elt->{opts}->{spread};
	    next if $elt->{opts}->{omit};

	    # Images are slightly more complex.
	    # Only after establishing the desired height we can issue
	    # the checkspace call, and we must get $y after that.

	    my $gety = sub {
		my $h = shift;
		my $have = $checkspace->($h);
		$ps->{pr}->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
		return wantarray ? ($y,$have) : $y;
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
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    if ( $elt->{multi} && !$elt->{msel} ) {
		my $i = @{ $elt->{multi} } - 1;
		while ( $i > 0 ) {
		    unshift( @elts, { %$elt, msel => $i } );
		    $i--;
		}
	    }
	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    my $t = $ps->{chorus}->{recall};
	    if ( $t->{type} !~ /^comment(?:_italic|_box)?$/ ) {
		die("Config error: Invalid value for pdf.chorus.recall.type\n");
	    }

	    if ( $t->{quote} && $elt->{chorus} ) {
		unshift( @elts, @{ $elt->{chorus} } );
	    }

	    elsif ( $elt->{chorus}
		    && $elt->{chorus}->[0]->{type} eq "set"
		    && $elt->{chorus}->[0]->{name} eq "label" ) {
		if ( $config->{settings}->{choruslabels} ) {
		    # Use as margin label.
		    unshift( @elts, { %$elt,
				      type => $t->{type} // "comment",
				      font => $ps->{fonts}->{$t->{type} // "label"},
				      text => $ps->{chorus}->{recall}->{tag},
				    } )
		      if $ps->{chorus}->{recall}->{tag} ne "";
		    unshift( @elts, { %$elt,
				      type => "set",
				      name => "label",
				      value => $elt->{chorus}->[0]->{value},
				    } );
		}
		else {
		    # Use as tag.
		    unshift( @elts, { %$elt,
				      type => $t->{type} // "comment",
				      font => $ps->{fonts}->{$t->{type} // "label"},
				      text => $elt->{chorus}->[0]->{value},
				    } )
		}
		if ( $ps->{chorus}->{recall}->{choruslike} ) {
		    $elts[0]->{context} = $elts[1]->{context} = "chorus";
		}
	    }
	    elsif ( $t->{tag} && $t->{type} =~ /^comment(?:_(?:box|italic))?/ ) {
		unshift( @elts, { %$elt,
				  type => $t->{type},
				  text => $t->{tag},
				 } );
		if ( $ps->{chorus}->{recall}->{choruslike} ) {
		    $elts[0]->{context} = "chorus";
		}
	    }
	    redo;
	}

	if ( $elt->{type} eq "tocline" ) {
	    my $vsp = toc_vsp( $elt, $ps );
	    my $vsp0 = toc_vsp( { title => "" }, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

	    $y -= $vsp0 * tocline( $elt, $x, $y, $ps );
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
	    next;
	}

	if ( $elt->{type} eq "diagrams" ) {
 	    $chorddiagrams->( $elt->{chords}, "below", $elt->{line} );
	    next;
	}

	if ( $elt->{type} eq "control" ) {
	    if ( $elt->{name} =~ /^($propitems_re)-size$/ ) {
		if ( defined $elt->{value} ) {
		    $do_size->( $1, $elt->{value} );
		}
		else {
		    # Restore default.
		    $ps->{fonts}->{$1}->{size} =
		      $pr->{_df}->{$1}->{size};
		    warn("No size to restore for font $1\n")
		      unless $ps->{fonts}->{$1}->{size};
		}
	    }
	    elsif ( $elt->{name} =~ /^($propitems_re)-font$/ ) {
		my $f = $1;
		if ( defined $elt->{value} ) {
		    my ( $fn, $sz ) = $elt->{value} =~ /^(.*) (\d+(?:\.\d+)?)$/;
		    $fn //= $elt->{value};
		    if ( $fn =~ m;/;
			 ||
			 $fn =~ m;\.(ttf|otf)$;i ) {
			delete $ps->{fonts}->{$f}->{description};
			delete $ps->{fonts}->{$f}->{name};
			$ps->{fonts}->{$f}->{file} = $elt->{value};
			# Discard $sz. There will be an {xxxsize} following.
		    }
		    elsif ( is_corefont( $fn ) ) {
			delete $ps->{fonts}->{$f}->{description};
			delete $ps->{fonts}->{$f}->{file};
			$ps->{fonts}->{$f}->{name} = is_corefont($fn);
			# Discard $sz. There will be an {xxxsize} following.
		    }
		    else {
			delete $ps->{fonts}->{$f}->{file};
			delete $ps->{fonts}->{$f}->{name};
			$ps->{fonts}->{$f}->{description} = $elt->{value};
		    }
		}
		else {
		    # Restore default.
		    my $sz = $ps->{fonts}->{$1}->{size};
		    $ps->{fonts}->{$f} =
		      { %{ $pr->{_df}->{$f} } };
#		    $ps->{fonts}->{$1}->{size} = $sz;
		}
		$pr->init_font($f);
	    }
	    elsif ( $elt->{name} =~ /^($propitems_re)-color$/ ) {
		if ( defined $elt->{value} ) {
		    $ps->{fonts}->{$1}->{color} = $elt->{value};
		}
		else {
		    # Restore default.
		    $ps->{fonts}->{$1}->{color} =
		      $pr->{_df}->{$1}->{color};
		}
	    }
	    next;
	}

	if ( $elt->{type} eq "set" ) {
	    if ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = is_true($elt->{value})
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
		$grid_margin->[2] = $cells;
		if ( $ps->{labels}->{comment} && $v[4] ne "" ) {
		    unshift( @elts, { %$elt,
				      type => $ps->{labels}->{comment},
				      text => $v[4],
				    } );
		    redo;
		}
		$i_tag = $v[4] unless $lyrics_only;
	    }
	    elsif ( $elt->{name} eq "label" ) {
		next if $elt->{context} eq "grid" && $lyrics_only;
		if ( $ps->{labels}->{comment} && $elt->{value} ne ""  ) {
		    unshift( @elts, { %$elt,
				      type => $ps->{labels}->{comment},
				      text => $elt->{value},
				    } );
		    redo;
		}
		$i_tag = $elt->{value};
	    }
	    elsif ( $elt->{name} eq "context" ) {
		$curctx = $elt->{value};
	    }
	    # Arbitrary config values.
	    elsif ( $elt->{name} =~ /^pdf\.(.+)/ ) {
		prpadd2cfg( $ps, $1 => $elt->{value} );
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

    if ( $dctl->{show} eq "below" ) {
	$chorddiagrams->( undef, "below");
    }

    my $pages = $page_num - $startpage + 1;
    $newpage->(), $pages++,
      if ( $ps->{'pagealign-songs'} > 1 && $pages % 2
	   && ( $opts->{songindex} < $opts->{numsongs}
		|| $opts->{forcealign} ) );

    # Now for the page headings and footers.
    $page_num = $opts->{page_num} - 1;
    $page_idx = $opts->{page_idx} - 1;
    $s->{meta}->{pages} = [ $pages ];

    for my $p ( 1 .. $pages ) {
	$page_num++;
	$page_idx++;
	warn( "page: $page_num($page_idx), ", $s->{meta}->{title}->[0],
	      ", ", plural($pages," page"), "\n")
	  if $config->{debug}->{pages} & 0x01;
	$pr->openpage($page_idx);

	# Put titles and footer.

	# If even/odd pages, leftpage signals whether the
	# header/footer parts must be swapped.
	my $rightpage = 1;
	if ( $ps->{"even-odd-pages"} ) {
	    # Even/odd printing...
	    $rightpage = $page_num % 2 != 0;
	    # Odd/even printing...
	    $rightpage = !$rightpage if $ps->{'even-odd-pages'} < 0;
	}
	$s->{meta}->{'page.side'} = $rightpage ? "right" : "left";

	# margin* are offsets from the edges of the paper.
	# _*margin are offsets taking even/odd pages into account.
	if ( $rightpage ) {
	    $ps->{_leftmargin}  = $ps->{marginleft};
	    $ps->{_rightmargin} = $ps->{marginright};
	}
	else {
	    $ps->{_leftmargin}  = $ps->{marginright};
	    $ps->{_rightmargin} = $ps->{marginleft};
	}

	# _margin* are physical coordinates, taking even/odd pages into account.
	$ps->{_marginleft}    = $ps->{_leftmargin};
	$ps->{_marginright}   = $ps->{papersize}->[0] - $ps->{_rightmargin};
	$ps->{_marginbottom}  = $ps->{marginbottom};
	$ps->{_margintop}     = $ps->{papersize}->[1] - $ps->{margintop};

	# Bottom margin, taking bottom chords into account.
	$ps->{_bottommargin}  = $ps->{marginbottom};

	# Physical coordinates; will be adjusted to columns if needed.
	$ps->{__leftmargin}   = $ps->{_marginleft};
	$ps->{__rightmargin}  = $ps->{_marginright};
	$ps->{__topmargin}    = $ps->{_margintop};
	$ps->{__bottommargin} = $ps->{_marginbottom};

	$s->{meta}->{page} = [ $s->{page} = $opts->{roman}
			       ? roman($page_num) : $page_num ];

	# Determine page class.
	my $class = 2;		# default
	if ( $page_num == 1 ) {
	    $class = 0;		# very first page
	}
	elsif ( $page_num == $startpage ) {
	    $class = 1;		# first of a song
	}
	$s->{meta}->{'page.class'} = $classes[$class];
	warn("page: $page_num($page_idx), side = ", $s->{meta}->{'page.side'},
	     " class = ", $classes[$class], "\n")
	  if $::config->{debug}->{pages} & 0x01;

	# Three-part title handlers.
	my $tpt = sub { tpt( $ps, $class, $_[0], $rightpage, $x, $y, $s ) };

	$x = $ps->{__leftmargin};
	if ( $ps->{headspace} ) {
	    warn("Metadata for pageheading: ", ::dump($s->{meta}), "\n")
	      if $config->{debug}->{meta};
	    $y = $ps->{_margintop} + $ps->{headspace};
	    $y -= $pr->font_bl($fonts->{title});
	    $y = $tpt->("title");
	    $y = $tpt->("subtitle");
	}

	if ( $ps->{footspace} ) {
	    $y = $ps->{marginbottom} - $ps->{footspace};
	    $tpt->("footer");
	}

    }

    return $pages;
}

sub prlabel {
    my ( $ps, $label, $x, $y ) = @_;
    return if $label eq "" || $ps->{_indent} == 0;
    my $align = $ps->{labels}->{align};
    my $font= $ps->{fonts}->{label} || $ps->{fonts}->{text};
    $font->{size} ||= $font->{fd}->{size};
    $ps->{pr}->setfont($font);	# for strwidth.

    # Now we have quoted strings we can have real newlines.
    # Split on real and unescaped (old style) newlines.
    for ( split( /\\n|\n/, $label ) ) {
	my $label = $_;
	if ( $align eq "right" ) {
	    my $avg_space_width = $ps->{pr}->strwidth("m");
	    $ps->{pr}->text( $label,
			     $x - $avg_space_width - $ps->{pr}->strwidth($label),
			     $y, $font );
	}
	elsif ( $align =~ /^cent(?:er|re)$/ ) {
	    $ps->{pr}->text( $label,
			     $x - $ps->{_indent} + $ps->{pr}->strwidth($label)/2,
			     $y, $font );
	}
	else {
	    $ps->{pr}->text( $label,
			     $x - $ps->{_indent}, $y, $font );
	}
	$y -= $font->{size} * 1.2;
    }
}

# Propagate markup entries over the fragments so that each fragment
# is properly terminated.
sub defrag {
    my ( $frag ) = @_;
    my @stack;
    my @res;

    foreach my $f ( @$frag ) {
	my @a = split( /(<.*?>)/, $f );
	if ( @stack ) {
	    unshift( @a, @stack );
	    @stack = ();
	}
	my @r;
	foreach my $a ( @a ) {
	    if ( $a =~ m;^<\s*/\s*(\w+)(.*)>$; ) {
		my $k = $1;
		#$a =~ s/\b //g;
		#$a =~ s/ \b//g;
		if ( @stack ) {
		    if ( $stack[-1] =~ /^<\s*$k\b/ ) {
			pop(@stack);
		    }
		    else {
			warn("Markup error: \"@$frag\"\n",
			     "  Closing <$k> but $stack[-1] is open\n");
			next;
		    }
		}
		else {
		    warn("Markup error: \"@$frag\"\n",
			 "  Closing <$k> but no markup is open\n");
		    next;
		}
	    }
	    elsif ( $a =~ m;^<\s*(\w+)(.*)>$; ) {
		my $k = $1;
		my $v = $2;
		# Do not push if self-closed.
		push( @stack, "<$k$v>" ) unless $v =~ m;/\s*$;;
	    }
	    push( @r, $a );
	}
	if ( @stack ) {
	    push( @r, map { my $t = $_;
			    $t =~ s;^<\s*(\w+).*;</$1>;;
			    $t; } reverse @stack );
	}
	push( @res, join("", @r ) );
    }
    if ( @stack ) {
	warn("Markup error: \"@$frag\"\n",
	     "  Unclosed markup: @{[ reverse @stack ]}\n" );
    }
    #warn("defrag: ", join('', @res), "\n");
    \@res;
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
    my @phrases = @{ defrag( $elt->{phrases} ) };

    if ( $type =~ /^comment/ ) {
	$ftext = $elt->{font} || $fonts->{$type} || $fonts->{comment};
	$ytext  = $ytop - $pr->font_bl($ftext);
	my $song   = $opts{song};
	$x += $opts{indent} if $opts{indent};
	$x += $elt->{indent} if $elt->{indent};
	pr_label_maybe( $ps, $x, $ytext );
	my $t = $elt->{text};
	if ( $elt->{chords} ) {
	    $t = "";
	    my @ph = @{ $elt->{phrases} };
	    for ( @{ $elt->{chords} }) {
		my $chord = $_;	# prevent chord clobber in 2pass mode
		if ( $chord eq '' ) {
		}
		else {
		    $chord = $chord->chord_display;
		}
		$t .= $chord . shift(@ph);
	    }
	}
	my ( $text, $ex ) = wrapsimple( $pr, $t, $x, $ftext );
	$pr->text( $text, $x, $ytext, $ftext );
	my $wi = $pr->strwidth( $config->{settings}->{wrapindent}//"x" );
	return $ex ne ""
	  ? { %$elt,
	      indent => $wi,
	      text => $ex, chords => undef  }
	  : undef;
    }
    if ( $type eq "tabline" ) {
	$ftext = $fonts->{tab};
	$ytext  = $ytop - $pr->font_bl($ftext);
	$x += $opts{indent} if $opts{indent};
	pr_label_maybe( $ps, $x, $ytext );
	$pr->text( $elt->{text}, $x, $ytext, $ftext, undef, "no markup" );
	return;
    }

    # assert $type eq "songline";
    $ftext = $fonts->{ $elt->{context} eq "chorus" ? "chorus" : "text" };
    $ytext  = $ytop - $pr->font_bl($ftext); # unless lyrics AND chords

    my $fchord = $fonts->{chord};
    my $ychord = $ytop - $pr->font_bl($fchord);

    # Just print the lyrics if no chords.
    if ( $lyrics_only
	 or
	 $suppress_empty_chordsline && !has_visible_chords($elt)
       ) {
	my $x = $x;
	$x += $opts{indent} if $opts{indent};
	$x += $elt->{indent} if $elt->{indent};
	pr_label_maybe( $ps, $x, $ytext );
	my ( $text, $ex ) = wrapsimple( $pr, join( "", @phrases ),
					$x, $ftext );
	$pr->text( $text, $x, $ytext, $ftext );
	my $wi = $pr->strwidth( $config->{settings}->{wrapindent}//"x" );
	return $ex ne ""
	  ? { %$elt,
	      indent => $wi,
	      phrases => [$ex] }
	  : undef;
    }

    if ( $chordscol || $inlinechords ) {
	$ytext  = $ychord if $ytext  > $ychord;
	$ychord = $ytext;
    }
    elsif ( $chordsunder ) {
	( $ytext, $ychord ) = ( $ychord, $ytext );
	# Adjust lyrics baseline for the chords.
	$ychord -= $ps->{fonts}->{text}->{size}
	  * $ps->{spacing}->{lyrics};
    }
    else {
	# Adjust lyrics baseline for the chords.
	$ytext -= $ps->{fonts}->{chord}->{size}
	          * $ps->{spacing}->{chords};
    }

    $elt->{chords} //= [ '' ];
    $x += $elt->{indent} if $elt->{indent};

    my $chordsx = $x;
    $chordsx += $ps->{chordscolumn} if $chordscol;
    if ( $chordsx < 0 ) {	#### EXPERIMENTAL
	($x, $chordsx) = (-$chordsx, $x);
    }
    $x += $opts{indent} if $opts{indent};

    # How to embed the chords.
    if ( $inlinechords ) {
	$inlinechords = '[%s]' unless $inlinechords =~ /%[cs]/;
	$ychord = $ytext;
    }

    my @chords;
    my $n = $#{$elt->{chords}};
    foreach my $i ( 0 .. $n ) {

	my $chord = $elt->{chords}->[$i];
	my $phrase = $phrases[$i];

	if ( $chordscol && $chord ne "" ) {

	    if ( $chordscapo ) {
		$pr->text(fmt_subst( $opts{song}, $ps->{capoheading} ),
			  $chordsx,
			  $ytext + $ftext->{size} *
			      $ps->{spacing}->{chords},
			  $fonts->{chord} );
		undef $chordscapo;
	    }

	    # Underline the first word of the phrase, to indicate
	    # the actual chord position. Skip leading non-letters.
	    $phrase = " " if $phrase eq "";

	    # This may screw up in some markup situations.
	    my ( $pre, $word, $rest ) =
	      $phrase =~ /^((?:\<[^>]*?\>|\W)+)?(\w+)(.+)?$/;
	    # This should take case of most cases...
	    unless ( $i == $n || defined($rest) && $rest !~ /^\</ ) {
		$rest = chop($word) . ($rest//"");
	    }
	    $phrase = ($pre//"") . "<u>" . $word . "</u>" . ($rest//"");

	    # Print the text.
	    pr_label_maybe( $ps, $x, $ytext );
	    $x = $pr->text( $phrase, $x, $ytext, $ftext );

	    # Collect chords to be printed in the side column.
	    $chord = $chord->chord_display;
	    push( @chords, $chord );
	}
	else {
	    my $xt0 = $x;
	    my $font = $fchord;
	    if ( $chord ne '' ) {
		my $ch = $chord->chord_display;
		my $dp = $ch . " ";
		if ( $chord->info->is_annotation ) {
		    $font = $fonts->{annotation};
		    ( $dp = $inlineannots ) =~ s/%[cs]/$ch/g
		      if $inlinechords;
		}
		elsif ( $inlinechords ) {
		    ( $dp = $inlinechords ) =~ s/%[cs]/$ch/g;
		}
		$xt0 = $pr->text( $dp, $x, $ychord, $font );
	    }

	    # Do not indent chorus labels (issue #81).
	    pr_label_maybe( $ps, $x-$opts{indent}, $ytext );
	    if ( $inlinechords ) {
		$x = $pr->text( $phrase, $xt0, $ytext, $ftext );
	    }
	    else {
		my $xt1;
		if ( $phrase =~ /^\s+$/ ) {
		    $xt1 = $xt0 + length($phrase) * $pr->strwidth(" ",$ftext);
#		    $xt1 = $pr->text( "n" x length($phrase), $xt0, $ytext, $ftext );
		}
		else {
		    $xt1 = $pr->text( $phrase, $x, $ytext, $ftext );
		}
		if ( $xt0 > $xt1 ) { # chord is wider
		    # Do we need to insert a split marker?
		    if ( $i < $n
			 && demarkup($phrase) !~ /\s$/
			 && demarkup($phrases[$i+1]) !~ /^\s/
			 # And do we have one?
			 && ( my $marker = $ps->{'split-marker'} ) ) {

			# Marker has 3 parts: start, repeat, and final.
			# final is always printed, last.
			# start is printed if there is enough room.
			# repeat is printed repeatedly to fill the rest.
			$marker = [ $marker, "", "" ]
			  unless is_arrayref($marker);

			# Reserve space for final.
			my $w = 0;
			$pr->setfont($ftext);
			$w = $pr->strwidth($marker->[2]) if $marker->[2];
			$xt0 -= $w;
			# start or repeat (if no start).
			my $m = $marker->[0] || $marker->[1];
			$x = $xt1;
			$x = $xt0 unless $m;
			while ( $x < $xt0 ) {
			    $x = $pr->text( $m, $x, $ytext, $ftext );
			    # After the first, use repeat.
			    $m = $marker->[1];
			    $x = $xt0, last unless $m;
			}
			# Print final.
			if ( $w ) {
			    $x = $pr->text( $marker->[2], $x, $ytext, $ftext );
			}
		    }
		    # Adjust the position for the chord and spit marker width.
		    $x = $xt0 if $xt0 > $x;
		}
		else {
		    # Use lyrics width.
		    $x = $xt1;
		}
	    }
	}
    }

    # Print side column with chords, if any.
    $pr->text( join(",  ", @chords),
	       $chordsx, $ychord, $fchord )
      if @chords;

    return;
}

sub imageline_vsp {
}

sub imageline {
    my ( $elt, $x, $ps, $gety ) = @_;

    my $x0 = $x;
    my $pr = $ps->{pr};
    my $id = $elt->{id};
    my $asset = $assets->{$id};
    unless ( $asset ) {
	warn("Line " . $elt->{line} . ", Undefined image id: \"$id\"\n");
    }
    my $opts = { %{$asset->{opts}//{}}, %{$elt->{opts}//{}} };
    my $img = $asset->{data};
    my $label = $opts->{label};
    my $anchor = $opts->{anchor} //= "float";
    my $allpages = 0;
    if ( $anchor eq "allpages" ) {
	$anchor = "page";
	$allpages = 1;
    }
    my $width = $opts->{width};
    my $height = $opts->{height};
    my $avwidth  = $asset->{vwidth};
    my $avheight = $asset->{vheight};
    my $scalex = $asset->{opts}->{design_scale} || 1;
    my $scaley = $scalex;

    unless ( $img ) {
	return "Unhandled image type: asset=$id";
    }
    if ( $assets->{$id}->{multi} ) {
	$elt->{multi} = $assets->{$id}->{multi};
    }
    if ( $elt->{msel} ) {
	for ( $assets->{$id}->{multi}->[$elt->{msel}] ) {
	    $img = $_->{xo};
	    # Take vwidth/vheight from subimage.
	    $avwidth  = $_->{vwidth};
	    $avheight = $_->{vheight};
	}
	$width = $height = 0;
	$label = "";
    }

    # Available width and height.
    my ( $pw, $ph );
    if ( $anchor eq "paper" ) {
	( $pw, $ph ) = @{$ps->{papersize}};
    }
    else {
	if ( $ps->{columns} > 1 ) {
	    $pw = $ps->{columnoffsets}->[1]
	      - $ps->{columnoffsets}->[0]
	      - $ps->{columnspace};
	}
	else {
	    # $pw = $ps->{__rightmargin} - $ps->{_leftmargin};
	    # See issue #428.
	    $pw = $ps->{_marginright} - $ps->{_leftmargin};
	}
	$ph = $ps->{_margintop} - $ps->{_marginbottom};
	$pw -= $ps->{_indent} if $anchor eq "float";
    }

    if ( $width && $width =~ /^(\d+(?:\.\d+)?)\%$/ ) {
	$width  = $1/100 * $pw;
    }
    if ( $height && $height =~ /^(\d+(?:\.\d+)?)\%$/ ) {
	$height = $1/100 * $ph;
    }

    my ( $w, $h ) = ( $width  || $avwidth  || $img->width,
		      $height || $avheight || $img->height );

    # Scale proportionally if width xor height was explicitly requested.
    if ( $width && !$height ) {
	$h = $width / ($avwidth || $img->width) * ($avheight || $img->height);
    }
    elsif ( !$width && $height ) {
	$w = $height / ($avheight || $img->height) * ($avwidth || $img->width);
    }

    if ( $w > $pw ) {
	$scalex = $pw / $w;
    }
    if ( $h*$scalex > $ph ) {
	$scalex = $ph / $h;
    }
    $scaley = $scalex;
    if ( $opts->{scale} ) {
	my @s;
	if ( is_arrayref( $opts->{scale} ) ) {
	    @s = @{$opts->{scale}};
	}
	else {
	    for ( split( /,/, $opts->{scale} ) ) {
		$_ = $1 / 100 if /^([\d.]+)\%$/;
		push( @s, $_ );
	    }
	    push( @s, $s[0] ) unless @s > 1;
	    carp("Invalid scale attribute: \"$opts->{scale}\" (too many values)\n")
	      unless @s == 2;
	}
	$scalex *= $s[0];
	$scaley *= $s[1];
    }

    warn("Image scale: ", pv($scalex), " ", pv($scaley), "\n")
      if $config->{debug}->{images};
    $w *= $scalex;
    $h *= $scaley;

    my 	$align = $opts->{align};

    # If the image is wider than the page width, and scaled to fit, it may
    # not be centered (https://github.com/ChordPro/chordpro/issues/428#issuecomment-2356447522).
    if ( $w >= $pw ) {
	$align = "left";
    }

    my $ox = $opts->{x};
    my $oy = $opts->{y};

    # Not sure I like this...
    if ( defined $oy && $oy =~ /base([-+].*)/ ) {
	$oy = -$1;
	$oy += $opts->{base}*$scaley if $opts->{base};
	warn("Y: ", $opts->{y}, " BASE: ", $opts->{base}, " -> $oy\n");
    }

    if ( $anchor eq "float" ) {
	# Note that with indent, the image is aligned to the indented area.
	$align //= ( $opts->{center} // 1 ) ? "center" : "left";
	# Note that image is placed aligned on $x.
	if ( $align eq "center" ) {
	    $x += $pw / 2;
	}
	elsif ( $align eq "right" ) {
	    $x += $pw;
	}
	warn("Image $align: $_[1] -> $x\n") if $config->{debug}->{images};
    }
    $align //= "left";

    # Extra scaling in case the available page width is temporarily
    # reduced, e.g. due to a right column for chords.
    my $w_actual = $ps->{__rightmargin}-$ps->{_leftmargin}-$ps->{_indent};
    my $xtrascale = $w < $w_actual ? 1
      : $w_actual / ( $ps->{_marginright}-$ps->{_leftmargin}-$ps->{_indent} );

    my ( $y, $spaceok ) = $gety->($anchor eq "float" ? $h*$xtrascale : 0);
    # y may have been changed by checkspace.
    if ( !$spaceok && $xtrascale < 1 ) {
	# An extra scaled image is flushed to the next page, recalc xtrascale.
	$y = $gety->($anchor eq "float" ? $h : 0);
	$xtrascale = ( $ps->{__rightmargin}-$ps->{_leftmargin} ) /
	  ( $ps->{_marginright}-$ps->{_leftmargin} );
	warn("ASSERT: xtrascale = $xtrascale, should be 1\n")
	  unless abs( $xtrascale - 1 ) < 0.01; # fuzz;
    }
    if ( defined ( my $tag = $i_tag // $label ) ) {
	$i_tag = $tag;
    	my $ftext = $ps->{fonts}->{comment};
	my $ytext  = $y - $pr->font_bl($ftext);
	pr_label_maybe( $ps, $x0, $ytext );
    }

    my $calc = sub {
	my ( $l, $r, $t, $b, $mirror ) = @_;
	my $_ox = $ox // 0;
	my $_oy = $oy // 0;
	$x = $l;
	$y = $t;

	if ( $_ox =~ /^([-+]?[\d.]+)\%$/ ) {
	    $ox = $_ox = $1/100 * ($r - $l) - ( $1/100 ) * $w;
	}
	if ( $_oy =~ /^([-+]?[\d.]+)\%$/ ) {
	    $oy = $_oy = $1/100 * ($t - $b) - ( $1/100 ) * $h;
	}
	if ( $mirror ) {
	    $x = $r - $w if $_ox =~ /^-/;
	    $y = $b + $h if $_oy =~ /^-/;
	}
    };

    if ( $anchor eq "column" ) {
	# Relative to the column.
	$calc->( @{$ps}{qw( __leftmargin __rightmargin
			    __topmargin __bottommargin )}, 0 );
    }
    elsif ( $anchor eq "page" ) {
	# Relative to the page.
	$calc->( @{$ps}{qw( _marginleft _marginright
			    __topmargin __bottommargin )}, 0 );
    }
    elsif ( $anchor eq "paper" ) {
	# Relative to the paper.
	$calc->( 0, $ps->{papersize}->[0], $ps->{papersize}->[1], 0, 1 );
    }
    else {
	# image is line oriented.
	# See issue #428.
	# $calc->( $x, $ps->{__rightmargin}, $y, $ps->{__bottommargin}, 0 );
	$calc->( $x, $ps->{_marginright}, $y, $ps->{__bottommargin}, 0 );
	warn( pv( "_MR = ", $ps->{_marginright} ),
	      pv( ", _RM = ", $ps->{_rightmargin} ),
	      pv( ", __RM = ", $ps->{__rightmargin} ),
	      pv( ", XS = ", $xtrascale ),
	      "\n") if 0;
    }

    $x += $ox if defined $ox;
    $y -= $oy if defined $oy;
    warn( sprintf("add_image x=%.1f y=%.1f w=%.1f h=%.1f scale=%.1f,%.1f,%.1f (%s x%+.1f y%+.1f) %s\n",
		  $x, $y, $w, $h,
		  $w/$img->width * $xtrascale,
		  $h/$img->height * $xtrascale,
		  $xtrascale,
		  $anchor,
		  $ox//0, $oy//0, $align,
		 )) if $config->{debug}->{images};

    $pr->add_object( $img, $x, $y,
		     xscale => $w/$img->width * $xtrascale,
		     yscale => $h/$img->height * $xtrascale,
		     border => $opts->{border} || 0,
		     maybe bordertrbl => $opts->{bordertrbl},
		     valign => $opts->{valign} // "top",
		     align  => $align,
		     maybe href => $opts->{href},
		   );

    # For 'allpages' images, remember the calculated results.
    if ( $allpages ) {
	push( @allpages,
	      { img => $img,
		x => $x, y => $y,
		xscale => $w/$img->width * $xtrascale,
		yscale => $h/$img->height * $xtrascale,
		border => $opts->{border} || 0,
		maybe bordertrbl => $opts->{bordertrbl},
		valign => $opts->{valign} // "top",
		align  => $align,
		maybe href => $opts->{href},
	      } );
    }

    if ( $anchor eq "float" ) {
	return ($h + ($oy//0)) * $xtrascale;
    }
    return 0;			# vertical size
}

sub imagespread {
    my ( $si, $x, $y, $ps ) = @_;
    my $pr = $ps->{pr};

    my $tag = "id=" . $si->{id};
    return "Unknown asset: $tag"
      unless exists( $assets->{$si->{id}} );
    my $asset = $assets->{$si->{id}};
    my $img = $asset->{data};
    return "Unhandled asset: $tag"
      unless $img;
    my $opts = {};

    # Available width and height.
    my $pw = $ps->{_marginright} - $ps->{_marginleft};
    my $ph = $ps->{_margintop} - $ps->{_marginbottom};

    my ( $w, $h ) = ( $opts->{width}  || $img->width,
		      $opts->{height} || $img->height );

    # Design scale.
    my $scalex = $asset->{opts}->{scale} || 1;
    my $scaley = $scalex;

    if ( $w > $pw ) {
	$scalex = $pw / $w;
    }
    if ( $h*$scalex > $ph ) {
	$scalex = $ph / $h;
    }
    $scaley = $scalex;

    if ( $opts->{scale} ) {
	my @s;
	if ( is_arrayref($opts->{scale}) ) {
	    @s = @{$opts->{scale}};
	}
	else {
	    for ( split( /,/, $opts->{scale} ) ) {
		$_ = $1 / 100 if /^([\d.]+)\%$/;
		push( @s, $_ );
	    }
	    push( @s, $s[0] ) unless @s > 1;
	    carp("Invalid scale attribute: \"$opts->{scale}\" (too many values)\n")
	      unless @s == 2;
	}
	$scalex *= $s[0];
	$scaley *= $s[1];
    }

    warn("Image scale: $scalex $scaley\n") if $config->{debug}->{images};
    $h *= $scalex;
    $w *= $scaley;

    my $align = $opts->{align};
    $align //= ( $opts->{center} // 1 ) ? "center" : "left";
    # Note that image is placed aligned on $x.
    if ( $align eq "center" ) {
	$x += $pw / 2;
    }
    elsif ( $align eq "right" ) {
	$x += $pw;
    }
    warn("Image $align: $_[1] -> $x\n") if $config->{debug}->{images};

    warn("add_image\n") if $config->{debug}->{images};
    # $pr->add_image( $img, $x, $y, $w, $h, $opts->{border} || 0 );
    $pr->add_object( $img, $x, $y,
		     xscale => $w/$img->width,
		     yscale => $h/$img->height,
		     border => $opts->{border} || 0,
		     maybe bordertrbl => $opts->{bordertrbl},
		     valign => "top",
		     align  => $align,
		   );

    return $h + $si->{space};			# vertical size
}

sub tocline {
    my ( $elt, $x, $y, $ps ) = @_;

    my $pr = $ps->{pr};
    my $fonts = $ps->{fonts};
    my $y0 = $y;
    my $ftoc = $fonts->{toc};
    $y -= $pr->font_bl($ftoc);
    $pr->setfont($ftoc);
    my $tpl = $elt->{title};
    my $vsp;
    my $lines = 0;

    my $p = $elt->{pageno} // "";
    my $pw = $pr->strwidth($p);
    my $ww = $ps->{__rightmargin} - $x - $pr->strwidth("xxx$p");
    $tpl = ( $elt->{break} =~ s/\n/\\n/gr ) . "\\n" . $tpl if $elt->{break};
    for my $text ( split( /\\n/, $tpl ) ) {
	$lines++;
	# Suppress unclosed markup warnings.
	local $SIG{__WARN__} = sub{
	    CORE::warn(@_) unless "@_" =~ /Unclosed markup/;
	};
	# Get the part that fits (hopefully, all) and print.
	( $text, my $ex ) = @{ defrag( [ $pr->wrap( $text, $ww ) ] ) };
	$pr->text( $text, $x, $y );
	unless ($vsp) {
	    $ps->{pr}->text( $p, $ps->{__rightmargin} - $pw, $y );
	    $vsp = _vsp("toc", $ps);
	    $x += $pr->strwidth( $config->{settings}->{wrapindent} )
	      if $ex ne "";
	}
	$y -= $vsp;
	if ( $ex ne "" ) {
	    $text = $ex;
	    redo;
	}
    }

    if ( $elt->{page} ) {
	my $ann = $pr->{pdfpage}->annotation;
	$ann->link($elt->{page});
	$ann->rect( $ps->{__leftmargin}, $y0-$lines*$vsp, $ps->{__rightmargin}, $y0 );
    }

    return $lines;
}

sub has_visible_chords {
    my ( $elt ) = @_;
    if ( $elt->{chords} ) {
	for ( @{ $elt->{chords} } ) {
	    next if defined;
	    warn("Undefined chord in chords: ", ::dump($elt) );
	}
	return join( "", @{ $elt->{chords} } ) =~ /\S/;
    }
    return;
}

sub has_visible_text {
    my ( $elt ) = @_;
    $elt->{phrases} && join( "", @{ $elt->{phrases} } ) =~ /\S/;
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

    # Vertical span of the lyrics and chords.
#    my $vsp = $fonts->{text}->{size} * $ps->{spacing}->{lyrics};
    my $vsp = text_vsp( $elt, $ps );
    my $csp = $fonts->{chord}->{size} * $ps->{spacing}->{chords};

    return $vsp if $lyrics_only || $chordscol;

    return $vsp if $suppress_empty_chordsline && ! has_visible_chords($elt);

    # No text printing if no text.
    $vsp = 0 if $suppress_empty_lyricsline && join( "", @{ $elt->{phrases} } ) !~ /\S/;

    if ( $inlinechords ) {
	$vsp = $csp if $csp > $vsp;
    }
    else {
	# We must show chords above lyrics, so add chords span.
	$vsp += $csp;
    }
    return $vsp;
}

sub _vsp {
    my ( $eltype, $ps, $sptype ) = @_;
    $sptype ||= $eltype;

    # Calculate the vertical span of this element.

    my $font = $ps->{fonts}->{$eltype};
    confess("Font $eltype has no size!") unless $font->{size};
    $font->{size} * $ps->{spacing}->{$sptype};
}

sub empty_vsp { _vsp( "empty", $_[1] ) }
sub grid_vsp  { _vsp( "grid",  $_[1] ) }
sub tab_vsp   { _vsp( "tab",   $_[1] ) }

sub toc_vsp   {
    my $vsp = _vsp( "toc",   $_[1] );
    my $tpl = $_[0]->{title};
    $tpl = $_[0]->{break} . "\\n" . $tpl if $_[0]->{break};
    my $ret = $vsp;
    while ( $tpl =~ /\\n/g ) {
	$ret += $vsp;
    }
    return $ret;
}

sub text_vsp {
    my ( $elt, $ps ) = @_;

    my $ftext = $ps->{fonts}->{ $elt->{context} eq "chorus"
				? "chorus" : "text" };
    my $layout = $ps->{pr}->{layout}->copy;
    $layout->set_font_description( $ftext->{fd} );
    $layout->set_font_size( $ftext->{size} );
    #warn("vsp: ".join( "", @{$elt->{phrases}} )."\n");

    my $msg = "";
    {
	local $SIG{__WARN__} = sub { $msg .= "@_" };
	$layout->set_markup( join( "", @{$elt->{phrases}} ) );
    }
    if ( $msg && $elt->{line} ) {
	$msg =~ s/^(.*)\n\s+//;
	warn("Line ", $elt->{line}, ", $msg\n");
    }
    my $vsp = $layout->get_size->{height} * $ps->{spacing}->{lyrics};
    #warn("vsp $vsp \"", $layout->get_text, "\"\n");
    # Calculate the vertical span of this line.

    _vsp( $elt->{context} eq "chorus" ? "chorus" : "text", $ps, "lyrics" );
}

sub set_columns {
    my ( $ps, $cols ) = @_;
    my @cols;
    if ( is_arrayref($cols) ) {
	@cols = @$cols;
	$cols = @$cols;
    }
    unless ( $cols ) {
	$cols = $ps->{columns} ||= 1;
    }
    else {
	$ps->{columns} = $cols ||= 1;
    }

    my $w = $ps->{papersize}->[0]
      - $ps->{_leftmargin} - $ps->{_rightmargin};
    $ps->{columnoffsets} = [ 0 ];

    if ( @cols ) {		# columns with explicit widths
	my $stars;
	my $wx = $w + $ps->{columnspace}; # available
	for ( @cols ) {
	    if ( !$_ || $_ eq '*' ) {
		$stars++;
	    }
	    elsif ( /^(\d+)%$/ ) {
		$_ = $1 * $w / 100; # patch
	    }
	    else {
		$wx -= $_;	# subtract from avail width
	    }
	}
	my $sw = $wx / $stars if $stars;
	my $l = 0;
	for ( @cols ) {
	    if ( !$_ || $_ eq '*' ) {
		$l += $sw;
	    }
	    else {
		$l += $_;
	    }
	    push( @{ $ps->{columnoffsets} }, $l );
	}
	#warn("COL: @{ $ps->{columnoffsets} }\n");
	return;
    }

    push( @{ $ps->{columnoffsets} }, $w ), return unless $cols > 1;

    my $d = ( $w - ( $cols - 1 ) * $ps->{columnspace} ) / $cols;
    $d += $ps->{columnspace};
    for ( 1 .. $cols-1 ) {
	push( @{ $ps->{columnoffsets} }, $_ * $d );
    }
    push( @{ $ps->{columnoffsets} }, $w );
    #warn("COL: @{ $ps->{columnoffsets} }\n");
}

sub showlayout {
    my ( $ps ) = @_;
    my $pr = $ps->{pr};
    my $col = "red";
    my $lw = 0.5;
    my $font = $ps->{fonts}->{grid};

    my $mr = $ps->{_rightmargin};
    my $ml = $ps->{_leftmargin};

    my $f = sub {
	my $t = sprintf( "%.1f", shift );
	$t =~ s/\.0$//;
	return $t;
    };

    $pr->rectxy( $ml,
		 $ps->{marginbottom},
		 $ps->{papersize}->[0]-$mr,
		 $ps->{papersize}->[1]-$ps->{margintop},
		 $lw, undef, $col);

    my $fsz = 7;
    my $ptop = $ps->{papersize}->[1]-$ps->{margintop}+$fsz-3;
    $pr->setfont($font,$fsz);
    $pr->text( "<span color='red'>$ml</span>",
	       $ml, $ptop, $font, $fsz );
    my $t = $f->($ps->{papersize}->[0]-$mr);
    $pr->text( "<span color='red'>$t</span>",
	       $ps->{papersize}->[0]-$mr-$pr->strwidth("$mr"),
	       $ptop, $font, $fsz );
    $t = $f->($ps->{papersize}->[1]-$ps->{margintop});
    $pr->text( "<span color='red'>$t  </span>",
	       $ml-$pr->strwidth("$t  "),
	       $ps->{papersize}->[1]-$ps->{margintop}-2,
	       $font, $fsz );
    $t = $f->($ps->{marginbottom});
    $pr->text( "<span color='red'>$t  </span>",
	       $ml-$pr->strwidth("$t  "),
	       $ps->{marginbottom}-2,
	       $font, $fsz );
    my @a = ( $ml,
	      $ps->{papersize}->[1]-$ps->{margintop}+$ps->{headspace},
	      $ps->{papersize}->[0]-$ml-$mr,
	      $lw, $col );
    $pr->hline(@a);
    $t = $f->($a[1]);
    $pr->text( "<span color='red'>$t  </span>",
	       $ml-$pr->strwidth("$t  "),
	       $a[1]-2,
	       $font, $fsz );
    $a[1] = $ps->{marginbottom}-$ps->{footspace};
    $pr->hline(@a);
    $t = $f->($a[1]);
    $pr->text( "<span color='red'>$t  </span>",
	       $ml-$pr->strwidth("$t  "),
	       $a[1]-2,
	       $font, $fsz );

    my $spreadimage = $ps->{_spreadimage};
    if ( defined($spreadimage) && !ref($spreadimage) ) {
	my $mr = $ps->{marginright};
	$a[1] = $ps->{papersize}->[1]-$ps->{margintop} - $spreadimage;
	$a[2] = $ps->{papersize}->[0]-$ml-$mr;
	$pr->hline(@a);
	$t = $f->($a[1]);
	$pr->text( "<span color='red'>$t  </span>",
		   $ml-$pr->strwidth("$t  "),
		   $a[1]-2,
		   $font, $fsz );
	$a[0] = $ps->{papersize}->[0]-$mr;
	$a[1] = $ps->{papersize}->[1]-$ps->{margintop};
	$a[2] = $a[1] - $ps->{marginbottom};
	$pr->vline(@a);
	$t = $f->($a[0]);
	$pr->text( "<span color='red'>$t  </span>",
		   $a[0]-$pr->strwidth("$t")/2,
		   $ptop,
		   $font, $fsz );
    }

    my @off = @{ $ps->{columnoffsets} };
    pop(@off);
    @off = ( $ps->{chordscolumn} ) if $chordscol;
    @a = ( undef,
	   $ps->{marginbottom},
	   $ps->{margintop}-$ps->{papersize}->[1]+$ps->{marginbottom},
	   $lw, $col );
    foreach my $i ( 0 .. @off-1 ) {
	next unless $off[$i];
	$a[0] = $f->($ml + $off[$i]);
	$pr->text( "<span color='red'>$a[0]</span>",
		   $a[0] - $pr->strwidth($a[0])/2, $ptop, $font, $fsz );
	$pr->vline(@a);
	$a[0] = $f->($ml + $off[$i] - $ps->{columnspace});
	$pr->text( "<span color='red'>$a[0]</span>",
		   $a[0] - $pr->strwidth($a[0])/2, $ptop, $font, $fsz );
	$pr->vline(@a);
	if ( $ps->{_indent} ) {
	    $a[0] = $ml + $off[$i] + $ps->{_indent};
	    $pr->vline(@a);
	}
    }
    if ( $ps->{_indent} ) {
	$a[0] = $ml + $ps->{_indent};
	$pr->vline(@a);
    }
}


# Get a format string for a given page class and type.
# Page classes have fallbacks.
sub get_format {
    my ( $ps, $class, $type, $rightpage  ) = @_;
    for ( my $i = $class; $i < @classes; $i++ ) {
	$class = $classes[$i];
	next if $class eq 'filler';
	my $fmt;
	my $swap = !$rightpage;
	if ( !$rightpage
	     && exists($ps->{formats}->{$class."-even"}->{$type}) ) {
	    $fmt = $ps->{formats}->{$class."-even"}->{$type};
	    $swap = 0;
	}
	elsif ( exists($ps->{formats}->{$class}->{$type}) ) {
	    $fmt = $ps->{formats}->{$class}->{$type};
	}
	next unless $fmt;

	# This should be dealt with in Config...
	$fmt = [ $fmt ] if @$fmt == 3 && !is_arrayref($fmt->[0]);

	# Swap left/right for even pages.
	if ( $swap ) {
	    # make a copy!
	    $fmt = [ map { [ reverse @$_ ] } @$fmt ];
	}

	if ( $::config->{debug}->{pages} & 0x02 ) {
	    warn( "format[$class,$type], ",
		  $rightpage ? "right" : "left",
		  ", swap = ", $swap ? "yes" : "no",
		  ", fmt = \"" . join('" "', @{$fmt->[0]}) . "\"\n");
	}
	return $fmt if $fmt;
    }
    return;
}

# Three-part titles.
# Note: baseline printing.
sub tpt {
    my ( $ps, $class, $type, $rightpage, $x, $y, $s ) = @_;
    my $fmt = get_format( $ps, $class, $type, $rightpage );
    return unless $fmt;
    warn("page: ", $s->{meta}->{page}->[0],
	 ", fmt[", $s->{meta}->{"page.class"}, ",$type] = \"",
	 join('" "',@{$fmt->[0]}), "\"\n" )
      if $::config->{debug}->{pages} & 0x01;

    my $pr = $ps->{pr};
    my $font = $ps->{fonts}->{$type};

    my $havefont;
    my $rm = $ps->{papersize}->[0] - $ps->{_rightmargin};

    for my $fmt ( @$fmt ) {
	if ( @$fmt % 3 ) {
	    die("ASSERT: " . scalar(@$fmt)," part format $class $type");
	}

	# Left part. Easiest.
	if ( $fmt->[0] ) {
	    my $t = fmt_subst( $s, $fmt->[0] );
	    if ( $t ne "" ) {
		$pr->setfont($font) unless $havefont++;
		$pr->text( $t, $x, $y );
	    }
	}

	# Center part.
	if ( $fmt->[1] ) {
	    my $t = fmt_subst( $s, $fmt->[1] );
	    if ( $t ne "" ) {
		$pr->setfont($font) unless $havefont++;
		$pr->text( $t, ($rm+$x-$pr->strwidth($t))/2, $y );
	    }
	}

	# Right part.
	if ( $fmt->[2] ) {
	    my $t = fmt_subst( $s, $fmt->[2] );
	    if ( $t ne "" ) {
		$pr->setfont($font) unless $havefont++;
		$pr->text( $t, $rm-$pr->strwidth($t), $y );
	    }
	}

	$y -= $font->{size} * ($ps->{spacing}->{$type} || 1);
    }

    # Return updated baseline.
    return $y;
}

sub wrap {
    my ( $pr, $elt, $x ) = @_;
    my $res = [];
    my @chords  = @{ $elt->{chords} // [] };
    my @phrases = @{ defrag( $elt->{phrases} // [] ) };
    my @rchords;
    my @rphrases;
    my $m = $pr->{ps}->{__rightmargin};
    my $wi = $pr->strwidth( $config->{settings}->{wrapindent}//"x",
			    $pr->{ps}->{fonts}->{text} );
    #warn("WRAP x=$x rm=$m w=", $m - $x, "\n");

    while ( @chords ) {
	my $chord  = shift(@chords);
	my $phrase = shift(@phrases) // "";
	my $ex = "";
	#warn("wrap x=$x rm=$m w=", $m - $x, " ch=$chord, ph=$phrase\n");

	if ( @rchords && $chord ) {
	    # Does the chord fit?
	    my $c = $chord->chord_display;
	    my $w;
	    if ( $c =~ /^\*(.+)/ ) {
		$pr->setfont( $pr->{ps}->{fonts}->{annotation} );
		$c = $1;
	    }
	    else {
		$pr->setfont( $pr->{ps}->{fonts}->{chord} );
	    }
	    $w = $pr->strwidth($c);
	    if ( $w > $m - $x ) {
		# Nope. Move to overflow.
		$ex = $phrase;
	    }
	}

	if ( $ex eq "" ) {
	    # Do lyrics fit?
	    my $font = $pr->{ps}->{fonts}->{text};
	    $pr->setfont($font);
	    my $ph;
	    ( $ph, $ex ) = $pr->wrap( $phrase, $m - $x );
	    # If it doesn not fit, it is usually a case a bad luck.
	    # However, we may be able to move to overflow.
	    my $w = $pr->strwidth($ph);
	    if ( $w > $m - $x && @rchords > 1 ) {
		$ex = $phrase;
	    }
	    else {
		push( @rchords, $chord );
		push( @rphrases, $ph );
		$chord = '';
	    }
	    $x += $w;
	}

	if ( $ex ne "" ) {	# overflow
	    if ( $rphrases[-1] =~ /[[:alpha:]]$/
		 && $ex =~ /^[[:alpha:]]/
		 && $chord ne '' ) {
		$rphrases[-1] .= "-";
	    }
	    unshift( @chords, $chord );
	    unshift( @phrases, $ex );
	    push( @$res,
		  { %$elt, chords => [@rchords], phrases => [@rphrases] } );
	    $x = $_[2] + $wi;;
	    $res->[-1]->{indent} = $wi if @$res > 1;
	    @rchords = ();
	    @rphrases = ();
	}
    }
    push( @$res, { %$elt, chords => \@rchords, phrases => \@rphrases } );
    $res->[-1]->{indent} = $wi if @$res > 1;
    return $res;
}

sub wrapsimple {
    my ( $pr, $text, $x, $font ) = @_;
    return ( "", "" ) unless length($text);

    $font ||= $pr->{font};
    $pr->setfont($font);
    $pr->wrap( $text, $pr->{ps}->{__rightmargin} - $x );
}

sub prepare_assets {
    my ( $s, $pr ) = @_;

    my %sa = %{$s->{assets}//{}} ;	# song assets

    warn("PDF: Preparing ", plural(scalar(keys %sa), " image"), "\n")
      if $config->{debug}->{images} || $config->{debug}->{assets};

    for my $id ( sort keys %sa ) {
	prepare_asset( $id, $s, $pr );
    }

    warn("PDF: Preparing ", plural(scalar(keys %sa), " image"), ", done\n")
      if $config->{debug}->{images} || $config->{debug}->{assets};
    $assets = $s->{assets} || {};
    ::dump( $assets, as => "Assets, Pass 2" )
      if $config->{debug}->{assets} & 0x02;

}

sub prepare_asset {
    my ( $id, $s, $pr ) = @_;

    my $ps = $s->{_ps} = $pr->{ps};		# for handlers TODO

    # All elements generate zero or one display items, except for SVG images
    # than can result in a series of display items.
    # So we first scan the list for SVG and delegate items and turn these
    # into simple display items.

#    warn("_MR = ", $ps->{_marginright}, ", _RM = ", $ps->{_rightmargin},
#	 ", __RM = ", $ps->{__rightmargin}, "\n");
#    my $pw = $ps->{__rightmargin} - $ps->{_marginleft};
    my $pw = $ps->{_marginright} - $ps->{_marginleft};
    my $cw = ( $pw - ( $ps->{columns} - 1 ) * $ps->{columnspace} ) /$ps->{columns}
      - $ps->{_indent};

    for my $elt ( $s->{assets}->{$id} ) {
	# Already prepared, e.g. multi-pass songbook.
	next if UNIVERSAL::can($elt->{data}, "width");

	$elt->{subtype} //= "image" if $elt->{uri};

	if ( $elt->{type} eq "image" && $elt->{subtype} eq "delegate" ) {
	    my $delegate = $elt->{delegate};
	    warn("PDF: Preparing delegate $delegate, handler ",
		 $elt->{handler},
		 ( map { " $_=" . $elt->{opts}->{$_} } keys(%{$elt->{opts}//{}})),
		 "\n") if $config->{debug}->{images};

	    my $pkg = __PACKAGE__;
	    $pkg =~ s/::Output::[:\w]+$/::Delegate::$delegate/;
	    eval "require $pkg" || die($@);
	    my $hd = $pkg->can($elt->{handler}) //
	      die("PDF: Missing delegate handler ${pkg}::$elt->{handler}\n");
	    unless ( $elt->{data} ) {
		$elt->{data} = fs_load( $elt->{uri}, { fail => 'hard' } );
	    }

	    # Determine actual width.
	    my $w = defined($elt->{opts}->{spread}) ? $pw : $cw;
	    $w = $elt->{opts}->{width}
	      if $elt->{opts}->{width} && $elt->{opts}->{width} < $w;

	    my $res = $hd->( $s, elt => $elt, pagewidth => $w );
	    if ( $res ) {
		$res->{opts} = { %{ $res->{opts} // {} },
				 %{ $elt->{opts} // {} } };
		warn( "PDF: Preparing delegate $delegate, handler ",
		      $elt->{handler}, " => ",
		      $res->{type}, "/", $res->{subtype},
		      ( map { " $_=" . $res->{opts}->{$_} } keys(%{$res->{opts}//{}})),
		      " w=$w",
		      "\n" )
		  if $config->{debug}->{images};
		$s->{assets}->{$id} = $res;
	    }
	    else {
		# Substitute alert image.
		$s->{assets}->{$id} = $res =
		  { type => "image",
		    line => $elt->{line},
		    subtype => "xform",
		    data => TextLayoutImageElement::alert(60),
		    opts => { %{$elt->{opts}//{}} } };
	    }

	    # If the delegate produced an image, continue processing.
	    if ( $res && $res->{type} eq "image" ) {
		$elt = $res;
	    }
	    else {
		# Proceed to next asset.
		next;
	    }
	}

	if ( $elt->{type} eq "image" && $elt->{subtype} eq "svg" ) {
	    warn("PDF: Preparing SVG image\n") if $config->{debug}->{images};
	    require SVGPDF;
	    SVGPDF->VERSION(0.080);

	    # One or more?
	    my $combine = ( !($elt->{opts}->{split}//1)
			    || $elt->{opts}->{id}
			    || defined($elt->{opts}->{spread}) )
	      ? "stacked" : "none";
	    my $sep = $elt->{opts}->{staffsep} || 0;

	    # Note we need special font and text handlers.
	    my $p = SVGPDF->new
	      ( pdf  => $ps->{pr}->{pdf},
		fc   => sub { svg_fonthandler( $ps, @_ ) },
		tc   => sub { svg_texthandler( $ps, @_ ) },
		atts => { debug   => $config->{debug}->{svg} > 1,
			  verbose => $config->{debug}->{svg} // 0,
			} );
	    my $data = $elt->{data};
	    my $o = $p->process( $data ? \join( "\n", @$data ) : $elt->{uri},
				 combine => $combine,
				 sep     => $sep,
			       );
	    warn( "PDF: Preparing SVG image => ",
		  plural(0+@$o, " element"), ", combine=$combine\n")
	      if $config->{debug}->{images};
	    if ( ! @$o ) {
		warn("Error in SVG embedding (no SVG objects found)\n");
		next;
	    }

	    my $res =
	    $s->{assets}->{$id} = {
			type     => "image",
			subtype  => "xform",
			width    => $o->[0]->{width},
			height   => $o->[0]->{height},
			vwidth   => $o->[0]->{vwidth},
			vheight  => $o->[0]->{vheight},
			data     => $o->[0]->{xo},
			opts     => { %{ $o->[0]->{opts}  // {} },
				      %{ $s->{assets}->{$id}->{opts} // {} },
				    },
			sep      => $sep,
		      };
	    if ( @$o > 1 ) {
		$res->{multi} = $o;
	    }
	    warn("Created asset $id (xform, ",
		 $o->[0]->{vwidth}, "x", $o->[0]->{vheight}, ")",
		 " scale=", $res->{opts}->{scale} || 1,
		 " align=", $res->{opts}->{align}//"default",
		 " sep=", $sep,
		 " base=", $res->{opts}->{base}//"",
		 "\n")
	      if $config->{debug}->{images};
	    next;
	}

	if ( $elt->{type} eq "image" && $elt->{subtype} eq "xform" ) {
	    # Ready to go.
	    next;
	}

	if ( $elt->{type} eq "image" ) {
	    warn("PDF: Preparing $elt->{subtype} image\n") if $config->{debug}->{images};
	    if ( ($elt->{uri}//"") =~ /^chord:(.+)/ ) {
		my $chord = $1;
		# Look it up.
		my $info = $s->{chordsinfo}->{$chord}
		  // ChordPro::Chords::known_chord($chord);
		# If it is defined locally, merge.
		for my $def ( @{ $s->{define} // [] } ) {
		    next unless $def->{name} eq $chord;
		    $info->{$_} = $def->{$_} for keys(%$def);
		}
		my $xo;
		unless ( $info ) {
		    warn("Unknown chord in asset: $1\n");
		    $xo = TextLayoutImageElement::alert(20);
		}
		else {
		    my $type = $elt->{opts}->{type} || $config->{instrument}->{type};
		    my $p;
		    if ( $type eq "keyboard" ) {
			require ChordPro::Output::PDF::KeyboardDiagram;
			$p = ChordPro::Output::PDF::KeyboardDiagram->new( ps => $ps );
		    }
		    else {
			require ChordPro::Output::PDF::StringDiagram;
			$p = ChordPro::Output::PDF::StringDiagram->new( ps => $ps );
		    }
		    $xo = $p->diagram_xo($info);
		}
		my $res =
		  $s->{assets}->{$id} = {
					 type     => "image",
					 subtype  => "xform",
					 width    => $xo->width,
					 height   => $xo->height,
					 data     => $xo,
					 maybe opts => $s->{assets}->{$id}->{opts},
					};
		warn("Created asset $id ($elt->{subtype}, ",
		     $res->{width}, "x", $res->{height}, ")",
		     map { " $_=" . $res->{opts}->{$_} } keys( %{$res->{opts}//{}} ),
		     "\n")
		  if $config->{debug}->{images};
	    }
	    else {
		if ( $elt->{uri} && !$elt->{data} ) {
		    $elt->{data} = fs_blob( $elt->{uri}, { fail => 'hard' } );
		}
		my $data = $elt->{data} ? IO::String->new($elt->{data}) : $elt->{uri};
		my $img = $pr->{pdf}->image($data);
		my $subtype = lc(ref($img) =~ s/^.*://r);
		$subtype = "jpg" if $subtype eq "jpeg";
		my $res =
		  $s->{assets}->{$id} = {
					 type     => "image",
					 subtype  => $subtype,
					 width    => $img->width,
					 height   => $img->height,
					 data     => $img,
					 maybe opts => $s->{assets}->{$id}->{opts},
					};
		warn("Created asset $id ($elt->{subtype}, ",
		     $res->{width}, "x", $res->{height}, ")",
		     ( map { " $_=" . $res->{opts}->{$_} }
		           keys( %{$res->{opts}//{}} ) ),
		     "\n")
		  if $config->{debug}->{images};
	    }
	}

	next;

	if ( $elt->{type} eq "image" && $elt->{opts}->{spread} ) {
	    if ( $s->{spreadimage} ) {
		warn("Ignoring superfluous spread image\n");
	    }
	    else {
		$s->{spreadimage} = $elt;
		warn("PDF: Preparing images, got spread image\n")
		  if $config->{debug}->{images};
		next;		# do not copy back
	    }
	}

    }
}

# Font handler for SVG embedding.
sub svg_fonthandler {
    my ( $ps, $svg, %args ) = @_;
    my ( $pdf, $style ) = @args{qw(pdf style)};

    my $family = lc( $style->{'font-family'} );
    my $stl    = lc( $style->{'font-style'}  // "normal" );
    my $weight = lc( $style->{'font-weight'} // "normal" );
    my $size   = $style->{'font-size'}       || 12;

    # Font cache.
    state $fc  = {};
    my $key    = join( "|", $family, $stl, $weight );

    # Clear cache when the PDF changes.
    state $cf  = "";
    if ( $cf ne $ps->{pr}->{pdf} ) {
	$cf = $ps->{pr}->{pdf};
	$fc = {};
    }

    # As a special case we handle fonts with 'names' like
    # pdf.font.foo and map these to the corresponding font
    # in the pdf.fonts structure.
    if ( $family =~ /^pdf\.fonts\.(.*)/ ) {
	my $try = $ps->{fonts}->{$1};
	if ( $try ) {
	    warn("SVG: Font $family found in config: ",
		 $try->{_ff}, "\n")
	      if $config->{debug}->{svg};
	    # The font may change during the run, so we do not
	    # cache it.
	    return $try->{fd}->{font};
	}
    }

    local *Text::Layout::FontConfig::_fallback = sub { 0 };

    my $font = $fc->{$key} //= do {

	my $t;
	my $try =
	  eval {
	      $t = Text::Layout::FontConfig->find_font( $family, $stl, $weight );
	      $t->get_font($ps->{pr}->{layout}->copy);
	  };
	if ( $try ) {
	    warn("SVG: Font $key found in font config: ",
		 $t->{loader_data},
		 "\n")
	      if $config->{debug}->{svg};
	    $try;
	}
	else {
	    return;
	}
    };

    return $font;
}

# Text handler for SVG embedding.
sub svg_texthandler {
    my ( $ps, $svg, %args ) = @_;
    my $xo    = delete($args{xo});
    my $pdf   = delete($args{pdf});
    my $style = delete($args{style});
    my $text  = delete($args{text});
    my %opts  = %args;

    my @t = split( /([♯♭])/, $text );
    if ( @t == 1 ) {
	# Nothing special.
	$svg->set_font( $xo, $style );
	return $xo->text( $text, %opts );
    }

    my ( $font, $sz ) = $svg->root->fontmanager->find_font($style);
    my $has_sharp = $font->glyphByUni(ord("♯")) ne ".notdef";
    my $has_flat  = $font->glyphByUni(ord("♭")) ne ".notdef";
    # For convenience we assume that either both are available, or missing.

    if ( $has_sharp && $has_flat ) {
	# Nothing special.
	$xo->font( $font, $sz );
	return $xo->text( $text, %opts );
    }

    # Replace the sharp and flat glyphs by glyps from the chordfingers font.
    my $d = 0;
    my $this = 0;
    while ( @t ) {
	my $text = shift(@t);
	my $fs   = shift(@t);
	$xo->font( $font, $sz ) unless $this eq $font;
	$d += $xo->text($text);
	$this = $font;
	next unless $fs;
	$xo->font( $ps->{fonts}->{chordfingers}->{fd}->{font}, $sz );
	$this = 0;
	$d += $xo->text( $fs eq '♭' ? '!' : '#' );
    }
    return $d;
}

1;
