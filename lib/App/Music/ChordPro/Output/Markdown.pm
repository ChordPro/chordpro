#!/usr/bin/perl

package main;

our $options;
our $config;

package App::Music::ChordPro::Output::Markdown;

use App::Music::ChordPro::Output::Common;

use strict;
use warnings;
use JSON;
use Data::Dumper;

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @book;
   # push(@book, "[TOC]"); # maybe https://metacpan.org/release/IMAGO/Markdown-TOC-0.01 to create a TOC?

    foreach my $song ( @{$sb->{songs}} ) {
	if ( @book ) {
	    push(@book, "") if $options->{'backend-option'}->{tidy};
	}
	push(@book, @{generate_song($song)});
    push(@book, "---\n"); #Horizontal line between each song
	}

    push( @book, "");
    \@book;
}

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chords lines
my $chords_under = 0;		# chords under lyrics
my $layout = Text::Layout::Markdown->new;
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

    push(@s, "# " . $s->{title})
      if defined $s->{title};
    if ( defined $s->{subtitle} ) {
	push(@s, map { +"## $_" } @{$s->{subtitle}});
    }

    push(@s, "") if $tidy;
	if ( $lyrics_only eq 0 ){
		my $all_chords = "";
		# https://chordgenerator.net/D.png?p=xx0212&s=2 # reuse of other projects (https://github.com/einaregilsson/ChordImageGenerator)?
		# generate png-out of this project? // fingers also possible - but not set in basics.
		foreach my $mchord (@{$s->{chords}->{chords}}){
			# replace -1 with 'x' - alternative '-'
			my $frets = join("", map { if($_ eq '-1'){ $_ = 'x'; } +"$_"} @{$s->{chordsinfo}->{$mchord}->{frets}});
			$all_chords .= "![$mchord](https://chordgenerator.net/$mchord.png?p=$frets&s=2) ";
			
		}
		push(@s, $all_chords);
  	}  
	my $ctx = "";
    my @elts = @{$s->{body}};
	my $init_context = 1;
	my $last_type = "";
    while ( @elts ) {
	my $elt = shift(@elts);

	if ($ctx = $elt->{context} ){ # same context
		push(@s, "\n**$ctx**\n") if($init_context eq 1);
		$init_context = 0;
	} else {
		$init_context = 1;
	}

	if ( $elt->{context} ne $ctx ) {
	    push(@s, "\n**$ctx**\n") if $ctx;
	}
	if($last_type ne $elt->{type}){
		if((
			($last_type =~ /^comment(?:_italic|_box)?$/) or 
			($last_type =~ /^comment(?:_italic|_box)?$/)
		)
		and $elt->{type} eq "songline"){push(@s, ""); } # Emptyline
	}
	$last_type = $elt->{type};

	if ( $elt->{type} eq "empty" ) {
	    push(@s, "***SHOULD NOT HAPPEN***")
	      if $s->{structure} eq 'structured';
	    push(@s, "");
	    next;
	}

#	 if ( $elt->{type} eq "colb" ) {
#	     push(@s, "\n\n\n");
#	     next;
#	}

	 if ( $elt->{type} eq "newpage" ) {
	     push(@s, "---"); #HR
	     next;
	 }

	if ( $elt->{type} eq "songline" ) {
	    push(@s, songline( $s, $elt ));
	    next;
	}

	if ( $elt->{type} eq "tabline" ) { #needed to be fixed font like code
	    push(@s, "\t".$elt->{text});
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    push(@s, "") if $tidy;
	    push(@s, "**chorus**");
	#	push(@s, " ");
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
	 #   push(@s, " ");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    if ( $rechorus->{quote} ) {
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
	    push(@s, "**Tabulatur**  ");
	    push(@s, "\t".map { $_->{text} } @{$elt->{body}} ); #maybe this need to go for code markup as well´?
#	    push(@s, " ");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "gridline" ) {
	    my @a = @{ $elt->{tokens} };
		@a = map { $_->{class} eq 'chord'
			 ? $_->{chord}
			 : $_->{symbol} } @a;
		push(@s, "\t".join("", @a));
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    push(@s, "") if $tidy;
	    push(@s, "**Verse**  ");
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
		    push(@s, "> " . $e->{text} . "  ");
		    next;
		}
		if ( $e->{type} eq "comment_italic" ) {
		    push(@s, "> *" .$e->{text}. "*  ");
		    next;
		}
	    }
	 #   push(@s, " ");
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
		if ($elt->{type} =~ /italic$/) {
			$text = "*" . $text . "*  ";
		}
	    push(@s, "> $text  ");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "image" ) {
	   # my @args = ( , ")" );
#	    while ( my($k,$v) = each( %{ $elt->{opts} } ) ) {
#		push( @args, "$k=$v" );
#	    }
#	    foreach ( @args ) {
#		next unless /\s/;
#		$_ = '"' . $_ . '"';
#	    }
	    push( @s, "![](".$elt->{uri}.")" );
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
    push(@s, "\x{00A0}  ") if $ctx;

    \@s;
}

