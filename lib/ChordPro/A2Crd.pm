#! perl

use v5.26;

package ChordPro::A2Crd;

use ChordPro::Version;
use ChordPro::Paths;
use ChordPro::Chords;

our $VERSION = $ChordPro::Version::VERSION;

=head1 NAME

ChordPro::A2Crd - convert lyrics and chords to ChordPro

=head1 SYNOPSIS

  perl -MA2Crd -e run -- [ options ] [ file ... ]

(But no one does that.)

When the associated B<chordpro> program has been installed correctly:

  chordpro --a2crd [ options ] [ file ... ]

=head1 DESCRIPTION

B<This program>, referred to as B<a2crd>, will read a text file
containing the lyrics of one or many songs with chord information
written visually above the lyrics. This is often referred to as I<crd>
data. B<a2crd> will then generate equivalent ChordPro output.

Typical a2crd input:

    Title: Swing Low Sweet Chariot

	  D          G    D
    Swing low, sweet chariot,
			   A7
    Comin' for to carry me home.
	  D7         G    D
    Swing low, sweet chariot,
		  A7       D
    Comin' for to carry me home.

      D                       G          D
    I looked over Jordan, and what did I see,
			   A7
    Comin' for to carry me home.
      D              G            D
    A band of angels comin' after me,
		  A7       D
    Comin' for to carry me home.

Note that the output from the conversion will generally need some
additional editing to be useful as input to ChordPro.

B<a2crd> is a wrapper around L<ChordPro::A2Crd>, which
does all of the work.

B<chordpro> will read one or more text files containing the lyrics of
one or many songs plus chord information. B<chordpro> will then
generate a photo-ready, professional looking, impress-your-friends
sheet-music suitable for printing on your nearest printer.

B<chordpro> is a rewrite of the Chordii program.

For more information about the ChordPro file format, see
L<https://www.chordpro.org>.

=cut

################ Common stuff ################

use strict;
use warnings;
use utf8;
use Carp;

################ The Process ################

package main;

our $options;
our $config;

package ChordPro::A2Crd;

use ChordPro::Config;

use File::LoadLines;
use Encode qw(decode decode_utf8 encode_utf8);
my $local_debug;

# API: Main entry point.
sub a2crd {
    my ($opts) = @_;
    $options = { %$options, %$opts } if $opts;

    # One configurator to bind them all.
    $config = ChordPro::Config::configurator({});
    $local_debug = $config->{debug}->{a2crd};

    # Process input.
    my $lines = $opts->{lines}
      ? delete($opts->{lines})
      : loadlines( @ARGV ? $ARGV[0] : \*STDIN);

    return [ a2cho($lines) ];
}

################ Subroutines ################

# Replace tabs with blanks, retaining layout.
my $tabstop;
sub expand {
    my ( $line ) = @_;
    return $line unless $line;
    $tabstop //= $::config->{a2crd}->{tabstop};
    return $line unless $tabstop > 0;

    my ( @l ) = split( /\t/, $line, -1 );
    return $l[0] if @l == 1;

    $line = shift(@l);
    $line .= " " x ($tabstop-length($line)%$tabstop) . shift(@l) while @l;

    return $line;
}

# API: Produce ChordPro data from AsciiCRD lines.
sub a2cho {
    my ( $lines ) = @_;
    my $map = "";
    my @lines_with_tabs_replaced ;
    foreach ( @$lines ) {
        if(/\t/) {
	    $_ = expand($_) ;
        }

	#s/=20/ /g ; # replace HTML coded space with ascii space, no, MUST LEAVE IN because it can mess up fingering diagrams like A/F#=202220
	s/=3D/=/g ; # replace HTML coded equal with ascii =
	# s/\s*$// ;  # remove all trailing whitespace -- no, MUST LEAVE IN so chords indicated above trailing whitespace will be properly formatted 

	my $n_ch_chords=0 ;

        #An odd format for chords, [ch]Chordname[\ch], possibly from reformated webpage
	# need to strip out and consider it to be a chord line
	while(s/\[ch\](.*?)\[\/ch\]/$1/)  {
	   $n_ch_chords++ ;
	}

        push @lines_with_tabs_replaced, $_ ;

	if($n_ch_chords < 1) {
	    $map .= classify($_);
	} else {
	    $map .= "c" ;
	}
    }
    maplines( $map, \@lines_with_tabs_replaced );

}

