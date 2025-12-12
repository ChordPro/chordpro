#! perl

package main;

our $config;
our $options;

package ChordPro::Output::HTML5;

# Modern HTML5 output backend for ChordPro
# Uses Object::Pad with ChordProBase class

use v5.26;
use Object::Pad;
use utf8;
use Ref::Util qw(is_ref);
use Text::Layout;

use ChordPro::Output::ChordProBase;

class ChordPro::Output::HTML5
  :isa(ChordPro::Output::ChordProBase) {

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Document Structure
    # =================================================================

    method render_document_begin($metadata) {
        my $title = $self->escape_text($metadata->{title} // 'ChordPro Songbook');

        return qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="generator" content="ChordPro HTML5 Backend">
    <title>$title</title>
    <style>
} . $self->generate_default_css() . qq{
    </style>
</head>
<body class="chordpro-songbook">
};
    }

    method render_document_end() {
        return qq{</body>
</html>
};
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Text Rendering
    # =================================================================

    method render_text($text, $style=undef) {
        my $processed = $self->process_text_with_markup($text);

        return $processed unless $style;

        return qq{<span class="cp-$style">$processed</span>};
    }

    method render_line_break() {
        return "<br>\n";
    }

    method render_paragraph_break() {
        return "\n";
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Structural Elements
    # =================================================================

    method render_section_begin($type, $label=undef) {
        my $label_attr = '';
        if (defined $label && $label ne '') {
            my $escaped_label = $self->escape_text($label);
            $label_attr = qq{ data-label="$escaped_label"};
        }

        return qq{<div class="cp-$type"$label_attr>\n};
    }

    method render_section_end($type) {
        return qq{</div><!-- .cp-$type -->\n};
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Media
    # =================================================================

    method render_image($uri, $opts={}) {
        my $escaped_uri = $self->escape_text($uri);
        my $alt = $self->escape_text($opts->{alt} // '');

        my @attrs;
        push @attrs, qq{src="$escaped_uri"};
        push @attrs, qq{alt="$alt"};
        push @attrs, qq{width="$opts->{width}"} if $opts->{width};
        push @attrs, qq{height="$opts->{height}"} if $opts->{height};
        push @attrs, qq{class="$opts->{class}"} if $opts->{class};

        my $attrs_str = join(' ', @attrs);
        return qq{<img $attrs_str>\n};
    }

    method render_metadata($key, $value) {
        my $escaped_key = $self->escape_text($key);
        my $escaped_value = $self->escape_text($value);

        return qq{<meta name="chordpro:$escaped_key" content="$escaped_value">\n};
    }

    # =================================================================
    # REQUIRED CHORDPRO METHODS - Music Notation
    # =================================================================

    method render_chord($chord_obj) {
        my $chord_name = $self->escape_text($chord_obj->name);
        return qq{<span class="cp-chord">$chord_name</span>};
    }

    method render_songline($phrases, $chords) {
        my $html = qq{<div class="cp-songline">\n};

        # Check if lyrics-only mode
        if ($self->is_lyrics_only()) {
            my $text = join('', @$phrases);
            $html .= qq{  <span class="cp-lyrics">} . $self->escape_text($text) . qq{</span>\n};
            $html .= qq{</div>\n};
            return $html;
        }

        # Check if line has any real chords
        my $has_chords = 0;
        if ($chords) {
            foreach my $chord (@$chords) {
                if ($chord && is_ref($chord) && $chord->key) {
                    $has_chords = 1;
                    last;
                }
            }
        }

        # If no chords in this line, render as simple lyrics (no chord spacing)
        # This applies in single-space mode OR when line genuinely has no chords
        if (!$has_chords) {
            my $text = join('', @$phrases);
            $html .= qq{  <span class="cp-lyrics">} . $self->process_text_with_markup($text) . qq{</span>\n};
            $html .= qq{</div>\n};
            return $html;
        }

        # Render chord-lyric pairs
        for (my $i = 0; $i < @$phrases; $i++) {
            my $phrase = $phrases->[$i] // '';
            my $chord = $chords->[$i];
            
            # Check if this is a chord-only pair (chord with empty lyrics)
            my $is_chord_only = ($chord && is_ref($chord) && $chord->key && $phrase eq '');
            my $pair_class = $is_chord_only ? 'cp-chord-lyric-pair cp-chord-only' : 'cp-chord-lyric-pair';

            $html .= qq{  <span class="$pair_class">\n};

            # Chord span (empty if no chord)
            if ($chord && is_ref($chord) && $chord->key) {
                my $chord_name = $self->process_text_with_markup($chord->chord_display);
                $html .= qq{    <span class="cp-chord">$chord_name</span>\n};
            } else {
                $html .= qq{    <span class="cp-chord cp-chord-empty"></span>\n};
            }

            # Lyric span
            my $processed_phrase = $self->process_text_with_markup($phrase);
            $html .= qq{    <span class="cp-lyrics">$processed_phrase</span>\n};

            $html .= qq{  </span>\n};
        }

        $html .= qq{</div>\n};
        return $html;
    }

    method render_grid_line($tokens) {
        my $html = qq{<div class="cp-gridline">\n};

        foreach my $token (@$tokens) {
            if ($token->{class} eq 'chord') {
                my $chord_name = $self->process_text_with_markup($token->{chord}->key);
                $html .= qq{  <span class="cp-grid-chord">$chord_name</span>\n};
            } else {
                my $symbol = $self->process_text_with_markup($token->{symbol});
                $html .= qq{  <span class="cp-grid-symbol">$symbol</span>\n};
            }
        }

        $html .= qq{</div>\n};
        return $html;
    }

    # =================================================================
    # SONG GENERATION - Override to customize structure
    # =================================================================

    method generate_song($song) {
        my $output = '';

        # Song container
        $output .= qq{<div class="cp-song">\n};

        # Title
        if ($song->{title}) {
            my $processed_title = $self->process_text_with_markup($song->{title});
            $output .= qq{  <h1 class="cp-title">$processed_title</h1>\n};
        }

        # Subtitles
        if ($song->{subtitle}) {
            foreach my $subtitle (@{$song->{subtitle}}) {
                my $processed = $self->process_text_with_markup($subtitle);
                $output .= qq{  <h2 class="cp-subtitle">$processed</h2>\n};
            }
        }

        # Metadata section
        if ($song->{artist} || $song->{composer} || $song->{album}) {
            $output .= qq{  <div class="cp-metadata">\n};

            if ($song->{artist}) {
                foreach my $artist (@{$song->{artist}}) {
                    my $processed = $self->process_text_with_markup($artist);
                    $output .= qq{    <div class="cp-artist">$processed</div>\n};
                }
            }

            if ($song->{composer}) {
                foreach my $composer (@{$song->{composer}}) {
                    my $processed = $self->process_text_with_markup($composer);
                    $output .= qq{    <div class="cp-composer">$processed</div>\n};
                }
            }

            if ($song->{album}) {
                my $processed = $self->process_text_with_markup($song->{album});
                $output .= qq{    <div class="cp-album">$processed</div>\n};
            }

            $output .= qq{  </div>\n};
        }

        # Process song body using base class dispatch
        if ($song->{body}) {
            foreach my $elt (@{$song->{body}}) {
                $output .= $self->dispatch_element($elt);
            }
        }

        # Close song container
        $output .= qq{</div><!-- .cp-song -->\n\n};

        return $output;
    }

    # =================================================================
    # HTML-SPECIFIC OVERRIDES
    # =================================================================

    # Override text formatting helpers
    method wrap_bold($text) {
        return qq{<strong>$text</strong>};
    }

    method wrap_italic($text) {
        return qq{<em>$text</em>};
    }

    method wrap_monospace($text) {
        return qq{<code>$text</code>};
    }

    # Override escape_text for HTML
    method escape_text($text) {
        return '' unless defined $text;

        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        $text =~ s/"/&quot;/g;
        $text =~ s/'/&#39;/g;

        return $text;
    }

    # Process text with Pango-style markup support
    method process_text_with_markup($text) {
        return '' unless defined $text;
        
        # Check if text contains markup tags
        if ($text =~ /</) {
            my $layout = Text::Layout::HTML->new;
            $layout->set_markup($text);
            return $layout->render;
        }
        
        # Plain text - just escape
        return $self->escape_text($text);
    }

    # =================================================================
    # CSS GENERATION
    # =================================================================

    method generate_default_css() {
        my $css_vars = $self->_get_default_css_variables();
        
        return q{
/* ChordPro HTML5 Default Stylesheet */

:root {
} . $css_vars . q{
}

/* Body and Page */
body.chordpro-songbook {
    font-family: var(--cp-font-text);
    font-size: var(--cp-size-text);
    color: var(--cp-color-text);
    line-height: 1.4;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}

/* Song Container */
.cp-song {
    margin-bottom: 3em;
    page-break-after: always;
}

/* Titles */
.cp-title {
    font-size: var(--cp-size-title);
    font-weight: bold;
    margin: 0.5em 0;
    color: var(--cp-color-text);
}

.cp-subtitle {
    font-size: var(--cp-size-subtitle);
    font-style: italic;
    margin: 0.3em 0;
    color: var(--cp-color-text);
}

/* Metadata */
.cp-metadata {
    margin: 1em 0;
    font-size: 0.9em;
}

.cp-artist,
.cp-composer,
.cp-album {
    margin: 0.2em 0;
    color: #555;
}

/* Songline - The Core Innovation */
.cp-songline {
    display: flex;
    flex-wrap: wrap;
    margin-bottom: var(--cp-spacing-line);
    line-height: 1.2;
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
    margin: 0.5em 0;
    font-style: italic;
}

.cp-comment-italic {
    font-style: italic;
}

/* Chorus */
.cp-chorus {
    margin: var(--cp-spacing-verse) 0;
    padding: 0.5em 0 0.5em 1em;
    border-left: 3px solid var(--cp-color-chorus-border);
    background: var(--cp-color-chorus-bg);
}

/* Verse */
.cp-verse {
    margin: var(--cp-spacing-verse) 0;
}

/* Bridge */
.cp-bridge {
    margin: var(--cp-spacing-verse) 0;
    padding-left: 1em;
    border-left: 2px dashed #999;
}

/* Tab */
.cp-tab {
    font-family: var(--cp-font-mono);
    font-size: 0.9em;
    white-space: pre;
    background: #f9f9f9;
    padding: 0.5em;
    border: 1px solid #ddd;
    margin: 1em 0;
    overflow-x: auto;
}

.cp-tabline {
    margin: 0;
}

/* Grid */
.cp-grid {
    font-family: var(--cp-font-mono);
    margin: 1em 0;
    background: #f9f9f9;
    padding: 0.5em;
    border: 1px solid #ddd;
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
    height: 0.8em;
}

/* Print Styles */
\\@media print {
    \\@page {
        size: A4;
        margin: 2cm;
    }

    body.chordpro-songbook {
        max-width: 100%;
        padding: 0;
    }

    .cp-song {
        page-break-after: always;
        page-break-inside: avoid;
    }

    .cp-chorus,
    .cp-verse,
    .cp-bridge {
        page-break-inside: avoid;
    }

    .cp-chord {
        color: #000;
    }
}
};
    }
    
    method _get_default_css_variables() {
        # Return default CSS variables
        # TODO: Make this configurable from config file
        return q{    /* Typography */
    --cp-font-text: Georgia, serif;
    --cp-font-chord: Arial, sans-serif;
    --cp-font-mono: 'Courier New', monospace;

    /* Font Sizes */
    --cp-size-text: 12pt;
    --cp-size-chord: 10pt;
    --cp-size-title: 18pt;
    --cp-size-subtitle: 14pt;
    --cp-size-comment: 11pt;

    /* Colors */
    --cp-color-text: #000;
    --cp-color-chord: #0066cc;
    --cp-color-comment: #666;
    --cp-color-highlight: #ff0;
    --cp-color-chorus-bg: #f5f5f5;
    --cp-color-chorus-border: #0066cc;

    /* Spacing */
    --cp-spacing-line: 0.3em;
    --cp-spacing-verse: 1em;
    --cp-spacing-chord: 0.2em;
};
    }
}

# =================================================================
# COMPATIBILITY WRAPPER - ChordPro calls as class method
# =================================================================

# This sub is called by ChordPro as a class method.
# It creates an instance and manually generates output (can't call inherited method due to name conflict).
sub generate_songbook {
    my ( $pkg, $sb ) = @_;

    # Create instance with config/options from global variables
    my $backend = $pkg->new(
        config => $main::config,
        options => $main::options,
    );

    # Manually implement what Base.generate_songbook does
    # (We can't call the inherited method because the sub name conflicts)
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
    # Split on newlines and keep them attached
    return [ $output =~ /^.*\n?/gm ];
}

# =================================================================
# TEXT::LAYOUT::HTML - Markup renderer for HTML output
# =================================================================

package Text::Layout::HTML;

use parent 'Text::Layout';
use ChordPro::Utils qw(fq);

sub new {
    my ( $pkg, @data ) = @_;
    my $self = $pkg->SUPER::new;
    $self->{_currentfont} = { 
        family => 'default',
        style => 'normal',
        weight => 'normal' 
    };
    $self->{_currentcolor} = 'black';
    $self->{_currentsize} = 12;
    $self;
}

sub html {
    my $t = shift;
    $t =~ s/&/&amp;/g;
    $t =~ s/</&lt;/g;
    $t =~ s/>/&gt;/g;
    $t;
}

sub render {
    my ( $self ) = @_;
    my $res = "";
    
    foreach my $fragment ( @{ $self->{_content} } ) {
        if ( $fragment->{type} eq 'strut' ) {
            next unless length($fragment->{label}//"");
            $res .= "<span id=\"".$fragment->{label}."\"></span>";
            next;
        }
        next unless length($fragment->{text});
        
        my $f = $fragment->{font} || $self->{_currentfont};
        my @c;  # styles
        my @d;  # decorations
        
        if ( $f->{style} eq "italic" ) {
            push( @c, q{font-style:italic} );
        }
        if ( $f->{weight} eq "bold" ) {
            push( @c, q{font-weight:bold} );
        }
        if ( $fragment->{color} && $fragment->{color} ne $self->{_currentcolor} ) {
            push( @c, join(":","color",$fragment->{color}) );
        }
        if ( $fragment->{size} && $fragment->{size} ne $self->{_currentsize} ) {
            push( @c, join(":","font-size",$fragment->{size}) );
        }
        if ( $fragment->{bgcolor} ) {
            push( @c, join(":","background-color",$fragment->{bgcolor}) );
        }
        if ( $fragment->{underline} ) {
            push( @d, q{underline} );
        }
        if ( $fragment->{strikethrough} ) {
            push( @d, q{line-through} );
        }
        push( @c, "text-decoration-line:".join(" ",@d) ) if @d;
        
        my $href = $fragment->{href} // "";
        $res .= "<a href=\"".html($href)."\">" if length($href);
        $res .= "<span style=\"" . join(";",@c) . "\">" if @c;
        $res .= html(fq($fragment->{text}));
        $res .= "</span>" if @c;
        $res .= "</a>" if length($href);
    }
    $res;
}

package ChordPro::Output::HTML5;

1;

=head1 NAME

ChordPro::Output::HTML5 - Modern HTML5 output backend for ChordPro

=head1 SYNOPSIS

    chordpro --generate=HTML5 -o song.html song.cho

=head1 DESCRIPTION

This is a modern HTML5 output backend for ChordPro that implements clean
separation of content and presentation using CSS.

Key features:

=over 4

=item * Object::Pad architecture with ChordProBase

=item * Flexbox-based chord positioning (works with any fonts)

=item * CSS variables for easy customization

=item * Responsive design with print media queries

=item * Embedded CSS (no external dependencies)

=item * Semantic HTML5 structure

=back

=head1 ARCHITECTURE

This backend extends ChordPro::Output::ChordProBase which provides:

=over 4

=item * Directive handler registry and dispatch

=item * Common ChordPro rendering methods

=item * Context tracking (verse, chorus, etc.)

=back

The HTML5 backend implements format-specific rendering:

=over 4

=item * HTML document structure

=item * CSS stylesheet generation

=item * Chord-lyric pair rendering with Flexbox

=item * HTML entity escaping

=back

=head1 CHORD POSITIONING

The core innovation is inline chord-lyric pairs with Flexbox:

    <div class="cp-songline">
      <span class="cp-chord-lyric-pair">
        <span class="cp-chord">C</span>
        <span class="cp-lyrics">Hel</span>
      </span>
      <span class="cp-chord-lyric-pair">
        <span class="cp-chord">G</span>
        <span class="cp-lyrics">lo</span>
      </span>
    </div>

This creates a structural relationship where chords stay above their
lyrics regardless of font families or sizes.

=head1 CSS CUSTOMIZATION

Users can override CSS variables:

    :root {
        --cp-font-text: 'Times New Roman', serif;
        --cp-font-chord: Helvetica, sans-serif;
        --cp-color-chord: #cc0000;
    }

=head1 SEE ALSO

L<ChordPro::Output::ChordProBase>, L<ChordPro::Output::Base>

=head1 AUTHOR

ChordPro Development Team

=cut
