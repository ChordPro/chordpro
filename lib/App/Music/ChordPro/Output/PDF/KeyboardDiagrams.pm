#! perl

use strict;

package App::Music::ChordPro::Output::PDF::KeyboardDiagrams;

use App::Music::ChordPro::Chords;

sub new {
    my ( $pkg, %init ) = @_;
    bless { %init || () } => $pkg;
}

# The vertical space the diagram requires.
sub vsp0 {
    my ( $self, $elt, $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    my $kh = $ctl->{height};
    my $lw  = ($ctl->{linewidth} || 0.10) * $kw;
    $ps->{fonts}->{diagram}->{size} * 1.2 + $kh + $lw;
}

# The advance height.
sub vsp1 {
    my ( $self, $elt, $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    $ctl->{vspace} * $ctl->{height};
}

# The vertical space the diagram requires, including advance height.
sub vsp {
    my ( $self, $elt, $ps ) = @_;
    $self->vsp0( $elt, $ps ) + $self->vsp1( $elt, $ps );
}

# The horizontal space the diagram requires.
sub hsp0 {
    my ( $self, $elt, $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    my $kh = $ctl->{height};
    my $lw  = ($ctl->{linewidth} || 0.10) * $kw;
    $lw + $ctl->{keys} * $kw;
}

# The advance width.
sub hsp1 {
    my ( $self, $elt, $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    $ctl->{hspace} * $kw;
}

# The horizontal space the diagram requires, including advance width.
sub hsp {
    my ( $self, $elt, $ps ) = @_;
    $self->hsp0( $elt, $ps ) + $self->hsp1( $elt, $ps );
}

my @Roman = qw( I II III IV V VI VI VII VIII IX X XI XII );

sub font_bl {
    goto &App::Music::ChordPro::Output::PDF::font_bl;
}

# The actual draw method.
sub draw {
    my ( $self, $info, $x, $y, $ps ) = @_;
    return unless $info;
    my $x0 = $x;

    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    my $kh = $ctl->{height};
    my $dot = 0.70 * $kw;
    my $lw  = ($ctl->{linewidth} || 0.10) * $kw;
    my $keys = $ctl->{keys};
    my $col = $ctl->{pressed} // "red";
    my $pr = $ps->{pr};

    my $w = $lw + $kw * $keys;
    my $h = $kh + $lw;

    # Draw font name.
    my $font = $ps->{fonts}->{diagram};
    $pr->setfont($font);
    my $name = App::Music::ChordPro::Output::PDF::chord_display($info);
    $name .= "*"
      unless $info->{origin} ne "user"
	|| $::config->{kbdiagrams}->{show} eq "user";
    $pr->text( $name, $x + ($w - $pr->strwidth($name))/2, $y - font_bl($font) );
    $y -= $font->{size} * 1.2 + $lw;

    my $v = $ctl->{height};
    my $h = $kh;

    # Draw the grid.
    my $xo = grid_xo($ps);
    $pr->{pdfgfx}->formimage( $xo, $x, $y-$v, 1 );

    my @keys = @{strings2keys($info)};

    my %k =  (  0 => [0,"L"],
		1 => [0,"B"],
		2 => [1,"M"],
		3 => [1,"B"],
		4 => [2,"R"],
		5 => [3,"L"],
		6 => [3,"B"],
		7 => [4,"M"],
		8 => [4,"B"],
		9 => [5,"M"],
	       10 => [5,"B"],
	       11 => [6,"R"] );

    my $kk = ( $keys % 7 == 0 ) ? 12 * int( $keys / 7 )
      : $keys == 10 ? 17 : 29;
    for my $key ( @keys ) {
	$key += 12 if $key < 0;
	$key -= 12 while $key >= $kk;
	my $o = int( $key / 12 );
	$key %= 12;
	my ($pos,$type) = @{$k{$key}};
	$pos -= 3 if uc($ctl->{base}) ne 'C';
	$pos %= 7;
	$pos += 7 * $o;
	if ( $type eq "L" ) {
	    $pr->poly( [ $x+$pos*$kw,              $y-$kh,
			 $x+$pos*$kw,              $y,
			 $x+($pos+0.75)*$kw-$lw/2, $y,
			 $x+($pos+0.75)*$kw-$lw/2, $y-($kh-$lw)/2,
			 $x+($pos+1)*$kw,          $y-($kh-$lw)/2,
			 $x+($pos+1)*$kw,          $y-$kh,
		       ],
		       $lw, $col, 'black' );
	}
	elsif ( $type eq "R" ) {
	    $pr->poly( [ $x+$pos*$kw,               $y-$kh,
			 $x+$pos*$kw,               $y-($kh-$lw)/2,
			 $x+($pos+0.375)*$kw-$lw/2, $y-($kh-$lw)/2,
			 $x+($pos+0.375)*$kw-$lw/2, $y,
			 $x+($pos+1)*$kw,           $y,
			 $x+($pos+1)*$kw,           $y-$kh,
		       ],
		       $lw, $col, 'black' );
	}
	elsif ( $type eq "M" ) {
	    $pr->poly( [ $x+$pos*$kw,               $y-$kh,
			 $x+$pos*$kw,               $y-$kh/2+$lw,
			 $x+($pos+0.375)*$kw-$lw/2, $y-$kh/2+$lw/2,
			 $x+($pos+0.375)*$kw-$lw/2, $y,
			 $x+($pos+0.75)*$kw-$lw/2,  $y,
			 $x+($pos+0.75)*$kw-$lw/2,  $y-$kh/2+$lw/2,
			 $x+($pos+1)*$kw,           $y-$kh/2+$lw,
			 $x+($pos+1)*$kw,           $y-$kh,
		       ],
		       $lw, $col, 'black' );
	}
	else {
	    $pr->poly( [ $x+($pos+0.75)*$kw-$lw,    $y,
			 $x+($pos+0.75)*$kw-$lw,    $y-($kh-$lw)/2,
			 $x+($pos+1.375)*$kw-$lw/2, $y-($kh-$lw)/2,
			 $x+($pos+1.375)*$kw-$lw/2, $y,
			 ],
		       $lw, $col, 'black' );
	}
    }

    return $w + $ctl->{hspace};
}

my $pdfapi = 'PDF::API2';
my %grids;

sub grid_xo {
    my ( $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    my $kh = $ctl->{height};
    my $lw  = ($ctl->{linewidth} || 0.10) * $kw;
    my $keys = $ctl->{keys};
    my $base = uc($ctl->{base}) eq "F" ? 3 : 0;

    return $grids{$kw,$kh,$lw,$keys} //= do
      {
	my $w = $lw + $kw * $keys;
	my $h = $kh + $lw;

	# Draw the grid.
	my $form = $pdfapi->new;
	my $p = $form->page;
	my $x = 0;
	my $y = $kh;
	my @bb = (-$lw/2, -$lw/2, $w-$lw/2, $h-$lw/2);
	$p->bbox(@bb);
	my $g = $p->gfx;
	App::Music::ChordPro::Output::PDF::Writer::rectxy
	    ( { pdfgfx => $g }, @bb, 0, 'yellow' ) if 0;
	App::Music::ChordPro::Output::PDF::Writer::hline
	    ( { pdfgfx => $g }, $x, $y - $_*$kh, $w, $lw ) for 0..1;
	App::Music::ChordPro::Output::PDF::Writer::vline
	    ( { pdfgfx => $g }, $x + $_*$kw, $y, $kh, $lw ) for 0..$keys;
	$x += ($kw)/2+$lw;
	for my $i ( 1, 2, 4, 5, 6, 8, 9, 11, 12, 13, 15, 16, 18, 19, 20 ) {
	    next if $i < $base;
	    last if $i > $keys + $base;
	    my $x = $x + ($i-$base-1)*$kw;
	    App::Music::ChordPro::Output::PDF::Writer::rectxy
		( { pdfgfx => $g }, $x, $y-$kh/2, $x + 0.75*$kw, $kh, $lw, 'black' );
	}

	# Still waste. but less...
	#$form = $form->stringify;
	#$form = $pdfapi->open_scalar($form);
	$p->{' fixed'} = 1;
	$ps->{pr}->{pdf}->importPageIntoForm($form,1);
      };
}

sub strings2keys {
    my ( $info ) = @_;
    return $info->{keys} if $info->{keys};
    return unless $info->{frets} && @{$info->{frets}};

    my @tuning = ( 4, 9, 2, 7, 11, 4 );
    my %keys;
    my $i = -1;
    my $base = $info->{base} - 1;
    $base = 0 if $base < 0;
    for ( @{ $info->{frets} } ) {
	$i++;
	next if $_ < 0;
	my $c = ( $tuning[$i] + $_ + $base ) % 12;
	$c += 12 if $c < $info->{root_ord};
	$keys{ $c }++;
    }
    return [ keys %keys ];
}

1;
