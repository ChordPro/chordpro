#! perl

package main;

our $options;
our $config;

package ChordPro::Output::MMA;

use ChordPro::Output::Common;

use strict;
use warnings;

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @book;

    die("MMA generation requires a single song\n")
      if @{$sb->{songs}} > 1;

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

my $groove;			# groove to use
my $single_space = 0;		# suppress chords line when empty
my $chords_under = 0;		# chords under lyrics

sub safemeta {
    my ( $s, $meta, $default ) = @_;
    return $default unless defined $meta && defined $s->{meta}->{$meta};
    return $s->{meta}->{$meta}->[0];
}

sub generate_song {
    my ( $s ) = @_;

    my $st = 0;			# current MMA statement number
    my $cur = '';		# MMA statement under construction
    my $prev = '';		# previous MMA statement
    my $did = 0;		# preamble was emitted
    my $pchord = '.';		# last real chord

    $groove       = $options->{'backend-option'}->{groove};
    my $tidy      = $options->{'backend-option'}->{tidy};

    # Normally a counting beat is 1 quarter. deCoda uses 1/8th.
    my $decoda    = $options->{'backend-option'}->{decoda} || $options->{'backend-option'}->{deCoda};

    $single_space = $options->{'single-space'};
    $chords_under = $config->{settings}->{'chords-under'};

    $s->structurize
      if ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';

    my @s;

    # Preamble.
    push( @s, "// title: " . $s->{title}, "" ) if defined $s->{title};

    # Select a groove.
    my $bpm = 4;
    my $q = 4;
    ( $bpm, $q ) = ( $1, $2 ) if safemeta( $s, "time", "4/4" ) =~ /^(\d+)\/(\d+)/;
    unless ( $groove ) {
	if ( $bpm == 3 ) {
	    $q = 4 unless $q == 8;
	    $groove = "Neutral$bpm$q";
	}
	elsif ( $bpm == 6 ) {
	    warn("Time 6/$q set to 6/8\n") unless $q == 8;
	    $q = 8;
	    $groove = "Neutral$bpm$q";
	}
	else {
	    warn("Time $bpm/$q set to 4/4\n");
	    $q = $bpm = 4;
	    $groove = "Neutral44";
	}
    }

    push( @s, sprintf( "Time   %d/%d", $bpm, $q ) );
    push( @s, makegroove( $bpm, $q ) );

    # When deCoda decodes a song in 6/8 at 100bpm, it gets interpreted as 2/4.
    # When the time signature is manually fixed to 6/8, the song becomes
    # twice as long. So we must double the tempo.
    push( @s, sprintf( "Tempo  %d",
		       safemeta( $s, "tempo", 60 ) * (( $q == 8 && $decoda ) ? 2 : 1 )
		     ) );

    push( @s, "", "/**** End of Preamble ****/", "" );

    my $ctx = "";
    my $line;

    foreach my $elt ( @{$s->{body}} ) {
	my $line = sprintf( "%3d", $elt->{line} );

	if ( $elt->{context} ne $ctx ) {
	    push(@s, "// $line End of $ctx") if $ctx;
	    push(@s, "// $line Start of $ctx") if $ctx = $elt->{context};
	}

	if ( $elt->{type} eq "empty" ) {
	    push(@s, "***SHOULD NOT HAPPEN***")
	      if $s->{structure} eq 'structured';
	    push(@s, "");
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    push(@s, "// $line Column break");
	    next;
	}

	if ( $elt->{type} eq "newpage" ) {
	    push(@s, "// $line New page");
	    next;
	}

	if ( $elt->{type} eq "gridline" ) {
	    my @a = @{ $elt->{tokens} };
	    # Reduce the elements (objects) to simple chords or symbols.
	    @a = map { $_->{class} eq 'chord'
			 ? $_->{chord}->key
			 : $_->{symbol} } @a;

	    push( @s, "// $line @a" );

	    # Remove label and initial bar symbol.
	    my $firstbar;
	    do { } until is_bar( $firstbar = shift(@a) );

	    if ( $decoda && $q == 4 ) {
		# deCoda always uses a beat step of 8. For x/4 times we must reduce.
		@a = reduce( \@a, $bpm, $line, \@s);
		push( @s, "// $line $firstbar " .
		      join(" ", @a) );
	    }

	    # Bars must be full.
	    if ( @a % ( $bpm + 1 ) )  {
		push( @s, "// $line $bpm $q ".scalar(@a)." OOPS?" );
		next;
	    }

	    my $rept = 0;
	    my $bar = 0;

	    # Process the elements.
	    while ( @a ) {
		# Increment bar number and mma statement number.
		$bar++;
		$st++;
		my $c = '';		# mma statement being constructed

		# Reuse last chord if we have none.
		if ( $a[0] eq '.' && $a[1] eq '.' ) {
		    $a[0] = $pchord;
		}

		# Process the beats.
		for ( my $b = 1; $b <= $bpm; $b++ ) {

		    # Get a chord.
		    $cur = shift(@a);

		    # Append to statement.
		    $c .= $cur eq '.' ? "/ " : "$cur ";
		    $pchord = $cur unless $cur eq '.';
		}

		# Remove trailing slashes.
		$c =~ s;[\s/]+$;;;
		$c = $prev unless $c =~ /\S/;

		# Print MMA statement.
		if ( $prev eq $c || $st == 1 ) {
		    $rept++;
		}
		else {
		    push( @s,
			  sprintf( "%3d  %s%s", $st-$rept, $prev,
				   $rept > 1 ? " * $rept" : "" )
				 ) if $rept;
		    $rept = 1;
		}
		$prev = $c;

		# Check for trailing barline.
		unless ( is_bar(shift(@a)) ) {
		    push( @s, "// bar $bar: Missing final barline?" );
		    warn("line $., bar $bar: Missing final barline?\n");
		}
	    }
	    push( @s,
		  sprintf( "%3d  %s%s", $st-$rept+1, $prev,
			   $rept > 1 ? " * $rept" : "" ) );
	    $rept = 0;

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
	    $text = fmt_subst( $s, $text );
	    push(@s, "// $line comment: $text");
	    push(@s, "") if $tidy;
	    next;
	}

	next;

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
	    push(@s, "// $line Start of chorus*");
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
	    push(@s, "// $line End of chorus*");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    push(@s, "") if $tidy;
	    push(@s, "// $line Start of tab");
	    push(@s, map { "// " . $_->{text} } @{$elt->{body}} );
	    push(@s, "// $line End of tab");
	    push(@s, "") if $tidy;
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    push(@s, "") if $tidy;
	    push(@s, "// $line Start of verse");
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
	    push(@s, "// $line End of verse");
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
	    push( @s, "// $line @args" );
	    next;
	}

	if ( $elt->{type} eq "set" ) {
	    next;
	}

	if ( $elt->{type} eq "control" ) {
	    next;
	}

	# Ignore everyting else.

    }
    push(@s, "// $line End of $ctx") if $ctx;

    \@s;
}

