#!/usr/bin/perl

package main;

our $options;
our $config;

package ChordPro::Output::Text;

use ChordPro::Output::Common;

use strict;
use warnings;

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @book;

    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    push(@book, "") if $options->{'backend-option'}->{tidy};
	    push(@book, "-- New song");
	}
	push(@book, @{generate_song($song)});
    }

    push( @book, "");
    \@book;
}

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chords lines
my $chords_under = 0;		# chords under lyrics
my $layout = Text::Layout::Text->new;
my $rechorus;

sub upd_config {
    $lyrics_only  = $config->{settings}->{'lyrics-only'};
    $chords_under = $config->{settings}->{'chords-under'};
    $rechorus  = $config->{text}->{chorus}->{recall};
}

sub generate_song {
    my ( $s ) = @_;

    my $tidy      = $options->{'backend-option'}->{tidy};
    $single_space = $options->{'single-space'};
    upd_config();

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
    my @elts = @{$s->{body}};
    while ( @elts ) {
	my $elt = shift(@elts);

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
	    push(@s, songline( $s, $elt ));
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
		    push(@s, songline( $s, $e ));
		    next;
		}
	    }
	    push(@s, "-- End of chorus*");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    if ( $rechorus->{quote} && $elt->{chorus} ) {
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
		    push(@s, songline( $s, $e ));
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
		    $text .= "[" . $elt->{chords}->[$_]->key . "]"
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
	    my @args = ( "image:", $elt->{uri} // "<none>" );
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
	    # Arbitrary config values.
	    elsif ( $elt->{name} =~ /^(text\..+)/ ) {
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

	if ( $elt->{type} eq "control" ) {
	}
    }
    push(@s, "-- End of $ctx") if $ctx;

    \@s;
}

sub songline {
    my ( $song, $elt ) = @_;

    my $t_line = "";
    my @phrases = map { $layout->set_markup($_); $layout->render }
      @{ $elt->{phrases} };

    if ( $lyrics_only
	 or
	 $single_space && ! ( $elt->{chords} && join( "", map { $_?$_->key:"" } @{ $elt->{chords} } ) =~ /\S/ )
       ) {
	$t_line = join( "", @phrases );
	$t_line =~ s/\s+$//;
	return $t_line;
    }

    unless ( $elt->{chords} ) {
	return ( "", join( " ", @phrases ) );
    }

    if ( my $f = $::config->{settings}->{'inline-chords'} ) {
	$f = '[%s]' unless $f =~ /^[^%]*\%s[^%]*$/;
	$f .= '%s';
	foreach ( 0..$#{$elt->{chords}} ) {
	    $t_line .= sprintf( $f,
				$elt->{chords}->[$_] ? chord( $song, $elt->{chords}->[$_] ) : "",
				$phrases[$_] );
	}
	return ( $t_line );
    }

    my $c_line = "";
    foreach my $c ( 0..$#{$elt->{chords}} ) {
	$c_line .= chord( $song, $elt->{chords}->[$c] ) . " "
	  if ref $elt->{chords}->[$c];
	$t_line .= $phrases[$c];
	my $d = length($c_line) - length($t_line);
	$t_line .= "-" x $d if $d > 0;
	$c_line .= " " x -$d if $d < 0;
    }
    s/\s+$// for ( $t_line, $c_line );
    return $chords_under
      ? ( $t_line, $c_line )
      : ( $c_line, $t_line )
}

sub chord {
    my ( $s, $c ) = @_;
    return "" unless length($c);
    $layout->set_markup($c->chord_display);
    my $t = $layout->render;
    return $c->info->is_annotation ? "*$t" : $t;
}

# Temporary. Eventually we'll have a decent HTML backend for Text::Layout.

package Text::Layout::Text;

use parent 'Text::Layout';
use ChordPro::Utils qw( fq );

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
	$res .= fq($fragment->{text});
    }
    $res;
}

1;
