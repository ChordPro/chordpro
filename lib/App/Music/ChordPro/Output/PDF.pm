#!/usr/bin/perl

package main;

use utf8;
our $config;
our $options;

package App::Music::ChordPro::Output::PDF;

use strict;
use warnings;
use Encode qw( encode_utf8 );
use App::Packager;
use File::Temp ();
use Storable qw(dclone);
use List::Util qw(any);
use feature 'state';

use App::Music::ChordPro::Output::Common
  qw( roman prep_outlines fmt_subst demarkup );

use App::Music::ChordPro::Output::PDF::Writer;
use App::Music::ChordPro::Utils;

my $pdfapi;

use Text::Layout;
use String::Interpolate::Named;

my $verbose = 0;

# For regression testing, run perl with PERL_HASH_SEED set to zero.
# This eliminates the arbitrary order of font definitions and triggers
# us to pinpoint some other data that would otherwise be varying.
my $regtest = defined($ENV{PERL_HASH_SEED}) && $ENV{PERL_HASH_SEED} == 0;

sub generate_songbook {
    my ( $self, $sb ) = @_;

    return [] unless $sb->{songs}->[0]->{body}; # no songs
    $verbose ||= $options->{verbose};

    my $ps = $config->{pdf};

    my $pr = (__PACKAGE__."::Writer")->new( $ps, $pdfapi );
    warn("Generating PDF ", $options->{output} || "__new__.pdf", "...\n") if $options->{verbose};

    my $name = ::runtimeinfo("short");
    $name =~ s/version.*/regression testing/ if $regtest;
    my %info = ( Title => $sb->{songs}->[0]->{meta}->{title}->[0],
		 Creator => $name );
    while ( my ( $k, $v ) = each %{ $ps->{info} } ) {
	next unless defined($v) && $v ne "";
	$info{ucfirst($k)} = fmt_subst( $sb->{songs}->[0], $v );
    }
    $pr->info(%info);

    # The book consists of 4 parts:
    # 1. The front matter.
    # 2. The table of contents.
    # 3. The songs.
    # 4. The back matter.
    my ( %start_of, %pages_of );
    for ( qw( front toc songbook back ) ) {
	$start_of{$_} = 1;
	$pages_of{$_} = 0;
    }

    # The songbook...
    my @book;
    my $page = $options->{"start-page-number"} ||= 1;

    if ( $ps->{'even-odd-pages'} && !($page % 2) ) {
	warn("Warning: Specifying an even start page when pdf.odd-even-pages is in effect may yield surprising results.\n");
    }

    my $first_song_aligned;
    foreach my $song ( @{$sb->{songs}} ) {

	# Align.
	if ( $ps->{'pagealign-songs'} && !($page % 2) ) {
	    $pr->newpage($ps, $page+1);
	    $page++;
	    $first_song_aligned //= 1;
	}
	$first_song_aligned //= 0;

	$song->{meta}->{tocpage} = $page;
	push( @book, [ $song->{meta}->{title}->[0], $song ] );

	$page += $song->{meta}->{pages} =
	  generate_song( $song, { pr => $pr, startpage => $page } );
	# Easy access to toc page.
	$song->{meta}->{page} = $song->{meta}->{tocpage};
    }
    $pages_of{songbook} = $page - 1;
    $start_of{back} = $page;

    $::config->{contents} //=
      [ { $::config->{toc}->{order} eq "alpha"
	  ? ( fields => [ "title" ] )
	  : ( fields => [ "songindex" ] ),
	  label => $::config->{toc}->{title},
	  line => $::config->{toc}->{line} } ];

    foreach my $ctl ( reverse( @{ $::config->{contents} } ) ) {
	next unless $options->{toc} // @book > 1;

	for ( qw( fields label line pageno ) ) {
	    next if exists $ctl->{$_};
	    die("Config error: \"contents\" is missing \"$_\"\n");
	}
	next if $ctl->{omit};

	my $book = prep_outlines( [ map { $_->[1] } @book ], $ctl );

	# Create a pseudo-song for the table of contents.
	my $t = $ctl->{label};
	my $l = $ctl->{line};
	my $start = $start_of{songbook} - $options->{"start-page-number"};
	my $pgtpl = $ctl->{pageno};
	my $song =
	  { title     => $t,
	    meta => { title => [ $t ] },
	    structure => "linear",
	    body      => [
		     map { +{ type    => "tocline",
			      context => "toc",
			      title   => fmt_subst( $_->[-1], $l ),
			      page    => $pr->{pdf}->openpage($_->[-1]->{meta}->{tocpage}+$start),
			      pageno  => fmt_subst( $_->[-1], $pgtpl ),
			    } } @$book,
	    ],
	  };

	# Prepend the toc.
	$page = generate_song( $song,
			       { pr => $pr, prepend => 1, roman => 1,
				 startpage => 1,
			       } );
	$pages_of{toc} += $page;
	$pages_of{toc}++ if $first_song_aligned;

	# Align.
	if ( $ps->{'even-odd-pages'} && $page % 2 && !$first_song_aligned ) {
	    $pr->newpage($ps, $page+1);
	    $page++;
	}
	$start_of{songbook} += $page;
	$start_of{back}     += $page;
    }

    if ( $options->{'front-matter'} ) {
	$page = 1;
	my $matter = $pdfapi->open( $options->{'front-matter'} );
	die("Missing front matter: ", $options->{'front-matter'}, "\n") unless $matter;
	for ( 1 .. $matter->pages ) {
	    $pr->{pdf}->importpage( $matter, $_, $_ );
	    $page++;
	}
	$pages_of{front} = $matter->pages;

	# Align to ODD page. Frontmatter starts on a right page but
	# songs on a left page.
	$pr->newpage( $ps, 1+$matter->pages ), $page++
	  if $ps->{'even-odd-pages'} && ($page % 2);

	$start_of{toc}      += $page - 1;
	$start_of{songbook} += $page - 1;
	$start_of{back}     += $page - 1;
    }

    if ( $options->{'back-matter'} ) {
	my $matter = $pdfapi->open( $options->{'back-matter'} );
	die("Missing back matter: ", $options->{'back-matter'}, "\n") unless $matter;
	$page = $start_of{back};
	$pr->newpage($ps), $page++, $start_of{back}++
	  if $ps->{'even-odd-pages'} && ($page % 2);
	for ( 1 .. $matter->pages ) {
	    $pr->{pdf}->importpage( $matter, $_, $page );
	    $page++;
	}
	$pages_of{back} = $matter->pages;
    }
    # warn ::dump(\%start_of) =~ s/\s+/ /gsr, "\n";
    # warn ::dump(\%pages_of) =~ s/\s+/ /gsr, "\n";

    # Note that the page indices run from zero.
    $pr->pagelabel( $start_of{front}-1,    'arabic', 'front-' )
      if $pages_of{front};
    $pr->pagelabel( $start_of{toc}-1,      'roman'            )
      if $pages_of{toc};
    $pr->pagelabel( $start_of{songbook}-1, 'arabic'           )
      if $pages_of{songbook};
    $pr->pagelabel( $start_of{back}-1,     'arabic', 'back-'  )
      if $pages_of{back};

    # Add the outlines.
    $pr->make_outlines( [ map { $_->[1] } @book ], $start_of{songbook} );

    $pr->finish( $options->{output} || "__new__.pdf" );
    warn("Generated PDF...\n") if $options->{verbose};

    generate_csv( \@book, $page, \%pages_of, \%start_of )
      if $options->{csv};

    _dump($ps) if $verbose;

    []
}

