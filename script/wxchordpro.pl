#!/usr/bin/perl

use Wx 0.9912 qw[:allclasses];

use strict;
use warnings;

package main;

use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use App::Packager;

# We need Wx::App for the mainloop.
# App::Music::ChordPro::Wx::Main is the main entry of the program.
use base qw(Wx::App App::Music::ChordPro::Wx::Main);

sub OnInit {
    my ( $self ) = shift;

    Wx::InitAllImageHandlers();

    my $main = App::Music::ChordPro::Wx::Main->new();
    exit unless $main->init;

#    my $icon = Wx::Icon->new();
#    $icon->CopyFromBitmap(Wx::Bitmap->new("wxchordpro.jpg", wxBITMAP_TYPE_ANY));
#    $main->SetIcon($icon);

    $self->SetTopWindow($main);
    $main->Show(1);

    return 1;
}

# No localisation yet.
# my $locale = Wx::Locale->new("English", "en", "en_US");
# $locale->AddCatalog("wxchordpro");

my $m = main->new();
$m->MainLoop();

=head1 NAME

wxchordpro - a simple Wx-based GUI wrapper for ChordPro

=head1 SYNOPSIS

  wxchordpro

=head1 DESCRIPTION

B<wxchordpro> is a GUI wrapper for the ChordPro program. It allows
opening of files, make changes, and preview (optionally print) the
formatted result.

For more information about the ChordPro file format, see
L<http://www.chordpro.org>.

For more information about ChordPro program, see L<App::Music::ChordPro>.

=head1 LICENSE

Copyright (C) 2010,2017 Johan Vromans,

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

