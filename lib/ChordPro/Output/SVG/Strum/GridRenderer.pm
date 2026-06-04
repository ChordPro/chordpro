package ChordPro::Output::SVG::Strum::GridRenderer;

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

use ChordPro::Paths;
use ChordPro::Output::SVG::Strum::Tokens;
use ChordPro::Output::SVG::Strum::SVGPrimitives;

# ============================================================
# Bar icon loader — reads SVG files from res/styles/svg/
# ============================================================

my $_bar_icons_cache;

sub _load_bar_icons() {
	return $_bar_icons_cache if defined $_bar_icons_cache;

	my %icon_files = (
		'single'       => [ 'Music-bar.svg',       6         ],
		'double'       => [ 'Music-doublebar.svg',  14        ],
		'end'          => [ 'Music-endbar.svg',     21        ],
		'repeat-start' => [ 'Repeatsign-left.svg',  46.132114 ],
		'repeat-end'   => [ 'Repeatsign-right.svg', 46.132114 ],
	);

	my %icons;
	for my $kind (sort keys %icon_files) {
		my ($filename, $width) = @{ $icon_files{$kind} };
		my $path = eval { CP->findres("styles/svg/$filename") };
		next unless $path && -f $path;

		open my $fh, '<:utf8', $path or next;
		my $raw = do { local $/; <$fh> };
		close $fh;
		next unless defined $raw;

		# Strip XML declaration, comments, sodipodi/inkscape elements
		$raw =~ s/<\?xml[^>]*\?>//g;
		$raw =~ s/<!--.*?-->//gs;
		$raw =~ s/<sodipodi:[^>]*\/>//g;
		$raw =~ s/<sodipodi:[^>]*>.*?<\/sodipodi:[^>]*>//gs;
		$raw =~ s/<inkscape:[^>]*\/>//g;
		# Strip outer <svg ...> wrapper and </svg>
		$raw =~ s/<svg\b[^>]*>//;
		$raw =~ s/<\/svg>//;
		# Strip empty <defs .../> or <defs ...></defs>
		$raw =~ s/<defs[^>]*\/>//g;
		$raw =~ s/<defs[^>]*>\s*<\/defs>//g;
		# Normalize black fill in style= to currentColor
		$raw =~ s/fill:#000000;//g;
		$raw =~ s/fill-opacity:1;//g;
		# Remove empty style attributes
		$raw =~ s/\s*style="\s*"//g;
		# Trim
		$raw =~ s/^\s+|\s+$//g;

		$icons{$kind} = { content => $raw, width => $width };
	}

	$_bar_icons_cache = \%icons;
	return \%icons;
}

# Build <defs> block with <symbol> elements for the given bar kinds
sub _bar_symbol_defs( $icons, $used_kinds ) {
	my @syms;
	for my $kind (sort keys %$used_kinds) {
		my $ico = $icons->{$kind} or next;
		my $w   = $ico->{width};
		my $content = $ico->{content};
		push @syms, sprintf(
			'<symbol id="bar-%s" viewBox="0 0 %.6f 100" preserveAspectRatio="none"><g fill="currentColor">%s</g></symbol>',
			$kind, $w, $content);
	}
	return @syms ? '<defs>' . join('', @syms) . '</defs>' : '';
}

# Emit <use> for a bar icon, centered on $x, from $bar_top to $bar_bottom
sub _bar_use( $kind, $x, $bar_top, $bar_bottom, $icons ) {
	my $ico = $icons->{$kind};
	unless ($ico) {
		# Fallback: thin rect
		return sprintf('<rect x="%.2f" y="%.2f" width="1" height="%.2f" fill="currentColor"/>',
			$x - 0.5, $bar_top, $bar_bottom - $bar_top);
	}
	my $icon_w  = $ico->{width};
	my $h       = $bar_bottom - $bar_top;
	# Keep bar thickness stable in X and stretch only in Y.
	my $scaled_w = $icon_w * (20 / 100);
	my $use_x    = $x - $scaled_w / 2;
	return sprintf('<use href="#bar-%s" x="%.4f" y="%.2f" width="%.4f" height="%.2f"/>',
		$kind, $use_x, $bar_top, $scaled_w, $h);
}

