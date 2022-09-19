#!/usr/bin/perl

package main;

our $options;
our $config;

package App::Music::ChordPro::Songbook;

use strict;
use warnings;

use App::Music::ChordPro;
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Song;

use Carp;
use List::Util qw(any);
use File::LoadLines;

sub new {
    my ($pkg) = @_;
    bless { songs => [ ] }, $pkg;
}

sub parse_file {
    my ( $self, $filename, $opts ) = @_;
    $opts //= {};
    my $meta = { %{$config->{meta}}, %{delete $opts->{meta}//{}} };
    my $defs = { %{delete $opts->{defs}//{}} };

    # Loadlines sets $opts->{_filesource}.
    my $lines = loadlines( $filename, $opts );
    # Sense crd input and convert if necessary.
    if ( !(defined($options->{a2crd}) && !$options->{a2crd}) and
	 !$options->{fragment}
	 and any { /\S/ } @$lines	# non-blank lines
	 and $options->{crd} || !any { /^{\s*\w+/ } @$lines ) {
	warn("Converting $filename to ChordPro format\n")
	  if $options->{verbose} || !($options->{a2crd}||$options->{crd});
	require App::Music::ChordPro::A2Crd;
	$lines = App::Music::ChordPro::A2Crd::a2crd( { lines => $lines } );
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
    bless $config => App::Music::ChordPro::Config:: if ref $config eq 'HASH';

    my $linecnt = 0;
    my $songs = 0;
    while ( @$lines ) {
	my $song = App::Music::ChordPro::Song
	  ->new( $opts->{_filesource} )
	  ->parse_song( $lines, \$linecnt, {%$meta}, {%$defs} );
	$song->{meta}->{songindex} = 1 + @{ $self->{songs} };
	push( @{ $self->{songs} }, $song );
	$songs++ if $song->{body};
    }

    warn("Warning: No songs found in ", $opts->{_filesource}, "\n")
      unless $songs || $::running_under_test;

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
