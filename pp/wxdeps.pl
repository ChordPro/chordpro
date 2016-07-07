#!/usr/bin/perl

# Produce pp options to Wx components.
#
# WARNING: ALPHA VERSION. PLEASE FEEDBACK.

use strict;
use warnings;
use Alien::wxWidgets;
use File::Spec;

unless ( @ARGV ) {
    die("Usage $0 [ Wx::Module... | component... | \"all\" ]\n");
}

my %stddeps =
  (
    'Wx'		=> [ qw( base core adv ) ],
    'Wx::AUI'		=> [ qw( aui ) ],
    'Wx::Html'		=> [ qw( html net ) ],
    'Wx::Media'		=> [ qw( media ) ],
    'Wx::RichText'	=> [ qw( base html xml richtext ) ],
    'Wx::XRC'		=> [ qw( base html xml xrc ) ],
    'Wx::GLCanvas'	=> [ qw( gl ) ],
    'Wx::Socket'	=> [ qw( net ) ],
    'Wx::WebView'	=> [ qw( webview ) ],
    'Wx::STC'		=> [ qw( stc ) ],
    'Wx::PropertyGrid'	=> [ qw( propgrid ) ],
  );

# Site specific install lib, if any (MS Windows only).
my $lib;
eval { $lib = Alien::wxWidgets->shared_library_path() };
if ( $lib ) {
    $lib =~ s/[\\\/]*//;
}
else {
    $lib = "";
}

my @components;

foreach ( @ARGV ) {
    if ( /^Wx(?:$|::)/ ) {
	push( @components, @{ $stddeps{$_} } ) if exists $stddeps{$_};
    }
    else {
	push( @components, $_ ) unless $_ eq "all";
    }
}

my @libs = Alien::wxWidgets->shared_libraries(@components);

foreach my $l ( @libs ) {
    $l = File::Spec->catfile( $lib, $l ) if $lib;
    print("--link=$l\n");
}

=head1 LICENSE

Copyright (C) 2016, Johan Vromans <jvromans@squirrel.nl>

This program is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
