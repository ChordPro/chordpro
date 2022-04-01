#!/usr/bin/perl

package App::Music::ChordPro::Output::LaTeX;
# Author: Johannes Rumpf / 2022
# relevant Latex packages - still using the template module would make it possible 
# to create any form of textual output. 
# delivered example will work with songs-package - any other package needed to be 
# evaluated / tested. But should work
# http://songs.sourceforge.net/songsdoc/songs.html
# https://www.ctan.org/pkg/songs
# https://www.ctan.org/pkg/guitar
# https://www.ctan.org/pkg/songbook
# https://www.ctan.org/pkg/gchords

use strict;
use warnings;
use App::Music::ChordPro::Output::Common;
use Template;
use LaTeX::Encode;

our $CHORDPRO_LIBRARY;

my $single_space = 0;		# suppress chords line when empty
my $lyrics_only = 0;		# suppress all chords lines
my %line_routines = ();
my $gtemplate;
my $gcfg;

my $newpage_tag = "[% newpage_tag %]" ;
my $emptyline_tag = "[% emptyline_tag %]";
my $columnbreak_tag = "[% columnbreak_tag %]";
my $beginchorus_tag = "[% beginchorus_tag %]";
my $endchorus_tag = "[% endchorus_tag %]";
my $beginverse_tag = "[% beginverse_tag %]";
my $endverse_tag = "[% endverse_tag %]";
my $beginabc_tag = "[% beginabc_tag %]";
my $endabc_tag = "[% endabc_tag %]";
my $beginlilypond_tag = "[% beginlilypond_tag %]";
my $endlilypond_tag = "[% endlilypond_tag %]";
my $begingrid_tag = "[% begingrid_tag %]";
my $endgrid_tag = "[% endgrid_tag %]";
my $begintab_tag = "[% begintab_tag %]";
my $endtab_tag = "[% endtab_tag %]";
my $gchordstart_tag = "[% gchordstart_tag %]";
my $gchordend_tag = "[% gchordend_tag %]"; 
my $chorded_line = "[% chorded_line %]";
my $unchorded_line = "[% unchorded_line %]";
my $start_spaces_songline = "[% start_spaces_songline %]";
my $eol = "[% eol %]";

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @songs;
    $gcfg = $::config->{latex};
    $gtemplate = Template->new({
        INCLUDE_PATH => [@{$gcfg->{template_include_path}}, ::rsc_or_file("res/templates/"), $CHORDPRO_LIBRARY],
        INTERPOLATE  => 1,
    }) || die "$Template::ERROR\n";

    foreach my $song ( @{$sb->{songs}} ) {
    	push( @songs, generate_song($song) );
    }
    my $songbook = '';
    my %vars = ();
    $vars{songs} = [@songs] ;
    $gtemplate->process($gcfg->{templates}->{songbook}, \%vars, $::options->{output} )
        || die $gtemplate->error();
 # i like it more to handle output through template module - but its possible to result it as array.
 #   return split(/\n/, $songbook); 
    $::options->{output} = '-';
    return [];
}

# some not implemented feature is requested. will be removed.
sub line_default {
    my ( $lineobject, $ref_lineobjects ) = @_;
    return "";
}
$line_routines{line_default} = \&line_default;

sub get_firstphrase{
   my ( $elts ) = @_; # reference to array
   my $line = "";
   foreach my $elt (@{ $elts }) {
       if($elt->{type} eq 'songline'){
          foreach my $phrase (@{$elt->{phrases}}){
                $line .=  $phrase;
            }
        return my_latex_encode($line);
       }
   }
}

