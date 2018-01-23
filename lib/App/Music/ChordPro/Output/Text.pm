#!/usr/bin/perl

package App::Music::ChordPro::Output::Text;

use strict;
use warnings;

sub generate_songbook {
    my ($self, $sb, $options) = @_;
    my @book;

    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    push(@book, "") if $options->{'backend-option'}->{tidy};
	    push(@book, "-- New song");
	}
	push(@book, @{generate_song($song, $options)});
    }

    push( @book, "");
    \@book;
}

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chords lines

sub generate_song {
    my ($s, $options) = @_;

    my $tidy = $options->{'backend-option'}->{tidy};
    $single_space = $options->{'single-space'};
    $lyrics_only = $::config->{settings}->{'lyrics-only'};

    $s->structurize
      if ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';

    my @s;

    push(@s, "-- Title: " . $s->{title})
      if defined $s->{title};
    if ( defined $s->{subtitle} ) {
	push(@s, map { +"-- Subtitle: $_" } @{$s->{subtitle}});
    }

    push(@s, "") if $tidy;

    my $ctx = "";
    foreach my $elt ( @{$s->{body}} ) {

	if ( $elt->{context} ne $ctx ) {
	    push(@s, "-- End of $ctx") if $ctx;
	    push(@s, "-- Start of $ctx") if $ctx = $elt->{context};
	}

	if ( $elt->{type} eq "empty" ) {
	    push(@s, "***SHOULD NOT HAPPEN***")
	      if $s->{structure} eq 'structured';
	    push(@s, "");
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    push(@s, "-- Column break");
	    next;
	}

	if ( $elt->{type} eq "newpage" ) {
	    push(@s, "-- New page");
	    next;
	}

	if ( $elt->{type} eq "songline" ) {
	    push(@s, songline($elt));
	    next;
	}

	if ( $elt->{type} eq "tabline" ) {
	    push(@s, $elt->{text});
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    push(@s, "") if $tidy;
	    push(@s, "-- Start of chorus*");
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
	    push(@s, "-- End of chorus*");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    push(@s, "") if $tidy;
	    push(@s, "-- Start of tab");
	    push(@s, map { $_->{text} } @{$elt->{body}} );
	    push(@s, "-- End of tab");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    push(@s, "") if $tidy;
	    push(@s, "-- Start of verse");
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "empty" ) {
		    push(@s, "***SHOULD NOT HAPPEN***")
		      if $s->{structure} eq 'structured';
		    next;
		}
		if ( $e->{type} eq "songline" ) {
		    push(@s, songline($e));
		    next;
		}
		if ( $e->{type} eq "comment" ) {
		    push(@s, "-c- " . $e->{text});
		    next;
		}
		if ( $e->{type} eq "comment_italic" ) {
		    push(@s, "-i- " . $e->{text});
		    next;
		}
	    }
	    push(@s, "-- End of verse");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} =~ /^comment(?:_italic|_box)?$/ ) {
	    push(@s, "") if $tidy;
	    my $text = $elt->{text};
	    if ( $elt->{chords} ) {
		$text = "";
		for ( 0..$#{ $elt->{chords} } ) {
		    $text .= "[" . $elt->{chords}->[$_] . "]"
		      if $elt->{chords}->[$_] ne "";
		    $text .= $elt->{phrases}->[$_];
		}
	    }
	    # $text = fmt_subst( $s, $text );
	    push(@s, "-- $text");
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
	    push( @s, "+ @args" );
	    next;
	}

	if ( $elt->{type} eq "set" ) {
	    if ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	    next;
	}

	if ( $elt->{type} eq "control" ) {
	}
    }
    push(@s, "-- End of $ctx") if $ctx;

    \@s;
}

sub songline {
    my ($elt) = @_;

    my $t_line = "";

    if ( $lyrics_only
	 or
	 $single_space && ! ( $elt->{chords} && join( "", @{ $elt->{chords} } ) =~ /\S/ )
       ) {
	$t_line = join( "", @{ $elt->{phrases} } );
	$t_line =~ s/\s+$//;
	return $t_line;
    }

    unless ( $elt->{chords} ) {
	return ( "", join( " ", @{ $elt->{phrases} } ) );
    }

    my $c_line = "";
    foreach ( 0..$#{$elt->{chords}} ) {
	$c_line .= $elt->{chords}->[$_] . " ";
	$t_line .= $elt->{phrases}->[$_];
	my $d = length($c_line) - length($t_line);
	$t_line .= "-" x $d if $d > 0;
	$c_line .= " " x -$d if $d < 0;
    }
    s/\s+$// for ( $t_line, $c_line );
    return ( $c_line, $t_line );
}

# Substitute %X sequences in title formats and comments.
sub fmt_subst {
    use App::Music::ChordPro::Output::Common;
    goto \&App::Music::ChordPro::Output::Common::fmt_subst;
}

1;
