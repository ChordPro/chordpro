// clair.js - module to output Clairnote sheets (https:clairnote.org)
//
// Copyright (C) 2019-2023 Jean-Francois Moine
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
// This module is loaded when "%%clairnote" appears in a ABC source.
//
// Parameters (none)
//	%%clairnote 1

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.clair = {

// table for helper lines (from C, to c'')
// index = (note pitch + 16)
// value = array of line numbers / null
    hl_tb: [
	new Int8Array([-10,-8,-6,-4,-2]), // _B,, -18
	new Int8Array([-10,-9,-8,-6,-4,-2]), // B,, -17
	new Int8Array([-8,-6,-4,-2]),	// C, -16
	new Int8Array([-8,-6,-4,-2]),	// ^C, -15
	new Int8Array([-8,-7,-6,-4,-2]), // D, -14
	new Int8Array([-6,-4,-2]),	// ^D, -13
	new Int8Array([-6,-4,-2]),	// E, -12
	new Int8Array([-6,-4,-2]),	// F, -11
	new Int8Array([-6,-5,-4,-2]),	// ^F, -10
	new Int8Array([-4,-2]),		// G, -9
	new Int8Array([-4,-2]),		// ^G, -8
	new Int8Array([-4,-2]),		// A, -7
	new Int8Array([-4,-3,-2]),	// _B, -6
	new Int8Array([-2]),		// B, -5
	new Int8Array([-2]),		// C -4
	new Int8Array([-2]),		// ^C -3
	new Int8Array([-2,-1]),		// D -2
	null,				// ^D -1
	null,				// E 0
	null,				// F 1
	new Int8Array([1]),		// ^F 2
	null,				// G 3
	null,				// ^G 4
	null,				// A 5
	new Int8Array([3,4]),		// _B 6
	new Int8Array([4]),		// B 7
	new Int8Array([4]),		// c 8
	new Int8Array([4]),		// ^c 9
	new Int8Array([4,5]),		// d 10
	null,				// _e 11
	null,				// e 12
	null,				// f 13
	new Int8Array([7]),		// ^f 14
	null,				// g 15
	null,				// ^g 16
	null,				// a 17
	new Int8Array([9,10]),		// _b 18
	new Int8Array([10]),		// b 19
	new Int8Array([10]),		// c' 20
	new Int8Array([10]),		// ^c' 21
	new Int8Array([10,11]),		// d' 22
	new Int8Array([10,11]),		// _e' 23
	new Int8Array([10,12]),		// e' 24
	new Int8Array([10,12]),		// f' 25
	new Int8Array([10,12,13]),	// ^f' 26
	new Int8Array([10,12,13]),	// g' 27
	new Int8Array([10,12,14]),	// ^g' 28
	new Int8Array([10,12,14]),	// a' 29
	new Int8Array([10,12,14,15]),	// _b' 30
	new Int8Array([10,12,14,15]),	// b' 31
	new Int8Array([10,12,14,16])	// c'' 32
    ],

// draw the helper lines
    draw_hl: function(of, s) {
	if (!s.p_v.clair) {
		of(s)
		return
	}

    var	i, m, hl,
	dx = s.grace ? 4 : [4.7, 5, 6, 7.2, 7.5][s.head] * 1.4,
	p_st = this.get_staff_tb()[s.st]

	for (m = 0; m <= s.nhd; m++) {
		hl = abc2svg.clair.hl_tb[s.notes[m].pit]
		if (!hl)
			continue
		for (i = 0; i < hl.length; i++)
			this.set_hl(p_st, hl[i], s.x, -dx, dx)
	}
    }, // draw_hl()

// draw the key signature
    draw_keysig: function(of, x, s) {
	if (!s.p_v.clair) {
		of(x, s)
		return
	}

    var	i,
	staffb = this.get_staff_tb()[s.st].y,
	a_tb = new Int8Array(24),
	sc = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23],
						// major scale (2 octaves)
	bn_tb = [7, 2, -3, 4, -1, 6, 1, 8, 3, -2, 5, 0, 7, 2, -3],
						// #sf -> (major) base note
	bn = bn_tb[s.k_sf + 7]			// base note

	if (!s.k_a_acc) {
		if (s.k_sf > 0) {
			for (i = 1; i <= s.k_sf; i++) {
				a_tb[bn_tb[i] + 3] = 1;		// index = y + 3
				a_tb[bn_tb[i] + 12 + 3] = 1
			}
			if (bn + sc[s.k_mode] > 8)
				bn -= 12
			for (i = 7; --i >= 0; ) {
				y = bn + sc[s.k_mode + i]
				this.xygl(x, staffb + y * 3, (y & 1) ? "wk" : "bk");
				if (a_tb[y + 3])
					this.xygl(x,
						staffb + y * 3,
						"sht");
				switch (s.k_mode + i) {
				case 3:
				case 7:
				case 10:
					x += 4.5
					break
				}
			}
		} else {
			for (i = s.k_sf; i < 0; i++) {
				a_tb[bn_tb[i + 6] + 3] = 1;	// index = y + 3
				a_tb[bn_tb[i + 6] + 12 + 3 ] = 1
			}
			if (bn + sc[s.k_mode] > 8)
				bn -= 12
			for (i = 0; i < 7; i++) {	// down top
				y = bn + sc[s.k_mode + i]
				this.xygl(x, staffb + y * 3, (y & 1) ? "wk" : "bk");
				if (a_tb[y + 3])
					this.xygl(x,
						staffb + y * 3,
						"flt");
				switch (s.k_mode + i) {
				case 2:
				case 6:
				case 9:
					x += 4.5
					break
				}
			}
		}
	} else if (s.k_a_acc.length) {
		for (i = 0; i < s.k_a_acc.length; i++) {
		    var	acc = s.k_a_acc[i];
			j = sc[(acc.pit + 3) % 7];
			a_tb[j] = acc.acc;
			a_tb[j + 12] = acc.acc
		}
// todo
	}
    }, // draw_keysig()