sub md_textline{
	my ( $songline ) = @_;
	my $empty = $songline;
    my $textline = $songline;
    my $nbsp = "\x{00A0}"; #unicode for nbsp sign
    if($empty =~ /^\s+/){ # starts with spaces
	    $empty =~ s/^(\s+).*$/$1/; # not the elegant solution - but working - replace all spaces in the beginning of a line
        my $replaces = $empty;  #with a nbsp symbol as the intend tend to be intentional
        $replaces =~ s/\s/$nbsp/g;
        $textline =~ s/$empty/$replaces/;
    }
	$textline = $textline."  "; # append two spaces to force linebreak in Markdown
	return $textline;
}
 

sub songline {
	# a bit more comments on what this means - i mean elt? whats that suppose to mean?
    my ( $song, $elt ) = @_;

    my $t_line = "";
    my @phrases = map { $layout->set_markup($_); $layout->render }
      @{ $elt->{phrases} };

    if ( $lyrics_only
	 or
	 $single_space && ! ( $elt->{chords} && join( "", @{ $elt->{chords} } ) =~ /\S/ )
       ) {
	$t_line = join( "", @phrases );
	return md_textline($t_line);
    }

    unless ( $elt->{chords} ) { # i guess we have a line with chords now... 
	return ( md_textline(join( " ", @phrases )) );
    }

    if ( my $f = $::config->{settings}->{'inline-chords'} ) {
	$f = '[%s]' unless $f =~ /^[^%]*\%s[^%]*$/;
	$f .= '%s';
	foreach ( 0..$#{$elt->{chords}} ) {
	    $t_line .= sprintf( $f,
				chord( $song, $elt->{chords}->[$_] ),
				$phrases[$_] );
	}
	return ( md_textline($t_line) );
    }

    my $c_line = "";
    foreach ( 0..$#{$elt->{chords}} ) {
	$c_line .= chord( $song, $elt->{chords}->[$_] ) . " ";
	$t_line .= $phrases[$_];
	my $d = length($c_line) - length($t_line);
	$t_line .= "-" x $d if $d > 0;
	$c_line .= " " x -$d if $d < 0;
    } # this looks like setting the chords above the words.

    s/\s+$// for ( $t_line, $c_line );

	# main problem in markdown - a fixed position is only available in "Code escapes" so weather to set
	# a tab or a double backticks (``)  - i tend to the tab - so all lines with tabs are "together"
	if ($c_line ne ""){ # Block-lines are not replacing initial spaces - as the are "code"
		$t_line = "\t".$t_line."  ";
		$c_line = "\t".$c_line."  ";
		}
	else{
		$t_line = md_textline($t_line);
	}
	return $chords_under
		? ( $t_line, $c_line )
		: ( $c_line, $t_line )
}

sub chord {
    my ( $s, $c ) = @_;
    return "" unless length($c);
    my $ci = $s->{chordsinfo}->{$c};
    return "<<$c>>" unless defined $ci;
    $layout->set_markup($ci->show);
    my $t = $layout->render;
    return $ci->is_annotation ? "*$t" : $t;
}

package Text::Layout::Markdown;

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
