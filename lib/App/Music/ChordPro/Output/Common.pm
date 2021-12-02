#!/usr/bin/perl

package main;

our $config;
our $options;

package App::Music::ChordPro::Output::Common;

use strict;
use warnings;
use App::Music::ChordPro::Chords;
use String::Interpolate::Named;
use utf8;
use POSIX qw(setlocale LC_TIME strftime);

use parent qw(Exporter);
our @EXPORT;
our @EXPORT_OK;

sub fmt_subst {
    my ( $s, $t ) = @_;
    my $res = "";
    my $m = { %{$s->{meta} || {} } };

    # Derived item(s).
    $m->{_key} = $m->{key} if exists $m->{key};
    if ( $m->{key} && $m->{capo} && (my $capo = $m->{capo}->[-1]) ) {
	####CHECK
	$m->{_key} =
	  [ map { App::Music::ChordPro::Chords::transpose( $_, $capo ) }
	        @{$m->{key}} ];
    }
    $m->{key_actual} //= $m->{key};
    $m->{tuning} //= [ join(" ", App::Music::ChordPro::Chords::get_tuning) ];
    # If config->{instrument} is missing, or null, the program abends with
    # Modification of a read-only value attempted.
    if ( $config->{instrument} ) {
	$m->{instrument} = [ $config->{instrument}->{type} ];
	$m->{"instrument.type"} = [ $config->{instrument}->{type} ];
	$m->{"instrument.description"} = [ $config->{instrument}->{description} ];
    }
    # Same here.
    if ( $config->{user} ) {
	$m->{user} = [ $config->{user}->{name} ];
	$m->{"user.name"} = [ $config->{user}->{name} ];
	$m->{"user.fullname"} = [ $config->{user}->{fullname} ];
    }
    setlocale( LC_TIME, "" );
    $m->{today} //= [ strftime( $config->{dates}->{today}->{format},
				localtime(time) ) ];
    interpolate( { %$s, args => $m,
		   separator => $config->{metadata}->{separator} },
		 $t );
}
push( @EXPORT, 'fmt_subst' );

# Roman - functions for converting between Roman and Arabic numerals
# 
# Stolen from Roman Version 1.24 by OZAWA Sakuro <ozawa at aisoft.co.jp>
# 1995-1997 and Alexandr Ciornii, C<< <alexchorny at gmail.com> >> 2007
# 
# Copyright (c) 1995 OZAWA Sakuro.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

