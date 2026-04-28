#! perl

package main;

use utf8;
our $config;
our $options;

our $ps;
our $pr;
our $dw;

package ChordPro::Output::PDF;

use strict;
use warnings;
use File::Temp ();
use Ref::Util qw(is_hashref is_arrayref is_coderef);
use Carp;
use ChordPro::Output::Common qw( prep_outlines fmt_subst );
use feature 'signatures';

use ChordPro::Output::PDF::Song;
use ChordPro::Output::PDF::Writer;
use ChordPro::Files;
use ChordPro::Paths;
use ChordPro::Utils;

# Set by Configurator.
our $pdfapi;

use Text::Layout;
use List::Util qw(any);
use Unicode::Collate;

my $verbose = 0;

# For regression testing, run perl with PERL_HASH_SEED set to zero.
# This eliminates the arbitrary order of font definitions and triggers
# us to pinpoint some other data that would otherwise be varying.
my $regtest = defined($ENV{PERL_HASH_SEED}) && $ENV{PERL_HASH_SEED} == 0;

# Convenience.
*generate_song = \&ChordPro::Output::PDF::Song::generate_song;

sub generate_songbook {
    my ( $self, $sb ) = @_;

    return [] unless $sb->{songs}->[0]->{body}
                  || $sb->{songs}->[0]->{source}->{embedding};
    $verbose ||= $options->{verbose};


    $config->unlock;
    $ps = $config->{pdf};
    # use DDP; p $ps->{songbook}, as => "in PDF";
    my $pagectrl = $self->pagectrl;
    $config->lock;

    my $extra_matter = 0;
    if ( $options->{toc} // (@{$sb->{songs}} > 1) ) {
	for ( @{ $::config->{contents} } ) {
	    # Treat ToCs as one.
	    $extra_matter++, last unless $_->{omit};
	}
	$extra_matter++ if $options->{title};
    }
    $extra_matter++ if $pagectrl->{cover} && !$options->{title};
    $extra_matter++ if $pagectrl->{front_matter};
    $extra_matter++ if $pagectrl->{back_matter};
    $extra_matter++ if $options->{csv};

    # $prefill indicates that in 2page mode, a filler page is needed to
    # get the songs properly aligned.
    my $prefill = 0;
    if ( $pagectrl->{align_songs_spread} ) {
	$prefill = 1;
    }
    if ( $pagectrl->{sort_songs} ) {
	sort_songbook( $sb, $pagectrl );
    }
    if ( $pagectrl->{compact_songs} ) {
	$prefill = compact_songbook( $sb, $pagectrl );
	return unless defined $prefill; # cancelled
    }

    progress( phase   => "PDF",
	      index   => 0,
	      total   => scalar(@{$sb->{songs}}) );

    $pr = (__PACKAGE__."::Writer")->new( $ps, $pdfapi );
    warn("Generating PDF ", $options->{output} || "__new__.pdf", "...\n")
      if $options->{verbose};

    my $name = ::runtimeinfo("short");
    $name =~ s/version.*/regression testing/ if $regtest;
    my %info = ( Title => $sb->{songs}->[0]->{meta}->{title}->[0],
		 Creator => $name );
    while ( my ( $k, $v ) = each %{ $ps->{info} } ) {
	next unless defined($v) && $v ne "";
	$info{ucfirst($k)} = fmt_subst( $sb->{songs}->[0], $v );
    }

    $info{PageCtrl} = pagectrl_msg($pagectrl);
    $pr->info(%info);

    # The resultant songbook consists of 5 parts:
    # 1, The cover. PDF doc or cho template.
    # 2. The front matter. PDF doc or cho template.
    # 3. The table of contents. May be templated.
    # 4. The songs.
    # 5. The back matter. PDF doc.
    # All parts except the songs are optional.
    my ( %start_of, %pages_of );
    for ( qw( cover front toc songbook back ) ) {
	$start_of{$_} = 1;
	$pages_of{$_} = 0;
    }

    # The songbook...
    my @book;

    # Page number in the PDF (for now, later we'll prepend tocs etc.).
    # Note that PDF page numbers start at 1.
    my $page = 1;
    # Logical page number offset.
    my $page_offset = ( $options->{'start-page-number'} || 1 ) - 1;
    $page_offset++ if $prefill && is_even($page_offset);

#    if ( $pagectrl->{dual_pages} && is_odd($page_offset) ) {
#	warn("Warning: Specifying an even start page when ".
#	     "pdf.odd-even-pages is in effect may yield surprising results.\n");
#    }

    # If there is back matter, and it has even pages, force
    # alignment of the final song as well.
    my $back_matter;
    my $force_align;
    if ( $pagectrl->{back_matter} ) {
	$back_matter = $pdfapi->open( expand_tilde($pagectrl->{back_matter}) );
	die("Missing back matter: ", $pagectrl->{back_matter}, "\n")
	  unless $back_matter;
	$force_align =
	  !( is_even($page_offset) xor is_even($back_matter->pages))
	  if $pagectrl->{align_songs_extend};
    }

    for my $songindex ( 1 .. @{$sb->{songs}} ) {
	my $song = $sb->{songs}->[$songindex-1];
	local $pagectrl->{align_songs_spread} = $pagectrl->{align_songs_spread};
	$pagectrl->{align_songs_spread} = 1 if is_odd($page_offset);

	# Align.
	if ( $song->{meta}->{pages} ) { # 2nd pass
	    if (    ( ($page+$page_offset) % 2)
		 && $song->{meta}->{pages}
		 && $song->{meta}->{pages} == 2 ) {
		$pr->newpage($page+1);
		$page++;
	    }

	}
	else {
	    $page += $pr->page_align( $pagectrl, "song$songindex", $page );
	}

	$song->{meta}->{tocpage} = $page; # physical
	push( @book, [ $song->{meta}->{title}->[0], $song ] );

	# Copy persistent assets into each of the songs.
	if ( $sb->{assets} && %{$sb->{assets}} ) {
	    $song->{assets} //= {};
	    while ( my ($k,$v) = each %{$sb->{assets}} ) {
		$song->{assets}->{$k} = $v;
	    }
	}

	return unless progress( msg => $song->{meta}->{title}->[0] );

	$song->{meta}->{"chordpro.songsource"} //= $song->{source}->{file};
	$pr->{bookmark} = "song_$songindex";
	my $pages =
	  generate_song( $song,
			 { pr	      => $pr,
			   page_idx   => $page,
			   page_num   => $page+$page_offset,
			   songindex  => $songindex,
			   numsongs   => scalar(@{$sb->{songs}}),
			   forcealign => $force_align,
			   pagectrl   => $pagectrl,
			 } );

	# Easy access to toc page.
	$song->{meta}->{page} = $page+$page_offset;
	if ( $song->{meta}->{bookmark} ) {
	    $pr->named_dest( $song->{meta}->{bookmark},
			     $pr->{pdf}->openpage($page)) if $pages;
	}
	else {
	    # Embedded PDF -> no toc.
	    $song->{meta}->{_TOC} = [ "no" ];
	}
	$page += $song->{meta}->{pages} = $pages;
    }
    $pages_of{songbook} = $page - 1;
    $start_of{back} = $page;

    $::config->{contents} //=
      [ { $::config->{toc}->{order} eq "alpha"
	  ? ( fields => [ "title" ] )
	  : ( fields => [ "songindex" ] ),
	  label => $::config->{toc}->{title},
	  line => $::config->{toc}->{line} } ];

    my @tocs = @{ $::config->{contents} };

    if ( $extra_matter ) {
	progress( phase   => "PDF(extra)",
		  index   => 0,
		  total   => $extra_matter );
    }

    my $tocix;
    my $frontmatter_songbook;
    while ( @tocs ) {
	my $ctl = shift(@tocs);
	next unless $options->{toc} // @book > 1;

	for ( qw( fields label line pageno ) ) {
	    next if exists $ctl->{$_};
	    die("Config error: \"contents\" is missing \"$_\"\n");
	}
	next if $ctl->{omit};
	$tocix++;

	my $book = prep_outlines( [ map { $_->[1] } @book ], $ctl );

	# Create a pseudo-song for the table of contents.
	my $toctitle = fmt_subst( $book[0][-1], $ctl->{label} );
	my $start = $start_of{songbook} - $page_offset;
	# Templates for toc line and page.
	my $tltpl = $ctl->{line};
	my $pgtpl = $ctl->{pageno};

	my $song;
	my $tmplfile;
	if ( $ctl->{template} ) {
	    my $tpl = $ctl->{template};
	    if ( $tpl =~ /\.\w+/ ) { # file
		$tmplfile = CP->siblingres( $book[0][-1]->{source}->{file},
				      $tpl, class => "templates" );
		warn("ToC template not found: $tpl\n") unless $tmplfile;
	    }
	    else {
		$tmplfile = CP->findres( $tpl.".cho", class => "templates" );
		if ( $verbose ) {
		    warn("ToC template",
			 $tmplfile ? " found: $tmplfile" : " not found: $tpl.cho\n")
		}
	    }
	}

	# Construct front matter songbook.
	my $fmsb;
	my $lines;
	my $opts;
	if ( $tmplfile ) {
	    # Songbook from template file.
	    $opts = { fail => 'hard' };
	    $lines = fs_load( $tmplfile, $opts );
	}
	else {
	    $lines = [ "{title: $toctitle}" ];
	    $opts = { _filesource => "<builtin>" };
	}
	$fmsb = ChordPro::Songbook->new;
	$fmsb->parse_file( $lines, { %$opts,
				     bookmark => "toc_$tocix",
				     generate => 'PDF' } );
	for ( $fmsb->{songs}->[-1] ) {
	    $_->{title} = $_->{title}
	      ? fmt_subst( $book[0][-1], $_->{title} )
	      : $toctitle;
	    $_->{meta}->{title} //= [ $_->{title} ];
	}

	my @songs = @{$fmsb->{songs}};

	# The first (of multiple) gets the global title/subtitle.
	if ( @songs > 1 ) {
	    for ( $songs[0] ) {
		$_->{meta}->{title} =
		  [ fmt_subst( $_, $options->{title} ) ]
		  if defined $options->{title};
		$_->{meta}->{subtitle} =
		  [ fmt_subst( $_, $options->{subtitle} ) ]
		  if defined $options->{subtitle};
		$_->{title} = $_->{meta}->{title}->[0];
	    }
	}

	# The last song gets the ToC appended.
	$song = pop(@songs);

	my %prev;
	if ( $ctl->{break} ) {
	    my $prevbreak = "";
	    $song->{body} //= [];
	    for ( @$book ) {
		my $break = fmt_subst( $_->[-1], $ctl->{break} );
		my $nl = 0;
		$nl++ while $break =~ s/^(\n|\\n)//;

		my $p = $pr->{pdf}->openpage($_->[-1]->{meta}->{tocpage});
		if ( $nl && $break ne $prevbreak ) {
		    push( @{ $song->{body} },
			  { type => "empty",
			    context => "toc",
			  } ) for 1..$nl;
		}
		my $title  = fmt_subst( $_->[-1], $tltpl );
		my $pageno = fmt_subst( $_->[-1], $pgtpl );
		%prev = () if $break ne $prevbreak;
		push( @{ $song->{body} },
		      { type    => "tocline",
			context => "toc",
			title   => $title,
			page    => $p,
			pageno  => $pageno,
			maybe break => ($break ne $prevbreak ? $break : undef),
		      } )
		  unless %prev && $prev{title} eq $title && $prev{pageno} eq $pageno;
		$prevbreak = $break;
		$prev{title} = $title;
		$prev{pageno} = $pageno;
	    }
	}
	else {
	push( @{ $song->{body} //= [] },
	      map { my $p = $pr->{pdf}->openpage($_->[-1]->{meta}->{tocpage});
		    +{ type    => "tocline",
		       context => "toc",
		       title   => fmt_subst( $_->[-1], $tltpl ),
		       page    => $p,
		       pageno  => fmt_subst( $_->[-1], $pgtpl ),
		     } } @$book );
        }

	$frontmatter_songbook //= ChordPro::Songbook->new;
	$frontmatter_songbook->add($_) for @songs;
	$frontmatter_songbook->add($song);
    }

    # Prepend the front matter songs.

    $force_align = $pagectrl->{align_songs_extend};
    if ( $frontmatter_songbook && @{$frontmatter_songbook->{songs}} ) {
	return unless progress( msg => "ToC" );
	$page = 1;

	my $toc = 0;
	for ( @{$frontmatter_songbook->{songs}} ) {
	    # Localize song alignment settings.
	    local $pagectrl->{align_songs} =
	      $pagectrl->{align_tocs};
	    local $pagectrl->{align_songs_spread} =
	      $pagectrl->{align_tocs} eq "songs"
	      ? $pagectrl->{align_songs_spread} : 0;
	    local $pagectrl->{align_songs_extend} =
	      $pagectrl->{align_tocs} eq "songs"
	      ? $pagectrl->{align_songs_extend} : 0;

	    $toc++;
	    $pr->{bookmark} = "toc_$toc";
#	    warn("TOC $toc $page\n");
#	    use DDP; p $pagectrl, as => "for toc";
	    $page += $pr->page_align( $pagectrl, "toc$toc", $page );
#	    warn("TOC $toc $page\n");
	    my $pages =
	      generate_song( $_,
			     { pr	  => $pr,
			       prepend	  => 1,
			       roman	  => 1,
			       page_idx	  => $page,
			       page_num	  => $page,
			       songindex  => $toc,
			       numsongs	  => 0+@{$frontmatter_songbook->{songs}},
			       bookmark   => $pr->{bookmark},
#			       forcealign => $force_align,
			       pagectrl   => $pagectrl,
			     } );
	    $pr->named_dest( $_->{meta}->{bookmark},
			     $pr->{pdf}->openpage($page)) if $pages;
	    $page += $pages;
#	    warn("TOC $toc $page\n");
	}
	$pages_of{toc} = $page - 1;
	$start_of{$_} += $page - 1 for qw( songbook back );
    }

    if ( $pagectrl->{front_matter} ) {
	$page = 1;
	my $matter = $pdfapi->open( expand_tilde($pagectrl->{front_matter}) );
	die("Missing front matter: ", $pagectrl->{front_matter}, "\n") unless $matter;
	return unless progress( msg => "Front matter" );
	for ( 1 .. $matter->pages ) {
	    $pr->{pdf}->import_page( $matter, $_, $_ );
	    $page++;
	}
	$pages_of{front} = $matter->pages;
	$start_of{$_} += $page - 1 for qw( toc songbook back );
    }

    # If we have a template, process it as a song and prepend.
    my $covertpl;
    if ( defined($options->{title}) && !@tocs ) {
	my $tpl = "cover";
	$covertpl = CP->findres( "$tpl.cho", class => "templates" );
	if ( $verbose ) {
	    warn("Cover template",
		 $covertpl ? " found: $covertpl" : " not found: $tpl.cho\n")
	}
    }
    if ( $covertpl ) {
	my $page = 1;
	my $opts = { fail => 'hard' };
	my $lines = fs_load( $covertpl, $opts );
	my $csb = ChordPro::Songbook->new;
	$csb->parse_file( $lines, { %$opts,
				    generate => 'PDF' } );
	for ( $csb->{songs}->[0] ) {
	    @{$_->{meta}}{ keys( %{$config->{meta}} ) } =
	      values ( %{$config->{meta}} );
	    $_->{meta}->{title} =
	      $options->{title} ?
	      [ $options->{title} ] : [ $_->{meta}->{title}->[0] ];
	    $_->{meta}->{subtitle} =
	      $options->{subtitle} ?
	      [ $options->{subtitle} ] : $_->{meta}->{subtitle};
	}
	for ( @{$csb->{songs}} ) {
	    my $p =
	      generate_song( $_,
			     { pr	  => $pr,
			       prepend	  => 1,
			       roman	  => 1,
			       page_idx   => $page,
			       page_num   => $page,
			       songindex  => 0,
			       numsongs	  => 1,
			       pagectrl	  => $pagectrl,
			     } );
	    $page += $p;
	    $start_of{$_} += $p for qw( songbook front toc back );
	}
	$pages_of{cover} = $page - 1;
    }
    elsif ( defined( $pagectrl->{cover} ) ) {
	my $cover = $pdfapi->open( expand_tilde($pagectrl->{cover}) );
	die("Missing cover: ", $pagectrl->{cover}, "\n") unless $cover;
	$page = 0;
	return unless progress( msg => "Cover" );
	for ( 1 .. $cover->pages ) {
	    $page++;
	    $pr->{pdf}->import_page( $cover, $_, $page );
	}
	$pages_of{cover} = $page;
	$start_of{$_} += $page for qw( songbook front toc back );
    }

    # Back matter (if any) has already been opened.
    if ( $back_matter ) {
	$page = $start_of{back};
	return unless progress( msg => "Back matter" );
	warn( "ASSERT: pages=", $pr->{pdf}->pages,
	      " back=", $start_of{back}, "\n" )
	  unless 1+$pr->{pdf}->pages == $start_of{back};
	for ( 1 .. $back_matter->pages ) {
	    $pr->{pdf}->import_page( $back_matter, $_, $page );
	    $page++;
	}
	$pages_of{back} = $back_matter->pages;
    }

    if ( 0 and $::config->{debug}->{pages} & 0x01 ) {
	warn("-- pre alignment\n");
	for ( qw( cover front toc songbook back ) ) {
	    warn( sprintf("%4d %-10s %s\n",
			  $start_of{$_}, $_,
			  plural( sprintf("%4d",$pages_of{$_})," page") ));
	}
	warn("-- final\n");
    }

    # Alignment. Only if odd/even pages.
    if ( $pagectrl->{dual_pages} ) {
	my @parts = qw( front toc songbook back );
	while ( @parts ) {
	    my $part = shift(@parts);
	    next unless $pages_of{$part};

	    # Always align parts, regardless of pagealign-songs.
	    local $pagectrl->{align_songs} = 1;

	    if ( @parts ) {
		if ( $pr->page_align( $pagectrl,
				      $part,
				      $start_of{$part},
				      $part eq "songbook"
				      ? $prefill
				        ? 1
				        : is_odd($page_offset)
				      : 0 ) ) {
		    $start_of{$_}++ for $part, @parts;
		}
	    }
	    else {
		$start_of{$part} +=
		  $pr->page_align( $pagectrl, $part, $start_of{$part},
				   is_odd($back_matter->pages) );
	    }
	}
    }

    if ( $::config->{debug}->{pages} & 0x01 ) {
	for ( qw( cover front toc songbook back ) ) {
	    warn( sprintf("%4d %-10s %s\n",
			  $start_of{$_}, $_,
			  plural( sprintf("%4d",$pages_of{$_})," page") ));
	}
    }

    # Note that the page indices run from zero.
    $pr->pagelabel( 0,                     'arabic', 'cover-' );
    $pr->pagelabel( $start_of{front}-1,    'arabic', 'front-' )
      if $pages_of{front};
    $pr->pagelabel( $start_of{toc}-1,      'roman'            )
      if $pages_of{toc};
    # Label song pages according to the user visible number.
    $pr->pagelabel( $start_of{songbook}-1, 'arabic', '',           ,
		    $options->{'start-page-number'} || 1 )
      if $pages_of{songbook};
    $pr->pagelabel( $start_of{back}-1,     'arabic', 'back-'  )
      if $pages_of{back};

    # Add the bookmarks.
    for ( qw( cover front toc back ) ) {
	next unless $pages_of{$_};
	my $p = $pr->{pdf}->openpage( $start_of{$_} );
	$pr->named_dest( $_, $p );
    }

    # Add the outlines.
    $pr->make_outlines( [ map { $_->[1] } @book ], $start_of{songbook} );

    $pr->finish( $options->{output} || "__new__.pdf" );
    warn("Generated PDF...\n") if $options->{verbose};

    if ( $options->{csv} ) {
	return unless progress( msg => "CSV" );
	generate_csv( \@book, $page, \%pages_of, \%start_of )
    }

    []
}

sub generate_csv {
    my ( $book, $page, $pages_of, $start_of ) = @_;

    # Create an MSPro compatible CSV for this PDF.
    push( @$book, [ "CSV", { meta => { tocpage => $page } } ] );
    my $csv = CP->sibling( $options->{output}, ext => ".csv" );
    my $fd = fs_open( $csv, '>:utf8' )
      or die( $csv, ": $!\n" );

    warn("Generating CSV $csv...\n")
      if  $config->{debug}->{csv} || $options->{verbose};

    $ps = $config->{pdf};
    my $ctl = $ps->{csv};
    my $sep = $ctl->{separator} // ";";
    my $vsep = $ctl->{vseparator} // "|";

    my $rfc4180 = sub {
	my ( $v ) = @_;
	$v = [$v] unless is_arrayref($v);
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

    # Extra meta info from command line, for non-song CSV.
    my $xm = $options->{meta} // {};
    unless ( $ctl->{songsonly} ) {
	$csvline->( { %$xm,
		      title     => 'Cover',
		      pagerange => $pagerange->("cover"),
		      sorttitle => 'Cover',
		      artist    => 'ChordPro' } )
	  if $pages_of->{cover};
	$csvline->( { %$xm,
		      title     => 'Front Matter',
		      pagerange => $pagerange->("front"),
		      sorttitle => 'Front Matter',
		      artist    => 'ChordPro' } )
	  if $pages_of->{front};
	$csvline->( { %$xm,
		      title     => "Table of Contents",
		      pagerange => $pagerange->("toc"),
		      sorttitle => "Table of Contents",
		      artist    => 'ChordPro' } )
	  if $pages_of->{toc};
    }

    warn( "CSV: ", scalar(@$book), " songs in book\n")
      if $config->{debug}->{csv};
    for ( my $p = 0; $p < @$book-1; $p++ ) {
	my ( $title, $song ) = @{$book->[$p]};
	my $page = $start_of->{songbook} + $song->{meta}->{tocpage} - 1;
	my $pp = $song->{meta}->{pages};
	my $m = { %{$song->{meta}},
		  pagerange => [ $pagerange->($pp, $page) ] };
	$csvline->($m);
    }

    unless ( $ctl->{songsonly} ) {
	$csvline->( { %$xm,
		      title     => 'Back Matter',
		      pagerange => $pagerange->("back"),
		      sorttitle => 'Back Matter',
		      artist    => 'ChordPro'} )
	  if $pages_of->{back};
    }
    close($fd);
    warn("Generated CSV...\n")
      if  $config->{debug}->{csv} || $options->{verbose};
}

################ ################

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

# Derive new style page controls from old style.
sub pagectrl {
    my ( $self ) = @_;

    # If at this point we still have old style page controls,
    # they were passed via command line and thus override.
    # $config->migrate_songbook_pagectrl;

    my $sb = $config->{pdf}->{songbook};
    my $pagectrl = { dual_pages		 => $sb->{'dual-pages'},
		     align_tocs		 => $sb->{'align-tocs'},
		     align_songs	 => $sb->{'align-songs'},
		     align_songs_spread	 => $sb->{'align-songs-spread'},
		     align_songs_extend	 => $sb->{'align-songs-extend'},
		     sort_songs		 => $sb->{'sort-songs'},
		     compact_songs	 => $sb->{'compact-songs'},
		     cover		 => $sb->{cover},
		     front_matter	 => $sb->{'front-matter'},
		     back_matter	 => $sb->{'back-matter'},
		 };

    unless ( $pagectrl->{dual_pages} ) {
	$pagectrl->{align_songs} = 0;
	$pagectrl->{align_tocs} = 0;
    }
    unless ( $pagectrl->{align_songs} ) {
	$pagectrl->{$_} = 0
	  for qw( align_songs_spread align_songs_extend compact_songs);
    }
    for ( qw( cover front_matter back_matter ) ) {
	$pagectrl->{$_} = undef unless is_true($pagectrl->{$_});
    }
    if ( $config->{debug}->{pagectrl} ) {
	use DDP; p $pagectrl, as => "pagectrl";
    }
    return $pagectrl;
}

sub pagectrl_msg {
    my ( $pagectrl ) = @_;
    my $msg = $pagectrl->{dual_pages} ? "dual" : "single";
    if ( $pagectrl->{align_tocs} ) {
	$msg .= ", align_tocs";
	$msg .= "_song" if $pagectrl->{align_tocs} eq "song";
    }
    if ( $pagectrl->{align_songs} ) {
	$msg .= ", align_songs";
	$msg .= ", extend" if $pagectrl->{align_songs_extend};
	$msg .= ", spread" if $pagectrl->{align_songs_spread};
    }
    $msg .= ", " . $pagectrl->{sort_songs} if $pagectrl->{sort_songs};

    return $msg;
}

sub sort_songbook {
    my ( $sb, $pagectrl ) = @_;
    return unless my $sorting = $pagectrl->{sort_songs};

    foreach my $song ( @{$sb->{songs}} ) {
	if (!defined($song->{meta}->{sorttitle})) {
	    $song->{meta}->{sorttitle} = $song->{meta}->{title};
	}
    }

    my @songlist = @{$sb->{songs}};

    my @tbs;			# to be sorted
    my $desc = 0;		# descending
    if ( $sorting =~ /^([-+]?)title$/i ) {
	$desc = $1 eq "-";
	@tbs = map { [ $_->{meta}->{sorttitle}->[0], $_ ] } @songlist;
    }
    elsif ( $sorting =~ /^([-+]?)subtitle$/i ) {
	$desc = $1 eq "-";
	@tbs = map { [ $_->{meta}->{subtitle}->[0], $_ ] } @songlist;
    }
    return unless @tbs;

    if ( 1 ) {
	my $collator = Unicode::Collate->new;
	my ( $aa, $bb ) = $desc ? qw( b a ) : qw( a b );
	my $l = "\$$aa"."->[0]";
	my $r = "\$$bb"."->[0]";
	my $proc = 'sub { my $tbs = shift; ';
	$proc .= '[ map { $_->[1] } sort { ';
	$proc .= "\$collator->cmp( $l, $r )";
	$proc .= ' } @$tbs ] }';
	my $sorter = eval $proc;
	die("OOPS $proc\n$@") if $@;
	$sb->{songs} = $sorter->(\@tbs);
    }
    else {
	my $proc = 'sub { my $tbs = shift; use locale; ';
	$proc .= '[ map { $_->[1] } sort { ';
	$proc .= $desc ? '$b->[0] cmp $a->[0]' : '$a->[0] cmp $b->[0]';
	$proc .= ' } @$tbs ] }';
	my $sorter = eval $proc;
	die("OOPS $proc\n$@") if $@;
	$sb->{songs} = $sorter->(\@tbs);
    }
}

sub compact_songbook {
    my ( $sb, $pagectrl ) = @_;
    return 0 unless $pagectrl->{compact_songs};

    my $ps = $config->{pdf};
    my $pri = ( __PACKAGE__."::Writer" )->new( $ps, $pdfapi );

    # Count pages to properly align multi-page songs without
    # needing to turn page.
    my $page = $options->{"start-page-number"} ||= 1;

    foreach my $song ( @{$sb->{songs}} ) {
	if (!defined($song->{meta}->{sorttitle})) {
	    $song->{meta}->{sorttitle} = $song->{meta}->{title};
	}
    }

    my @songlist = @{$sb->{songs}};
    my $filler = 0;		# filler for 2page

    # Progress indicator
    progress( phase   => "Counting",
	      index   => 0,
	      total   => scalar(@{$sb->{songs}}) );

    my $i = 1;
    foreach my $song ( @songlist ) {
	return unless progress( msg => $song->{title} );
	$i++;

	#### HACK ATTACK.
	# Assets will be rendered, but then they are part of the temp
	# PDF, not the final one.
	# We copy the unprocessed assets and restore after the 1st pass.
	use Storable qw(dclone);
	my $assets;
	$assets = dclone( $song->{assets} ) if $song->{assets};
	####

	$song->{meta}->{pages} =
	  generate_song( $song,
			 { pr	  => $pri,
			   startpage  => 1,
			   pagectrl	  => $pagectrl,
			 } );
	####
	$song->{assets} = $assets if $assets;
	####
    }

    my @new;
    my $used = "";
    # First an arbitrary odd-pages song.
    for ( my $i=0; $i < @songlist; $i++ ) {
	next unless is_odd( $options->{'start-page-number'}||1 );
	next unless is_odd($songlist[$i]->{meta}->{pages});
	push( @new, $songlist[$i] );
	vec( $used, $i, 1 ) = 1;
	last;
    }
    ##### TODO: If still empty, need filler.
    $filler++ unless @new;

    # Then all even-pages songs.
    for ( my $i=0; $i < @songlist; $i++ ) {
	next if vec( $used, $i, 1 );
	next unless is_even($songlist[$i]->{meta}->{pages});
	push( @new, $songlist[$i] );
	vec( $used, $i, 1 ) = 1;
    }

    # Finally, all other odd-pages songs.
    for ( my $i=0; $i < @songlist; $i++ ) {
	next if vec( $used, $i, 1 );
	next unless is_odd($songlist[$i]->{meta}->{pages});
	push( @new, $songlist[$i] );
	vec( $used, $i, 1 ) = 1;
    }

    die("compact ", scalar(@new), " <> ", scalar(@songlist), "!\n")
      unless scalar(@new) == scalar(@songlist);

    @songlist = @new;

    $sb->{songs} = [@songlist];

    return $filler;
}

sub diagrammer {
    my ( $type ) = @_;
    my $p;
    if ( $type eq "keyboard" ) {
	require ChordPro::Output::PDF::KeyboardDiagram;
	$p = ChordPro::Output::PDF::KeyboardDiagram->new( pr => $pr );
    }
    else {
	require ChordPro::Output::PDF::StringDiagram;
	$p = ChordPro::Output::PDF::StringDiagram->new( pr => $pr );
    }
    return $p;
}

use Object::Pad;

class TextLayoutImageElement :isa(Text::Layout::PDFAPI2::ImageElement);

use Carp;

use Text::ParseWords qw( shellwords );

method parse( $ctx, $k, $v ) {

    my %ctl = ( type => "img", %$ctx );
    my $err;

    # Split the attributes.
    foreach my $kk ( shellwords($v) ) {

	# key=value
	if ( $kk =~ /^([-\w]+)=(.+)$/ ) {
	    my ( $k, $v ) = ( $1, $2 );

	    # Ignore case unless required.
	    $v = lc $v unless $k =~ /^(id|chord|src)$/;

	    if ( $k =~ /^(chord|src)$/ ) {
		if ( $v =~ /^(chord|builtin):/ ) {
		    $k = $1;
		    $v = $';
		}
		$ctl{$k} = $v;
	    }
	    elsif ( $k =~ /^(id|bbox)$/ ) {
		$ctl{$k} = $v;
	    }
	    elsif ( $k eq "align" && $v =~ /^(left|right|center)$/ ) {
		$ctl{$k} = $v;
	    }
	    elsif ( $k eq "type" && $v =~ /^(strings?|keyboard)$/ ) {
		$ctl{instrument} = $v;
	    }
	    elsif ( $k =~ /^(width|height|dx|dy|w|h)$/ ) {
		$v = $1                      if $v =~ /^(-?[\d.]+)pt$/;
		$v = $1 * $ctx->{size}       if $v =~ /^(-?[\d.]+)em$/;
		$v = $1 * $ctx->{size} / 2   if $v =~ /^(-?[\d.]+)ex$/;
		#$v = $1 * $ctx->{size} / 100 if $v =~ /^(-?[\d.]+)\%$/;
		if ( $v =~ /^(-?[\d.]+)\%$/ ) {
		    warn("Invalid img attribute: \"$kk\" (percentage not allowed)\n");
		    $err++;
		}
		else {
		    $ctl{$k} = $v;
		}
	    }
	    elsif ( $k =~ /^(scale)$/ ) {
		my @s;
		for ( split( /,/, $v ) ) {
		    $_ = $1 / 100 if /^([\d.]+)\%$/;
		    push( @s, $_ );
		}
		push( @s, $s[0] ) unless @s > 1;
		unless ( @s == 2 ) {
		    warn("Invalid img attribute: \"$kk\" (too many values)\n");
		    $err++;
		}
		$ctl{$k} = \@s;
	    }
	    else {
		warn("Invalid img attribute: \"$k\" ($kk)\n");
		$err++;
	    }
	}

	# Currently we do not have value-less attributes.
	else {
	    warn("Invalid img attribute: \"$kk\"\n");
	    $err++;
	}
    }

    if ( $err ) {
	if ( $ctl{id} ) {
	    $ctl{id} = "__ERROR__";
	}
    }
    elsif ( $ctl{id} ) {
	my $a = ChordPro::Output::PDF::Song::assets($ctl{id});
	if ( $a && $a->{opts}->{base} ) {
	    $ctl{base} = $a->{opts}->{base};
	}
    }

    return \%ctl;
}

method getimage ($fragment) {
    $fragment->{_img} //= do {
	my $xo;
	if ( $fragment->{id} ) {
	    my $o = ChordPro::Output::PDF::Song::assets($fragment->{id});
	    $xo = $o->{data} if $o;
	    unless ( $o && $xo ) {
		warn("Unknown image ID in <img>: $fragment->{id}\n")
		  unless $fragment->{id} eq "__ERROR__";
		$xo = alert( $fragment->{size} );
	    }
	    $fragment->{design_scale} = $o->{opts}->{scale};
	    if ( $o->{width} && $o->{vwidth} ) {
		$fragment->{design_scale} ||= 1;
		$fragment->{design_scale} *= $o->{vwidth}/$o->{width};
	    }
	}
	elsif ( $fragment->{builtin} ) {
	    my $i = $fragment->{builtin};
	    if ( $i =~ /^alert(?:\(([\d.]+)\))?$/ ) {
		$xo = alert( $1 || $fragment->{size} );
	    }
	    else {
		warn("Unknown builtin image in <img>: $i\n");
		$xo = alert( $fragment->{size} );
	    }
	}
	elsif ( $fragment->{chord} ) {
	    my $info = ChordPro::Chords::known_chord($fragment->{chord});
	    unless ( $info ) {
		warn("Unknown chord in <img>: $fragment->{chord}\n");
		$xo = alert( $fragment->{size} );
	    }
	    else {
		my $type = $fragment->{instrument} // $config->{instrument}->{type};
		my $p = ChordPro::Output::PDF::diagrammer($type);
		$xo = $p->diagram_xo($info);
	    }
	}
	$xo // $self->SUPER::getimage($fragment) // alert( $fragment->{size} );
    };
}

sub alert ($size) {
    my $scale = $size/20;
    my $xo = $pr->{pdf}->xo_form;
    $xo->bbox( 0, -18*$scale, 20*$scale, 0 );
    $xo->matrix( $scale, 0, 0, -$scale, 0, 0 );
    $xo->line_width(2)->line_join(1);
    $xo->stroke_color("red");
    $xo->fill_color("red");
    $xo->move( 1, 17 )->polyline( 19, 17, 10, 1 )->close->stroke;
    $xo->rectangle( 9, 13, 11, 15 );
    $xo->move( 9, 12 )->polyline( 8.5, 7, 11.5, 7, 11, 12 )->close->fill;
    return $xo;
}

class TextLayoutSymbolElement :does(Text::Layout::ElementRole);

use ChordPro::Utils qw(parse_kv);
use ChordPro::Symbols;

field $glyphs;

BUILD {
    $glyphs = ChordPro::Symbols::symbols();
};

method parse( $ctx, $k, $v ) {
    my $kv = parse_kv($v);
    my $res =
      { %$ctx,
	type => "text",
	font => Text::Layout::FontConfig->from_string("ChordProSymbols"),
      };

    while ( ( $k,$v) = each(%$kv) ) {
	$res->{$k} = $v, next
	  if $k =~ /^(size|color|bgcolor|href)$/;
	$res->{text} = $glyphs->{$k}, next if defined $glyphs->{$k};
	warn("Unknown attribute in <sym>: $k (ignored)\n");
    }

    return $res;
}

# These methods must be defined for the role, but will not be used.
method render( $hash, $gfx, $x, $y ) {}
method bbox( $hash ) {}

1;
