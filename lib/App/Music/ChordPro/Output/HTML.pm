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
my $layout;

sub generate_song {
    my ( $s ) = @_;

    my $tidy      = $::options->{tidy};
    $single_space = $::options->{'single-space'};
    $lyrics_only  = $::config->{settings}->{'lyrics-only'};
    $s->structurize;
    $layout = Text::Layout::Text->new;

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
	      '<div class="title">' . nhtml($_) . '</div>',
	    );

    }
    if ( defined $s->{subtitle} ) {
	push( @s,
	      map { '<div class="subtitle">' . nhtml($_) . '</div>' }
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
	    push(@s, songline( $s, $elt ));
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    my $p = '<div class="tab">';
	    foreach ( @{ $elt->{body} } ) {
		next if $_->{type} eq "set";
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
		    push( @s, songline( $s, $e ) );
		    next;
		}
		if ( $e->{type} =~ /^comment(_\w+)?$/ ) {
		    push( @s,
			  '<div class="' . $e->{type} . '">' .
			  nhtml($e->{text}) . '</div>' );
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
		  nhtml($elt->{text}) . '</div>' );
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
    my ( $song, $elt ) = @_;

    my $t_line = "";

    $elt->{chords} //= [ '' ];
    my @c = map {
	$_ eq "" ? "" : $song->{chordsinfo}->{$_}->show
    } @{ $elt->{chords} };

    if ( $lyrics_only
	 or
	 $single_space && ! ( $elt->{chords} && join( "", @c ) =~ /\S/ )
       ) {
	$t_line = join( "", @{ $elt->{phrases} } );
	$t_line =~ s/\s+$//;
	return ( '<table class="songline">',
		 '  <tr class="lyrics">',
		 '    <td>' . nhtml($t_line) . '</td>',
		 '  </tr>',
		 '</table>' );
    }

    if ( $::config->{settings}->{'chords-under'} ) {
	return ( '<table class="songline">',
		 '  <tr class="lyrics">',
		 '    ' . join( '',
				map { ( $_ =~ s/^\s+// ? '<td class="indent">' : '<td>' ) . nhtml($_) . '</td>' }
				( @{ $elt->{phrases} } ) ),
		 '  </tr>',
		 '  <tr class="chords">',
		 '    ' . join( '',
				map { '<td>' . nhtml($_) . ' </td>' }
				( @c ) ),
		 '  </tr>',
		 '</table>' );
    }
    return ( '<table class="songline">',
	     '  <tr class="chords">',
	     '    ' . join( '',
			    map { '<td>' . nhtml($_) . ' </td>' }
			    ( @c ) ),
	     '  </tr>',
	     '  <tr class="lyrics">',
	     '    ' . join( '',
			    map { ( $_ =~ s/^\s+// ? '<td class="indent">' : '<td>' ) . nhtml($_) . '</td>' }
			    ( @{ $elt->{phrases} } ) ),
	     '  </tr>',
	     '</table>' );
}

sub nhtml {
    return unless defined $_[0];
    $layout->set_markup(shift);
    html($layout->render);
}

sub html {
    my $t = shift;
    $t =~ s/&/&amp;/g;
    $t =~ s/</&lt;/g;
    $t =~ s/>/&gt;/g;
    $t;
}

# Temporary. Eventually we'll have a decent HTML backend for Text::Layout.

package Text::Layout::Text;

use parent 'Text::Layout';

# Eliminate warning when HTML backend is loaded together with Text backend.
no warnings 'redefine';

sub new {
    my ( $pkg, @data ) = @_;
    my $self = $pkg->SUPER::new;
    $self;
}

sub render {
    my ( $self ) = @_;
    my $res = "";
    foreach my $fragment ( @{ $self->{_content} } ) {
	next unless length($fragment->{text});
	$res .= $fragment->{text};
    }
    $res;
}

1;
