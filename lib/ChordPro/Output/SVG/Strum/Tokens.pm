package ChordPro::Output::SVG::Strum::Tokens;

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;
use URI::Escape ();
use ChordPro::Symbols qw( strum );
use Exporter 'import';
our @EXPORT_OK = qw( bar_unicode esc svg_to_data_uri chord_display_text strum_name normalize_grid_chord_parts strum_symbol_info );

use constant {
    MUSIC_BAR          => "\x{1D100}",  # MUSICAL SYMBOL SINGLE BARLINE
    MUSIC_FINALBAR     => "\x{1D102}",  # MUSICAL SYMBOL FINAL BARLINE
    MUSIC_DBLBAR       => "\x{1D103}",  # MUSICAL SYMBOL DOUBLE BARLINE
    MUSIC_REPEAT_START => "\x{1D106}",  # MUSICAL SYMBOL REPEAT SIGN LEFT
    MUSIC_REPEAT_END   => "\x{1D107}",  # MUSICAL SYMBOL REPEAT SIGN RIGHT
};

sub esc( $text ) {
	return "" unless defined $text;
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	$text =~ s/"/&quot;/g;
	$text =~ s/'/&#39;/g;
	$text;
}

sub bar_unicode( $symbol ) {
	return MUSIC_DBLBAR . MUSIC_FINALBAR     if $symbol eq '||';
	return MUSIC_REPEAT_START                if $symbol eq '|:' || $symbol eq '{';
	return MUSIC_REPEAT_END                  if $symbol eq ':|' || $symbol eq '}';
	return MUSIC_REPEAT_END . MUSIC_REPEAT_START if $symbol eq ':|:' || $symbol eq '}{';
	return MUSIC_FINALBAR                    if $symbol eq '|.';
	return MUSIC_BAR;
}

sub svg_to_data_uri( $svg ) {
	return "" unless defined($svg) && $svg ne '';
	my $escaped = URI::Escape::uri_escape_utf8($svg);
	return "data:image/svg+xml;charset=utf-8,$escaped";
}

sub chord_display_text( $chord ) {
	return "" unless defined $chord;

	my $name = "";

	if ( ref($chord) eq 'HASH' ) {
		$name = $chord->{name} // $chord->{format} // "";
		if ( $name eq "" && ref($chord->{info}) eq 'HASH' ) {
			$name = $chord->{info}->{name} // $chord->{info}->{format} // "";
		}
	}
	elsif ( ref($chord) eq 'ARRAY' ) {
		if ( ref($chord->[2]) eq 'HASH' ) {
			$name = $chord->[2]->{name} // $chord->[2]->{format} // "";
		}
		$name = $chord->[0] // "" if $name eq "";
	}
	elsif ( ref($chord) ) {
		if ( $chord->can('info') ) {
			my $info = $chord->info;
			if ( ref($info) eq 'HASH' ) {
				$name = $info->{name} // $info->{format} // '';
			}
			elsif ( ref($info) ) {
				$name = $info->name if $info->can('name');
				if ( $name eq '' && $info->can('format') ) {
					$name = $info->format;
				}
			}
		}
		$name = $chord->name if $name eq '' && $chord->can('name');
		if ( $name eq "" && $chord->can('chord_display') ) {
			$name = $chord->chord_display;
		}
	}
	else {
		$name = "$chord";
	}

	return $name // "";
}

sub strum_name( $chord ) {
	return lc(chord_display_text($chord));
}

sub normalize_grid_chord_parts( $parts_in ) {
	my @parts = @{ $parts_in // [] };

	if ( @parts > 1 && ( ($parts[0] // '') eq '' ) ) {
		shift @parts;
	}

	@parts = ('') unless @parts;
	return \@parts;
}

sub strum_symbol_info( $chord ) {
	my $raw = strum_name($chord);
	my $token = $raw;
	my %info = (
		raw       => $raw,
		direction => '',
		clap      => 0,
		hold_right => 0,
		muted     => 0,
		accent    => 0,
		arpeggio  => 0,
		staccato  => 0,
		rest      => 0,
		code      => '',
		glyph     => '',
	);

	if ( $raw eq '.' ) {
		$info{rest} = 1;
		return \%info;
	}

	return \%info if $raw eq '';

	if ( $token =~ s/_+$// ) {
		$info{hold_right} = 1;
	}

	if ( $token =~ /down/ ) {
		$info{direction} = 'down';
		$token =~ s/down//g;
	}
	elsif ( $token =~ /dn/ ) {
		$info{direction} = 'down';
		$token =~ s/dn//g;
	}
	elsif ( $token =~ /up/ ) {
		$info{direction} = 'up';
		$token =~ s/up//g;
	}
	elsif ( $token =~ /↠|↣|↡|↤|↦|↩|↢|↥/ ) {
		$info{direction} = 'down';
		$token =~ s/↠|↣|↡|↤|↦|↩|↢|↥//g;
	}
	elsif ( $token =~ /←|↖|↓|↑|↔|↙|→|↕/ ) {
		$info{direction} = 'up';
		$token =~ s/←|↖|↓|↑|↔|↙|→|↕//g;
	}
	elsif ( $token =~ /d/ ) {
		$info{direction} = 'down';
		$token =~ s/d//g;
	}
	elsif ( $token =~ /u/ ) {
		$info{direction} = 'up';
		$token =~ s/u//g;
	}

	$info{muted}    = 1 if $token =~ /x/i;
	$info{accent}   = 1 if $token =~ /\+/;
	$info{arpeggio} = 1 if $token =~ /a/;
	$info{staccato} = 1 if $token =~ /s/;
	my $is_plain_direction = $raw =~ /^(?:d|dn|down|u|up)_*$/i ? 1 : 0;

	# Standalone x in strum rows is a clap/percussive beat marker, not a directional mute.
	if ( $info{direction} eq '' && $token =~ /^x$/i ) {
		$info{clap} = 1;
		$info{muted} = 0;
	}

	if ( $info{direction} ne '' ) {
		my $dir = $info{direction} eq 'down' ? 'd' : 'u';
		my $suffix = '';
		# Keep muted/staccato/arpeggio mutually ordered and deterministic.
		if ( $info{muted} ) {
			$suffix = 'x';
		}
		elsif ( $info{arpeggio} ) {
			$suffix = 'a';
		}
		elsif ( $info{staccato} ) {
			$suffix = 's';
		}

		my $code = $dir . $suffix . ( $info{accent} ? '+' : '' );
		$info{code} = $code;
		# Keep plain dn/up on configurable up/down defaults in draw_arrow_svg.
		if ( !$is_plain_direction ) {
			my $glyph = strum($code);
			$info{glyph} = $glyph if defined($glyph) && $glyph ne '';
		}
	}

	return \%info;
}

1;