sub generate_csv {
    my ( $book, $page, $pages_of, $start_of ) = @_;

    # Create an MSPro compatible CSV for this PDF.
    push( @$book, [ "CSV", { meta => { tocpage => $page } } ] );
    ( my $csv = $options->{output} ) =~ s/\.pdf$/.csv/i;
    open( my $fd, '>:utf8', encode_utf8($csv) )
      or die( encode_utf8($csv), ": $!\n" );

    warn("Generating CSV ", encode_utf8($csv), "...\n")
      if  $config->{debug}->{csv} || $options->{verbose};

    my $ps = $config->{pdf};
    my $ctl = $ps->{csv};
    my $sep = $ctl->{separator} // ";";
    my $vsep = $ctl->{vseparator} // "|";

    my $rfc4180 = sub {
	my ( $v ) = @_;
	$v = [$v] unless ref($v) eq 'ARRAY';
	return "" unless defined($v) && defined($v->[0]);
	$v = join( $sep, @$v );
	return $v unless $v =~ m/[$sep"\n\r]/s;
	$v =~ s/"/""/g;
	return '"' . $v . '"';
    };

    my $pagerange = sub {
	my ( $pages, $page ) = @_;
	if ( @_ == 1 ) {
	    $pages = $pages_of->{$_[0]};
	    $page  = $start_of->{$_[0]};
	}
	$pages > 1
	  ? ( $page ."-". ($page+$pages-1) )
	  : $page,
      };

    my $csvline = sub {
	my ( $m ) = @_;
	my @cols = ();
	for ( @{ $ctl->{fields} } ) {
	    next if $_->{omit};
	    my $v = $_->{value} // '%{'.$_->{meta}.'}';
	    local( $config->{metadata}->{separator} ) = $vsep;
	    push( @cols, $rfc4180->( fmt_subst( { meta => $m }, $v ) ) );
	}
	print $fd ( join( $sep, @cols ), "\n" );
	scalar(@cols);
    };

    my @cols;
    my $ncols;
    for ( @{ $ctl->{fields} } ) {
	next if $_->{omit};
	push( @cols, $rfc4180->($_->{name}) );
    }
    $ncols = @cols;
    #warn( "CSV: $ncols fields\n" );
    print $fd ( join( $sep, @cols ), "\n" );

    unless ( $ctl->{songsonly} ) {
	$csvline->( { title     => '__front_matter__',
		      pagerange => $pagerange->("front"),
		      sorttitle => 'Front Matter',
		      artist    => 'ChordPro' } )
	  if $pages_of->{front};
	$csvline->( { title     => '__table_of_contents__',
		      pagerange => $pagerange->("front"),
		      sorttitle => 'Table of Contents',
		      artist    => 'ChordPro' } )
	  if $pages_of->{toc};
    }

    warn( "CSV: ", scalar(@$book), " songs in book\n")
      if $config->{debug}->{csv};
    for ( my $p = 0; $p < @$book-1; $p++ ) {
	my ( $title, $song ) = @{$book->[$p]};
	my $page = $start_of->{songbook} + $song->{meta}->{tocpage}
	  - ($options->{"start-page-number"} || 1);
	my $pp = $song->{meta}->{pages};
	my $m = { %{$song->{meta}},
		  pagerange => [ $pagerange->($pp, $page) ] };
	$csvline->($m);

	unless ( $ctl->{songsonly} ) {
	    $csvline->( { title     => '__back_matter__',
			  pagerange => $pagerange->("back"),
			  sorttitle => 'Back Matter',
			  artist    => 'ChordPro'} )
	      if $pages_of->{back};
	}
    }
    close($fd);
    warn("Generated CSV...\n")
      if  $config->{debug}->{csv} || $options->{verbose};
}

my $source;			# song source
my $structured = 0;		# structured data
my $suppress_empty_chordsline = 0;	# suppress chords line when empty
my $suppress_empty_lyricsline = 0;	# suppress lyrics line when blank
my $lyrics_only = 0;		# suppress all chord lines
my $inlinechords = 0;		# chords inline
my $inlineannots;		# format for inline annots
my $chordsunder = 0;		# chords under the lyrics
my $chordscol = 0;		# chords in a separate column
my $chordscapo = 0;		# capo in a separate column
my $i_tag;
our $assets;

use constant SIZE_ITEMS => [ qw (chord text tab grid diagram toc title footer) ];

sub generate_song {
    my ( $s, $opts ) = @_;

    return 0 unless $s->{body};	# empty song
    local $config = dclone( $s->{config} // $config );

    $source = $s->{source};
    $assets = $s->{assets} || {};

    $suppress_empty_chordsline = $::config->{settings}->{'suppress-empty-chords'};
    $suppress_empty_lyricsline = $::config->{settings}->{'suppress-empty-lyrics'};
    $inlinechords = $::config->{settings}->{'inline-chords'};
    $inlineannots = $::config->{settings}->{'inline-annotations'};
    $chordsunder  = $::config->{settings}->{'chords-under'};
    my $ps = $::config->clone->{pdf};
    my $pr = $opts->{pr};
    $ps->{pr} = $pr;
    $pr->{ps} = $ps;
    $pr->init_fonts();
    my $fonts = $ps->{fonts};

    $structured = ( $options->{'backend-option'}->{structure} // '' ) eq 'structured';
    $s->structurize if $structured;

    # Diagrams drawer.
    my $dd;
    my $dctl;
    if ( $::config->{instrument}->{type} eq "keyboard" ) {
	require App::Music::ChordPro::Output::PDF::KeyboardDiagrams;
	$dd = App::Music::ChordPro::Output::PDF::KeyboardDiagrams->new($ps);
	$dctl = $ps->{kbdiagrams};
    }
    else {
	require App::Music::ChordPro::Output::PDF::StringDiagrams;
	$dd = App::Music::ChordPro::Output::PDF::StringDiagrams->new($ps);
	$dctl = $ps->{diagrams};
    }

    my $sb = $s->{body};

    # set_columns needs these, set provisional values.
    $ps->{_leftmargin}  = $ps->{marginleft};
    $ps->{_rightmargin} = $ps->{marginright};
    set_columns( $ps,
		 $s->{settings}->{columns} || $::config->{settings}->{columns} );

    $chordscol    = $ps->{chordscolumn};
    $lyrics_only  = $::config->{settings}->{'lyrics-only'};
    $chordscapo   = $s->{meta}->{capo};

    my $fail;
    for my $item ( @{ SIZE_ITEMS() } ) {
	for ( $options->{"$item-font"} ) {
	    next unless $_;
	    delete( $fonts->{$item}->{file} );
	    delete( $fonts->{$item}->{name} );
	    delete( $fonts->{$item}->{description} );
	    if ( m;/; ) {
		$fonts->{$item}->{file} = $_;
	    }
	    elsif ( is_corefont($_) ) {
		$fonts->{$item}->{name} = $_;
	    }
	    else {
		$fonts->{$item}->{description} = $_;
	    }
	    $pr->init_font($item) or $fail++;
	}
	for ( $options->{"$item-size"} ) {
	    next unless $_;
	    $fonts->{$item}->{size} = $_;
	}
    }
    die("Unhandled fonts detected -- aborted\n") if $fail;

    if ( $ps->{labels}->{comment} ) {
	$ps->{_indent} = 0;
    }
    elsif ( $ps->{labels}->{width} eq "auto" ) {
	if ( $s->{labels} && @{ $s->{labels} } ) {
	    my $longest = 0;
	    my $ftext = $fonts->{label} || $fonts->{text};
	    my $w = $pr->strwidth("    ", $ftext);
	    for ( @{ $s->{labels} } ) {
		for ( split( /\\n/, $_ ) ) {
		    my $t = $pr->strwidth( $_, $ftext ) + $w;
		    $longest = $t if $t > $longest;
		}
	    }
	    $ps->{_indent} = $longest;
	}
	else {
	    $ps->{_indent} = 0;
	}
    }
    else {
	$ps->{_indent} = $ps->{labels}->{width};
    }

    my $set_sizes = sub {
	$ps->{lineheight} = $fonts->{text}->{size} - 1; # chordii
	$ps->{chordheight} = $fonts->{chord}->{size};
    };
    $set_sizes->();
    $ps->{'vertical-space'} = $options->{'vertical-space'};
    for ( @{ SIZE_ITEMS() } ) {
	$fonts->{$_}->{_size} = $fonts->{$_}->{size};
    }

    my $x;
    my $y = $ps->{papersize}->[1] - $ps->{margintop};

    $ps->{'even-odd-pages'} =  1 if $options->{'even-pages-number-left'};
    $ps->{'even-odd-pages'} = -1 if $options->{'odd-pages-number-left'};

    my $st = $s->{settings}->{titles} || $::config->{settings}->{titles};
    if ( defined($st)
	 && ! $ps->{'titles-directive-ignore'} ) {
	my $swap = sub {
	    my ( $from, $to ) = @_;
	    for my $class ( qw( default title first ) ) {
		for ( qw( title subtitle footer ) ) {
		    next unless defined $ps->{formats}->{$class}->{$_};
		    unless ( ref($ps->{formats}->{$class}->{$_}) eq 'ARRAY' ) {
			warn("Oops -- pdf.formats.$class.$_ is not an array\n");
			next;
		    }
		    unless ( ref($ps->{formats}->{$class}->{$_}->[0]) eq 'ARRAY' ) {
			$ps->{formats}->{$class}->{$_} =
			  [ $ps->{formats}->{$class}->{$_} ];
		    }
		    for my $l ( @{$ps->{formats}->{$class}->{$_}} ) {
			( $l->[$from], $l->[$to] ) =
			  ( $l->[$to], $l->[$from] );
		    }
		}
	    }
	};

	if ( $st eq "left" ) {
	    $swap->(0,1);
	}
	if ( $st eq "right" ) {
	    $swap->(2,1);
	}
    }

    my $do_size = sub {
	my ( $tag, $value ) = @_;
	if ( $value =~ /^(.+)\%$/ ) {
	    $fonts->{$tag}->{_size} //=
	      $::config->{pdf}->{fonts}->{$tag}->{size};
	    $fonts->{$tag}->{size} =
	      ( $1 / 100 ) * $fonts->{$tag}->{_size};
	}
	else {
	    $fonts->{$tag}->{size} =
	      $fonts->{$tag}->{_size} = $value;
	}
	$set_sizes->();
    };

    my $col;

    my $col_adjust = sub {
	if ( $ps->{columns} <= 1 ) {
	    warn("L=", $ps->{__leftmargin},
	     ", R=", $ps->{__rightmargin},
	     "\n") if $config->{debug}->{spacing};
	    return;
	}
	$x = $ps->{_leftmargin} + $ps->{columnoffsets}->[$col];
	$ps->{__leftmargin} = $x;
	$ps->{__rightmargin} =
	  $ps->{_leftmargin}
	    + $ps->{columnoffsets}->[$col+1];
	$ps->{__rightmargin} -= $ps->{columnspace}
	  if $col < $ps->{columns}-1;
	warn("C=$col, L=", $ps->{__leftmargin},
	     ", R=", $ps->{__rightmargin},
	     "\n") if $config->{debug}->{spacing};
	$y = $ps->{_top};
	$x += $ps->{_indent};
    };

    my $vsp_ignorefirst;
    my $startpage = $opts->{startpage} || 1;
    my $thispage = $startpage - 1;

    # Physical newpage handler.
    my $newpage = sub {

	# Add page to the PDF.
	$pr->newpage($ps, $opts->{prepend} ? $thispage+1 : () );

	# Put titles and footer.

	# If even/odd pages, leftpage signals whether the
	# header/footer parts must be swapped.
	my $rightpage = 1;
	if ( $ps->{"even-odd-pages"} ) {
	    # Even/odd printing...
	    $rightpage = $thispage % 2 == 0;
	    # Odd/even printing...
	    $rightpage = !$rightpage if $ps->{'even-odd-pages'} < 0;
	}

	# margin* are offsets from the edges of the paper.
	# _*margin are offsets taking even/odd pages into account.
	# _margin* are physical coordinates, taking ...
	if ( $rightpage ) {
	    $ps->{_leftmargin}  = $ps->{marginleft};
	    $ps->{_marginleft}  = $ps->{marginleft};
	    $ps->{_rightmargin} = $ps->{marginright};
	    $ps->{_marginright} = $ps->{papersize}->[0] - $ps->{marginright};
	}
	else {
	    $ps->{_leftmargin}  = $ps->{marginright};
	    $ps->{_marginleft}  = $ps->{marginright};
	    $ps->{_rightmargin} = $ps->{marginleft};
	    $ps->{_marginright} = $ps->{papersize}->[0] - $ps->{marginleft};
	}
	$ps->{_marginbottom}  = $ps->{marginbottom};
	$ps->{_margintop}     = $ps->{papersize}->[1] - $ps->{margintop};
	$ps->{_bottommargin}  = $ps->{marginbottom};

	# Physical coordinates; will be adjusted to columns if needed.
	$ps->{__leftmargin}   = $ps->{_marginleft};
	$ps->{__rightmargin}  = $ps->{_marginright};
	$ps->{__topmargin}    = $ps->{_margintop};
	$ps->{__bottommargin} = $ps->{_marginbottom};

	$thispage++;
	$s->{meta}->{page} = [ $s->{page} = $opts->{roman}
			       ? roman($thispage) : $thispage ];

	# Determine page class and background.
	my $class = 2;		# default
	my $bgpdf = $ps->{formats}->{default}->{background};
	if ( $thispage == 1 ) {
	    $class = 0;		# very first page
	    $bgpdf = $ps->{formats}->{first}->{background}
	      || $ps->{formats}->{title}->{background}
	      || $bgpdf;
	}
	elsif ( $thispage == $startpage ) {
	    $class = 1;		# first of a song
	    $bgpdf = $ps->{formats}->{title}->{background}
	      || $bgpdf;
	}
	if ( $bgpdf ) {
	    my ( $fn, $pg ) = ( $bgpdf, 1 );
	    if ( $bgpdf =~ /^(.+):(\d+)$/ ) {
		( $bgpdf, $pg ) = ( $1, $2 );
	    }
	    $fn = ::rsc_or_file($bgpdf);
	    if ( -s -r $fn ) {
		$pg++ if $ps->{"even-odd-pages"} && !$rightpage;
		$pr->importpage( $fn, $pg );
	    }
	    else {
		warn( "PDF: Missing or empty background document: ",
		      $bgpdf, "\n" );
	    }
	}

	$x = $ps->{__leftmargin};
	$x += $ps->{_indent};
	$y = $ps->{_margintop};
	$y += $ps->{headspace} if $ps->{'head-first-only'} && $class == 2;
	$ps->{_top} = $y;
	$col = 0;
	$vsp_ignorefirst = 1;
	$col_adjust->();
    };

    my $checkspace = sub {

	# Verify that the amount of space if still available.
	# If not, perform a column break or page break.
	# Use negative argument to force a break.
	# Returns true if there was space.

	my $vsp = $_[0];
	return 1 if $vsp >= 0 && $y - $vsp >= $ps->{_bottommargin};

	if ( ++$col >= $ps->{columns}) {
	    $newpage->();
	    $vsp_ignorefirst = 0;
	}
	$col_adjust->();
	return;
    };

    my $chorddiagrams = sub {
	my ( $chords, $show, $ldisp ) = @_;
	return unless $dctl->{show};
	my @chords;
	$chords = $s->{chords}->{chords}
	  if !defined($chords) && $s->{chords};
	$show //= $dctl->{show};
	if ( $chords ) {
	    for ( @$chords ) {
		my $i = $s->{chordsinfo}->{$_};
		push( @chords, $i ) unless $i->is_nc;
	    }
	}
	return unless @chords;

	# Determine page class.
	my $class = 2;		# default
	if ( $thispage == 1 ) {
	    $class = 0;		# very first page
	}
	elsif ( $thispage == $startpage ) {
	    $class = 1;		# first of a song
	}

	# If chord diagrams are to be printed in the right column, put
	# them on the first page.
	if ( $show eq "right" && $class <= 1 ) {
	    my $vsp = $dd->vsp( undef, $ps );

	    my $v = int( ( $ps->{_margintop} - $ps->{marginbottom} ) / $vsp );
	    my $c = int( ( @chords - 1) / $v ) + 1;
	    # warn("XXX ", scalar(@chords), ", $c colums of $v max\n");
	    my $column =
	      $ps->{_marginright} - $ps->{_marginleft}
		- ($c-1) * $dd->hsp(undef,$ps)
		- $dd->hsp0(undef,$ps);

	    my $hsp = $dd->hsp(undef,$ps);
	    my $x = $x + $column - $ps->{_indent};
	    $ps->{_rightmargin} = $ps->{papersize}->[0] - $x + $ps->{columnspace};
	    $ps->{__rightmargin} = $x - $ps->{columnspace};
	    set_columns( $ps,
			 $s->{settings}->{columns} || $::config->{settings}->{columns} );
	    $col_adjust->();
	    my $y = $y;
	    while ( @chords ) {

		for ( 0..$c-1 ) {
		    last unless @chords;
		    $dd->draw( shift(@chords), $x + $_*$hsp, $y, $ps );
		}

		$y -= $vsp;
	    }
	}
	elsif ( $show eq "top" && $class <= 1 ) {

	    my $ww = ( $ps->{_marginright} - $ps->{_marginleft} );

	    # Number of diagrams, based on minimal required interspace.
	    my $h = int( ( $ww
			   # Add one interspace (cuts off right)
			   + $dd->hsp1(undef,$ps) )
			 / $dd->hsp(undef,$ps) );
	    die("ASSERT: $h should be greater than 0") unless $h > 0;

	    my $hsp = $dd->hsp(undef,$ps);
	    my $vsp = $dd->vsp( undef, $ps );
	    while ( @chords ) {
		my $x = $x - $ps->{_indent};

		for ( 0..$h-1 ) {
		    last unless @chords;
		    $dd->draw( shift(@chords), $x + $_*$hsp, $y, $ps );
		}

		$y -= $vsp;
	    }
	    $ps->{_top} = $y;
	}
	elsif ( $show eq "bottom" && $class <= 1 && $col == 0 ) {

	    my $ww = ( $ps->{_marginright} - $ps->{_marginleft} );

	    # Number of diagrams, based on minimal required interspace.
	    my $h = int( ( $ww
			   # Add one interspace (cuts off right)
			   + $dd->hsp1(undef,$ps) )
			 / $dd->hsp(undef,$ps) );
	    die("ASSERT: $h should be greater than 0") unless $h > 0;

	    my $vsp = $dd->vsp( undef, $ps );
	    my $hsp = $dd->hsp( undef, $ps );

	    my $y = $ps->{marginbottom} + (int((@chords-1)/$h) + 1) * $vsp;
	    $ps->{_bottommargin} = $y;

	    $y -= $dd->vsp1( undef, $ps ); # advance height

	    while ( @chords ) {
		my $x = $x - $ps->{_indent};
		$checkspace->($vsp);
		$pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

		for ( 1..$h ) {
		    last unless @chords;
		    $dd->draw( shift(@chords), $x, $y, $ps );
		    $x += $hsp;
		}

		$y -= $vsp;
		$pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
	    }
	}
	elsif ( $show eq "below" ) {

	    my $vsp = $dd->vsp( undef, $ps );
	    my $hsp = $dd->hsp( undef, $ps );
	    my $h = int( ( $ps->{__rightmargin}
			   - $ps->{__leftmargin}
			   + $dd->hsp1( undef, $ps ) ) / $hsp );
	    while ( @chords ) {
		$checkspace->($vsp);
		my $x = $x - $ps->{_indent};
		$pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

		for ( 1..$h ) {
		    last unless @chords;
		    $dd->draw( shift(@chords), $x, $y, $ps );
		    $x += $hsp;
		}

		$y -= $vsp;
		$pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
	    }
	}
    };

    # Get going.
    $newpage->();

    # Embed source and config for debugging;
    $pr->embed($source->{file}) if $source->{file} && $options->{debug};

    my @elts = @{$sb};
    my $elt;			# current element

    my $prev;			# previous element

    my $grid_cellwidth;
    my $grid_barwidth = 0.5 * $fonts->{chord}->{size};
    my $grid_margin;
    my $did = 0;
    my $curctx = "";

    while ( @elts ) {
	$elt = shift(@elts);

	if ( $elt->{type} eq "newpage" ) {
	    $newpage->();
	    next;
	}

	if ( $elt->{type} eq "colb" ) {
	    $checkspace->(-1);
	    next;
	}

	if ( $elt->{type} ne "set" && !$did++ ) {
	    # Insert top/left/right/bottom chord diagrams.
 	    $chorddiagrams->() unless $dctl->{show} eq "below";
	    showlayout($ps) if $ps->{showlayout} || $config->{debug}->{spacing};
	}

	if ( $elt->{type} eq "empty" ) {
	    my $y0 = $y;
	    warn("***SHOULD NOT HAPPEN1***")
	      if $s->{structure} eq "structured";
	    $vsp_ignorefirst = 0, next if $vsp_ignorefirst;
	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};
	    my $vsp = empty_vsp( $elt, $ps );
	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
	    next;
	}

	unless ( $elt->{type} =~ /^(?:control|set|ignore)$/ ) {
	    $vsp_ignorefirst = 0;
	}

	if ( $elt->{type} eq "songline"
	     or $elt->{type} eq "tabline"
	     or $elt->{type} =~ /^comment(?:_box|_italic)?$/ ) {

	    if ( $elt->{context} ne $curctx ) {
		$curctx = $elt->{context};
	    }

	    my $fonts = $ps->{fonts};
	    my $type   = $elt->{type};

	    my $ftext;
	    if ( $type eq "songline" ) {
		$ftext = $fonts->{text};
	    }
	    elsif ( $type =~ /^comment/ ) {
		$ftext = $fonts->{$type} || $fonts->{comment};
	    }
	    elsif ( $type eq "tabline" ) {
		$ftext = $fonts->{tab};
	    }

	    # Get vertical space the songline will occupy.
	    my $vsp = songline_vsp( $elt, $ps );
	    if ( $elt->{type} eq "songline" && !$elt->{indent} ) {
		my $e = wrap( $pr, $elt, $x );
		if ( @$e > 1 ) {
		    $checkspace->($vsp * scalar( @$e ));
		    $elt = shift( @$e );
		    unshift( @elts, @$e );
		}
	    }

	    # Add prespace if fit. Otherwise newpage.
	    $checkspace->($vsp);

	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

	    my $indent = 0;

	    # Handle decorations.

	    if ( $elt->{context} eq "chorus" ) {
		my $style = $ps->{chorus};
		$indent = $style->{indent};
		if ( $style->{bar}->{offset} && $style->{bar}->{width} ) {
		    my $cx = $ps->{__leftmargin} + $ps->{_indent}
		      - $style->{bar}->{offset}
			+ $indent;
		    $pr->vline( $cx, $y, $vsp,
				$style->{bar}->{width},
				$style->{bar}->{color} );
		}
		$curctx = "chorus";
		$i_tag = "" unless $config->{settings}->{choruslabels};
	    }

	    # Substitute metadata in comments.
	    if ( $elt->{type} =~ /^comment/ && !$elt->{indent} ) {
		$elt = { %$elt };
		# Flatten chords/phrases.
		if ( $elt->{chords} ) {
		    $elt->{text} = "";
		    for ( 0..$#{ $elt->{chords} } ) {
			$elt->{text} .= $elt->{chords}->[$_] . $elt->{phrases}->[$_];
		    }
		}
		$elt->{text} = fmt_subst( $s, $elt->{text} );
	    }

	    # Comment decorations.

	    $pr->setfont( $ftext );

=begin xxx

	    my $text = $elt->{text};
	    my $w = $pr->strwidth( $text );

	    # Draw background.
	    my $bgcol = $ftext->{background};
	    if ( $elt->{type} eq "comment" ) {
		# Default to grey.
		$bgcol ||= "#E5E5E5";
		# Since we default to grey, we need a way to cancel it.
		undef $bgcol if $bgcol eq "none";
	    }
	    if ( $bgcol ) {
		$pr->rectxy( $x + $indent - 2, $y + 2,
			     $x + $indent + $w + 2, $y - $vsp, 3, $bgcol );
	    }

	    # Draw box.
	    my $x0 = $x;
	    if ( $elt->{type} eq "comment_box" ) {
		$x0 += 0.25;	# add some offset for the box
		$pr->rectxy( $x0 + $indent, $y + 1,
			     $x0 + $indent + $w + 1, $y - $vsp + 1,
			     0.5, undef,
			     $ftext->{color} || $ps->{theme}->{foreground} );
	    }

=cut

	    my $r = songline( $elt, $x, $y, $ps, song => $s, indent => $indent );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    unshift( @elts, $r ) if $r;
	    next;
	}

	if ( $elt->{type} eq "chorus" ) {
	    warn("NYI: type => chorus\n");
	    my $cy = $y + vsp($ps,-2); # ####TODO????
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "songline" ) {
		    $y = songline( $e, $x, $y, $ps );
		    next;
		}
		elsif ( $e->{type} eq "empty" ) {
		    warn("***SHOULD NOT HAPPEN2***");
		    $y -= vsp($ps);
		    next;
		}
	    }
	    my $style = $ps->{chorus};
	    my $cx = $ps->{__leftmargin} - $style->{bar}->{offset};
	    $pr->vline( $cx, $cy, vsp($ps), 1, $style->{bar}->{color} );
	    $y -= vsp($ps,4); # chordii
	    next;
	}

	if ( $elt->{type} eq "verse" ) {
	    warn("NYI: type => verse\n");
	    foreach my $e ( @{$elt->{body}} ) {
		if ( $e->{type} eq "songline" ) {
		    my $h = songline_vsp( $e, $ps );
		    $checkspace->($h);
		    songline( $e, $x, $y, $ps );
		    $y -= $h;
		    next;
		}
		elsif ( $e->{type} eq "empty" ) {
		    warn("***SHOULD NOT HAPPEN2***");
		    $y -= vsp($ps);
		    next;
		}
	    }
	    $y -= vsp($ps,4);	# chordii
	    next;
	}

	if ( $elt->{type} eq "gridline" ) {

	    my $vsp = grid_vsp( $elt, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

	    my $cells = $grid_margin->[2];
	    $grid_cellwidth = ( $ps->{__rightmargin}
				- $ps->{_indent}
				- $ps->{__leftmargin}
				- ($cells)*$grid_barwidth
			      ) / $cells;
	    warn("L=", $ps->{__leftmargin},
		 ", I=", $ps->{_indent},
		 ", R=", $ps->{__rightmargin},
		 ", C=$cells, GBW=$grid_barwidth, W=", $grid_cellwidth,
		 "\n") if $config->{debug}->{spacing};

	    gridline( $elt, $x, $y,
		      $grid_cellwidth,
		      $grid_barwidth,
		      $grid_margin,
		      $ps, song => $s );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    next;
	}

	if ( $elt->{type} eq "tab" ) {
	    warn("NYI? tab\n");
	    $pr->setfont( $fonts->{tab} );
	    my $dy = $fonts->{tab}->{size};
	    foreach my $e ( @{$elt->{body}} ) {
		next unless $e->{type} eq "tabline";
		$pr->text( $e->{text}, $x, $y );
		$y -= $dy;
	    }
	    next;
	}

	if ( $elt->{type} eq "tabline" ) {

	    my $vsp = tab_vsp( $elt, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

	    songline( $elt, $x, $y, $ps );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    next;
	}

	if ( $elt->{type} eq "delegate" ) {
	    if ( $elt->{subtype} =~ /^image(?:-(\w+))?$/ ) {
		my $delegate = $1 // $elt->{delegate};
		my $pkg = __PACKAGE__;
		$pkg =~ s/::Output::\w+$/::Delegate::$delegate/;
		eval "require $pkg" || die($@);
		my $hd = $pkg->can($elt->{handler}) //
		  die("PDF: Missing delegate handler ${pkg}::$elt->{handler}\n");
		my $pw;			# available width
		if ( $ps->{columns} > 1 ) {
		    $pw = $ps->{columnoffsets}->[1]
		      - $ps->{columnoffsets}->[0]
		      - $ps->{columnspace};
		}
		else {
		    $pw = $ps->{__rightmargin} - $ps->{_leftmargin};
		}
		my $res = $hd->( $s, $pw, $elt );
		next unless $res; # assume errors have been given
		unshift( @elts, @$res );
		next;
	    }
	    die("PDF: Unsupported delegation $elt->{subtype}\n");
	}

	if ( $elt->{type} eq "image" ) {
	    # Images are slightly more complex.
	    # Only after establishing the desired height we can issue
	    # the checkspace call, and we must get $y after that.

	    my $gety = sub {
		my $h = shift;
		$checkspace->($h);
		$ps->{pr}->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
		return $y;
	    };

	    my $vsp = imageline( $elt, $x, $ps, $gety );

	    # Turn error into comment.
	    unless ( $vsp =~ /^\d/ ) {
		unshift( @elts, { %$elt,
				  type => "comment_box",
				  text => $vsp,
				} );
		redo;
	    }

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    next;
	}

	if ( $elt->{type} eq "svg" ) {
	    # We turn SVG into one (or more) XForm objects.

	    require App::Music::ChordPro::Output::PDF::SVG;
	    my $p = App::Music::ChordPro::Output::PDF::SVG->new
	      ( $ps, debug => $config->{debug}->{images} > 1 );
	    my $o = $p->process_file( $elt->{uri} );
	    warn("PDF: SVG objects: ", 0+@$o, "\n")
	      if $config->{debug}->{images} || !@$o;
	    if ( ! @$o ) {
		warn("Error in SVG embedding\n");
		next;
	    }

	    my @res;
	    for my $xo ( @$o ) {
		state $imgcnt = 0;
		my $assetid = sprintf("XFOasset%03d", $imgcnt++);
		$assets->{$assetid} = { type => "xform", data => $xo };

		push( @res,
		      { type => "xform",
			width => $xo->{width},
			height => $xo->{height},
			id  => $assetid,
			opts => { center => $elt->{opts}->{center},
				  scale => $elt->{opts}->{scale} || 1 } },
		    );
		warn("Created asset $assetid (xform, ",
		     $xo->{width}, "x", $xo->{height}, ")",
		     " scale=", $elt->{opts}->{scale} || 1,
		     " center=", $elt->{opts}->{center}//0,
		     "\n")
		  if $config->{debug}->{images};
	    }

	    unshift( @elts, @res );
	    next;
	}

	if ( $elt->{type} eq "xform" ) {
	    my $h = $elt->{height};
	    my $w = $elt->{width};
	    my $scale = $elt->{opts}->{scale};
	    my $vsp = $h * $scale;
	    $checkspace->($vsp);
	    $ps->{pr}->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    my $xo = $assets->{ $elt->{id} };
	    $pr->{pdfgfx}->object( $xo->{data}->{xo}, $x, $y-$vsp, $scale );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};

	    next;
	}

	if ( $elt->{type} eq "rechorus" ) {
	    my $t = $ps->{chorus}->{recall};
	    if ( $t->{type} !~ /^comment(?:_italic|_box)?$/ ) {
		die("Config error: Invalid value for pdf.chorus.recall.type\n");
	    }

	    if ( $t->{quote} ) {
		unshift( @elts, @{ $elt->{chorus} } ) if $elt->{chorus};
	    }

	    elsif ( $elt->{chorus}
		    && $elt->{chorus}->[0]->{type} eq "set"
		    && $elt->{chorus}->[0]->{name} eq "label" ) {
		if ( $config->{settings}->{choruslabels} ) {
		    # Use as margin label.
		    unshift( @elts, { %$elt,
				      type => $t->{type} // "comment",
				      font => $ps->{fonts}->{label},
				      text => $ps->{chorus}->{recall}->{tag},
				    } )
		      if $ps->{chorus}->{recall}->{tag} ne "";
		    unshift( @elts, { %$elt,
				      type => "set",
				      name => "label",
				      value => $elt->{chorus}->[0]->{value},
				    } );
		}
		else {
		    # Use as tag.
		    unshift( @elts, { %$elt,
				      type => $t->{type} // "comment",
				      font => $ps->{fonts}->{label},
				      text => $elt->{chorus}->[0]->{value},
				    } )
		}
		if ( $ps->{chorus}->{recall}->{choruslike} ) {
		    $elts[0]->{context} = $elts[1]->{context} = "chorus";
		}
	    }
	    elsif ( $t->{tag} && $t->{type} =~ /^comment(?:_(?:box|italic))?/ ) {
		unshift( @elts, { %$elt,
				  type => $t->{type},
				  text => $t->{tag},
				 } );
		if ( $ps->{chorus}->{recall}->{choruslike} ) {
		    $elts[0]->{context} = "chorus";
		}
	    }
	    redo;
	}

	if ( $elt->{type} eq "tocline" ) {
	    my $vsp = toc_vsp( $elt, $ps );
	    $checkspace->($vsp);
	    $pr->show_vpos( $y, 0 ) if $config->{debug}->{spacing};

	    tocline( $elt, $x, $y, $ps );

	    $y -= $vsp;
	    $pr->show_vpos( $y, 1 ) if $config->{debug}->{spacing};
	    next;
	}

	if ( $elt->{type} eq "diagrams" ) {
 	    $chorddiagrams->( $elt->{chords}, "below", $elt->{line} );
	    next;
	}

	if ( $elt->{type} eq "control" ) {
	    if ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-size$/ ) {
		if ( defined $elt->{value} ) {
		    $do_size->( $1, $elt->{value} );
		}
		else {
		    # Restore default.
		    $ps->{fonts}->{$1}->{size} =
		      $::config->{pdf}->{fonts}->{$1}->{size};
		}
	    }
	    elsif ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-font$/ ) {
		my $f = $1;
		if ( defined $elt->{value} ) {
		    if ( $elt->{value} =~ m;/;
			 ||
			 $elt->{value} =~ m;\.(ttf|otf)$;i ) {
			delete $ps->{fonts}->{$f}->{description};
			delete $ps->{fonts}->{$f}->{name};
			$ps->{fonts}->{$f}->{file} = $elt->{value};
		    }
		    elsif ( is_corefont( $elt->{value} ) ) {
			delete $ps->{fonts}->{$f}->{description};
			delete $ps->{fonts}->{$f}->{file};
			$ps->{fonts}->{$f}->{name} = $elt->{value};
		    }
		    else {
			delete $ps->{fonts}->{$f}->{file};
			delete $ps->{fonts}->{$f}->{name};
			$ps->{fonts}->{$f}->{description} = $elt->{value};
		    }
		}
		else {
		    # Restore default.
		    $ps->{fonts}->{$f} =
		      { %{ $::config->{pdf}->{fonts}->{$f} } };
		}
		$pr->init_font($f);
	    }
	    elsif ( $elt->{name} =~ /^(text|chord|grid|toc|tab)-color$/ ) {
		if ( defined $elt->{value} ) {
		    $ps->{fonts}->{$1}->{color} = $elt->{value};
		}
		else {
		    # Restore default.
		    $ps->{fonts}->{$1}->{color} =
		      $::config->{pdf}->{fonts}->{$1}->{color};
		}
	    }
	    next;
	}

	if ( $elt->{type} eq "set" ) {
	    if ( $elt->{name} eq "lyrics-only" ) {
		$lyrics_only = $elt->{value}
		  unless $lyrics_only > 1;
	    }
	    elsif ( $elt->{name} eq "gridparams" ) {
		my @v = @{ $elt->{value} };
		my $cells;
		my $bars = 8;
		$grid_margin = [ 0, 0 ];
		if ( $v[1] ) {
		    $cells = $v[0] * $v[1];
		    $bars = $v[0];
		}
		else {
		    $cells = $v[0];
		}
		$cells += $grid_margin->[0] = $v[2] if $v[2];
		$cells += $grid_margin->[1] = $v[3] if $v[3];
		$grid_margin->[2] = $cells;
		if ( $ps->{labels}->{comment} ) {
		    unshift( @elts, { %$elt,
				      type => $ps->{labels}->{comment},
				      text => $v[4],
				    } );
		    redo;
		}
		$i_tag = $v[4];
	    }
	    elsif ( $elt->{name} eq "label" ) {
		if ( $ps->{labels}->{comment} ) {
		    unshift( @elts, { %$elt,
				      type => $ps->{labels}->{comment},
				      text => $elt->{value},
				    } );
		    redo;
		}
		$i_tag = $elt->{value};
	    }
	    elsif ( $elt->{name} eq "context" ) {
		$curctx = $elt->{value};
	    }
	    # Arbitrary config values.
	    elsif ( $elt->{name} =~ /^pdf\.(.+)/ ) {
		# $ps is inuse, modify in place.
		my @k = split( /[.]/, $1 );
		my $cc = $ps;
		my $c = \$cc;
		foreach ( @k ) {
		    $c = \($$c->{$_});
		}
		$$c = $elt->{value};
	    }
	    next;
	}
	if ( $elt->{type} eq "ignore" ) {
	    next;
	}

	warn("PDF: Unhandled operator: ", $elt->{type}, " (ignored)\n");
    }
    continue {
	$prev = $elt;
    }

    if ( $dctl->{show} eq "below" ) {
	$chorddiagrams->( undef, "below");
    }

    my $pages = $thispage - $startpage + 1;
    $newpage->(), $pages++,
      if $ps->{'pagealign-songs'} > 1 && $pages % 2;

    # Now for the page headings and footers.
    $thispage = $startpage - 1;
    $s->{meta}->{pages} = [ $pages ];

    for my $p ( 1 .. $pages ) {

	$pr->openpage($ps, $thispage+1 );

	# Put titles and footer.

	# If even/odd pages, leftpage signals whether the
	# header/footer parts must be swapped.
	my $rightpage = 1;
	if ( $ps->{"even-odd-pages"} ) {
	    # Even/odd printing...
	    $rightpage = $thispage % 2 == 0;
	    # Odd/even printing...
	    $rightpage = !$rightpage if $ps->{'even-odd-pages'} < 0;
	}

	# margin* are offsets from the edges of the paper.
	# _*margin are offsets taking even/odd pages into account.
	# _margin* are physical coordinates, taking ...
	if ( $rightpage ) {
	    $ps->{_leftmargin}  = $ps->{marginleft};
	    $ps->{_marginleft}  = $ps->{marginleft};
	    $ps->{_rightmargin} = $ps->{marginright};
	    $ps->{_marginright} = $ps->{papersize}->[0] - $ps->{marginright};
	}
	else {
	    $ps->{_leftmargin}  = $ps->{marginright};
	    $ps->{_marginleft}  = $ps->{marginright};
	    $ps->{_rightmargin} = $ps->{marginleft};
	    $ps->{_marginright} = $ps->{papersize}->[0] - $ps->{marginleft};
	}
	$ps->{_marginbottom}  = $ps->{marginbottom};
	$ps->{_margintop}     = $ps->{papersize}->[1] - $ps->{margintop};
	$ps->{_bottommargin}  = $ps->{marginbottom};

	# Physical coordinates; will be adjusted to columns if needed.
	$ps->{__leftmargin}   = $ps->{_marginleft};
	$ps->{__rightmargin}  = $ps->{_marginright};
	$ps->{__topmargin}    = $ps->{_margintop};
	$ps->{__bottommargin} = $ps->{_marginbottom};

	$thispage++;
	$s->{meta}->{page} = [ $s->{page} = $opts->{roman}
			       ? roman($thispage) : $thispage ];

	# Determine page class.
	my $class = 2;		# default
	if ( $thispage == 1 ) {
	    $class = 0;		# very first page
	}
	elsif ( $thispage == $startpage ) {
	    $class = 1;		# first of a song
	}

	# Three-part title handlers.
	my $tpt = sub { tpt( $ps, $class, $_[0], $rightpage, $x, $y, $s ) };

	$x = $ps->{__leftmargin};
	if ( $ps->{headspace} ) {
	    warn("Metadata for pageheading: ", ::dump($s->{meta}), "\n")
	      if $config->{debug}->{meta};
	    $y = $ps->{_margintop} + $ps->{headspace};
	    $y -= font_bl($fonts->{title});
	    $y = $tpt->("title");
	    $y = $tpt->("subtitle");
	}

	if ( $ps->{footspace} ) {
	    $y = $ps->{marginbottom} - $ps->{footspace};
	    $tpt->("footer");
	}

    }

    return $pages;
}

