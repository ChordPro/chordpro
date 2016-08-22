#!/usr/bin/perl

package App::Music::ChordPro::Output::LaTeX;

use strict;
use warnings;

sub generate_songbook {
    my ($self, $sb, $options) = @_;
    my @book;

    push(@book, "\\documentclass{article}");
    push(@book, "\\let\\chord=\\textit");
    push(@book, "\\begin{document}");
    push(@book, "");
    foreach my $song ( @{$sb->{songs}} ) {
	push(@book, @{generate_song($song, $options)});
	push(@book, "");
    }
    push(@book, "\\end{document}");
    \@book;
}

sub generate_song {
    my ($s, $options) = @_;

    my @s;

    push(@s, "\\begin{song}{".ltx($s->{title}||"") . "}");
    if ( defined $s->{subtitle} ) {
	push(@s, map { +"\\subtitle{".ltx($_)."}" } @{$s->{subtitle}});
    }

    push(@s, "");

    foreach my $elt ( @{$s->{body}} ) {

	if ( $elt->{type} eq "song" ) {
	    push(@s, songline($elt));
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    push(@s, "");
	    push(@s, "\\begin{chorus}");
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "song" ) {
		    push(@s, songline($e));
		    next;
		}
	    }
	    push(@s, "\\end{chorus}");
	    push(@s, "");
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    push(@s, "");
	    push(@s, "\\begin{verbatim}");
	    push(@s, @{$elt->{body}});
	    push(@s, "\\end{verbatim}");
	    push(@s, "");
	    next;
	}

	if ( $elt->{type} eq "comment" ) {
	    push(@s, "");
	    push(@s, "\\comment{" . ltx($elt->{text}) . "}");
	    push(@s, "");
	    next;
	}
    }
    push(@s, "\\end{song}");

    \@s;
}

sub songline {
    my ($elt) = @_;
    my @lines;
    push(@lines, "\\begin{tabbing}");

    my $line = "";
    foreach ( @{$elt->{phrases}} ) {
	$line .= ltx($_) . "\\=";
    }
    $line .= "\\kill";
    push(@lines, $line);

    $line = "";
    foreach ( @{$elt->{chords}} ) {
	$line .= "\\chord{" . ltx($_) . "}\\>";
    }
    $line .= "\\\\";
    push(@lines, $line);

    $line = "";
    foreach ( @{$elt->{phrases}} ) {
	$line .= ltx($_) . "\\>";
    }
    $line .= "\\\\";
    push(@lines, $line);

    push(@lines, "\\end{tabbing}");
    @lines;
}

sub ltx {
    my $txt = shift;
    $txt =~ s/ /~/g;
    $txt;
}

1;
