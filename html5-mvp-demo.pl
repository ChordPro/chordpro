#!/usr/bin/perl

# Standalone HTML5 backend MVP demonstration
# This creates a complete HTML file from a simple ChordPro song structure

use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

# =================================================================
# MINIMAL SONG STRUCTURE (what ChordPro parser creates)
# =================================================================

my $song = {
    title => "Amazing Grace",
    subtitle => ["Traditional Hymn"],
    artist => ["John Newton"],
    composer => ["John Newton"],
    body => [
        # Verse 1
        {
            type => 'verse',
            body => [
                {
                    type => 'songline',
                    phrases => ['A', 'mazing ', 'grace! How ', 'sweet the ', 'sound'],
                    chords => [
                        mock_chord('G'),
                        mock_chord('G/B'),
                        mock_chord('C'),
                        mock_chord('G'),
                        undef,
                    ],
                },
                {
                    type => 'songline',
                    phrases => ['That ', 'saved a ', 'wretch like ', 'me!'],
                    chords => [
                        mock_chord('G'),
                        mock_chord('Em'),
                        mock_chord('D'),
                        undef,
                    ],
                },
            ],
        },
        # Comment
        {
            type => 'comment',
            text => 'Simple and beautiful',
        },
        # Chorus
        {
            type => 'chorus',
            body => [
                {
                    type => 'songline',
                    phrases => ["'Twas ", 'grace that ', 'taught my ', 'heart to fear,'],
                    chords => [
                        mock_chord('G'),
                        mock_chord('C'),
                        mock_chord('G'),
                        undef,
                    ],
                },
                {
                    type => 'songline',
                    phrases => ['And ', 'grace my ', 'fears relieved;'],
                    chords => [
                        mock_chord('Em'),
                        mock_chord('D'),
                        undef,
                    ],
                },
            ],
        },
    ],
};

# =================================================================
# HTML5 BACKEND IMPLEMENTATION
# =================================================================

print document_begin($song->{title});
print join('', @{generate_song($song)});
print document_end();

sub generate_song {
    my ($song) = @_;
    my @output;
    
    # Song container
    push @output, qq{<div class="cp-song">\n};
    
    # Title
    if ($song->{title}) {
        push @output, qq{  <h1 class="cp-title">} . escape_html($song->{title}) . qq{</h1>\n};
    }
    
    # Subtitles
    if ($song->{subtitle}) {
        foreach my $subtitle (@{$song->{subtitle}}) {
            push @output, qq{  <h2 class="cp-subtitle">} . escape_html($subtitle) . qq{</h2>\n};
        }
    }
    
    # Metadata
    if ($song->{artist} || $song->{composer}) {
        push @output, qq{  <div class="cp-metadata">\n};
        if ($song->{artist}) {
            foreach my $artist (@{$song->{artist}}) {
                push @output, qq{    <div class="cp-artist">} . escape_html($artist) . qq{</div>\n};
            }
        }
        if ($song->{composer}) {
            foreach my $composer (@{$song->{composer}}) {
                push @output, qq{    <div class="cp-composer">} . escape_html($composer) . qq{</div>\n};
            }
        }
        push @output, qq{  </div>\n};
    }
    
    # Process body
    if ($song->{body}) {
        foreach my $elt (@{$song->{body}}) {
            push @output, dispatch_element($elt);
        }
    }
    
    push @output, qq{</div><!-- .cp-song -->\n};
    
    return \@output;
}

sub dispatch_element {
    my ($elt) = @_;
    my $type = $elt->{type};
    
    return songline($elt)     if $type eq 'songline';
    return comment_text($elt) if $type eq 'comment';
    
    # Container elements
    if ($elt->{body}) {
        my @output;
        if ($type eq 'verse') {
            push @output, qq{<div class="cp-verse">\n};
            foreach my $child (@{$elt->{body}}) {
                push @output, dispatch_element($child);
            }
            push @output, qq{</div>\n};
        }
        elsif ($type eq 'chorus') {
            push @output, qq{<div class="cp-chorus">\n};
            foreach my $child (@{$elt->{body}}) {
                push @output, dispatch_element($child);
            }
            push @output, qq{</div>\n};
        }
        return join('', @output);
    }
    
    return '';
}