// update a clef
    new_clef: function(s) {
	switch (s.clef_type) {
	case 't':
		s.clef_line = 3;
		s.clefpit = -2;
		s.clef_name = "cl4"
		break
	case 'c':
		s.clef_line = 3;
		s.clefpit = 6;
		s.clef_name = "cl3"
		break
	case 'b':
		s.clef_line = 3;
		s.clefpit = 14;
		s.clef_name = "cl2"
		break
	}
    }, // new_clef()

// function called before SVG generation
    output_music: function(of) {
    var	s, m, mp, p_v, v,
	cfmt = this.cfmt(),
	tsfirst = this.get_tsfirst(),
	voice_tb = this.get_voice_tb()

	// define the new clefs and key signatures
	// (clefs converted from clairnote.ly)
	this.do_begin_end("svg", null, '<defs>\n\
<g id="cl2">\n\
<path transform="translate(-9,-27) scale(8)" d="m0.2656 -0.78107\n\
 C0.3775 -0.79547 0.4351 -0.84567 0.7003 -0.85587\n\
 C0.9459 -0.86587 1.0531 -0.85987 1.1805 -0.83797\n\
 C1.6967 -0.74937 2.1173 -0.13032 2.1173 0.64059\n\
 C2.1173 2.10531 0.9987 3.04975 0.019 3.8078\n\
 C0 3.8345 0 3.846 0 3.8652\n\
 C0 3.9101 0.022 3.94 0.056 3.94\n\
 C0.071 3.94 0.079 3.93904 0.107 3.9231\n\
 C1.3341 3.23572 2.6095 2.2656 2.6095 0.57604\n\
 C2.6095 -0.4711 2.0006 -1.05061 1.1664 -1.05061\n\
 C0.9058 -1.05561 0.7658 -1.05861 0.5568 -1.02591\n\
 C0.4588 -1.01061 0.248 -0.97281 0.219 -0.92831\n\
 C0.165 -0.89151 0.162 -0.77308 0.266 -0.78129"/>\n\
<text x="-5" y="-24" font-size="28px">&#xe083;</text>\n\
</g>\n\
<g id="cl3">\n\
<path transform="translate(-9,-12) scale(8)" d="m1.0406 -2.93878\n\
 C0.9606 -2.93578 0.8881 -2.93178 0.8237 -2.92878\n\
 L0.8237 -2.92846\n\
 C0.6586 -2.92046 0.4659 -2.89806 0.3697 -2.87906\n\
 C0.1409 -2.83386 0.0236 -2.78916 0 -2.75937\n\
 C-0.018 -2.73927 -0.015 -2.71087 0 -2.69037\n\
 C0.023 -2.64587 0.145 -2.67017 0.4188 -2.72887\n\
 C0.5108 -2.74867 0.6924 -2.76597 0.8607 -2.77257\n\
 C1.0868 -2.78157 1.2883 -2.70417 1.3194 -2.69167\n\
 C1.7053 -2.53668 2.0444 -2.24033 2.0444 -1.46855\n\
 C2.0444 -0.8488 1.8942 -0.04261 1.4629 -0.04261\n\
 C1.4489 -0.04061 1.4419 -0.03861 1.4289 -0.02891\n\
 C1.4149 -0.01311 1.4179 -0.00091 1.4169 0.01179\n\
 C1.4169 0.01193 1.4169 0.01195 1.4169 0.01211\n\
 C1.4169 0.01225 1.4169 0.01227 1.4169 0.01243\n\
 C1.4169 0.02513 1.4169 0.03723 1.4289 0.05313\n\
 C1.4389 0.06213 1.4479 0.06493 1.4629 0.06683\n\
 C1.8942 0.06683 2.0444 0.87302 2.0444 1.49278\n\
 C2.0444 2.26455 1.7053 2.56059 1.3194 2.71559\n\
 C1.2884 2.72799 1.0868 2.80579 0.8607 2.79679\n\
 C0.6924 2.78979 0.5113 2.77259 0.4188 2.75279\n\
 C0.145 2.69409 0.0231 2.66979 0 2.71429\n\
 C-0.011 2.73479 -0.014 2.76349 0 2.78359\n\
 C0.024 2.81339 0.1409 2.85799 0.3697 2.90328\n\
 C0.4657 2.92228 0.6586 2.94468 0.8237 2.95268\n\
 L0.8237 2.953\n\
 C0.9525 2.958 1.1126 2.9714 1.305 2.96\n\
 C1.9479 2.916 2.5587 2.47655 2.5587 1.48844\n\
 C2.5587 0.89409 2.1807 0.20184 1.7065 0.01218\n\
 C2.1807 -0.17748 2.5587 -0.86972 2.5587 -1.46406\n\
 C2.5587 -2.45218 1.9479 -2.89194 1.305 -2.93594\n\
 C1.209 -2.94194 1.1207 -2.94094 1.0406 -2.93794"/>\n\
<text x="-5,-5" y="0,-24" font-size="28px">&#xe083;&#xe084;</text>\n\
</g>\n\
<g id="cl4">\n\
<path transform="translate(-9,3) scale(8)" d="m1.5506 -4.76844\n\
 C1.5376 -4.76844 1.5066 -4.75114 1.5136 -4.73384\n\
 L1.7544 -4.17292\n\
 C1.8234 -3.97367 1.8444 -3.88334 1.8444 -3.66416\n\
 C1.8444 -3.16204 1.5635 -2.76967 1.2174 -2.38312\n\
 L1.0789 -2.2278\n\
 C0.5727 -1.68982 0 -1.16441 0 -0.45906\n\
 C0 -0.36713 -0.6414 1.05 1.4549 1.05\n\
 C1.5319 1.05 1.6984 1.0492 1.8799 1.0372\n\
 C2.0139 1.0282 2.1594 0.9969 2.2732 0.9744\n\
 C2.3771 0.9538 2.5752 0.8757 2.5752 0.8757\n\
 C2.7512 0.8152 2.6612 0.62915 2.5442 0.6835\n\
 C2.5442 0.6835 2.3481 0.7626 2.2449 0.7822\n\
 C2.1355 0.803 1.9939 0.8319 1.8645 0.8382\n\
 C1.6935 0.8462 1.5257 0.8402 1.4569 0.8352\n\
 C1.1541 0.8139 0.8667 0.67432 0.6558 0.48763\n\
 C0.5148 0.36284 0.3782 0.17408 0.3582 -0.12709\n\
 C0.3582 -0.76471 0.792 -1.23147 1.255 -1.71365\n\
 L1.3978 -1.86523\n\
 C1.8046 -2.29959 2.185 -2.75829 2.185 -3.32815\n\
 C2.185 -3.77846 1.9185 -4.42204 1.6113 -4.75678\n\
 C1.5983 -4.76858 1.5713 -4.77188 1.5513 -4.76828"/>\n\
<text x="-3" y="0" font-size="28px">&#xe084;</text>\n\
</g>\n\
<ellipse id="bk" class="fill" rx="2.9" ry="2.4"/>\n\
<ellipse id="wk" class="stroke" stroke-width="1" rx="2.5" ry="2"/>\n\
<path id="flt" class="stroke" stroke-width="1.5" d="m-2.5 -1l-7 -7"/>\n\
<path id="sht" class="stroke" stroke-width="1.5" d="m-2.5 1l-7 7"/>\n\
</defs>')

	// change the pitches of all notes
	// (pitch + accidental => offset)
	for (v = 0; v < voice_tb.length; v++) {
		p_v = voice_tb[v]
		if (!p_v.clair)
			continue
		p_v.scale = 1.3;
		for (s = p_v.sym; s; s = s.next) {
			if (!s.dur)
				continue
			for (m = 0; m <= s.nhd; m++) {
				mp = s.notes[m].midi
				if (mp) {
					mp -= 46;
					s.notes[m].pit = mp
					delete s.notes[m].acc
				}
			}
		}
	}
	of()
    },