sub font_bl {
    my ( $font ) = @_;
#    $font->{size} / ( 1 - $font->{fd}->{font}->descender / $font->{fd}->{font}->ascender );
    $font->{size} * $font->{fd}->{font}->ascender / 1000;
}

sub font_ul {
    my ( $font ) = @_;
    $font->{fd}->{font}->underlineposition / 1024 * $font->{size};
}

sub prlabel {
    my ( $ps, $label, $x, $y, $font) = @_;
    return if $label eq "" || $ps->{_indent} == 0;
    my $align = $ps->{labels}->{align};
    $font ||= $ps->{fonts}->{label} || $ps->{fonts}->{text};
    $font->{size} ||= $font->{fd}->{size};
    $ps->{pr}->setfont($font);	# for strwidth.
    for ( split( /\\n/, $label ) ) {
	my $label = $_;
	if ( $align eq "right" ) {
	    my $avg_space_width = $ps->{pr}->strwidth("m");
	    $ps->{pr}->text( $label,
			     $x - $avg_space_width - $ps->{pr}->strwidth($label),
			     $y, $font );
	}
	elsif ( $align =~ /^cent(?:er|re)$/ ) {
	    $ps->{pr}->text( $label,
			     $x - $ps->{_indent} + $ps->{pr}->strwidth($label)/2,
			     $y, $font );
	}
	else {
	    $ps->{pr}->text( $label,
			     $x - $ps->{_indent}, $y, $font );
	}
	$y -= $font->{size} * 1.2;
    }
}

