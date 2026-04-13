#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

use Encode qw( encode from_to );

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = ChordPro::Songbook->new;

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{subtitle: Sub Títlë}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "__STRING__: One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );

my $song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		       'subtitle' => [
				   'Sub Títlë',
				  ]
		      },
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'subtitle' => [
			   'Sub Títlë',
			  ]
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

mkdir("out") unless -d "out";

$data = encode("UTF-8", $data);

my @BOMs = qw( UTF-8 UTF-16BE UTF-16LE UTF-32BE UTF-32LE );
my @noBOMs = qw( ISO-8859-1 UTF-8 );

my %enc2bom = map { $_ => encode($_, "\x{feff}") } @BOMs;

enctest( $_, 1 ) for @noBOMs;
enctest($_) for @BOMs;

done_testing( 3 * ( 1 + 4*(@noBOMs + @BOMs) ) );

sub enctest {
    my ( $enc, $nobom ) = @_;
    my $encoded = $data;
    _enctest( $encoded, $enc, $nobom );
    $encoded = $data;
    $encoded =~ s/\n/\x0a/g;
    _enctest( $encoded, $enc, $nobom, "LF" );
    $encoded = $data;
    $encoded =~ s/\n/\x0d/g;
    _enctest( $encoded, $enc, $nobom, "CR" );
    $encoded = $data;
    $encoded =~ s/\n/\x0d\x0a/g;
    _enctest( $encoded, $enc, $nobom, "CRLF" );
}

sub _enctest {
    my ( $encoded, $enc, $nobom, $crlf ) = @_;
    from_to( $encoded, "UTF-8", $enc );
    unless ( $nobom ) {
	BAIL_OUT("Unknown encoding: $enc") unless $enc2bom{$enc};
	$encoded = $enc2bom{$enc} . $encoded;
    }

    my $fn = "out/$enc.cho";
    open( my $fh, ">:raw", $fn ) or die("$fn: $!\n");
    print $fh $encoded;
    close($fh);
    $enc .= " (no BOM)" if $nobom;
    $enc .= " ($crlf)" if $crlf;

    my $s = ChordPro::Songbook->new;
    eval { $s->parse_file($fn) } or diag("$@");
    ok( scalar( @{ $s->{songs} } ) == 1, "$enc: One song" );
    isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
    $song->{source}->{file} = $fn;
    is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

    unlink($fn);
}
