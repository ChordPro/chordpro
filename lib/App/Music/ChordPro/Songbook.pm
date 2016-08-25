#!/usr/bin/perl

package App::Music::ChordPro::Songbook;

use strict;
use warnings;

use App::Music::ChordPro::Chords;

use Encode qw(decode encode);
use Carp;

sub new {
    my ($pkg) = @_;
    bless { songs => [ App::Music::ChordPro::Song->new ] }, $pkg;
}

my $def_context = "";
my $in_context = $def_context;
my $xpose;
my @used_chords;
my %used_chords;
my $re_meta;

my $diag;			# for diagnostics

sub parsefile {
    my ( $self, $filename, $options ) = @_;

    my $fh;
    if ( ref($filename) ) {
	my $data = encode("UTF-8", $$filename);
	$filename = "__STRING__";
	open($fh, '<', \$data)
	  or croak("$filename: $!\n");
    }
    else {
	open($fh, '<', $filename)
	  or croak("$filename: $!\n");
    }

    push( @{ $self->{songs} }, App::Music::ChordPro::Song->new )
      if exists($self->{songs}->[-1]->{body});
    $self->{songs}->[-1]->{structure} = "linear";
    $xpose = $options->{transpose};
    @used_chords = ();
    %used_chords = ();
    App::Music::ChordPro::Chords::reset_song_chords();
    $diag->{format} = $options->{diagformat}
      || $::config->{diagnostics}->{format};
    $diag->{file} = $filename;

    # Build regex for the known metadata items.
    if ( $::config->{metadata}->{keys} ) {
	$re_meta = '^(' .
	  join( '|', map { quotemeta } @{$::config->{metadata}->{keys}} )
	    . ')$';
	$re_meta = qr/$re_meta/;
    }
    else {
	undef $re_meta;
    }

    while ( <$fh> ) {
	s/[\r\n]+$//;
	$diag->{line} = $.;
	$diag->{orig} = $_;

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
	    $options->{_legacy}
	      ? $self->global_directive( $1, 1 )
	      : $self->directive($1);
	    next;
	}

	if ( $in_context eq "tab" ) {
	    $self->add( type => "tabline", text => $_ );
	    next;
	}

	if ( $in_context eq "grid" ) {
	    $self->add( type => "gridline", $self->decompose_grid($_) );
	    next;
	}

	if ( /\S/ ) {
	    $self->add( type => "songline", $self->decompose($_) );
	}
	else {
	    $self->add( type => "empty" );
	}
    }

    my $showgrids;
    if ( exists($self->{songs}->[-1]->{settings}->{showgrids} ) ) {
	$showgrids = $self->{songs}->[-1]->{settings}->{showgrids};
    }
    else {
	$showgrids = $::config->{chordgrid}->{show};
    }

    if ( $showgrids ) {
	if ( $::config->{chordgrid}->{hard} ) {
	    @used_chords =
	      grep { ! App::Music::ChordPro::Chords::chord_info($_)->{easy} } @used_chords;
	}
	if ( $::config->{chordgrid}->{sorted} ) {
	    @used_chords =
	      sort App::Music::ChordPro::Chords::chordcompare @used_chords;
	}

	$self->add( type => "chord-grids",
		    origin => "song",
		    chords => [ @used_chords ] );
    }

    # $self->{songs}->[-1]->structurize;

    return 1;
}

sub add {
    my $self = shift;
    push( @{$self->{songs}->[-1]->{body}},
	  { context => $in_context,
	    @_ } );
}

