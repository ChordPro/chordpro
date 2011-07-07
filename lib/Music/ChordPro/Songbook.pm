#!/usr/bin/perl

package Music::ChordPro::Songbook;

use strict;
use warnings;
use Carp;

sub new {
    my ($pkg) = @_;
    bless { songs => [bless {}, 'Music::ChordPro::Song'] }, $pkg;
}

sub parsefile {
    my ($self, $filename) = @_;

    open(my $fh, '<', $filename)
      or croak("$filename: $!\n");
    binmode( $fh, ':encoding(utf-8)' );

    my $type = "";		# normal
    my $tab = [];
    my $chorus = [];

    push(@{$self->{songs}}, bless {}, 'Music::ChordPro::Song')
      if exists($self->{songs}->[-1]->{body});

    my $flush = sub {
	# Flush out any accumulated TAB or CHORUS sections.
	if ( @$tab ) {
	    push(@{$self->{songs}->[-1]->{body}},
		 { type => "tab",
		   body => [ @$tab ],
		 });
	    $tab = [];
	}
	if ( @$chorus ) {
	    push(@{$self->{songs}->[-1]->{body}},
		 { type => "chorus",
		   body => [ @$chorus ],
		 });
	    $chorus = [];
	}
    };

    while ( <$fh> ) {
	chomp;

	next if /^#/;

	if ( /\{(.*)\}\s*$/ ) {
	    $flush->();
	    $type = $self->directive($1);
	}
	elsif ( $type eq "tab" ) {
	    push(@$tab, $_);
	}
	elsif ( $type eq "chorus" ) {
	    if ( /\W/ ) {
		# Basically, we could recurse here...
		push(@$chorus,
		     { type => "song",
		       $self->decompose($_),
		     });
	    }
	    else {
		push( @$chorus, { type => "empty" } );
	    }
	}
	else {
	    if ( /\W/ ) {
		push(@{$self->{songs}->[-1]->{body}},
		     { type => "song",
		       $type ? ( flag => $type ) : (),
		       $self->decompose($_),
		     });
	    }
	    else {
		push( @{$self->{songs}->[-1]->{body}}, { type => "empty" } );
	    }
	}
    }
    $flush->();
}

sub decompose {
    my ($self, $line) = @_;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my @a = split(/(\[.*?\])/, $line, -1);

    die("Illegal line $.:\n$_\n") unless @a; #### TODO

    shift(@a) if $a[0] eq "";
    unshift(@a, '[]') if $a[0] !~ /^\[/;


    my @phrases;
    my @chords;
    while ( @a ) {
	my $t = shift(@a);
	$t =~ s/^\[(.*)\]$/$1/;
	push(@chords, $t);
	push(@phrases, shift(@a));
    }

    return ( phrases => \@phrases, chords  => \@chords );
}

sub directive {
    my ($self, $d) = @_;
    return "chorus" if $d =~ /^start_of_chorus|soc$/;
    return ""       if $d =~ /^end_of_chorus|eoc$/;
    return "tab"    if $d =~ /^start_of_tab|sot$/;
    return ""       if $d =~ /^end_of_tab|eot$/;

    if ( $d =~ /^colb$/ ) {
	push(@{$self->{songs}->[-1]->{body}},
	     { type => "colb" });
	next;
    }

    if ( $d =~ /^(?:title|t):\s*(.*)/ ) {
	$self->{songs}->[-1]->{title} = $1;
	next;
    }

    if ( $d =~ /^(?:subtitle|st):\s*(.*)/ ) {
	push(@{$self->{songs}->[-1]->{subtitle}}, $1);
	next;
    }

    if ( $d =~ /^(?:comment|c):\s*(.*)/ ) {
	push(@{$self->{songs}->[-1]->{body}},
	     { type => "comment", text => $1 });
	next;
    }

    if ( $d =~ /^define\s+([^:]+):\s+
		   base-fret\s+(\d+)\s+
		   frets\s+([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])
		  /x
	    ||
	    $d =~ /^define:\s+(\S+)\s+
		   base-fret\s+(\d+)\s+
		   frets\s+([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])
		  /x
	  ) {
	my @f = ($3, $4, $5, $6, $7, $8);
	push(@{$self->{songs}->[-1]->{define}},
	     { name => $1,
	       $2 ? ( base => $2 ) : (),
	       frets => [ map { $_ =~ /^\d+/ ? $_ : '-' } @f ],
	     });
	next;
    }

    if ( $d =~ /^(?:new_song|ns)$/ ) {
	push(@{$self->{songs}}, bless {}, 'Music::ChordPro::Song');
	next;
    }

    warn("Unknown directive: $d\n");
    "";
}

1;
