#!/usr/bin/perl

package Music::ChordPro::Output::ChordPro;

use strict;
use warnings;

sub generate_songbook {
    my ($self, $sb, $options) = @_;
    my @book;

    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    push(@book, "") if $options->{tidy};
	    push(@book, "{new_song}");
	}
	push(@book, @{generate_song($song, $options)});
    }

    push( @book, "");
    \@book;
}

my $lyrics_only = 0;

sub generate_song {
    my ($s, $options) = @_;

    my $tidy = $options->{tidy};
    $lyrics_only = $options->{'lyrics-only'};

    my @s;

    push(@s, "{title: " . $s->{title} . "}")
      if defined $s->{title};
    if ( defined $s->{subtitle} ) {
	push(@s, map { +"{subtitle: $_}" } @{$s->{subtitle}});
    }

    if ( $s->{settings} ) {
	foreach ( sort keys %{ $s->{settings} } ) {
	    push(@s, "{$_: " . $s->{settings}->{$_} . "}");
	}
    }

    push(@s, "") if $tidy;

    foreach my $elt ( @{$s->{body}} ) {

	if ( $elt->{type} eq "empty" ) {
	    push(@s, "");
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    push(@s, "{column_break}");
	    next;
	}

	if ( $elt->{type} eq "newpage" ) {
	    push(@s, "{new_page}");
	    next;
	}

	if ( $elt->{type} eq "song" ) {
	    push(@s, songline($elt));
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    push(@s, "") if $tidy;
	    push(@s, "{start_of_chorus}");
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "empty" ) {
		    push(@s, "");
		    next;
		}
		if ( $e->{type} eq "song" ) {
		    push(@s, songline($e));
		    next;
		}
	    }
	    push(@s, "{end_of_chorus}");
	    push(@s, "") if $tidy;
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

	if ( $elt->{type} eq "comment" || $elt->{type} eq "comment_italic" ) {
	    push(@s, "") if $tidy;
	    push(@s, "{" . $elt->{type} . ": " . $elt->{text} . "}");
	    push(@s, "") if $tidy;
	    next;
	}

    }


    \@s;
}

sub songline {
    my ($elt) = @_;

    if ( $lyrics_only ) {
	return join( "", @{ $elt->{phrases} } );
    }

    my $line = "";
    foreach ( 0..$#{$elt->{chords}} ) {
	$line .= "[" . $elt->{chords}->[$_] . "]" . $elt->{phrases}->[$_];
    }
    $line =~ s/^\[\]//;
    $line;
}

1;
