#!/usr/bin/perl

package main;

our $options;
our $config;

package ChordPro::Output::Markdown;
# Author: Johannes Rumpf / 2022
# Migrated to Object::Pad architecture: 2025

use strict;
use warnings;
use v5.26;
use Object::Pad;
use utf8;

use ChordPro::Output::ChordProBase;
use ChordPro::Output::Common;
use Text::Layout::Markdown;
use Ref::Util qw(is_arrayref);

class ChordPro::Output::Markdown
  :isa(ChordPro::Output::ChordProBase) {

    # Markdown-specific fields
    field $text_layout;
    field $chords_under;
    field $tidy;
    field $cp;  # Chord-Prefix for code blocks
    field $current_song;  # Current song being processed

    BUILD {
        $text_layout = Text::Layout::Markdown->new;
        $chords_under = 0;
        $tidy = 0;
        $cp = "\t";  # Tab for code blocks in Markdown

        # Get Markdown-specific config
        $chords_under = $self->config->{settings}->{'chords-under'} // 0;
        $tidy = $self->options->{'backend-option'}->{tidy} // 0;
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Document Structure
    # =================================================================

    method render_document_begin($metadata) {
        # Markdown has no document wrapper - just start with content
        return "";
    }

    method render_document_end() {
        # Markdown has no document wrapper
        return "";
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Text Rendering
    # =================================================================

    method render_text($text, $style=undef) {
        # Use Text::Layout for markup handling
        $text_layout->set_markup($text);
        my $rendered = $text_layout->render;

        return $rendered unless $style;

        # Apply Markdown styling
        return "**$rendered**" if $style eq 'bold';
        return "*$rendered*" if $style eq 'italic';
        return "`$rendered`" if $style eq 'monospace' || $style eq 'code';

        return $rendered;
    }

    method render_line_break() {
        return "  \n";  # Two spaces + newline in Markdown
    }

    method render_paragraph_break() {
        return "\n\n";
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Structural Elements
    # =================================================================

    method render_section_begin($type, $label=undef) {
        # Most sections in Markdown don't have explicit begin markers
        # Handle special cases
        if ($type eq 'chorus') {
            return "**Chorus**\n\n";
        }
        elsif ($type eq 'tab') {
            return "**Tabulatur**  \n\n";
        }
        elsif ($type eq 'grid') {
            return "**Grid**  \n\n";
        }
        elsif ($type eq 'comment' || $type eq 'comment_italic') {
            return "> ";
        }

        return "";
    }

    method render_section_end($type) {
        # Handle special section endings
        if ($type eq 'chorus') {
            return "---------------  \n";
        }
        elsif ($type eq 'verse' || $type eq 'tab' || $type eq 'grid') {
            return "\n";
        }
        elsif ($type eq 'comment' || $type eq 'comment_italic') {
            return "  \n";
        }

        return "";
    }

    # =================================================================
    # REQUIRED BASE CLASS METHODS - Media
    # =================================================================

    method render_image($uri, $opts={}) {
        my $alt = $opts->{alt} // '';
        return "![$alt]($uri)";
    }

    method render_metadata($key, $value) {
        # Markdown doesn't have metadata in the same way
        return "";
    }

    # =================================================================
    # REQUIRED CHORDPRO METHODS - Music Notation
    # =================================================================

    method render_chord($chord_obj) {
        return "" unless $chord_obj;
        return $chord_obj->key if $chord_obj->info->is_annotation;
        $text_layout->set_markup($chord_obj->chord_display);
        return $text_layout->render;
    }

    method render_songline($phrases, $chords) {
        my @rendered_phrases = map {
            $text_layout->set_markup($_);
            $text_layout->render;
        } @$phrases;

        # Lyrics-only mode
        if ($self->is_lyrics_only()) {
            my $line = join("", @rendered_phrases);
            return $self->markdown_textline($cp . $line);
        }

        # Single-space mode (suppress empty chord lines)
        my $has_chords = 0;
        if ($chords) {
            foreach my $chord (@$chords) {
                if ($chord && $chord->raw =~ /\S/) {
                    $has_chords = 1;
                    last;
                }
            }
        }

        if ($self->is_single_space() && !$has_chords) {
            my $line = join("", @rendered_phrases);
            return $self->markdown_textline($cp . $line);
        }

        # No chords
        unless ($chords) {
            return $self->markdown_textline($cp . join(" ", @rendered_phrases));
        }

        # Inline chords mode
        if (my $f = $config->{settings}->{'inline-chords'}) {
            $f = '[%s]' unless $f =~ /^[^%]*\%s[^%]*$/;
            $f .= '%s';
            my $t_line = "";
            foreach (0..$#{$chords}) {
                $t_line .= sprintf($f,
                    $self->render_chord($chords->[$_]),
                    $rendered_phrases[$_]);
            }
            return $self->markdown_textline($cp . $t_line);
        }

        # Standard mode: chords above lyrics
        my $c_line = "";
        my $t_line = "";
        foreach (0..$#{$chords}) {
            $c_line .= $self->render_chord($chords->[$_]) . " ";
            $t_line .= $rendered_phrases[$_];
            my $d = length($c_line) - length($t_line);
            $t_line .= "-" x $d if $d > 0;
            $c_line .= " " x -$d if $d < 0;
        }

        $t_line =~ s/\s+$//;
        $c_line =~ s/\s+$//;

        if ($c_line ne "") {
            $t_line = $cp . $t_line . "  ";
            $c_line = $cp . $c_line . "  ";
        } else {
            $t_line = $self->markdown_textline($cp . $t_line);
        }

        # Return as array ref for chord/lyric pairs
        return $chords_under
            ? [$t_line, $c_line]
            : [$c_line, $t_line];
    }

    method render_grid_line($tokens) {
        my @parts = map {
            $_->{class} eq 'chord'
                ? $_->{chord}->raw
                : $_->{symbol}
        } @$tokens;

        return "\t" . join("", @parts);
    }

    # =================================================================
    # OVERRIDE GENERATE_SONG - Custom Markdown structure
    # =================================================================

    method generate_song($song) {
        my @output;

        # Store current song for metadata substitution in comments
        $current_song = $song;

        # Assume songlines without context are verses
        foreach my $item (@{$song->{body}}) {
            if ($item->{type} eq "songline" && $item->{context} eq '') {
                $item->{context} = 'verse';
            }
        }

        # Structurize the song
        $song->structurize;

        # Title
        push @output, "# " . $song->{title} if defined $song->{title};

        # Subtitles
        if (defined $song->{subtitle}) {
            push @output, map { "## $_" } @{$song->{subtitle}};
        }
        push @output, "" if defined $song->{subtitle};

        # Chord diagrams (if not lyrics-only)
        unless ($self->is_lyrics_only()) {
            my $all_chords = "";
            if ($song->{chords} && $song->{chords}->{chords}) {
                foreach my $mchord (@{$song->{chords}->{chords}}) {
                    if ($song->{chordsinfo} && $song->{chordsinfo}->{$mchord}) {
                        my $frets = join("", map {
                            $_ eq '-1' ? 'x' : $_
                        } @{$song->{chordsinfo}->{$mchord}->{frets}});
                        $all_chords .= "![$mchord](https://chordgenerator.net/$mchord.png?p=$frets&s=2) ";
                    }
                }
            }
            if ($all_chords) {
                push @output, $all_chords;
                push @output, "";
            }
        }

        # Process song body
        if ($song->{body}) {
            foreach my $elt (@{$song->{body}}) {
                # Set chord prefix based on whether body has chords
                if ($elt->{body} && ($elt->{type} eq 'verse' || $elt->{type} eq 'chorus')) {
                    $cp = $self->body_has_chords($elt->{body}) ? "\t" : "";
                }

                my $result = $self->dispatch_element($elt);
                if (is_arrayref($result)) {
                    push @output, @$result;
                } else {
                    push @output, $result;
                }
            }
        }

        return join("\n", @output) . "\n";
    }

    # Override generate_songbook to add separators and clean up
    method generate_songbook_impl($songbook) {
        my @book;

        foreach my $song (@{$songbook->{songs}}) {
            if (@book) {
                push @book, "" if $tidy;
            }
            push @book, $self->generate_song($song);
            push @book, "---------------  \n";
        }

        push @book, "";

        # Remove all double empty lines
        my @new;
        my $count = 0;
        foreach (@book) {
            if ($_ =~ /.{1,}/) {
                push @new, $_;
                $count = 0;
            } else {
                push @new, $_ if $count == 0;
                $count++;
            }
        }

        return \@new;
    }

    # =================================================================
    # OVERRIDE ELEMENT HANDLERS
    # =================================================================

    method handle_songline($elt) {
        my $result = $self->render_songline($elt->{phrases}, $elt->{chords});
        if (ref($result) eq 'ARRAY') {
            return join("\n", @$result) . "\n";
        }
        return $result . "\n";
    }

    method handle_tabline($elt) {
        return "\t" . $elt->{text} . "\n";
    }

    method handle_gridline($elt) {
        return $self->render_grid_line($elt->{tokens}) . "\n";
    }

    method handle_empty($elt) {
        return "$cp\n";
    }

    method handle_comment($elt) {
        my $text = $elt->{text};

        # Handle metadata substitution in comments
        if ($text && $text =~ /%\{/ && $current_song) {
            require ChordPro::Output::Common;
            $text = ChordPro::Output::Common::fmt_subst($current_song, $text);
        }

        # Handle chords in comments
        if ($elt->{chords}) {
            $text = "";
            for (0..$#{$elt->{chords}}) {
                $text .= "[" . $elt->{chords}->[$_]->raw . "]"
                    if $elt->{chords}->[$_] ne "";
                $text .= $elt->{phrases}->[$_];
            }
        }

        if ($elt->{type} =~ /italic$/) {
            $text = "*" . $text . "*  ";
        }

        return "> $text  \n";
    }

    method handle_comment_italic($elt) {
        return "> *" . $elt->{text} . "*  \n";
    }

    method handle_set($elt) {
        # Set directives are configuration and don't produce output
        return "";
    }

    method handle_diagrams($elt) {
        # Diagrams are handled in generate_song(), not in body
        return "";
    }

    method handle_colb($elt) {
        return "\n\n\n";
    }

    method handle_newpage($elt) {
        return "---------------  \n";
    }

    method handle_image($elt) {
        return $self->render_image($elt->{uri}) . "\n";
    }

    method handle_chorus($elt) {
        my $output = '';
        $output .= $self->render_section_begin('chorus');

        if ($elt->{body}) {
            foreach my $child (@{$elt->{body}}) {
                $output .= $self->dispatch_element($child);
            }
        }

        $output .= $self->render_section_end('chorus');
        return $output;
    }

    method handle_verse($elt) {
        my $output = '';

        if ($elt->{body}) {
            foreach my $child (@{$elt->{body}}) {
                $output .= $self->dispatch_element($child);
            }
        }

        $output .= $self->render_section_end('verse');
        return $output;
    }

    method handle_tab($elt) {
        my $output = '';
        $output .= $self->render_section_begin('tab');

        if ($elt->{body}) {
            foreach my $child (@{$elt->{body}}) {
                my $line = $self->dispatch_element($child);
                # Add tab prefix for tab content
                $line =~ s/^/\t/mg;
                $output .= $line;
            }
        }

        return $output;
    }

    method handle_grid($elt) {
        my $output = '';
        $output .= $self->render_section_begin('grid');

        if ($elt->{body}) {
            foreach my $child (@{$elt->{body}}) {
                $output .= $self->dispatch_element($child);
            }
        }

        $output .= $self->render_section_end('grid');
        return $output;
    }

    # =================================================================
    # MARKDOWN-SPECIFIC HELPER METHODS
    # =================================================================

    method markdown_textline($line) {
        my $nbsp = "\x{00A0}";  # Unicode for nbsp
        if ($line =~ /^\s+/) {
            my $spaces = $line;
            $spaces =~ s/^(\s+).*$/$1/;
            my $replaces = $spaces;
            $replaces =~ s/\s/$nbsp/g;
            $line =~ s/$spaces/$replaces/;
        }
        return $line . "  ";  # Two spaces for line break
    }

    method body_has_chords($elts) {
        foreach my $elt (@$elts) {
            if ($elt->{type} eq 'songline') {
                if (defined $elt->{chords} && scalar @{$elt->{chords}} > 0) {
                    return 1;
                }
            }
        }
        return 0;
    }
}

# =================================================================
# COMPATIBILITY WRAPPER - ChordPro calls as class method
# =================================================================

sub generate_songbook {
    my ($pkg, $sb) = @_;

    # Create instance with config/options from global variables
    my $backend = $pkg->new(
        config => $main::config,
        options => $main::options,
    );

    # Call custom implementation
    return $backend->generate_songbook_impl($sb);
}

1;