# Propagate markup entries over the fragments so that each fragment
# is properly terminated.
sub defrag {
    my ( $frag ) = @_;
    my @stack;
    my @res;

    foreach my $f ( @$frag ) {
	my @a = split( /(<.*?>)/, $f );
	if ( @stack ) {
	    unshift( @a, @stack );
	    @stack = ();
	}
	my @r;
	foreach my $a ( @a ) {
	    if ( $a =~ m;^<\s*/\s*(\w+)(.*)>$; ) {
		my $k = $1;
		#$a =~ s/\b //g;
		#$a =~ s/ \b//g;
		if ( @stack ) {
		    if ( $stack[-1] =~ /^<\s*$k\b/ ) {
			pop(@stack);
		    }
		    else {
			warn("Markup error: \"@$frag\"\n",
			     "  Closing <$k> but $stack[-1] is open\n");
			next;
		    }
		}
		else {
		    warn("Markup error: \"@$frag\"\n",
			 "  Closing <$k> but no markup is open\n");
		    next;
		}
	    }
	    elsif ( $a =~ m;^<\s*(\w+)(.*)>$; ) {
		my $k = $1;
		push( @stack, "<$k$2>" );
	    }
	    push( @r, $a );
	}
	if ( @stack ) {
	    push( @r, map { my $t = $_;
			    $t =~ s;^<\s*(\w+).*;</$1>;;
			    $t; } reverse @stack );
	}
	push( @res, join("", @r ) );
    }
    if ( @stack ) {
	warn("Markup error: \"@$frag\"\n",
	     "  Unclosed markup: @{[ reverse @stack ]}\n" );
    }
    #warn("defrag: ", join('', @res), "\n");
    \@res;
}

