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

use Template;
use ChordPro::Paths;
use ChordPro::Output::HTML5;
use ChordPro::Output::HTML5Paged::FormatGenerator;

our $CHORDPRO_LIBRARY;  # May be set externally

class ChordPro::Output::HTML5Paged
  :isa(ChordPro::Output::HTML5) {

    field $format_generator;
    field $template_engine;
    
    BUILD {
        # Initialize FormatGenerator for PDF format → CSS translation
        $format_generator = ChordPro::Output::HTML5Paged::FormatGenerator->new(
            config => $self->config,
            options => $self->options,
        );
        
        # Initialize Template::Toolkit (following LaTeX.pm pattern)
        my $config = $self->config // {};
        my $cfg = {};
        if (exists $config->{html5} && ref($config->{html5}) eq 'HASH') {
            $cfg = $config->{html5}->{paged} // {};
        }
        
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
        
        $template_engine = Template->new({
            INCLUDE_PATH => [
                @{$cfg->{template_include_path} // []},
                $template_path,
                $CHORDPRO_LIBRARY
            ],
            INTERPOLATE => 1,
        }) || die "$Template::ERROR\n";
    }

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
    # OVERRIDE SONG GENERATION TO ADD METADATA ATTRIBUTES
    # =================================================================

    method generate_song($song) {
        # Call parent to get base HTML
        my $output = $self->SUPER::generate_song($song);
        
        # Add metadata attributes for CSS string-set
        # These allow @page margin boxes to access song metadata
        if ($song->{title}) {
            my $escaped = $self->escape_text($song->{title});
            # Add data-title attribute to cp-title element
            $output =~ s/(<h1 class="cp-title")/$1 data-title="$escaped"/;
        }
        
        if ($song->{subtitle} && @{$song->{subtitle}}) {
            my $escaped = $self->escape_text($song->{subtitle}[0]);
            # Add data-subtitle attribute to first cp-subtitle element
            $output =~ s/(<h2 class="cp-subtitle")/$1 data-subtitle="$escaped"/;
        }
        
        my $meta = $song->{meta} || {};
        
        if ($meta->{artist} && @{$meta->{artist}}) {
            my $escaped = $self->escape_text($meta->{artist}[0]);
            # Add data-artist attribute to first cp-artist element
            $output =~ s/(<div class="cp-artist")/$1 data-artist="$escaped"/;
        }
        
        if ($meta->{album} && @{$meta->{album}}) {
            my $escaped = $self->escape_text($meta->{album}[0]);
            # Add data-album attribute to cp-album element
            $output =~ s/(<div class="cp-album")/$1 data-album="$escaped"/;
        }
        
        if ($meta->{arranger} && @{$meta->{arranger}}) {
            my $escaped = $self->escape_text($meta->{arranger}[0]);
            # Add data-arranger attribute to first cp-arranger element
            $output =~ s/(<div class="cp-arranger")/$1 data-arranger="$escaped"/;
        }
        
        if ($meta->{lyricist} && @{$meta->{lyricist}}) {
            my $escaped = $self->escape_text($meta->{lyricist}[0]);
            # Add data-lyricist attribute to first cp-lyricist element
            $output =~ s/(<div class="cp-lyricist")/$1 data-lyricist="$escaped"/;
        }
        
        if ($meta->{copyright} && @{$meta->{copyright}}) {
            my $escaped = $self->escape_text($meta->{copyright}[0]);
            # Add data-copyright attribute to first cp-copyright element
            $output =~ s/(<div class="cp-copyright")/$1 data-copyright="$escaped"/;
        }
        
        if ($meta->{duration} && @{$meta->{duration}}) {
            my $escaped = $self->escape_text($meta->{duration}[0]);
            # Add data-duration attribute to cp-duration element
            $output =~ s/(<div class="cp-duration")/$1 data-duration="$escaped"/;
        }
        
        return $output;
    }

    # =================================================================
    # CONFIGURATION RESOLUTION (Phase 4)
    # =================================================================

    method _resolve_theme_colors() {
        my $config = $self->config // {};
        my $pdf_theme = eval { $config->{pdf}->{theme} } // {};
        my $html_theme = eval { $config->{html5}->{paged}->{theme} } // {};
        
        # HTML5Paged overrides PDF, with fallback defaults
        # Must use eval{} for each key access due to restricted hashes
        my $fg = eval { $html_theme->{foreground} } // eval { $pdf_theme->{foreground} } // 'black';
        my $fg_med = eval { $html_theme->{'foreground-medium'} } // eval { $pdf_theme->{'foreground-medium'} } // '#888';
        my $fg_light = eval { $html_theme->{'foreground-light'} } // eval { $pdf_theme->{'foreground-light'} } // '#ddd';
        my $bg = eval { $html_theme->{background} } // eval { $pdf_theme->{background} } // 'white';
        
        return {
            foreground => $self->_convert_color_to_css($fg),
            'foreground-medium' => $self->_convert_color_to_css($fg_med),
            'foreground-light' => $self->_convert_color_to_css($fg_light),
            background => $self->_convert_color_to_css($bg),
        };
    }

    method _resolve_spacing() {
        my $config = $self->config // {};
        my $pdf_spacing = eval { $config->{pdf}->{spacing} } // {};
        my $html_spacing = eval { $config->{html5}->{paged}->{spacing} } // {};
        
        # HTML5Paged overrides PDF, with fallback defaults
        # Use eval{} for each key access due to restricted hashes
        return {
            title => eval { $html_spacing->{title} } // eval { $pdf_spacing->{title} } // 1.2,
            lyrics => eval { $html_spacing->{lyrics} } // eval { $pdf_spacing->{lyrics} } // 1.2,
            chords => eval { $html_spacing->{chords} } // eval { $pdf_spacing->{chords} } // 1.2,
            diagramchords => eval { $html_spacing->{diagramchords} } // eval { $pdf_spacing->{diagramchords} } // 1.2,
            grid => eval { $html_spacing->{grid} } // eval { $pdf_spacing->{grid} } // 1.2,
            tab => eval { $html_spacing->{tab} } // eval { $pdf_spacing->{tab} } // 1,
            toc => eval { $html_spacing->{toc} } // eval { $pdf_spacing->{toc} } // 1.4,
            empty => eval { $html_spacing->{empty} } // eval { $pdf_spacing->{empty} } // 1,
        };
    }

    method _resolve_chorus_styles() {
        my $config = $self->config // {};
        my $pdf_chorus = eval { $config->{pdf}->{chorus} } // {};
        my $html_chorus = eval { $config->{html5}->{paged}->{chorus} } // {};
        
        my $pdf_bar = eval { $pdf_chorus->{bar} } // {};
        my $html_bar = eval { $html_chorus->{bar} } // {};
        
        my $bar_color = eval { $html_bar->{color} } // eval { $pdf_bar->{color} } // 'foreground';
        
        # Resolve color references to theme colors
        if ($bar_color eq 'foreground' || $bar_color eq 'foreground-medium' || $bar_color eq 'foreground-light') {
            my $theme = $self->_resolve_theme_colors();
            $bar_color = $theme->{$bar_color} // $theme->{foreground};
        }
        
        return {
            indent => eval { $html_chorus->{indent} } // eval { $pdf_chorus->{indent} } // 0,
            bar_offset => eval { $html_bar->{offset} } // eval { $pdf_bar->{offset} } // 8,
            bar_width => eval { $html_bar->{width} } // eval { $pdf_bar->{width} } // 1,
            bar_color => $self->_convert_color_to_css($bar_color),
        };
    }

    method _resolve_grid_styles() {
        my $config = $self->config // {};
        my $pdf_grids = eval { $config->{pdf}->{grids} } // {};
        my $html_grids = eval { $config->{html5}->{paged}->{grids} } // {};
        
        my $pdf_symbols = eval { $pdf_grids->{symbols} } // {};
        my $html_symbols = eval { $html_grids->{symbols} } // {};
        
        my $pdf_volta = eval { $pdf_grids->{volta} } // {};
        my $html_volta = eval { $html_grids->{volta} } // {};
        
        return {
            symbols_color => $self->_convert_color_to_css(
                eval { $html_symbols->{color} } // eval { $pdf_symbols->{color} } // 'blue'
            ),
            volta_color => $self->_convert_color_to_css(
                eval { $html_volta->{color} } // eval { $pdf_volta->{color} } // 'blue'
            ),
        };
    }

    method _convert_color_to_css($color) {
        # Pass through: hex colors, CSS color names, rgb(), rgba(), etc.
        # No conversion needed - CSS accepts most color formats
        return $color;
    }

    # =================================================================
    # PAGED.JS CSS GENERATION
    # =================================================================

    method generate_paged_css() {
        my $config = $self->config // {};
        my $pdf = $config->{pdf} // {};
        
        # Check for html5.paged config (may not exist in all configs)
        my $html5_paged = {};
        if (exists $config->{html5} && ref($config->{html5}) eq 'HASH' 
            && exists $config->{html5}->{paged} && ref($config->{html5}->{paged}) eq 'HASH') {
            $html5_paged = $config->{html5}->{paged};
        }

        # Get page setup configuration (html5.paged overrides pdf settings)
        # Use eval to safely access potentially restricted hash keys
        my $papersize = eval { $html5_paged->{papersize} } // $pdf->{papersize} // 'a4';
        my $margintop = eval { $html5_paged->{margintop} } // $pdf->{margintop} // 80;
        my $marginbottom = eval { $html5_paged->{marginbottom} } // $pdf->{marginbottom} // 40;
        my $marginleft = eval { $html5_paged->{marginleft} } // $pdf->{marginleft} // 40;
        my $marginright = eval { $html5_paged->{marginright} } // $pdf->{marginright} // 40;

        # Convert papersize to CSS
        my $css_pagesize = $self->_format_papersize($papersize);

        # Convert margins to CSS (PDF uses pt, we convert to mm for paged.js)
        my $css_margins = $self->_format_margins($margintop, $marginright, $marginbottom, $marginleft);
        
        # Generate format rules (headers/footers) via FormatGenerator
        my $format_rules = $format_generator->generate_rules();
        
        # Collect template variables
        # Clone config hashes to plain hashrefs to avoid restricted hash issues
        my $css_config = eval { $html5_paged->{css} } // {};
        
        # Extract and clone CSS sub-configs to plain hashes
        my $colors_cfg = eval { $css_config->{colors} } // {};
        my $fonts_cfg = eval { $css_config->{fonts} } // {};
        my $sizes_cfg = eval { $css_config->{sizes} } // {};
        my $spacing_cfg = eval { $css_config->{spacing} } // {};
        
        # Resolve PDF config → CSS (Phase 4)
        my $theme = $self->_resolve_theme_colors();
        my $spacing = $self->_resolve_spacing();
        my $chorus_styles = $self->_resolve_chorus_styles();
        my $grid_styles = $self->_resolve_grid_styles();
        
        # Header/footer spacing (Phase 4)
        my $headspace = eval { $html5_paged->{headspace} } // $pdf->{headspace} // 60;
        my $footspace = eval { $html5_paged->{footspace} } // $pdf->{footspace} // 20;
        
        my $vars = {
            # Page setup
            papersize => $css_pagesize,
            margins => $css_margins,
            margintop => $margintop,
            marginbottom => $marginbottom,
            marginleft => $marginleft,
            marginright => $marginright,
            headspace => $headspace,
            footspace => $footspace,
            
            # Format rules from FormatGenerator
            format_rules => $format_rules,
            
            # Phase 4: PDF config compatibility
            theme => $theme,
            spacing => $spacing,
            chorus_styles => $chorus_styles,
            grid_styles => $grid_styles,
            
            # CSS customization from config (Phase 3)
            # Deep clone to plain hashes to avoid restricted hash issues in templates
            colors => { %$colors_cfg },
            fonts => { %$fonts_cfg },
            sizes => { %$sizes_cfg },
        };
        
        # Process template
        my $css = '';
        my $template = $html5_paged->{templates}->{css} // 'html5paged/base.tt';
        
        $template_engine->process($template, $vars, \$css)
            || die "Template error: " . $template_engine->error();
        
        # Append custom CSS if configured (Phase 3)
        if (my $custom_file = eval { $html5_paged->{css}->{'custom-css-file'} }) {
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