sub songline {
    my ($elt) = @_;
    my $phrases = $elt->{phrases};
    my $chords = $elt->{chords};
    
    my $html = qq{  <div class="cp-songline">\n};
    
    # Render chord-lyric pairs using Flexbox
    for (my $i = 0; $i < @$phrases; $i++) {
        my $phrase = $phrases->[$i] // '';
        my $chord = $chords->[$i];
        
        $html .= qq{    <span class="cp-chord-lyric-pair">\n};
        
        # Chord (empty if no chord)
        if ($chord && ref($chord) && $chord->{key}) {
            my $chord_name = escape_html($chord->{name});
            $html .= qq{      <span class="cp-chord">$chord_name</span>\n};
        } else {
            $html .= qq{      <span class="cp-chord cp-chord-empty"></span>\n};
        }
        
        # Lyrics
        my $escaped_phrase = escape_html($phrase);
        $html .= qq{      <span class="cp-lyrics">$escaped_phrase</span>\n};
        
        $html .= qq{    </span>\n};
    }
    
    $html .= qq{  </div>\n};
    return $html;
}

sub comment_text {
    my ($elt) = @_;
    my $text = escape_html($elt->{text});
    return qq{  <div class="cp-comment">$text</div>\n};
}

sub document_begin {
    my ($title) = @_;
    my $escaped_title = escape_html($title);
    
    return qq{<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="generator" content="ChordPro HTML5 Backend MVP">
    <title>$escaped_title</title>
    <style>
} . generate_css() . qq{
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

sub generate_css {
    return q{
/* ChordPro HTML5 Stylesheet */

:root {
    --cp-font-text: Georgia, serif;
    --cp-font-chord: Arial, sans-serif;
    --cp-size-text: 12pt;
    --cp-size-chord: 10pt;
    --cp-size-title: 18pt;
    --cp-size-subtitle: 14pt;
    --cp-color-chord: #0066cc;
    --cp-color-comment: #666;
    --cp-color-chorus-bg: #f5f5f5;
    --cp-color-chorus-border: #0066cc;
    --cp-spacing-line: 0.3em;
    --cp-spacing-verse: 1em;
}

body.chordpro-songbook {
    font-family: var(--cp-font-text);
    font-size: var(--cp-size-text);
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
    line-height: 1.4;
}

.cp-song {
    margin-bottom: 3em;
}

.cp-title {
    font-size: var(--cp-size-title);
    font-weight: bold;
    margin: 0.5em 0;
}

.cp-subtitle {
    font-size: var(--cp-size-subtitle);
    font-style: italic;
    margin: 0.3em 0;
}

.cp-metadata {
    margin: 1em 0;
    font-size: 0.9em;
    color: #555;
}

.cp-artist, .cp-composer {
    margin: 0.2em 0;
}

/* CORE INNOVATION: Flexbox chord positioning */
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
    padding-bottom: 0.2em;
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

.cp-comment {
    font-size: 11pt;
    color: var(--cp-color-comment);
    margin: 0.5em 0;
    font-style: italic;
}

.cp-verse {
    margin: var(--cp-spacing-verse) 0;
}

.cp-chorus {
    margin: var(--cp-spacing-verse) 0;
    padding: 0.5em 0 0.5em 1em;
    border-left: 3px solid var(--cp-color-chorus-border);
    background: var(--cp-color-chorus-bg);
}

@media print {
    @page {
        size: A4;
        margin: 2cm;
    }
    
    body.chordpro-songbook {
        max-width: 100%;
        padding: 0;
    }
    
    .cp-verse, .cp-chorus {
        page-break-inside: avoid;
    }
}
};
}

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

sub mock_chord {
    my ($name) = @_;
    return {
        key => $name,
        name => $name,
    };
}
