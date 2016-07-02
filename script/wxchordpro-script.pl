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
    $self->SetTopWindow($main);
    $main->Show(1);

    return 1;
}

# No localisation yet.
# my $locale = Wx::Locale->new("English", "en", "en_US");
# $locale->AddCatalog("wxchordpro");

my $m = main->new();
$m->MainLoop();