// set a format parameter
    set_fmt: function(of, cmd, param) {
	if (cmd == "clairnote") {
		if (!this.get_bool(param))
			return
		this.set_v_param("clair", true);
		this.set_v_param("stafflines", "|-|---|-|")
		this.set_v_param("staffscale", .8)
		return
	}
	of(cmd, param)
    },

// set the pitches according to the clefs
    set_pitch: function(of, last_s) {
	if (last_s) {
		of(last_s)
		return			// not the 1st time
	}
    var	p_v, s, v,
	voice_tb = this.get_voice_tb(),
	staff_tb = this.get_staff_tb()

	for (v = 0; v < voice_tb.length; v++) {
		p_v = voice_tb[v]
		if (!p_v.clair)
			continue
		abc2svg.clair.new_clef(staff_tb[p_v.st].clef)
		for (s = p_v.sym; s; s = s.next) {
			if (s.clef_type)
				abc2svg.clair.new_clef(s)
		}
	}
	of(last_s)
    },

// set the clairnote flag in the current voice
    set_vp: function(of, a) {
    var	i,
	curvoice = this.get_curvoice()

	for (i = 0; i < a.length; i++) {
		if (a[i] == "clair=") {
			curvoice.clair = a[i + 1]
			break
		}
	}
	of(a)
    },

// set the width of the clairnote key signatures
    set_width: function(of, s) {
	if (s.k_sf && s.p_v && s.p_v.clair) {
		s.wl = 8;
		s.wr = 10
	} else {
		of(s)
	}
    },

    set_hooks: function(abc) {
	abc.draw_hl = abc2svg.clair.draw_hl.bind(abc, abc.draw_hl);
	abc.draw_keysig = abc2svg.clair.draw_keysig.bind(abc, abc.draw_keysig);
	abc.output_music = abc2svg.clair.output_music.bind(abc, abc.output_music);
	abc.set_format = abc2svg.clair.set_fmt.bind(abc, abc.set_format);
	abc.set_pitch = abc2svg.clair.set_pitch.bind(abc, abc.set_pitch);
	abc.set_vp = abc2svg.clair.set_vp.bind(abc, abc.set_vp);
	abc.set_width = abc2svg.clair.set_width.bind(abc, abc.set_width)
    }
} // clair

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.clair = abc2svg.clair.set_hooks
