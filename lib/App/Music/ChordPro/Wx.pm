#! perl

use strict;
use warnings;
use utf8;

package App::Music::ChordPro::Wx;

our $VERSION = "0.84";

1;

=head1 NAME

wxchordpro - a simple Wx-based GUI wrapper for ChordPro

=head1 SYNOPSIS

  wxchordpro [ ChordPro file ]

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

