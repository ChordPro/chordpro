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

use ChordPro::Utils;
use ChordPro::Output::SVG::Images;

sub prepare_assets( $s, $pr ) {

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
	    warn("Assets: Preparing delegate $delegate, handler ",
		 $elt->{handler},
		 ( map { " $_=" . $elt->{opts}->{$_} } keys(%{$elt->{opts}//{}})),
		 "\n") if $config->{debug}->{images};

	    my $pkg = 'ChordPro::Delegate::' . $delegate;
	    eval "require $pkg" || die($@);
	    my $hd = $pkg->can($elt->{handler}) //
	      die("Assets: Missing delegate handler ${pkg}::$elt->{handler}\n");
	    unless ( $elt->{data} ) {
		$elt->{data} = fs_load( $elt->{uri}, { fail => 'hard' } );
	    }

	    # Determine actual width.
	    my $w = defined($elt->{opts}->{spread}) ? $pw : $cw;
	    $w = $elt->{opts}->{width}
	      if $elt->{opts}->{width} && $elt->{opts}->{width} < $w;

	    my $res = $hd->( $s, elt => $elt, pagewidth => $w );
	    if ( 0&&$res ) {
		$res->{opts} = { %{ $res->{opts} // {} },
				 %{ $elt->{opts} // {} } };
		warn( "Assets: Preparing delegate $delegate, handler ",
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

1;