# Map bar symbol string → icon kind
sub _bar_kind( $symbol ) {
	return 'repeat-start' if $symbol eq '|:' || $symbol eq '{';
	return 'repeat-end'   if $symbol eq ':|' || $symbol eq '}';
	return 'double'       if $symbol eq '||';
	return 'end'          if $symbol eq '|.';
	return 'single';
}

# ============================================================
# render_grid — per-row SVG rendering (universal backend)
# ============================================================

sub render_grid( %args ) {
	my $rows   = $args{rows}   // [];
	my $layout = $args{layout} // {};

	my $cell_width      = $layout->{cell_width}      // $args{cell_width}      // 24;
	my $row_height      = $layout->{row_height}      // $args{row_height}      // 26;
	my $row_gap         = $layout->{row_gap}          // $args{row_gap}          // 6;
	my $font_size       = $layout->{font_size}        // $args{font_size}        // 12;
	my $tight_pair_step = $layout->{tight_pair_step}  // $args{tight_pair_step}  // 0.55;

	my $compute_columns = sub ($tokens, $is_strumline = 0) {
		my $cols = 0;
		for my $token (@$tokens) {
			my $class = $token->{class} // '';
			if ($class eq 'chords') {
				if ($is_strumline) {
					$cols += 1;
				}
				else {
					my $parts = ChordPro::Output::SVG::Strum::Tokens::normalize_grid_chord_parts( $token->{chords} );
					my $n = scalar(@$parts);
					$n = 1 if $n < 1;
					$cols += $n;
				}
			}
			else {
				$cols++;
			}
		}
		$cols = 1 if $cols < 1;
		return $cols;
	};

	my $columns = $args{columns};
	if (my $shape = $args{shape}) {
		if (($shape->{total_cells} // 0) > 0) {
			$columns = $shape->{total_cells};
		}
	}
	if (!defined $columns || $columns < 1) {
		$columns = 1;
		for my $row (@$rows) {
			my $is_strum = (($row->{type} // '') eq 'strumline') ? 1 : 0;
			my $line_cols = $compute_columns->($row->{tokens} // [], $is_strum);
			$columns = $line_cols if $line_cols > $columns;
		}
	}

	my $bar_columns_for = sub ($tokens, $is_strumline = 0) {
		my @bars;
		my $col = 1;
		for my $token (@$tokens) {
			my $class = $token->{class} // '';
			if ($class eq 'chords') {
				$col += $is_strumline ? 1 : do {
					my $parts = ChordPro::Output::SVG::Strum::Tokens::normalize_grid_chord_parts( $token->{chords} );
					my $n = scalar(@$parts); $n = 1 if $n < 1; $n;
				};
				next;
			}
			push @bars, $col if $class eq 'bar';
			$col++;
		}
		return \@bars;
	};

	my @canonical_bar_columns;
	for my $row (@$rows) {
		my $is_strum = (($row->{type} // '') eq 'strumline') ? 1 : 0;
		my $bars = $bar_columns_for->($row->{tokens} // [], $is_strum);
		next unless @$bars;
		@canonical_bar_columns = @$bars;
		last if (($row->{type} // '') eq 'gridline');
	}

	# Group rows into output units: gridline immediately followed by strumline → pair
	my @units;
	my $idx = 0;
	while ($idx < scalar(@$rows)) {
		my $this_type = $rows->[$idx]{type} // '';
		my $next_type = ($idx + 1 < scalar(@$rows)) ? ($rows->[$idx+1]{type} // '') : '';
		if ($this_type eq 'gridline' && $next_type eq 'strumline') {
			push @units, { rows => [ $rows->[$idx], $rows->[$idx+1] ], is_pair => 1 };
			$idx += 2;
		}
		else {
			push @units, { rows => [ $rows->[$idx] ], is_pair => 0 };
			$idx++;
		}
	}

	my $bar_icons  = _load_bar_icons();
	my $width      = $columns * $cell_width;
	my $font_stack = ChordPro::Output::SVG::Strum::SVGPrimitives::svg_font_stack();

	my @result_rows;
	for my $unit (@units) {
		my $is_pair    = $unit->{is_pair};
		my $unit_rows  = $unit->{rows};
		my $height     = $is_pair ? (2 * $row_height + $row_gap) : $row_height;

		my %used_kinds;
		my @parts;

		for my $ri (0 .. $#$unit_rows) {
			my $row       = $unit_rows->[$ri];
			my $type      = $row->{type} // 'gridline';
			my $tokens    = $row->{tokens} // [];
			my $base_y    = $ri * ($row_height + $row_gap);
			my $bar_top   = $base_y + 3;
			my $bar_bottom;
			if ($is_pair && $ri == 0) {
				# Paired gridline: bar spans both rows
				$bar_bottom = $base_y + 2 * $row_height + $row_gap - 3;
			}
			else {
				$bar_bottom = $base_y + $row_height - 3;
			}
			my $bar_label_y = ($is_pair && $ri == 0)
				? ($base_y + 2 * $row_height + $row_gap)
				: ($base_y + $row_height);
			my $is_strum_row         = ($type eq 'strumline');
			my $is_paired_strumline  = ($is_pair && $ri == 1);

			my $column    = 1;
			my $bar_index = 0;
			my $last_arrow_x;
			my $pending_tie_x;
			my $prev_was_bar = 0;

			for my $token (@$tokens) {
				my $class = $token->{class} // '';

				if ($class eq 'chords') {
					$prev_was_bar = 0;
					my $parts_raw       = $token->{chords} // [];
					my $had_leading_empty = ( @$parts_raw > 1 && ( ($parts_raw->[0] // '') eq '' ) ) ? 1 : 0;
					my $parts_in        = ChordPro::Output::SVG::Strum::Tokens::normalize_grid_chord_parts( $parts_raw );
					my $prev_arrow_x;
					my $prev_info;
					my $base_x = ($column - 0.5) * $cell_width;

					if ($had_leading_empty && $is_strum_row) {
						push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_rest_svg(
							x => $base_x, base_y => $base_y, font_size => $font_size);
					}

					for my $pi (0 .. $#$parts_in) {
						my $part = $parts_in->[$pi];
						my $x    = $base_x;
						if ($is_strum_row) {
							my $info = ChordPro::Output::SVG::Strum::Tokens::strum_symbol_info($part);
							if (ref($token->{holds}) eq 'ARRAY' && $token->{holds}->[$pi]) {
								$info->{hold_right} = 1;
							}
							if ($had_leading_empty && $pi == 0 && ($info->{direction}//'') ne '') {
								$x = $base_x + ($cell_width * $tight_pair_step);
							}
							elsif (defined $prev_arrow_x
								&& (($prev_info // {})->{direction} // '') ne ''
								&& (($info->{direction}//'') ne '')) {
								$x = $prev_arrow_x + ($cell_width * $tight_pair_step);
							}
							if ( $info->{rest} ) {
								push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_rest_svg(
									x => $x, base_y => $base_y, font_size => $font_size);
								$last_arrow_x = undef; $prev_arrow_x = undef;
							}
							elsif ( $info->{clap} ) {
								if (defined $pending_tie_x) {
									push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_tie_svg(
										from_x => $pending_tie_x,
										to_x   => $x,
										base_y => $base_y,
									);
									$pending_tie_x = undef;
								}
								push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_clap_svg(
									x => $x, base_y => $base_y, font_size => 14);
								$last_arrow_x = undef;
								$prev_arrow_x = undef;
								$pending_tie_x = $x if $info->{hold_right};
							}
							elsif (($info->{direction}//'') ne '') {
								if (defined $pending_tie_x) {
									push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_tie_svg(
										from_x => $pending_tie_x,
										to_x   => $x,
										base_y => $base_y,
									);
									$pending_tie_x = undef;
								}
								push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_arrow_svg(
									x => $x, base_y => $base_y,
									direction => $info->{direction}, info => $info);
								$last_arrow_x = $x; $prev_arrow_x = $x;
								$pending_tie_x = $x if $info->{hold_right};
							}
							$prev_info = $info;
						}
						else {
							my $label = ChordPro::Output::SVG::Strum::Tokens::chord_display_text($part);
							$label = '' if $label eq '.';
							if ($had_leading_empty && $pi == 0 && $label ne '') {
								$x = $base_x + ($cell_width * $tight_pair_step);
							}
							push @parts, sprintf(
								'<text x="%.2f" y="%.2f" text-anchor="middle" font-size="%d" fill="currentColor">%s</text>',
								$x, $base_y + 16, $font_size,
								ChordPro::Output::SVG::Strum::Tokens::esc($label)) if $label ne '';
						}
						$column++ unless $is_strum_row;
					}
					$column++ if $is_strum_row;
					next;
				}

				my $x = ($column - 0.5) * $cell_width;
				if ($class eq 'bar') {
					my $bar_col = $canonical_bar_columns[$bar_index] // $column;
					$x = ($bar_col - 0.5) * $cell_width;
					$bar_index++;
					my $symbol = $token->{symbol} // '|';
					my $kind   = _bar_kind($symbol);

					# Only the gridline row (or unpaired strumline if it has a bar) draws the bar
					if (!$is_paired_strumline) {
						$used_kinds{$kind} = 1;
						# For :|: emit right then left
						if ($symbol eq ':|:' || $symbol eq '}{') {
							my $kind_r = 'repeat-end';
							my $kind_l = 'repeat-start';
							$used_kinds{$kind_r} = 1;
							$used_kinds{$kind_l} = 1;
							my $ico_r = $bar_icons->{'repeat-end'};
							my $ico_l = $bar_icons->{'repeat-start'};
							my $w_r = $ico_r ? $ico_r->{width} * (20 / 100) : 6;
							my $w_l = $ico_l ? $ico_l->{width} * (20 / 100) : 6;
							push @parts, _bar_use($kind_r, $x - $w_l/2, $bar_top, $bar_bottom, $bar_icons);
							push @parts, _bar_use($kind_l, $x + $w_r/2, $bar_top, $bar_bottom, $bar_icons);
						}
						else {
							push @parts, _bar_use($kind, $x, $bar_top, $bar_bottom, $bar_icons);
						}
					}
					if ($type eq 'gridline') {
						# Avoid duplicate glyph rendering: when icon bar symbols are available,
						# do not emit legacy Unicode bar text for the same token.
						if ( !$bar_icons->{$kind} ) {
							push @parts, sprintf(
								'<text x="%.2f" y="%.2f" text-anchor="middle" font-size="6" fill="currentColor">%s</text>',
								$x, $bar_label_y,
								ChordPro::Output::SVG::Strum::Tokens::esc(
									ChordPro::Output::SVG::Strum::Tokens::bar_unicode($symbol)));
						}
						# Volta bracket: horizontal line from current bar to next bar, plus number label
						if (my $volta = $token->{volta}) {
							my $next_col = $canonical_bar_columns[$bar_index];  # bar_index already incremented
							my $bracket_end = defined($next_col)
								? ($next_col - 0.5) * $cell_width
								: $x + 2 * $cell_width;
							my $bky = $bar_top;
							push @parts, sprintf(
								'<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="currentColor" stroke-width="1"/>',
								$x, $bky, $bracket_end, $bky);
							push @parts, sprintf(
								'<text x="%.2f" y="%.2f" font-size="8" fill="currentColor" data-volta="%s">%s</text>',
								$x + 3, $bky + 9,
								ChordPro::Output::SVG::Strum::Tokens::esc($volta),
								ChordPro::Output::SVG::Strum::Tokens::esc($volta));
						}
					}
					$last_arrow_x = undef;
					# In paired |s rows, synthetic adjacent bars (e.g. leading '|' + '|:')
					# should consume a single beat column together.
					if ($is_paired_strumline) {
						$column++ unless $prev_was_bar;
					}
					else {
						$column++;
					}
					$prev_was_bar = 1;
					next;
				}
				$prev_was_bar = 0;

				if ($type eq 'gridline') {
					my $text = '';
					my $emit_text = 1;
					if ($class eq 'chord') {
						$text = ChordPro::Output::SVG::Strum::Tokens::chord_display_text($token->{chord});
					}
					elsif ($class eq 'repeat1' || $class eq 'repeat2') {
						$text = $token->{symbol} // '';
						my $left_idx = $bar_index - 1;
						$left_idx = 0 if $left_idx < 0;
						my $left_col  = $canonical_bar_columns[$left_idx] // 1;
						my $right_col = $canonical_bar_columns[$bar_index] // ($columns + 1);
						my $x_left  = ($left_col  - 0.5) * $cell_width;
						my $x_right = ($right_col - 0.5) * $cell_width;
						$x = ($x_left + $x_right) / 2;
					}
					elsif ($class eq 'slash' || $class eq 'space') {
						$text = $token->{symbol} // '';
						$emit_text = 0 if $class eq 'space' && $text eq '.';
					}
					if ($emit_text) {
						push @parts, sprintf(
							'<text x="%.2f" y="%.2f" text-anchor="middle" font-size="%d" fill="currentColor">%s</text>',
							$x, $base_y + 16, $font_size,
							ChordPro::Output::SVG::Strum::Tokens::esc($text));
					}
				}
				else {
					my $info = $class eq 'chord'
						? ChordPro::Output::SVG::Strum::Tokens::strum_symbol_info($token->{chord})
						: {};
					$info->{hold_right} = 1 if $token->{hold_right};
					if ( $info->{rest} ) {
						push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_rest_svg(
							x => $x, base_y => $base_y, font_size => $font_size);
						$last_arrow_x = undef;
					}
					elsif ( $info->{clap} ) {
						if (defined $pending_tie_x) {
							push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_tie_svg(
								from_x => $pending_tie_x,
								to_x   => $x,
								base_y => $base_y,
							);
							$pending_tie_x = undef;
						}
						push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_clap_svg(
							x => $x, base_y => $base_y, font_size => 14);
						$last_arrow_x = undef;
						$pending_tie_x = $x if $info->{hold_right};
					}
					elsif (($info->{direction}//'') ne '') {
						if (defined $pending_tie_x) {
							push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_tie_svg(
								from_x => $pending_tie_x,
								to_x   => $x,
								base_y => $base_y,
							);
							$pending_tie_x = undef;
						}
						push @parts, ChordPro::Output::SVG::Strum::SVGPrimitives::draw_arrow_svg(
							x => $x, base_y => $base_y,
							direction => $info->{direction}, info => $info);
						$last_arrow_x = $x;
						$pending_tie_x = $x if $info->{hold_right};
					}
				}
				$column++;
			}
		}

		my $defs = _bar_symbol_defs($bar_icons, \%used_kinds);
		my $unit_type = $is_pair ? 'pair' : ($unit_rows->[0]{type} // 'gridline');
		my $svg = sprintf(
			'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.2f %.2f" width="100%%" height="%.2f" aria-hidden="true" style="font-family:%s">%s%s</svg>',
			$width, $height, $height,
			ChordPro::Output::SVG::Strum::Tokens::esc($font_stack),
			$defs, join('', @parts));

		push @result_rows, {
			image  => $svg,
			width  => $width,
			height => $height,
			type   => $unit_type,
		};
	}

	return { rows => \@result_rows };
}

# ============================================================
# grid_block_svg — compatibility wrapper: monolithic SVG
# ============================================================

sub grid_block_svg( %args ) {
	my $rows = $args{rows} // [];
	my $row_height = $args{row_height} // 26;
	my $row_gap = $args{row_gap} // 6;
	my $font_size = $args{font_size} // 12;
	my $tight_pair_step = $args{tight_pair_step} // 0.55;

	# Dynamic bar width: expand cell_width when strumline rows contain sub-beat pairs.
	my $cell_width;
	if (exists $args{cell_width}) {
		$cell_width = $args{cell_width};
	}
	else {
		my $has_subbeats = 0;
		OUTER: for my $row (@$rows) {
			next unless ($row->{type} // '') eq 'strumline';
			for my $tok (@{$row->{tokens} // []}) {
				next unless ($tok->{class} // '') eq 'chords';
				my @parts = @{$tok->{chords} // []};
				my $real = grep { defined($_) && $_ ne '' } @parts;
				if ($real >= 2 || (@parts >= 2 && ($parts[0] // '') eq '')) {
					$has_subbeats = 1; last OUTER;
				}
			}
		}
		$cell_width = $has_subbeats ? 30 : 24;
	}

	my $result = render_grid(
		rows            => $rows,
		columns         => $args{columns},
		cell_width      => $cell_width,
		row_height      => $row_height,
		row_gap         => $row_gap,
		font_size       => $font_size,
		tight_pair_step => $tight_pair_step,
	);

	my $result_rows = $result->{rows};
	return '' unless @$result_rows;

	# Stitch per-unit SVGs into a monolithic SVG using nested <g translate()>
	my $total_width  = $result_rows->[0]{width};
	my $total_height = 0;
	for my $i (0 .. $#$result_rows) {
		$total_height += $result_rows->[$i]{height};
		$total_height += $row_gap if $i < $#$result_rows;
	}

	my $font_stack = ChordPro::Output::SVG::Strum::SVGPrimitives::svg_font_stack();

	# Collect unique defs and per-unit content
	my %all_defs;
	my @unit_parts;
	my $y_offset = 0;
	for my $i (0 .. $#$result_rows) {
		my $row_svg = $result_rows->[$i]{image};
		# Extract defs symbols
		while ($row_svg =~ /<symbol\s[^>]*id="([^"]+)"[^>]*>.*?<\/symbol>/gs) {
			my ($id, $full) = ($1, $&);
			$all_defs{$id} //= $full;
		}
		# Extract inner content (strip svg wrapper and defs)
		my $inner = $row_svg;
		$inner =~ s{<svg\b[^>]*>}{};
		$inner =~ s{</svg>}{};
		$inner =~ s{<defs>.*?</defs>}{}gs;
		push @unit_parts, { content => $inner, y => $y_offset, h => $result_rows->[$i]{height} };
		$y_offset += $result_rows->[$i]{height};
		$y_offset += $row_gap if $i < $#$result_rows;
	}

	my $defs_str = '';
	if (%all_defs) {
		$defs_str = '<defs>' . join('', values %all_defs) . '</defs>';
	}

	my @mono_parts;
	for my $u (@unit_parts) {
		my $content = $u->{content};
		if ($u->{y} > 0) {
			# Shift all y="N" values by the unit's y offset so the monolithic
			# SVG uses absolute coordinates (required by existing test assertions).
			my $offset = $u->{y};
			$content =~ s/\by="([\d.]+)"/sprintf('y="%.2f"', $1 + $offset)/ge;
		}
		push @mono_parts, $content;
	}

	return sprintf(
		'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.2f %.2f" width="100%%" height="%.2f" aria-hidden="true" style="font-family:%s">%s%s</svg>',
		$total_width, $total_height, $total_height,
		ChordPro::Output::SVG::Strum::Tokens::esc($font_stack),
		$defs_str, join('', @mono_parts));
}

1;

__END__
