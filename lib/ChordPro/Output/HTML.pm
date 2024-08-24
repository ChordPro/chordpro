#!/usr/bin/perl

package ChordPro::Output::HTML;

# Produce nice viewable HMTL output.
#
# You should be able to print it using a decent browser (notexisting)
# or a formatting tool like weasyprint.

use strict;
use warnings;
use ChordPro::Output::Common;
use ChordPro::Utils qw();

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

    my @elts = @{$s->{body}};
    while ( @elts ) {
	my $elt = shift(@elts);

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
	    my @elts = @{$elt->{body}};
	    while ( @elts ) {
		my $e = shift(@elts);
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
			  '<span>' . nhtml($e->{text}) . '</span></div>' );
		    next;
		}
		if ( $e->{type} eq "set" && $e->{name} eq "label" ) {
		    push( @s,
			  '<div class="label">' . nhtml($e->{value}) . '</div>'
			);
		    next;
		}
		if ( $e->{type} eq "delegate"
		     && $e->{subtype} =~ /^image(?:-(\w+))?$/ ) {
		    my $delegate = $1 // $e->{delegate};
		    my $pkg = __PACKAGE__;
		    $pkg =~ s/::Output::\w+$/::Delegate::$delegate/;
		    eval "require $pkg" || die($@);
		    my $hd = $pkg->can($e->{handler}) //
		      die("HTML: Missing delegate handler ${pkg}::$e->{handler}\n");
		    my $res = $hd->( $s, 0, $e );
		    next unless $res; # assume errors have been given
		    unshift( @elts, @$res );
		    next;
		}
		if ( $e->{type} eq "svg" ) {
		    push( @s, '<div class="' . $e->{type} . '">' );
		    push( @s, File::LoadLines::loadlines( $e->{uri} ) );
		    push( @s, "</div>" );
		    push( @s, "" ) if $tidy;
		    next;
		}


	    }
	    push( @s, '</div>' );
	    push( @s, "" ) if $tidy;
	    next;
	}

	if ( $elt->{type} eq "comment" || $elt->{type} eq "comment_italic" ) {
	    if ( $elt->{chords} ) {
		my $t = "";
		for ( my $i=0; $i < @{$elt->{chords}}; $i++ ) {
		    $t .= $s->{chordsinfo}->{$elt->{chords}->[$i]->key}->name
		      if $elt->{chords}->[$i];
		    $t .= $elt->{phrases}->[$i];
		}
		push( @s, '<div class="' . $elt->{type} . '"><span>' .
		      nhtml($t) . '</span></div>' );

	    }
	    else {
		push( @s,
		      '<div class="' . $elt->{type} . '">' .
		      '<span>' . nhtml($elt->{orig}) . '</span></div>' );
	    }
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
	    next;
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
	$_ eq "" ? "" : $song->{chordsinfo}->{$_->key }->name
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

=for later

sub gridline {
}

<style>
div.grid_2_4x4_1 {
    display: grid;
    grid-template-columns: 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263% 5.263%;
}
div.grid_2_4x4_1 div   { padding: 4px }
div.grid_2_4x4_1 div.A { grid-column: span 2 }
div.grid_2_4x4_1 div.L { border-left: 1px solid black   }
div.grid_2_4x4_1 div.M { border-left: 1px solid #e0e0e0 }
div.grid_2_4x4_1 div.R { border-right: 1px solid black  }
div.grid_2_4x4_1 div.Z { grid-column: span 1 }
</style>

<div class="grid_2_4x4_1">

  <div class="A">intro</div>
  <div class="L">a1</div>
  <div class="M">a2</div>
  <div class="M">a3</div>
  <div class="M">a4</div>
  <div class="L">b1</div>
  <div class="M">b2</div>
  <div class="M">b3</div>
  <div class="M">b4</div>
  <div class="L">c1</div>
  <div class="M">c2</div>
  <div class="M">c3</div>
  <div class="M">c4</div>
  <div class="L">d1</div>
  <div class="M">d2</div>
  <div class="M">d3</div>
  <div class="M R">d4 d4</div>
  <div class="Z"></div>

  <div class="A"></div>
  <div class="L">a1</div>
  <div class="M">a2</div>
  <div class="M">a3</div>
  <div class="M">a4</div>
  <div class="L">b1</div>
  <div class="M">b2</div>
  <div class="M">b3</div>
  <div class="M">b4</div>
  <div class="L">c1</div>
  <div class="M">c2</div>
  <div class="M">c3</div>
  <div class="M">c4</div>
  <div class="L">d1</div>
  <div class="M">d2</div>
  <div class="M">d3</div>
  <div class="M R">d4</div>
  <div class="Z">2x</div>

</div>

=cut

sub nhtml {
    return unless defined $_[0];
    $layout->set_markup(shift);
    $layout->render;
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
    $self->{_currentfont} = { family => 'default',
			      style => 'normal',
			      weight => 'normal' };
    $self->{_currentcolor} = 'black';
    $self->{_currentsize} = 12;
    $self;
}

sub render {
    my ( $self ) = @_;
    my $res = "";
    foreach my $fragment ( @{ $self->{_content} } ) {
	next unless length($fragment->{text});
	my $f = $fragment->{font} || $self->{_currentfont};
	my @c;			# styles
	my @d;			# decorations
	if ( $f->{style} eq "italic" ) {
	    push( @c, q{font-style:italic} );
	}
	if ( $f->{weight} eq "bold" ) {
	    push( @c, q{font-weight:bold} );
	}
	if ( $fragment->{color} && $fragment->{color} ne $self->{_currentcolor} ) {
	    push( @c, join(":","color",$fragment->{color}) );
	}
	if ( $fragment->{size} && $fragment->{size} ne $self->{_currentsize} ) {
	    push( @c, join(":","font-size",$fragment->{size}) );
	}
	if ( $fragment->{bgcolor} ) {
	    push( @c, join(":","background-color",$fragment->{bgcolor}) );
	}
	if ( $fragment->{underline} ) {
	    push( @d, q{underline} );
	}
	if ( $fragment->{strikethrough} ) {
	    push( @d, q{line-through} );
	}
	push( @c, "text-decoration-line:@d" ) if @d;
	$res .= "<span style=\"" . join(";",@c) . "\">" if @c;
	$res .= ChordPro::Output::HTML::html(ChordPro::Utils::fq($fragment->{text}));
	$res .= "</span>" if @c;
    }
    $res;
}

1;