sub songline {
    my ($elt) = @_;

    my $t_line = "";

    if ( $single_space && ! ( $elt->{chords} && join( "", @{ $elt->{chords} } ) =~ /\S/ )
       ) {
	$t_line = join( "", @{ $elt->{phrases} } );
	$t_line =~ s/\s+$//;
	return $t_line;
    }

    unless ( $elt->{chords} ) {
	return ( "", join( " ", @{ $elt->{phrases} } ) );
    }

    if ( my $f = $::config->{settings}->{'inline-chords'} ) {
	$f = '[%s]' unless $f =~ /^[^%]*\%s[^%]*$/;
	$f .= '%s';
	foreach ( 0..$#{$elt->{chords}} ) {
	    $t_line .= sprintf( $f,
				$elt->{chords}->[$_]->key,
				$elt->{phrases}->[$_] );
	}
	return ( $t_line );
    }

    my $c_line = "";
    foreach ( 0..$#{$elt->{chords}} ) {
	$c_line .= $elt->{chords}->[$_]->key . " ";
	$t_line .= $elt->{phrases}->[$_];
	my $d = length($c_line) - length($t_line);
	$t_line .= "-" x $d if $d > 0;
	$c_line .= " " x -$d if $d < 0;
    }
    s/\s+$// for ( $t_line, $c_line );
    return $chords_under
      ? ( $t_line, $c_line )
      : ( $c_line, $t_line )
}

sub is_bar {
    for ( $_[0] ) {
	return 1
	  if $_ eq "|:"  || $_ eq "{"
	  || $_ eq ":|"  || $_ eq "}"
	  || $_ eq ":|:" || $_ eq "}{"
	  || $_ eq "|"   || $_ eq "||" || $_ eq "|.";
    }
    return;
}

