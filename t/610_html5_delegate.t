#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

plan tests => 6;

my $input = "html5_delegate_svg.cho";
my $out = "out/html5_delegate_svg.html";

@ARGV = (
    "--no-default-configs",
    "--no-userconfig",
    "--no-sysconfig",
    "--generate", "HTML5",
    "--output", $out,
    $input,
);
my $warn = '';
local $SIG{__WARN__} = sub { $warn .= join('', @_); warn @_ };
::run();

ok( -f $out, "Generated delegate HTML5 output" );

open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
my $content = do { local $/; <$out_fh> };
close $out_fh;

like( $content, qr/class="[^"]*cp-delegate[^"]*"/, "Delegate image class present" );
like( $content, qr/<img\b[^>]*src="data:image\/svg\+xml;charset=utf-8,/, "SVG delegate rendered via URL-encoded SVG data URI" );
unlike( $content, qr/<div\b[^>]*cp-delegate-svg[^>]*>\s*<svg\b/s, "No inline SVG delegate container emitted" );
unlike( $warn, qr/Please remove handler "ChordPro::Delegate::ABC"/, "No deprecated ABC handler warning" );

my $stdef_defs = () = ($content =~ /id%3D%22stdef%22/g);
my $stdef_refs = () = ($content =~ /%23stdef/g);
cmp_ok( $stdef_defs, '>=', $stdef_refs, "Bug 72: Split ABC SVG payloads include defs for all #stdef references" );

unlink $out;
