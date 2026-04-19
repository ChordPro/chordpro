#! perl

package ChordPro::Output::ChordProBase;

# ChordPro-specific base class.
# Extends OutputBase with ChordPro directive handling and music notation.
# This is the parent class for all ChordPro output formats.

use v5.26;
use Object::Pad;
use utf8;
use Carp;

use ChordPro::Output::Base;

class ChordPro::Output::ChordProBase :abstract
  :isa(ChordPro::Output::Base) {

    # Current context (verse, chorus, bridge, etc.)
    field $current_context :reader;

    # Lyrics-only mode
    field $lyrics_only :reader(is_lyrics_only);

    # Single-space mode (suppress empty chord lines)
    field $single_space :reader(is_single_space);

    # =================================================================
    # CHORDPRO-SPECIFIC ABSTRACT METHODS
    # =================================================================

    # Core music notation rendering
    method render_chord :abstract ($chord_obj);

    method render_songline :abstract ($phrases, $chords);

    # Musical sections
    method render_chorus_begin($label=undef) {
        return $self->render_section_begin('chorus', $label);
    }

    method render_chorus_end() {
        return $self->render_section_end('chorus');
    }

    method render_verse_begin($label=undef) {
        return $self->render_section_begin('verse', $label);
    }

    method render_verse_end() {
        return $self->render_section_end('verse');
    }

    method render_bridge_begin($label=undef) {
        return $self->render_section_begin('bridge', $label);
    }

    method render_bridge_end() {
        return $self->render_section_end('bridge');
    }

    # Chord diagrams
    method render_chord_diagram($chord_def) {
        # Default: not supported
        return "";
    }

    # Tablature
    method render_tab_begin() {
        return $self->render_section_begin('tab');
    }

    method render_tab_line($line) {
        return $self->render_text($line, 'monospace');
    }

    method render_tab_end() {
        return $self->render_section_end('tab');
    }

    # Grid notation
    method render_grid_begin() {
        return $self->render_section_begin('grid');
    }

    method render_grid_line :abstract ($tokens);

    method render_grid_end() {
        return $self->render_section_end('grid');
    }

    # =================================================================
    # INITIALIZATION
    # =================================================================

    BUILD {
        # Get mode settings from options
        $single_space = $self->options->{'single-space'} // 0;
        $lyrics_only = $self->config->{settings}->{'lyrics-only'} // 0;
    }

    method dispatch_element($elt) {
        my $type = $elt->{type};

        # Dispatch based on element type
        return $self->handle_songline($elt)     if $type eq 'songline';
        return $self->handle_tabline($elt)      if $type eq 'tabline';
        return $self->handle_gridline($elt)     if $type eq 'gridline';
        return $self->handle_empty($elt)        if $type eq 'empty';
        return $self->handle_colb($elt)         if $type eq 'colb';
        return $self->handle_newpage($elt)      if $type eq 'newpage';

        # Text elements
        return $self->handle_comment($elt)      if $type eq 'comment';

        # Additional metadata
        return $self->handle_arranger($elt)     if $type eq 'arranger';
        return $self->handle_copyright($elt)    if $type eq 'copyright';
        return $self->handle_lyricist($elt)     if $type eq 'lyricist';
        return $self->handle_duration($elt)     if $type eq 'duration';

        # Environment containers (with body)
        return $self->handle_chorus($elt)       if $type eq 'chorus';
        return $self->handle_rechorus($elt)     if $type eq 'rechorus';
        return $self->handle_verse($elt)        if $type eq 'verse';
        return $self->handle_bridge($elt)       if $type eq 'bridge';
        return $self->handle_tab($elt)          if $type eq 'tab';
        return $self->handle_grid($elt)         if $type eq 'grid';
        
        # Environment start/end directives
        return $self->handle_start_of_chorus($elt)  if $type eq 'start_of_chorus';
        return $self->handle_end_of_chorus($elt)    if $type eq 'end_of_chorus';
        return $self->handle_start_of_verse($elt)   if $type eq 'start_of_verse';
        return $self->handle_end_of_verse($elt)     if $type eq 'end_of_verse';
        return $self->handle_start_of_bridge($elt)  if $type eq 'start_of_bridge';
        return $self->handle_end_of_bridge($elt)    if $type eq 'end_of_bridge';
        return $self->handle_start_of_tab($elt)     if $type eq 'start_of_tab';
        return $self->handle_end_of_tab($elt)       if $type eq 'end_of_tab';
        return $self->handle_start_of_grid($elt)    if $type eq 'start_of_grid';
        return $self->handle_end_of_grid($elt)      if $type eq 'end_of_grid';

        # Delegate-based elements (ABC, LilyPond, etc.)
        return $self->handle_delegate($elt)     if $type eq 'delegate';

        # Set directives (configuration changes)
        return $self->handle_set($elt)          if $type eq 'set';

        # Diagrams
        return $self->handle_diagrams($elt)     if $type eq 'diagrams';

        # Comment variants
        return $self->handle_comment_italic($elt) if $type eq 'comment_italic';
        return $self->handle_comment_box($elt)   if $type eq 'comment_box';

        # Empty element type
        return "" if $type eq '';

        # Unknown type
        warn("Unknown element type: $type\n") if $type;
        return "";
    }

    # =================================================================
    # DEFAULT DIRECTIVE HANDLERS
    # =================================================================

    # Metadata handlers
    method handle_title($elt) {
        my $title = $elt->{value};
        $self->render_metadata('title', $title);
        return $self->render_section_begin('title', $title);
    }

    method handle_subtitle($elt) {
        my $subtitle = $elt->{value};
        $self->render_metadata('subtitle', $subtitle);
        return $self->render_section_begin('subtitle', $subtitle);
    }

    method handle_artist($elt) {
        my $artist = $elt->{value};
        $self->render_metadata('artist', $artist);
        return $self->render_text($artist, 'artist');
    }

    method handle_composer($elt) {
        return $self->render_text($elt->{value}, 'composer');
    }

    method handle_album($elt) {
        return $self->render_text($elt->{value}, 'album');
    }

    method handle_year($elt) {
        return $self->render_text($elt->{value}, 'year');
    }

    method handle_key($elt) {
        return $self->render_text("Key: " . $elt->{value}, 'meta');
    }

    method handle_time($elt) {
        return $self->render_text("Time: " . $elt->{value}, 'meta');
    }

    method handle_tempo($elt) {
        return $self->render_text("Tempo: " . $elt->{value}, 'meta');
    }

    method handle_capo($elt) {
        return $self->render_text("Capo: " . $elt->{value}, 'meta');
    }

    method handle_arranger($elt) {
        return $self->render_text($elt->{value}, 'arranger');
    }

    method handle_copyright($elt) {
        return $self->render_text($elt->{value}, 'copyright');
    }

    method handle_lyricist($elt) {
        return $self->render_text($elt->{value}, 'lyricist');
    }

    method handle_duration($elt) {
        return $self->render_text("Duration: " . $elt->{value}, 'meta');
    }

    # Formatting handlers
    method handle_comment($elt) {
        return $self->render_section_begin('comment')
             . $self->render_text($elt->{text})
             . $self->render_section_end('comment');
    }

    method handle_comment_italic($elt) {
        return $self->render_section_begin('comment_italic')
             . $self->render_text($elt->{text}, 'italic')
             . $self->render_section_end('comment_italic');
    }

    method handle_comment_box($elt) {
        return $self->render_section_begin('comment_box')
             . $self->render_text($elt->{text})
             . $self->render_section_end('comment_box');
    }

    method handle_highlight($elt) {
        return $self->render_section_begin('highlight')
             . $self->render_text($elt->{text})
             . $self->render_section_end('highlight');
    }

    method handle_set($elt) {
        # Configuration directives don't produce output
        # Subclasses can override if they need special handling
        return "";
    }

    method handle_diagrams($elt) {
        # Chord diagrams - usually handled in document generation
        # Subclasses can override for format-specific rendering
        return "";
    }

    # Environment handlers
    method handle_start_of_chorus($elt) {
        $current_context = 'chorus';
        return $self->render_section_begin('chorus', $elt->{label});
    }

    method handle_end_of_chorus($elt) {
        $current_context = '';
        return $self->render_section_end('chorus');
    }

    method handle_start_of_verse($elt) {
        $current_context = 'verse';
        return $self->render_section_begin('verse', $elt->{label});
    }

    method handle_end_of_verse($elt) {
        $current_context = '';
        return $self->render_section_end('verse');
    }

    method handle_start_of_bridge($elt) {
        $current_context = 'bridge';
        return $self->render_section_begin('bridge', $elt->{label});
    }

    method handle_end_of_bridge($elt) {
        $current_context = '';
        return $self->render_section_end('bridge');
    }

    method handle_start_of_tab($elt) {
        $current_context = 'tab';
        return $self->render_tab_begin();
    }

    method handle_end_of_tab($elt) {
        $current_context = undef;
        return $self->render_tab_end();
    }

    method handle_start_of_grid($elt) {
        $current_context = 'grid';
        return $self->render_grid_begin();
    }

    method handle_end_of_grid($elt) {
        $current_context = undef;
        return $self->render_grid_end();
    }

    # Element handlers
    method handle_songline($elt) {
        return $self->render_songline($elt->{phrases}, $elt->{chords});
    }

    method handle_tabline($elt) {
        return $self->render_tab_line($elt->{text});
    }

    method handle_gridline($elt) {
        return $self->render_grid_line($elt->{tokens});
    }

    method handle_empty($elt) {
        return $self->render_paragraph_break();
    }

    # Layout handlers
    method handle_colb($elt) {
        return "";  # Subclasses handle column breaks
    }

    method handle_newpage($elt) {
        return "";  # Subclasses handle page breaks
    }

    method handle_column_break($elt) {
        return "";  # Subclasses handle column breaks
    }

    method handle_columns($elt) {
        return "";  # Subclasses handle column settings
    }

    method handle_new_page($elt) {
        return "";  # Subclasses handle page breaks
    }

    method handle_new_song($elt) {
        return "";  # Subclasses handle song boundaries
    }

    # Special handlers
    method handle_image($elt) {
        my $uri = $elt->{uri} // $elt->{id};
        return $self->render_image($uri, $elt->{opts});
    }

    method handle_define($elt) {
        # Chord definitions are typically stored, not rendered directly
        return "";
    }

    method handle_chord($elt) {
        # Standalone chord directive
        return $self->render_chord($elt->{chord});
    }

    method handle_control($elt) {
        # Control directives (lyrics-only, etc.)
        if ($elt->{name} eq 'lyrics-only') {
            $lyrics_only = $elt->{value} unless $lyrics_only > 1;
        }
        return "";
    }

    method handle_delegate($elt) {
        # Delegate to external processors (ABC, LilyPond, etc.)
        # Subclasses override for format-specific handling
        return "";
    }

    # Container handlers
    method handle_chorus($elt) {
        my $output = '';
        $output .= $self->render_chorus_begin($elt->{label});
        foreach my $e (@{$elt->{body}}) {
            $output .= $self->dispatch_element($e);
        }
        $output .= $self->render_chorus_end();
        return $output;
    }

    method handle_rechorus($elt) {
        my $config = $self->config // {};
        my $recall = eval { $config->{html5}->{chorus}->{recall} }
          // eval { $config->{pdf}->{chorus}->{recall} }
          // eval { $config->{text}->{chorus}->{recall} }
          // {};

        my $quote = eval { $recall->{quote} } // 0;
        my $tag = eval { $recall->{tag} };
        $tag = 'Chorus' if !defined($tag) || $tag eq '';
        my $type = eval { $recall->{type} } // '';
        my $choruslike = eval { $recall->{choruslike} } // 0;

        if ( $quote && $elt->{chorus} ) {
            return $self->handle_chorus({ body => $elt->{chorus} });
        }

        my $output = '';
        if ( $type && $tag ne '' ) {
            if ( $type eq 'comment' ) {
                $output = $self->handle_comment({ text => $tag });
            }
            elsif ( $type eq 'comment_italic' ) {
                $output = $self->handle_comment_italic({ text => $tag });
            }
            elsif ( $type eq 'comment_box' ) {
                $output = $self->handle_comment_box({ text => $tag });
            }
        }

        if ( $output eq '' ) {
            $output = $self->render_section_begin('rechorus')
              . $self->render_text($tag)
              . $self->render_section_end('rechorus');
        }

        if ( $choruslike ) {
            return $self->render_section_begin('choruslike')
              . $output
              . $self->render_section_end('choruslike');
        }

        return $output;
    }

    method handle_verse($elt) {
        my $output = '';
        $output .= $self->render_verse_begin($elt->{label});
        foreach my $e (@{$elt->{body}}) {
            $output .= $self->dispatch_element($e);
        }
        $output .= $self->render_verse_end();
        return $output;
    }

    method handle_bridge($elt) {
        my $output = '';
        $output .= $self->render_bridge_begin($elt->{label});
        foreach my $e (@{$elt->{body}}) {
            $output .= $self->dispatch_element($e);
        }
        $output .= $self->render_bridge_end();
        return $output;
    }

    method handle_tab($elt) {
        my $output = '';
        $output .= $self->render_tab_begin();
        foreach my $e (@{$elt->{body}}) {
            $output .= $self->dispatch_element($e);
        }
        $output .= $self->render_tab_end();
        return $output;
    }

    method handle_grid($elt) {
        my $output = '';
        $output .= $self->render_grid_begin();
        foreach my $e (@{$elt->{body}}) {
            $output .= $self->dispatch_element($e);
        }
        $output .= $self->render_grid_end();
        return $output;
    }

    # =================================================================
    # HELPER METHODS
    # =================================================================

}


