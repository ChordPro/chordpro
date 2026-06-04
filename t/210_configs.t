#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Config;

plan tests => 6;

sub Config::new {
    my ( $pkg, $init ) = @_;
    bless { %$init } => 'ChordPro::Config';
}

# Original content.
my $orig = Config->new
  ( { a => { b => [ 'c', 'd' ], e => [[ 'f' ]] }, g => { h => 1, i => 1 } } );

# Actual content, initially a copy of original content.
my $actual = Config->new
  ( { a => { b => [ 'c', 'd' ], e => [[ 'f' ]] }, g => { h => 1, i => 1 } } );

# Augmentation hash.
my $aug = { a => { b => [ 'prepend', 'x' ], e => [ [ 'g' ] ] }, g => { i => 2 } };

# Expected new content.
my $new = Config->new
  ( { a => { b => [ 'x', 'c', 'd' ], e => [[ 'g' ]] }, g => { h => 1, i => 2 } } );

is_deeply( $orig, $actual, "orig = actual" );

$actual->augment($aug);
is_deeply( $actual, $new, "augmented" );

$actual->reduce($orig);
is_deeply( $actual, $aug, "reduced" );

my $cfg_file = "out/html5_override_config.json";
unless ( -d "out" ) {
    mkdir "out" or die "Cannot create out/: $!";
}

open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
print $cfg_fh <<'JSON';
{
  "html5": {
    "css": {
      "fonts": {
        "text": "Georgia, serif"
      }
    },
    "paged": {
      "papersize": "a4",
      "margintop": 80,
      "marginbottom": 40,
      "marginleft": 40,
      "marginright": 40
    }
  }
}
JSON
close $cfg_fh;

my @warns;
local $SIG{__WARN__} = sub { push @warns, @_ };
my $cfg = ChordPro::Config::configurator(
    {
        nosysconfig => 1,
        nolegacyconfig => 1,
        nouserconfig => 1,
        config => $cfg_file,
    }
);

ok( $cfg, "loaded HTML5 override config" );
ok( !grep { /Config error: unknown item html5\./ } @warns,
    "no unknown-item warnings for html5 overrides" );
is( $cfg->{html5}->{css}->{fonts}->{text}, "Georgia, serif",
    "html5 css font override applied" );

unlink $cfg_file;
