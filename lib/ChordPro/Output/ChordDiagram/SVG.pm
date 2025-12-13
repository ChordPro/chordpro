#! perl

# ChordPro::Output::ChordDiagram::SVG
#
# Generate SVG chord diagrams for string and keyboard instruments
# This module can be used by any output backend that needs SVG chord diagrams

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";

package ChordPro::Output::ChordDiagram::SVG;

our $VERSION = '1.0.0';

=head1 NAME

ChordPro::Output::ChordDiagram::SVG - SVG chord diagram generator

=head1 SYNOPSIS

    use ChordPro::Output::ChordDiagram::SVG;
    
    my $generator = ChordPro::Output::ChordDiagram::SVG->new();
    my $svg = $generator->generate_string_diagram($chord_name, $chord_info);
    
=head1 DESCRIPTION

This module generates SVG markup for chord diagrams. It handles:

- String instruments (guitar, ukulele, etc.)
- Keyboard instruments (piano)
- Grid layout with frets and strings
- Open and muted string indicators
- Finger position dots
- Finger number labels
- Base fret indicators

=head1 METHODS

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {
        # Default dimensions (can be overridden)
        cell_width    => $args{cell_width} // 15,
        cell_height   => $args{cell_height} // 18,
        num_frets     => $args{num_frets} // 4,
        margin_top    => $args{margin_top} // 30,
        margin_bottom => $args{margin_bottom} // 25,
        margin_left   => $args{margin_left} // 25,
        margin_right  => $args{margin_right} // 10,
        
        # Colors
        stroke_color  => $args{stroke_color} // "#333",
        nut_color     => $args{nut_color} // "#000",
        dot_color     => $args{dot_color} // "#000",
        text_color    => $args{text_color} // "#000",
        
        # Escape function
        escape_fn     => $args{escape_fn} // \&_default_escape,
    };
    
    return bless $self, $class;
}

=head2 generate_string_diagram($chord_name, $chord_info)

Generate an SVG diagram for a string instrument chord.

Parameters:
- $chord_name: The name of the chord (e.g., "Am", "G7")
- $chord_info: Chord info object with frets, fingers, base properties

Returns: SVG markup as a string

=cut

