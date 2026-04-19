#! perl

# ChordPro::Output::SVG::ChordDiagram
#
# Generate SVG chord diagrams for string and keyboard instruments
# This module can be used by any output backend that needs SVG chord diagrams

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";

package ChordPro::Output::SVG::ChordDiagram;

use ChordPro::Chords ();

our $VERSION = '1.0.0';

=head1 NAME

ChordPro::Output::SVG::ChordDiagram - SVG chord diagram generator

=head1 SYNOPSIS

    use ChordPro::Output::SVG::ChordDiagram;
    
    my $generator = ChordPro::Output::SVG::ChordDiagram->new();
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

        # Optional config for keyboard diagrams
        config        => $args{config},
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
            $svg .= qq{  <text x="$x" y="$marker_y" text-anchor="middle" class="diagram-muted">\x{00d7}</text>\n};
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

my %keytypes =
    (  0 => [0,"L"],
         1 => [0,"B"],
         2 => [1,"M"],
         3 => [1,"B"],
         4 => [2,"R"],
         5 => [3,"L"],
         6 => [3,"B"],
         7 => [4,"M"],
         8 => [4,"B"],
         9 => [5,"M"],
        10 => [5,"B"],
        11 => [6,"R"] );

=head2 generate_keyboard_diagram($chord_name, $chord_info)

Generate an SVG diagram for a keyboard/piano chord.

Parameters:
- $chord_name: The name of the chord
- $chord_info: Chord info object with keyboard key information

Returns: SVG markup as a string (currently placeholder)

=cut