sub chord {
    my ( $c ) = @_;
    return $c unless length($c);
    my $parens = $c =~ s/^\((.*)\)$/$1/;
    if ( exists $used_chords{$c} ) {
	return $parens ? "($used_chords{$c})" : $used_chords{$c};
    }

    my $info = App::Music::ChordPro::Chords::chord_info($c);
    unless ( $info ) {
	do_warn("Unknown chord: $c\n");
	$info = App::Music::ChordPro::Chords::add_unknown_chord($c)
	  if $::config->{chordgrid}->{auto};
    }
    my $xc = App::Music::ChordPro::Chords::transpose( $c, $xpose );
    if ( $xc ) {
	$used_chords{$c} = $xc;
    }
    else {
	$xc = $c;
    }
    push( @used_chords, $xc ) if $info;
    return $parens ? "($xc)" : $xc;
}

sub cxpose {
    my ( $t ) = @_;
    $t =~ s/\[(.+?)\]/chord($1)/ge;
    return $t;
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
	push(@chords, chord($t));
	push(@phrases, shift(@a));
    }

    return ( phrases => \@phrases, chords  => \@chords );
}

sub decompose_grid {
    my ($self, $line) = @_;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my $rest;
    if ( $line =~ /(.*\|\S*)\s([^\|]*)$/ ) {
	$line = $1;
	$rest = cxpose($2);
    }
    my @tokens = map { chord($_) } split( ' ', $line );
    return ( tokens => \@tokens, $rest ? ( comment => $rest ) : () );
}

sub dir_split {
    my ( $d ) = @_;
    $d =~ s/^[: ]+//;
    $d =~ s/\s+$//;
    my $dir = lc($d);
    my $arg = "";
    if ( $d =~ /^(.*?)[: ]\s*(.*)/ ) {
	( $dir, $arg ) = ( lc($1), $2 );
    }
    $dir =~ s/[: ]+$//;
    ( $dir, $arg );
}

