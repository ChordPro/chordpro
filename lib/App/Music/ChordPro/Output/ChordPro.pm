#!/usr/bin/perl

package main;

our $options;
our $config;

package App::Music::ChordPro::Output::ChordPro;

use strict;
use warnings;

use App::Music::ChordPro::Output::Common;
use App::Music::ChordPro::Utils qw( fq qquote );

my $re_meta;

sub generate_songbook {
    my ( $self, $sb ) = @_;

    # Skip empty songbooks.
    return [] unless eval { $sb->{songs}->[0]->{body} };

    # Build regex for the known metadata items.
    $re_meta = join( '|',
		     map { quotemeta }
		     "title", "subtitle",
		     "artist", "composer", "lyricist", "arranger",
		     "album", "copyright", "year",
		     "key", "time", "tempo", "capo", "duration" );
    $re_meta = qr/^($re_meta)$/;

    my @book;

    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    push(@book, "") if $options->{'backend-option'}->{tidy};
	    push(@book, "{new_song}");
	}
	push(@book, @{generate_song($song)});
    }

    push( @book, "");
    \@book;
}

my $lyrics_only = 0;
my $variant = 'cho';
my $rechorus;

sub upd_config {
    $rechorus = $::config->{chordpro}->{chorus}->{recall};
    $lyrics_only = 2 * $::config->{settings}->{'lyrics-only'};
}

