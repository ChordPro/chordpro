#!/usr/bin/perl

my $src = shift;
open( my $fd, ">", $src);
open( my $fi, "<", "$src.pl" );
$fd->print( <$fi> );
$fd->close;
