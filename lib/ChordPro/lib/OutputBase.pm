#! perl

package ChordPro::lib::OutputBase;

# Base class for all ChordPro output backends.
# Provides minimal language features that every backend must implement.
# Subclasses specialize for specific output formats.

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class ChordPro::lib::OutputBase {
    
    # Configuration from ChordPro
    field $config :param;
    
    # Output options
    field $options :param //= {};
    
    # Current song being processed
    field $song;
    
    # =================================================================
    # ABSTRACT METHODS - Must be implemented by subclasses
    # =================================================================
    
    # Document structure
    method render_document_begin($metadata) {
        croak("render_document_begin() must be implemented by subclass");
    }
    
    method render_document_end() {
        croak("render_document_end() must be implemented by subclass");
    }
    
    # Text rendering
    method render_text($text, $style=undef) {
        croak("render_text() must be implemented by subclass");
    }
    
    method render_line_break() {
        croak("render_line_break() must be implemented by subclass");
    }
    
    method render_paragraph_break() {
        croak("render_paragraph_break() must be implemented by subclass");
    }
    
    # Structural elements
    method render_section_begin($type, $label=undef) {
        croak("render_section_begin() must be implemented by subclass");
    }
    
    method render_section_end($type) {
        croak("render_section_end() must be implemented by subclass");
    }
    
    # Lists (optional - some backends may not support)
    method render_list_begin($ordered=0) {
        return "";  # Default: no-op
    }
    
    method render_list_item($content) {
        return $content;  # Default: just return content
    }
    
    method render_list_end() {
        return "";  # Default: no-op
    }
    
    # Media
    method render_image($uri, $opts={}) {
        croak("render_image() must be implemented by subclass");
    }
    
    # Metadata
    method render_metadata($key, $value) {
        croak("render_metadata() must be implemented by subclass");
    }
    
    # =================================================================
    # OPTIONAL FEATURES - Backends declare capabilities
    # =================================================================
    
    method supports_feature($feature_name) {
        # Default: no special features
        return 0;
    }
    
    # =================================================================
    # HELPER METHODS - Provided to all subclasses
    # =================================================================
    
    method escape_text($text) {
        # Default: no escaping
        # Subclasses override for format-specific escaping
        return $text;
    }
    
    method format_text($text, $format={}) {
        # Default: basic text formatting
        # Subclasses can override for richer formatting
        my $result = $text;
        
        if ($format->{bold}) {
            $result = $self->wrap_bold($result);
        }
        if ($format->{italic}) {
            $result = $self->wrap_italic($result);
        }
        if ($format->{monospace}) {
            $result = $self->wrap_monospace($result);
        }
        
        return $result;
    }
    
    # Text formatting wrappers - override in subclasses
    method wrap_bold($text) { return $text; }
    method wrap_italic($text) { return $text; }
    method wrap_monospace($text) { return $text; }
    
    # =================================================================
    # UTILITY METHODS
    # =================================================================
    
    method set_song($s) {
        $song = $s;
    }
    
    method get_song() {
        return $song;
    }
    
    method get_config() {
        return $config;
    }
    
    method get_options() {
        return $options;
    }
    
    # Helper to check if a config key exists
    method config_has($key) {
        my @parts = split(/\./, $key);
        my $ref = $config;
        
        foreach my $part (@parts) {
            return 0 unless ref($ref) eq 'HASH' && exists $ref->{$part};
            $ref = $ref->{$part};
        }
        
        return 1;
    }
    
    # Helper to get config value with default
    method config_get($key, $default=undef) {
        my @parts = split(/\./, $key);
        my $ref = $config;
        
        foreach my $part (@parts) {
            return $default unless ref($ref) eq 'HASH' && exists $ref->{$part};
            $ref = $ref->{$part};
        }
        
        return $ref;
    }
    
    # =================================================================
    # LIFECYCLE METHODS
    # =================================================================
    
    BUILD {
        # Validate that we have required config
        croak("config parameter is required") unless defined $config;
    }
    
    # Entry point for generating a songbook
    method generate_songbook($songbook) {
        my @output;
        
        # Begin document
        push @output, $self->render_document_begin({
            title => $songbook->{title} // 'Songbook',
            songs => scalar(@{$songbook->{songs}}),
        });
        
        # Process each song
        foreach my $s (@{$songbook->{songs}}) {
            $self->set_song($s);
            push @output, $self->generate_song($s);
        }
        
        # End document
        push @output, $self->render_document_end();
        
        return \@output;
    }
    
    # Entry point for generating a single song
    method generate_song($s) {
        croak("generate_song() must be implemented by subclass");
    }
}

1;

=head1 NAME

ChordPro::lib::OutputBase - Base class for ChordPro output backends

=head1 SYNOPSIS

    package ChordPro::Output::MyFormat;
    
    use v5.26;
    use Object::Pad;
    
    class ChordPro::Output::MyFormat
      :isa(ChordPro::lib::OutputBase) {
        
        method render_text($text, $style=undef) {
            return $self->escape_text($text);
        }
        
        method generate_song($song) {
            my @output;
            # ... generate output ...
            return \@output;
        }
    }

=head1 DESCRIPTION

This is the base class for all ChordPro output backends. It provides:

=over 4

=item * Abstract interface that all backends must implement

=item * Common helper methods for text processing

=item * Configuration access utilities

=item * Lifecycle management

=back

=head1 REQUIRED METHODS

Subclasses must implement these methods:

=over 4

=item render_document_begin($metadata)

Begin the output document with metadata.

=item render_document_end()

Close the output document.

=item render_text($text, $style)

Render plain or styled text.

=item render_section_begin($type, $label)

Begin a structural section (title, chorus, verse, etc).

=item render_section_end($type)

End a structural section.

=item render_image($uri, $opts)

Render an image with options.

=item render_metadata($key, $value)

Output metadata (title, artist, etc).

=item generate_song($song)

Generate output for a complete song.

=back

=head1 OPTIONAL METHODS

These methods have default implementations:

=over 4

=item supports_feature($feature_name)

Returns true if backend supports the named feature.

=item escape_text($text)

Escape text for the output format.

=item format_text($text, $format)

Apply text formatting (bold, italic, etc).

=back

=head1 HELPER METHODS

=over 4

=item config_get($key, $default)

Get configuration value with dotted key notation.

=item config_has($key)

Check if configuration key exists.

=item get_song()

Get current song being processed.

=back

=head1 SEE ALSO

L<ChordPro::lib::OutputChordProBase>, L<ChordPro::Output::HTML5>

=cut