sub songline {
    my ( $elt, $x, $ytop, $ps, %opts ) = @_;

    # songline draws text in boxes as follows:
    #
    # +------------------------------
    # |  C   F    G
    # |
    # +------------------------------
    # |  Lyrics text
    # +------------------------------
    #
    # Variants are:
    #
    # +------------------------------
    # |  Lyrics text (lyrics-only, or single-space and no chords)
    # +------------------------------
    #
    # Likewise comments and tabs (which may have different fonts /
    # decorations).
    #
    # And:
    #
    # +-----------------------+-------
    # |  Lyrics text          | C F G
    # +-----------------------+-------
    #
    # Note that printing text involves baselines, and that chords
    # may have a different height than lyrics.
    #
    # To find the upper/lower extents, the ratio
    #
    #  $font->ascender / $font->descender
    #
    # can be used. E.g., a font of size 16 with descender -250 and
    # ascender 750 must be drawn at 12 points under $ytop.

    my $pr    = $ps->{pr};
    my $fonts = $ps->{fonts};

    my $type   = $elt->{type};

    my $ftext;
    my $ytext;
    my $tag = $i_tag // "";
    $i_tag = undef;

    my @phrases = @{ defrag( $elt->{phrases} ) };

    if ( $type =~ /^comment/ ) {
	$ftext = $elt->{font} || $fonts->{$type} || $fonts->{comment};
	$ytext  = $ytop - font_bl($ftext);
	my $song   = $opts{song};
	$x += $opts{indent} if $opts{indent};
	$x += $elt->{indent} if $elt->{indent};
	prlabel( $ps, $tag, $x, $ytext );
	my ( $text, $ex ) = wrapsimple( $pr, $elt->{text}, $x, $ftext );
	$pr->text( $text, $x, $ytext, $ftext );
	return $ex ne "" ? { %$elt, indent => $pr->strwidth("x"), text => $ex } : undef;
    }
    if ( $type eq "tabline" ) {
	$ftext = $fonts->{tab};
	$ytext  = $ytop - font_bl($ftext);
	$x += $opts{indent} if $opts{indent};
	prlabel( $ps, $tag, $x, $ytext );
	$pr->text( $elt->{text}, $x, $ytext, $ftext, undef, "no markup" );
	return;
    }

    # assert $type eq "songline";
    $ftext = $fonts->{text};
    $ytext  = $ytop - font_bl($ftext); # unless lyrics AND chords

    my $fchord = $fonts->{chord};
    my $ychord = $ytop - font_bl($fchord);

    # Just print the lyrics if no chords.
    if ( $lyrics_only
	 or
	 $suppress_empty_chordsline && !has_visible_chords($elt)
       ) {
	my $x = $x;
	$x += $opts{indent} if $opts{indent};
	$x += $elt->{indent} if $elt->{indent};
	prlabel( $ps, $tag, $x, $ytext );
	my ( $text, $ex ) = wrapsimple( $pr, join( "", @phrases ),
					$x, $ftext );
	$pr->text( $text, $x, $ytext, $ftext );
	return $ex ne "" ? { %$elt, indent => $pr->strwidth("x"), phrases => [$ex] } : undef;
    }

    if ( $chordscol || $inlinechords ) {
	$ytext  = $ychord if $ytext  > $ychord;
	$ychord = $ytext;
    }
    elsif ( $chordsunder ) {
	( $ytext, $ychord ) = ( $ychord, $ytext );
	# Adjust lyrics baseline for the chords.
	$ychord -= $ps->{fonts}->{text}->{size}
	  * $ps->{spacing}->{lyrics};
    }
    else {
	# Adjust lyrics baseline for the chords.
	$ytext -= $ps->{fonts}->{chord}->{size}
	          * $ps->{spacing}->{chords};
    }

    $elt->{chords} //= [ '' ];
    $x += $elt->{indent} if $elt->{indent};

    my $chordsx = $x;
    $chordsx += $ps->{chordscolumn} if $chordscol;
    if ( $chordsx < 0 ) {	#### EXPERIMENTAL
	($x, $chordsx) = (-$chordsx, $x);
    }
    $x += $opts{indent} if $opts{indent};

    # How to embed the chords.
    if ( $inlinechords ) {
	$inlinechords = '[%s]' unless $inlinechords =~ /%[cs]/;
	$ychord = $ytext;
    }

    my @chords;
    my $n = $#{$elt->{chords}};
    foreach my $i ( 0 .. $n ) {

	my $chord = $elt->{chords}->[$i];
	my $phrase = $phrases[$i];

	if ( $chordscol && $chord ne "" ) {

	    if ( $chordscapo ) {
		$pr->text(fmt_subst( $opts{song}, $ps->{capoheading} ),
			  $chordsx,
			  $ytext + $ftext->{size} *
			      $ps->{spacing}->{chords},
			  $fonts->{chord} );
		undef $chordscapo;
	    }

	    # Underline the first word of the phrase, to indicate
	    # the actual chord position. Skip leading non-letters.
	    $phrase = " " if $phrase eq "";
	    my ( $pre, $word, $rest ) = $phrase =~ /^(\W+)?(\w+)(.+)?$/;
	    my $ulstart = $x;
	    $ulstart += $pr->strwidth($pre) if defined($pre);
	    my $w = $pr->strwidth( $word//" ", $ftext );
	    # Avoid running together of syllables.
	    $w *= 0.75 unless defined($rest);

	    $pr->hline( $ulstart, $ytext + font_ul($ftext), $w,
			0.25, $ps->{theme}->{foreground} );

	    # Print the text.
	    prlabel( $ps, $tag, $x, $ytext );
	    $tag = "";
	    $x = $pr->text( $phrase, $x, $ytext, $ftext );

	    # Collect chords to be printed in the side column.
	    my $info = $opts{song}->{chordsinfo}->{$chord};
	    croak("Missing info for chord $chord") unless $info;
	    $chord = $info->chord_display;
	    push(@chords, $chord);
	}
	else {
	    my $xt0 = $x;
	    my $font = $fchord;
	    if ( $chord ne '' ) {
		my $info = $opts{song}->{chordsinfo}->{$chord};
		Carp::croak("Missing info for chord $chord") unless $info;
		$chord = $info->chord_display;
		my $dp = $chord . " ";
		if ( $info->is_annotation ) {
		    $font = $fonts->{annotation};
		    ( $dp = $inlineannots ) =~ s/%[cs]/$chord/g
		      if $inlinechords;
		}
		elsif ( $inlinechords ) {
		    ( $dp = $inlinechords ) =~ s/%[cs]/$chord/g;
		}
		$xt0 = $pr->text( $dp, $x, $ychord, $font );
	    }

	    # Do not indent chorus labels (issue #81).
	    prlabel( $ps, $tag, $x-$opts{indent}, $ytext );
	    $tag = "";
	    if ( $inlinechords ) {
		$x = $pr->text( $phrase, $xt0, $ytext, $ftext );
	    }
	    else {
		my $xt1;
		if ( $phrase =~ /^\s+$/ ) {
		    $xt1 = $xt0 + length($phrase) * $pr->strwidth(" ",$ftext);
#		    $xt1 = $pr->text( "n" x length($phrase), $xt0, $ytext, $ftext );
		}
		else {
		    $xt1 = $pr->text( $phrase, $x, $ytext, $ftext );
		}
		if ( $xt0 > $xt1 ) { # chord is wider
		    # Do we need to insert a split marker?
		    if ( $i < $n
			 && demarkup($phrase) !~ /\s$/
			 && demarkup($phrases[$i+1]) !~ /^\s/
			 # And do we have one?
			 && ( my $marker = $ps->{'split-marker'} ) ) {

			# Marker has 3 parts: start, repeat, and final.
			# final is always printed, last.
			# start is printed if there is enough room.
			# repeat is printed repeatedly to fill the rest.
			$marker = [ $marker, "", "" ]
			  unless UNIVERSAL::isa( $marker, 'ARRAY' );

			# Reserve space for final.
			my $w = 0;
			$pr->setfont($ftext);
			$w = $pr->strwidth($marker->[2]) if $marker->[2];
			$xt0 -= $w;
			# start or repeat (if no start).
			my $m = $marker->[0] || $marker->[1];
			$x = $xt1;
			$x = $xt0 unless $m;
			while ( $x < $xt0 ) {
			    $x = $pr->text( $m, $x, $ytext, $ftext );
			    # After the first, use repeat.
			    $m = $marker->[1];
			    $x = $xt0, last unless $m;
			}
			# Print final.
			if ( $w ) {
			    $x = $pr->text( $marker->[2], $x, $ytext, $ftext );
			}
		    }
		    # Adjust the position for the chord and spit marker width.
		    $x = $xt0 if $xt0 > $x;
		}
		else {
		    # Use lyrics width.
		    $x = $xt1;
		}
	    }
	}
    }

    # Print side column with chords, if any.
    $pr->text( join(",  ", @chords),
	       $chordsx, $ychord, $fchord )
      if @chords;

    return;
}

sub is_bar {
    exists( $_[0]->{class} ) && $_[0]->{class} eq "bar";
}

sub gridline {
    my ( $elt, $x, $y, $cellwidth, $barwidth, $margin, $ps, %opts ) = @_;

    # Grid context.

    my $pr = $ps->{pr};
    my $fonts = $ps->{fonts};

    my $tag = $i_tag // "";
    $i_tag = undef;

    # Use the chords font for the chords, and for the symbols size.
    my $fchord = { %{ $fonts->{grid} || $fonts->{chord} } };
    delete($fchord->{background});
    $y -= font_bl($fchord);

    prlabel( $ps, $tag, $x, $y );

    $x += $barwidth;
    $cellwidth += $barwidth;

    $elt->{tokens} //= [ {} ];

    my $firstbar;
    my $lastbar;
    foreach my $i ( 0 .. $#{ $elt->{tokens} } ) {
	next unless is_bar( $elt->{tokens}->[$i] );
	$lastbar = $i;
	$firstbar //= $i;
    }

    my $prevbar = -1;
    my @tokens = @{ $elt->{tokens} };
    my $t;

    if ( $margin->[0] ) {
	$x -= $barwidth;
	if ( $elt->{margin} ) {
	    my $t = $elt->{margin};
	    if ( $t->{chords} ) {
		$t->{text} = "";
		for ( 0..$#{ $t->{chords} } ) {
		    $t->{text} .= $t->{chords}->[$_] . $t->{phrases}->[$_];
		}
	    }
	    $pr->text( $t->{text}, $x, $y, $fonts->{comment} );
	}
	$x += $margin->[0] * $cellwidth + $barwidth;
    }

    my $ctl = $pr->{ps}->{grids}->{cellbar};
    my $needcell = $ctl->{width};
    foreach my $i ( 0 .. $#tokens ) {
	my $token = $tokens[$i];
	my $sz = $fchord->{size};

	if ( $token->{class} eq "bar" ) {
	    $x -= $barwidth;
	    $t = $token->{symbol};
	    if ( 0 ) {
		$t = "{" if $t eq "|:";
		$t = "}" if $t eq ":|";
		$t = "}{" if $t eq ":|:";
	    }
	    else {
		$t = "|:" if $t eq "{";
		$t = ":|" if $t eq "}";
		$t = ":|:" if $t eq "}{";
	    }

	    my $lcr = -1;	# left, center, right
	    $lcr = 0 if $i > $firstbar;
	    $lcr = 1 if $i == $lastbar;

	    if ( $t eq "|" ) {
		pr_barline( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq "||" ) {
		pr_dbarline( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq "|:" ) {
		pr_rptstart( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq ":|" ) {
		pr_rptend( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq ":|:" ) {
		pr_rptendstart( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq "|." ) {
		pr_endline( $x, $y, $lcr, $sz, $pr );
	    }
	    elsif ( $t eq " %" ) { # repeat2Bars
		pr_repeat( $x+$sz/2, $y, 0, $sz, $pr );
	    }
	    else {
		die($t);	# can't happen
	    }
	    $x += $barwidth;
	    $prevbar = $i;
	    $needcell = 0;
	    next;
	}

	if ( $token->{class} eq "repeat2" ) {
	    # For repeat2Bars, change the next bar line to pseudo-bar.
	    my $k = $prevbar + 1;
	    while ( $k <= $#tokens
		    && !is_bar($tokens[$k]) ) {
		$k++;
	    }
	    $tokens[$k] = { symbol => " %", class => "bar" };
	    $x += $cellwidth;
	    $needcell = 0;
	    next;
	}

	pr_cellline( $x-$barwidth, $y, 0, $sz, $ctl->{width},
		     $pr->_fgcolor($ctl->{color}), $pr )
	  if $needcell;
	$needcell = $ctl->{width};

	if ( exists $token->{chord} ) {
	    my $t = $token->{chord};
	    my $i = $opts{song}->{chordsinfo}->{$t};
	    $t = $i->chord_display if $i;
	    $pr->text( $t, $x, $y, $fchord )
	      unless $token eq ".";
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "slash" ) {
	    $pr->text( "/", $x, $y, $fchord );
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "space" ) {
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "repeat1" ) {
	    $t = $token->{symbol};
	    my $k = $prevbar + 1;
	    while ( $k <= $#tokens
		    && !is_bar($tokens[$k]) ) {
		$k++;
	    }
	    pr_repeat( $x + ($k - $prevbar - 1)*$cellwidth/2, $y,
		       0, $fchord->{size}, $pr );
	    $x += $cellwidth;
	}
	if ( $x > $ps->{papersize}->[0] ) {
	    # This should be signalled by the parser.
	    # warn("PDF: Too few cells for content\n");
	    last;
	}
    }

    if ( $margin->[1] && $elt->{comment} ) {
	my $t = $elt->{comment};
	if ( $t->{chords} ) {
	    $t->{text} = "";
	    for ( 0..$#{ $t->{chords} } ) {
		$t->{text} .= $t->{chords}->[$_] . $t->{phrases}->[$_];
	    }
	}
	$pr->text( " " . $t->{text}, $x, $y, $fonts->{comment} );
    }
}

sub pr_cellline {
    my ( $x, $y, $lcr, $sz, $w, $col, $pr ) = @_;
    $x -= $w / 2 * ($lcr + 1);
    $pr->vline( $x, $y+0.9*$sz, $sz, $w, $col );
}

sub pr_barline {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = $w
    $x -= $w / 2 * ($lcr + 1);
    $pr->vline( $x, $y+0.9*$sz, $sz, $w );
}

sub pr_dbarline {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 1.5 * $w * ($lcr + 1);
    $pr->vline( $x, $y+0.9*$sz, $sz, $w );
    $x += 2 * $w;
    $pr->vline( $x, $y+0.9*$sz, $sz, $w );
}

sub pr_rptstart {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 1.5 * $w * ($lcr + 1);
    $pr->vline( $x, $y+0.9*$sz, $sz, $w  );
    $x += 2 * $w;
    $y += 0.55 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w );
    $y -= 0.4 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w );
}

sub pr_rptend {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 1.5 * $w * ($lcr + 1);
    $pr->vline( $x + 2*$w, $y+0.9*$sz, $sz, $w );
    $y += 0.55 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w );
    $y -= 0.4 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w );
}

sub pr_rptendstart {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 5 * $w
    $x -= 2.5 * $w * ($lcr + 1);
    $pr->vline( $x + 2*$w, $y+0.9*$sz, $sz, $w );
    $y += 0.55 * $sz;
    $pr->line( $x,      $y, $x     , $y+$w, $w );
    $pr->line( $x+4*$w, $y, $x+4*$w, $y+$w, $w );
    $y -= 0.4 * $sz;
    $pr->line( $x,      $y, $x,      $y+$w, $w );
    $pr->line( $x+4*$w, $y, $x+4*$w, $y+$w, $w );
}

sub pr_repeat {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 3;		# glyph width = 3 * $w
    $x -= 1.5 * $w * ($lcr + 1);
    my $lw = $sz / 10;
    $x -= $w / 2;
    $pr->line( $x, $y+0.2*$sz, $x + $w, $y+0.7*$sz, $lw );
    $pr->line( $x, $y+0.6*$sz, $x + 0.07*$sz , $y+0.7*$sz, $lw );
    $x += $w;
    $pr->line( $x - 0.05*$sz, $y+0.2*$sz, $x + 0.02*$sz, $y+0.3*$sz, $lw );
}

sub pr_endline {
    my ( $x, $y, $lcr, $sz, $pr ) = @_;
    my $w = $sz / 10;		# glyph width = 2 * $w
    $x -= 0.75 * $w * ($lcr + 1);
    $pr->vline( $x, $y+0.85*$sz, 0.9*$sz, 2*$w );
}

sub imageline_vsp {
}

sub imageline {
    my ( $elt, $x, $ps, $gety ) = @_;

    my $opts = $elt->{opts};
    my $pr = $ps->{pr};

    if ( $elt->{uri} =~ /^id=(.+)/ ) {
	return "Unknown asset: id=$1"
	  unless exists( $assets->{$1} );
    }
    elsif ( ! -s $elt->{uri} ) {
	return "$!: " . $elt->{uri};
    }

    warn("get_image ", $elt->{uri}, "\n") if $config->{debug}->{images};
    my $img = eval { $pr->get_image($elt) };
    unless ( $img ) {
	warn($@);
	return "Unhandled image type: " . $elt->{uri};
    }

    # Available width and height.
    my $pw;
    if ( $ps->{columns} > 1 ) {
	$pw = $ps->{columnoffsets}->[1]
	  - $ps->{columnoffsets}->[0]
	    - $ps->{columnspace};
    }
    else {
	$pw = $ps->{__rightmargin} - $ps->{_leftmargin};
    }

    my $ph = $ps->{_margintop} - $ps->{_marginbottom};

    my $scale = 1;
    my ( $w, $h ) = ( $opts->{width}  || $img->width,
		      $opts->{height} || $img->height );
    if ( defined $opts->{scale} ) {
	$scale = $opts->{scale} || 1;
    }
    else {
	if ( $w > $pw ) {
	    $scale = $pw / $w;
	}
	if ( $h*$scale > $ph ) {
	    $scale = $ph / $h;
	}
    }
    warn("Image scale: $scale\n") if $config->{debug}->{images};
    $h *= $scale;
    $w *= $scale;
    if ( $opts->{center} ) {
	$x += ($pw - $w) / 2;
	warn("Image center: $_[1] -> $x\n") if $config->{debug}->{images};
    }

    my $y = $gety->($h);	# may have been changed by checkspace
    if ( defined ( my $tag = $i_tag // $opts->{label} ) ) {
	$i_tag = undef;
    	my $ftext = $ps->{fonts}->{comment};
	my $ytext  = $y - font_bl($ftext);
	prlabel( $ps, $tag, $x, $ytext );
    }

    warn("add_image\n") if $config->{debug}->{images};
    $pr->add_image( $img, $x, $y, $w, $h, $opts->{border} || 0 );
    warn("done\n") if $config->{debug}->{images};

    return $h;			# vertical size
}

sub tocline {
    my ( $elt, $x, $y, $ps ) = @_;

    my $pr = $ps->{pr};
    my $fonts = $ps->{fonts};
    my $y0 = $y;
    my $ftoc = $fonts->{toc};
    $y -= font_bl($ftoc);
    $pr->setfont($ftoc);
    my $tpl = $elt->{title};
    my $vsp;
    for ( split( /\\n/, $tpl ) ) {
	$ps->{pr}->text( $_, $x, $y );
	unless ($vsp) {
	    my $p = $elt->{pageno};
	    $ps->{pr}->text( $p, $ps->{__rightmargin} - $pr->strwidth($p), $y );
	    $vsp = _vsp("toc", $ps);
	}
	$y -= $vsp;
    }
    my $ann = $pr->{pdfpage}->annotation;
    $ann->link($elt->{page});
    $ann->rect( $ps->{_leftmargin}, $y0 - $ftoc->{size} * $ps->{spacing}->{toc},
		$ps->{__rightmargin}, $y0 );
    ####CHECK MARGIN RIGHT
}

sub has_visible_chords {
    my ( $elt ) = @_;
    if ( $elt->{chords} ) {
	for ( @{ $elt->{chords} } ) {
	    next if defined;
	    warn("Undefined chord in chords: ", ::dump($elt) );
	}
	return join( "", @{ $elt->{chords} } ) =~ /\S/;
    }
    return;
}

sub has_visible_text {
    my ( $elt ) = @_;
    $elt->{phrases} && join( "", @{ $elt->{phrases} } ) =~ /\S/;
}

sub songline_vsp {
    my ( $elt, $ps ) = @_;

    # Calculate the vertical span of this songline.
    my $fonts = $ps->{fonts};

    if ( $elt->{type} =~ /^comment/ ) {
	my $ftext = $fonts->{$elt->{type}} || $fonts->{comment};
	return $ftext->{size} * $ps->{spacing}->{lyrics};
    }
    if ( $elt->{type} eq "tabline" ) {
	my $ftext = $fonts->{tab};
	return $ftext->{size} * $ps->{spacing}->{tab};
    }

    # Vertical span of the lyrics and chords.
#    my $vsp = $fonts->{text}->{size} * $ps->{spacing}->{lyrics};
    my $vsp = text_vsp( $elt, $ps );
    my $csp = $fonts->{chord}->{size} * $ps->{spacing}->{chords};

    return $vsp if $lyrics_only || $chordscol;

    return $vsp if $suppress_empty_chordsline && ! has_visible_chords($elt);

    # No text printing if no text.
    $vsp = 0 if $suppress_empty_lyricsline && join( "", @{ $elt->{phrases} } ) !~ /\S/;

    if ( $inlinechords ) {
	$vsp = $csp if $csp > $vsp;
    }
    else {
	# We must show chords above lyrics, so add chords span.
	$vsp += $csp;
    }
    return $vsp;
}

sub _vsp {
    my ( $eltype, $ps, $sptype ) = @_;
    $sptype ||= $eltype;

    # Calculate the vertical span of this element.

    my $font = $ps->{fonts}->{$eltype};
    $font->{size} * $ps->{spacing}->{$sptype};
}

sub empty_vsp { _vsp( "empty", $_[1] ) }
sub grid_vsp  { _vsp( "grid",  $_[1] ) }
sub tab_vsp   { _vsp( "tab",   $_[1] ) }

sub toc_vsp   {
    my $vsp = _vsp( "toc",   $_[1] );
    my $tpl = $_[0]->{title};
    my $ret = $vsp;
    while ( $tpl =~ /\\n/g ) {
	$ret += $vsp;
    }
    return $ret;
}

sub text_vsp {
    my ( $elt, $ps ) = @_;

    my $layout = Text::Layout->new( $ps->{pr}->{pdf} );
    $layout->set_font_description( $ps->{fonts}->{text}->{fd} );
    $layout->set_font_size( $ps->{fonts}->{text}->{size} );
    #warn("vsp: ".join( "", @{$elt->{phrases}} )."\n");
    $layout->set_markup( join( "", @{$elt->{phrases}} ) );
    my $vsp = $layout->get_size->{height} * $ps->{spacing}->{lyrics};
    #warn("vsp $vsp \"", $layout->get_text, "\"\n");
    # Calculate the vertical span of this line.

    _vsp( "text", $ps, "lyrics" );
}

sub set_columns {
    my ( $ps, $cols ) = @_;
    unless ( $cols ) {
	$cols = $ps->{columns} ||= 1;
    }
    else {
	$ps->{columns} = $cols ||= 1;
    }

    my $w = $ps->{papersize}->[0]
      - $ps->{_leftmargin} - $ps->{_rightmargin};

    $ps->{columnoffsets} = [ 0 ];
     push( @{ $ps->{columnoffsets} }, $w ), return unless $cols > 1;

    my $d = ( $w - ( $cols - 1 ) * $ps->{columnspace} ) / $cols;
    $d += $ps->{columnspace};
    for ( 1 .. $cols-1 ) {
	push( @{ $ps->{columnoffsets} }, $_ * $d );
    }
    push( @{ $ps->{columnoffsets} }, $w );
}

sub showlayout {
    my ( $ps ) = @_;
    my $pr = $ps->{pr};
    my $col = "red";
    my $lw = 0.5;
    my $font = $ps->{fonts}->{grid};

    my $mr = $ps->{_rightmargin};
    my $ml = $ps->{_leftmargin};

    $pr->rectxy( $ml,
		 $ps->{marginbottom},
		 $ps->{papersize}->[0]-$mr,
		 $ps->{papersize}->[1]-$ps->{margintop},
		 $lw, undef, $col);

    my $fsz = 7;
    my $ptop = $ps->{papersize}->[1]-$ps->{margintop}+$fsz-3;
    $pr->setfont($font,$fsz);
    $pr->text( "<span color='red'>$ml</span>",
	       $ml, $ptop, $font, $fsz );
    my $t = $ps->{papersize}->[0]-$mr;
    $pr->text( "<span color='red'>$t</span>",
	       $ps->{papersize}->[0]-$mr-$pr->strwidth("$mr"),
	       $ptop, $font, $fsz );
    $t = $ps->{papersize}->[1]-$ps->{margintop};
    $pr->text( "<span color='red'>$t  </span>",
	       $ml-$pr->strwidth("$t  "),
	       $ps->{papersize}->[1]-$ps->{margintop}-2,
	       $font, $fsz );
    $t = $ps->{marginbottom};
    $pr->text( "<span color='red'>$t  </span>",
	       $ml-$pr->strwidth("$t  "),
	       $ps->{marginbottom}-2,
	       $font, $fsz );
    my @a = ( $ml,
	      $ps->{papersize}->[1]-$ps->{margintop}+$ps->{headspace},
	      $ps->{papersize}->[0]-$ml-$mr,
	      $lw, $col );
    $pr->hline(@a);
    $t = $a[1];
    $pr->text( "<span color='red'>$t  </span>",
	       $ml-$pr->strwidth("$t  "),
	       $a[1]-2,
	       $font, $fsz );
    $a[1] = $ps->{marginbottom}-$ps->{footspace};
    $pr->hline(@a);
    $t = $a[1];
    $pr->text( "<span color='red'>$t  </span>",
	       $ml-$pr->strwidth("$t  "),
	       $a[1]-2,
	       $font, $fsz );

    my @off = @{ $ps->{columnoffsets} };
    pop(@off);
    @off = ( $ps->{chordscolumn} ) if $chordscol;
    @a = ( undef,
	   $ps->{marginbottom},
	   $ps->{margintop}-$ps->{papersize}->[1]+$ps->{marginbottom},
	   $lw, $col );
    foreach my $i ( 0 .. @off-1 ) {
	next unless $off[$i];
	$a[0] = $ml + $off[$i];
	$pr->text( "<span color='red'>$a[0]</span>",
		   $a[0] - $pr->strwidth($a[0])/2, $ptop, $font, $fsz );
	$pr->vline(@a);
	$a[0] = $ml + $off[$i] - $ps->{columnspace};
	$pr->text( "<span color='red'>$a[0]</span>",
		   $a[0] - $pr->strwidth($a[0])/2, $ptop, $font, $fsz );
	$pr->vline(@a);
	if ( $ps->{_indent} ) {
	    $a[0] = $ml + $off[$i] + $ps->{_indent};
	    $pr->vline(@a);
	}
    }
    if ( $ps->{_indent} ) {
	$a[0] = $ml + $ps->{_indent};
	$pr->vline(@a);
    }
}

sub configurator {
    my ( $cfg ) = @_;

    # From here, we're mainly dealing with the PDF settings.
    my $pdf   = $cfg->{pdf};

    # Get PDF library.
    unless ( $pdfapi ) {
	if ( $pdf->{library} ) {
	    unless ( eval( "require " . $pdf->{library} ) ) {
		die("Missing ", $pdf->{library}, " library\n");
	    }
	    $pdfapi = $pdf->{library};
	}
	else {
	    for ( qw( PDF::Builder PDF::API2 ) ) {
		eval "require $_" or next;
		$pdfapi = $_;
		last;
	    }
	}
	die("Missing PDF library\n") unless $pdfapi;
    }

    my $fonts = $pdf->{fonts};

    # Apply Chordii command line compatibility.

    # Command line only takes text and chord fonts.
    for my $type ( qw( text chord ) ) {
	for ( $options->{"$type-font"} ) {
	    next unless $_;
	    if ( m;/; ) {
		$fonts->{$type}->{file} = $_;
	    }
	    else {
		die("Config error: \"$_\" is not a built-in font\n")
		  unless is_corefont($_);
		$fonts->{$type}->{name} = $_;
	    }
	}
	for ( $options->{"$type-size"} ) {
	    $fonts->{$type}->{size} = $_ if $_;
	}
    }

    for ( $options->{"page-size"} ) {
	$pdf->{papersize} = $_ if $_;
    }
    for ( $options->{"vertical-space"} ) {
	next unless $_;
	$pdf->{spacing}->{lyrics} +=
	  $_ / $fonts->{text}->{size};
    }
    for ( $options->{"lyrics-only"} ) {
	next unless defined $_;
	# If set on the command line, it cannot be overridden
	# by configs and {controls}.
	$pdf->{"lyrics-only"} = 2 * $_;
    }
    for ( $options->{"single-space"} ) {
	next unless defined $_;
	$pdf->{"suppress-empty-chords"} = $_;
    }
    for ( $options->{"even-pages-number-left"} ) {
	next unless defined $_;
	$pdf->{"even-pages-number-left"} = $_;
    }

    # Chord grid width.
    if ( $options->{'chord-grid-size'} ) {
	# Note that this is legacy, so for the chord diagrams only,
	$pdf->{diagrams}->{width} =
	  $pdf->{diagrams}->{height} =
	    $options->{'chord-grid-size'} /
	      @{ $config->{notes}->{sharps} };
    }

    # Map papersize name to [ width, height ].
    unless ( eval { $pdf->{papersize}->[0] } ) {
	eval "require ${pdfapi}::Resource::PaperSizes";
	my %ps = "${pdfapi}::Resource::PaperSizes"->get_paper_sizes;
	die("Unhandled paper size: ", $pdf->{papersize}, "\n")
	  unless exists $ps{lc $pdf->{papersize}};
	$pdf->{papersize} = $ps{lc $pdf->{papersize}}
    }

    # Merge properties for derived fonts.
    my $fm = sub {
	my ( $font, $def ) = @_;
	for ( keys %{ $fonts->{$def} } ) {
	    next if /^(?:background|frame)$/;
	    $fonts->{$font}->{$_} //= $fonts->{$def}->{$_};
	}
    };
    $fm->( qw( subtitle       text     ) );
    $fm->( qw( comment_italic text     ) );
    $fm->( qw( comment_box    text     ) );
    $fm->( qw( comment        text     ) );
    $fm->( qw( annotation     chord    ) );
    $fm->( qw( toc            text     ) );
    $fm->( qw( empty          text     ) );
    $fm->( qw( grid           chord    ) );
    $fm->( qw( grid_margin    comment  ) );
    $fm->( qw( diagram        comment  ) );
    $fm->( qw( diagram_base   comment  ) );

    # Default footer is small subtitle.
    $fonts->{footer}->{size} //= 0.6 * $fonts->{subtitle}->{size};
    $fm->( qw( footer         subtitle ) );

    # This one is fixed.
    $fonts->{chordfingers}->{title} = "ChordProSymbols.ttf";
}

# Get a format string for a given page class and type.
# Page classes have fallbacks.
sub get_format {
    my ( $ps, $class, $type ) = @_;
    my @classes = qw( first title default );
    for ( my $i = $class; $i < @classes; $i++ ) {
	next unless exists($ps->{formats}->{$classes[$i]}->{$type});
	return $ps->{formats}->{$classes[$i]}->{$type};
    }
    return;
}

# Three-part titles.
# Note: baseline printing.
sub tpt {
    my ( $ps, $class, $type, $rightpage, $x, $y, $s ) = @_;
    my $fmt = get_format( $ps, $class, $type );
    return unless $fmt;
    if ( @$fmt == 3 && ref($fmt->[0]) ne 'ARRAY' ) {
	$fmt = [ $fmt ];
    }
    # @fmt = ( left-fmt, center-fmt, right-fmt )
    my $pr = $ps->{pr};
    my $font = $ps->{fonts}->{$type};

    my $havefont;
    my $rm = $ps->{papersize}->[0] - $ps->{_rightmargin};

    for my $fmt ( @$fmt ) {
	if ( @$fmt % 3 ) {
	    die("ASSERT: " . scalar(@$fmt)," part format $class $type");
	}

	my @fmt = @$fmt;
	@fmt = @fmt[2,1,0] unless $rightpage; # swap

	# Left part. Easiest.
	if ( $fmt[0] ) {
	    my $t = fmt_subst( $s, $fmt[0] );
	    if ( $t ne "" ) {
		$pr->setfont($font) unless $havefont++;
		$pr->text( $t, $x, $y );
	    }
	}

	# Center part.
	if ( $fmt[1] ) {
	    my $t = fmt_subst( $s, $fmt[1] );
	    if ( $t ne "" ) {
		$pr->setfont($font) unless $havefont++;
		$pr->text( $t, ($rm+$x-$pr->strwidth($t))/2, $y );
	    }
	}

	# Right part.
	if ( $fmt[2] ) {
	    my $t = fmt_subst( $s, $fmt[2] );
	    if ( $t ne "" ) {
		$pr->setfont($font) unless $havefont++;
		$pr->text( $t, $rm-$pr->strwidth($t), $y );
	    }
	}

	$y -= $font->{size} * ($ps->{spacing}->{$type} || 1);
    }

    # Return updated baseline.
    return $y;
}

sub wrap {
    my ( $pr, $elt, $x ) = @_;
    my $res = [];
    my @chords  = @{ $elt->{chords} // [] };
    my @phrases = @{ defrag( $elt->{phrases} // [] ) };
    my @rchords;
    my @rphrases;
    my $m = $pr->{ps}->{__rightmargin};
    #warn("WRAP x=$x rm=$m w=", $m - $x, "\n");

    while ( @chords ) {
	my $chord  = shift(@chords);
	my $phrase = shift(@phrases) // "";
	my $ex = "";
	#warn("wrap x=$x rm=$m w=", $m - $x, " ch=$chord, ph=$phrase\n");

	if ( @rchords ) {
	    # Does the chord fit?
	    my $font = $pr->{ps}->{fonts}->{chord};
	    $pr->setfont($font);
	    my $w = $pr->strwidth($chord);
	    if ( $w > $m - $x ) {
		# Nope. Move to overflow.
		$ex = $phrase;
	    }
	}

	if ( $ex eq "" ) {
	    # Do lyrics fit?
	    my $font = $pr->{ps}->{fonts}->{text};
	    $pr->setfont($font);
	    my $ph;
	    ( $ph, $ex ) = $pr->wrap( $phrase, $m - $x );
	    # If it doesn not fit, it is usually a case a bad luck.
	    # However, we may be able to move to overflow.
	    my $w = $pr->strwidth($ph);
	    if ( $w > $m - $x && @rchords > 1 ) {
		$ex = $phrase;
	    }
	    else {
		push( @rchords, $chord );
		push( @rphrases, $ph );
		$chord = '';
	    }
	    $x += $w;
	}

	if ( $ex ne "" ) {	# overflow
	    if ( $rphrases[-1] =~ /[[:alpha:]]$/
		 && $ex =~ /^[[:alpha:]]/
		 && $chord ne '' ) {
		$rphrases[-1] .= "-";
	    }
	    unshift( @chords, $chord );
	    unshift( @phrases, $ex );
	    push( @$res,
		  { %$elt, chords => [@rchords], phrases => [@rphrases] } );
	    $x = $_[2] + $pr->strwidth("x");
	    $res->[-1]->{indent} = $pr->strwidth("x") if @$res > 1;
	    @rchords = ();
	    @rphrases = ();
	}
    }
    push( @$res, { %$elt, chords => \@rchords, phrases => \@rphrases } );
    $res->[-1]->{indent} = $pr->strwidth("x") if @$res > 1;
    return $res;
}

sub wrapsimple {
    my ( $pr, $text, $x, $font ) = @_;
    return ( "", "" ) unless length($text);

    $font ||= $pr->{font};
    $pr->setfont($font);
    $pr->wrap( $text, $pr->{ps}->{__rightmargin} - $x );
}

my %corefonts = map { $_ => 1 }
  ( "times-roman",
    "times-bold",
    "times-italic",
    "times-bolditalic",
    "helvetica",
    "helvetica-bold",
    "helvetica-oblique",
    "helvetica-boldoblique",
    "courier",
    "courier-bold",
    "courier-oblique",
    "courier-boldoblique",
    "zapfdingbats",
    "georgia",
    "georgia,bold",
    "georgia,italic",
    "georgia,bolditalic",
    "verdana",
    "verdana,bold",
    "verdana,italic",
    "verdana,bolditalic",
    "webdings",
    "wingdings" );

sub is_corefont {
    $corefonts{lc $_[0]};
}

sub _dump {
    return unless $config->{debug}->{fonts};
    my ( $ps ) = @_;
    print STDERR ("== Font family map\n");
    Text::Layout::FontConfig->new->_dump if $verbose;
    print STDERR ("== Font associations\n");
    foreach my $f ( sort keys( %{$ps->{fonts}} ) ) {
	printf STDERR ("%-15s  %s\n", $f,
		       eval { $ps->{fonts}->{$f}->{description} } ||
		       eval { $ps->{fonts}->{$f}->{file} } ||
		       eval { "[".$ps->{fonts}->{$f}->{name}."]" } ||
		       "[]"
		      );
    }
}

1;