sub generate_song {
    my ( $s ) = @_;

    my $tidy = $options->{'backend-option'}->{tidy};
    my $structured = ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';
    # $s->structurize if ++$structured;
    $variant = $options->{'backend-option'}->{variant} || 'cho';
    my $seq  = $options->{'backend-option'}->{seq};
    my $expand = $options->{'backend-option'}->{expand};
    my $msp  = $variant eq "msp";
    upd_config();

    my @s;
    my %imgs;

    if ( $s->{preamble} ) {
	@s = @{ $s->{preamble} };
    }

    push(@s, "{title: " . fq($s->{meta}->{title}->[0]) . "}")
      if defined $s->{meta}->{title};
    if ( defined $s->{subtitle} ) {
	push(@s, map { +"{subtitle: ".fq($_)."}" } @{$s->{subtitle}});
    }

    if ( $s->{meta} ) {
	if ( $msp ) {
	    $s->{meta}->{source} //= [ "Lead Sheet" ];
	    $s->{meta}->{custom2} //= [ $seq ] if defined $seq;
	}
	# Known ones 'as is'.
	my %used;
	foreach my $k ( sort keys %{ $s->{meta} } ) {
	    next if $k =~ /^(?:title|subtitle)$/;
	    if ( $k =~ $re_meta ) {
		push( @s, map { +"{$k: ".fq($_)."}" } @{ $s->{meta}->{$k} } );
		$used{$k}++;
	    }
	}
	# Unknowns with meta prefix.
	foreach my $k ( sort keys %{ $s->{meta} } ) {
	    next if $used{$k};
	    next if $k =~ /^(?:title|subtitle|songindex|key_.*|chords|numchords)$/;
	    next if $k =~ /^_/;
	    push( @s, map { +"{meta: $k ".fq($_)."}" } @{ $s->{meta}->{$k} } );
	}
    }

    if ( $s->{settings} ) {
	foreach ( sort keys %{ $s->{settings} } ) {
	    push(@s, "{$_: " . $s->{settings}->{$_} . "}");
	    $s[-1] = "{no_grid}"
	      if $s[-1] eq "{diagrams: 0}";
	}
    }

    push(@s, "") if $tidy;

    # Move a trailing list of chords to the beginning, so the chords
    # are defined when the song is parsed.
    if ( @{ $s->{body} } && $s->{body}->[-1]->{type} eq "diagrams"
    	 && $s->{body}->[-1]->{origin} ne "__CLI__"
       ) {
    	unshift( @{ $s->{body} }, pop( @{ $s->{body} } ) );
    }

    if ( $s->{define} ) {
	foreach my $info ( @{ $s->{define} } ) {
	    my $t = "{define: " . $info->{name};
	    if ( $info->{copyall} ) {
		$t .= " copyall " . $info->{copyall};
	    }
	    elsif ( $info->{copy} ) {
		$t .= " copy " . $info->{copy};
	    }
	    for ( qw( display format ) ) {
		next unless defined $info->{$_};
		$t .= " $_ " . qquote($info->{$_} );
	    }
	    $t .= " base-fret " . $info->{base};
	    $t .= " frets " .
	      join(" ", map { $_ < 0 ? "N" : $_ } @{$info->{frets}})
		if $info->{frets};
	    $t .= " fingers " .
	      join(" ", map { $_ < 0 ? "N" : $_ } @{$info->{fingers}})
		if $info->{fingers} && @{$info->{fingers}};
	    $t .= " keys " .
	      join(" ", @{$info->{keys}})
		if $info->{keys} && @{$info->{keys}};
	    push(@s, $t . "}");
	}
	push(@s, "") if $tidy;
    }

    my $ctx = "";
    my $dumphdr = 1;

    if ( $s->{chords} && $variant ne 'msp' ) {
	$dumphdr = 0 unless $s->{chords}->{origin} eq "__CLI__";
	push( @s,
	      @{ App::Music::ChordPro::Chords::list_chords
		  ( $s->{chords}->{chords},
		    $s->{chords}->{origin},
		    $dumphdr ) } );
	$dumphdr = 0;
    }

    my @elts = @{$s->{body}};
    while ( @elts ) {
	my $elt = shift(@elts);

	if ( $elt->{context} ne $ctx ) {
	    push(@s, "{end_of_$ctx}") if $ctx;
	    $ctx = $elt->{context};
	    if ( $ctx ) {

		my $t = "{start_of_$ctx";

		if ( $elt->{type} eq "set" ) {
		    if ( $elt->{name} eq "gridparams" ) {
			my @gridparams = @{ $elt->{value} };
			$t .= ": ";
			$t .= $gridparams[2] . "+" if $gridparams[2];
			$t .= $gridparams[0];
			$t .= "x" . $gridparams[1] if $gridparams[1];
			$t .= "+" . $gridparams[3] if $gridparams[3];
			if ( $gridparams[4] ) {
			    my $tag = $gridparams[4];
			    $t .= " " . $tag if $tag ne "";
			}
		    }
		    elsif ( $elt->{name} eq "label" ) {
			my $tag = $elt->{value};
			$t .= ": " . $tag if $tag ne "";
		    }

		}
		$t .= "}";
		push( @s, $t );
	    }
	}

	if ( $elt->{type} eq "empty" ) {
	    push(@s, "***SHOULD NOT HAPPEN***"), next
	      if $structured;
	    push( @s, "" );
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    next if $msp;
	    push(@s, "{column_break}");
	    next;
	}

	if ( $elt->{type} eq "newpage" ) {
	    next if $msp;
	    push(@s, "{new_page}");
	    next;
	}

	if ( $elt->{type} eq "songline" ) {
	    push(@s, songline( $s, $elt ));
	    next;
	}

	if ( $elt->{type} eq "tabline" ) {
	    push(@s, $elt->{text} );
	    next;
	}

	if ( $elt->{type} eq "gridline" ) {
	    push(@s, gridline( $s, $elt ));
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    push(@s, "") if $tidy;
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "empty" ) {
		    push(@s, "***SHOULD NOT HAPPEN***"), next
		      if $structured;
		}
		if ( $e->{type} eq "song" ) {
		    push(@s, songline( $s, $e ));
		    next;
		}
	    }
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    push(@s, "") if $tidy;
	    push(@s, "{start_of_chorus*}");
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "empty" ) {
		    push(@s, "");
		    next;
		}
		if ( $e->{type} eq "songline" ) {
		    push(@s, songline( $s, $e ));
		    next;
		}
	    }
	    push(@s, "{end_of_chorus*}");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    if ( $msp ) {
		push( @s, "{chorus}" );
	    }
	    elsif ( $rechorus->{quote} ) {
		unshift( @elts, @{ $elt->{chorus} } );
	    }
	    elsif ( $rechorus->{type} &&  $rechorus->{tag} ) {
		push( @s, "{".$rechorus->{type}.": ".$rechorus->{tag}."}" );
	    }
	    else {
		push( @s, "{chorus}" );
	    }
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    push(@s, "") if $tidy;
	    push(@s, "{start_of_tab}");
	    push(@s, @{$elt->{body}});
	    push(@s, "{end_of_tab}");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} =~ /^comment(?:_italic|_box)?$/ ) {
	    my $type = $elt->{type};
	    my $text = $expand ? $elt->{text} : $elt->{orig};
	    if ( $msp ) {
		$type = $type eq 'comment'
		  ? 'highlight'
		    : $type eq 'comment_italic'
		      ? 'comment'
		      : $type;
	    }
	    # Flatten chords/phrases.
	    if ( $elt->{chords} ) {
		$text = "";
		for ( 0..$#{ $elt->{chords} } ) {
		    $text .= "[" . $elt->{chords}->[$_] . "]"
		      if $elt->{chords}->[$_] ne "";
		    $text .= $elt->{phrases}->[$_];
		}
	    }
	    $text = fmt_subst( $s, $text ) if $msp;
	    push(@s, "") if $tidy;
	    push(@s, "{$type: ".fq($text)."}");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "image" ) {
	    my $uri = $elt->{uri};
	    if ( $msp && $uri !~ /^id=/ ) {
		$imgs{$uri} //= keys(%imgs);
		$uri = sprintf("id=img%02d", $imgs{$uri});
	    }
	    my @args = ( "image:", $uri );
	    while ( my($k,$v) = each( %{ $elt->{opts} } ) ) {
		push( @args, "$k=$v" );
	    }
	    foreach ( @args ) {
		next unless /\s/;
		$_ = '"' . $_ . '"';
	    }
	    push( @s, "{@args}" );
	    next;
	}

	if ( $elt->{type} eq "diagrams" ) {
	    $dumphdr = 0 unless $elt->{origin} eq "__CLI__";
	    push( @s,
		  @{ App::Music::ChordPro::Chords::list_chords
		      ( [ map {
			    $s->{chordsinfo}->{$_}->{origin} eq 'inline'
			      ? $s->{chordsinfo}->{$_}
			      : $s->{chordsinfo}->{$_}->{name}
		          } @{$elt->{chords}} ],
			$elt->{origin},
			$dumphdr ) } );
	    $dumphdr = 0;
	    next;
	}

	if ( $elt->{type} eq "set" ) {
	    if ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	    elsif ( $elt->{name} eq "transpose" ) {
	    }
	    # Arbitrary config values.
	    elsif ( $elt->{name} =~ /^(chordpro\..+)/ ) {
		my @k = split( /[.]/, $1 );
		my $cc = {};
		my $c = \$cc;
		foreach ( @k ) {
		    $c = \($$c->{$_});
		}
		$$c = $elt->{value};
		$config->augment($cc);
		upd_config();
	    }
	    next;
	}

	if ( $elt->{type} eq "ignore" ) {
	    push( @s, $elt->{text} );
	    next;
	}

    }

    push(@s, "{end_of_$ctx}") if $ctx;

    # Process image assets.
    foreach ( sort { $imgs{$a} <=> $imgs{$b} } keys %imgs ) {
	my $url = $_;
	my $id = $imgs{$url};
	my $type = "jpg";
	$type = lc($1) if $url =~ /\.(\w+)$/;
	require MIME::Base64;
	require Image::Info;

	# Slurp the image.
	my $fd;
	unless ( open( $fd, '<:raw', $url ) ) {
	    warn("$url: $!\n");
	    next;
	}
	my $data = do { local $/; <$fd> };
	close($fd);

	# Get info.
	my $info = Image::Info::image_info(\$data);
	if ( $info->{error} ) {
	    do_warn($info->{error});
	    next;
	}

	# Write in-line data.
	push( @s,
	      sprintf( "##image: id=img%02d" .
		       " src=%s type=%s width=%d height=%d enc=base64",
		       $id, $url, $info->{file_ext},
		       $info->{width}, $info->{height} ) );
	$data = MIME::Base64::encode($data, '');
	my $i = 0;
	# Note: 76 is the standard chunk size for base64 data.
	while ( $i < length($data) ) {
	    push( @s, "# ".substr($data, $i, 76) );
	    $i += 76;
	}
    }

    \@s;
}

