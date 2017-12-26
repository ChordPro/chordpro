#!/usr/bin/perl

package App::Music::ChordPro::Output::ChordPro;

use strict;
use warnings;

use App::Music::ChordPro::Output::Common;

my $re_meta;

sub generate_songbook {
    my ($self, $sb, $options) = @_;

    # Skip empty songbooks.
    return [] unless eval { $sb->{songs}->[0]->{body} };

    # Build regex for the known metadata items.
    if ( $::config->{metadata}->{keys} ) {
	$re_meta = '^(' .
	  join( '|', map { quotemeta } @{$::config->{metadata}->{keys}} )
	    . ')$';
	$re_meta = qr/$re_meta/;
    }
    else {
	undef $re_meta;
    }

    my @book;

    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    push(@book, "") if $options->{'backend-option'}->{tidy};
	    push(@book, "{new_song}");
	}
	push(@book, @{generate_song($song, $options)});
    }

    push( @book, "");
    \@book;
}

my $lyrics_only = 0;
my @gridparams;

sub generate_song {
    my ($s, $options) = @_;

    my $tidy = $options->{'backend-option'}->{tidy};
    $lyrics_only = 2 * $::config->{settings}->{'lyrics-only'};
    my $structured = ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';
    # $s->structurize if ++$structured;
    my $variant = $options->{'backend-option'}->{variant} || 'cho';

    my @s;

    if ( $s->{preamble} ) {
	@s = @{ $s->{preamble} };
    }
 
    push(@s, "{title: " . $s->{meta}->{title}->[0] . "}")
      if defined $s->{meta}->{title};
    if ( defined $s->{subtitle} ) {
	push(@s, map { +"{subtitle: $_}" } @{$s->{subtitle}});
    }

    if ( $s->{meta} ) {
	foreach my $k ( sort keys %{ $s->{meta} } ) {
	    next if $k =~ /^(?:title|subtitle)$/;
	    if ( $variant eq 'msp' || $k =~ $re_meta ) {
		push( @s, map { +"{$k: $_}" } @{ $s->{meta}->{$k} } );
	    }
	    else {
		push( @s, map { +"{meta: $k $_}" } @{ $s->{meta}->{$k} } );
	    }
	}
    }

    if ( $s->{settings} ) {
	foreach ( sort keys %{ $s->{settings} } ) {
	    push(@s, "{$_: " . $s->{settings}->{$_} . "}");
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
	    $t .= " base-fret " . $info->{base};
	    $t .= " frets " .
	      join(" ", map { $_ < 0 ? "N" : $_ } @{$info->{frets}})
		if $info->{frets};
	    $t .= " fingers " .
	      join(" ", map { $_ < 0 ? "N" : $_ } @{$info->{fingers}})
		if $info->{fingers};
	    push(@s, $t);
	}
	push(@s, "") if $tidy;
    }

    my $ctx = "";
    my $dumphdr = 1;

    if ( $s->{chords} ) {
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
		if ( $elt->{type} eq "set" &&
		     $elt->{name} eq "gridparams" ) {
		    @gridparams = @{ $elt->{value} };
		}
		if ( @gridparams ) {
		    my $t = "{start_of_$ctx ";
		    $t .= $gridparams[2] . "+" if $gridparams[2];
		    $t .= $gridparams[0];
		    $t .= "x" . $gridparams[1] if $gridparams[1];
		    $t .= "+" . $gridparams[3] if $gridparams[3];
		    push( @s, $t );
		}
		else {
		    push(@s, "{start_of_$ctx}");
		}
	    }
	}

	if ( $elt->{type} eq "empty" ) {
	    push(@s, "***SHOULD NOT HAPPEN***"), next
	      if $structured;
	    push( @s, "" );
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    next if $variant eq 'msp';
	    push(@s, "{column_break}");
	    next;
	}

	if ( $elt->{type} eq "newpage" ) {
	    next if $variant eq 'msp';
	    push(@s, "{new_page}");
	    next;
	}

	if ( $elt->{type} eq "songline" ) {
	    push(@s, songline($elt));
	    next;
	}

	if ( $elt->{type} eq "tabline" ) {
	    push(@s, $elt->{text} );
	    next;
	}

	if ( $elt->{type} eq "gridline" ) {
	    push(@s, gridline($elt));
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
		    push(@s, songline($e));
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
		    push(@s, songline($e));
		    next;
		}
	    }
	    push(@s, "{end_of_chorus*}");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    if ( $variant eq 'msp' ) {
		push( @s, "{chorus}" );
	    }
	    else {
		unshift( @elts, @{ $elt->{chorus} } );
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
	    my $text = $elt->{orig};
	    if ( $variant eq 'msp' ) {
		$type = $type eq 'comment'
		  ? 'highlight'
		    : $type eq 'comment_italic'
		      ? 'comment'
			: $type;
		# Flatten chords/phrases.
		if ( $elt->{chords} ) {
		    $elt->{text} = "";
		    for ( 0..$#{ $elt->{chords} } ) {
			$elt->{text} .= "[" . $elt->{chords}->[$_] . "]"
			  if $elt->{chords}->[$_] ne "";
			$elt->{text} .= $elt->{phrases}->[$_];
		    }
		}
		$text = fmt_subst( $s, $elt->{text} );
	    }
	    push(@s, "") if $tidy;
	    push(@s, "{$type: $text}");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "image" ) {
	    my @args = ( "image:", $elt->{uri} );
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
		      ( $elt->{chords}, $elt->{origin},
			$dumphdr ) } );
	    $dumphdr = 0;
	    next;
	}

	if ( $elt->{type} eq "set" ) {
	    if ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	    elsif ( $elt->{name} eq "gridparams" ) {
		@gridparams = @{ $elt->{value} };
	    }
	    elsif ( $elt->{name} eq "transpose" ) {
	    }
	    next;
	}

	if ( $elt->{type} eq "ignore" ) {
	    push( @s, $elt->{text} );
	    next;
	}
    }
    push(@s, "{end_of_$ctx}") if $ctx;

    \@s;
}

sub songline {
    my ($elt) = @_;

    if ( $lyrics_only || !exists($elt->{chords}) ) {
	return join( "", @{ $elt->{phrases} } );
    }

    my $line = "";
    foreach ( 0..$#{$elt->{chords}} ) {
	$line .= "[" . $elt->{chords}->[$_] . "]" . $elt->{phrases}->[$_];
    }
    $line =~ s/^\[\]//;
    $line;
}

sub gridline {
    my ($elt) = @_;

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
		$res .= "[" . $t->{chords}->[$_] . "]" . $t->{phrases}->[$_];
	    }
	}
	else {
	    $res .= $t->{text};
	}
	$res =~ s/^\[\]//;
	$line .= $res;
    }

    $line;
}

# Substitute %X sequences in title formats.
sub fmt_subst {
    goto \&App::Music::ChordPro::Output::Common::fmt_subst;
}

1;