# Classify the line and return a single-char token.
my $classify;
sub classify {
    my ( $line ) = @_;
    return '_' if $line =~ /^\s*$/;	# empty line
    return '{' if $line =~ /^\{.+/;	# directive
    unless ( defined $classify ) {
	my $classifier = $::config->{a2crd}->{classifier};
	$classify = __PACKAGE__->can("classify_".$classifier);
	unless ( $classify ) {
	    warn("No such classifier: $classifier, using classic\n");
	    $classify = \&classify_classic;
	}

    }
    $classify->($line);
}

sub classify_classic {
    my ( $line ) = @_;
    # Lyrics or Chords heuristic.
    my @words = split ( /\s+/, $line );
    my $len = length($line);
    $line =~ s/\s+//g;
    my $type = ( $len / length($line) - 1 ) < 1 ? 'l' : 'c';
    my $p = ChordPro::Chords::Parser->default;
    if ( $type eq 'l') {
        foreach (@words) {
            if (length $_ > 0) {
                if (!ChordPro::Chords::parse_chord($_)) {
                    return 'l';
                }
            }
        }
        return 'c';
    }
    return $type;
}

# JJW -- attempts at using "relaxed" in the standard chordnames parser were too relaxed
# so I made this to try to parse unspecified chords that still have well defined "parts" in the chordname
# these chords probably are understandable by a human, but too out of spec for the chordpro parser to interpret
# my use of regex is probably not optimal -- I haven't had a lot of regex experience.
# this currently only works for the roman chord notation
sub generic_parse_chord
{
    my $word = shift ;

    my ($chord,$bass) ;
    if ( $word =~ m;^(.*)/(.*); ) {
	$chord = $1;
	$bass = $2;
    } else {
	$chord=$word ;
    }

    if($bass) {

	# this was the first attempt, but found it to be to restrictive
	#return 0 if(! ($bass =~ /^($roots)$/) ) ;

	# now allow anything after the "/"
    }

    # in anticipation of nashville and solfege ;
    my $roots = "^[A-G]" ;
    my $found_chord_base="" ;

    # first part of chord needs to be [A-G]
    return 0 if(! ($chord =~ s/($roots)//))  ;

    $found_chord_base .= $1 ;

    $chord = lc($chord) ; # simplify to lowercase for further parsing

    if($chord =~ s/^([b#]|flat|sharp)//) {
	$found_chord_base .= $1 ;
    }

    if($chord =~ s/^(minor|major)//) {
	$found_chord_base .= $1 ;
    }

    if($chord =~ s/^(min|maj)//) {
	$found_chord_base .= $1 ;
    }

    if($chord =~ s/^(m|dim|0|o|aug|\+)//) {
	$found_chord_base .= $1 ;
    }

    $chord =~ s/^[\d]*// ;  # to get the 7 in "A7", etc

    # all that should remain are note numbers and note modifiers b, #, "sus", "add", "flat", "sharp", -, +
    # strip those possible combinations one at a time

    while( $chord =~ s/^(b|#|\+|\-|flat|sharp|sus|add)*?\d// ) {} ;

    # if all that remains are digits and  "#b-", it's probably a chord
    my $n_ok = ($chord =~ tr/0123456789#b-//) ;

    return 1 if $n_ok == length $chord ;
}

# determine if the input line is a fingering definition for a chord
sub decode_fingering
{
    my ($line,$return_chordpro_fingering) = @_ ;
    my $is_fingering=0 ;
    my $input_line = $line ;
    my $any_chord_ok=1 ; # allows any text for the chord preceding a fingering pattern to be valid

    # since more than one chord can be defined on a single input text line,
    # hold all results in these two arrays 
    my (@chords,@fingerss) ;

    # THIS ONLY WORKS FOR FRETS <=9 right now

    # is it a fingering notation?

    my $pre = "^.*?\\s*?" ; # the pattern to match just before a chord name
    my $valid = "[A-G]{1}\\S*?" ; # a valid chordname

    # ("chord:")  followed by "|x2344x|"  or "x2344x"
    while($line =~ /$pre($valid)\:+?\s*?(\|?[xX0-9]{3,7}\|?)/) {
	my $cname=$1 ;
	my $fingers_this=$2 ;
	my $nobar_fingers=$fingers_this ;
	$nobar_fingers =~ s/\|//g ;

	if($any_chord_ok || generic_parse_chord($cname)) {
	    push @chords,$cname ;
	    push @fingerss,$nobar_fingers ;
	    $is_fingering=1 ;
	}

	$line =~ s/.*?$nobar_fingers// ;
    }


    # ("chord")  followed by "|x2344x|"  "x2344x"
    while($line =~ /$pre($valid)\s+?(\|?[xX0-9]{3,7}\|?)/) {
	my $cname=$1 ;
	my $fingers_this=$2 ;
	my $nobar_fingers=$fingers_this ;
	$nobar_fingers =~ s/\|//g ;

	if($any_chord_ok || generic_parse_chord($1)) {
	    push @chords,$cname ;
	    push @fingerss,$nobar_fingers ;
	    $is_fingering=1 ;
	}

	$line =~ s/.*?$nobar_fingers// ;
    }

    # "(chord) = (fingering)" format
    while($line =~ /$pre($valid)\s*?\=\s*?([xX0123456789]{3,7})/) {
	my $cname=$1 ;
	my $fingers_this=$2 ;
	my $nobar_fingers=$fingers_this ;
	$nobar_fingers =~ s/\|//g ;

	if($any_chord_ok || generic_parse_chord($1)) {
	    push @chords,$cname ;
	    push @fingerss,$nobar_fingers ;
	    $is_fingering=1 ;
	}

	$line =~ s/.*?$nobar_fingers// ;
    }

    if($is_fingering) {
	return 1 if ! $return_chordpro_fingering ;

	# handle situation where more than one chord is defined on an input text line
	my @output_lines ;

	#push @output_lines, $input_line if 1 ; # only for debugging

	foreach my $chord (@chords) {
	    my $fingers = shift @fingerss ;
	    my $min_fret=100 ;
	    my $max_fret=0 ;
	    my @frets ;

	    while($fingers =~ s/(.)//) {
		my $fret=$1 ;
		push @frets, $fret ;

		if($fret =~ /[0-9]/) {
		    $min_fret = $fret if $min_fret > $fret ;
		    $max_fret = $fret if $max_fret < $fret ;
		}
	    }

	    # now convert the requested fingering to chordpro format
	    my $bf=$min_fret ;

	    my $chordpro = "{define $chord base-fret $bf frets" ;
	    $bf-- if $bf > 0 ;

	    foreach my $fret (@frets) {
		$chordpro = $chordpro . " " ;

		if($fret =~ /[0-9]/) {
		    my $rf = $fret-$bf ;

		    $chordpro .= "$rf" ;
		} else {
		    $chordpro .= '-' ;
		}
	    }

	    $chordpro .= "}" ;
	    push @output_lines, $chordpro ;
	}

	return @output_lines ;
    }

    return 0 ;
}

# classification characters are:
# 'l' = normal text line, usually lyrics but may be other plain text as well
# 'C' = a comment
# 'f' = a chord fingering request
# 't' = tablature
# 'c' = chords, usually to be output inline with a subsequent 'l' line
# '{' = an embedded chordpro directive found in the input file, to be output with no changes
# '_' = a blank line, i.e. it contains only whitespace

# Alternative classifier by Jeff Welty.
# Strategy: Percentage of recognzied chords.
sub classify_pct_chords {
    my ( $line ) = @_;
    my $lc_line = lc($line) ;

    return 'C' if $line =~ /^\s*\[.+?\]/;	# comment
    return 'C' if $line =~ /^\s*\#.+?/;	# comment
    return 'C' if $lc_line =~ /(from|email|e\-mail)\:?.+?@+/ ;  # email is treated as a comment
    return 'C' if $lc_line =~ /(from|email|e\-mail)\:.+?/ ;  # same as above, but there MUST be a colon, and no @ is necessary
    return 'C' if $lc_line =~ /(date|subject)\:.+?/ ;  # most likely part of email lines is treated as a comment

    # check for a chord fingering specification, i.e. A=x02220
    return 'f' if decode_fingering($line,0) ;

    if(0) {
	#Oct 31 and before
	return 't' if $line =~ /^\s*?[A-G|a-g]\s*\|.*?\-.*\|/;	# tablature
	return 't' if $line =~ /^\s*?[A-G|a-g]\s*\-.*?\-.*\|*/; # tablature
    } else {
	# try to accomodate tablature lines with text after the tab

	my $longest_tablature_string=0 ;
	my $tmpline = $line ;

	# REGEX components:

	# start with any amount of whitespace
	# ^\s*?
	# must be one string note
	# [A-G|a-g]
	# one or more of : or |
	# [:\|]+
	# in the tablature itself, separators of : or |, modifiers of b=bend,p=pull off,h=hammer on,x=muted,0-9 fret positionsj,\/=slides,() for two digit fret positions
	# [\-:\|bphxBPHX0-9\/\\\(\)]*?
	# one or more of : or |
	# [:\|]+

	while($tmpline =~ s/^(\s*?[A-G|a-g][:\|]+[\-:\|bphxBPHX0-9\/\\\(\)]*?[:\|]+)//) {
	    $longest_tablature_string = length($1) if $longest_tablature_string < length($1) ;
	}

	return 't' if $longest_tablature_string > 8 ;
    }


    # count number of specific characters to help identify tablature lines
    my $n_v = ($line =~ tr/v//) ;
    my $n_dash = ($line =~ tr/-//) ;
    my $n_equal = ($line =~ tr/=//) ;
    my $n_bar = ($line =~ tr/|//) ;
    my $n_c_accent = ($line =~ tr/^//) ;
    my $n_period = ($line =~ tr/.//) ;
    my $n_space = ($line =~ tr/ //) ;
    my $n_slash = ($line =~ tr/\///) ;
    my $n_underscore = ($line =~ tr/_//) ;
    my $n_digit = ($line =~ tr/0123456789//) ;

    # some inputs are of the form "|  /  /  / _ / | / / / /  / |", to indicate strumming patterns
    # need to recognize this as tablature for nice formatting, and if chords are in the line
    # preceding they will be included in the tablature by maplines() to ensure correct formatting
    my $longest_strumming_string=0 ;
    my $cntline = $line ;

    while( $cntline =~ s/([\|\/ _]+?)//) {
	$longest_strumming_string = length($1) if $longest_strumming_string < length($1) ;
    }

    return 't' if ($longest_strumming_string >= 6) ;



    # Lyrics or Chords heuristic.
    my @words = split ( /\s+/, $line );

    my $n_tot_chars = length($line) ;
    $line =~ s/\s+//g ;
    my $n_nonblank_chars = length($line) ;

    # have to wait until $n_nonblank_chars is computed to do these tests
    return 'l' if ($n_dash == $n_nonblank_chars || $n_equal == $n_nonblank_chars) ;  # only "-" or "=", meant to be a textual underline indication of the previous line
    return 't' if (($n_period + $n_dash + $n_bar + $n_c_accent + $n_v + $n_digit)/$n_nonblank_chars > 0.8) ;  # mostly characters used in standard tablature
    return 't' if (($n_bar + $n_slash + $n_underscore)/$n_nonblank_chars >= 0.5) ;  # mostly characters used in strumming tablature


    my $n_chords=0 ;
    my $n_words=0 ;

    #print("CL:") ; # JJW, uncomment for debugging

    foreach (@words) {
	if (length $_ > 0) {
	    $n_words++ ;


	    my $is_chord = ChordPro::Chords::parse_chord($_) ? 1 : 0  ;
	    if(! $is_chord) {
		if(generic_parse_chord($_)) {
		    print STDERR "$_ detected by generic, not internal parse_chord\n" if $local_debug ;
		    $is_chord=1 ;
		}
	    }

	    $n_chords++ if $is_chord ;
	    print STDERR " ($is_chord:$_)" if $local_debug ;

	    #print(" \'$is_chord:$_\'") ; # JJW, uncomment for debugging
	}
    }
    print STDERR "\n" if $local_debug ;

    return '_' if $n_words == 0 ;	# blank line, redundant logic with sub classify(), but makes this more robust to changes in classify() ;

    my $type = $n_chords/$n_words > 0.4 ? 'c' : 'l' ;

    if($type eq 'l') {
	# is it likely the line had a lot of unknown chords, check
	# the ratio of total chars to nonblank chars , if it is large then

	# it's probably a chord line
	# $type = 'c' if $n_words > 1 && $n_tot_chars/$n_nonblank_chars > 2. ;
    }

    #print(" --- ($n_chords/$n_words) = $type\n") ; # JJW, uncomment for debugging

    return $type ;
}

# reformat an input line classified as a comment for the chordpro format
sub format_comment_line
{
    my $line = $_[0] ;
    # remove [] from original comment
    $line =~ s/\[// ;
    $line =~ s/\]// ;
    return '' if $line eq '' ;
    return "{comment:" . $line . "}" ;
}

# Process the lines via the map.
my $infer_titles;
sub maplines {
    my ( $map, $lines ) = @_;
    my @out;
    $infer_titles //= $::config->{a2crd}->{'infer-titles'};

    # Preamble.
    # Pass empty lines.

    print STDERR  "====== _C =====\n" if $local_debug ;
    print STDERR "MAP: \'$map\' \n" if $local_debug ;

    while ( $map =~ s/^([_C])// ) {
	print STDERR "$1 == @{$lines}[0]\n" if $local_debug ;
	# simply output blank or comment lines at the start of the file
	# but don't count the line as possible title
	my $pre  = ($1 eq "C" ? "{comment:" : "" ) ;
	my $post = ($1 eq "C" ? "}" : "" ) ;
	push( @out, $pre . shift( @$lines ) . $post );
    }

    print STDERR "====== infer title =====\n" if $local_debug ;
    # Infer title/subtitle.
    if ( $infer_titles && $map =~ s/^l// ) {
	push( @out, "{title: " . shift( @$lines ) . "}");
	if ( $map =~ s/^l// ) {
	    push( @out, "{subtitle: " . shift( @$lines ) . "}");
	}
    }

    print STDERR "====== UNTIL chords or tablature =====\n" if $local_debug ;
    # Pass lines until we have chords or tablature

    while ($map =~ /^(.)(.)(.)/) {
	push @out, "ULC $map" if $local_debug ;
	# some unusual situations to handle, 

	# cl. => exit this loop for normal cl processing
	# .t => exit the loop
	# l.t or c.t => output the l or c as comment, then exit the loop
	# [_f{C].. => output the blank, fingering,directive or comment, and continue the loop

	# we have to stop one line before tablature, in case the line before the tablature needs to be included in the
	# tablature itself
	print STDERR "$1 == @{$lines}[0]\n" if $local_debug ;

	last if($1 eq "c" && $2 eq "l") ;
	last if($2 eq "t" ) ;

	if(($1 eq "c" || $1 eq "l") && $3 eq "t") {
	    push @out, format_comment_line(shift(@$lines)) ;
	    $map =~ s/.// ;
	    last ;
	}

	# in the remaining cases, output the line (properly handled), and continue the loop
	if ( $1 eq "l" or $1 eq "C") {
	    push @out, format_comment_line(shift(@$lines)) ;
	}
	elsif ( $1 eq "f" ) {
	    foreach my $fchart (decode_fingering(shift( @$lines ),1) ) {
		push( @out, $fchart);
	    }
	}
	elsif ( $1 eq "{" ) {
	    my $line = shift @$lines ;
	    push( @out, $line);

	    if($line =~ /{sot}/) {
		# output all subsequent lines until {eot} is found
		while(1) {
		    $line = shift @$lines ;
		    die "Malformed input, {sot} has no matching {eot}" if ! $line ;
		    $map =~ s/.// ;
		    push( @out, $line);
		    last if $line =~ /{eot}/ ;
		}

	    }
	}
	else {
	    push( @out, shift( @$lines ) );
	}
	$map =~ s/.// ;
    }

    push @out, "====== FINAL LOOP =====" if $local_debug ;
    # Process the lines using the map.
    while ( $map ) {
	# warn($map);
	push @out, "FL $map" if $local_debug ;
	$map =~ /(.)/ ;
	print STDERR "$1 == @{$lines}[0]\n" if $local_debug ;

	#a fingering line, simply output the directive and continue
	if ( $map =~ s/^f// ) {
	    foreach my $fchart (decode_fingering(shift( @$lines ),1) ) {
		push( @out, $fchart);
	    }
	    next ;
	}

	# Blank line - output the blank line and continue
	if ( $map =~ s/^_// ) {
	    push( @out, '');
	    shift(@$lines);
	    next ;
	}

	# A comment line, output and continue
	if ( $map =~ s/^C// ) {
	    push @out, format_comment_line(shift(@$lines)) ;
	    next ;
	}

	# Tablature
	my $in_tablature=0 ;

	# special case: chords or lyrics before tabs, keep the chords or lyrics in {sot}, which is probably
	# what the original text intended for alignment with the tablature
	if ( $map =~ s/^[cl]t/t/ ) {
	    if(! $in_tablature) {
		push( @out, "{sot}") ;
		$in_tablature=1 ;
	    }
	    push( @out, shift(@$lines));
	}

	while( $map =~ s/^t// ) {
	    if(! $in_tablature) {
		push( @out, "{sot}") ;
		$in_tablature=1 ;
	    }
	    push( @out, shift(@$lines));
	    # and Fall through.
	}

	if($in_tablature) {
	    # Text line OR chord line with following blank line or EOF -- make part of tablature
	    if ( $map =~ s/^[cl](_|$)// ) {
		push( @out, shift(@$lines));
		push( @out, '');
		shift(@$lines);
	    }

	    push( @out, "{eot}") ;
	    $in_tablature=0 ;
	    next ;
	}

	# Blank line preceding lyrics: pass.
	if ( $map =~ s/^_l/l/ ) {
	    push( @out, '');
	    shift(@$lines);
	}

	# The normal case: chords + lyrics.
	if ( $map =~ s/^cl// ) {
	    push( @out, combine( shift(@$lines), shift(@$lines), "cl" ) );
	}

	# Empty line preceding a chordless lyrics line.
	elsif ( $map =~ s/^__l// ) {
	    push( @out, '' );
	    shift( @$lines );
	    push( @out, combine( shift(@$lines), shift(@$lines), "__l" ) );
	}

	# Chordless lyrics line.
	elsif ( $map =~ s/^_l// ) {
	    push( @out, combine( shift(@$lines), shift(@$lines), "_l" ) );
	}

	# Lone directives.
	elsif ( $map =~ s/^{// ) {
	    my $line = shift @$lines ;
	    push( @out, $line);

	    if($line =~ /{sot}/) {
		# output all subsequent lines until {eot} is found
		while(1) {
		    $line = shift @$lines ;
		    die "Malformed input, {sot} has no matching {eot}" if ! $line ;
		    $map = s/.// ;
		    push( @out, $line);
		    last if $line =~ /{eot}/ ;
		}

	    }
	}

	# Lone lyrics.
	elsif ( $map =~ s/^l// ) {
	    push( @out, shift( @$lines ) );
	}

	# Lone chords.
	elsif ( $map =~ s/^c// ) {
	    push( @out, combine( shift(@$lines), '', "c" ) );
	}

	# Empty line.
	elsif ( $map =~ s/^_// ) {
	    push( @out, '' );
	    shift( @$lines );
	}

	# Can't happen.
	else {
	    croak("MAP: $map");
	}
    }
    return wantarray ? @out : \@out;
}

# Combine two lines (chords + lyrics) into lyrics with [chords].
sub combine {
    my ( $l1, $l2 ) = @_;
    my $res = "";
    while ( $l1 =~ /^(\s*)(\S+)(.*)/ ) {
	$res .= join( '',
		      substr( $l2, 0, length($1), '' ),
		      '[' . $2 . ']',
		      substr( $l2, 0, length($2), '' ) );
	$l1 = $3;
    }
    return $res.$l2;
}

################ Options and Configuration ################

=head1 COMMAND LINE OPTIONS

=over 4

=item B<--output=>I<FILE> (short: B<-o>)

Designates the name of the output file where the results are written
to. Default is standard output.

=item B<--version> (short: B<-V>)

Prints the program version and exits.

=item B<--help> (short: -h)

Prints a help message. No other output is produced.

=item B<--manual>

Prints the manual page. No other output is produced.

=item B<--ident>

Shows the program name and version.

=item B<--verbose>

Provides more verbose information of what is going on.

=back

=cut

use Getopt::Long 2.13;

# Package name.
my $my_package;
# Program name and version.
my ($my_name, $my_version);
my %configs;

sub app_setup {
    goto &ChordPro::app_setup;
    my ($appname, $appversion, %args) = @_;
    my $help = 0;               # handled locally
    my $manual = 0;             # handled locally
    my $ident = 0;              # handled locally
    my $version = 0;            # handled locally
    my $defcfg = 0;		# handled locally
    my $fincfg = 0;		# handled locally

    # Package name.
    $my_package = $args{package};
    # Program name and version.
    if ( defined $appname ) {
        ($my_name, $my_version) = ($appname, $appversion);
    }
    else {
        ($my_name, $my_version) = qw( MyProg 0.01 );
    }

    # Config files.
    %configs = %{ CP->configs };

    my $app_lc = lc("ChordPro"); # common config
    my $options =
      {
       verbose          => 0,           # verbose processing

       # Development options (not shown with -help).
       debug            => 0,           # debugging
       trace            => 0,           # trace (show process)

       # Service.
       _package         => $my_package,
       _name            => $my_name,
       _version         => $my_version,
       _stdin           => \*STDIN,
       _stdout          => \*STDOUT,
       _stderr          => \*STDERR,
       _argv            => [ @ARGV ],
      };

    # Colled command line options in a hash, for they will be needed
    # later.
    my $clo = {};

    # Sorry, layout is a bit ugly...
    if ( !GetOptions
         ($clo,
          "output|o=s",                 # Saves the output to FILE

          ### Configuration handling ###

          'config|cfg=s@',
          'noconfig|no-config',
          'sysconfig=s',
          'nosysconfig|no-sysconfig',
          'userconfig=s',
          'nouserconfig|no-userconfig',
	  'nodefaultconfigs|no-default-configs|X',
	  'define=s%',
	  'print-default-config' => \$defcfg,
	  'print-final-config'   => \$fincfg,

          ### Standard options ###

          "version|V" => \$version,     # Prints version and exits
          'ident'               => \$ident,
          'help|h|?'            => \$help,
          'manual'              => \$manual,
          'verbose|v+',
          'trace',
          'debug+',
         ) )
    {
        # GNU convention: message to STDERR upon failure.
        app_usage(\*STDERR, 2);
    }

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
	my $f = "pod/A2Crd.pod";
        unshift( @_, -input => CP->findres($f) );
        &pod2usage;
    };

    # GNU convention: message to STDOUT upon request.
    app_ident(\*STDOUT) if $ident || $help || $manual;
    if ( $manual or $help ) {
        app_usage(\*STDOUT, 0) if $help;
        $pod2usage->(VERBOSE => 2) if $manual;
    }
    app_ident(\*STDOUT, 0) if $version;

    # If the user specified a config, it must exist.
    # Otherwise, set to a default.
    for my $config ( qw(sysconfig userconfig) ) {
        for ( $clo->{$config} ) {
            if ( defined($_) ) {
                die("$_: $!\n") unless -r $_;
                next;
            }
	    # Use default.
	    next if $clo->{nodefaultconfigs};
	    next unless $configs{$config};
            $_ = $configs{$config};
            undef($_) unless -r $_;
        }
    }
    for my $config ( qw(config) ) {
        for ( $clo->{$config} ) {
            if ( defined($_) ) {
                foreach my $c ( @$_ ) {
		    my $try = $c;
		    # Check for resource names.
		    if ( ! -r $try ) {
			$try = CP->findcfg($c);
		    }
                    die("$c: $!\n") unless -r $try;
                }
                next;
            }
	    # Use default.
	    next if $clo->{nodefaultconfigs};
	    next unless $configs{$config};
            $_ = [ $configs{$config} ];
            undef($_) unless -r $_->[0];
        }
    }
    # If no config was specified, and no default is available, force no.
    for my $config ( qw(sysconfig userconfig config) ) {
        $clo->{"no$config"} = 1 unless $clo->{$config};
    }

    ####TODO: Should decode all, and remove filename exception.
    for ( keys %{ $clo->{define} } ) {
	$clo->{define}->{$_} = decode_utf8($clo->{define}->{$_});
    }

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;
    # warn(Dumper($options), "\n") if $options->{debug};

    if ( $defcfg || $fincfg ) {
	print ChordPro::Config::config_default()
	  if $defcfg;
	print ChordPro::Config::config_final()
	  if $fincfg;
	exit 0;
    }

    # Return result.
    $options;
}

sub app_ident {
    my ($fh, $exit) = @_;
    print {$fh} ("This is ",
                 $my_package
                 ? "$my_package [$my_name $my_version]"
                 : "$my_name version $my_version",
                 "\n");
    exit $exit if defined $exit;
}

sub app_usage {
    my ($fh, $exit) = @_;
    my $cmd = $0;
    $cmd .= " --a2crd" if $cmd !~ m;(?:^|\/|\\)a2crd(?:\.\w+)$;;
    print ${fh} <<EndOfUsage;
Usage: $cmd [ options ] [ file ... ]

Options:
    --output=FILE  -o   Saves the output to FILE
    --version  -V       Prints version and exits
    --help  -h          This message
    --manual            The full manual
    --ident             Show identification
    --verbose           Verbose information
EndOfUsage
    exit $exit if defined $exit;
}

=head1 AUTHOR

Johan Vromans C<< <jv at CPAN dot org > >>

=head1 SUPPORT

A2Crd is part of ChordPro (the program). Development is hosted on
GitHub, repository L<https://github.com/ChordPro/chordpro>.

Please report any bugs or feature requests to the GitHub issue tracker,
L<https://github.com/ChordPro/chordpro/issues>.

A user community discussing ChordPro can be found at
L<https://groups.google.com/forum/#!forum/chordpro>.

=head1 LICENSE

Copyright (C) 2010,2018 Johan Vromans,

This program is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