1;

=head1 NAME

ChordPro::lib::OutputChordProBase - Base class for ChordPro output backends

=head1 SYNOPSIS

    package ChordPro::Output::HTML5;

    use v5.26;
    use Object::Pad;

    class ChordPro::Output::HTML5
      :isa(ChordPro::lib::OutputChordProBase) {

        method render_chord($chord_obj) {
            return qq{<span class="chord">$chord_obj->name</span>};
        }

        method render_songline($phrases, $chords) {
            # ... HTML5-specific rendering ...
        }
    }

=head1 DESCRIPTION

This class extends OutputBase with ChordPro-specific functionality including:

=over 4

=item * Directive handler registration and dispatch

=item * Music notation rendering (chords, songlines)

=item * Environment handling (chorus, verse, bridge, tab, grid)

=item * Context tracking

=back

=head1 REQUIRED METHODS

Subclasses must implement:

=over 4

=item render_chord($chord_obj)

Render a chord symbol.

=item render_songline($phrases, $chords)

Render a line of lyrics with chords.

=item render_grid_line($tokens)

Render a grid notation line.

=back

=head1 DIRECTIVE HANDLERS

The following directives are handled by default:

=over 4

=item Meta: title, subtitle, artist, composer, album, year, key, time, tempo, capo

=item Formatting: comment, comment_italic, comment_box, highlight

=item Environment: start_of_chorus, end_of_chorus, start_of_verse, etc.

=item Layout: new_page, column_break, columns

=item Special: image, define, chord

=back

=head1 SEE ALSO

L<ChordPro::Output::Base>, L<ChordPro::Output::HTML5>

=cut