sub line_songline {
    my ( $lineobject ) = @_;
    my $index = 0;
    my $line = "";
    my $chord = "";
    my $has_chord = 0;
    foreach my $phrase (@{$lineobject->{phrases}}){
        if(defined $lineobject->{chords}){
            if (@{$lineobject->{chords}}[$index] ne '' ){
                $chord = $gchordstart_tag.@{$lineobject->{chords}}[$index] .$gchordend_tag; #songbook format \\[chord]
                $has_chord = 1;
        }}
        $line .=  $chord . latex_encode($phrase);
        $index += 1; 
        $chord = "";
    }

	my $empty = $line;
    my $textline = $line;
    my $nbsp = $start_spaces_songline; #unicode for nbsp sign # start_spaces_songline
    if($empty =~ /^\s+/){ # starts with spaces
	    $empty =~ s/^(\s+).*$/$1/; # not the elegant solution - but working - replace all spaces in the beginning of a line
        my $replaces = $empty;  #with a nbsp symbol as the intend tend to be intentional
        $replaces =~ s/\s+/$nbsp/g;
        $textline =~ s/$empty/$replaces/;
    }
    $line = $textline;
    if ($has_chord) { $line = $chorded_line . $line; } else { $line = $unchorded_line . $line; }
    return $line.$eol;
}
$line_routines{line_songline} = \&line_songline;

sub line_newpage {
    my ( $lineobject ) = @_;
    return $newpage_tag;
}
$line_routines{line_newpage} = \&line_newpage;

sub line_empty {
    my ( $lineobject ) = @_;
    return $emptyline_tag;
}
$line_routines{line_empty} = \&line_empty;

sub line_comment {
    my ( $lineobject ) = @_; # Template for comment?
    my $vars = {
        comment => latex_encode($lineobject->{text})
    };
    my $comment = '';
    $gtemplate->process($gcfg->{templates}->{comment}, $vars, \$comment) || die $gtemplate->error();
    return $comment ;
}
$line_routines{line_comment} = \&line_comment;

sub line_comment_italic {
    my ( $lineobject ) = @_; # Template for comment?
    my $vars = {
        comment => "\\textit{". latex_encode($lineobject->{text}) ."}"
    };
    my $comment = '';
    $gtemplate->process($gcfg->{templates}->{comment}, $vars, \$comment) || die $gtemplate->error();
    return $comment;
}
$line_routines{line_comment_italic} = \&line_comment_italic;

sub line_image {
    my ( $lineobject ) = @_;
    my $image = '';
    $gtemplate->process($gcfg->{templates}->{image}, $lineobject, \$image)|| die $gtemplate->error();
    return $image;
}
$line_routines{line_image} = \&line_image;

sub line_colb {
    my ( $lineobject ) = @_; # Template for comment?
    return $columnbreak_tag;
}
$line_routines{line_colb} = \&line_colb;

sub line_chorus {
    my ( $lineobject ) = @_; #
   return $beginchorus_tag ."\n". 
          elt_handler($lineobject->{body}) . 
          $endchorus_tag . "\n";
}
$line_routines{line_chorus} = \&line_chorus;

sub line_verse {
    my ( $lineobject ) = @_; #
   return $beginverse_tag ."\n". 
        elt_handler($lineobject->{body}) 
        .$endverse_tag ."\n";
}
$line_routines{line_verse} = \&line_verse;

sub line_set { # potential comments in fe. Chorus or verse or .... complicated handling - potential contextsensitiv.
    my ( $lineobject ) = @_;
    return '';
}
$line_routines{line_set} = \&line_set;

sub line_tabline {
    my ( $lineobject ) = @_;
    return $lineobject->{text}.$eol;
}
$line_routines{line_tabline} = \&line_tabline;

sub line_tab {
    my ( $lineobject ) = @_;
    return $begintab_tag."\n". 
           elt_handler($lineobject->{body}) .
           $endtab_tag ."\n";
}
$line_routines{line_tab} = \&line_tab;

sub line_grid {
    my ( $lineobject ) = @_;
    return $begingrid_tag."\n".
           elt_handler($lineobject->{body}) 
           .$endgrid_tag ."\n";
}
$line_routines{line_grid} = \&line_grid;