sub reduce {
    my ( $a, $bpm, $line, $s ) = @_;
    my @a = @$a;
    warn("R: ", join(' ',@a), "\n") if $config->{debug}->{mma};
    my @reduced;
    my $bar = 0;
    my $carry;

    while ( @a ) {
	$bar++;
	if ( $carry ) {
	    if ( $a[0] eq '.' ) {
		$a[0] = $carry;
	    }
	    else {
		push( @$s,
		      sprintf( "// line %d, bar %d, cannot resolve %s (from previous line)",
			       $line, $bar, $carry ) );
	    }
	    $carry = '';
	}
	for ( my $b = 1; $b <= $bpm; $b++ ) {
	    my $a0 = shift(@a);
	    my $a1 = shift(@a);
	    # Check for clash.
	    if ( $a0 ne '.' && $a1 ne '.' ) {
		if ( @a > 1 && $a[0] eq '.' && $a[1] eq '.' ) {
		    # X Y . . => X . Y .
		    $a[0] = $a1;
		    push( @$s,
			  sprintf("// line %d, bar %d, beat %d: shifting %s to beat %d",
				  $line, $bar, $b, $a[0], $b+1) );
		}
		else {
		    # Cannot resolve.
		    push( @$s,
			  sprintf( "// line %d, bar %d, beat %d: too many chords",
				   $line, $bar, $b ) );
		}
	    }
 
	    # Check for clash and try to resolve.
	    # . X => X .
	    if ( $a0 eq '.' && $a1 ne '.' ) {
		$a0 = $a1;
		push( @$s,
		      sprintf( "// line %d, bar %d, beat %d: move back %s",
			       $line, $bar, $b, $a1) );
	    }
	    # x X . => x . X 
	    elsif (  $a1 ne '.' ) {
		if ( @a > 1 && is_bar($a[0]) && $a[1] eq '.' ) {
		    $a[1] = $a1;
		    push( @$s,
			  sprintf( "// line %d, bar %d, beat %d: advancing %s",
				   $line, $bar, $b, $a1) );
		}
		elsif ( @a > 0 && $a[0] eq '.' ) {
		    $a[0] = $a1;
		    push( @$s,
			  sprintf( "// line %d, bar %d, beat %d: advancing %s",
				   $line, $bar, $b, $a1) );
		}
		elsif ( !@a ) {
		    $carry = $a1;
		    push( @$s,
			  sprintf( "// line %d, bar %d, beat %d: carry %s to next line",
				   $line, $bar, $b, $a1) );
		}
	    }
	    push( @reduced, $a0 );
	}
	if ( is_bar($a[0]) ) {
	    push( @reduced, shift(@a) );
	}
	else {
	    push( @$s,
		  sprintf( "// line %d, bar %d, missing bar line?", $line, $bar ) )
	}
    }
    return @reduced;
}

sub makegroove {
    my ( $bpm, $q ) = @_;

    return ( "Groove $groove" ) if $groove;

    my @s;
    if ( $bpm == 3 ) {
	$q = 4 unless $q == 8;
	$groove = "Neutral$bpm$q";
    }
    elsif ( $bpm == 6 ) {
	$q = 4 unless $q == 8;
	$groove = "Neutral$bpm$q";
    }
    else {
	$groove = "Neutral44";
    }

    my $seq;
    my $whole;

    if ( $bpm == 3 && $q == 4 ) {
	$whole = "2.";
	$seq = "{ 1 0 90; 2 0 30; 3 0 30 }";
    }
    elsif ( $bpm == 3 && $q == 8 ) {
	$whole = "4.";
	$seq = "{ 1 0 90; 1.67 0 30; 2.33 0 30 }";
    }
    elsif ( $bpm == 6 && $q == 8 ) {
	$whole = "1.";
	$seq = "{ 1 0 90; 2 0 30; 3 0 30; 4 0 80; 5 0 30; 6 0 30 }";
    }
    else {			# assume 4/4
	$whole = "1";
	$seq = "{ 1 0 90; 2 0 30; 3 0 50; 4 0 30 }";
    }

    return split( /\n/, <<EOD );
SeqClear
SeqSize 1
Time $bpm/$q

Begin Drum-Side
    Tone        KickDrum1
    Sequence    { 1.0 0 60 }
    Volume      30
End

Begin Drum-CHH
    Tone        ClosedHiHat
    Sequence    $seq
    Volume      30
End

Begin Chord
    Channel	2
    Voice	ReedOrgan
    Sequence	{ 1 $whole 50 }
    Volume	30
    Articulate 	100
End

DefGroove $groove

Groove $groove

EOD

}

1;

unless ( caller) {
    my $bpm = 4;
    my @s = ();
    unless ( join( ' ',
		   reduce( [split(' ','C . . . . . . . | C . . . . . . . | C . . . . . . . | C . . . . . . . |')], $bpm, 1, \@s) )
	     eq 'C . . . | C . . . | C . . . | C . . . |'
	   ) {
	warn("reduce error\n");
	print "$_\n" for @s;
    }
    while ( <> ) {
	@s = ();
	chomp;
	print("=> ", join(' ',reduce([split(' ',$_)], $bpm, 1, \@s)), "\n");
	print "$_\n" for @s;
    }
}
