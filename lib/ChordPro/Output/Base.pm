#! perl

package ChordPro::Output::Base;

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class ChordPro::Output::Base :abstract {

    field $config :param :reader;
    field $options :param :reader //= {};
    field $song :reader :writer;
    field $current_context :reader;
    field $lyrics_only :reader(is_lyrics_only);
    field $single_space :reader(is_single_space);

    method render_document_begin($metadata);
    method render_document_end();
    method render_text($text, $style=undef);
    method render_line_break();
    method render_paragraph_break();
    method render_section_begin($type, $label=undef);
    method render_section_end($type);
    method render_image($uri, $opts={});
    method render_metadata($key, $value);
    method render_chord($chord_obj);
    method render_songline($phrases, $chords);
    method render_grid_line($tokens);
    method generate_song($s);

    method render_list_begin($ordered=0) {
        return "";
    }

    method render_list_item($content) {
        return $content;
    }

    method render_list_end() {
        return "";
    }

    method supports_feature($feature_name) {
        return 0;
    }

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

    method render_chord_diagram($chord_def) {
        return "";
    }

    method render_tab_begin() {
        return $self->render_section_begin('tab');
    }

    method render_tab_line($line) {
        return $self->render_text($line, 'monospace');
    }

    method render_tab_end() {
        return $self->render_section_end('tab');
    }

    method render_grid_begin() {
        return $self->render_section_begin('grid');
    }

    method render_grid_end() {
        return $self->render_section_end('grid');
    }

    BUILD {
        croak("config parameter is required") unless defined $config;
        $single_space = $options->{'single-space'} // 0;
        $lyrics_only = $config->{settings}->{'lyrics-only'} // 0;
    }

    method dispatch_element($elt) {
        my $type = $elt->{type};

        return $self->handle_songline($elt)          if $type eq 'songline';
        return $self->handle_tabline($elt)           if $type eq 'tabline';
        return $self->handle_gridline($elt)          if $type eq 'gridline';
        return $self->handle_empty($elt)             if $type eq 'empty';
        return $self->handle_colb($elt)              if $type eq 'colb';
        return $self->handle_newpage($elt)           if $type eq 'newpage';
        return $self->handle_comment($elt)           if $type eq 'comment';
        return $self->handle_arranger($elt)          if $type eq 'arranger';
        return $self->handle_copyright($elt)         if $type eq 'copyright';
        return $self->handle_lyricist($elt)          if $type eq 'lyricist';
        return $self->handle_duration($elt)          if $type eq 'duration';
        return $self->handle_chorus($elt)            if $type eq 'chorus';
        return $self->handle_rechorus($elt)          if $type eq 'rechorus';
        return $self->handle_verse($elt)             if $type eq 'verse';
        return $self->handle_bridge($elt)            if $type eq 'bridge';
        return $self->handle_tab($elt)               if $type eq 'tab';
        return $self->handle_grid($elt)              if $type eq 'grid';
        return $self->handle_start_of_chorus($elt)   if $type eq 'start_of_chorus';
        return $self->handle_end_of_chorus($elt)     if $type eq 'end_of_chorus';
        return $self->handle_start_of_verse($elt)    if $type eq 'start_of_verse';
        return $self->handle_end_of_verse($elt)      if $type eq 'end_of_verse';
        return $self->handle_start_of_bridge($elt)   if $type eq 'start_of_bridge';
        return $self->handle_end_of_bridge($elt)     if $type eq 'end_of_bridge';
        return $self->handle_start_of_tab($elt)      if $type eq 'start_of_tab';
        return $self->handle_end_of_tab($elt)        if $type eq 'end_of_tab';
        return $self->handle_start_of_grid($elt)     if $type eq 'start_of_grid';
        return $self->handle_end_of_grid($elt)       if $type eq 'end_of_grid';
        return $self->handle_delegate($elt)          if $type eq 'delegate';
        return $self->handle_set($elt)               if $type eq 'set';
        return $self->handle_meta($elt)              if $type eq 'meta';
        return $self->handle_diagrams($elt)          if $type eq 'diagrams';
        return $self->handle_comment_italic($elt)    if $type eq 'comment_italic';
        return $self->handle_comment_box($elt)       if $type eq 'comment_box';

        return "" if $type eq '';

        warn("Unknown element type: $type\n") if $type;
        return "";
    }

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
        return "";
    }

    method handle_meta($elt) {
        return "";
    }

    method handle_diagrams($elt) {
        return "";
    }

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

    method handle_colb($elt) {
        return "";
    }

    method handle_newpage($elt) {
        return "";
    }

    method handle_column_break($elt) {
        return "";
    }

    method handle_columns($elt) {
        return "";
    }

    method handle_new_page($elt) {
        return "";
    }

    method handle_new_song($elt) {
        return "";
    }

    method handle_image($elt) {
        my $uri = $elt->{uri} // $elt->{id};
        return $self->render_image($uri, $elt->{opts});
    }

    method handle_define($elt) {
        return "";
    }

    method handle_chord($elt) {
        return $self->render_chord($elt->{chord});
    }

    method handle_control($elt) {
        if ($elt->{name} eq 'lyrics-only') {
            $lyrics_only = $elt->{value} unless $lyrics_only > 1;
        }
        return "";
    }

    method handle_delegate($elt) {
        return "";
    }

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
        my $recall = $config->{pdf}->{chorus}->{recall}
          // $config->{text}->{chorus}->{recall}
          // $config->{chordpro}->{chorus}->{recall}
          // {};
        $recall = {} unless ref($recall) eq 'HASH';

        my $quote = $recall->{quote} // 0;
        my $tag = $recall->{tag};
        $tag = 'Chorus' if !defined($tag) || $tag eq '';
        my $type = $recall->{type} // '';
        my $choruslike = $recall->{choruslike} // 0;

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

    method generate_songbook($songbook) {
        my $output = '';

        $output .= $self->render_document_begin({
            title => $songbook->{title} // 'Songbook',
            songs => scalar(@{$songbook->{songs}}),
        });

        foreach my $s (@{$songbook->{songs}}) {
            $song = $s;
            $output .= $self->generate_song($s);
        }

        $output .= $self->render_document_end();

        return [ $output =~ /^.*\n?/gm ];
    }
}

1;

=head1 NAME

ChordPro::Output::Base - Shared base class for ChordPro output backends

=head1 SYNOPSIS

    package ChordPro::Output::MyFormat;

    use v5.26;
    use Object::Pad;
    use ChordPro::Output::Base;

    class ChordPro::Output::MyFormat
      :isa(ChordPro::Output::Base) {

        method render_document_begin($metadata) { ... }
        method render_document_end() { ... }
        method render_text($text, $style=undef) { ... }
        method render_line_break() { ... }
        method render_paragraph_break() { ... }
        method render_section_begin($type, $label=undef) { ... }
        method render_section_end($type) { ... }
        method render_image($uri, $opts={}) { ... }
        method render_metadata($key, $value) { ... }
        method render_chord($chord_obj) { ... }
        method render_songline($phrases, $chords) { ... }
        method render_grid_line($tokens) { ... }
        method generate_song($song) { ... }
    }

=head1 DESCRIPTION

This class provides the shared document lifecycle, directive dispatch, and
ChordPro element handling used by the modern text-building backends.
