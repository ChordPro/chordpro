#!/usr/bin/perl

package main;

our $options;
our $config;

package ChordPro::Songbook;

use strict;
use warnings;
use feature 'state';

use ChordPro;
use ChordPro::Config;
use ChordPro::Files;
use ChordPro::Song;
use ChordPro::Utils qw(progress);

use Carp;
use List::Util qw(any);
use Storable qw(dclone);
use Ref::Util qw(is_arrayref is_plain_hashref);
use MIME::Base64;

my $regtest = defined($ENV{PERL_HASH_SEED}) && $ENV{PERL_HASH_SEED} == 0;

sub new {
    my ($pkg) = @_;
    bless { songs => [ ] }, $pkg;
}

sub parse_file {
    my ( $self, $filename, $opts ) = @_;
    $opts //= {};
    my $meta = { %{$config->{meta}}, %{delete $opts->{meta}//{}} };
    my $defs = { %{delete $opts->{defs}//{}} };

    # Check for PDF embedding.
    if ( $filename =~ /\.pdf$/i ) {
	return $self->embed_file( $filename, $meta, $defs );
    }

    # fs_load sets $opts->{_filesource}.
    $opts->{fail} = "soft";
    my $lines = is_arrayref($filename) ? $filename
      : fs_load( $filename, $opts );
    die( $filename, ": ", $opts->{error}, "\n" ) if $opts->{error};

    # Sense crd input and convert if necessary.
    if ( !(defined($options->{a2crd}) && !$options->{a2crd}) and
	 !$options->{fragment}
	 and any { /\S/ } @$lines	# non-blank lines
	 and $options->{crd} || !any { /^{\s*\w+/ } @$lines ) {
	warn("Converting $filename to ChordPro format\n")
	  if $options->{verbose} || !($options->{a2crd}||$options->{crd});
	require ChordPro::A2Crd;
	$lines = ChordPro::A2Crd::a2crd( { lines => $lines } );
    }

    $opts //= {};

    # Used by tests.
    for ( "transpose", "transcode" ) {
	next unless exists $opts->{$_};
	$config->{settings}->{$_} = $opts->{$_};
    }
    for ( "no-substitute", "no-transpose" ) {
	next unless exists $opts->{$_};
	$options->{$_} = $opts->{$_};
    }
    bless $config => ChordPro::Config:: if is_plain_hashref($config);

    my $linecnt = 0;
    my $songs = 0;

    while ( @$lines ) {
	my $song = ChordPro::Song->new($opts)
	  ->parse_song( $lines, \$linecnt,
			{ %{dclone($meta)},
			  "bookmark"   => $opts->{bookmark} //= sprintf( "song_%d", 1 + @{ $self->{songs} } ),
			},
			{ %$defs } );

	$song->{meta}->{songindex} = 1 + @{ $self->{songs} };
	push( @{ $self->{songs} }, $song );
	$songs++;

	# Copy persistent assets to the songbook.
	if ( $song->{assets} ) {
	    $self->{assets} //= {};
	    while ( my ($k,$v) = each %{$song->{assets}} ) {
		next unless $v->{opts} && $v->{opts}->{persist};
		$self->{assets}->{$k} = $v;
	    }
	}
    }

    if ( @{$self->{songs}} > 1 ) {
	my $song = $self->{songs}->[-1];
	unless ( $song->{body}
		 && any { $_->{type} ne "ignore" } @{$song->{body}} ) {
	    pop( @{ $self->{songs} } );
	    $songs--;
	}
    }

    warn("Warning: No songs found in ", $opts->{_filesource}, "\n")
      unless $songs || $::running_under_test;

    return 1;
}

sub add {
    my ( $self, $song ) = @_;
    push( @{$self->{songs}}, $song );
    $self;
}

sub embed_file {
    my ( $self, $filename, $meta, $defs ) = @_;

    unless ( fs_test( sr => $filename ) ) {
	warn("$filename: $! (skipped)\n");
	return;
    }
    my $type = "pdf";

    my $song = ChordPro::Song->new( { filesource => $filename } );
    $song->{meta}->{songindex} = 1 + @{ $self->{songs} };
    $song->{source} =
      { file      => $filename,
	line      => 1,
	embedding => $type,
      };
    my $title = $defs->{title} // $filename;
    $song->{title} = $title;
    $song->{meta}->{title} = [ $title ];
    push( @{ $self->{songs} }, $song );
    $song->dump(0) if $config->{debug}->{song};
    return 1;
}

# Used by HTML backend.
sub structurize {
    my ( $self ) = @_;

    foreach my $song ( @{ $self->{songs} } ) {
	$song->structurize;
    }
}

1;
