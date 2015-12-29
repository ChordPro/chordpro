#!/usr/bin/perl

package Music::ChordPro::Songbook;

use strict;
use warnings;
use Encode qw(decode);
use Carp;

sub new {
    my ($pkg) = @_;
    bless { songs => [ Music::ChordPro::Song->new ] }, $pkg;
}

my $def_context = "";
my $in_context = $def_context;

sub parsefile {
    my ( $self, $filename, $options ) = @_;

    open(my $fh, '<', $filename)
      or croak("$filename: $!\n");

    #### TODO: parsing config and rc file?
    push( @{ $self->{songs} }, Music::ChordPro::Song->new )
      if exists($self->{songs}->[-1]->{body});
    $self->{songs}->[-1]->{structure} = "linear";

    while ( <$fh> ) {
	s/[\r\n]+$//;

	my $line;
	if ( $options->{encoding} ) {
	    $line = decode( $options->{encoding}, $_, 1 );
	}
	else {
	    eval { $line = decode( "UTF-8", $_, 1 ) };
	    $line = decode( "iso-8859-1", $_ ) if $@;
	}
	$_ = $line;

	#s/^#({t:)/$1/;
	next if /^#/;

	# For practical reasons: a prime should always be an apostroph.
	s/'/\x{2019}/g;

	if ( /\{(.*)\}\s*$/ ) {
	    $self->directive($1);
	    next;
	}

	if ( $in_context eq "tab" ) {
	    $self->add( type => "tabline", text => $_ );
	    next;
	}

	if ( /\S/ ) {
	    $self->add( type => "songline", $self->decompose($_) );
	}
	else {
	    $self->add( type => "empty" );
	}
    }
    # $self->{songs}->[-1]->structurize;
}

sub add {
    my $self = shift;
    push( @{$self->{songs}->[-1]->{body}},
	  { context => $in_context,
	    @_ } );
}

sub decompose {
    my ($self, $line) = @_;
    $line =~ s/\s+$//;
    my @a = split(/(\[.*?\])/, $line, -1);

    die("Illegal line $.:\n$_\n") unless @a; #### TODO

    if ( @a == 1 ) {
	return ( phrases => [ $line ] );
    }

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

    # Context flags.

    if    ( $d eq "soc" ) { $d = "start_of_chorus" }
    elsif ( $d eq "sot" ) { $d = "start_of_tab"    }
    elsif ( $d eq "eoc" ) { $d = "end_of_chorus"   }
    elsif ( $d eq "eot" ) { $d = "end_of_tab"      }


    if ( $d =~ /^start_of_(\w+)$/ ) {
	warn("Already in " . ucfirst($in_context) . " context\n")
	  if $in_context;
	$in_context = $1;
	return;
    }
    if ( $d =~ /^end_of_(\w+)$/ ) {
	warn("Not in " . ucfirst($1) . " context\n")
	  unless $in_context eq $1;
	$in_context = $def_context;
	return;
    }

    # Song settings.

    my $cur = $self->{songs}->[-1];

    if ( $d =~ /^(?:title|t):\s*(.*)/i ) {
	$cur->{title} = $1;
	return;
    }

    if ( $d =~ /^(?:subtitle|st):\s*(.*)/i ) {
	push(@{$cur->{subtitle}}, $1);
	return;
    }

    # Breaks.

    if ( $d =~ /^(?:colb|column_break)$/i ) {
	$self->add( type => "colb" );
	return;
    }

    if ( $d =~ /^(?:new_page|np)$/i ) {
	$self->add( type => "newpage" );
	return;
    }

    if ( $d =~ /^(?:new_song|ns)$/i ) {
	push(@{$self->{songs}}, Music::ChordPro::Song->new );
	return;
    }

    # Comments. Strictly speaking they do not belong here.

    if ( $d =~ /^(?:comment|c|highlight):\s*(.*)/i ) {
	$self->add( type => "comment", text => $1 );
	return;
    }

    if ( $d =~ /^(?:comment_italic|ci):\s*(.*)/i ) {
	$self->add( type => "comment_italic", text => $1 );
	return;
    }

    # Song / Global settings.

    # $cur = ???;

    if ( $d =~ /^(?:titles\s*:\s*)(left|right|center|centre)$/i ) {
	$cur->{settings}->{titles} =
	  $1 eq "centre" ? "center" : $1;
	return;
    }

    if ( $d =~ /^(?:columns\s*:\s*)(\d+)$/i ) {
	$cur->{settings}->{columns} = $1;
	return;
    }

    if ( $d =~ /^([-+])([-\w]+)$/i ) {
	$self->add( type => "control",
		    name => $2,
		    value => $1 eq "+" ? "1" : "0",
		  );
	return;
    }

    # Formatting.
    if ( $d =~ /^(text|chord|tab)(font|size|colou?r):\s*(.*)$/ ) {
	my $item = $1;
	my $prop = $2;
	my $value = $3;
	if ( $prop eq "size" ) {
	    unless ( $value =~ /^\d+(?:\.\d+)?\%?$/ ) {
		warn("Illegal value \"$value\" for $item$prop\n");
		return;
	    }
	}
	if ( $prop =~ /^colou?r$/  ) {
	    unless ( get_colour($value) ) {
		warn("Illegal value \"$value\" for $item$prop\n");
		return;
	    }
	}
	$self->add( type => "control",
		    name => "$item-$prop",
		    value => $value );
	return;
    }

    #### TODO: other # strings (ukelele, banjo, ...)
    # define A: basefret N frets N N N N N N
    # define: A basefret N frets N N N N N N
    if ( $d =~ /^define\s+([^:]+):\s+
		   base-fret\s+(\d+)\s+
		   frets\s+([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])
		  /xi
	    ||
	    $d =~ /^define:\s+(\S+)\s+
		   base-fret\s+(\d+)\s+
		   frets\s+([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])\s+
		   ([0-9---xX])
		  /xi
	  ) {
	my @f = ($3, $4, $5, $6, $7, $8);
	push(@{$cur->{define}},
	     { name => $1,
	       $2 ? ( base => $2 ) : (),
	       frets => [ map { $_ =~ /^\d+/ ? $_ : '-' } @f ],
	     });
	return;
    }

    # Metadata extensions. Ignore for now.
    if ( $d =~ /^(artist|composer|album|key|time|tempo)$/ ) {
	return;
    }

    # Warn about unknowns, unless they are x_... form.
    warn("Unknown directive: $d\n") unless $d =~ /^x_/;
    return "";
}

sub structurize {
    my ( $self ) = @_;

    foreach my $song ( @{ $self->{songs} } ) {
	$song->structurize;
    }
}

package Music::ChordPro::Song;

sub new {
    my ( $pkg, %init ) = @_;
    bless { structure => "linear", %init }, $pkg;
}

sub structurize {
    my ( $self ) = @_;

    return if $self->{structure} eq "structured";

    my @body;
    my $context = $def_context;

    foreach my $item ( @{ $self->{body} } ) {
	if ( $item->{type} eq "empty" && $item->{context} eq $def_context ) {
	    $context = $def_context;
	    next;
	}
	if ( $context ne $item->{context} ) {
	    push( @body, { type => $context = $item->{context}, body => [] } );
	}
	if ( $context ) {
	    push( @{ $body[-1]->{body} }, $item );
	}
	else {
	    push( @body, $item );
	}
    }
    $self->{body} = [ @body ];
    $self->{structure} = "structured";
}

1;
