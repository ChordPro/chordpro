#! perl

package main;

our $config;
our $options;

package ChordPro::Output::HTML5Helper::FormatGenerator;

# PDF format → CSS @page rule translator for HTML5 backend
# Extracts format parsing logic for reusability

use v5.26;
use Object::Pad;
use utf8;

class ChordPro::Output::HTML5Helper::FormatGenerator {
    field $config :param;
    field $options :param = {};
    
    # No complex fields to initialize, but BUILD available if needed
    BUILD {
        # Field initialization would go here if needed
    }
    
    # =================================================================
    # PUBLIC API
    # =================================================================
    
    # Main entry point: generate all format rules from PDF config
    method generate_rules() {
        my $pdf = $config->{pdf};
        return $self->_generate_format_rules($pdf);
    }
    
    # =================================================================
    # PRIVATE METHODS - Format Rule Generation
    # =================================================================
    
    method _generate_format_rules($pdf) {
        my $formats = $pdf->{formats};
        my @rules;
        
        # Generate rules for each format type
        # Default format (applies to all pages unless overridden)
        push @rules, $self->_generate_format_rule('default', eval { $formats->{default} }, undef);
        
        # Title page (first page of each song)
        push @rules, $self->_generate_format_rule('title', eval { $formats->{title} }, 'title');
        
        # Very first page
        push @rules, $self->_generate_format_rule('first', eval { $formats->{first} }, ':first');
        
        # Even pages (left in duplex printing)
        # CSS :left selector applies to left-facing pages in duplex printing
        my $default_even = eval { $formats->{'default-even'} };
        if (defined $default_even) {
            push @rules, $self->_generate_format_rule('default-even', $default_even, ':left');
        }
        
        # Odd pages (right in duplex printing) 
        # CSS :right selector applies to right-facing pages in duplex printing
        my $default_odd = eval { $formats->{'default-odd'} };
        if (defined $default_odd) {
            push @rules, $self->_generate_format_rule('default-odd', $default_odd, ':right');
        }
        
        # Title page even/odd variants
        my $title_even = eval { $formats->{'title-even'} };
        if (defined $title_even) {
            push @rules, $self->_generate_format_rule('title-even', $title_even, 'title:left');
        }
        
        my $title_odd = eval { $formats->{'title-odd'} };
        if (defined $title_odd) {
            push @rules, $self->_generate_format_rule('title-odd', $title_odd, 'title:right');
        }
        
        # First page even/odd (though :first usually takes precedence)
        my $first_even = eval { $formats->{'first-even'} };
        if (defined $first_even) {
            push @rules, $self->_generate_format_rule('first-even', $first_even, ':first:left');
        }
        
        my $first_odd = eval { $formats->{'first-odd'} };
        if (defined $first_odd) {
            push @rules, $self->_generate_format_rule('first-odd', $first_odd, ':first:right');
        }
        
        return join("\n\n", grep { $_ } @rules);
    }
    
    method _generate_format_rule($format_name, $format_config, $page_selector=undef) {
        return '' unless $format_config;
        return '' unless ref($format_config) eq 'HASH';
        
        # Determine page selector
        my $selector = $page_selector // $format_name;
        $selector = "\@page $selector" unless $selector =~ /^\@page/;
        $selector = "\@page" if $format_name eq 'default' && !$page_selector;
        
        my @margin_boxes;
        
        # Process title (top)
        if (exists $format_config->{title}) {
            push @margin_boxes, $self->_generate_margin_boxes(
                'top', $format_config->{title}, $format_name
            );
        }
        
        # Process subtitle (top, below title)
        if (exists $format_config->{subtitle}) {
            # Subtitle uses top boxes but with smaller font
            push @margin_boxes, $self->_generate_margin_boxes(
                'subtitle', $format_config->{subtitle}, $format_name
            );
        }
        
        # Process footer (bottom)
        if (exists $format_config->{footer}) {
            push @margin_boxes, $self->_generate_margin_boxes(
                'bottom', $format_config->{footer}, $format_name
            );
        }
        
        return '' unless @margin_boxes;
        
        my $boxes = join("\n\n", grep { $_ } @margin_boxes);
        
        return qq{/* Format: $format_name */
$selector {
$boxes
}};
    }
    
