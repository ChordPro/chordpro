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
use Template;

use ChordPro::Paths;
use ChordPro::Output::ChordProBase;
use ChordPro::Output::ChordDiagram::SVG;

class ChordPro::Output::HTML5
  :isa(ChordPro::Output::ChordProBase) {

    # SVG diagram generator
    field $svg_generator;
    
    # Template engine for CSS generation
    field $template_engine;

    BUILD {
        # Initialize SVG diagram generator with HTML escape function
        $svg_generator = ChordPro::Output::ChordDiagram::SVG->new(
            escape_fn => sub { $self->escape_text(@_) }
        );
        
        # Initialize Template::Toolkit (following LaTeX.pm pattern)
        my $config = $self->config // {};
        my $html5_cfg = eval { $config->{html5} } // {};
        
        my $template_path = CP->findres("templates");
        unless ($template_path) {
            # Fallback for tests - try relative paths
            for my $path ("../lib/ChordPro/res/templates", "lib/ChordPro/res/templates", "../blib/lib/ChordPro/res/templates") {
                if (-d $path) {
                    $template_path = $path;
                    last;
                }
            }
        }
        
        my $include_path = eval { $html5_cfg->{template_include_path} } // [];
        
        $template_engine = Template->new({
            INCLUDE_PATH => [
                @$include_path,
                $template_path,
                $main::CHORDPRO_LIBRARY
            ],
            INTERPOLATE => 1,
        }) || die "$Template::ERROR\n";
    }

    # =================================================================
    # TEMPLATE PROCESSING HELPER
    # =================================================================

    method _process_template($template_name, $vars) {
        my $output = '';
        my $config = $self->config // {};
        my $html5_cfg = eval { $config->{html5} } // {};
        my $template = eval { $html5_cfg->{templates}->{$template_name} } 
                       // "html5/$template_name.tt";
        
        $template_engine->process($template, $vars, \$output)
            || die "Template error ($template_name): " . $template_engine->error();
        
        return $output;
    }

    # =================================================================
    # TEMPLATE-BASED ELEMENT RENDERERS (LaTeX.pm pattern)
    # =================================================================

    method _render_songline_template($element) {
        # Prepare chord-lyric pairs
        my @pairs;
        my $chords = $element->{chords} // [];
        my $phrases = $element->{phrases} // [];
        
        for (my $i = 0; $i < @$phrases; $i++) {
            my $chord = $chords->[$i];
            my $chord_name = '';
            if ($chord) {
                if (ref($chord) eq 'HASH') {
                    $chord_name = $chord->{name} // '';
                } elsif (ref($chord) && $chord->can('chord_display')) {
                    # ChordPro::Chords::Appearance object
                    $chord_name = $chord->chord_display // '';
                } elsif (ref($chord) && $chord->can('name')) {
                    $chord_name = $chord->name // '';
                } else {
                    $chord_name = "$chord";  # Stringify
                }
            }
            
            my $lyrics = $phrases->[$i] // '';
            my $is_chord_only = ($chord_name ne '' && $lyrics eq '');
            
            push @pairs, {
                chord => $chord_name,
                lyrics => $self->process_text_with_markup($lyrics),
                is_chord_only => $is_chord_only,
            };
        }
        
        return $self->_process_template('songline', { pairs => \@pairs });
    }

    method _render_comment_template($element) {
        return $self->_process_template('comment', {
            text => $self->process_text_with_markup($element->{text} // ''),
            italic => ($element->{type} eq 'comment_italic'),
        });
    }

    method _render_image_template($element) {
        my $opts = $element->{opts} // {};
        return $self->_process_template('image', {
            uri => $element->{uri} // '',
            title => $element->{title} // '',
            width => $opts->{width} // '',
            height => $opts->{height} // '',
            class => $opts->{class} // 'cp-image',
        });
    }

    method render_gridline($element) {
        my $tokens = $element->{tokens} // [];
        my $margin = $element->{margin};
        my $comment = $element->{comment};
        
        my $html = '<div class="cp-gridline">';
        
        # Render margin if present
        if ($margin) {
            my $margin_text = $margin->{chord} // $margin->{text} // '';
            if (ref($margin_text) && $margin_text->can('chord_display')) {
                $margin_text = $margin_text->chord_display;
            } elsif (ref($margin_text) && $margin_text->can('name')) {
                $margin_text = $margin_text->name;
            }
            $html .= '<span class="cp-grid-margin">' . $self->escape_text($margin_text) . '</span>';
        }
        
        # Render tokens
        $html .= '<span class="cp-grid-tokens">';
        foreach my $token (@$tokens) {
            my $class = $token->{class} // '';
            my $text = '';
            
            if ($class eq 'chord') {
                my $chord = $token->{chord};
                if (ref($chord) eq 'HASH') {
                    $text = $chord->{name} // '';
                } elsif ($chord && $chord->can('chord_display')) {
                    $text = $chord->chord_display;
                } elsif ($chord && $chord->can('name')) {
                    $text = $chord->name;
                } else {
                    $text = "$chord";
                }
            } else {
                $text = $token->{symbol} // '';
            }
            
            $html .= '<span class="cp-grid-' . $class . '">' . $self->escape_text($text) . '</span>';
        }
        $html .= '</span>';
        
        # Render comment if present
        if ($comment) {
            my $comment_text = $comment->{chord} // $comment->{text} // '';
            if (ref($comment_text) && $comment_text->can('chord_display')) {
                $comment_text = $comment_text->chord_display;
            } elsif (ref($comment_text) && $comment_text->can('name')) {
                $comment_text = $comment_text->name;
            }
            $html .= '<span class="cp-grid-comment">' . $self->escape_text($comment_text) . '</span>';
        }
        
        $html .= '</div>';
        return $html;
    }

    method _process_song_body($body) {
        my $html = '';
        
        foreach my $element (@{$body}) {
            my $type = $element->{type};
            
            # Dispatch to appropriate handler
            if ($type eq 'songline') {
                $html .= $self->_render_songline_template($element);
            }
            elsif ($type eq 'comment' || $type eq 'comment_italic') {
                $html .= $self->_render_comment_template($element);
            }
            elsif ($type eq 'image') {
                $html .= $self->_render_image_template($element);
            }
            elsif ($type eq 'empty') {
                $html .= qq{<div class="cp-empty"></div>\n};
            }
            elsif ($type eq 'chorus') {
                $html .= qq{<div class="cp-chorus">\n};
                $html .= $self->_process_song_body($element->{body});
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'verse') {
                $html .= qq{<div class="cp-verse">\n};
                $html .= $self->_process_song_body($element->{body});
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'bridge') {
                $html .= qq{<div class="cp-bridge">\n};
                $html .= $self->_process_song_body($element->{body});
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'tab') {
                $html .= qq{<div class="cp-tab">\n};
                $html .= $self->_process_song_body($element->{body});
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'tabline') {
                my $text = $self->escape_text($element->{text} // '');
                $html .= qq{<div class="cp-tabline">$text</div>\n};
            }
            elsif ($type eq 'grid') {
                $html .= qq{<div class="cp-grid">\n};
                $html .= $self->_process_song_body($element->{body});
                $html .= qq{</div>\n};
            }
            elsif ($type eq 'gridline') {
                $html .= $self->render_gridline($element);
            }
            elsif ($type eq 'new_page' || $type eq 'newpage') {
                $html .= qq{<div class="cp-new-page"></div>\n};
            }
            elsif ($type eq 'new_physical_page') {
                $html .= qq{<div class="cp-new-physical-page"></div>\n};
            }
            elsif ($type eq 'colb' || $type eq 'column_break') {
                $html .= qq{<div class="cp-column-break"></div>\n};
            }
            # Ignore other types (set, control, etc.)
        }
        
        return $html;
    }

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
        # Structurize the song to convert start_of/end_of directives into containers
        eval { $song->structurize } if $song->can('structurize');

        # Process metadata with markup
        my $meta = $song->{meta} // {};
        my $processed_meta = {};
        foreach my $key (keys %$meta) {
            if (ref($meta->{$key}) eq 'ARRAY') {
                $processed_meta->{$key} = [
                    map { $self->process_text_with_markup($_) } @{$meta->{$key}}
                ];
            }
        }

        # Process song body to HTML
        my $body_html = '';
        if ($song->{body}) {
            $body_html = $self->_process_song_body($song->{body});
        }

        # Generate chord diagrams if present (unless lyrics-only)
        my $chord_diagrams_html = '';
        unless ($self->is_lyrics_only()) {
            $chord_diagrams_html = $self->render_chord_diagrams($song);
        }

        # Process title/subtitles with markup
        my $processed_title = $song->{title} ? $self->process_text_with_markup($song->{title}) : '';
        my @processed_subtitles = ();
        if ($song->{subtitle}) {
            @processed_subtitles = map { $self->process_text_with_markup($_) } @{$song->{subtitle}};
        }

        # Prepare template variables
        my $vars = {
            title => $processed_title,
            subtitle => \@processed_subtitles,
            meta => $processed_meta,
            chord_diagrams_html => $chord_diagrams_html,
            body_html => $body_html,
        };

        # Process song template
        return $self->_process_template('song', $vars);
    }

    # =================================================================
    # HTML-SPECIFIC OVERRIDES - Layout Directives
    # =================================================================

    # Override layout directive handlers for HTML
    method handle_newpage($elt) {
        return qq{<div style="page-break-before: always;"></div>\n};
    }

    method handle_new_page($elt) {
        return $self->handle_newpage($elt);
    }

    method handle_new_physical_page($elt) {
        # In HTML, physical page is same as logical page
        return $self->handle_newpage($elt);
    }

    method handle_colb($elt) {
        return qq{<div style="column-break-before: always;"></div>\n};
    }

    method handle_column_break($elt) {
        return $self->handle_colb($elt);
    }

    method handle_columns($elt) {
        my $num = $elt->{value} // 1;
        if ($num > 1) {
            return qq{<div style="column-count: $num;">\n};
        } else {
            return qq{</div><!-- end columns -->\n};
        }
    }

    # =================================================================
    # HTML-SPECIFIC OVERRIDES - Text Formatting
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
    # CHORD DIAGRAM RENDERING
    # =================================================================

    method render_chord_diagrams($song) {
        my $cfg = $self->config // {};
        my $diagrams_cfg = $cfg->{diagrams} // {};
        
        # Check if diagrams should be shown
        my $show = $diagrams_cfg->{show} // 'all';
        return '' if $show eq 'none';
        
        # Get list of chords to display
        my @chord_names;
        if ($song->{chords} && $song->{chords}->{chords}) {
            @chord_names = @{$song->{chords}->{chords}};
        } else {
            return '';
        }
        
        # Filter based on 'show' setting
        my @chords_to_display;
        my $suppress = $diagrams_cfg->{suppress} // [];
        my %suppress = map { $_ => 1 } @$suppress;
        
        foreach my $chord_name (@chord_names) {
            next if $suppress{$chord_name};
            
            my $info = $song->{chordsinfo}->{$chord_name};
            next unless $info;
            next unless $info->can('has_diagram') && $info->has_diagram;
            
            # Skip if show=user and chord is not user-defined
            next if $show eq 'user' && !$info->{diagram};
            
            push @chords_to_display, { name => $chord_name, info => $info };
        }
        
        return '' unless @chords_to_display;
        
        # Sort if requested
        if ($diagrams_cfg->{sorted}) {
            @chords_to_display = sort { 
                ($a->{info}->{root_ord} // 0) <=> ($b->{info}->{root_ord} // 0)
                || $a->{name} cmp $b->{name}
            } @chords_to_display;
        }
        
        # Generate SVG diagrams
        my @diagrams;
        foreach my $chord (@chords_to_display) {
            my $svg = $svg_generator->generate_diagram($chord->{name}, $chord->{info});
            push @diagrams, $svg if $svg;
        }
        
        return '' unless @diagrams;
        
        # Use template to render
        return $self->_process_template('chord_diagrams', { diagrams => \@diagrams });
    }

    # =================================================================
    # CSS GENERATION
    # =================================================================

    method generate_default_css() {
        my $config = $self->config // {};
        my $html5_cfg = eval { $config->{html5} } // {};
        
        # Extract and clone CSS sub-configs to plain hashes (avoid restricted hash issues)
        my $css_config = eval { $html5_cfg->{css} } // {};
        my $colors_cfg = eval { $css_config->{colors} } // {};
        my $fonts_cfg = eval { $css_config->{fonts} } // {};
        my $sizes_cfg = eval { $css_config->{sizes} } // {};
        my $spacing_cfg = eval { $css_config->{spacing} } // {};
        
        my $vars = {
            # CSS customization from config
            # Deep clone to plain hashes to avoid restricted hash issues in templates
            colors => { %$colors_cfg },
            fonts => { %$fonts_cfg },
            sizes => { %$sizes_cfg },
            spacing => { %$spacing_cfg },
        };
        
        # Process CSS template
        my $css = '';
        my $template = eval { $html5_cfg->{templates}->{css} } // 'html5/base.tt';
        
        $template_engine->process($template, $vars, \$css)
            || die "CSS Template error: " . $template_engine->error();
        
        # Append custom CSS if configured
        if (my $custom_file = eval { $html5_cfg->{css}->{'custom-css-file'} }) {
            if (-f $custom_file) {
                open my $fh, '<:utf8', $custom_file or warn "Can't load custom CSS: $!";
                if ($fh) {
                    local $/;
                    $css .= "\n\n/* User Custom CSS */\n" . <$fh>;
                    close $fh;
                }
            }
        }
        
        return $css;
    }
}

# =================================================================
# COMPATIBILITY WRAPPER - ChordPro calls as class method
# =================================================================

# This sub is called by ChordPro as a class method.
# It creates an instance and generates output using templates (following LaTeX.pm pattern).
sub generate_songbook {
    my ( $pkg, $sb ) = @_;

    # Create instance with config/options from global variables
    my $backend = $pkg->new(
        config => $main::config,
        options => $main::options,
    );

    # Process each song (returns HTML strings)
    my @songs_html;
    foreach my $song ( @{$sb->{songs}} ) {
        push @songs_html, $backend->generate_song($song);
    }

    # Generate CSS
    my $css = $backend->generate_default_css();

    # Prepare template variables
    my $vars = {
        title => $sb->{title} // $sb->{songs}->[0]->{title} // 'Songbook',
        songs => \@songs_html,
        css => $css,
    };

    # Process songbook template
    my $output = $backend->_process_template('songbook', $vars);

    # Return as array ref of lines (ChordPro expects this format)
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
