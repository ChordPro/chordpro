#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode from_to);

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{subtitle: Sub Títlë}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "__STRING__: One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

my $song = {
	    'settings' => {},
	    'meta' => {
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
	    'subtitle' => [
			   'Sub Títlë',
			  ]
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

chdir("t") if -d "t";
mkdir("out") unless -d "out";

$data = encode("UTF-8", $data);

my @BOMs = qw( UTF-8 UTF-16BE UTF-16LE UTF-32BE UTF-32LE );
my @noBOMs = qw( ISO-8859-1 UTF-8 );

my %enc2bom = map { $_ => encode($_, "\x{feff}") } @BOMs;

enctest( $_, 1 ) for @noBOMs;
enctest($_) for @BOMs;

done_testing( 3 * ( 1 + @noBOMs + @BOMs ) );

sub enctest {
    my ( $enc, $nobom ) = @_;
    my $encoded = $data;
    from_to( $encoded, "UTF-8", $enc );
    unless ( $nobom ) {
	BAIL_OUT("Unknown encoding: $enc") unless $enc2bom{$enc};
	$encoded = $enc2bom{$enc} . $encoded;
    }

    my $fn = "out/$enc.cho";
    open( my $fh, ">", $fn ) or die("$fn: $!\n");
    print $fh $encoded;
    close($fh);

    $enc .= " (no BOM)" if $nobom;

    my $s = App::Music::ChordPro::Songbook->new;
    eval { $s->parsefile($fn) } or diag("$@");
    ok( scalar( @{ $s->{songs} } ) == 1, "$enc: One song" );
    isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
    $song->{source}->{file} = $fn;
    is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

    unlink($fn);
}
