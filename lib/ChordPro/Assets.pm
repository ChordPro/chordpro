#! perl

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';

package main;

use utf8;
our $config;
our $options;

package ChordPro::Assets;

use Exporter 'import';
our @EXPORT;

use ChordPro::Files;
use ChordPro::Utils;
use ChordPro::Output::SVG::Images;
use IO::String;

sub prepare_assets( $s, $pr = undef ) {

    my %sa = %{$s->{assets}//{}} ;	# song assets

    warn("Assets: Preparing ", plural(scalar(keys %sa), " image"), "\n")
      if $config->{debug}->{images} || $config->{debug}->{assets};

    for my $id ( sort keys %sa ) {
	prepare_asset( $id, $s, $pr );
    }

    warn("Assets: Preparing ", plural(scalar(keys %sa), " image"), ", done\n")
      if $config->{debug}->{images} || $config->{debug}->{assets};
    my $assets = $s->{assets} || {};
    ::dump( $assets, as => "Assets, Pass 2" )
      if $config->{debug}->{assets} & 0x02;
    return $assets;

}

push( @EXPORT, 'prepare_assets' );

sub prepare_asset( $id, $s, $pr ) {

    my $ps;
    $ps = $s->{_ps} = $pr->{ps} if $pr;

    # All elements generate zero or one display items, except for SVG images
    # than can result in a series of display items.
    # So we first scan the list for SVG and delegate items and turn these
    # into simple display items.

#    warn("_MR = ", $ps->{_marginright}, ", _RM = ", $ps->{_rightmargin},
#	 ", __RM = ", $ps->{__rightmargin}, "\n");
#    my $pw = $ps->{__rightmargin} - $ps->{_marginleft};
    my $pw = $ps ? $ps->{_marginright} - $ps->{_marginleft} : 700;
    my $cw = $ps ? ( $pw - ( $ps->{columns} - 1 ) * $ps->{columnspace} ) /$ps->{columns}
      - $ps->{_indent} : 700;

    for my $elt ( $s->{assets}->{$id} ) {
	# Already prepared, e.g. multi-pass songbook.
	next if UNIVERSAL::can($elt->{data}, "width");

	$elt->{subtype} //= "image" if $elt->{uri};

	if ( $elt->{type} eq "image" && $elt->{subtype} eq "delegate" ) {
	    my $delegate = $elt->{delegate};
	    my $handler = $elt->{handler};
	    # Backend name is used to apply backend-specific delegate overrides.
	    my $backend = lc( $s->{generate} // "" );
	    warn("Assets: Preparing delegate $delegate, handler ",
		 $handler,
		 ( map { " $_=" . $elt->{opts}->{$_} } keys(%{$elt->{opts}//{}})),
		 "\n") if $config->{debug}->{images};

	    # Delegate config can be keyed either lowercase or as given; support both.
	    my $dcfg_src = $config->{delegates}->{lc($delegate)}
	      // $config->{delegates}->{$delegate};
	    # Clone config hashes before use to avoid mutating restricted/shared data.
	    my $dcfg = ref($dcfg_src) eq 'HASH' ? { %$dcfg_src } : undef;
	    # Optional per-backend config section (e.g. pdf/html/markdown).
	    my $bcfg = ( $backend && $dcfg && ref($dcfg->{$backend}) eq 'HASH' )
	      ? { %{ $dcfg->{$backend} } } : undef;
	    # Per-backend handler override takes precedence over the element default.
	    if ( $bcfg && $bcfg->{handler} ) {
		$handler = $bcfg->{handler};
	    }

	    my $pkg = 'ChordPro::Delegate::' . $delegate;
	    eval "require $pkg" || die($@);
	    my $hd = $pkg->can($handler) //
	      die("Assets: Missing delegate handler ${pkg}::$handler\n");
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
		warn( "Assets: Preparing delegate $delegate, handler ",
		      $handler, " => ",
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
		    subtype => "svg",
		    data => [ SVG->alert(60) ],
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

	next unless $ps;

	if ( $elt->{type} eq "image" && $elt->{subtype} eq "svg" ) {
	    warn("Assets: Preparing SVG image\n") if $config->{debug}->{images};
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
	    warn( "Assets: Preparing SVG image => ",
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
	    warn("Assets: Preparing $elt->{subtype} image\n") if $config->{debug}->{images};
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
		    my $p = ChordPro::Output::PDF::diagrammer($type);
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
		warn("Assets: Preparing images, got spread image\n")
		  if $config->{debug}->{images};
		next;		# do not copy back
	    }
	}

    }
}

push( @EXPORT, 'prepare_asset' );

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
	$xo->font( $ps->{fonts}->{chordprosymbols}->{fd}->{font}, $sz );
	$this = 0;
	$d += $xo->text( $fs eq '♭' ? '!' : '#' );
    }
    return $d;
}

1;
