#! perl

package main;

our $config;
our $options;

package ChordPro::Output::HTML5Paged;

# HTML5 output backend with paged.js for printing
# Extends HTML5 backend with print-optimized layout

use v5.26;
use Object::Pad;
use utf8;

use ChordPro::Output::HTML5;

class ChordPro::Output::HTML5Paged
  :isa(ChordPro::Output::HTML5) {

    # =================================================================
    # OVERRIDE DOCUMENT STRUCTURE FOR PAGED.JS
    # =================================================================

    method render_document_begin($metadata) {
        my $title = $self->escape_text($metadata->{title} // 'ChordPro Songbook');
        my $pagedjs_version = '0.4.3';

        return qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="generator" content="ChordPro HTML5Paged Backend">
    <title>$title</title>

    <!-- Paged.js for pagination -->
    <script src="https://unpkg.com/pagedjs\@$pagedjs_version/dist/paged.polyfill.js"></script>

    <style>
} . $self->generate_paged_css() . qq{
    </style>
</head>
<body class="chordpro-songbook chordpro-paged">
    <div class="book-content">
};
    }

    method render_document_end() {
        return qq{    </div>
</body>
</html>
};
    }

    # =================================================================
    # PAGED.JS CSS GENERATION
    # =================================================================

    method generate_paged_css() {
        my $config = $self->config // {};
        my $pdf = $config->{pdf} // {};
        
        # Check for html5.paged config (may not exist in all configs)
        my $html5_paged = {};
        if (exists $config->{html5} && ref($config->{html5}) eq 'HASH') {
            $html5_paged = $config->{html5}->{paged} // {};
        }

        # Get page setup configuration (html5.paged overrides pdf settings)
        my $papersize = $html5_paged->{papersize} // $pdf->{papersize} // 'a4';
        my $margintop = $html5_paged->{margintop} // $pdf->{margintop} // 80;
        my $marginbottom = $html5_paged->{marginbottom} // $pdf->{marginbottom} // 40;
        my $marginleft = $html5_paged->{marginleft} // $pdf->{marginleft} // 40;
        my $marginright = $html5_paged->{marginright} // $pdf->{marginright} // 40;
        my $headspace = $html5_paged->{headspace} // $pdf->{headspace} // 60;
        my $footspace = $html5_paged->{footspace} // $pdf->{footspace} // 20;

        # Convert papersize to CSS
        my $css_pagesize = $self->_format_papersize($papersize);

        # Convert margins to CSS (PDF uses pt, we convert to mm for paged.js)
        my $css_margins = $self->_format_margins($margintop, $marginright, $marginbottom, $marginleft);
        
        # Generate format rules (headers/footers)
        my $format_rules = $self->_generate_format_rules($pdf);

        return qq{
/* ChordPro HTML5 with Paged.js Stylesheet */

/* Page Setup */
\@page {
    size: $css_pagesize;
    margin: $css_margins;
}

$format_rules

/* Page-specific rules are generated from config above */

/* Root variables */
:root {
    /* Typography */
    --cp-font-text: Georgia, serif;
    --cp-font-chord: Arial, sans-serif;
    --cp-font-mono: 'Courier New', monospace;

    /* Font Sizes */
    --cp-size-text: 11pt;
    --cp-size-chord: 9pt;
    --cp-size-title: 16pt;
    --cp-size-subtitle: 13pt;
    --cp-size-comment: 10pt;

    /* Colors */
    --cp-color-text: #000;
    --cp-color-chord: #0066cc;
    --cp-color-comment: #666;
    --cp-color-chorus-bg: #f5f5f5;
    --cp-color-chorus-border: #0066cc;

    /* Spacing */
    --cp-spacing-line: 0.2em;
    --cp-spacing-verse: 0.8em;
    --cp-spacing-chord: 0.15em;
}

/* Body and container */
body.chordpro-paged {
    font-family: var(--cp-font-text);
    font-size: var(--cp-size-text);
    color: var(--cp-color-text);
    line-height: 1.3;
    margin: 0;
    padding: 0;
}

.book-content {
    width: 100%;
}

/* Song Container */
.cp-song {
    page: song;
    page-break-before: always;
    page-break-after: always;
    margin-bottom: 2em;
}

.cp-song:first-child {
    page-break-before: avoid;
}

/* Set running header with song title */
.cp-title {
    string-set: song-title content();
}

/* Titles */
.cp-title {
    font-size: var(--cp-size-title);
    font-weight: bold;
    margin: 0 0 0.5em 0;
    color: var(--cp-color-text);
    page-break-after: avoid;
}

.cp-subtitle {
    font-size: var(--cp-size-subtitle);
    font-style: italic;
    margin: 0 0 0.3em 0;
    color: var(--cp-color-text);
    page-break-after: avoid;
}

/* Metadata */
.cp-metadata {
    margin: 0.8em 0 1.2em 0;
    font-size: 0.9em;
    page-break-after: avoid;
}

.cp-artist,
.cp-composer,
.cp-album {
    margin: 0.2em 0;
    color: #555;
}

/* Songline - Flexbox chord positioning */
.cp-songline {
    display: flex;
    flex-wrap: wrap;
    margin-bottom: var(--cp-spacing-line);
    line-height: 1.2;
    page-break-inside: avoid;
}

.cp-chord-lyric-pair {
    display: inline-flex;
    flex-direction: column;
    align-items: flex-start;
    vertical-align: bottom;
}

/* Spacing for chord-only pairs (chords with no lyrics) */
.cp-chord-only {
    margin-right: 0.5em;
}

.cp-chord {
    font-family: var(--cp-font-chord);
    font-size: var(--cp-size-chord);
    color: var(--cp-color-chord);
    font-weight: bold;
    line-height: 1.2;
    min-height: 1.2em;
    height: 1.2em;
    padding-bottom: var(--cp-spacing-chord);
}

.cp-chord-empty {
    visibility: hidden;
}

.cp-lyrics {
    font-family: var(--cp-font-text);
    font-size: var(--cp-size-text);
    white-space: pre;
    line-height: 1.2;
}

/* Comments */
.cp-comment {
    font-size: var(--cp-size-comment);
    color: var(--cp-color-comment);
    margin: 0.4em 0;
    font-style: italic;
    page-break-inside: avoid;
}

.cp-comment-italic {
    font-style: italic;
}

/* Chorus */
.cp-chorus {
    margin: var(--cp-spacing-verse) 0;
    padding: 0.4em 0 0.4em 1em;
    border-left: 3px solid var(--cp-color-chorus-border);
    background: var(--cp-color-chorus-bg);
    page-break-inside: avoid;
}

/* Verse */
.cp-verse {
    margin: var(--cp-spacing-verse) 0;
    page-break-inside: avoid;
}

/* Bridge */
.cp-bridge {
    margin: var(--cp-spacing-verse) 0;
    padding-left: 1em;
    border-left: 2px dashed #999;
    page-break-inside: avoid;
}

/* Tab */
.cp-tab {
    font-family: var(--cp-font-mono);
    font-size: 0.85em;
    white-space: pre;
    background: #f9f9f9;
    padding: 0.4em;
    border: 1px solid #ddd;
    margin: 0.8em 0;
    page-break-inside: avoid;
}

.cp-tabline {
    margin: 0;
}

/* Grid */
.cp-grid {
    font-family: var(--cp-font-mono);
    margin: 0.8em 0;
    background: #f9f9f9;
    padding: 0.4em;
    border: 1px solid #ddd;
    page-break-inside: avoid;
}

.cp-gridline {
    display: flex;
    gap: 0.5em;
    margin: 0.2em 0;
}

.cp-grid-chord {
    font-family: var(--cp-font-chord);
    color: var(--cp-color-chord);
    font-weight: bold;
    min-width: 3em;
}

.cp-grid-symbol {
    color: #999;
}

/* Empty lines */
.cp-empty {
    height: 0.6em;
}
/* Chord Diagrams */
.cp-chord-diagrams {
    display: flex;
    flex-wrap: wrap;
    gap: 1em;
    margin: 1em 0;
    page-break-inside: avoid;
}

.cp-chord-diagram {
    display: inline-block;
    margin: 0;
}

.cp-diagram-svg {
    width: 4em;
    height: auto;
}

.diagram-name {
    font-family: var(--cp-font-chord);
    font-size: 14px;
    font-weight: bold;
    fill: var(--cp-color-chord);
}

.diagram-fret-marker {
    font-size: 12px;
    fill: #666;
}

.diagram-finger {
    font-size: 10px;
    fill: #fff;
    font-weight: bold;
}

.diagram-dot {
    fill: #000;
}

.diagram-open {
    stroke: #000;
    fill: none;
    stroke-width: 2;
}

.diagram-muted {
    stroke: #000;
    fill: none;
    stroke-width: 2;
}
/* Screen preview styles */
\@media screen {
    body.chordpro-paged {
        background: #525252;
        padding: 20px;
    }

    .book-content {
        background: white;
        box-shadow: 0 0 10px rgba(0,0,0,0.3);
        max-width: 210mm;
        margin: 0 auto;
        padding: 15mm 20mm;
    }

    .cp-song {
        page-break-before: auto;
        border-bottom: 1px dashed #ccc;
        padding-bottom: 2em;
    }

    .cp-song:last-child {
        border-bottom: none;
    }
}

/* Print styles */
\@media print {
    body.chordpro-paged {
        background: white;
        padding: 0;
    }

    .book-content {
        background: white;
        box-shadow: none;
        max-width: none;
        margin: 0;
        padding: 0;
    }

    /* Let paged.js handle page breaks */
    .cp-song {
        border-bottom: none;
    }
}
};
    }

    # =================================================================
    # CONFIGURATION HELPER METHODS
    # =================================================================

    method _format_papersize($papersize) {
        # Named paper sizes (case-insensitive)
        my %sizes = (
            a4     => 'A4',
            letter => 'letter',
            legal  => 'legal',
            a3     => 'A3',
            a5     => 'A5',
            b5     => 'B5',
        );

        # Check if it's a named size
        if (!ref($papersize)) {
            my $lower = lc($papersize);
            return $sizes{$lower} if exists $sizes{$lower};
            return uc($papersize);  # Return as-is, uppercase
        }

        # Array format: [width, height] in pt -> convert to mm
        if (ref($papersize) eq 'ARRAY' && @$papersize == 2) {
            my $width_mm = $self->_pt_to_mm($papersize->[0]);
            my $height_mm = $self->_pt_to_mm($papersize->[1]);
            return sprintf("%.2fmm %.2fmm", $width_mm, $height_mm);
        }

        # Fallback
        return 'A4';
    }

    method _format_margins {
        my ($top, $right, $bottom, $left) = @_;

        # Convert pt to mm and format as CSS margin shorthand
        my $top_mm = $self->_pt_to_mm($top);
        my $right_mm = $self->_pt_to_mm($right);
        my $bottom_mm = $self->_pt_to_mm($bottom);
        my $left_mm = $self->_pt_to_mm($left);

        return sprintf("%.2fmm %.2fmm %.2fmm %.2fmm",
                      $top_mm, $right_mm, $bottom_mm, $left_mm);
    }

    method _pt_to_mm($pt) {
        # 1 pt = 0.352778 mm
        return $pt * 0.352778;
    }

    method _mm_to_pt($mm) {
        # 1 mm = 2.83465 pt
        return $mm * 2.83465;
    }
    
    # =================================================================
    # PHASE 3: HEADERS & FOOTERS CONFIGURATION
    # =================================================================
    
    method _generate_format_rules($pdf) {
        my $formats = $pdf->{formats} // {};
        my @rules;
        
        # Generate rules for each format type
        push @rules, $self->_generate_format_rule('default', $formats->{default});
        push @rules, $self->_generate_format_rule('title', $formats->{title});
        push @rules, $self->_generate_format_rule('first', $formats->{first}, ':first');
        
        # Handle even page formats if they exist
        push @rules, $self->_generate_format_rule('default-even', $formats->{'default-even'}, ':left')
            if exists $formats->{'default-even'};
        push @rules, $self->_generate_format_rule('title-even', $formats->{'title-even'})
            if exists $formats->{'title-even'};
        
        return join("\n\n", grep { $_ } @rules);
    }
    
    method _generate_format_rule($format_name, $format_config, $page_selector=undef) {
        return '' unless $format_config;
        
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
        
        # Handle subtitle positioning (needs different margin-box names)
        my @margin_box_positions = @positions;
        if ($position eq 'subtitle') {
            # For subtitle, we might want to use @top-left-corner, etc.
            # For simplicity, use same as top but with different styling
            $position = 'top';
        }
        
        for my $i (0..2) {
            my $content = ref($format_spec) eq 'ARRAY' ? $format_spec->[$i] : '';
            next unless defined $content && $content ne '';
            
            my $box_name = "\@${position}-$positions[$i]";
            my $css_content = $self->_format_content_string($content);
            
            # Generate margin box rule
            push @boxes, qq{    $box_name {
        content: $css_content;
        font-size: 10pt;
        color: #666;
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

# =================================================================
# COMPATIBILITY WRAPPER - ChordPro calls as class method
# =================================================================

sub generate_songbook {
    my ( $pkg, $sb ) = @_;

    # Create instance with config/options from global variables
    my $backend = $pkg->new(
        config => $main::config,
        options => $main::options,
    );

    # Manually implement what Base.generate_songbook does
    my $output = '';

    # Begin document
    $output .= $backend->render_document_begin({
        title => $sb->{title} // $sb->{songs}->[0]->{title} // 'Songbook',
        songs => scalar(@{$sb->{songs}}),
    });

    # Process each song
    foreach my $s (@{$sb->{songs}}) {
        $output .= $backend->generate_song($s);
    }

    # End document
    $output .= $backend->render_document_end();

    # Return as array ref of lines (ChordPro expects this format)
    return [ $output =~ /^.*\n?/gm ];
}

1;

=head1 NAME

ChordPro::Output::HTML5Paged - HTML5 output with paged.js for printing

=head1 SYNOPSIS

    chordpro --generate=HTML5Paged -o songbook.html songs.cho

=head1 DESCRIPTION

This backend extends the HTML5 output backend with paged.js support for
professional printing and PDF generation.

Key features:

=over 4

=item * Based on HTML5 backend (inherits all features)

=item * Paged.js integration for pagination

=item * Print-optimized CSS with @page rules

=item * Automatic page breaks between songs

=item * Running headers with song titles

=item * Page numbers in footer

=item * Screen preview mode

=item * Professional print layout

=back

=head1 USAGE

Generate a songbook with paged.js:

    chordpro --generate=HTML5Paged -o songbook.html *.cho

Open the generated HTML file in a browser. Paged.js will automatically:

=over 4

=item * Paginate the content

=item * Add page numbers

=item * Insert running headers

=item * Handle page breaks

=back

To generate a PDF, use the browser's "Print to PDF" function or use a
headless browser like Puppeteer:

    npx puppeteer print songbook.html songbook.pdf

=head1 PAGED.JS

Paged.js is a polyfill for paged media CSS. It allows you to create
print-ready documents using web technologies. The library is loaded
from a CDN and requires an internet connection on first view.

Learn more at: https://pagedjs.org/

=head1 CUSTOMIZATION

The CSS can be customized by modifying the generate_paged_css() method
or by adding a custom stylesheet in the document.

=head1 SEE ALSO

L<ChordPro::Output::HTML5>, L<ChordPro::Output::ChordProBase>, L<ChordPro::Output::Base>

=head1 AUTHOR

ChordPro Development Team

=cut