sub songline {
    my ( $song, $elt ) = @_;

    if ( $lyrics_only || !exists($elt->{chords}) ) {
	return fq(join( "", @{ $elt->{phrases} } ));
    }

    my $line = "";
    foreach ( 0..$#{$elt->{chords}} ) {
	$line .= "[" . fq(chord( $song, $elt->{chords}->[$_])) . "]" . fq($elt->{phrases}->[$_]);
    }
    $line =~ s/^\[\]//;
    $line;
}

sub gridline {
    my ( $song, $elt ) = @_;

    my $line = "";
    for ( @{ $elt->{tokens} } ) {
	$line .= " " if $line;
	if ( $_->{class} eq "chord" ) {
	    $line .= $_->{chord};
	}
	else {
	    $line .= $_->{symbol};
	}
    }

    if ( $elt->{comment} ) {
	$line .= " " if $line;
	my $res = "";
	my $t = $elt->{comment};
	if ( $t->{chords} ) {
	    for ( 0..$#{ $t->{chords} } ) {
		$res .= "[" . fq(chord( $song, $t->{chords}->[$_])) . "]" . fq($t->{phrases}->[$_]);
	    }
	}
	else {
	    $res .= fq($t->{text});
	}
	$res =~ s/^\[\]//;
	$line .= $res;
    }

    $line;
}

sub chord {
    my ( $s, $c ) = @_;
    return "" unless length($c);
    #    $c =~ s/^\*// if $variant eq 'msp' && length($c) > 1;
#    Carp::confess("XX \"$c\" ", ::dump($s->{chordsinfo})) unless defined $s->{chordsinfo}->{$c};
    my $ci = $s->{chordsinfo}->{$c};
    return "<<$c>>" unless defined $ci;
    my $t = $ci->show;
    return "*$t" if $variant ne 'msp' && $ci->is_annotation;
    return $t;
}

1;