our %roman2arabic = qw(I 1 V 5 X 10 L 50 C 100 D 500 M 1000);
my %roman_digit = qw(1 IV 10 XL 100 CD 1000 MMMMMM);
my @figure = reverse sort keys %roman_digit;
#my %roman_digit;
$roman_digit{$_} = [split(//, $roman_digit{$_}, 2)] foreach @figure;

sub isroman($) {
    my $arg = shift;
    $arg ne '' and
      $arg =~ /^(?: M{0,3})
                (?: D?C{0,3} | C[DM])
                (?: L?X{0,3} | X[LC])
                (?: V?I{0,3} | I[VX])$/ix;
}
push( @EXPORT_OK, 'isroman' );

sub arabic($) {
    my $arg = shift;
    isroman $arg or return undef;
    my($last_digit) = 1000;
    my($arabic);
    foreach (split(//, uc $arg)) {
        my($digit) = $roman2arabic{$_};
        $arabic -= 2 * $last_digit if $last_digit < $digit;
        $arabic += ($last_digit = $digit);
    }
    $arabic;
}
push( @EXPORT_OK, 'arabic' );

sub Roman($) {
    my $arg = shift;
    0 < $arg and $arg < 4000 or return undef;
    my($x, $roman);
    foreach (@figure) {
        my($digit, $i, $v) = (int($arg / $_), @{$roman_digit{$_}});
        if (1 <= $digit and $digit <= 3) {
            $roman .= $i x $digit;
        } elsif ($digit == 4) {
            $roman .= "$i$v";
        } elsif ($digit == 5) {
            $roman .= $v;
        } elsif (6 <= $digit and $digit <= 8) {
            $roman .= $v . $i x ($digit - 5);
        } elsif ($digit == 9) {
            $roman .= "$i$x";
        }
        $arg -= $digit * $_;
        $x = $i;
    }
    $roman;
}
push( @EXPORT_OK, 'Roman' );

sub roman($) {
    lc Roman shift;
}
push( @EXPORT_OK, 'roman' );

# Prepare outlines.
# This mainly untangles alternative names when being sorted on.
# Returns a book array where each element consists of the sort items,
# and the song.

sub prep_outlines {
    my ( $book, $ctl ) = @_;
    return [] unless $book && @$book; # unlikely
    return [] if $ctl->{omit};

    my @fields = @{$ctl->{fields}};
    if ( @fields > 2 ) {
	croak("Too many fields for outline (max 2)");
    }
    elsif ( @fields == 1 && $fields[0] eq "songindex" ) {
	# Return in book order.
	return [ map { [ $_->{meta}->{songindex}, $_ ] } @$book ];
    }
    return $book unless @fields; # ?

    my @book;
    foreach my $song ( @$book ) {
	my $meta = $song->{meta};

	my @split;

	foreach my $item ( @fields ) {
	    ( my $coreitem = $item ) =~ s/^sort//;
	    push( @split, [] ), next unless $meta->{$coreitem};

	    my @s = map { [ $_ ] }
	      @{ UNIVERSAL::isa( $meta->{$coreitem}, 'ARRAY' )
		? $meta->{$coreitem}
		: [ $meta->{$coreitem} ]
	    };

	    if ( $meta->{"sort$coreitem"} ) {
		if ( $coreitem eq $item ) {
		    for ( my $i = 0; $i < @{$meta->{"sort$coreitem"}}; $i++ ) {
			next unless defined $s[$i]->[0];
			$s[$i]->[1] = $meta->{"sort$coreitem"}->[$i];
		    }
		}
		else {
		    for ( my $i = 0; $i < @{$meta->{$item}}; $i++ ) {
			next unless defined $s[$i]->[0];
			$s[$i]->[1] = $meta->{$item}->[$i];
		    }
		}
	    }
	    push( @split, [ $coreitem, @s ] );
	}

	# Merge with (unique) copies of the song.
	if ( @split == 0 ) {
	    push( @book, $song );
	}
	elsif ( @split == 1 ) {
	    my $f1 = shift(@{$split[0]});
	    my $addsort1 = $f1 =~ /^(title|artist)$/;
	    for my $s1 ( @{$split[0]} ) {
		push( @book,
		      { %$song,
			meta =>
			{ %$meta,
			  $f1       => [ $s1->[0] ],
			  $addsort1
			  ? ( "sort$f1" => [ $s1->[1] // $s1->[0] ] )
			  : (),
			}
		      }
		    );
	    }
	}
	else {
	    my $f1 = shift(@{$split[0]}) // "";
	    my $f2 = shift(@{$split[1]}) // "";
	    my $addsort1 = $f1 =~ /^(title|artist)$/;
	    my $addsort2 = $f2 =~ /^(title|artist)$/;
	    for my $s1 ( @{$split[0]} ) {
		for my $s2 ( @{$split[1]} ) {
		    push( @book,
			  { %$song,
			   meta =>
			   { %$meta,
			     $f1       => [ $s1->[0] ],
			     $addsort1
			     ? ( "sort$f1" => [ $s1->[1] // $s1->[0] ] )
			     : (),
			     $f2       => [ $s2->[0] ],
			     $addsort2
			     ? ( "sort$f2" => [ $s2->[1] // $s2->[0] ] )
			     : (),
			   }
			  }
			);
		}
	    }
	}
    }

    # Sort.
    if ( @{$ctl->{fields}} == 1 ) {
	@book =
	  sort { $a->[0] cmp $b->[0] }
	  map { [ demarkup(lc($_->{meta}->{$ctl->{fields}->[0]}->[0])), $_ ] }
	  @book;
    }
    elsif ( @{$ctl->{fields}} == 2 ) {
	@book =
	  sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] }
	  map { [ demarkup(lc($_->{meta}->{$ctl->{fields}->[0]}->[0])),
		  demarkup(lc($_->{meta}->{$ctl->{fields}->[1]}->[0])),
		  $_ ] }
	  @book;
    }
    else {
	# Already asserted.
    }

    return \@book;
}
push( @EXPORT_OK, 'prep_outlines' );

# Remove markup.
sub demarkup {
    my ( $t ) = @_;
    $t =~ s;</?([-\w]+|span\s.*?)>;;g;
    return $t;
}
push( @EXPORT, 'demarkup' );

1;
