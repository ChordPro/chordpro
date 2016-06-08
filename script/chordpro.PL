#!/usr/bin/perl

my $src = shift;
open( my $fd, ">", $src);
open( my $fi, "<", "$src-script.pl" );
print { $fd } ( <$fi> );
close($fd);