sub line_gridline {
    my ( $lineobject ) = @_;
    my $line = '';
    if(defined $lineobject->{margin}){
        $line .= $lineobject->{margin}->{text} . "\t";
    }
    else {
        $line .= "\t\t";
    }
    foreach my $token (@{ $lineobject->{tokens} }){
        if ($token->{class} eq 'chord'){
            $line .= $token->{chord};
        }
        else {
           $line .= $token->{symbol};
        }
    }
    if(defined $lineobject->{comment}){
        $line .= $lineobject->{comment}->{text};
    }
    return $line. $eol;
}
$line_routines{line_gridline} = \&line_gridline;

sub elt_handler {
    my ( $elts ) = @_; # reference to array
    my $cref; #command reference to subroutine

    my $lines = "";
    foreach my $elt (@{ $elts }) {
    # Gang of Four-Style - sort of command pattern 
    my $sub_type = "line_".$elt->{type}; # build command "line_<linetype>"
  #  if (exists &{$sub_type}) { #check if sub is implemented / maybe hash is -would be- faster...
     if (defined $line_routines{$sub_type}) {
        $cref = $line_routines{$sub_type}; #\&$sub_type; # due to use strict - we need to get an reference to the command 
        $lines .= &$cref($elt); # call line with actual line-object
    }
    else {
        $lines .= line_default($elt); # default = empty line
        
    }
  }
  return $lines;
}

sub my_latex_encode{
    my ( $val ) = @_;
    if ((ref($val) eq 'SCALAR') or ( ref($val) eq '' )) { return latex_encode($val); }
    if (ref($val) eq 'ARRAY'){
        my @array_return;
        foreach my $array_val (@{$val}){
            push(@array_return, my_latex_encode($array_val));
        }
        return \@array_return;
    }
    if (ref($val) eq 'HASH'){
        my %hash_return = ();
        foreach my $hash_key (keys( % {$val } )){
            $hash_return{$hash_key} = my_latex_encode( $val->{$hash_key} );
        }
        return \%hash_return;
    }
}

sub generate_song {
    my ( $s ) = @_;
    my %gtemplatatevar = ();

    if ( defined $s->{meta} ) {
		$gtemplatatevar{meta} = my_latex_encode($s->{meta});
    }
    $gtemplatatevar{meta}->{index} = get_firstphrase($s->{body}); # needs unstructured data - .. redesign?
    
  # asume songline a verse when no context is applied. # check https://github.com/ChordPro/chordpro/pull/211
  # Songbook needs to have a verse otherwise the chords-makro is not in the right context
	foreach my $item ( @{ $s->{body} } ) {
	if ( $item->{type} eq "songline" &&  $item->{context} eq '' ){
		$item->{context} = 'verse';
	}} # end of pull -- 
    $s->structurize; # removes empty lines 


    for ( $s->{title} // "Untitled" ) {
		$gtemplatatevar{title} = my_latex_encode($s->{title});
    }
    if ( defined $s->{subtitle} ) {
		$gtemplatatevar{subtitle} = my_latex_encode($s->{subtitle});
    }


    if ( defined $s->{chords}->{chords} ) {
       my @chords;
        foreach my $mchord (@{$s->{chords}->{chords}}){
            # replace -1 with 'x' - alternative '-'
            my $frets = join("", map { if($_ eq '-1'){ $_ = 'X'; } +"$_"} @{$s->{chordsinfo}->{$mchord}->{frets}});
            my %chorddef = (
                "chord" => $mchord,
                "frets" => $frets,
                "base" => $s->{chordsinfo}->{$mchord}->{base},
                "fingers" => $s->{chordsinfo}->{$mchord}->{fingers});
            push(@chords, \%chorddef);
        }
        $gtemplatatevar{chords} = \@chords;
    }

    $gtemplatatevar{songlines} = elt_handler($s->{body});
    
   # my $song = '';
   # $gtemplate->process($gcfg->{template_song}, \%gtemplatatevar, \$song) || die $gtemplate->error();
    
    return \%gtemplatatevar;
    #$song;
}

1;

#not implemented line-types
# sub line_rechorus {
#     my ( $lineobject ) = @_;
# }

# sub line_control {
#     my ( $lineobject ) = @_;
# }
