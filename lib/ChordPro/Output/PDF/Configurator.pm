#! perl

package main;

our $config;
our $options;

package ChordPro::Output::PDF;

our $pdfapi;

sub configurator {
    my ( $cfg ) = @_;

    # From here, we're mainly dealing with the PDF settings.
    my $pdf   = $cfg->{pdf};

    # Get PDF library.
    $pdfapi //= config_pdfapi( $pdf->{library} );

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
		if ( is_corefont($_) ) {
		    $fonts->{$type}->{name} = is_corefont($_);
		}
		elsif ( defined $pdf->{fontconfig}->{s/\s+\d+$//r} ) {
		    $fonts->{$type}->{description} = $_;
		}
		else {
		    die("Config error: \"$_\" is not a built-in font\n")
		}
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

    # Chord grid width.
    if ( $options->{'chord-grid-size'} ) {
	# Note that this is legacy, so for the chord diagrams only,
	$pdf->{diagrams}->{width} =
	  $pdf->{diagrams}->{height} =
	    $options->{'chord-grid-size'} /
	      @{ $config->{notes}->{sharps} };
    }

    # Map papersize name to [ width, height ].
    unless ( eval { $pdf->{papersize}->[0] } ) {
	eval "require ${pdfapi}::Resource::PaperSizes";
	my %ps = "${pdfapi}::Resource::PaperSizes"->get_paper_sizes;
	die("Unhandled paper size: ", $pdf->{papersize}, "\n")
	  unless exists $ps{lc $pdf->{papersize}};
	$pdf->{papersize} = $ps{lc $pdf->{papersize}}
    }

    # Merge properties for derived fonts.
    my $fm = sub {
	my ( $font, $def ) = @_;
	for ( keys %{ $fonts->{$def} } ) {
	    next if /^(?:background|frame)$/;
	    next if $font eq "chordfingers" && $_ eq "size";
	    $fonts->{$font}->{$_} //= $fonts->{$def}->{$_};
	}
    };
    $fm->( qw( subtitle       text     ) );
    $fm->( qw( chorus         text     ) );
    $fm->( qw( comment_italic text     ) );
    $fm->( qw( comment_box    text     ) );
    $fm->( qw( comment        text     ) );
    $fm->( qw( annotation     chord    ) );
    $fm->( qw( label          text     ) );
    $fm->( qw( toc            text     ) );
    $fm->( qw( empty          text     ) );
    $fm->( qw( grid           chord    ) );
    $fm->( qw( grid_margin    comment  ) );
    $fm->( qw( diagram        comment  ) );
    $fm->( qw( diagram_base   comment  ) );
    $fm->( qw( chordfingers   diagram  ) );

    # Default footer is small subtitle.
    $fonts->{footer}->{size} //= 0.6 * $fonts->{subtitle}->{size};
    $fm->( qw( footer         subtitle ) );

    # This one is fixed.
    $fonts->{chordprosymbols}->{file} = "ChordProSymbols.ttf";

}

sub config_pdfapi {
    my ( $lib, $verbose ) = @_;
    my $pdfapi;

    my $t = "config";
    # Get PDF library.
    if ( $ENV{CHORDPRO_PDF_API} ) {
	$t = "CHORDPRO_PDF_API";
	$lib = $ENV{CHORDPRO_PDF_API};
    }
    if ( $lib ) {
	unless ( eval( "require $lib" ) ) {
	    die("Missing PDF library $lib ($t)\n");
	}
	$pdfapi = $lib;
	warn("Using PDF library $lib ($t)\n") if $verbose;
    }
    else {
	for ( qw( PDF::API2 PDF::Builder ) ) {
	    eval "require $_" or next;
	    $pdfapi = $_;
	    warn("Using PDF library $_ (detected)\n") if $verbose;
	    last;
	}
    }
    die("Missing PDF library\n") unless $pdfapi;
    return $pdfapi;
}

1;
