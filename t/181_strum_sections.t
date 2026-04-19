#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 12;

my $s = ChordPro::Songbook->new;

my $data = <<'EOD';
{title: Standalone Strum}
{start_of_strum: label="Verse Groove" tuplet=3}
dn up dn~up | dn~up
{end_of_strum}
EOD

eval { $s->parse_file(\$data, { nosongline => 1 }) } or diag("$@");
my $song = $s->{songs}->[0];
ok( $song, "Song parsed" );

my @strum_assets = grep {
    my $asset = $song->{assets}->{$_};
    ($asset->{delegate} // '') eq 'Strum'
} keys %{ $song->{assets} // {} };

ok( scalar(@strum_assets) == 1, "Exactly one standalone strum asset created" );
my $asset_id = $strum_assets[0];
my $asset = $song->{assets}->{$asset_id};

is( $asset->{subtype} // '', 'delegate', "Standalone strum stored as delegate image asset" );
is( $asset->{opts}->{tuplet} // '', 3, "Tuplet option parsed from start_of_strum" );
is( scalar(@{ $asset->{data} // [] }), 1, "Standalone strum payload line captured" );

my ($image_ref) = grep {
    ($_->{type} // '') eq 'image' && ($_->{id} // '') eq $asset_id
} @{ $song->{body} // [] };
ok( $image_ref, "Song body contains image reference to strum asset" );

$data = <<'EOD';
{title: Grid Strum Compatibility}
{start_of_grid}
| C . . . |
|s dn up dn up |
{end_of_grid}
EOD

eval { $s->parse_file(\$data, { nosongline => 1 }) } or diag("$@");
my $song2 = $s->{songs}->[1];
my ($strumline) = grep { ($_->{type} // '') eq 'strumline' } @{ $song2->{body} // [] };
ok( $strumline, "Grid strumline parsing remains available" );

$data = <<'EOD';
{title: Canonical Strum Header}
{start_of_strum: 4/4 verse triplet}
dn up dn up
{end_of_strum}
{strum: verse}
EOD

eval { $s->parse_file(\$data, { nosongline => 1 }) } or diag("$@");
my $song3 = $s->{songs}->[2];
ok( $song3, "Canonical start_of_strum header parsed" );

my @canon_assets = grep {
    my $asset = $song3->{assets}->{$_};
    ($asset->{delegate} // '') eq 'Strum'
} keys %{ $song3->{assets} // {} };

is( scalar(@canon_assets), 1, "Canonical header creates one reusable strum asset" );
my $canon_asset_id = $canon_assets[0];
my $canon_asset = $song3->{assets}->{$canon_asset_id};

is( $canon_asset->{opts}->{time_sig} // '', '4/4', "Canonical header extracts time signature" );
is( $canon_asset->{opts}->{tuplet} // '', 3, "Canonical header extracts textual tuplet as numeric value" );

my @canon_image_refs = grep {
    ($_->{type} // '') eq 'image' && ($_->{id} // '') eq $canon_asset_id
} @{ $song3->{body} // [] };
is( scalar(@canon_image_refs), 2, "Canonical strum pattern can be referenced via {strum: label}" );