sub directive {
    my ($self, $d) = @_;
    my ( $dir, $arg ) = dir_split($d);

    # Context flags.

    if    ( $dir eq "soc" ) { $dir = "start_of_chorus" }
    elsif ( $dir eq "sot" ) { $dir = "start_of_tab"    }
    elsif ( $dir eq "eoc" ) { $dir = "end_of_chorus"   }
    elsif ( $dir eq "eot" ) { $dir = "end_of_tab"      }

    if ( $dir =~ /^start_of_(\w+)\s*(.*)$/ ) {
	do_warn("Already in " . ucfirst($in_context) . " context\n")
	  if $in_context;
	$in_context = $1;
	my $par = $2;
	if ( $1 eq "grid" && $par && $par =~ /^(\d+)(?:x(\d+))?$/ ) {
	    do_warn("Invalid grid params: $par (must be non-zero)"), return
	      unless $1;
	    $self->add( type => "control",
			name => "gridparams",
			value => [ $1, $2 ] );
	}
	else {
	    do_warn("Garbage in start_of_$1: $par (ignored)\n")
	      if $par;
	}
	return;
    }
    if ( $dir =~ /^end_of_(\w+)$/ ) {
	do_warn("Not in " . ucfirst($1) . " context\n")
	  unless $in_context eq $1;
	$in_context = $def_context;
	return;
    }
    if ( $dir =~ /^chorus$/i ) {
	$self->add( type => "rechorus" );
	return;
    }

    # Song settings.

    my $cur = $self->{songs}->[-1];

    # Breaks.

    if ( $dir =~ /^(?:colb|column_break)$/i ) {
	$self->add( type => "colb" );
	return;
    }

    if ( $dir =~ /^(?:new_page|np|new_physical_page|npp)$/i ) {
	$self->add( type => "newpage" );
	return;
    }

    if ( $dir =~ /^(?:new_song|ns)$/i ) {
	return unless $self->{songs}->[-1]->{body};
	push(@{$self->{songs}}, App::Music::ChordPro::Song->new );
	return;
    }

    # Comments. Strictly speaking they do not belong here.

    if ( $dir =~ /^(?:comment|c|highlight)$/ ) {
	$self->add( type => "comment", text => cxpose($arg) );
	return;
    }

    if ( $dir =~ /^(?:comment_italic|ci)$/ ) {
	$self->add( type => "comment_italic", text => cxpose($arg) );
	return;
    }

    if ( $dir =~ /^(?:comment_box|cb)$/ ) {
	$self->add( type => "comment_box", text => cxpose($arg) );
	return;
    }

    # Images.
    if ( $dir eq "image" ) {
	use Text::ParseWords qw(shellwords);
	my @args = shellwords($arg);
	my $uri;
	my %opts;
	foreach ( @args ) {
	    if ( /^(width|height|border|center)=(\d+)$/i ) {
		$opts{lc($1)} = $2;
	    }
	    elsif ( /^(scale)=(\d(?:\.\d+)?)$/i ) {
		$opts{lc($1)} = $2;
	    }
	    elsif ( /^(center|border)$/i ) {
		$opts{lc($_)} = 1;
	    }
	    elsif ( /^(src|uri)=(.+)$/i ) {
		$uri = $2;
	    }
	    elsif ( /^(title)=(.*)$/i ) {
		$opts{title} = $1;
	    }
	    elsif ( /^(.+)=(.*)$/i ) {
		do_warn( "Unknown image attribute: $1\n" );
		next;
	    }
	    else {
		$uri = $_;
	    }
	}
	unless ( $uri ) {
	    do_warn( "Missing image source\n" );
	    return;
	}
	$self->add( type => "image",
		    uri  => $uri,
		    opts => \%opts );
	return;
    }

    if ( $dir =~ /^(?:title|t)$/ ) {
	$cur->{title} = $arg;
	push( @{ $self->{songs}->[-1]->{meta}->{title} }, $arg );
	return;
    }

    if ( $dir =~ /^(?:subtitle|st)$/ ) {
	push(@{$cur->{subtitle}}, $arg);
	push( @{ $self->{songs}->[-1]->{meta}->{subtitle} }, $arg );
	return;
    }

    # Metadata extensions (legacy). Should use meta instead.
    # Only accept the list from config.
    if ( $re_meta && $dir =~ $re_meta ) {
	if ( $xpose && $1 eq "key" ) {
	    $arg = App::Music::ChordPro::Chords::transpose( $arg, $xpose );
	}
	push( @{ $self->{songs}->[-1]->{meta}->{$1} }, $arg );
	return;
    }

    # More metadata.
    if ( $dir =~ /^(meta)$/ ) {
	if ( $arg =~ /([^ :]+)[ :]+(.*)/ ) {
	    my $key = lc $1;
	    my $val = $2;
	    if ( $xpose && $key eq "key" ) {
		$val = App::Music::ChordPro::Chords::transpose( $val, $xpose );
	    }
	    if ( $re_meta && $key =~ $re_meta ) {
		# Known.
		push( @{ $self->{songs}->[-1]->{meta}->{$key} }, $val );
	    }
	    elsif ( $::config->{metadata}->{strict} ) {
		# Unknown, and strict.
		do_warn("Unknown metadata item: $key");
	    }
	    else {
		# Allow.
		push( @{ $self->{songs}->[-1]->{meta}->{$key} }, $val );
	    }
	}
	else {
	    do_warn("Incomplete meta directive: $d\n");
	}
	return;
    }

    return if $self->global_directive( $d, 0 );

    # Warn about unknowns, unless they are x_... form.
    do_warn("Unknown directive: $d\n") unless $d =~ /^x_/;
    return;
}

