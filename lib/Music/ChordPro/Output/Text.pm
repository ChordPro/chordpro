#!/usr/bin/perl

package Music::ChordPro::Output::Text;

use strict;
use warnings;

my $single_space = 0;		# suppress chords line when empty
				# if > 1, suppress chords line when nonempty

sub generate_songbook {
    my ($self, $sb, $options) = @_;
    my @book;

    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    push(@book, "") if $options->{tidy};
	    push(@book, "-- New song");
	}
	push(@book, @{generate_song($song, $options)});
    }

    push( @book, "");
    \@book;
}

*Music::ChordPro::Songbook::generate_text = \&generate_songbook;

sub generate_song {
    my ($s, $options) = @_;

    my $tidy = $options->{tidy};
    $single_space = $options->{'single-space'};

    my @s;

    push(@s, "-- Title: " . $s->{title})
      if defined $s->{title};
    if ( defined $s->{subtitle} ) {
	push(@s, map { +"-- Subtitle: $_" } @{$s->{subtitle}});
    }

    push(@s, "") if $tidy;

    foreach my $elt ( @{$s->{body}} ) {

	if ( $elt->{type} eq "empty" ) {
	    push(@s, "");
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    # push(@s, "{column_break}");
	    next;
	}

	if ( $elt->{type} eq "newpage" ) {
	    # push(@s, "{new_page}");
	    next;
	}

	if ( $elt->{type} eq "song" ) {
	    push(@s, songline($elt));
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    push(@s, "") if $tidy;
	    push(@s, "-- Start of chorus");
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
	    push(@s, "-- End of chorus");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    push(@s, "") if $tidy;
	    push(@s, "-- Start of tab");
	    push(@s, @{$elt->{body}});
	    push(@s, "-- End of tab");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "comment" || $elt->{type} eq "comment_italic" ) {
	    push(@s, "") if $tidy;
	    push(@s, "-- $elt->{text}");
	    push(@s, "") if $tidy;
	    next;
	}

    }


    \@s;
}

sub songline {
    my ($elt) = @_;
    my $t_line = "";
    unless ( $single_space ) {
	foreach ( 0..$#{$elt->{chords}} ) {
	    $t_line .= $elt->{phrases}->[$_];
	}
	s/\s+$// for ( $t_line );
	return $t_line;
    }

    my $c_line = "";
    foreach ( 0..$#{$elt->{chords}} ) {
	$c_line .= $elt->{chords}->[$_] . " ";
	$t_line .= $elt->{phrases}->[$_];
	my $d = length($c_line) - length($t_line);
	$t_line .= "-" x $d if $d > 0 && $single_space == 1;
	$c_line .= " " x -$d if $d < 0;
    }
    s/\s+$// for ( $t_line, $c_line );
    return $t_line if $single_space > 1 || $c_line !~ /\S/;
    return $c_line . "\n" . $t_line;
}

1;