    method _generate_margin_boxes($position, $format_spec, $format_name) {
        # format_spec is either an array [left, center, right] or [[left, center, right]] or false
        return '' if !$format_spec || (ref($format_spec) eq 'SCALAR' && !$$format_spec);
        return '' if $format_spec eq 'false' || $format_spec eq '0';
        
        # Unwrap nested array if present (ChordPro sometimes wraps format arrays)
        if (ref($format_spec) eq 'ARRAY' && @$format_spec == 1 && ref($format_spec->[0]) eq 'ARRAY') {
            $format_spec = $format_spec->[0];
        }
        
        my @boxes;
        my @positions = ('left', 'center', 'right');
        
        # Check if this is an even-page format
        # For even pages (:left in CSS), swap left and right content
        my $is_even_page = ($format_name =~ /-even$/ || $format_name =~ /:left/);
        
        # Handle subtitle positioning (needs different margin-box names)
        my @margin_box_positions = @positions;
        if ($position eq 'subtitle') {
            # For subtitle, we might want to use @top-left-corner, etc.
            # For simplicity, use same as top but with different styling
            $position = 'top';
        }
        
        my $theme = $config->{pdf}->{theme};
        my $color = $theme->{'foreground-medium'} // '#666';

        my $paged_cfg = $config->{html5}->{paged};
        my $font_size = eval { $paged_cfg->{'format-font-size'} }
            // eval { $paged_cfg->{format_font_size} }
            // eval { $config->{pdf}->{formats}->{'font-size'} }
            // '10pt';

        for my $i (0..2) {
            # For even pages, swap left (0) and right (2) indices
            my $content_idx = $is_even_page && ($i == 0 || $i == 2) ? 2 - $i : $i;
            my $content = ref($format_spec) eq 'ARRAY' ? $format_spec->[$content_idx] : '';
            next unless defined $content && $content ne '';
            
            my $box_name = "\@${position}-$positions[$i]";
            my $css_content = $self->_format_content_string($content);
            
            # Generate margin box rule
            push @boxes, qq{    $box_name {
        content: $css_content;
        font-size: $font_size;
        color: $color;
    }};
        }
        
        return join("\n\n", @boxes);
    }
    
    method _format_content_string($content) {
        # Handle references (shouldn't happen, but be safe)
        $content = '' if ref($content);
        
        # Handle empty content
        return 'none' if !defined $content || $content eq '';
        
        # Parse metadata substitutions: %{title}, %{page}, %{artist}, etc.
        my @parts;
        
        while ($content =~ /%\{([^}]+)\}/) {
            my $pre = $`;
            my $meta_key = $1;
            $content = $';
            
            # Add literal text before metadata
            push @parts, qq{"$pre"} if $pre ne '';
            
            # Add metadata reference
            if ($meta_key eq 'page') {
                push @parts, 'counter(page)';
            }
            elsif ($meta_key eq 'title') {
                push @parts, 'string(song-title)';
            }
            elsif ($meta_key eq 'subtitle') {
                push @parts, 'string(song-subtitle)';
            }
            elsif ($meta_key eq 'artist') {
                push @parts, 'string(song-artist)';
            }
            elsif ($meta_key eq 'album') {
                push @parts, 'string(song-album)';
            }
            elsif ($meta_key eq 'arranger') {
                push @parts, 'string(song-arranger)';
            }
            elsif ($meta_key eq 'lyricist') {
                push @parts, 'string(song-lyricist)';
            }
            elsif ($meta_key eq 'copyright') {
                push @parts, 'string(song-copyright)';
            }
            elsif ($meta_key eq 'duration') {
                push @parts, 'string(song-duration)';
            }
            else {
                # Other metadata - use generic string
                push @parts, qq{string(song-$meta_key)};
            }
        }
        
        # Add remaining literal text
        push @parts, qq{"$content"} if $content ne '';
        
        # Return combined content
        return @parts ? join(' ', @parts) : 'none';
    }
}

1;

=head1 NAME

ChordPro::Output::HTML5Helper::FormatGenerator - PDF format to CSS @page translator

=head1 SYNOPSIS

    use ChordPro::Output::HTML5Helper::FormatGenerator;
    
    my $generator = ChordPro::Output::HTML5Helper::FormatGenerator->new(
        config => $config,
        options => $options,
    );
    
    my $css_rules = $generator->generate_rules();

=head1 DESCRIPTION

This module extracts PDF format configuration (headers/footers) and translates
it to CSS @page rules with margin boxes for use with paged.js.

It parses the pdf.formats configuration structure:
- default, title, first formats
- even/odd page variants
- Three-part format specifications [left, center, right]
- Metadata substitutions (%{title}, %{page}, etc.)

And generates CSS like:
    @page title {
        @bottom-left { content: string(song-title); }
        @bottom-right { content: counter(page); }
    }

=head1 METHODS

=head2 generate_rules()

Main entry point. Returns CSS string with all @page rules generated from
pdf.formats configuration.

=head1 SEE ALSO

L<ChordPro::Output::HTML5>

=cut
