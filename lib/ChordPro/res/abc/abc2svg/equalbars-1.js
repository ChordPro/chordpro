// equalbars.js - module to set equal spaced measure bars
//
// Copyright (C) 2018-2023 Jean-Francois Moine
//
// This file is part of abc2svg.
//
// abc2svg is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg.  If not, see <http://www.gnu.org/licenses/>.
//
// This module is loaded when "%%equalbars" appears in a ABC source.
//
// Parameters
//	%%equalbars bool

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.equalbars = {

    // new tune - clear the width of the start of the staff
    output_music: function(of) {
	this.equalbars_d = 0;
	of()
    },

    // get the equalbars parameter
   set_fmt: function(of, cmd, parm) {
	if (cmd != "equalbars") {
		of(cmd, parm)
		return
	}
    var	fmt = this.cfmt()
	fmt.equalbars = this.get_bool(parm)
	fmt.stretchlast = 1
    },

    // adjust the symbol offsets of a music line
    // only the bars of the first voice are treated
    set_sym_glue: function(of, width) {
    var	C = abc2svg.C,
	s, s2, d, w, i, n, x, g, t, t0,
	bars = [],
	tsfirst = this.get_tsfirst();

	of(width)			// compute the x offset of the symbols
	if (!this.cfmt().equalbars)
		return

	// search the first note/rest/space
	for (s2 = tsfirst; s2; s2 = s2.next) {
		switch (s2.type) {
		default:
			continue
		case C.GRACE:
		case C.MREST:
		case C.NOTE:
		case C.REST:
		case C.SPACE:
			break
		}
		break
	}
	if (!s2)
		return

	// build an array of the bars
	t0 = t = s2.time
	for (s = s2; s.next; s = s.next) {
		if (s.type == C.BAR && s.seqst && s.time != t) {
			bars.push([s, s.time - t]);
			t = s.time
		}
	}

	// push the last bar or replace it in the array
	if (s.time != t)
		bars.push([s, s.time - t])
	else
		bars[bars.length - 1][0] = s	// replace the last bar

	t = s.time
	if (s.dur)
		t += s.dur;

	n = bars.length
	if (n <= 1)
		return				// one or no bar

	// if small width, get the widest measure
	if (s.x < width) {
		w = 0
		x = 0
		for (i = 0; i < n; i++) {
			s = bars[i][0]
			if (s.x - x > w)
				w = s.x - x
			x = s.x
		}
		if (w * n < width)
			width = w * n
		this.set_realwidth(width)
	}

	// set the measure parameters
	x = s2.type == C.GRACE ? s2.extra.x : (s2.x - s2.wl)
	if (this.equalbars_d < x)
		this.equalbars_d = x		// new offset of the first note/rest

	d = this.equalbars_d
	w = (width - d) / (t - t0)		// width per time unit

	// loop on the bars
	for (i = 0; i < n; i++) {
		do {			// don't shift the 1st note from the bar
			if (s2.type == C.GRACE) {
				for (g = s2.extra; g; g = g.next)
					g.x = d + g.x - x
			} else {
				s2.x = d + s2.x - x
			}
			s2 = s2.ts_next
		} while (!s2.seqst)

		s = bars[i][0];			// next bar
		f = w * bars[i][1] / (s.x - x)

		// and update the x offsets
		for ( ; s2 != s; s2 = s2.ts_next) {
			if (s2.type == C.GRACE) {
				for (g = s2.extra; g; g = g.next)
					g.x = d + (g.x - x) * f
//			} else if (s2.x) {
			} else {
				s2.x = d + (s2.x - x) * f
			}
		}
		d += w * bars[i][1];
		x = s2.x
		while (1) {
			s2.x = d;
			s2 = s2.ts_next
			if (!s2 || s2.seqst)
				break
		}
		if (!s2)
			break
	}
    }, // set_sym_glue()

    set_hooks: function(abc) {
	abc.output_music = abc2svg.equalbars.output_music.bind(abc, abc.output_music);
	abc.set_format = abc2svg.equalbars.set_fmt.bind(abc, abc.set_format);
	abc.set_sym_glue = abc2svg.equalbars.set_sym_glue.bind(abc, abc.set_sym_glue)
    }
} // equalbars

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.equalbars = abc2svg.equalbars.set_hooks
