package ChordPro::Output::SVG::Strum::StrumlineRenderer;

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

use ChordPro::Output::SVG::Strum::Tokens;
use ChordPro::Output::SVG::Strum::SVGPrimitives;

sub strum_cells_from_text( $text ) {
	my @cells;
	my $column = 1;
	my @tokens = grep { defined($_) && $_ ne '' } split( /\s+/, ($text // '') );

	for my $token ( @tokens ) {
		if ( $token =~ /^(?:\|\:|\:\||\:\|\:|\|\||\|\.|\||\{|\}|\}\{)$/ ) {
			my $bar_kind = 'single';
			$bar_kind = 'double' if $token eq '||';
			$bar_kind = 'repeat-start' if $token eq '|:' || $token eq '{';
			$bar_kind = 'repeat-end' if $token eq ':|' || $token eq '}';
			$bar_kind = 'repeat-both' if $token eq ':|:' || $token eq '}{';
			$bar_kind = 'end' if $token eq '|.';
			push @cells, {
				type => 'bar',
				column => $column,
				bar_kind => $bar_kind,
				bar_symbol => $token,
			};
			$column++;
			next;
		}

		my @parts = split( /~/, $token, -1 );
		my $had_leading_tilde = ( @parts > 1 && ( ($parts[0] // '') eq '' ) ) ? 1 : 0;
		if ( $had_leading_tilde ) {
			shift @parts;
		}
		my @part_info = map { ChordPro::Output::SVG::Strum::Tokens::strum_symbol_info({ name => $_ }) } @parts;

		if ( $had_leading_tilde ) {
			push @cells, {
				type => 'cell',
				column => $column,
				direction => '',
				muted => 0, accent => 0, arpeggio => 0, staccato => 0,
				rest => 1,
				pause => 0,
				connect_left => 0,
			};
			$column++;
		}

		for my $idx (0 .. $#parts) {
			my $info = $part_info[$idx] // {};
			my $prev_info = $idx > 0 ? ($part_info[$idx - 1] // {}) : {};
			my $raw = $info->{raw} // '';

			my $is_rest = $info->{rest} // 0;
			if ( !$is_rest && $raw eq '' && @parts > 1 ) {
				$is_rest = 1 if $idx > 0 && (($prev_info->{raw}//'') ne '');
			}

			my $is_pause = 0;
			if ( !$is_rest ) {
				$is_pause = ($raw eq '' && ($idx == 0 || (($prev_info->{raw}//'') ne ''))) ? 1 : 0;
			}
			my $connect_left = (($info->{direction}//'') ne '' && ($prev_info->{direction}//'') ne '') ? 1 : 0;

			push @cells, {
				type => 'cell',
				column => $column,
				direction => $info->{direction},
				clap => $info->{clap},
				hold_right => $info->{hold_right},
				code => $info->{code},
				glyph => $info->{glyph},
				muted => $info->{muted},
				accent => $info->{accent},
				arpeggio => $info->{arpeggio},
				staccato => $info->{staccato},
				rest => $is_rest,
				pause => $is_pause,
				connect_left => $connect_left,
			};
			$column++;
		}
	}

	my $columns = $column - 1;
	$columns = 1 if $columns < 1;
	return (\@cells, $columns);
}

sub strumline_svg_from_text( %args ) {
	my ($cells, $columns) = strum_cells_from_text($args{text} // '');
	# Expand cell_width automatically when sub-beat pairs are present.
	my $has_pairs = grep { $_->{connect_left} // 0 } @$cells;
	my $default_cw = $has_pairs ? 30 : 24;
	return strumline_svg(
		cells => $cells,
		columns => $args{columns} // $columns,
		show_bars => exists $args{show_bars} ? $args{show_bars} : 1,
		cell_width => exists $args{cell_width} ? $args{cell_width} : $default_cw,
		height => $args{height} // 26,
		stroke_width => $args{stroke_width} // 1.6,
	);
}

sub strumline_svg( %args ) {
	my $cells      = $args{cells} // [];
	my $columns    = $args{columns} // scalar(@$cells) || 1;
	my $show_bars  = $args{show_bars} // 0;
	my $cell_width = $args{cell_width} // 24;
	my $height     = $args{height} // 26;
	my $stroke     = $args{stroke_width} // 1.6;
	my $tight_pair_step = $args{tight_pair_step} // 0.55;

	$columns = 1 if $columns < 1;
	my $width = $columns * $cell_width;
	my $font_stack = ChordPro::Output::SVG::Strum::SVGPrimitives::svg_font_stack();

	my @parts;

	my $last_arrow_x;
	my $pending_tie_from_x;
	for my $cell ( @$cells ) {
		my $column = $cell->{column} // 1;
		my $x = ($column - 0.5) * $cell_width;

		if ( ($cell->{type} // '') eq 'bar' ) {
			$last_arrow_x = undef;
			next unless $show_bars;
			push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_bar_svg(
				x => $x, kind => $cell->{bar_kind},
				symbol => $cell->{bar_symbol});
			next;
		}

		if ( $cell->{rest} ) {
			push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_rest_svg( x => $x, base_y => 0 );
			$last_arrow_x = undef;
			next;
		}

		if ( $cell->{pause} ) {
			push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_pause_svg( x => $x, cell_width => $cell_width );
			$last_arrow_x = undef;
			next;
		}

		my $direction = $cell->{direction} // '';
		my $is_clap = $cell->{clap} ? 1 : 0;
		unless ( $direction || $is_clap ) {
			$last_arrow_x = undef;
			next;
		}

		if ( $cell->{connect_left} && defined $last_arrow_x ) {
			$x = $last_arrow_x + ($cell_width * $tight_pair_step);
		}

		if ( defined $pending_tie_from_x ) {
			push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_tie_svg(
				from_x => $pending_tie_from_x,
				to_x   => $x,
				base_y => 0,
			);
			$pending_tie_from_x = undef;
		}

		if ($is_clap) {
			push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_clap_svg(
				x => $x,
				base_y => 0,
				font_size => 14,
			);
			$last_arrow_x = undef;
		}
		else {
			push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_arrow_svg(
				x => $x, base_y => 0, direction => $direction,
				stroke_width => $stroke,
				info => {
					code     => $cell->{code},
					glyph    => $cell->{glyph},
					muted    => $cell->{muted},
					accent   => $cell->{accent},
					arpeggio => $cell->{arpeggio},
					staccato => $cell->{staccato},
				},
			);
			$last_arrow_x = $x;
		}

		$pending_tie_from_x = $x if $cell->{hold_right};
	}

	return sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.2f %d" width="%.2f" height="%d" aria-hidden="true" style="font-family:%s">%s</svg>',
		$width, $height, $width, $height, ChordPro::Output::SVG::Strum::Tokens::esc($font_stack), join('', @parts));
}

1;
