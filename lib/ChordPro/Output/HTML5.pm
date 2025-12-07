#! perl

package main;

our $config;
our $options;

package ChordPro::Output::HTML5;

# Modern HTML5 output backend for ChordPro
# Uses clean architecture with CSS for styling

use v5.26;
use utf8;
use strict;
use warnings;
use feature 'signatures';

my $single_space = 0;  # suppress chords line when empty
my $lyrics_only = 0;   # suppress all chords lines

sub generate_songbook {
    my ( $self, $sb ) = @_;
    
    $single_space = $options->{'single-space'};
    $lyrics_only = $config->{settings}->{'lyrics-only'};
    
    my @book;
    
    # Document begin
    my $title = $sb->{songs}->[0]->{title} // 'ChordPro Songbook';
    push @book, document_begin($title);
    
    # Generate each song
    foreach my $song ( @{$sb->{songs}} ) {
        push @book, @{generate_song($song)};
    }
    
    # Document end
    push @book, document_end();
    
    return \@book;
}

sub generate_song {
    my ( $song ) = @_;
    my @output;
    
    # Song container
    push @output, qq{<div class="cp-song">\n};
    
    # Title
    if ($song->{title}) {
        my $escaped_title = escape_html($song->{title});
        push @output, qq{  <h1 class="cp-title">$escaped_title</h1>\n};
    }
    
    # Subtitles
    if ($song->{subtitle}) {
        foreach my $subtitle (@{$song->{subtitle}}) {
            my $escaped = escape_html($subtitle);
            push @output, qq{  <h2 class="cp-subtitle">$escaped</h2>\n};
        }
    }
    
    # Metadata section
    if ($song->{artist} || $song->{composer} || $song->{album}) {
        push @output, qq{  <div class="cp-metadata">\n};
        
        if ($song->{artist}) {
            foreach my $artist (@{$song->{artist}}) {
                my $escaped = escape_html($artist);
                push @output, qq{    <div class="cp-artist">$escaped</div>\n};
            }
        }
        
        if ($song->{composer}) {
            foreach my $composer (@{$song->{composer}}) {
                my $escaped = escape_html($composer);
                push @output, qq{    <div class="cp-composer">$escaped</div>\n};
            }
        }
        
        if ($song->{album}) {
            my $escaped = escape_html($song->{album});
            push @output, qq{    <div class="cp-album">$escaped</div>\n};
        }
        
        push @output, qq{  </div>\n};
    }
    
    # Process song body
    if ($song->{body}) {
        foreach my $elt (@{$song->{body}}) {
            push @output, dispatch_element($elt);
        }
    }
    
    # Close song container
    push @output, qq{</div><!-- .cp-song -->\n\n};
    
    return \@output;
}

# =================================================================
# ELEMENT DISPATCH
# =================================================================

sub dispatch_element {
    my ($elt) = @_;
    my $type = $elt->{type};
    
    return songline($elt)     if $type eq 'songline';
    return comment_text($elt) if $type eq 'comment';
    return tabline($elt)      if $type eq 'tabline';
    return gridline($elt)     if $type eq 'gridline';
    return empty_line()       if $type eq 'empty';
    
    # Handle container elements with body
    if ($elt->{body}) {
        my @output;
        if ($type eq 'chorus') {
            push @output, chorus_begin($elt);
            foreach my $child (@{$elt->{body}}) {
                push @output, dispatch_element($child);
            }
            push @output, chorus_end();
        }
        elsif ($type eq 'verse') {
            push @output, verse_begin($elt);
            foreach my $child (@{$elt->{body}}) {
                push @output, dispatch_element($child);
            }
            push @output, verse_end();
        }
        elsif ($type eq 'bridge') {
            push @output, bridge_begin($elt);
            foreach my $child (@{$elt->{body}}) {
                push @output, dispatch_element($child);
            }
            push @output, bridge_end();
        }
        elsif ($type eq 'tab') {
            push @output, tab_begin($elt);
            foreach my $child (@{$elt->{body}}) {
                push @output, dispatch_element($child);
            }
            push @output, tab_end();
        }
        elsif ($type eq 'grid') {
            push @output, grid_begin($elt);
            foreach my $child (@{$elt->{body}}) {
                push @output, dispatch_element($child);
            }
            push @output, grid_end();
        }
        return join('', @output);
    }
    
    return '';
}

# =================================================================
# SONGLINE RENDERING - Core chord positioning
# =================================================================