sub generate_string_diagram ( $self, $chord_name, $info ) {
    # Get values from either object or hash
    my $frets = ref($info) eq 'HASH' ? ($info->{frets} // []) : ($info->frets // []);
    return '' unless ref($frets) eq 'ARRAY' && @$frets;
    
    my $fingers = ref($info) eq 'HASH' ? ($info->{fingers} // []) : ($info->fingers // []);
    my $base = ref($info) eq 'HASH' ? ($info->{base} // 1) : ($info->base // 1);
    my $strings = scalar @$frets;
    
    # Get dimensions
    my $cell_width = $self->{cell_width};
    my $cell_height = $self->{cell_height};
    my $num_frets = $self->{num_frets};
    my $margin_top = $self->{margin_top};
    my $margin_bottom = $self->{margin_bottom};
    my $margin_left = $self->{margin_left};
    my $margin_right = $self->{margin_right};
    
    my $grid_width = ($strings - 1) * $cell_width;
    my $grid_height = $num_frets * $cell_height;
    
    my $svg_width = $grid_width + $margin_left + $margin_right;
    my $svg_height = $grid_height + $margin_top + $margin_bottom;
    
    my $escape = $self->{escape_fn};
    my $escaped_name = $escape->($chord_name);
    
    my $svg = qq{<svg class="cp-diagram-svg" viewBox="0 0 $svg_width $svg_height" xmlns="http://www.w3.org/2000/svg">\n};
    
    # Chord name
    my $name_x = $margin_left + $grid_width / 2;
    $svg .= qq{  <text x="$name_x" y="18" text-anchor="middle" class="diagram-name">$escaped_name</text>\n};
    
    # Draw grid
    my $grid_x = $margin_left;
    my $grid_y = $margin_top;
    
    my $stroke_color = $self->{stroke_color};
    my $nut_color = $self->{nut_color};
    
    # Horizontal lines (frets)
    for my $i (0..$num_frets) {
        my $y = $grid_y + $i * $cell_height;
        my $x2 = $grid_x + $grid_width;
        my $class = $i == 0 && $base == 1 ? "diagram-nut" : "diagram-line";
        my $width = $i == 0 && $base == 1 ? 3 : 1;
        my $stroke = $i == 0 && $base == 1 ? $nut_color : $stroke_color;
        $svg .= qq{  <line x1="$grid_x" y1="$y" x2="$x2" y2="$y" stroke="$stroke" stroke-width="$width" class="$class"/>\n};
    }
    
    # Vertical lines (strings)
    for my $i (0..$strings-1) {
        my $x = $grid_x + $i * $cell_width;
        my $y2 = $grid_y + $grid_height;
        $svg .= qq{  <line x1="$x" y1="$grid_y" x2="$x" y2="$y2" stroke="$stroke_color" stroke-width="1" class="diagram-line"/>\n};
    }
    
    # Base fret indicator (if not on nut)
    if ($base > 1) {
        my $base_x = $grid_x - 15;
        my $base_y = $grid_y + $cell_height / 2;
        $svg .= qq{  <text x="$base_x" y="$base_y" text-anchor="end" class="diagram-base">${base}fr</text>\n};
    }
    
    # Draw finger positions and open/muted markers
    for my $i (0..$strings-1) {
        my $fret = $frets->[$i];
        my $x = $grid_x + $i * $cell_width;
        
        if ($fret < 0) {
            # Muted string
            my $marker_y = $grid_y - 8;
            $svg .= qq{  <text x="$x" y="$marker_y" text-anchor="middle" class="diagram-muted">×</text>\n};
        }
        elsif ($fret == 0) {
            # Open string
            my $circle_y = $grid_y - 8;
            $svg .= qq{  <circle cx="$x" cy="$circle_y" r="3" class="diagram-open"/>\n};
        }
        else {
            # Finger position
            my $dot_y = $grid_y + ($fret - 0.5) * $cell_height;
            $svg .= qq{  <circle cx="$x" cy="$dot_y" r="5" class="diagram-dot"/>\n};
            
            # Finger number (if provided)
            if ($fingers && defined $fingers->[$i] && $fingers->[$i] ne '-' && $fingers->[$i] =~ /\d/) {
                my $finger_y = $grid_y + $grid_height + 18;
                my $finger = $fingers->[$i];
                $svg .= qq{  <text x="$x" y="$finger_y" text-anchor="middle" class="diagram-finger">$finger</text>\n};
            }
        }
    }
    
    $svg .= qq{</svg>\n};
    
    return $svg;
}

=head2 generate_keyboard_diagram($chord_name, $chord_info)

Generate an SVG diagram for a keyboard/piano chord.

Parameters:
- $chord_name: The name of the chord
- $chord_info: Chord info object with keyboard key information

Returns: SVG markup as a string (currently placeholder)

=cut

sub generate_keyboard_diagram ( $self, $chord_name, $info ) {
    # TODO: Implement full keyboard diagram rendering
    # For now, return a simple placeholder
    my $escape = $self->{escape_fn};
    my $escaped_name = $escape->($chord_name);
    return qq{<span class="diagram-name">$escaped_name</span> (keyboard)};
}

=head2 generate_diagram($chord_name, $chord_info)

Auto-detect chord type and generate appropriate diagram.

Parameters:
- $chord_name: The name of the chord
- $chord_info: Chord info object

Returns: SVG markup as a string

=cut

sub generate_diagram ( $self, $chord_name, $info ) {
    # Determine if this is a keyboard or string instrument
    # Handle both blessed objects and hash refs
    my $has_keys;
    my $has_frets;
    
    if (ref($info) eq 'HASH') {
        $has_keys = exists $info->{kbkeys} || exists $info->{keys};
        $has_frets = exists $info->{frets};
    } else {
        $has_keys = $info->can('kbkeys');
        $has_frets = $info->can('frets');
    }
    
    # If has_frets method/key exists, it's a string instrument
    if ($has_frets) {
        return $self->generate_string_diagram($chord_name, $info);
    }
    # Otherwise if has kbkeys, it's a keyboard
    elsif ($has_keys) {
        my $kbkeys = ref($info) eq 'HASH' ? $info->{kbkeys} || $info->{keys} : $info->kbkeys;
        if (defined $kbkeys) {
            return $self->generate_keyboard_diagram($chord_name, $info);
        }
    }
    
    # Fallback
    return '';
}

# Default HTML escape function
sub _default_escape {
    my $text = shift;
    return '' unless defined $text;
    
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    $text =~ s/'/&#39;/g;
    
    return $text;
}

1;

=head1 AUTHOR

ChordPro Development Team

=head1 LICENSE

This program is free software. You can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
