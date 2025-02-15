#! perl

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

package ChordPro::Delegate::Grille;

=for docs

** EXPERIMENTAL ** EXPERIMENTAL ** EXPERIMENTAL ** EXPERIMENTAL **

Experimental delegate to produce a 'grille' image from a grid.

This is a magical delegate. It is not enumerated in the config but
invoked automagically when you use a 'grille' instead of 'grid'.

Differences with grid directive:

 * No grid shape argument.

 * Accepts all image arguments.

Differences with grid content:

 * Margin text = part name.

 * No trailing comments.

 * Cells are fixed size (but may get higher).

=cut

use ChordPro::Files;
use ChordPro::Utils qw(dimension maybe json_load);
use Ref::Util qw( is_arrayref );

sub DEBUG() { $::config->{debug}->{x2} }

sub grille2xo( $song, %args ) {
    my $elt = $args{elt};
    my $kv = { %{$elt->{opts}} };
    my $context = $elt->{context};
    my $ps = $song->{_ps};
    my $pr = $ps->{pr};

    if ( DEBUG > 1 ) {
	use DDP; p %args, as => "args";
	use DDP; p $elt,  as => "elt";
	use DDP; p $kv,   as => "opts";
    }

    my $data = compose( \@{$elt->{data}} );
    if ( DEBUG ) {
	use DDP; p $data;
    }

    my $txtfont = $ps->{fonts}->{grille}->{fd};
    my $size = $kv->{size} || $txtfont->{size} || 12;
    my $symfont = $ps->{fonts}->{chordfingers}->{fd};
    my $go = O_Grille->new;

    my @structure;
    if ( is_arrayref($data) ) {
	@structure = ( " " );
	$go->load( { parts => [ { part => " ", lines => $data } ] } );
    }
    else {
	$go->load($data);
	@structure = split( /([IABCDCVZ0-9]\d*'?)/, $go->structure // "" );
    }

    my $gr = Grille->new( grille => $go );

    my $xo = $gr->build( gfx     => $pr->{pdfgfx},
			 txtfont => $txtfont,
			 symfont => $symfont,
			 size    => $size,
			 color   => "red",
		       );

    # Finish.
    my $scale;
    my $design_scale;
    $kv->{scale} = dimension( $kv->{scale}//1, width => 1 );
    if ( $kv->{scale} != 1 ) {
	if ( $kv->{id} ) {
	    $design_scale = $kv->{scale};
	}
	else {
	    $scale = $kv->{scale};
	}
    }
    return
	  { type    => "image",
	    line    => $elt->{line},
	    subtype => "xform",
	    data    => $xo,
	    width   => $xo->width,
	    height  => $xo->height,
	    opts => { maybe id           => $kv->{id},
		      maybe align        => $kv->{align},
		      maybe spread       => $kv->{spread},
		      maybe scale        => $scale,
		      maybe design_scale => $design_scale,
		    } };
}

sub compose( $data ) {
    my $struct;

    my @parts;
    my $part;
    while ( @$data ) {
	my $l = shift(@$data);
	my @cells = ();
	my @lines = ();
	my $line;
	my $cell = {};
	if ( $l->{margin} ) {
	    push( @parts, $part ) if $part;
	    $part = { part => $l->{margin}->{text} };
	}
	$part //= { part => "" } unless @parts;

	while ( @{$l->{tokens}} ) {
	    my $t = shift( @{$l->{tokens}} );
	    my $c = $t->{class};
	    my @chords;
	    if ( $c eq "bar" ) {
		push( @cells, $cell ) if %$cell;
		if ( $t->{symbol} eq "||" ) {
		    if ( %$cell ) {
			$cell->{dbar_end} = 1;
			$cell = {};
		    }
		    else {
			$cell = { dbar_start => 1 };
		    }
		}
		elsif ( $t->{symbol} eq "|." ) {
		    if ( %$cell ) {
			$cell->{end_bar} = 1;
			$cell = {};
		    }
		    else {
			$cell = {};
		    }
		}
		elsif ( $t->{symbol} eq "|:" ) {
		    $cell = { repeat_start => 1 };
		}
		elsif ( $t->{symbol} eq ":|" ) {
		    if ( %$cell ) {
			$cell->{repeat_end} = 1;
			$cell = {};
		    }
		    else {
			$cell = {};
		    }
		}
		else {
		    $cell = {};
		}
	    }
	    elsif ( $c eq "chord" ) {
		push( @{$cell->{chords}}, $t->{chord}->chord_display );
	    }
	    elsif ( $c eq "space" ) {
		push( @{$cell->{chords}}, "." );
	    }
	    elsif ( $c eq "repeat1" ) {
		push( @{$cell->{chords}}, "R" );
	    }
	    elsif ( $c eq "repeat2" ) {
		$cell->{chords} = [ "R2" ];
		shift( @{$l->{tokens}} )
		  while $l->{tokens}->[0] eq ".";
	    }
	}
	push( @cells, $cell )
	  if %$cell && ( @cells ? $cells[-1] ne "R2" : 1 );

	push( @lines, { cells => [@cells] } );

	push( @{$part->{lines}}, @lines );
    }
    push( @parts, $part ) if $part;
    return { parts => \@parts };
}

# This is mainly for testing/development.

sub json2xo( $song, %args ) {
    my $elt = $args{elt};
    my $ctl = { %{ $::config->{delegates}->{$elt->{context}} } };
    my $kv = { %{$elt->{opts}} };
    my $context = $elt->{context};
    my $data = $elt->{data};
    my $ps = $song->{_ps};
    my $pr = $ps->{pr};

    # Default alignment.
    $kv->{align} //= $ctl->{align};

    if ( DEBUG > 1 ) {
	use DDP; p %args, as => "args";
	use DDP; p $elt,  as => "elt";
	use DDP; p $kv,   as => "opts";
	use DDP; p $ctl,  as => "ctl";
    }

    $data = json_load( join( "\n", @$data ), "grille" );

    my $txtfont = $ps->{fonts}->{grille}->{fd};
    my $fz = $kv->{size} || $txtfont->{size} || 30;
    my $symfont = $ps->{fonts}->{chordfingers}->{fd};
    my $go = O_Grille->new;

    my @structure;
    if ( is_arrayref($data) ) {
	@structure = ( " " );
	$go->load( { parts => [ { part => " ", lines => $data } ] } );
    }
    else {
	$go->load($data);
	@structure = split( /([IABCDCVZ0-9]\d*'?)/, $go->structure // "" );
    }

    my $do = DrawingObject->new( gfx     => $pr->{pdfgfx},
				 txtfont => $txtfont,
				 symfont => $symfont,
				 size    => $fz,
				 color   => "blue",
			       );

    my $gr = Grille->new( grille => $go );

    my $xo = $gr->build( do      => $do,
		       );

    # Finish.
    my $scale;
    my $design_scale;
    $kv->{scale} = dimension( $kv->{scale}//1, width => 1 );
    if ( $kv->{scale} != 1 ) {
	if ( $kv->{id} ) {
	    $design_scale = $kv->{scale};
	}
	else {
	    $scale = $kv->{scale};
	}
    }
    return
	  { type    => $ctl->{type}, # image
	    line    => $elt->{line},
	    subtype => "xform",
	    data    => $xo,
	    width   => $xo->width,
	    height  => $xo->height,
	    opts => { maybe id           => $kv->{id},
		      maybe align        => $kv->{align},
		      maybe spread       => $kv->{spread},
		      maybe scale        => $scale,
		      maybe design_scale => $design_scale,
		    } };
}

# Pre-scan.
sub options( $data ) { {} }

use Object::Pad;

################

use Class::JSON_Object;

class O_Grille       :does(Class::JSON_Object) {
    field $cells     :Optional;
    field $structure :Optional;
    field @parts     :Class(O_Grille_Part);
}

class O_Grille_Part  :does(Class::JSON_Object) {
    field $part;
    field @lines     :Class(O_Grille_Line);
}

class O_Grille_Line  :does(Class::JSON_Object) {
    field @cells     :Class(O_Grille_Cell);

    method expand_rests {
	my @pl = ();
	for ( @cells ) {
	    push( @pl, $_ );
	    if ( @{$_->chords} == 1 && $_->chords->[0] eq 'R2' ) {
		$_->chords->[0] = ' R2';
		push( @pl, O_Grille_EmptyCell->new );
	    }
	}
	@cells = @pl;
    }
}

class O_Grille_Cell  :does(Class::JSON_Object) {
    field @chords;
    field $repeat_start	:Optional = 0;
    field $repeat_end	:Optional = 0;
    field $coda		:Optional = 0;
    field $segno	:Optional = 0;
    field $end_bar	:Optional = 0;
    field $dbar_start	:Optional = 0;
    field $dbar_end	:Optional = 0;

    method is_dot(@c) {
	for ( @c ) {
	    return 0 unless $_ =~ /^(?:\s+|\.|\/)$/;
	}
	return 1;
    }
}

class O_Grille_EmptyCell  :isa(O_Grille_Cell) {
    field $chords = [" "];
}

################

class Grille;

sub DEBUG() { $::config->{debug}->{x2} }
use Ref::Util qw( is_arrayref );

field $grille	 :param;	# the grille
field $cw	 :param = 0;	# cell width
field $ch	 :param = 0;	# cell height
field $gw	 :param = 0;	# number of cells

# These are initialized by 'build' method.
field $do;			# drawing object
field $size;
field $txtfont;
field $symfont;
field $color;
field $fontsize;

ADJUST {
    $gw ||= $grille->cells;
}

method grille_cell( $xc, $yc, $cell, %args ) {

    DEBUG &&
      warn( sprintf( "cell %s, x = %6.2f, y = %6.2f, ".
		     "cw = %.2f, ch = %.2f, border = 0b%04b\n",
		     join(':',@args{qw(part line cell)}),
		     $xc, $yc, $cw, $ch, $args{border} ) );

    for ( $args{border} ) {
	last unless $_;
	# Draw cell boundaries.
	$do->move( $xc+$cw, $yc-$ch );
	if ( $_ & 0b0100 ) {		# Bottom
	    $do->hline($xc);
	}
	else {
	    $do->move( $xc, $yc-$ch );
	}
	if ( $_ & 0b0010 ) {		# Left
	    $do->vline($yc);
	}
	else {
	    $do->move( $xc, $yc );
	}
	if ( $_ & 0b1000 ) {		# Top
	    $do->hline($xc+$cw);
	}
	else {
	    $do->move( $xc+$cw, $yc );
	}
	if ( $_ & 0b1111 ) {		# all
	    $do->close;
	}
	elsif ( $_ & 0b0001 ) {		# Right
	    $do->vline($yc-$ch);
	}
	$do->stroke;
	if ( $cell->dbar_start ) {
	    my $d = $size / 8;
	    $do->move( $xc+$d, $yc-$ch )->vline($yc)->stroke;
	}
	if ( $cell->repeat_start ) {
	    my $d = $size / 16;
	    $do->set_symfont;
	    $do->set_markup("\x{27}");
	    my ( $w, $h ) = $do->get_size;
	    $do->show( $xc+$d, $yc -$ch/2+ $h/2 );
	}
	if ( $cell->repeat_end ) {
	    my $d = $size / 16;
	    $do->set_symfont;
	    $do->set_markup("\x{27}");
	    my ( $w, $h ) = $do->get_size;
	    $do->show( $xc+$cw-$w-$d, $yc -$ch/2+ $h/2 );
	}
	if ( $cell->dbar_end ) {
	    my $d = $size / 8;
	    $do->move( $xc+$cw-$d, $yc-$ch )->vline($yc)->stroke;
	}
	if ( $cell->end_bar ) {
	    my $d = $size / 8;
	    $do->rectangle( $xc+$cw-$d, $yc-$ch, $xc+$cw, $yc )->fill;
	}
    }

    my $c = $cell->chords;
    return unless $c =~ /\S/;	# nothing to do

    # Unified view.
    $c = [ $c ] unless is_arrayref($c);

    my $nc = @$c;
    if ( $nc == 4 && $cell->is_dot(@$c[1..3]) ) {
	$nc = 1;
    }
    elsif ( $nc == 3 && $cell->is_dot(@$c[1..2]) ) {
	$nc = 1;
    }
    elsif ( $nc == 2 && $cell->is_dot($c->[1]) ) {
	$nc = 1;
    }
    elsif ( $nc == 4 && $cell->is_dot(@$c[1,3]) ) {
	$nc = 2;
	$c->[1] = $c->[2];
    }

    my $fontsize = $size;

    if ( $nc == 1 ) {
	$c = $c->[0];
	if ( $c eq ' R2' ) {
	    $do->set_symfont($fontsize);
	    $do->set_markup("\x{28}"); # ·//.
	    my ($w, $h) = $do->get_size;
	    $do->show( $xc+$cw-$w/2, $yc-$ch/2+$h/2 );
	}
	elsif ( $c eq 'R' ) {
	    $do->set_symfont($fontsize);
	    $do->set_markup("\x{29}");
	    my ($w, $h) = $do->get_size;
	    $do->show( $xc+$cw/2-$w/2, $yc-$ch/2+$h/2 );
	}
	else {
	    die("Unexpanded R2 in cell $args{part}:$args{line}:$args{cell}\n")
	      if $c eq 'R2';
	    $self->fit_cell( $xc, $yc, $c, 0, 0 );
	}
    }

    elsif ( $nc == 2 ) { # LT BR
	$do->move( $xc, $yc-$ch );
	$do->line( $xc+$cw, $yc );
	$do->stroke;

	# Note that [[A B][C D]] yields the same as [A B C D].
	if ( is_arrayref($c->[0]) ) { # L T
	    $do->move( $xc+$cw/2, $yc-$ch/2 );
	    $do->line( $xc, $yc );
	    $do->stroke;
	    $self->fit_cell( $xc, $yc, $c->[0][0],  0,  1 );
	    $self->fit_cell( $xc, $yc, $c->[0][1],  1,  0 );
	}
	else {			   # LT
	    $self->fit_cell( $xc, $yc, $c->[0],  1,  1 );
	}
	if ( is_arrayref($c->[1]) ) { # B R
	    $do->move( $xc+$cw/2, $yc-$ch/2 );
	    $do->line( $xc+$cw, $yc-$ch );
	    $do->stroke;
	    $self->fit_cell( $xc, $yc, $c->[1][0], -1,  0 );
	    $self->fit_cell( $xc, $yc, $c->[1][1],  0, -1 );
	}
	else {		           # BR
	    $self->fit_cell( $xc, $yc, $c->[1],  -1, -1 );
	}
    }

    elsif ( $nc == 3 ) { # BL T BR
	unless ( $cell->is_dot(@$c[1,2]) ) {
	    $do->move( $xc+$cw/2, $yc-$ch/1.5 );
	    $do->line( $xc+$cw/2, $yc-$ch );
	    $do->stroke;
	}
	unless ( $cell->is_dot($c->[0]) ) {
	    if ( $cell->is_dot($c->[1]) ) {
		$self->fit_cell( $xc, $yc, $c->[0],  1,  1 );
	    }
	    else {
		$self->fit_cell( $xc, $yc, $c->[0],  -1,  1 );
	    }
	}
	unless ( $cell->is_dot($c->[1]) ) {
	    $do->move( $xc+$cw/2, $yc-$ch/1.5 );
	    $do->line( $xc, $yc );
	    $do->stroke;
	    if ( $cell->is_dot($c->[2]) ) {
		$self->fit_cell( $xc, $yc, $c->[1],   1,  -1 );
	    }
	    else {
		$self->fit_cell( $xc, $yc, $c->[1],  1,  0,
				 scale => 0.6);
	    }
	}
	unless ( $cell->is_dot($c->[2]) ) {
	    $do->move( $xc+$cw/2, $yc-$ch/1.5 );
	    $do->line( $xc+$cw, $yc );
	    $do->stroke;
	    $self->fit_cell( $xc, $yc, $c->[2], -1,  -1 );
	}
    }

    elsif ( $nc == 4 ) { # LTBR
	my $drawn = 0;
	unless ( $cell->is_dot($c->[0]) ) {
#	    $do->move( $xc+$cw/2, $yc-$ch/2 );
#	    $do->line( $xc, $yc );
#	    $do->move( $xc+$cw/2, $yc-$ch/2 );
#	    $do->line( $xc, $yc-$ch );
#	    $do->stroke;
	    $drawn |= 0x1001;
	    $self->fit_cell( $xc, $yc, $c->[0],  0,  1 );
	}
	unless ( $cell->is_dot($c->[1]) ) {
	    unless ( $drawn & 0b100 ) {
		$do->move( $xc+$cw/2, $yc-$ch/2 );
		$do->line( $xc, $yc );
	    }
	    $do->move( $xc+$cw/2, $yc-$ch/2 );
	    $do->line( $xc+$cw, $yc );
	    $do->stroke;
	    $drawn |= 0x1100;
	    $self->fit_cell( $xc, $yc, $c->[1],  1,  0 );
	}
	unless ( $cell->is_dot($c->[2]) ) {
	    $do->move( $xc+$cw/2, $yc-$ch/2 );
	    $do->line( $xc, $yc-$ch );
	    unless ( $drawn & 0b0100 ) {
		$do->move( $xc+$cw/2, $yc-$ch/2 );
		$do->line( $xc+$cw, $yc-$ch );
	    }
	    $do->stroke;
	    $drawn |= 0x0011;
	    $self->fit_cell( $xc, $yc, $c->[2], -1,  0 );
	}
	unless ( $cell->is_dot($c->[3]) ) {
	    unless ( $drawn & 0b0100 ) {
		$do->move( $xc+$cw/2, $yc-$ch/2 );
		$do->line( $xc+$cw, $yc );
	    }
	    unless ( $drawn & 0b0010 ) {
		$do->move( $xc+$cw/2, $yc-$ch/2 );
		$do->line( $xc+$cw, $yc-$ch );
	    }
	    $do->stroke unless $drawn & 0b0110;
	    $self->fit_cell( $xc, $yc, $c->[3], 0, -1 );
	}
    }
}

method fit_cell( $xc, $yc, $c, $top=0, $left=0, %args ) {
    my $scale    = $args{scale} || $top ? $left ? 0.7 : 0.45 : $left ? 0.45 : 1;
    my $sz = $size * $scale;

    my $c2 = "";
    if ( is_arrayref($c) && $left && @$c == 2 ) {
	( $c, $c2 ) = @$c;
    }
    elsif ( is_arrayref($c) ) {
	$c = join("~", @$c );
    }
    $do->set_txtfont($sz);
    $c =~ s/~/ /g;
    $do->set_markup($c);
    # my $ink = $do->get_extents;
    # my ($w, $h) = @{$ink}{qw(width height)};
    my ($w, $h) = $do->get_size;
    $xc += 4;
    my $xx = ( $c2 eq "" ? $cw : 0.55*$cw ) - 8;
    my $cw = $cw - 8;
    if ( $w > $scale * $xx ) {
	$_ = ($_ * $scale * $xx) / $w for $sz, $h, $w;
	$do->set_font_size($sz);
	$do->set_markup($c);
	DEBUG && warn("\"$c\" \@$sz\n");
    }
    $do->show( $left > 0
	       ? $xc
	       : $left < 0
	         ? $xc+$cw-$w
	         : $xc+$cw/2-$w/2,
	       $top > 0
	       ? $yc
	       : $top < 0
	         ? $yc-$ch+$h
	         : $yc-$ch/2+( $c2 eq "" ? $h/2 : $h/1.2 ) );

    if ( $c2 ne "" ) {
	$do->set_markup($c2);
	$do->show( $left > 0
		   ? $xc
		   : $left < 0
		   ? $xc+$cw-$w
		   : $xc+$cw/2-$w/2,
		   $top > 0
		   ? $yc
		   : $top < 0
		   ? $yc-$ch+$h
		   : $yc-$ch/2+$h/5 );
    }
}

method grille_line( $xl, $yl, $pl, %args ) {

    # warn("line $args{line}, x = $xl, y = $yl\n");

    $pl = $pl->cells;
    warn("Line exceeds width\n")
      if @$pl > $gw;
    my $lcc = 0;		# line cell count

    # Pre-scan for height.
    $ch = 0.75 *$cw;
    for my $c ( @$pl ) {
	if ( is_arrayref($c->chords) ) {
	    for ( @{$c->chords} ) {
		if ( is_arrayref($_) ) {
		    $ch = $cw;
		    last;
		}
	    }
	}
    }
    # warn("pw = $pw, gw = $gw, cw = $cw, ch = $ch\n" );

    my $xc = $xl;
    my $yc = $yl;

    my $nc;
    while ( @$pl ) {	# CELL
	my $c = shift(@$pl);
	$lcc++;
	# p $c, as => "Part $part, line $lcc, cell $clc";
	$self->grille_cell( $xc, $yc, $c,
			    %args, border => @$pl ? 0b1111 : 0b1110,
			    cell => $lcc,
			  );
	$xc += $cw;
    }

    DEBUG &&
      warn( sprintf( "line, x = %.2f, y = %.2f, w = %.2f, h = %.2f\n",
		     $xl, $yl, $xc - $xl, $ch ) );

    wantarray ? ( $xc - $xl, $ch ) : $ch;
}

method grille_part( $xp, $yp, $p, %args ) {

    my $part = $p->part // " ";
    # warn("part: $part, x = $xp, y = $yp\n");

    $_->expand_rests for @{$p->lines};

    # Establish total width of the grid.
    # If not specified, derive from the first A part.
    if ( !$gw && $part =~ /^(A\d*| )$/ ) {
	for ( @{$p->lines->[0]->cells } ) {
	    $gw++;
	}
	DEBUG && warn("Grid cells = $gw\n");
    }

    $cw ||= 2 * $size;

    # Convenience.
    if ( $part eq 'I' ) {
	$part = 'Intro';
    }
    elsif ( $part eq 'Z' ) {
	$part = 'Coda';
    }

    # Show part.
    my $wp = 0;
    if ( $part ne ' ' ) {
	# p $p, as => "Part $part";
	$do->set_txtfont($size);
	$do->set_markup($part." ");
	( $wp, my $h ) = $do->get_size;
	$do->show( $xp-$wp, $yp );
    }

    my $plc = 0;		# part line count
    my $xl = $xp;
    my $yl = $yp;

    for my $pl ( @{$p->lines} ) {	# PARTS LINE
	$plc++;

	my ( $w, $h ) = $self->grille_line( $xl, $yl, $pl,
					    line => $plc, %args );

	$yl -= $h;
    }

    DEBUG &&
      warn( sprintf( "part %s, x = %.2f, y = %.2f, w = %.2f, h = %.2f\n",
		     $part, $xp, $yp, $wp+$gw*$cw,, $yp - $yl ) );

    wantarray ? ( $gw*$cw, $yp - $yl, $wp ) : $yp - $yl;
}

method build( %args ) {

    my $missing = "";
    for ( qw( gfx symfont txtfont size ) ) {
	$missing .= "$_ " unless defined $args{$_};
    }
    die("Missing arguments to Grille::build: $missing\n") if $missing;

    my $gfx  = $args{gfx};
    $symfont = $args{symfont};
    $txtfont = $args{txtfont};
    $color   = $args{color}   if defined $args{color};
    $size    = $args{size};

    $do = DrawingObject->new( gfx     => $gfx,
			      txtfont => $txtfont,
			      symfont => $symfont,
			      size    => $size,
			      color   => $color // "cyan",
			    );
    $fontsize = $size;

    my $xp = 0;
    my $yp = 0;
    my %did;
    $gw = $grille->cells;
    my $xo = $do->newxo;
    my $lw = $do->lw;
    my $i;

    for my $p ( @{$grille->parts} ) {
	$do->newxo;
	my $part = $p->part;
	next unless $part;
	next if $did{$part}++;
	( my $w, my $h, $i ) =
	  $self->grille_part( 0, 0, $p, %args, part => $part );
	$do->bboxlw( -$i, 0, $w+$i, -$h );
	$xo->object( $do->gfx, $xp, $yp, 1 );
	$yp -= $h + 1 + int($cw/10);
    }

    $xo->bbox( -$lw/2-$i, $yp+$lw/2, $gw*$cw+$i+$lw/2, $lw/2 );
    return $xo;
}

################ Draw Object ################

class DrawingObject;

field $gfx	:accessor :param;
field $size     :accessor :param;
field $txtfont  :accessor :param;
field $symfont  :accessor :param;
field $color    :accessor :param = "lime";
field $lw       :accessor :param = undef;

field $pdf	:accessor;
field $layout;

ADJUST {
    $pdf = $gfx->{' apipage'}->{' api'};
    $lw //= $size / 50;
};

method newxo() {
    $gfx = $pdf->xo_form;
    $gfx->fill_color($color);
    $gfx->stroke_color($color);
    $gfx->line_width($lw);
    $gfx;
}

# Drawing methods. Most of them return self for call chaining.
method move( $x, $y ) {
    $gfx->move( $x, $y );
    $self;
}
method line( $x, $y ) {
    $gfx->line( $x, $y );
    $self;
}
method vline( $y ) {
    $gfx->vline( $y );
    $self;
}
method hline( $x ) {
    $gfx->hline( $x );
    $self;
}
method close() {
    $gfx->close;
    $self;
}
method fill() {
    $gfx->close;
    $self;
}
method stroke() {
    $gfx->stroke;
    $self;
}
method rectangle( $x1,$y1, $x2,$y2 ) {
    $gfx->rectangle( $x1,$y1, $x2,$y2 );
    $self;
}
method bboxlw( $x1,$y1, $x2,$y2 ) {
    my $lw2 = $lw/2;
    $gfx->bbox( $x1-$lw2, $y1+$lw2, $x2+$lw2, $y2-$lw2 );
    $self;
}

# Text methods.
method set_txtfont( $sz = undef ) {
    $layout //= Text::Layout->new($pdf);
    $layout->set_font_description($txtfont);
    $layout->set_font_size( $sz || $size );
}
method set_symfont( $sz = undef ) {
    $layout //= Text::Layout->new($pdf);
    $layout->set_font_description($symfont);
    $layout->set_font_size( $sz || $size );
}
method set_font_size($sz) {
    $layout->set_font_size($sz);
    $self;
}
method set_markup($t) {
    $layout //= Text::Layout->new($pdf);
    $layout->set_markup("<span color='$color'>$t</span>");
#    $layout->set_markup($t);
    $self;
}
method get_size() {
    $layout->get_size();
}
method show( $x, $y ) {
    $gfx->textstart;
    $layout->show( $x, $y, $gfx );
    $gfx->textend;
    $self;
}

1;