sub global_directive {
    my ($self, $d, $legacy ) = @_;
    my ( $dir, $arg ) = dir_split($d);

    my $cur = $self->{songs}->[-1];

    # Song / Global settings.

    if ( $dir eq "titles"
	 && $arg =~ /^(left|right|center|centre)$/i ) {
	$cur->{settings}->{titles} =
	  lc($1) eq "centre" ? "center" : lc($1);
	return 1;
    }

    if ( $dir eq "columns"
	 && $arg =~ /^(\d+)$/ ) {
	$cur->{settings}->{columns} = $arg;
	return 1;
    }

    if ( $dir eq "pagetype" || $dir eq "pagesize" ) {
	$cur->{settings}->{papersize} = $arg;
	return 1;
    }

    if ( $dir =~ /^(?:grid|g)$/ ) {
	$cur->{settings}->{showgrids} = 1;
	return 1;
    }
    if ( $dir =~ /^(?:no_grid|ng)$/ ) {
	$cur->{settings}->{showgrids} = 0;
	return 1;
    }

    if ( $d =~ /^([-+])([-\w]+)$/i ) {
	return if $legacy;
	$self->add( type => "control",
		    name => $2,
		    value => $1 eq "+" ? "1" : "0",
		  );
	return 1;
    }

    if ( $dir =~ /^([-+])([-\w]+)$/ ) {
	return if $legacy;
	$self->add( type => "control",
		    name => $2,
		    value => $arg,
		  );
	return 1;
    }

    # Formatting.
    if ( $dir =~ /^(text|chord|tab|grid|title|footer|toc)(font|size|colou?r)$/ ) {
	my $item = $1;
	my $prop = $2;
	my $value = $arg;
	return if $legacy
	  && ! ( $item =~ /^(text|chord|tab)$/ && $prop =~ /^(font|size)$/ );

	$prop = "color" if $prop eq "colour";
	if ( $prop eq "size" ) {
	    unless ( $value =~ /^\d+(?:\.\d+)?\%?$/ ) {
		do_warn("Illegal value \"$value\" for $item$prop\n");
		return 1;
	    }
	}
	if ( $prop =~ /^colou?r$/  ) {
	    my $v;
	    unless ( $v = get_color($value) ) {
		do_warn("Illegal value \"$value\" for $item$prop\n");
		return 1;
	    }
	    $value = $v;
	}
	$self->add( type => "control",
		    name => "$item-$prop",
		    value => $prop eq 'font' ? $value : lc($value) );
	return 1;
    }

    # define A: base-fret N frets N N N N N N
    # define: A base-fret N frets N N N N N N
    # optional: base-fret N (defaults to 1)
    # optional: N N N N N N (for unknown chords)
    if (    $d =~ /^define[: ]+([^: ]+)[: ]\s*
		   (?:base-fret\s+(\d+)\s+)?
		   frets
		   ((?:\s+[0-9---xX])*
		    \s+[0-9---xX])?
		   \s*$
		  /xi
	  ) {
	my @f = split(' ', $3||'');
	my $ci = { name => $1,
		   base => $2 || 1,
		   frets => [ map { $_ =~ /^\d+/ ? $_ : -1 } @f ],
		 };
	push( @{$cur->{define}}, $ci );
	if ( @f ) {
	    my $res =
	      App::Music::ChordPro::Chords::add_song_chord
		  ( $ci->{name}, $ci->{base} || 1, $ci->{frets} );
	    do_warn("Invalid chord: ", $ci->{name}, ": ", $res, "\n") if $res;
	}
	else {
	    App::Music::ChordPro::Chords::add_unknown_chord( $ci->{name} );
	}
	return 1;
    }
    return;
}

sub structurize {
    my ( $self ) = @_;

    foreach my $song ( @{ $self->{songs} } ) {
	$song->structurize;
    }
}

sub get_color {
    $_[0];
}

sub msg {
    my $m = join("", @_);
    $m =~ s/\n+$//;
    my $t = $diag->{format};
    $t =~ s/\%f/$diag->{file}/g;
    $t =~ s/\%n/$diag->{line}/g;
    $t =~ s/\%l/$diag->{orig}/g;
    $t =~ s/\%m/$m/g;
    $t =~ s/\\n/\n/g;
    $t =~ s/\\t/\t/g;
    $t;
}

sub do_warn {
    warn(msg(@_)."\n");
}

package App::Music::ChordPro::Song;

sub new {
    my ( $pkg, %init ) = @_;
    bless { structure => "linear", settings => {}, %init }, $pkg;
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