sub songline {
    my ($elt) = @_;
    my $phrases = $elt->{phrases};
    my $chords = $elt->{chords};
    
    my $html = qq{<div class="cp-songline">\n};
    
    # Check if lyrics-only mode
    if ($lyrics_only) {
        my $text = join('', @$phrases);
        $html .= qq{  <span class="cp-lyrics">} . escape_html($text) . qq{</span>\n};
        $html .= qq{</div>\n};
        return $html;
    }
    
    # Check if single-space mode (suppress empty chord lines)
    my $has_chords = 0;
    if ($chords) {
        foreach my $chord (@$chords) {
            if ($chord && ref($chord) && $chord->key) {
                $has_chords = 1;
                last;
            }
        }
    }
    
    if ($single_space && !$has_chords) {
        my $text = join('', @$phrases);
        $html .= qq{  <span class="cp-lyrics">} . escape_html($text) . qq{</span>\n};
        $html .= qq{</div>\n};
        return $html;
    }
    
    # Render chord-lyric pairs
    for (my $i = 0; $i < @$phrases; $i++) {
        my $phrase = $phrases->[$i] // '';
        my $chord = $chords->[$i];
        
        $html .= qq{  <span class="cp-chord-lyric-pair">\n};
        
        # Chord span (empty if no chord)
        if ($chord && ref($chord) && $chord->key) {
            my $chord_name = escape_html($chord->name);
            $html .= qq{    <span class="cp-chord">$chord_name</span>\n};
        } else {
            $html .= qq{    <span class="cp-chord cp-chord-empty"></span>\n};
        }
        
        # Lyric span
        my $escaped_phrase = escape_html($phrase);
        $html .= qq{    <span class="cp-lyrics">$escaped_phrase</span>\n};
        
        $html .= qq{  </span>\n};
    }
    
    $html .= qq{</div>\n};
    return $html;
}

# =================================================================
# OTHER ELEMENTS
# =================================================================

sub comment_text {
    my ($elt) = @_;
    my $text = escape_html($elt->{text});
    my $class = $elt->{italic} ? 'cp-comment cp-comment-italic' : 'cp-comment';
    return qq{<div class="$class">$text</div>\n};
}

sub tabline {
    my ($elt) = @_;
    my $text = escape_html($elt->{text});
    return qq{<div class="cp-tabline">$text</div>\n};
}

sub gridline {
    my ($elt) = @_;
    my $tokens = $elt->{tokens};
    my $html = qq{<div class="cp-gridline">\n};
    
    foreach my $token (@$tokens) {
        if ($token->{class} eq 'chord') {
            my $chord_name = escape_html($token->{chord}->key);
            $html .= qq{  <span class="cp-grid-chord">$chord_name</span>\n};
        } else {
            my $symbol = escape_html($token->{symbol});
            $html .= qq{  <span class="cp-grid-symbol">$symbol</span>\n};
        }
    }
    
    $html .= qq{</div>\n};
    return $html;
}

sub empty_line {
    return qq{<div class="cp-empty">&nbsp;</div>\n};
}

# =================================================================
# ENVIRONMENT BLOCKS
# =================================================================

sub chorus_begin {
    my ($elt) = @_;
    return qq{<div class="cp-chorus">\n};
}

sub chorus_end {
    return qq{</div><!-- .cp-chorus -->\n};
}

sub verse_begin {
    my ($elt) = @_;
    return qq{<div class="cp-verse">\n};
}

sub verse_end {
    return qq{</div><!-- .cp-verse -->\n};
}

sub bridge_begin {
    my ($elt) = @_;
    return qq{<div class="cp-bridge">\n};
}

sub bridge_end {
    return qq{</div><!-- .cp-bridge -->\n};
}

sub tab_begin {
    my ($elt) = @_;
    return qq{<div class="cp-tab">\n};
}

sub tab_end {
    return qq{</div><!-- .cp-tab -->\n};
}

sub grid_begin {
    my ($elt) = @_;
    return qq{<div class="cp-grid">\n};
}

sub grid_end {
    return qq{</div><!-- .cp-grid -->\n};
}

# =================================================================
# DOCUMENT STRUCTURE
# =================================================================

sub document_begin {
    my ($title) = @_;
    my $escaped_title = escape_html($title);
    
    return qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="generator" content="ChordPro HTML5 Backend">
    <title>$escaped_title</title>
    <style>
} . generate_default_css() . qq{
    </style>
</head>
<body class="chordpro-songbook">
};
}

sub document_end {
    return qq{</body>
</html>
};
}

# =================================================================
# CSS GENERATION
# =================================================================

sub generate_default_css {
    return q{
/* ChordPro HTML5 Default Stylesheet */

:root {
    /* Typography */
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
}

.cp-chord {
    font-family: var(--cp-font-chord);
    font-size: var(--cp-size-chord);
    color: var(--cp-color-chord);
    font-weight: bold;
    line-height: 1.2;
    min-height: 1.2em;
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
@media print {
    @page {
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

# =================================================================
# HELPER FUNCTIONS
# =================================================================

sub escape_html {
    my ($text) = @_;
    return '' unless defined $text;
    
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    $text =~ s/'/&#39;/g;
    
    return $text;
}

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

=item * Flexbox-based chord positioning (works with any fonts)

=item * CSS variables for easy customization

=item * Responsive design with print media queries

=item * Embedded CSS (no external dependencies)

=item * Semantic HTML5 structure

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

=head1 AUTHOR

ChordPro Development Team

=cut
