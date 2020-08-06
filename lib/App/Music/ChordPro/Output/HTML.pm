#!/usr/bin/perl

package App::Music::ChordPro::Output::HTML;

# Produce nice viewable HMTL output.
#
# You should be able to print it using a decent browser (notexisting)
# or a formatting tool like weasyprint.

use strict;
use warnings;
use App::Music::ChordPro::Output::Common;

sub generate_songbook {
    my ( $self, $sb ) = @_;

    my @book;
    my $cfg = $::config->{html} // {};
    $cfg->{styles}->{display} //= "chordpro.css";
    $cfg->{styles}->{print} //= "chordpro_print.css";

    push( @book,
	  '<html>',
	  '<head>',
	  '<meta charset="utf-8">' );
    foreach ( sort keys %{ $cfg->{styles} } ) {
	push( @book,
	      '<link rel="stylesheet" href="'.$cfg->{styles}->{$_}.'"'.
	      ( $_ =~ /^(display|default)$/ ? "" : qq{ media="$_"} ).
	      '>' );
    }
    push( @book, '</head>',
	  '<body>',
	);

    foreach my $song ( @{$sb->{songs}} ) {
	push( @book, @{ generate_song($song) } );
    }

    push( @book, "</body>", "</html>" );
    \@book;
}

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chords lines

sub generate_song {
    my ( $s ) = @_;

    my $tidy      = $::options->{tidy};
    $single_space = $::options->{'single-space'};
    $lyrics_only  = $::config->{settings}->{'lyrics-only'};
    $s->structurize;

    my @s;

    for ( $s->{title} // "Untitled" ) {
	push( @s,
	      '<div class="song">',
	      '<style>',
	      '@page {',
	      '  @top-center {',
	      '      content: counter(song) ". ' . $_ . '";',
	      '  }',
	      '}',
	      '</style>',
	      '<div class="title">' . html($_) . '</div>',
	    );

    }
    if ( defined $s->{subtitle} ) {
	push( @s,
	      map { '<div class="subtitle">' . html($_) . '</div>' }
	      @{$s->{subtitle}} );
    }

    push(@s, "") if $tidy;

    foreach my $elt ( @{$s->{body}} ) {

	if ( $elt->{type} eq "empty" ) {
	    push(@s, "***SHOULD NOT HAPPEN***");
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

	if ( $elt->{type} eq "songline" ) {
	    push(@s, songline($elt));
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    my $p = '<div class="tab">';
	    foreach ( @{ $elt->{body} } ) {
		push( @s, $p . html($_->{text}) );
		$p = "";
	    }
	    push( @s, $p . '</div>' );
	    push( @s, "") if $tidy;
	    next;
	}

	if ( exists $elt->{body} ) {
	    push( @s, '<div class="' . $elt->{type} . '">' );
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "empty" ) {
		    push( @s, "<!-- ***SHOULD NOT HAPPEN*** -->" );
		    next;
		}
		if ( $e->{type} eq "songline" ) {
		    push( @s, songline($e) );
		    next;
		}
		if ( $e->{type} =~ /^comment(_\w+)?$/ ) {
		    push( @s,
			  '<div class="' . $e->{type} . '">' .
			  html($e->{text}) . '</div>' );
		    next;
		}
	    }
	    push( @s, '</div>' );
	    push( @s, "" ) if $tidy;
	    next;
	}

	if ( $elt->{type} eq "comment" || $elt->{type} eq "comment_italic" ) {
	    push( @s,
		  '<div class="' . $elt->{type} . '">' .
		  html($elt->{text}) . '</div>' );
	    push( @s, "" ) if $tidy;
	    next;
	}

	if ( $elt->{type} eq "image" ) {
	    my @args;
	    while ( my($k,$v) = each( %{ $elt->{opts} } ) ) {
		push( @args, "$k=\"$v\"" );
	    }
	    # First shot code. Fortunately (not surprisingly :))
	    # HTML understands most arguments.
	    push( @s,
		  '<div class="' . $elt->{type} . '">' .
		  '<img src="' . $elt->{uri} . '" ' .
		  "@args" . "/>" .
		  '</div>' );
	    push( @s, "" ) if $tidy;

	}

	if ( $elt->{type} eq "control" ) {
	    if ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	}
    }

    push( @s, '</div>' );	# song
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
	return ( '<table class="songline">',
		 '  <tr class="lyrics">',
		 '    <td>' . html($t_line) . '</td>',
		 '  </tr>',
		 '</table>' );
    }

    $elt->{chords} //= [ '' ];

    if ( $::config->{settings}->{'chords-under'} ) {
	return ( '<table class="songline">',
		 '  <tr class="lyrics">',
		 '    ' . join( '',
				map { ( $_ =~ s/^\s+// ? '<td class="indent">' : '<td>' ) . html($_) . '</td>' }
				( @{ $elt->{phrases} } ) ),
		 '  </tr>',
		 '  <tr class="chords">',
		 '    ' . join( '',
				map { '<td>' . html($_) . ' </td>' }
				( @{ $elt->{chords} } ) ),
		 '  </tr>',
		 '</table>' );
    }
    return ( '<table class="songline">',
	     '  <tr class="chords">',
	     '    ' . join( '',
			    map { '<td>' . html($_) . ' </td>' }
			    ( @{ $elt->{chords} } ) ),
	     '  </tr>',
	     '  <tr class="lyrics">',
	     '    ' . join( '',
			    map { ( $_ =~ s/^\s+// ? '<td class="indent">' : '<td>' ) . html($_) . '</td>' }
			    ( @{ $elt->{phrases} } ) ),
	     '  </tr>',
	     '</table>' );
}

sub html {
    my $t = shift;
    $t =~ s/&/&amp;/g;
    $t =~ s/</&lt;/g;
    $t =~ s/>/&gt;/g;
    $t;
}

# Substitute %X sequences in title formats.
sub fmt_subst {
    goto \&App::Music::ChordPro::Output::Common::fmt_subst;
}

1;