sub generate_keyboard_diagram ( $self, $chord_name, $info ) {
    my $escape = $self->{escape_fn};
    my $escaped_name = $escape->($chord_name);

    my $cfg = _resolve_kb_config($self->{config});
    my $kw = $cfg->{width};
    my $kh = $cfg->{height};
    my $keys = $cfg->{keys};
    my $base = $cfg->{base};
    my $lw = $cfg->{linewidth} * $kw;
    my $pressed_color = $cfg->{pressed_color};
    my $stroke_color = $cfg->{stroke_color};

    my $allowed = { map { $_ => 1 } qw(7 10 14 17 21) };
    $keys = 14 unless $allowed->{$keys};

    my $base_k = 0;
    my $base_note = 0;
    if ( defined $base && uc($base) eq 'F' ) {
        $base_k = 3;
        $base_note = 5;
    }

    my @keys = @{ ChordPro::Chords::get_keys($info) // [] };

    my $root_ord = ref($info) eq 'HASH' ? ($info->{root_ord} // 0) : ($info->root_ord // 0);

    my $kk = ($keys % 7 == 0)
      ? 12 * int($keys / 7)
      : $keys == 10 ? 17 : 29;

    my $kd = 0;
    if (@keys) {
        $kd = -int(($keys[0] + $root_ord) / 12) * 12;
        $kd += 12 if ($keys[0] + $root_ord) < $base_note;
    }

    my $margin_top = 20;
    my $margin_bottom = 6;
    my $svg_width = $keys * $kw + $lw;
    my $svg_height = $kh + $margin_top + $margin_bottom;
    my $y = $margin_top;
    my $t = $y;
    my $m = $y + $kh / 2;
    my $b = $y + $kh;
    my $l = 0;
    my $ml = $l + $kw / 3;
    my $mr = $l + 2 * $kw / 3;
    my $r = $l + $kw;
    my $xr = $l + 4 * $kw / 3;

    my $svg = qq{<svg class="cp-diagram-svg" viewBox="0 0 $svg_width $svg_height" xmlns="http://www.w3.org/2000/svg">\n};
    my $name_x = $svg_width / 2;
    $svg .= qq{  <text x="$name_x" y="14" text-anchor="middle" class="diagram-name">$escaped_name</text>\n};

    my %pressed;
    for my $key (@keys) {
        my $k = $key + $kd + $root_ord;
        $k += 12 if $k < 0;
        $k -= 12 while $k >= $kk;

        my $o = int($k / 12);
        $k %= 12;
        my ($pos, $type) = @{ $keytypes{$k} };
        $pos -= $base_k;
        $pos += 7, $o-- while $pos < 0;
        $pos %= 7;
        $pos += 7 * $o if $o >= 1;

        next if $pos < 0 || $pos >= $keys;
        $pressed{"$pos:$type"} = 1;
    }

    my @white_shapes;
    my @black_shapes;
    for my $k (0 .. $kk - 1) {
        my $o = int($k / 12);
        my $note = $k % 12;
        my ($pos, $type) = @{ $keytypes{$note} };
        $pos -= $base_k;
        $pos += 7, $o-- while $pos < 0;
        $pos %= 7;
        $pos += 7 * $o if $o >= 1;
        next if $pos < 0 || $pos >= $keys;

        my $pkw = $pos * $kw;
        if ($type eq 'B') {
            push @black_shapes, {
                x => $pkw + $mr,
                y => $t,
                width => $xr - $mr,
                height => $kh / 2,
                pressed => $pressed{"$pos:$type"},
            };
        } else {
            my @points;
            if ($type eq 'L') {
                @points = (
                    [$pkw + $l,  $b],
                    [$pkw + $l,  $t],
                    [$pkw + $mr, $t],
                    [$pkw + $mr, $m],
                    [$pkw + $r,  $m],
                    [$pkw + $r,  $b],
                );
            } elsif ($type eq 'R') {
                @points = (
                    [$pkw + $l,  $b],
                    [$pkw + $l,  $m],
                    [$pkw + $ml, $m],
                    [$pkw + $ml, $t],
                    [$pkw + $r,  $t],
                    [$pkw + $r,  $b],
                );
            } else {
                @points = (
                    [$pkw + $l,  $b],
                    [$pkw + $l,  $m],
                    [$pkw + $ml, $m],
                    [$pkw + $ml, $t],
                    [$pkw + $mr, $t],
                    [$pkw + $mr, $m],
                    [$pkw + $r,  $m],
                    [$pkw + $r,  $b],
                );
            }

            my $points = join(' ', map { $_->[0] . ',' . $_->[1] } @points);
            push @white_shapes, {
                points => $points,
                pressed => $pressed{"$pos:$type"},
            };
        }
    }

    for my $shape (@white_shapes) {
        my $class = $shape->{pressed} ? 'diagram-key-white diagram-key-pressed' : 'diagram-key-white';
        my $fill = $shape->{pressed} ? qq{ fill="$pressed_color"} : '';
        $svg .= qq{  <polygon points="$shape->{points}" class="$class" stroke="$stroke_color" stroke-width="$lw"$fill/>\n};
    }

    for my $shape (@black_shapes) {
        my $class = $shape->{pressed} ? 'diagram-key-black diagram-key-pressed' : 'diagram-key-black';
        my $fill = $shape->{pressed} ? qq{ fill="$pressed_color"} : '';
        $svg .= qq{  <rect x="$shape->{x}" y="$shape->{y}" width="$shape->{width}" height="$shape->{height}" class="$class" stroke="$stroke_color" stroke-width="$lw"$fill/>\n};
    }

    $svg .= qq{</svg>\n};
    return $svg;
}

sub _resolve_kb_config {
    my ($config) = @_;
    $config //= {};

    my $html5_cfg = eval { $config->{html5} } // {};
    my $pdf_cfg = eval { $config->{pdf} } // {};
    my $kb_cfg = eval { $html5_cfg->{kbdiagrams} }
      // eval { $pdf_cfg->{kbdiagrams} }
      // {};

    my $theme = eval { $html5_cfg->{theme} }
      // eval { $pdf_cfg->{theme} }
      // {};

    my $pressed = eval { $kb_cfg->{pressed} } // 'foreground-medium';
    my $pressed_color = _resolve_theme_color($pressed, $theme);

    return {
        width => eval { $kb_cfg->{width} } // 4,
        height => eval { $kb_cfg->{height} } // 20,
        keys => eval { $kb_cfg->{keys} } // 14,
        base => eval { $kb_cfg->{base} } // 'C',
        linewidth => eval { $kb_cfg->{linewidth} } // 0.1,
        pressed_color => $pressed_color,
        stroke_color => _resolve_theme_color('foreground', $theme),
    };
}

sub _resolve_theme_color {
    my ($color, $theme) = @_;
    $theme //= {};
    return '#000' unless defined $color;

    if ($color =~ /^(foreground|foreground-medium|foreground-light|background)$/) {
        my $theme_color = eval { $theme->{$color} };
        return $theme_color if defined $theme_color && $theme_color ne '';
    }

    return $color;
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
