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

class ChordPro::Output::ChordProBase
  :isa(ChordPro::Output::Base) {
    
    # Handler registry for directives
    field %directive_handlers;
    
    # Current context (verse, chorus, bridge, etc.)
    field $current_context;
    
    # Lyrics-only mode
    field $lyrics_only;
    
    # Single-space mode (suppress empty chord lines)
    field $single_space;
    
    # =================================================================
    # CHORDPRO-SPECIFIC ABSTRACT METHODS
    # =================================================================
    
    # Core music notation rendering
    method render_chord($chord_obj) {
        croak("render_chord() must be implemented by subclass");
    }
    
    method render_songline($phrases, $chords) {
        croak("render_songline() must be implemented by subclass");
    }
    
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
    
    method render_grid_line($tokens) {
        croak("render_grid_line() must be implemented by subclass");
    }
    
    method render_grid_end() {
        return $self->render_section_end('grid');
    }
    
    # =================================================================
    # DIRECTIVE HANDLER REGISTRATION
    # =================================================================
    
    BUILD {
        $self->register_directive_handlers();
        
        # Get mode settings from options
        my $opts = $self->get_options();
        $single_space = $opts->{'single-space'} // 0;
        
        my $cfg = $self->get_config();
        $lyrics_only = $cfg->{settings}->{'lyrics-only'} // 0;
    }
    
    method register_directive_handlers() {
        # Meta directives
        %directive_handlers = (
            title => sub { $self->handle_title(@_) },
            subtitle => sub { $self->handle_subtitle(@_) },
            artist => sub { $self->handle_artist(@_) },
            composer => sub { $self->handle_composer(@_) },
            album => sub { $self->handle_album(@_) },
            year => sub { $self->handle_year(@_) },
            key => sub { $self->handle_key(@_) },
            time => sub { $self->handle_time(@_) },
            tempo => sub { $self->handle_tempo(@_) },
            capo => sub { $self->handle_capo(@_) },
            
            # Formatting directives
            comment => sub { $self->handle_comment(@_) },
            comment_italic => sub { $self->handle_comment_italic(@_) },
            comment_box => sub { $self->handle_comment_box(@_) },
            highlight => sub { $self->handle_highlight(@_) },
            
            # Environment directives  
            start_of_chorus => sub { $self->handle_start_of_chorus(@_) },
            end_of_chorus => sub { $self->handle_end_of_chorus(@_) },
            start_of_verse => sub { $self->handle_start_of_verse(@_) },
            end_of_verse => sub { $self->handle_end_of_verse(@_) },
            start_of_bridge => sub { $self->handle_start_of_bridge(@_) },
            end_of_bridge => sub { $self->handle_end_of_bridge(@_) },
            start_of_tab => sub { $self->handle_start_of_tab(@_) },
            end_of_tab => sub { $self->handle_end_of_tab(@_) },
            start_of_grid => sub { $self->handle_start_of_grid(@_) },
            end_of_grid => sub { $self->handle_end_of_grid(@_) },
            
            # Chord directives
            define => sub { $self->handle_define(@_) },
            chord => sub { $self->handle_chord(@_) },
            
            # Layout directives
            new_page => sub { $self->handle_new_page(@_) },
            new_song => sub { $self->handle_new_song(@_) },
            column_break => sub { $self->handle_column_break(@_) },
            columns => sub { $self->handle_columns(@_) },
            
            # Special directives
            image => sub { $self->handle_image(@_) },
            
            # Control directives
            control => sub { $self->handle_control(@_) },
        );
        
        # Register aliases
        $directive_handlers{c} = $directive_handlers{comment};
        $directive_handlers{ci} = $directive_handlers{comment_italic};
        $directive_handlers{cb} = $directive_handlers{comment_box};
        $directive_handlers{soc} = $directive_handlers{start_of_chorus};
        $directive_handlers{eoc} = $directive_handlers{end_of_chorus};
        $directive_handlers{sov} = $directive_handlers{start_of_verse};
        $directive_handlers{eov} = $directive_handlers{end_of_verse};
        $directive_handlers{sob} = $directive_handlers{start_of_bridge};
        $directive_handlers{eob} = $directive_handlers{end_of_bridge};
        $directive_handlers{sot} = $directive_handlers{start_of_tab};
        $directive_handlers{eot} = $directive_handlers{end_of_tab};
        $directive_handlers{sog} = $directive_handlers{start_of_grid};
        $directive_handlers{eog} = $directive_handlers{end_of_grid};
        $directive_handlers{np} = $directive_handlers{new_page};
        $directive_handlers{ns} = $directive_handlers{new_song};
        $directive_handlers{colb} = $directive_handlers{column_break};
    }
    
    # =================================================================
    # DIRECTIVE DISPATCH
    # =================================================================
    
    method dispatch_directive($name, $elt) {
        my $handler = $directive_handlers{$name};
        
        if ($handler) {
            return $handler->($elt);
        } else {
            warn("Unknown directive: {$name}\n");
            return "";
        }
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
        
        # Environment containers
        return $self->handle_chorus($elt)       if $type eq 'chorus';
        return $self->handle_verse($elt)        if $type eq 'verse';
        return $self->handle_bridge($elt)       if $type eq 'bridge';
        return $self->handle_tab($elt)          if $type eq 'tab';
        return $self->handle_grid($elt)         if $type eq 'grid';
        
        # Delegate-based elements (ABC, LilyPond, etc.)
        return $self->handle_delegate($elt)     if $type eq 'delegate';
        
        # Unknown type
        warn("Unknown element type: $type\n");
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
    
    # Environment handlers
    method handle_start_of_chorus($elt) {
        $current_context = 'chorus';
        return $self->render_chorus_begin($elt->{label});
    }
    
    method handle_end_of_chorus($elt) {
        $current_context = undef;
        return $self->render_chorus_end();
    }
    
    method handle_start_of_verse($elt) {
        $current_context = 'verse';
        return $self->render_verse_begin($elt->{label});
    }
    
    method handle_end_of_verse($elt) {
        $current_context = undef;
        return $self->render_verse_end();
    }
    
    method handle_start_of_bridge($elt) {
        $current_context = 'bridge';
        return $self->render_bridge_begin($elt->{label});
    }
    
    method handle_end_of_bridge($elt) {
        $current_context = undef;
        return $self->render_bridge_end();
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
        my @output;
        push @output, $self->render_chorus_begin($elt->{label});
        foreach my $e (@{$elt->{body}}) {
            push @output, $self->dispatch_element($e);
        }
        push @output, $self->render_chorus_end();
        return join("", @output);
    }
    
    method handle_verse($elt) {
        my @output;
        push @output, $self->render_verse_begin($elt->{label});
        foreach my $e (@{$elt->{body}}) {
            push @output, $self->dispatch_element($e);
        }
        push @output, $self->render_verse_end();
        return join("", @output);
    }
    
    method handle_bridge($elt) {
        my @output;
        push @output, $self->render_bridge_begin($elt->{label});
        foreach my $e (@{$elt->{body}}) {
            push @output, $self->dispatch_element($e);
        }
        push @output, $self->render_bridge_end();
        return join("", @output);
    }
    
    method handle_tab($elt) {
        my @output;
        push @output, $self->render_tab_begin();
        foreach my $e (@{$elt->{body}}) {
            push @output, $self->dispatch_element($e);
        }
        push @output, $self->render_tab_end();
        return join("", @output);
    }
    
    method handle_grid($elt) {
        my @output;
        push @output, $self->render_grid_begin();
        foreach my $e (@{$elt->{body}}) {
            push @output, $self->dispatch_element($e);
        }
        push @output, $self->render_grid_end();
        return join("", @output);
    }
    
    # =================================================================
    # HELPER METHODS
    # =================================================================
    
    method get_current_context() {
        return $current_context;
    }
    
    method is_lyrics_only() {
        return $lyrics_only;
    }
    
    method is_single_space() {
        return $single_space;
    }
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
