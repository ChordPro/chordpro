// abc2svg - abc2svg.js
//
// Copyright (C) 2014-2025 Jean-François Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

// define the abc2svg object is not yet done
if (typeof abc2svg == "undefined")
	var abc2svg = {};

// constants
abc2svg.C = {
	BLEN: 1536,

	// symbol types
	BAR: 0,
	CLEF: 1,
	CUSTOS: 2,
	SM: 3,		// sequence marker (transient)
	GRACE: 4,
	KEY: 5,
	METER: 6,
	MREST: 7,
	NOTE: 8,
	PART: 9,
	REST: 10,
	SPACE: 11,
	STAVES: 12,
	STBRK: 13,
	TEMPO: 14,
	BLOCK: 16,
	REMARK: 17,

	// note heads
	FULL: 0,
	EMPTY: 1,
	OVAL: 2,
	OVALBARS: 3,
	SQUARE: 4,

	// position types
	SL_ABOVE: 0x01,		// position (3 bits)
	SL_BELOW: 0x02,
	SL_AUTO: 0x03,
	SL_HIDDEN: 0x04,
	SL_DOTTED: 0x08,	// modifiers
	SL_ALI_MSK: 0x70,	// align
		SL_ALIGN: 0x10,
		SL_CENTER: 0x20,
		SL_CLOSE: 0x40
    };

// !! tied to the symbol types in abc2svg.js !!
abc2svg.sym_name = ['bar', 'clef', 'custos', 'smark', 'grace',
		'key', 'meter', 'Zrest', 'note', 'part',
		'rest', 'yspace', 'staves', 'Break', 'tempo',
		'', 'block', 'remark']

	// key table - index = number of accidentals + 7
abc2svg.keys = [
	new Int8Array([-1,-1,-1,-1,-1,-1,-1 ]),	// 7 flat signs
	new Int8Array([-1,-1,-1, 0,-1,-1,-1 ]),	// 6 flat signs
	new Int8Array([ 0,-1,-1, 0,-1,-1,-1 ]),	// 5 flat signs
	new Int8Array([ 0,-1,-1, 0, 0,-1,-1 ]),	// 4 flat signs
	new Int8Array([ 0, 0,-1, 0, 0,-1,-1 ]),	// 3 flat signs
	new Int8Array([ 0, 0,-1, 0, 0, 0,-1 ]),	// 2 flat signs
	new Int8Array([ 0, 0, 0, 0, 0, 0,-1 ]),	// 1 flat signs
	new Int8Array([ 0, 0, 0, 0, 0, 0, 0 ]),	// no accidental
	new Int8Array([ 0, 0, 0, 1, 0, 0, 0 ]),	// 1 sharp signs
	new Int8Array([ 1, 0, 0, 1, 0, 0, 0 ]),	// 2 sharp signs
	new Int8Array([ 1, 0, 0, 1, 1, 0, 0 ]),	// 3 sharp signs
	new Int8Array([ 1, 1, 0, 1, 1, 0, 0 ]),	// 4 sharp signs
	new Int8Array([ 1, 1, 0, 1, 1, 1, 0 ]),	// 5 sharp signs
	new Int8Array([ 1, 1, 1, 1, 1, 1, 0 ]),	// 6 sharp signs
	new Int8Array([ 1, 1, 1, 1, 1, 1, 1 ])	// 7 sharp signs
]

// base-40 representation of musical pitch
// (http://www.ccarh.org/publications/reprints/base40/)
abc2svg.p_b40 = new Int8Array(			// staff pitch to base-40
//		  C  D   E   F   G   A   B
		[ 2, 8, 14, 19, 25, 31, 37 ])
abc2svg.b40_p = new Int8Array(			// base-40 to staff pitch
//		       C		 D
		[0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1,
//	      E		     F		       G
	2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4,
//	      A			B
	5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6 ])
abc2svg.b40_a = new Int8Array(			// base-40 to accidental
//		         C		      D
		[-2, -1, 0, 1, 2, -3, -2, -1, 0, 1, 2, -3,
//		E		 F		      G
	-2, -1, 0, 1, 2, -2, -1, 0, 1, 2, -3, -2, -1, 0, 1, 2, -3,
//		A		     B
	-2, -1, 0, 1, 2, -3, -2, -1, 0, 1, 2 ])
abc2svg.b40_m = new Int8Array(			// base-40 to midi
//			 C		   D
		[-2, -1, 0, 1, 2, 0, 0, 1, 2, 3, 4, 0,
//	      E		     F		       G
	2, 3, 4, 5, 6, 3, 4, 5, 6, 7, 0, 5, 6, 7, 8, 9, 0,
//	      A			    B
	7, 8, 9, 10, 11, 0, 9, 10, 11, 12, 13 ])
abc2svg.b40l5 = new Int8Array([			// base-40 to line of fifth
//		  C			  D
	-14, -7,  0,  7, 14,  0,-12, -5,  2,  9, 16,  0,
//		  E		      F			      G	
	-10, -3,  4, 11, 18,-15, -8, -1,  6, 13,  0,-13, -6,  1,  8, 15,  0,
//		  A			  B
	-11, -4,  3, 10, 17,  0, -9, -2,  5, 12, 19 ])

abc2svg.isb40 = new Int8Array(		// interval with sharp to base-40 interval
	[0, 1, 6,7,12,17,18,23,24,29,30,35])

abc2svg.pab40 = function(p, a) {
	p += 19				// staff pitch from C-1
   var	b40 = ((p / 7) | 0) * 40 + abc2svg.p_b40[p % 7]
	if (a && a != 3)		// if some accidental, but not natural
		b40 += a
	return b40
} // pit2b40()
abc2svg.b40p = function(b) {
	return ((b / 40) | 0) * 7 + abc2svg.b40_p[b % 40] - 19
} // b40p()
abc2svg.b40a = function(b) {
	return abc2svg.b40_a[b % 40]
} // b40a()
abc2svg.b40m = function(b) {
	return ((b / 40) | 0) * 12 + abc2svg.b40_m[b % 40]
} // b40m()

// chord table
// This table is used in various modules
// to convert the types of chord symbols to a minimum set.
// More chord types may be added by the command %%chordalias.
abc2svg.ch_alias = {
	"maj": "",
	"min": "m",
	"-": "m",
	"°": "dim",
	"+": "aug",
	"+5": "aug",
	"maj7": "M7",
	"Δ7": "M7",
	"Δ": "M7",
	"min7": "m7",
	"-7": "m7",
	"ø7": "m7b5",
	"°7": "dim7",
	"min+7": "m+7",
	"aug7": "+7",
	"7+5": "+7",
	"7#5": "+7",
	"sus": "sus4",
	"7sus": "7sus4"
} // ch_alias

// global fonts
abc2svg.font_tb = []	// fonts - index = font.fid
abc2svg.font_st = {}	// font style => font_tb index for incomplete user fonts

// cache for converting a duration into [head, dots, nflags]
abc2svg.hdn = {}

// font weight
// reference:
//	https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight
abc2svg.ft_w = {
	thin: 100,
	extralight: 200,
	light: 300,
	regular: 400,
	medium:  500,
	semi: 600,
	demi: 600,
	semibold: 600,
	demibold: 600,
	bold: 700,
	extrabold: 800,
	ultrabold: 800,
	black: 900,
	heavy: 900
}
abc2svg.ft_re = new RegExp('\
-?Thin|-?Extra Light|-?Light|-?Regular|-?Medium|\
-?[DS]emi|-?[DS]emi[ -]?Bold|\
-?Bold|-?Extra[ -]?Bold|-?Ultra[ -]?Bold|-?Black|-?Heavy/',
	"i")

// lyric prefix
abc2svg.lypre = /^\d.+\.|^[\d-]+\.?|^\w+:|^\(|^\)/;

// simplify a rational number n/d
abc2svg.rat = function(n, d) {
    var	a, t,
	n0 = 0,
	d1 = 0,
	n1 = 1,
	d0 = 1
	while (1) {
		if (d == 0)
			break
		t = d
		a = (n / d) | 0
		d = n % d
		n = t
		t = n0 + a * n1
		n0 = n1
		n1 = t
		t = d0 + a * d1
		d0 = d1
		d1 = t
	}
	return [n1, d1]
} // rat()

// compare pitches
// This function is used to sort the note pitches
abc2svg.pitcmp = function(n1, n2) { return n1.pit - n2.pit }

// start of the Abc object
abc2svg.Abc = function(user) {
	"use strict";

    // constants
    var	C = abc2svg.C;

	// mask some unsafe functions
    var	require = empty_function,
	system = empty_function,
	write = empty_function,
	XMLHttpRequest = empty_function,
	std = null,
	os = null

// -- constants --

// staff system
var	OPEN_BRACE = 0x01,
	CLOSE_BRACE = 0x02,
	OPEN_BRACKET = 0x04,
	CLOSE_BRACKET = 0x08,
	OPEN_PARENTH = 0x10,
	CLOSE_PARENTH = 0x20,
	STOP_BAR = 0x40,
	FL_VOICE = 0x80,
	OPEN_BRACE2 = 0x0100,
	CLOSE_BRACE2 = 0x0200,
	OPEN_BRACKET2 = 0x0400,
	CLOSE_BRACKET2 = 0x0800,
	MASTER_VOICE = 0x1000,

	IN = 96,		// resolution 96 PPI
	CM = 37.8,		// 1 inch = 2.54 centimeter
	YSTEP			// number of steps for y offsets

// error texts
var errs = {
	bad_char: "Bad character '$1'",
	bad_grace: "Bad character in grace note sequence",
	bad_transp: "Bad transpose value",
	bad_val: "Bad value in $1",
	bar_grace: "Cannot have a bar in grace notes",
	ignored: "$1: inside tune - ignored",
	misplaced: "Misplaced '$1' in %%score",
	must_note: "!$1! must be on a note",
	must_note_rest: "!$1! must be on a note or a rest",
	nonote_vo: "No note in voice overlay",
	not_ascii: "Not an ASCII character",
	not_enough_n: 'Not enough notes/rests for %%repeat',
	not_enough_m: 'Not enough measures for %%repeat',
	not_enough_p: "Not enough parameters in %%map",
	not_in_tune: "Cannot have '$1' inside a tune",
	notransp: "Cannot transpose with a temperament"
}

    var	self = this,				// needed for modules
	glovar = {
		meter: {
			type: C.METER,		// meter in tune header
			wmeasure: 1,		// no M:
			a_meter: []		// default: none
		},
	},
	info = {},			// information fields
	parse = {
		ctx: {},
		prefix: '%',
		state: 0,
		ottava: [],
		line: new scanBuf
	},
	tunes = [],		// first time symbol and voice array per tune for playing
	psvg			// PostScript

// utilities
function clone(obj, lvl) {
	if (!obj)
		return obj
	var tmp = new obj.constructor
	for (var k in obj)
	    if (obj.hasOwnProperty(k)) {
		if (lvl && typeof obj[k] == "object")
			tmp[k] = clone(obj[k], lvl - 1)
		else
			tmp[k] = obj[k]
	    }
	return tmp
}

function errbld(sev, txt, fn, idx) {
	var i, j, l, c, h

	if (user.errbld) {
		switch (sev) {
		case 0: sev = "warn"; break
		case 1: sev = "error"; break
		default: sev= "fatal"; break
		}
		user.errbld(sev, txt, fn, idx)
		return
	}
	if (idx != undefined && idx >= 0) {
		i = l = 0
		while (1) {
			j = parse.file.indexOf('\n', i)
			if (j < 0 || j > idx)
				break
			l++;
			i = j + 1
		}
		c = idx - i
	}
	h = ""
	if (fn) {
		h = fn
		if (l)
			h += ":" + (l + 1) + ":" + (c + 1);
		h += " "
	}
	switch (sev) {
	case 0: h += "Warning: "; break
	case 1: h += "Error: "; break
	default: h += "Internal bug: "; break
	}
	user.errmsg(h + txt, l, c)
}

function error(sev, s, msg, a1, a2, a3, a4) {
	var i, j, regex, tmp

	if (sev < cfmt.quiet)
		return
	if (s) {
		if (s.err)		// only one error message per symbol
			return
		s.err = true
	}
	if (user.textrans) {
		tmp = user.textrans[msg]
		if (tmp)
			msg = tmp
	}
	if (arguments.length > 3)
		msg = msg.replace(/\$./g, function(a) {
			switch (a) {
			case '$1': return a1
			case '$2': return a2
			case '$3': return a3
			default  : return a4
			}
		})
	if (s && s.fname)
		errbld(sev, msg, s.fname, s.istart)
	else
		errbld(sev, msg)
}

// scanning functions
function scanBuf() {
//	this.buffer = buffer
	this.index = 0;

	scanBuf.prototype.char = function() {
		return this.buffer[this.index]
	}
	scanBuf.prototype.next_char = function() {
		return this.buffer[++this.index]
	}
	scanBuf.prototype.get_int = function() {
		var	val = 0,
			c = this.buffer[this.index]
		while (c >= '0' && c <= '9') {
			val = val * 10 + Number(c);
			c = this.next_char()
		}
		return val
	}
}

function syntax(sev, msg, a1, a2, a3, a4) {
    var	s = {
		fname: parse.fname,
		istart: parse.istart + parse.line.index
	}

	error(sev, s, msg, a1, a2, a3, a4)
}

// inject javascript code
function js_inject(js) {
	eval('"use strict";\n' + js)
}
// abc2svg - deco.js - decorations
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

// Decoration objects
// dd {			// decoration definition (static)
//	dd_en,			// definition of the ending decoration
//	dd_st,			// definition of the starting decoration
//	func,			// function
//	glyph,			// glyph
//	h,			// height / ascent
//	hd,			// descent
//	inv,			// inverted glyph
//	name,			// name
//	str,			// string
//	wl,			// left width
//	wr,			// right width
// }
// de {			// decoration elements (in an array - one list per music line)
//	dd,			// definition of the decoration
//	defl {			// flags
//		noen,			// no end of this decoration
//		nost,			// no start of this decoration
//	},
//	has_val,		// defined value
//	ix,			// index of the decoration in the 'de' list
//	lden,			// end of a long decoration
//	ldst,			// start of a long decoration if true
//	m,			// note index when note decoration
//	prev,			// previous decoration (hack for 'tr~~~~~')
//	s,			// symbol
//	start,			// start of the decoration (in the ending element)
//	up,			// above the symbol
//	val,			// value
//	x,			// x offset
//	y,			// y offset
// }

var	dd_tb = {},		// definition of the decorations
	a_de,			// array of the decoration elements
	cross			// cross voice decorations

// decorations - populate with standard decorations
var decos = {
	dot: "0 stc 6 .7 1",
	tenuto: "0 emb 6 4 3",
	slide: "1 sld 5,5 7 1",
	arpeggio: "2 arp 12 10 3",
	roll: "3 roll 5,4 5 6",
	lowermordent: "3 lmrd 6,5 4 6",
	uppermordent: "3 umrd 6,5 4 6",
	trill: "3 trl 14 5 8",
	upbow: "3 upb 12,2 3 7",
	downbow: "3 dnb 8,2 4 6",
	gmark: "3 grm 7 4 6",
	wedge: "0 wedge 8 1.5 1",		// (staccatissimo or spiccato)
	longphrase: "5 lphr 0 1 16",
	mediumphrase: "5 mphr 0 1 16",
	shortphrase: "5 sphr 0 1 16",
	turnx: "3 turnx 7,2.5 5 6",
	invertedturn: "3 turn 7,2 5 6",
//	"0": "3 fng 5,5 3 3 0",			// dynamic - see deco_def()
//	"1": "3 fng 5,5 3 3 1",
//	"2": "3 fng 5,5 3 3 2",
//	"3": "3 fng 5,5 3 3 3",
//	"4": "3 fng 5,5 3 3 4",
//	"5": "3 fng 5,5 3 3 5",
	plus: "3 dplus 8,2 2 4",
	"+": "3 dplus 8,2 2 4",
	">": "5 accent 3.5,3.5 4 4",
	accent: "5 accent 3.5,3.5 4 4",
	emphasis: "5 accent 3.5,3.5 4 4",
	marcato: "3 marcato 9 5 5",
	"^": "3 marcato 9 5 5",
	mordent: "3 lmrd 6,5 4 6",
	open: "3 opend 8 3 3",
	snap: "3 snap 10 3 3",
	thumb: "3 thumb 10 3 3",
	turn: "3 turn 7,2.5 5 6",
	"trill(": "5 ltr 8 0 0",
	"trill)": "5 ltr 8 0 0",
	"8va(": "5 8va 12 6 6",
	"8va)": "5 8va 12 6 6",
	"8vb(": "4 8vb 10,5 6 6",
	"8vb)": "4 8vb 10,5 6 6",
	"15ma(": "5 15ma 12 9 9",
	"15ma)": "5 15ma 12 9 9",
	"15mb(": "4 15mb 12 9 9",
	"15mb)": "4 15mb 12 9 9",
	breath: "5 brth 0 1 16",
	caesura: "5 caes 0 1 20",
	short: "5 short 0 1 16",
	tick: "5 tick 0 1 16",
	coda: "5 coda 22,5 10 10",
	dacapo: "5 dacs 16 20 20 Da Capo",
	dacoda: "5 dacs 16 20 20 Da Coda",
	"D.C.": "5 dcap 16,3 6 6",
	"D.S.": "5 dsgn 16,3 6 6",
	"D.C.alcoda": "5 dacs 16 32 32 D.C. al Coda",
	"D.S.alcoda": "5 dacs 16 32 32 D.S. al Coda",
	"D.C.alfine": "5 dacs 16 32 32 D.C. al Fine",
	"D.S.alfine": "5 dacs 16 32 32 D.S. al Fine",
	fermata: "5 hld 12 7.5 7.5",
	fine: "5 dacs 16 12 12 Fine",
	invertedfermata: "7 hld 12 8 8",
	segno: "5 sgno 22,2 5 5",
	f: "6 f 12,5 3 4",
	ff: "6 ff 12,5 8 5",
	fff: "6 fff 12,5 11 9",
	ffff: "6 ffff 12,5 15 12",
	mf: "6 mf 12,5 8 10",
	mp: "6 mp 12,5 9 10",
	p: "6 p 12,5 3 6",
	pp: "6 pp 12,5 8 9",
	ppp: "6 ppp 12,5 14 11",
	pppp: "6 pppp 12,5 14 17",
	pralltriller: "3 umrd 6,5 4 6",
	sfz: "6 sfz 12,5 9 9",
	ped: "6 ped 9 6 10",
	"ped-up": "6 pedoff 9 4 4",
	"ped(": "7 lped 14 1 1",
	"ped)": "7 lped 14 1 1",
	"crescendo(": "6 cresc 15,2 0 0",
	"crescendo)": "6 cresc 15,2 0 0",
	"<(": "6 cresc 15,2 0 0",
	"<)": "6 cresc 15,2 0 0",
	"diminuendo(": "6 dim 15,2 0 0",
	"diminuendo)": "6 dim 15,2 0 0",
	">(": "6 dim 15,2 0 0",
	">)": "6 dim 15,2 0 0",
	"-(": "8 gliss 0 0 0",
	"-)": "8 gliss 0 0 0",
	"~(": "8 glisq 0 0 0",
	"~)": "8 glisq 0 0 0",
// internal
//	color: "10 0 0 0 0",
	invisible: "32 0 0 0 0",
	beamon: "33 0 0 0 0",
	trem1: "34 0 0 0 0",
	trem2: "34 0 0 0 0",
	trem3: "34 0 0 0 0",
	trem4: "34 0 0 0 0",
	xstem: "35 0 0 0 0",
	beambr1: "36 0 0 0 0",
	beambr2: "36 0 0 0 0",
	rbstop: "37 0 0 0 0",
	"/": "38 0 0 6 6",
	"//": "38 0 0 6 6",
	"///": "38 0 0 6 6",
	"beam-accel": "39 0 0 0 0",
	"beam-rall": "39 0 0 0 0",
	stemless: "40 0 0 0 0",
	rbend: "41 0 0 0 0",
	editorial: "42 0 0 0 0",
	"sacc-1": "3 sacc-1 6,4 4 4",
	sacc3: "3 sacc3 6,5 4 4",
	sacc1: "3 sacc1 6,4 4 4",
	courtesy: "43 0 0 0 0",
	"cacc-1": "3 cacc-1 0 0 0",
	cacc3: "3 cacc3 0 0 0",
	cacc1: "3 cacc1 0 0 0",
	"tie(": "44 0 0 0 0",
	"tie)": "44 0 0 0 0",
	fg: "45 0 0 0 0"},

	// types of decoration per function
	f_near = [
		d_near,		// 0 - near the note
		d_slide,	// 1 - slide or tied to the note stem
		d_arp		// 2 - arpeggio
	],
	f_note = [
		null, null, null, null,
		d_upstaff	// 4 (below the staff)
	],
	f_staff = [
		null, null, null,
		d_upstaff,	// 3 - tied to note
		null,
		d_upstaff,	// 5 (above the staff)
		d_upstaff,	// 6 - tied to staff (dynamic marks)
		d_upstaff	// 7 (below the staff)
	]

/* -- get the max/min vertical offset -- */
function y_get(st, up, x, w) {
	var	y,
		p_staff = staff_tb[st],
	i = (x / 2) | 0,
	j = ((x + w) / 2) | 0

	if (i < 0) {
		i = 0
		if (j < 0)
			j = 0
	}
	if (j >= YSTEP) {
		j = YSTEP - 1
		if (i > j)
			i = j
	}
	if (up) {
		y = p_staff.top[i++]
		while (i <= j) {
			if (y < p_staff.top[i])
				y = p_staff.top[i];
			i++
		}
	} else {
		y = p_staff.bot[i++]
		while (i <= j) {
			if (y > p_staff.bot[i])
				y = p_staff.bot[i];
			i++
		}
	}
	return y
}

/* -- adjust the vertical offsets -- */
function y_set(st, up, x, w, y) {
    var	p_staff = staff_tb[st],
	i = (x / 2) | 0,
	j = ((x + w) / 2) | 0

	/* (may occur when annotation on 'y' at start of an empty staff) */
	if (i < 0) {
		i = 0
		if (j < 0)
			j = 0
	}
	if (j >= YSTEP) {
		j = YSTEP - 1
		if (i > j)
			i = j
	}
	if (up) {
		while (i <= j) {
			if (p_staff.top[i] < y)
				p_staff.top[i] = y;
			i++
		}
	} else {
		while (i <= j) {
			if (p_staff.bot[i] > y)
				p_staff.bot[i] = y;
			i++
		}
	}
}

// get the staff position
// - of the ornaments
function up3(s, pos) {
	switch (pos & 0x07) {
	case C.SL_ABOVE:
		return 1	// true
	case C.SL_BELOW:
		return 0	// false
	}
	return s.multi > 0 || !s.second
} // up3()

// - of the dynamic and volume marks
function up6(s, pos) {
	switch (pos & 0x07) {
	case C.SL_ABOVE:
		return true
	case C.SL_BELOW:
		return false
	}
	if (s.multi)
		return s.multi > 0
	if (!s.p_v.have_ly)
		return false

	/* above if the lyrics are below the staff */
	return (s.pos.voc & 0x07) != C.SL_ABOVE
}

/* -- drawing functions -- */
/* 2: special case for arpeggio */
function d_arp(de) {
	var	m, h, dx,
		s = de.s,
		dd = de.dd,
		xc = dd.wr

	if (s.type == C.NOTE) {
		for (m = 0; m <= s.nhd; m++) {
			if (s.notes[m].acc) {
				dx = s.notes[m].shac
			} else {
				dx = 1 - s.notes[m].shhd
				switch (s.head) {
				case C.SQUARE:
					dx += 3.5
					break
				case C.OVALBARS:
				case C.OVAL:
					dx += 2
					break
				}
			}
			if (dx > xc)
				xc = dx
		}
	}
	h = 3 * (s.notes[s.nhd].pit - s.notes[0].pit) + 4;
	m = dd.h			/* minimum height */
	if (h < m)
		h = m;

	de.has_val = true;
	de.val = h;
//	de.x = s.x - xc;
	de.x -= xc;
	de.y = 3 * ((s.notes[0].pit + s.notes[s.nhd].pit) / 2 - 18) - h / 2 - 3
}

/* 0: near the note (dot, tenuto) */
function d_near(de) {
	var	y,
		up = de.up,
		s = de.s,
		dd = de.dd

	y = up ? s.ymx : s.ymn
	if (y > 0 && y < 24) {
		y = (((y + 9) / 6) | 0) * 6 - 6	// between lines
	}
	if (up) {
		if (s.ys > 27
		 && dd.name[0] == 'd'		// if dot (staccato)
		 && s.a_dd[0].name == "dot"	// as the first decoration
		 && s.stem > 0 && s.nflags >= 0
		 && s.beam_st && s.beam_end)
			y -= 6			// put the dot a bit lower
		else
			y += dd.hd
		if (s.ymx < y + dd.h)
			s.ymx = y + dd.h
	} else if (dd.name[0] == 'w') {		// wedge (no descent)
		de.inv = true
		y -= dd.h
		s.ymn = y
	} else {
		y -= dd.h
		s.ymn = y - dd.hd
	}
	de.x -= dd.wl
	de.y = y
	if (s.type == C.NOTE)
		de.x += s.notes[s.stem >= 0 ? 0 : s.nhd].shhd
}

/* 1: special case for slide */
function d_slide(de) {
    var	m, dx, xc, yc,
	s = de.s

	if (s.decstm != null) {			// decoration tied to the stem
		if (de.s.stem >= 0) {
			if (s.nflags >= -1) {
				xc = 3.5
				yc = s.ys
				if (s.nflags > 1)
					yc -= 4 * (s.nflags - 1)
			} else {
				xc = 0
				yc = s.y + 21
			}
			de.y = (yc + 3 * (s.notes[s.nhd].pit - 18)) / 2
		} else {
			de.rotpi = 1//true	// rotate pi (180°)
			if (s.nflags >= -1) {
				xc = -3.5
				yc = s.ys
				if (s.nflags > 1)
					yc += 4 * (s.nflags - 1)
			} else {
				xc = 0
				yc = s.y - 21
			}
			de.y = (yc + 3 * (s.notes[0].pit - 18)) / 2
		}
	} else {
		xc = -5
		de.y = 3 * (s.notes[0].pit - 18)
		if (de.dd.glyph == "sld") {		// !slide!
			xc = -10
			for (m = 0; m <= s.nhd; m++) {
				if (s.notes[m].acc) {
					dx = -7 - s.notes[m].shac
				} else {
					dx = -10 + s.notes[m].shhd
					switch (s.head) {
					case C.SQUARE:
						dx -= 3.5
						break
					case C.OVALBARS:
					case C.OVAL:
						dx -= 2
						break
					}
				}
				if (dx < xc)
					xc = dx
			}
		}
	}
	de.x += xc

	if (de.y < 0)
		y_set(s.st, 0, de.x, de.dd.wl, de.y - de.dd.h)
}

// special case for long decoration
function d_trill(de) {
	if (de.ldst)
		return
    var	y, w, tmp,
	dd = de.dd,
	de2 = de.prev,
	up = de.start.up,
		s2 = de.s,
		st = s2.st,
		s = de.start.s,
		x = s.x

	// shift the starting point of a long decoration
	// in the cases "T!trill(!" and "!pp!!<(!"
	// (side effect on x)
	function sh_st() {
	    var	de3,
		de2 = de.start,			// start of the decoration
		s = de2.s,
		i = de2.ix			// index of the current decoration

		while (--i >= 0) {
			de3 = a_de[i]
			if (!de3 || de3.s != s)
				break
		}
		while (1) {			// loop on the decorations of the symbol
			i++
			de3 = a_de[i]
			if (!de3 || de3.s != s)
				break
			if (de3 == de2)
				continue
			if (!(up ^ de3.up)
			 && (de3.dd.name == "trill"
			  || de3.dd.func == 6)) {	// dynamic
				x += de3.dd.wr + 2
				break
			}
		}
	} // sh_st()

	// shift the ending point of a long decoration
	// (side effect on w)
	function sh_en() {
	    var	de3,
		i = de.ix			// index of the current decoration

		while (--i > 0) {
			de3 = a_de[i]
			if (!de3 || de3.s != s2)
				break
		}
		while (1) {			// loop on the decorations of the symbol
			i++
			de3 = a_de[i]
			if (!de3 || de3.s != s2)
				break
//			if (de3 == de || de3 == de2)
			if (de3 == de)
				continue
			if (!(up ^ de3.up)
			 && de3.dd.func == 6) {	// if dynamic mark
				w -= de3.dd.wl
				break
			}
		}
	} //sh_en()

	// d_trill()
	if (de2) {			// same height
		x = de2.s.x + de.dd.wl + 2
		de2.val -= de2.dd.wr
		if (de2.val < 8)
			de2.val = 8
	}
	de.st = st
	de.up = up

	sh_st()				// shift the starting point?

	if (de.defl.noen) {		/* if no decoration end */
		w = de.x - x
		if (w < 20) {
			x = de.x - 20 - 3;
			w = 20
		}
	} else {
		w = s2.x - x - 4
		sh_en(de)		// shift the ending point?
		if (w < 20)
			w = 20
	}
	y = y_get(st, up, x - dd.wl, w)
	if (up) {
		tmp = staff_tb[s.st].topbar + 2
		if (y < tmp)
			y = tmp
	} else {
		tmp = staff_tb[s.st].botbar - 2
		if (y > tmp)
			y = tmp
		y -= dd.h
	}
	if (de2) {			// if same height
		if (up) {
			if (y < de2.y)
				y = de2.y	// (only on one note)
		} else {
			if (y >= de2.y) {
				y = de2.y
			} else {
				do {
					de2.y = y
					de2 = de2.prev	// go backwards
				} while (de2)
			}
		}
	}

	de.lden = false;
	de.has_val = true;
	de.val = w;
	de.x = x;
	de.y = y
	if (up)
		y += dd.h;
	else
		y -= dd.hd
	y_set(st, up, x, w, y)
	if (up)
		s.ymx = s2.ymx = y
	else
		s.ymn = s2.ymn = y
}

/* 3, 4, 5, 7: above (or below) the staff */
function d_upstaff(de) {

	// don't treat here the long decorations
	if (de.ldst)			// if long deco start
		return
	if (de.start) {			// if long decoration
		d_trill(de)
		return
	}

    var	y, inv,
	up = de.up,
	s = de.s,
	dd = de.dd,
	x = de.x,
	w = dd.wl + dd.wr

	// glyphs inside the staff
	switch (dd.glyph) {
	case "lphr":
	case "mphr":
	case "sphr":
	case "short":
	case "tick":
		if (s.type == C.BAR)
			s.invis = 1
		// fall thru
	case "brth":
	case "caes":
		y = staff_tb[s.st].topbar + 2 + dd.hd
		if (!s.invis) {
			if (dd.glyph == "brth" && y < s.ymx)
				y = s.ymx
			for (s = s.ts_next; s; s = s.ts_next)
				if (s.seqst)
					break
			x += ((s ? s.x : realwidth) - x) * .45
		}
		de.x = x
		de.y = y
		return
	}

	if (s.nhd)
		x += s.notes[s.stem >= 0 ? 0 : s.nhd].shhd;

	switch (dd.ty) {
	case '@':
	case '<':
	case '>':
		y = de.y
		break
	}
	if (y == undefined) {
		if (up) {
			y = y_get(s.st, true, x - dd.wl, w)
					+ dd.hd
			if (de.y > y)
				y = de.y
			s.ymx = y + dd.h
		} else {
			y = y_get(s.st, false, x - dd.wl, w)
				- dd.h
			if (de.y < y)
				y = de.y
			if (dd.name == "fermata"
			 || dd.glyph == "accent"
			 || dd.glyph == "roll")
				de.inv = 1
			s.ymn = y - dd.hd
		}
	}

	if (dd.wr > 5 && x > realwidth - dd.wr)
		de.x = x = realwidth - dd.wr

//    if (dd.func == 6
//     && ((de.pos & C.SL_ALI_MSK) == C.SL_ALIGN
//      || ((de.pos & C.SL_ALI_MSK) == 0
//       && de.s.fmt.dynalign > 0)))	// if align
//	;
//    else
	if (up)
		y_set(s.st, 1, x - dd.wl, w, y + dd.h)
	else
		y_set(s.st, 0, x - dd.wl, w, y - dd.hd)

	de.y = y
}

// add a decoration
/* syntax:
 *	%%deco <name> <c_func> <glyph> <h> <wl> <wr> [<str>]
 * "<h>" may be followed by ",<hd>" (descent)
 */
function deco_add(param) {
	var dv = param.match(/(\S*)\s+(.*)/);
	decos[dv[1]] = dv[2]
}

// define a decoration
// nm is the name of the decoration
// nmd is the name of the definition in the table 'decos'
function deco_def(nm, nmd) {
	if (!nmd)
		nmd = nm
    var a, dd, dd2, nm2, c, i, elts, str, hd,
	text = decos[nmd]

	// check if a long decoration with number
	if (!text) {
		if (/\d[()]$/.test(nmd))
			text = decos[nmd.replace(/\d/, '')]
		else if (/^\d$/.test(nmd))	// or some fingering/string number
			text = "3 fng 5,5 3 3 " + nmd
	}
	if (!text) {
		if (cfmt.decoerr)
			error(1, null, "Unknown decoration '$1'", nm)
		return //undefined
	}

	// extract the values
	a = text.match(/(\d+)\s+(.+?)\s+([0-9.,]+)\s+([0-9.]+)\s+([0-9.]+)/)
	if (!a) {
		error(1, null, "Invalid decoration '$1'", nm)
		return //undefined
	}
	var	c_func = Number(a[1]),
//		glyph = a[2],
		h = a[3],
		wl = parseFloat(a[4]),
		wr = parseFloat(a[5])

	if (isNaN(c_func)) {
		error(1, null, "%%deco: bad C function value '$1'", a[1])
		return //undefined
	}
	if (c_func > 10
	 && (c_func < 32 || c_func > 45)) {
		error(1, null, "%%deco: bad C function index '$1'", c_func)
		return //undefined
	}
//	if (c_func == 5)			// old !trill(!
//		c_func = 3
//	if (c_func == 7)			// old !cresc(!
//		c_func = 6

	if (h.indexOf(',') > 0) {
		h = h.split(',')
		hd = h[1]
		h = h[0]
	} else {
		hd = 0
	}
	if (h > 50 || wl > 80 || wr > 80) {
		error(1, null, "%%deco: abnormal h/wl/wr value '$1'", text)
		return //undefined
	}

	// create/redefine the decoration
	dd = dd_tb[nm]
	if (!dd) {
		dd = {
			name: nm
		}
		dd_tb[nm] = dd
	}

	/* set the values */
	dd.func = nm.indexOf("head-") == 0 ? 9 : c_func;
	dd.glyph = a[2];
	dd.h = Number(h)
	dd.hd = Number(hd)
	dd.wl = wl;
	dd.wr = wr;
	str = text.replace(a[0], '').trim()
	if (str) {				// optional string
		if (str[0] == '"')
			str = str.slice(1, -1);
		if (str[0] == '@') {
			c = str.match(/^@([0-9.-]+),([0-9.-]+);?/)
		    if (!c) {
			error(1, null, "%%deco: bad position '$1'", str)
			return
		    }
			dd.dx = +c[1]		// x and y offsets
			dd.dy = +c[2]
			str = str.replace(c[0], '')
		}
		dd.str = str
	}

	/* compatibility */
	if (dd.func == 6 && dd.str == undefined)
		dd.str = nm

	// link the start and end of long decorations
	c = nm.slice(-1)
	if (c == '(' ||
	    (c == ')' && nm.indexOf('(') < 0)) {	// not (#)
		dd.str = null;			// (no string)
		nm2 = nm.slice(0, -1) + (c == '(' ? ')' : '(');
		dd2 = dd_tb[nm2]
		if (dd2) {
			if (c == '(') {
				dd.dd_en = dd2;
				dd2.dd_st = dd
			} else {
				dd.dd_st = dd2;
				dd2.dd_en = dd
			}
		}
	}
	return dd
}

// define a cross-voice tie
// @nm = decoration name
// @s = note symbol
// @nt1 = note
function do_ctie(nm, s, nt1) {
    var	nt2 = cross[nm],
	nm2 = nm.slice(0, -1) + (nm.slice(-1) == '(' ? ')' : '(')

	if (nt2) {
		error(1, s, "Conflict on !$1!", nm)
		return
	}
	if (nt1.tie_ty)			// if normal '-'
		curvoice.tie_s = null

	nt1.s = s
	nt2 = cross[nm2]
	if (!nt2) {
		cross[nm] = nt1		// keep the start/end
		return
	}
	if (nm.slice(-1) == ')') {
		nt2 = nt1
		nt1 = cross[nm2]
	}
	cross[nm2] = null
	if (nt1.midi != nt2.midi
	 || nt1.s.time + nt1.dur != nt2.s.time) {
		error(1, s, "Bad tie")
	} else {
		if (!nt1.tie_ty)		// if not normal '-'
			nt1.tie_ty = C.SL_AUTO
		nt1.tie_e = nt2
		nt2.tie_s = nt1
		nt1.s.ti1 = nt2.s.ti2 = true
	}
} // do_ctie()

// get/create the definition of a decoration
function get_dd(nm) {
    var	ty, p,
	dd = dd_tb[nm]

	if (dd)
		return dd
	if ("<>^_@".indexOf(nm[0]) >= 0	// if position
	 && !/^([>^]|[<>]\d?[()])$/.test(nm)) {
		ty = nm[0]
		if (ty == '@') {
			p = nm.match(/@([-\d]+),([-\d]+)/)
			if (p)
				ty = p[0]
			else
				ty = ''		// accept decorations starting with '@'
		}
		dd = deco_def(nm, nm.replace(ty, ''))
	} else {
		dd = deco_def(nm)
	}
	if (!dd)
		return
	if (ty) {
		if (ty[0] == '@') {		// if with x,y
			dd.x = Number(p[1])
			dd.y = Number(p[2])
			ty = '@'
		}
		dd.ty = ty
	}
	return dd
} // get_dd()

/* -- convert the decorations -- */
function deco_cnv(s, prev) {
    var	i, j, dd, nm, note, s1, court, fg

	// mark a finger glissando
	function sav_fg() {
	    var	i,
		s1 = prev

		if (s.type != C.NOTE)
			return 1
		while (s1 && s1.type != C.NOTE)
			s1 = s1.prev
		if (!s1)
			return 1
		for (i = 0; i < s1.a_dd.length; i++) {
			if (s1.a_dd[i].name == dd.name) {
				if (!s.fg)
					s.fg = []
				s.fg.push({
					ty: 1,		// end of glissando
					s: s1,
					nm: dd.name
				})
				if (!s1.fg)
					s1.fg = []
				s1.fg.push({
					ty: 0,		// start of glissando
					s: s,
					nm: dd.name
				})
				return 0
			}
		}
		return 1
	} // sav_fg()

	while (1) {
		nm = a_dcn.shift()
		if (!nm)
			break
		dd = get_dd(nm)
		if (!dd)
			continue

		/* special decorations */
		switch (dd.func) {
		case 0:			// near
			if (s.type == C.BAR && nm == "dot") {
				s.bar_dotted = true
				continue
			}
			// fall thru
		case 1:			// slide & deco on stem
			if (dd.glyph[0] == '|')
				s.decstm = dd.h		// deco on stem
			// fall thru
		case 2:			// arp
//			if (s.type != C.NOTE && s.type != C.REST) {
			if (!s.notes) {
				error(1, s, errs.must_note_rest, nm)
				continue
			}
			break
		case 3:
			if (fg && dd.glyph == "fng") { // move the fingers out of staves
				for (i = 0; i <= 5; i++) {
					decos[i.toString()] = "5 fng 5,5 3 3 " + i
					if (dd_tb[i.toString()])
						dd_tb[i.toString()].func = 5
				}
			}
			break
		case 4:			// below the staff
		case 5:			// above the staff
			i = nm.match(/1?[85]([vm])([ab])([()])/)
			if (i) {				// if ottava
				j = i[1] == 'v' ? 1 : 2
				if (i[2] == 'b')
					j = -j
				if (!s.ottava)
					s.ottava = []
				s.ottava[i[3] == '(' ? 0 : 1] = j
				glovar.ottava = 1 //true
			}
			break
		case 8:			// gliss
			if (s.type != C.NOTE) {
				error(1, s, errs.must_note, nm)
				continue
			}
			note = s.notes[s.nhd] // move to the upper note of the chord
			if (!note.a_dd)
				note.a_dd = []
			note.a_dd.push(dd)
			continue
		case 9:			// alternate head
			if (!s.notes) {
				error(1, s, errs.must_note_rest, nm)
				continue
			}

			// move the alternate head of the chord to the notes
			for (j = 0; j <= s.nhd; j++) {
				note = s.notes[j]
				note.invis = true
				if (!note.a_dd)
					note.a_dd = []
				note.a_dd.push(dd)
			}
			continue
		case 10:		/* color */
			if (s.notes) {
				for (j = 0; j <= s.nhd; j++)
					s.notes[j].color = nm
			} else {
				s.color = nm
			}
			break
		case 32:		/* invisible */
			s.invis = true
			break
		case 33:		/* beamon */
			if (s.type != C.BAR) {
				error(1, s, "!beamon! must be on a bar")
				continue
			}
			s.beam_on = true
			break
		case 34:		/* trem1..trem4 */
			if (s.type != C.NOTE
			 || !prev
			 || prev.type != C.NOTE
			 || s.dur != prev.dur) {
				error(1, s,
					"!$1! must be on the last of a couple of notes",
					nm)
				continue
			}
			s.trem2 = true;
			s.beam_end = true;
			s.beam_st = false;
			prev.beam_st = true;
			prev.beam_end = false;
			s.ntrem = prev.ntrem = Number(nm[4]);
			for (j = 0; j <= s.nhd; j++)
				s.notes[j].dur *= 2;
			for (j = 0; j <= prev.nhd; j++)
				prev.notes[j].dur *= 2
			break
		case 35:		/* xstem */
			if (s.type != C.NOTE) {
				error(1, s, errs.must_note, nm)
				continue
			}
			s.xstem = true;
			break
		case 36:		/* beambr1 / beambr2 */
			if (s.type != C.NOTE) {
				error(1, s, errs.must_note, nm)
				continue
			}
			if (nm[6] == '1')
				s.beam_br1 = true
			else
				s.beam_br2 = true
			break
		case 37:		/* rbstop */
			s.rbstop = 1	// open
			break
		case 38:		/* /, // and /// = tremolo */
			if (s.type != C.NOTE) {
				error(1, s, errs.must_note, nm)
				continue
			}
			s.trem1 = true;
			s.ntrem = nm.length	/* 1, 2 or 3 */
			break
		case 39:		/* beam-accel/beam-rall */
			if (s.type != C.NOTE) {
				error(1, s, errs.must_note, nm)
				continue
			}
			s.feathered_beam = nm[5] == 'a' ? 1 : -1;
			break
		case 40:		/* stemless */
			s.stemless = true
			break
		case 41:		/* rbend */
			s.rbstop = 2	// with end
			break
		case 42:		// editorial
			if (s.type != C.NOTE) {
				error(1, s, errs.must_note, nm)
				continue
			}
			if (!s.notes[0].acc)
				continue
			nm = "sacc" + s.notes[0].acc.toString() // small accidental
			dd = dd_tb[nm]
			if (!dd) {
				dd = deco_def(nm)
				if (!dd) {
					error(1, s, errs.bad_val, "!editorial!")
					continue
				}
			}
			delete s.notes[0].acc
			curvoice.acc[s.notes[0].pit + 19] = 0	// ignore the accidental
			break
		case 43:		// courtesy
			if (s.type != C.NOTE) {
				error(1, s, errs.must_note, nm)
				continue
			}
			j = curvoice.acc[s.notes[0].pit + 19]
			if (s.notes[0].acc || !j)
				continue
			court = 1			// defer
			break
		case 44:		// cross-voice ties
			if (s.type != C.NOTE) {
				error(1, s, errs.must_note, nm)
				continue
			}
			do_ctie(nm, s, s.notes[0])	// (only one note for now)
			continue
		case 45:		// finger glissando
			fg = 1 //true
			continue
//		default:
//			break
		}

		// handle the fingering in case finger glissando
		if (fg && dd.glyph == 'fng') {
			fg = 0 //false
			if (sav_fg()) {
				error(1, s,
					"!$1! must be on the last of a couple of notes",
					nm)
				continue
			}
		}

		// add the decoration in the symbol
		if (!s.a_dd)
			s.a_dd = []
		s.a_dd.push(dd)
	}
	// handle the possible courtesy accidental
	if (court) {
		a_dcn.push("cacc" + j)
		dh_cnv(s, s.notes[0])
	}
}

// -- convert head decorations --
// The decorations are in the global array a_dcn
function dh_cnv(s, nt) {
    var	k, nm, dd

	while (1) {
		nm = a_dcn.shift()
		if (!nm)
			break
		dd = get_dd(nm)
		if (!dd)
			continue

		switch (dd.func) {
		case 1:			// slide
		case 3:
		case 8:			// gliss
			break
		default:
			error(1, s, "Cannot have !$1! on a head", nm)
			continue
		case 9:			// head replacement
			nt.invis = true
			break
		case 32:		// invisible
			nt.invis = true
			continue
		case 10:		// color
			nt.color = nm
			continue
		case 40:		// stemless chord (abcm2ps behaviour)
			s.stemless = true
			continue
		case 44:		// cross-voice ties
			do_ctie(nm, s, nt)
			continue
		}

		// add the decoration in the note
		if (!nt.a_dd)
			nt.a_dd = []
		nt.a_dd.push(dd)
	}
} // dh_cnv()

/* -- update the x position of a decoration -- */
// used to center the rests
function deco_update(s, dx) {
	var	i, de,
		nd = a_de.length

	for (i = 0; i < nd; i++) {
		de = a_de[i]
		if (de.s == s)
			de.x += dx
	}
}

/* -- adjust the symbol width -- */
function deco_width(s, wlnt) {
    var	dd, i, w,
	wl = wlnt,
	wr = s.wr,
		a_dd = s.a_dd,
		nd = a_dd.length

	for (i = 0; i < nd; i++) {
		dd =  a_dd[i]
		switch (dd.func) {
		case 1:			/* slide */
		case 2:			/* arpeggio */
			if (wl < 12)
				wl = 12
			break
		case 3:
			switch (dd.glyph) {
			case "brth":
			case "lphr":
			case "mphr":
			case "sphr":
				if (s.wr < 20)
					s.wr = 20
				break
			default:
				w = dd.wl + 2
				if (wl < w)
					wl = w
				break
			}
			// fall thru
		default:
			switch (dd.ty) {
			case '<':
				w = wlnt + dd.wl + dd.wr + 6
				if (wl < w)
					wl = w
				break
			case '>':
				w = wr + dd.wl + dd.wr + 6
				if (s.wr < w)
					s.wr = w
				break
			}
			break
		}
	}
	return wl
}

// compute the width of decorations in chord
function deco_wch(nt) {
    var	i, w, dd,
	wl = 0,
	n = nt.a_dd.length

	for (i = 0; i < n; i++) {
		dd = nt.a_dd[i]
		w = dd.wl + dd.wr
		if (nt.shac)
			w += nt.shac
		if (w > wl)
			wl = w
	}
	return wl
} // deco_wch()

/* -- draw the decorations -- */
/* (the staves are defined) */
Abc.prototype.draw_all_deco = function() {
	if (!a_de.length)
		return
	var	de, dd, s, note, f, st, x, y, y2, ym, uf, i, str, a,
		new_de = [],
		ymid = []

	// display a finger glissando
	function out_fg() {
	    var	k, l, de2, fg, fg2, x2,
		j = s.fg.length

		while (--j >= 0) {
			fg = s.fg[j]
			if (fg.nm == dd.name)
				break
		}
		if (j < 0)
			return

		if (fg.ty) {		// end
			if (fg.ty == 1)		// no start (not treated yet)
				out_wln(x - 19, y, 12)
			return
		}

		x2 = x + 7		// start
		for (k = 0; k < a_de.length; k++) {
			de2 = a_de[k]
			if (de2.s != fg.s
			 || de2.dd.name != dd.name)
				continue
			for (l = 0; l < de2.s.fg.length; l++) {
				fg2 = de2.s.fg[l]
				if (fg2.nm == fg.nm)
					break
			}
			if (fg2.nm == fg.nm) {		// if same finger
				fg2.ty = 2		// end done
				xypath(x2, y + 1)
				output += 'l' + (de2.x - 7 - x2).toFixed(1)
					+ ' ' + (y - de2.y
						- staff_tb[s.st].y).toFixed(1)
					+ '" stroke-width=".7"/>\n'
				return
			}
		}
		out_wln(x2, y, 12)	// start without end
	} // out_fg()

		st = nstaff;
		y = staff_tb[st].y
		while (--st >= 0) {
			y2 = staff_tb[st].y;
			ymid[st] = (y + 24 + y2) * .5;
			y = y2
		}

	while (1) {
		de = a_de.shift()
		if (!de)
			break
		dd = de.dd
		if (!dd)
			continue		// deleted

		if (dd.dd_en)			// start of long decoration
			continue

		// handle the stem direction
		s = de.s
		f = dd.glyph;
		i = f.indexOf('/')
		if (i > 0) {
			if (s.stem >= 0)
				f = f.slice(0, i)
			else
				f = f.slice(i + 1)
		}

		// no voice scale if staff decoration
		if (f_staff[dd.func])
			set_sscale(s.st)
		else
			set_scale(s);

		st = de.st;
		if (!staff_tb[st].topbar)
			continue		// invisible staff
		x = de.x + (dd.dx || 0)
		y = de.y + staff_tb[st].y + (dd.dy || 0)

		/* center the dynamic marks between two staves */
/*fixme: KO when deco on other voice and same direction*/
		if (dd.func == 6
			&& ((de.pos & C.SL_ALI_MSK) == C.SL_CENTER
			 || ((de.pos & C.SL_ALI_MSK) == 0
			  && !s.fmt.dynalign))
			&& ((de.up && st > 0)
			 || (!de.up && st < nstaff))) {
			if (de.up)
				ym = ymid[--st]
			else
				ym = ymid[st++];
			ym -= dd.h * .5
			if ((de.up && y < ym)
			 || (!de.up && y > ym)) {
//				if (s.st > st) {
//					while (s.st != st)
//						s = s.ts_prev
//				} else if (s.st < st) {
//					while (s.st != st)
//						s = s.ts_next
//				}
				y2 = y_get(st, !de.up, de.x, de.val)
					+ staff_tb[st].y
				if (de.up)
					y2 -= dd.h
//fixme: y_set is not used later!
				if ((de.up && y2 > ym)
				 || (!de.up && y2 < ym)) {
					y = ym;
//					y_set(st, de.up, de.x, de.val,
//						(de.up ? y + dd.h : y)
//							- staff_tb[st].y)
					if (stv_g.scale != 1)
						y += stv_g.dy / 2
				}
			}
		}

		// check if user JS decoration
		if (user.deco) {
			uf = user.deco[f]
			if (uf && typeof(uf) == "function") {
				uf.call(self, x, y, de)
				continue
			}
		}

		// check if user PS definition
		if (self.psdeco(x, y, de))
			continue

		anno_start(s, 'deco')
//		if (de.flags.grace) {
//			g_open(x, y, 0, .7, de.inv ? -.7 : 0);
//			x = y = 0
//		} else
		if (de.inv) {
			y = y + dd.h - dd.hd
			g_open(x, y, 0, 1, -1);
			x = y = 0
		} else if (de.rotpi) {
			g_open(x, y, 180)
			x = y = 0
		}
		if (de.has_val) {
			if (dd.func != 2	// if not !arpeggio!
			 || stv_g.st < 0)	// or not staff scale
// || voice_tb[s.v].scale != 1)
				out_deco_val(x, y, f, de.val / stv_g.scale, de.defl)
			else
				out_deco_val(x, y, f, de.val, de.defl)
			if (de.cont)
				new_de.push(de.start)	// to be continued next line
		} else if (dd.str != undefined		// string
			&& !tgls[dd.glyph]
			&& !glyphs[dd.glyph]) {		// with a class
			if (s.fg)			// if finger glissando
				out_fg()		// (may change y)
			out_deco_str(x, y,		// - dd.h * .2,
					de)
		} else if (de.lden) {
			out_deco_long(x, y, de)
		} else {
			xygl(x, y, f)
		}
		if (stv_g.g)
			g_close();
		anno_stop(s, 'deco')
	}

	// keep the long decorations which continue on the next line
	a_de = new_de
}

/* -- create the decorations and define the ones near the notes -- */
/* (the staves are not yet defined) */
/* (delayed output) */
/* this function must be called first as it builds the deco element table */
function draw_deco_near() {
    var	s, g

	// update starting old decorations
	function ldeco_update(s) {
		var	i, de,
//			x = s.ts_prev.x + s.ts_prev.wr
			x = s.x - s.wl,
			nd = a_de.length

		for (i = 0; i < nd; i++) {
			de = a_de[i];
			de.ix = i;
			de.s.x = de.x = x;
			de.defl.nost = true
		}
	}

	/* -- create the deco elements, and treat the near ones -- */
	function create_deco(s) {
	    var	dd, k, pos, de, x, y, up,
		nd = s.a_dd.length

		if (s.y == undefined)
			s.y = 0			// (no y in measure bars)

/*fixme:pb with decorations above the staff*/
		for (k = 0; k < nd; k++) {
			dd = s.a_dd[k]

			// adjust the position
			x = s.x
			y = s.y
			switch (dd.func) {
			default:
				if (dd.func >= 10)
					continue
				pos = 0
				break
			case 3:				/* d_upstaff */
			case 4:
			case 5:				// after slurs
				pos = s.pos.orn
				break
			case 6:				/* dynamic */
				pos = s.pos.dyn
				break
			}

			switch (dd.ty) {		// explicit position
			case '^':
				pos = (pos & ~0x07) | C.SL_ABOVE
				break
			case '_':
				pos = (pos & ~0x07) | C.SL_BELOW
				break
			case '<':
			case '>':
				pos = (pos & 0x07) | C.SL_CLOSE
				if (dd.ty == '<') {
					x -= dd.wr + 8
					if (s.notes[0].acc)
						x -= 8
				} else {
					x += dd.wl + 8
				}
				y = 3 * (s.notes[0].pit - 18)
						- (dd.h - dd.hd) / 2
				break
			case '@':
				x += dd.x
				y += dd.y
				break
			}

			if ((pos & 0x07) == C.SL_HIDDEN)
				continue

			de = {
				s: s,
				dd: dd,
				st: s.st,
				ix: a_de.length,
				defl: {},
				x: x,
				y: y
			}
			if (pos)
				de.pos = pos

			up = 0 //false
			if (dd.ty == '^') {
				up = 1 //true
			} else if (dd.ty == '_') {
				;
			} else {
				switch (dd.func) {
				case 0:
					if (s.multi)
						up = s.multi > 0
					else
						up = s.stem < 0
					break
				case 3:
				case 5:
					up = up3(s, pos)
					break
				case 6:
					up = up6(s, pos)
					break
				}
			}
			de.up = up

			if (dd.name.indexOf("inverted") >= 0)
				de.inv = 1
			if (s.type == C.BAR && !dd.ty)
				de.x -= s.wl / 2 - 2
			a_de.push(de)
			if (dd.dd_en) {
				de.ldst = true
			} else if (dd.dd_st) {
//fixme: pb with "()"
				de.lden = true;
				de.defl.nost = true
			}

			if (f_near[dd.func])
				f_near[dd.func](de)
		}
	} // create_deco()

	// create the decorations of note heads
	function create_dh(s, m) {
	    var	de, k, dd,
		note = s.notes[m],
		nd = note.a_dd.length,
		x = s.x

		for (k = 0; k < nd; k++) {
			dd = note.a_dd[k]

//fixme: check if hidden?
			de = {
				s: s,
				dd: dd,
				st: s.st,
				m: m,
				ix: 0,
				defl: {},
				x: x,
				y: 3 * (note.pit - 18) - (dd.h - dd.hd) / 2
//				dy: 0
			}

			if (dd.ty) {		// if explicit position
				if (dd.ty == '@') {
					de.x += dd.x
					de.y += dd.y
				} else {
					de.y -= (dd.h - dd.hd) / 2	// center
					if (dd.ty == '<') {
						de.x -= dd.wr + 8
						if (s.notes[m].acc)
							x -= 8
					} else if (dd.ty == '>') {
						de.x += dd.wl + 8
					}
				}
			} else {
				if (note.shhd)
					de.x += note.shhd * stv_g.scale
				if (note.shac)
					de.x -= note.shac
				if (dd.func != 8)	// if not glissendo
					de.x -= dd.wl + dd.wr + 3
			}

			a_de.push(de)
			if (dd.dd_en) {
				de.ldst = true
			} else if (dd.dd_st) {
				de.lden = true;
				de.defl.nost = true
			}
		}
	} // create_dh()

	// create all decorations of a note (chord and heads)
	function create_all(s) {
		if (s.invis && s.play)	// play sequence: no decoration
			return
		if (s.a_dd)
			create_deco(s)
		if (s.notes) {
			for (var m = 0; m < s.notes.length; m++) {
				if (s.notes[m].a_dd)
					create_dh(s, m)
			}
		}
	} // create_all()

	// link the long decorations
	function ll_deco() {
	    var	i, j, de, de2, de3, dd, dd2, v, s, st,
			n_de = a_de.length

		// add ending decorations
		for (i = 0; i < n_de; i++) {
			de = a_de[i]
			if (!de.ldst)	// not the start of long decoration
				continue
			dd = de.dd;
			dd2 = dd.dd_en;
			s = de.s;
			v = s.v			// search later in the voice
			for (j = i + 1; j < n_de; j++) {
				de2 = a_de[j]
				if (!de2.start
				 && de2.dd == dd2 && de2.s.v == v)
					break
			}
			if (j == n_de) {	// no end, search in the staff
				st = s.st;
				for (j = i + 1; j < n_de; j++) {
					de2 = a_de[j]
					if (!de2.start
					 && de2.dd == dd2 && de2.s.st == st)
						break
				}
			}
			if (j == n_de) {	// no end, insert one
				de2 = {
					s: s,
					st: de.st,
					dd: dd2,
					ix: a_de.length - 1,
					x: realwidth - 6,
					y: s.y,
					cont: true,	// keep for next line
					lden: true,
					defl: {
						noen: true
					}
				}
				if (de2.x < s.x + 10)
					de2.x = s.x + 10
				if (de.m != undefined)
					de2.m = de.m;
				a_de.push(de2)
			}
			de2.start = de;
			de2.defl.nost = de.defl.nost

			// handle same decoration ending at a same time
			j = i
			while (--j >= 0) {
				de3 = a_de[j]
				if (!de3.start)
					continue
				if (de3.s.time < s.time)
					break
				if (de3.dd.name == de2.dd.name) {
					de2.prev = de3
					break
				}
			}
		}

		// add starting decorations
		for (i = 0; i < n_de; i++) {
			de2 = a_de[i]
			if (!de2.lden	// not the end of long decoration
			 || de2.start)	// start already found
				continue
			s = de2.s;
			de = {
				s: prev_scut(s),
				st: de2.st,
				dd: de2.dd.dd_st,
				ix: a_de.length - 1,
//				x: s.x - s.wl - 4,
				y: s.y,
				ldst: true
			}
			de.x = de.s.x + de.s.wr
			if (de2.m != undefined)
				de.m = de2.m;
			a_de.push(de);
			de2.start = de
		}
	} // ll_deco

	// update the long decorations started in the previous line
	for (s = tsfirst ; s; s = s.ts_next) {
		switch (s.type) {
		case C.CLEF:
		case C.KEY:
		case C.METER:
			continue
		}
		break
	}
	if (a_de.length)
		ldeco_update(s)

	for ( ; s; s = s.ts_next) {
		switch (s.type) {
		case C.BAR:
		case C.MREST:
		case C.NOTE:
		case C.REST:
		case C.SPACE:
			break
		case C.GRACE:
			for (g = s.extra; g; g = g.next)
				create_all(g)
			break
		default:
			continue
		}
		create_all(s)
	}
	ll_deco()			// link the long decorations
}

/* -- define the decorations tied to a note -- */
/* (the staves are not yet defined) */
/* (delayed output) */
function draw_deco_note() {
	var	i, de, dd, f,
		nd = a_de.length

	for (i = 0; i < nd; i++) {
		de = a_de[i];
		dd = de.dd;
		f = dd.func
		if (f_note[f]
		 && de.m == undefined)
			f_note[f](de)
	}
}

// -- define the music elements tied to the staff --
//	- decoration tied to the staves
//	- chord symbols
//	- repeat brackets
/* (the staves are not yet defined) */
/* (unscaled delayed output) */
function draw_deco_staff() {
    var	s, p_voice, y, i, v, de, dd, w,
	minmax = new Array(nstaff + 1),
	nd = a_de.length

	/* draw the repeat brackets */
	function draw_repbra(p_voice) {
		var s, s1, x, y, y2, i, p, w, wh, first_repeat;

		// search the max y offset of the line
		y = staff_tb[p_voice.st].topbar + 15	// 10 (vert bar) + 5 (room)
		for (s = p_voice.sym; s; s = s.next) {
			if (s.type != C.BAR)
				continue
			if (!s.rbstart || s.norepbra)
				continue
/*fixme: line cut on repeat!*/
			if (!s.next)
				break
			if (!first_repeat) {
				first_repeat = s;
				set_font("repeat")
			}
			s1 = s
			for (;;) {
				if (!s.next)
					break
				s = s.next
				if (s.rbstop)
					break
			}
			x = s1.x
			if (s1.xsh)			// volta shift
				x += s1.xsh
			y2 = y_get(p_voice.st, true, x, s.x - x) + 2
			if (y < y2)
				y = y2

			// have room for the vertical lines and the repeat numbers
			if (s1.rbstart == 2) {
				y2 = y_get(p_voice.st, true, x, 3) + 10
				if (y < y2)
					y = y2
			}
			if (s.rbstop == 2) {
				y2 = y_get(p_voice.st, true, s.x - 3, 3) + 10
				if (y < y2)
					y = y2
			}
			if (s1.text) {
				wh = strwh(s1.text);
				y2 = y_get(p_voice.st, true, x + 4, wh[0]) +
						wh[1]
				if (y < y2)
					y = y2
			}
			if (s.rbstart)
				s = s.prev
		}

		/* draw the repeat indications */
		s = first_repeat
		if (!s)
			return
		set_dscale(p_voice.st, true);
		y2 =  y * staff_tb[p_voice.st].staffscale
		for ( ; s; s = s.next) {
			if (!s.rbstart || s.norepbra)
				continue
			s1 = s
			while (1) {
				if (!s.next)
					break
				s = s.next
				if (s.rbstop)
					break
			}
			if (s1 == s)
				break
			x = s1.x
			if (s1.xsh)			// volta shift
				x += s1.xsh
			if (cfmt.measurenb > 0 & s.bar_num
			 && s.bar_num % cfmt.measurenb)
				x += 6
			if (s.type != C.BAR) {
				w = s.rbstop ? 0 : s.x - realwidth + 4
			} else if ((s.bar_type.length > 1	// if complex bar
				 && s.bar_type != "[]")
				|| s.bar_type == "]") {
//				if (s.bar_type == "]")
//					s.invis = true
//fixme:%%staves: cur_sy moved?
				if (s1.st > 0
				 && !(cur_sy.staves[s1.st - 1].flags & STOP_BAR))
					w = s.wl
				else if (s.bar_type.slice(-1) == ':')
					w = 12
				else if (s.bar_type[0] != ':')
//				      || s.bar_type == "]")
					w = 0		/* explicit repeat end */
				else
					w = 8
			} else {
				w = (s.rbstop && !s.rbstart) ? 0 : 8
			}
			w = (s.x - x - w)	// / staff_tb[p_voice.st].staffscale;

			if (!s.next		// 2nd ending at end of line
			 && !s.rbstop
			 && !p_voice.bar_start) { // continue on next line
				p_voice.bar_start = _bar(s)
				p_voice.bar_start.bar_type = ""
				p_voice.bar_start.rbstart = 1
			}
			if (s1.text)
				xy_str(x + 4, y2 - gene.curfont.size,
					s1.text);
			xypath(x, y2);
			if (s1.rbstart == 2)
				output += 'm0 10v-10';
			output+= 'h' + w.toFixed(1)
			if (s.rbstop == 2)
				output += 'v10';
			output += '"/>\n';
			y_set(s1.st, true, x, w, y + 2)

			if (s.rbstart)
				s = s.prev
		}
	} // draw_repbra()

	/* create the decorations tied to the staves */
	for (i = 0; i <= nstaff; i++)
		minmax[i] = {
			ymin: 0,
			ymax: 0
		}
	for (i = 0; i < nd; i++) {
		de = a_de[i];
		dd = de.dd
		if (!dd)		// if error
			continue
		if (!f_staff[dd.func]	/* if not tied to the staff */
		 || de.m != undefined	// or head decoration
		 || dd.ty == '<' || dd.ty == '>' || dd.ty == '@')
			continue

		f_staff[dd.func](de)
		if (dd.func != 6
		 || dd.dd_en)		// if start
			continue

		if ((de.pos & C.SL_ALI_MSK) == C.SL_ALIGN
		 || ((de.pos & C.SL_ALI_MSK) == 0
		  && de.s.fmt.dynalign > 0)) {	// if align
			if (de.up) {
				if (de.y > minmax[de.st].ymax)
					minmax[de.st].ymax = de.y
			} else {
				if (de.y < minmax[de.st].ymin)
					minmax[de.st].ymin = de.y
			}
		}
	}

	// set the same vertical offset of the dynamic marks
	for (i = 0; i < nd; i++) {
		de = a_de[i];
		dd = de.dd
		if (!dd)				// if error
			continue

		// if @x,y offsets, update the top and bottom of the staff
		if (dd.ty == '@') {
		    var	y2

			y = de.y
			if (y > 0) {
				y2 = y + dd.h + 2
				if (y2 > staff_tb[de.st].ann_top)
					staff_tb[de.st].ann_top = y2
			} else {
				y2 = y - dd.hd - 2
				if (y2 < staff_tb[de.st].ann_bot)
					staff_tb[de.st].ann_bot = y2

			}
			continue
		}
		if (dd.func != 6
		 || dd.ty == '<' || dd.ty == '>'
		 || dd.dd_en)				// if start
			continue

		w = de.val || (dd.wl + dd.wr)
		if ((de.pos & C.SL_ALI_MSK) == C.SL_ALIGN
		  || ((de.pos & C.SL_ALI_MSK) == 0
		   && de.s.fmt.dynalign > 0)) {		// if align
			if (de.up)
				y = minmax[de.st].ymax
			else
				y = minmax[de.st].ymin;
			de.y = y
		} else {
			y = de.y
		}
		if (de.up)
			y += dd.h;
		else
			y -= dd.hd
		y_set(de.st, de.up, de.x, w, y)
	}

	// second pass for pedal (under the staff)
	for (i = 0; i < nd; i++) {
		de = a_de[i]
		dd = de.dd
		if (!dd)			// if error
			continue
		if (dd.dd_en			// if start
		 || dd.name.slice(0, 3) != "ped")
			continue
		w = de.val || 10
		de.y = y_get(de.st, 0, de.x, w)
			- (dd.dd_st && cfmt.pedline ? 10 : dd.h)
		y_set(de.st, 0, de.x, w, de.y)	// (no descent)
	}

	draw_all_chsy()		// draw all chord symbols

	/* draw the repeat brackets */
	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v]
		if (p_voice.second || !p_voice.sym || p_voice.ignore)
			continue
		draw_repbra(p_voice)
	}
}

/* -- draw the measure bar numbers -- */
/* (scaled delayed output) */
function draw_measnb() {
	var	s, st, bar_num, x, y, w, any_nb, font_size, w0,
		sy = cur_sy

	/* search the top staff */
	for (st = 0; st <= nstaff; st++) {
		if (sy.st_print[st])
			break
	}
	if (st > nstaff)
		return				/* no visible staff */
	set_dscale(st)

	/* leave the measure numbers as unscaled */
	if (staff_tb[st].staffscale != 1) {
		font_size = get_font("measure").size;
		param_set_font("measurefont", "* " +
			(font_size / staff_tb[st].staffscale).toString())
	}
	set_font("measure");
	w0 = cwidf('0');			// (greatest) width of a number

	s = tsfirst;				/* clef */
	bar_num = gene.nbar
	if (bar_num > 1) {
		if (cfmt.measurenb == 0) {
			any_nb = true;
			y = y_get(st, true, 0, 20)
			if (y < staff_tb[st].topbar + 14)
				y = staff_tb[st].topbar + 14;
			xy_str(0, y - gene.curfont.size * .2, bar_num.toString())
			y_set(st, true, 0, 20, y + gene.curfont.size + 2)
		} else if (bar_num % cfmt.measurenb == 0) {
			for ( ; ; s = s.ts_next) {
				switch (s.type) {
				case C.CLEF:
				case C.KEY:
				case C.METER:
				case C.STBRK:
					continue
				}
				break
			}

			// don't display the number twice
		     if (s.type != C.BAR || !s.bar_num) {
			any_nb = true;
			w = w0
			if (bar_num >= 10)
				w *= bar_num >= 100 ? 3 : 2
			if (gene.curfont.pad)
				w += gene.curfont.pad * 2
			x = (s.prev
				? s.prev.x + s.prev.wr / 2
				: s.x - s.wl) - w
			y = y_get(st, true, x, w) + 5
			if (y < staff_tb[st].topbar + 6)
				y = staff_tb[st].topbar + 6;
			y += gene.curfont.pad
			xy_str(x, y - gene.curfont.size * .2, bar_num.toString())
			y += gene.curfont.size + gene.curfont.pad
			y_set(st, true, x, w, y);
//			s.ymx = y
		     }
		}
	}

	for ( ; s; s = s.ts_next) {
		switch (s.type) {
		case C.STAVES:
			sy = s.sy
			for (st = 0; st < nstaff; st++) {
				if (sy.st_print[st])
					break
			}
			set_dscale(st)
			continue
		default:
			continue
		case C.BAR:
			if (!s.bar_num || s.bar_num <= 1)
				continue
			break
		}

		bar_num = s.bar_num
		if (cfmt.measurenb == 0
		 || (bar_num % cfmt.measurenb) != 0
		 || !s.next
		 || s.bar_mrep)
			continue
		if (!any_nb)
			any_nb = true;
		w = w0
		if (bar_num >= 10)
			w *= bar_num >= 100 ? 3 : 2
		if (gene.curfont.pad)
			w += gene.curfont.pad * 2
		x = s.x
		y = y_get(st, true, x, w)
		if (y < staff_tb[st].topbar + 6)
			y = staff_tb[st].topbar + 6
		if (s.next.type == C.NOTE) {
			if (s.next.stem > 0) {
				if (y < s.next.ys - gene.curfont.size)
					y = s.next.ys - gene.curfont.size
			} else {
				if (y < s.next.y)
					y = s.next.y
			}
		}
		y += 2 + gene.curfont.pad
		xy_str(x, y - gene.curfont.size * .2, bar_num.toString())
		y += gene.curfont.size + gene.curfont.pad
		y_set(st, true, x, w, y);
//		s.ymx = y
	}
	gene.nbar = bar_num

	if (font_size)
		param_set_font("measurefont", "* " + font_size.toString());
}

/* -- draw the parts and the tempo information -- */
// (unscaled delayed output)
function draw_partempo() {
    var	s, s2, some_part, some_tempo, h, w, y, st, p,
	sy = cur_sy

	// search the top staff
	for (st = 0; st <= nstaff; st++) {
		if (sy.st_print[st])
			break
	}
	if (st > nstaff)
		return				// no visible staff
	set_dscale(st, 1)			// no scale

	/* get the minimal y offset */
    var	ymin = staff_tb[st].topbar + 2,
		dosh = 0,
		shift = 1,
	x = -100		// (must be negative for %%soloffs)

	// output the parts
	for (s = tsfirst; s; s = s.ts_next) {
		s2 = s.part
		if (!s2 || s2.invis)
			continue
		if (!some_part) {
			some_part = s;
			set_font("parts");
			h = gene.curfont.size + 2 +
				gene.curfont.pad * 2
		}
		if (s2.x == undefined)
			s2.x = s.x - 10
		p = s2.text
		if (cfmt.partname)
			s2.ntxt = p = partname(p)[2]
		w = strwh(p)[0]
		y = y_get(st, true, s2.x, w + 3)
		if (ymin < y)
			ymin = y
	}
	if (some_part) {
		set_sscale(-1)
		ymin *= staff_tb[st].staffscale
		for (s = some_part; s; s = s.ts_next) {
			s2 = s.part
			if (!s2 || s2.invis)
				continue
			p = s2.ntxt || s2.text
			w = strwh(p)[0]
			if (user.anno_start || user.anno_stop) {
				s2.wl = 0
				s2.wr = w
				s2.ymn = ymin
				s2.ymx = s2.ymn + h
				anno_start(s2)
			}
			xy_str(s2.x,
				ymin + gene.curfont.pad + gene.curfont.size * .22,
				p)
			y_set(st, 1, s2.x, w + 3,
				(ymin + h) / staff_tb[st].staffscale)
			anno_stop(s2)
		}
	}

	// output the tempos
	ymin = staff_tb[st].topbar + 6
	for (s = tsfirst; s; s = s.ts_next) {
		if (s.type != C.TEMPO || s.invis)
			continue
		if (!some_tempo)
			some_tempo = s
		w = s.tempo_wh[0]
//		if (s.time == 0 && s.x > 40)	// at start of tune and no %%soloffs,
//			s.x = 40	// shift the tempo over the key signature
		y = y_get(st, true, s.x - 16, w)
		if (y > ymin)
			ymin = y
		if (x >= s.x - 16 && !(dosh & (shift >> 1)))
			dosh |= shift
		shift <<= 1
		x = s.x - 16 + w
	}
	if (some_tempo) {
		set_sscale(-1)
		set_font("tempo")
		ymin += 2
		ymin *= staff_tb[st].staffscale

		/* draw the tempo indications */
		for (s = some_tempo; s; s = s.ts_next) {
			if (s.type != C.TEMPO
			 || s.invis)		// (displayed by %%titleformat)
				continue
			w = s.tempo_wh[0]
			h = s.tempo_wh[1]
			y = ymin
			if (dosh & 1)
				y += h
			if (user.anno_start || user.anno_stop) {
				s.wl = 16
//				s.wr = 30
				s.wr = w - 16
				s.ymn = y
				s.ymx = s.ymn + 14
				anno_start(s)
			}
			writempo(s, s.x - 16, y)
			anno_stop(s)
			y_set(st, 1, s.x - 16, w,
				(y + h + 2) / staff_tb[st].staffscale)
			dosh >>= 1
		}
	}
}
// abc2svg - draw.js - draw functions
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

// constants
var	STEM_MIN	= 16,	/* min stem height under beams */
	STEM_MIN2	= 14,	/* ... for notes with two beams */
	STEM_MIN3	= 12,	/* ... for notes with three beams */
	STEM_MIN4	= 10,	/* ... for notes with four beams */
	STEM_CH_MIN	= 14,	/* min stem height for chords under beams */
	STEM_CH_MIN2	= 10,	/* ... for notes with two beams */
	STEM_CH_MIN3	= 9,	/* ... for notes with three beams */
	STEM_CH_MIN4	= 9,	/* ... for notes with four beams */
	BEAM_DEPTH	= 3.2,	/* width of a beam stroke */
	BEAM_OFFSET	= .25,	/* pos of flat beam relative to staff line */
	BEAM_SHIFT	= 5,	/* shift of second and third beams */
	BEAM_STUB	= 7,	/* length of stub for flag under beam */ 
	SLUR_SLOPE	= .7,	// max slope of a slur
	GSTEM		= 15,	/* grace note stem length */
	GSTEM_XOFF	= 2.3	/* x offset for grace note stem */

    var cache,
	anno_a = []		// symbols with annotations

/* -- compute the best vertical offset for the beams -- */
function b_pos(grace, stem, nflags, b) {
	var	top, bot, d1, d2,
		shift = !grace ? BEAM_SHIFT : 3.5,
		depth = !grace ? BEAM_DEPTH : 1.8

	/* -- up/down shift needed to get k*6 -- */
	function rnd6(y) {
		var iy = Math.round((y + 12) / 6) * 6 - 12
		return iy - y
	} // rnd6()

	if (stem > 0) {
		bot = b - (nflags - 1) * shift - depth
		if (bot > 26)
			return 0
		top = b
	} else {
		top = b + (nflags - 1) * shift + depth
		if (top < -2)
			return 0
		bot = b
	}

	d1 = rnd6(top - BEAM_OFFSET);
	d2 = rnd6(bot + BEAM_OFFSET)
	return d1 * d1 > d2 * d2 ? d2 : d1
}

/* duplicate a note for beaming continuation */
function sym_dup(s) {
    var	m, note

	s = clone(s)
	s.invis = true
	delete s.extra;
	delete s.text
	delete s.a_gch
	delete s.a_ly
	delete s.a_dd;
	delete s.tp
	s.notes = clone(s.notes)
	for (m = 0; m <= s.nhd; m++) {
		note = s.notes[m] = clone(s.notes[m])
		delete note.a_dd
	}
	return s
}

/* -- calculate a beam -- */
/* (the staves may be defined or not) */
var min_tb = [
	[STEM_MIN, STEM_MIN,
		STEM_MIN2, STEM_MIN3, STEM_MIN4, STEM_MIN4],
	[STEM_CH_MIN, STEM_CH_MIN,
		STEM_CH_MIN2, STEM_CH_MIN3, STEM_CH_MIN4, STEM_CH_MIN4]
]

// (possible hook)
Abc.prototype.calculate_beam = function(bm, s1) {
    var	s, s2, g, notes, nflags, st, v, two_staves, two_dir,
	n, x, y, ys, a, b, stem_err, max_stem_err,
		p_min, p_max, s_closest,
		stem_xoff, scale,
		visible, dy

	if (!s1.beam_st) {	/* beam from previous music line */
		s = sym_dup(s1);
		lkvsym(s, s1);
		lktsym(s, s1);
		s.x -= 12
		if (s.x > s1.prev.x + 12)
			s.x = s1.prev.x + 12;
		s.beam_st = true
		delete s.beam_end;
		s.tmp = true
		delete s.sls;
		s1 = s
	}

	/* search last note in beam */
	notes = nflags = 0;	/* set x positions, count notes and flags */
	two_staves = two_dir = false;
	st = s1.st;
	v = s1.v;
	stem_xoff = s1.grace ? GSTEM_XOFF : 3.5
	for (s2 = s1;  ;s2 = s2.next) {
		if (s2.type == C.NOTE) {
			if (s2.nflags > nflags)
				nflags = s2.nflags;
			notes++
			if (s2.st != st)
				two_staves = true
			if (s2.stem != s1.stem)
				two_dir = true
			if (!visible && !s2.invis
			 && (!s2.stemless || s2.trem2))
				visible = true
			if (s2.beam_end)
				break
		}
		if (!s2.next) {		/* beam towards next music line */
			for (; ; s2 = s2.prev) {
				if (s2.type == C.NOTE)
					break
			}
			s = sym_dup(s2);
			s.next = s2.next
			if (s.next)
				s.next.prev = s;
			s2.next = s;
			s.prev = s2;
			s.ts_next = s2.ts_next
			if (s.ts_next)
				s.ts_next.ts_prev = s;
			s2.ts_next = s;
			s.ts_prev = s2
			delete s.beam_st;
			s.beam_end = true;
			s.tmp = true
			delete s.sls;
			s.x += 12
			if (s.x < realwidth - 12)
				s.x = realwidth - 12;
			s2 = s;
			notes++
			break
		}
	}

	// at least, must have a visible note with a stem
	if (!visible)
		return false;

	bm.s2 = s2			/* (don't display the flags) */

	if (staff_tb[st].y == 0) {	/* staves not defined */
		if (two_staves)
			return false
	} else {			/* staves defined */
//		if (!two_staves && !s1.grace) {
		if (!two_staves) {
			bm.s1 = s1;	/* beam already calculated */
			bm.a = (s1.ys - s2.ys) / (s1.xs - s2.xs);
			bm.b = s1.ys - s1.xs * bm.a + staff_tb[st].y;
			bm.nflags = nflags
			return true
		}
	}

	s_closest = s1;
	p_min = 100;
	p_max = 0
	for (s = s1; ; s = s.next) {
		if (s.type != C.NOTE)
			continue
		if ((scale = s.p_v.scale) == 1)
			scale = staff_tb[s.st].staffscale
		if (s.stem >= 0) {
			x = stem_xoff + s.notes[0].shhd
			if (s.notes[s.nhd].midi > p_max) {
				p_max = s.notes[s.nhd].midi
				s_closest = s
			}
		} else {
			x = -stem_xoff + s.notes[s.nhd].shhd
			if (s.notes[0].midi < p_min) {
				p_min = s.notes[0].midi
				s_closest = s
			}
		}
		s.xs = s.x + x * scale;
		if (s == s2)
			break
	}

	// have flat beams on grace notes when asked
	if (s.grace && s1.fmt.flatbeams)
		a = 0

	// if a note inside the beam is the closest to the beam, the beam is flat
	else if (!two_dir
	      && notes >= 3
	      && s_closest != s1 && s_closest != s2)
		a = 0

	y = s1.ys + staff_tb[st].y
	if (a == undefined) {
		if (two_dir
		 && s1.stem != s2.stem
		 && s1.st == s2.st) {		// if inverted stems,
			y -= 5 * s1.stem	// remove the beam depth
			s2.ys -= 5 * s2.stem			
		}
		a = (s2.ys + staff_tb[s2.st].y - y) / (s2.xs - s1.xs)
	}

	if (a != 0) {
		a = s1.fmt.beamslope * a /
			(s1.fmt.beamslope + Math.abs(a)) // max steepness for beam
		if (a > -.04 && a < .04)
			a = 0				// slope too low
	}

	// center the main beam
	b = (y + s2.ys + staff_tb[s2.st].y) / 2 - a * (s2.xs + s1.xs) / 2

	/* have room for the symbols in the staff */
	max_stem_err = 0;		/* check stem lengths */

	// when 2 directions, check if all beams are on the same side of the main beam
	s = s1
	if (two_dir) {
		n = 1
		while (1) {
			if (s.stem != s1.stem
			 && (s.nflags == 1
			  || s.beam_br1  || s.beam_br2)) {
				n = 0
				break
			}
			if (s == s2)
				break
			s = s.next
		}
		if (n)				// same side
			n = (s1.nflags + s2.nflags)
				* (s1.nflags >= s2.nflags ? s1.stem : s2.stem)
					/ 4
		else				// different sides
			n = -(s1.nflags * s1.stem + s2.nflags * s2.stem)
					/ 2
		b += ((s1.grace ? 3.5 : BEAM_SHIFT) * n
				+ BEAM_DEPTH * s1.stem) / 2
	} else if (!s1.grace) {		/* normal notes */
		var beam_h = BEAM_DEPTH + BEAM_SHIFT * (nflags - 1)
//--fixme: added for abc2svg
		while (s.ts_prev
		    && s.ts_prev.type == C.NOTE
		    && s.ts_prev.time == s.time
		    && s.ts_prev.x > s1.xs)
			s = s.ts_prev

		for (; s && s.time <= s2.time; s = s.ts_next) {
			if (s.type != C.NOTE
			 || s.invis
			 || (s.st != st
			  && s.v != v)) {
				continue
			}
			x = s.v == v ? s.xs : s.x;
			ys = a * x + b - staff_tb[s.st].y
			if (s.v == v) {
				stem_err = min_tb[s.nhd == 0 ? 0 : 1][s.nflags]
				if (s.stem > 0) {
					if (s.notes[s.nhd].pit > 26) {
						stem_err -= 2
						if (s.notes[s.nhd].pit > 28)
							stem_err -= 2
					}
					stem_err -= ys - 3 * (s.notes[s.nhd].pit - 18)
				} else {
					if (s.notes[0].pit < 18) {
						stem_err -= 2
						if (s.notes[0].pit < 16)
							stem_err -= 2
					}
					stem_err -= 3 * (s.notes[0].pit - 18) - ys
				}
				stem_err += BEAM_DEPTH + BEAM_SHIFT * (s.nflags - 1)
			} else {
/*fixme: KO when two_staves*/
				if (s1.stem > 0) {
					if (s.stem > 0) {
/*fixme: KO when the voice numbers are inverted*/
						if (s.ymn > ys + 4
						 || s.ymx < ys - beam_h - 2)
							continue
						if (s.v > v)
							stem_err = s.ymx - ys
						else
							stem_err = s.ymn + 8 - ys
					} else {
						stem_err = s.ymx - ys
					}
				} else {
					if (s.stem < 0) {
						if (s.ymx < ys - 4
						 || s.ymn > ys - beam_h - 2)
							continue
						if (s.v < v)
							stem_err = ys - s.ymn
						else
							stem_err = ys - s.ymx + 8
					} else {
						stem_err = ys - s.ymn
					}
				}
				stem_err += 2 + beam_h
			}
			if (stem_err > max_stem_err)
				max_stem_err = stem_err
		}
	} else {				/* grace notes */
		for ( ; ; s = s.next) {
			ys = a * s.xs + b - staff_tb[s.st].y;
			stem_err = GSTEM - 2
			if (s.stem > 0)
				stem_err -= ys - (3 * (s.notes[s.nhd].pit - 18))
			else
				stem_err += ys - (3 * (s.notes[0].pit - 18));
			stem_err += 3 * (s.nflags - 1)
			if (stem_err > max_stem_err)
				max_stem_err = stem_err
			if (s == s2)
				break
		}
	}

	if (max_stem_err > 0)		/* shift beam if stems too short */
		b += s1.stem * max_stem_err

	// have room for the gracenotes and clefs
    if (!two_staves && !two_dir)
	for (s = s1.next; ; s = s.next) {
		switch (s.type) {
		case C.REST:		/* cannot move rests in multi-voices */
			if (!s.multi)
				break
			g = s.ts_next
			if (!g || g.st != st
			 || (g.type != C.NOTE && g.type != C.REST))
				break
//fixme:too much vertical shift if some space above the note
//fixme:this does not fix rest under beam in second voice (ts_prev)
			/*fall thru*/
//		case C.BAR:
			if (s.invis)
				break
			/*fall thru*/
		case C.CLEF:
			y = a * s.x + b
			if (s1.stem > 0) {
				y = s.ymx - y
					+ BEAM_DEPTH + BEAM_SHIFT * (nflags - 1)
					+ 2
				if (y > 0)
					b += y
			} else {
				y = s.ymn - y
					- BEAM_DEPTH - BEAM_SHIFT * (nflags - 1)
					- 2
				if (y < 0)
					b += y
			}
			break
		case C.GRACE:
			for (g = s.extra; g; g = g.next) {
				y = a * g.x + b
				if (s1.stem > 0) {
					y = g.ymx - y
						+ BEAM_DEPTH + BEAM_SHIFT * (nflags - 1)
					if (y > 0)
						b += y
				} else {
					y = g.ymn - y
						- BEAM_DEPTH - BEAM_SHIFT * (nflags - 1)
					if (y < 0)
						b += y
				}
			}
			break
		}
		if (s == s2)
			break
	}

	if (a == 0)		/* shift flat beams onto staff lines */
		b += b_pos(s1.grace, s1.stem, nflags, b - staff_tb[st].y)

	/* adjust final stems and rests under beam */
	for (s = s1; ; s = s.next) {
		switch (s.type) {
		case C.NOTE:
			s.ys = a * s.xs + b - staff_tb[s.st].y
			if (s.stem > 0) {
				s.ymx = s.ys + 2.5
			} else {
				s.ymn = s.ys - 2.5
			}
			break
		case C.REST:
			y = a * s.x + b - staff_tb[s.st].y
			dy = BEAM_DEPTH + BEAM_SHIFT * (nflags - 1)
				+ (s.head != C.FULL ? 4 : 9)
			if (s1.stem > 0) {
				y -= dy
				if (s1.multi == 0 && y > 12)
					y = 12
				if (s.y <= y)
					break
			} else {
				y += dy
				if (s1.multi == 0 && y < 12)
					y = 12
				if (s.y >= y)
					break
			}
			if (s.head != C.FULL)
				y = (((y + 3 + 12) / 6) | 0) * 6 - 12;
			s.y = y
			break
		}
		if (s == s2)
			break
	}

	/* save beam parameters */
	if (staff_tb[st].y == 0)	/* if staves not defined */
		return false
	bm.s1 = s1;
	bm.a = a;
	bm.b = b;
	bm.nflags = nflags
	return true
}

/* -- draw the beams for one word -- */
/* (the staves are defined) */
function draw_beams(bm) {
    var	s, i, beam_dir, shift, bshift, bstub, bh, da, bsh,
		k, k1, k2, x1,
	osh = 0,				// shift other side
		s1 = bm.s1,
		s2 = bm.s2

	/* -- draw a single beam -- */
	function draw_beam(x1, x2, dy, h, bm,
				 n) {		/* beam number (1..n) */
		var	y1, dy2,
			s = bm.s1,
			nflags = s.nflags

		if (s.ntrem)
			nflags -= s.ntrem
		if (s.trem2 && n > nflags) {
			if (s.dur >= C.BLEN / 2) {
				x1 = s.x + 6;
				x2 = bm.s2.x - 6
			} else if (s.dur < C.BLEN / 4) {
			    var	dx = x2 - x1
				if (dx < 16) {
					x1 += dx / 4
					x2 -= dx / 4
				} else {
					x1 += 5
					x2 -= 6
				}
			}
		}

		y1 = bm.a * x1 + bm.b - dy;
		x2 -= x1;
		x2 /= stv_g.scale;
		dy2 = bm.a * x2 * stv_g.stsc
		xypath(x1, y1, true);
		output += 'l' + x2.toFixed(1) + ' ' + (-dy2).toFixed(1) +
			'v' + h.toFixed(1) +
			'l' + (-x2).toFixed(1) + ' ' + dy2.toFixed(1) +
			'z"/>\n'
	} // draw_beam()

	anno_start(s1, 'beam')
/*fixme: KO if many staves with different scales*/
//	set_scale(s1)
	if (!s1.grace) {
		bshift = BEAM_SHIFT;
		bstub = BEAM_STUB;
		shift = .34;		/* (half width of the stem) */
		bh = BEAM_DEPTH
	} else {
		bshift = 3.5;
		bstub = 3.2;
		shift = .29;
		bh = 1.8
	}
	bh /= stv_g.scale

/*fixme: quick hack for stubs at end of beam and different stem directions*/
	beam_dir = s1.stem
	if (s1.stem != s2.stem
	 && s1.nflags > s2.nflags)
		beam_dir = s2.stem
	if (beam_dir < 0)
		bh = -bh;

	/* make first beam over whole word and adjust the stem lengths */
	draw_beam(s1.xs - shift, s2.xs + shift, 0, bh, bm, 1);
	da = 0
	for (s = s1; ; s = s.next) {
		if (s.type == C.NOTE
		 && s.stem != beam_dir)
			s.ys = bm.a * s.xs + bm.b
				- staff_tb[s.st].y
				+ bshift * (s.nflags - 1) * s.stem
				- bh
		if (s == s2)
			break
	}

	if (s1.feathered_beam) {
		da = bshift / (s2.xs - s1.xs)
		if (s1.feathered_beam > 0) {
			da = -da;
			bshift = da * s1.xs
		} else {
			bshift = da * s2.xs
		}
		da = da * beam_dir
	}

	/* other beams with two or more flags */
	shift = 0
	for (i = 2; i <= bm.nflags; i++) {
		shift += bshift
		if (da != 0)
			bm.a += da
		for (s = s1; ; s = s.next) {
			if (s.type != C.NOTE
			 || s.nflags < i) {
				if (s == s2)
					break
				continue
			}
			if (s.trem1
			 && i > s.nflags - s.ntrem) {
				x1 = (s.dur >= C.BLEN / 2) ? s.x : s.xs;
				draw_beam(x1 - 5, x1 + 5,
					  (shift + 2.5) * beam_dir,
					  bh, bm, i)
				if (s == s2)
					break
				continue
			}
			k1 = s
			while (1) {
				if (s == s2)
					break
				k = s.next
				if (k.type == C.NOTE || k.type == C.REST) {
					if (k.trem1){
						if (k.nflags - k.ntrem < i)
							break
					} else if (k.nflags < i) {
						break
					}
				}
				if (k.beam_br1
				 || (k.beam_br2 && i > 2))
					break
				s = k
			}
			k2 = s
			while (k2.type != C.NOTE)
				k2 = k2.prev;
			x1 = k1.xs
			bsh = shift * beam_dir
			if (k1 == k2) {
				if (k1 == s1) {
					x1 += bstub
				} else if (k1 == s2) {
					x1 -= bstub
				} else if (k1.beam_br1
				        || (k1.beam_br2
					 && i > 2)) {
					x1 += bstub
				} else {
					k = k1.next
					while (k.type != C.NOTE)
						k = k.next
					if (k.beam_br1
					 || (k.beam_br2 && i > 2)) {
						x1 -= bstub
					} else {
						k1 = k1.prev
						while (k1.type != C.NOTE)
							k1 = k1.prev
						if (k1.nflags < k.nflags
						 || (k1.nflags == k.nflags
						  && k1.dots < k.dots))
							x1 += bstub
						else
							x1 -= bstub
					}
				}
				if (k1.stem != beam_dir) {
					osh -= bshift
					bsh = osh * beam_dir
					k1.ys = bm.a * k1.xs + bm.b
						- staff_tb[k1.st].y - bh
				}
			} else if (k1.stem == k2.stem && k1.stem != beam_dir) {

				// inverted stems: put the beam on the other side
				osh -= bshift
				bsh = osh * beam_dir
				for (s = k1; ; s = s.next) {
					if (s.type == C.NOTE)
						s.ys = bm.a * s.xs + bm.b
							- staff_tb[s.st].y
							- bh
					if (s == k2)
						break
				}
			}
			draw_beam(x1, k2.xs,
				  bsh,
				  bh, bm, i)
			if (s == s2)
				break
		}
	}
	if (s1.tmp)
		unlksym(s1)
	else if (s2.tmp)
		unlksym(s2)
	anno_stop(s1, 'beam')
}

/* -- draw the left side of the staves -- */
function draw_lstaff(x) {
    var	i, j, yb, h, fl,
		nst = cur_sy.nstaff,
		l = 0

	/* -- draw a system brace or bracket -- */
	function draw_sysbra(x, st, flag) {
		var i, st_end, yt, yb

		while (!cur_sy.st_print[st]) {
			if (cur_sy.staves[st].flags & flag)
				return
			st++
		}
		i = st_end = st
		while (1) {
			if (cur_sy.st_print[i])
				st_end = i
			if (cur_sy.staves[i].flags & flag)
				break
			i++
		}
		yt = staff_tb[st].y + staff_tb[st].topbar
					* staff_tb[st].staffscale;
		yb = staff_tb[st_end].y + staff_tb[st_end].botbar
					* staff_tb[st_end].staffscale
		if (flag & (CLOSE_BRACE | CLOSE_BRACE2))
			out_brace(x, yb, yt - yb)
		else
			out_bracket(x, yt, yt - yb)
	}

	for (i = 0; ; i++) {
		fl = cur_sy.staves[i].flags
		if (fl & (OPEN_BRACE | OPEN_BRACKET))
			l++
		if (cur_sy.st_print[i])
			break
		if (fl & (CLOSE_BRACE | CLOSE_BRACKET))
			l--
		if (i == nst)
			break
	}
	for (j = nst; j > i; j--) {
		if (cur_sy.st_print[j])
			break
	}
	if (i == j && l == 0)
		return
	yb = staff_tb[j].y + staff_tb[j].botbar * staff_tb[j].staffscale;
	h = staff_tb[i].y + staff_tb[i].topbar * staff_tb[i].staffscale - yb;
	xypath(x, yb);
	output += "v" + (-h).toFixed(1) + '"/>\n'
	for (i = 0; i <= nst; i++) {
		fl = cur_sy.staves[i].flags
		if (fl & OPEN_BRACE)
			draw_sysbra(x, i, CLOSE_BRACE)
		if (fl & OPEN_BRACKET)
			draw_sysbra(x, i, CLOSE_BRACKET)
		if (fl & OPEN_BRACE2)
			draw_sysbra(x - 6, i, CLOSE_BRACE2)
		if (fl & OPEN_BRACKET2)
			draw_sysbra(x - 6, i, CLOSE_BRACKET2)
	}
}

/* -- draw the time signature -- */
function draw_meter(s) {
	if (!s.a_meter)
		return
    var	i, m, meter, x, x0, yt,
	p_staff = staff_tb[s.st],
	y = p_staff.y

	// adjust the vertical offset according to the staff definition
	if (p_staff.stafflines != '|||||')
		y += (p_staff.topbar + p_staff.botbar) / 2 - 12	// bottom

	for (i = 0; i < s.a_meter.length; i++) {
		meter = s.a_meter[i];
		x = s.x + s.x_meter[i]
		yt = y + (meter.bot ? 18 : 12)
		if (s.a_meter[i + 1]
		 && (s.a_meter[i + 1].top == '|'
		  || s.a_meter[i + 1].top == '.')) {
			xygl(x, yt, "mtr" + meter.top[0] + s.a_meter[i + 1].top)
			i++
			continue
		}
		xygl(x, yt, "mtr" + meter.top[0])
		if (meter.top.length > 1) {
			m = 0
			x0 = x
			while (1) {
				switch (meter.top[m]) {
				case '(':
				case ')':
					x += 4
					break
				case '1':
					x += 8
					break
				case ' ':
					x += 4
					break
				case '+':
					x += 2
					// fall thru
				default:
					x += 10
					break
				}
				if (++m >= meter.top.length)
					break
				xygl(x, yt, "mtr" + meter.top[m])
			}
			x = (x0 + x) / 2 - 5
		}
		if (meter.bot) {
			if (meter.bot[1]) {
				if (meter.bot[0] == 1) {
					x0 = x - 4
					x += 4
				} else {
					x0 = x - 5
					x += 5
				}
				xygl(x0, y + 6, "mtr" + meter.bot[0])
				xygl(x, y + 6, "mtr" + meter.bot[1])
			} else {
				xygl(x, y + 6, "mtr" + meter.bot[0])
			}
		}
	}
}

    var	acc_nd = {}		// cache of the microtonal accidentals

/* -- draw an accidental -- */
function draw_acc(x, y, a) {
	if (typeof a == "object") {		// if microtone
	    var	c,
		n = a[0],
		d = a[1]

		c = n + '_' + d
		a = acc_nd[c]
		if (!a) {
			a = abc2svg.rat(Math.abs(n), d)
			d = a[1]
			a = (n < 0 ? -a[0] : a[0]).toString()
			if (d != 1)
				a += '_' + d
			acc_nd[c] = a
		}
	}
	xygl(x, y, "acc" + a)
}

// memorize the helper/ledger lines
function set_hl(p_st, n, x, dx1, dx2) {
    var	i, hl

	if (n >= 0) {
		hl = p_st.hlu[n]
		if (!hl)
			hl = p_st.hlu[n] = []
	} else {
		hl = p_st.hld[-n]
		if (!hl)
			hl = p_st.hld[-n] = []
	}

	for (i = 0; i < hl.length; i++) {
		if (x >= hl[i][0])
			break
	}
	if (i == hl.length) {
		hl.push([x, dx1, dx2])
	} else if (x > hl[i][0]) {
		hl.splice(++i, 0, [x, dx1, dx2])
	} else {
		if (dx1 < hl[i][1])
			hl[i][1] = dx1
		if (dx2 > hl[i][2])
			hl[i][2] = dx2
	}
} // set_hl()

// draw helper lines
// (possible hook)
Abc.prototype.draw_hl = function(s) {
    var	i, j, n, note,
	hla = [],
	st = s.st,
	p_staff = staff_tb[st]

	// check if any helper line
	if (!p_staff.hll
	 || s.invis)
		return			// no helper line (no line)
	for (i = 0; i <= s.nhd; i++) {
		note = s.notes[i]
		if (!p_staff.hlmap[note.pit - p_staff.hll])
			hla.push([note.pit - 18,
				  note.shhd * s.p_v.scale])
	}
	n = hla.length
	if (!n)
		return			// no

	// handle the helper lines out of the staff
    var	dx1, dx2, hl, shhd,hlp,
	stafflines = cur_sy.staves[st].stafflines,
	top = stafflines.length - 1,
	yu =  top,
	bot = (p_staff.hll - 17) / 2,
	yl = bot,
	dx = (s.grace ? 4 : hw_tb[s.head] * 1.3) * s.p_v.scale

	// get the x start and x stop of the intermediate helper lines
	note = s.notes[s.stem < 0 ? s.nhd : 0]
	shhd = note.shhd

	for (i = 0; i < hla.length; i++) {
		hlp = hla[i][0]
		dx1 = (hla[i][1] < shhd ? hla[i][1] : shhd) - dx
		dx2 = (hla[i][1] > shhd ? hla[i][1] : shhd) + dx
		if (hlp < bot * 2) {
			if (++hlp < yl * 2)
				yl = hlp >> 1
			n--
		} else if (hlp > top * 2) {
			yu = hlp >> 1
			n--
		}
		set_hl(p_staff, hlp >> 1, s.x, dx1, dx2)
	}

	dx1 = shhd - dx
	dx2 = shhd + dx
	while (++yl < bot)
		set_hl(p_staff, yl,
			s.x, dx1, dx2)
	while (--yu > top)
		set_hl(p_staff, yu,
			s.x, dx1, dx2)
	if (!n)
		return			// no more helper lines

	// draw the helper lines inside the staff
	i = yl;
	j = yu
	while (i > bot && stafflines[i] == '-')
		i--
	while (j < top && stafflines[j] == '-')
		j++
	for ( ; i < j; i++) {
		if (stafflines[i] == '-')
			set_hl(p_staff, i, s.x, dx1, dx2)
	}
}

/* -- draw a key signature -- */
// (possible hook)
var	sharp_cl = new Int8Array([24, 9, 15, 21, 6, 12, 18]),
	flat_cl = new Int8Array([12, 18, 24, 9, 15, 21, 6]),
	sharp1 = new Int8Array([-9, 12, -9, -9, 12, -9]),
	sharp2 = new Int8Array([12, -9, 12, -9, 12, -9]),
	flat1 = new Int8Array([9, -12, 9, -12, 9, -12]),
	flat2 = new Int8Array([-12, 9, -12, 9, -12, 9])

Abc.prototype.draw_keysig = function(x, s) {
	var	old_sf = s.k_old_sf,
		st = s.st,
		staffb = staff_tb[st].y,
		i, shift, p_seq,
		clef_ix = s.k_y_clef,
	a_acc = s.k_a_acc			// accidental list [pit, acc]

	// set the accidentals when K: with modified accidentals
	function set_k_acc(a_acc, sf) {
	    var i, j, n, nacc, p_acc,
		accs = [],
		pits = []

		if (sf > 0) {
			for (nacc = 0; nacc < sf; nacc++) {
				accs[nacc] = 1			// sharp
				pits[nacc] = [26, 23, 27, 24, 21, 25, 22][nacc]
			}
		} else {
			for (nacc = 0; nacc < -sf; nacc++) {
				accs[nacc] = -1			// flat
				pits[nacc] = [22, 25, 21, 24, 20, 23, 26][nacc]
			}
		}
		n = a_acc.length
		for (i = 0; i < n; i++) {
			p_acc = a_acc[i]
			for (j = 0; j < nacc; j++) {
				if (pits[j] == p_acc.pit) {
					accs[j] = p_acc.acc
					break
				}
			}
			if (j == nacc) {
				accs[j] = p_acc.acc
				pits[j] = p_acc.pit
				nacc++
			}
		}
		for (i = 0; i < nacc; i++) {
			p_acc = a_acc[i]
			if (!p_acc)
				p_acc = a_acc[i] = {}
			p_acc.acc = accs[i]
			p_acc.pit = pits[i]
		}
	} // set_k_acc()

	// ---- draw_keysig ---
	if (clef_ix & 1)
		clef_ix += 7;
	clef_ix /= 2
	while (clef_ix < 0)
		clef_ix += 7;
	clef_ix %= 7

	/* normal accidentals */
	if (a_acc && !s.exp)			// if added accidentals
		set_k_acc(a_acc, s.k_sf)	// merge them into the key

	if (!a_acc) {

		/* put neutrals if 'accidental cancel' */
		if (s.fmt.cancelkey || s.k_sf == 0) {

			/* when flats to sharps, or sharps to flats, */
			if (s.k_sf == 0
			 || old_sf * s.k_sf < 0) {

				/* old sharps */
				shift = sharp_cl[clef_ix];
				p_seq = shift > 9 ? sharp1 : sharp2
				for (i = 0; i < old_sf; i++) {
					xygl(x, staffb + shift, "acc3");
					shift += p_seq[i];
					x += 5.5
				}

				/* old flats */
				shift = flat_cl[clef_ix];
				p_seq = shift < 18 ? flat1 : flat2
				for (i = 0; i > old_sf; i--) {
					xygl(x, staffb + shift, "acc3");
					shift += p_seq[-i];
					x += 5.5
				}
				if (s.k_sf != 0)
					x += 3		/* extra space */
			}
		}

		/* new sharps */
		if (s.k_sf > 0) {
			shift = sharp_cl[clef_ix];
			p_seq = shift > 9 ? sharp1 : sharp2
			for (i = 0; i < s.k_sf; i++) {
				xygl(x, staffb + shift, "acc1");
				shift += p_seq[i];
				x += 5.5
			}
			if (s.fmt.cancelkey && i < old_sf) {
				x += 2
				for (; i < old_sf; i++) {
					xygl(x, staffb + shift, "acc3");
					shift += p_seq[i];
					x += 5.5
				}
			}
			if (s.k_bagpipe == 'p') {	// K:Hp - add the g natural
				xygl(x, staffb + 27, "acc3")
				x += 5.5
			}
		}

		/* new flats */
		if (s.k_sf < 0) {
			shift = flat_cl[clef_ix];
			p_seq = shift < 18 ? flat1 : flat2
			for (i = 0; i > s.k_sf; i--) {
				xygl(x, staffb + shift, "acc-1");
				shift += p_seq[-i];
				x += 5.5
			}
			if (s.fmt.cancelkey && i > old_sf) {
				x += 2
				for (; i > old_sf; i--) {
					xygl(x, staffb + shift, "acc3");
					shift += p_seq[-i];
					x += 5.5
				}
			}
		}
	} else if (a_acc.length) {

		/* explicit accidentals */
		var	acc,
			last_acc = a_acc[0].acc,
			last_shift = 100,
			s2 = {
				st: st,
				nhd: 0,
				notes: [{}]
			}

		for (i = 0; i < a_acc.length; i++) {
			acc = a_acc[i];
			shift = (s.k_y_clef	// clef shift
				+ acc.pit - 18) * 3
			while (shift < -3)		// let the accidentals inside the staff
				shift += 21
			while (shift > 27)
				shift -= 21
			if (i != 0
			 && (shift > last_shift + 18
			  || shift < last_shift - 18))
				x -= 5.5		// no clash
			else if (acc.acc != last_acc)
				x += 3;
			last_acc = acc.acc;
			s2.x = x
			s2.notes[0].pit = shift / 3 + 18;
// is this useful?
//			s2.head = C.FULL
//			s2.notes[0].shhd = 0
//			self.draw_hl(s2)
			last_shift = shift;
			draw_acc(x, staffb + shift, acc.acc)
			x += 5.5
		}
	}
}

// output the measure repeat number
function nrep_out(x, y, n) {
	y -= 3
	if (n < 10) {
		xygl(x - 4, y, "mtr" + n)
	} else {
		xygl(x - 10, y, "mtr" + ((n / 10) | 0))
		xygl(x - 2, y, "mtr" + (n % 10))
	}
} // nrep_out()

// if rest alone in the measure or measure repeat,
// change the head and center
function center_rest(s) {
    var	s2, x
	
	if (s.dur < C.BLEN * 2)
		s.nflags = -2		// semibreve / whole
	else if (s.dur < C.BLEN * 4)
		s.nflags = -3
	else
		s.nflags = -4
	s.dots = 0

	/* don't use next/prev: there is no bar in voice overlay */
	s2 = s.ts_next
	while (s2.time != s.time + s.dur
	    && s2.ts_next)
		s2 = s2.ts_next
	x = s2.x - s2.wl
	s2 = s
	while (!s2.seqst)
		s2 = s2.ts_prev
	s2 = s2.ts_prev
	x = (x + s2.x + s2.wr) / 2

	/* center the associated decorations */
	if (s.a_dd)
		deco_update(s, x - s.x)
	s.x = x
} // center_rest()

/* -- draw a rest -- */
/* (the staves are defined) */
var rest_tb = [
	"r128", "r64", "r32", "r16", "r8",
	"r4",
	"r2", "r1", "r0", "r00"]

function draw_rest(s) {
    var	s2, i, j, y, bx,
	p_staff = staff_tb[s.st],
	yb = p_staff.y,			// bottom of staff
	x = s.x

	if (s.notes[0].shhd)
		x += s.notes[0].shhd * stv_g.scale

	if (s.rep_nb) {
		set_sscale(s.st);
		anno_start(s);
		if (p_staff.stafflines == '|||||')
			yb += 12
		else
			yb += (p_staff.topbar + p_staff.botbar) / 2
		if (s.rep_nb < 0) {
			xygl(x, yb, "srep")
		} else {
			xygl(x, yb, "mrep")
			if (s.rep_nb > 2 && s.v == cur_sy.top_voice
			 && s.fmt.measrepnb > 0
			 && !(s.rep_nb % s.fmt.measrepnb))
				nrep_out(x, yb + p_staff.topbar, s.rep_nb)
		}
		anno_a.push(s)
		return
	}

	set_scale(s);
	anno_start(s);

	if (s.notes[0].color)
		set_color(s.notes[0].color);

	y = s.y;

	i = 5 - s.nflags		/* rest_tb index (5 = C_XFLAGS) */
	if (i == 7 && y == 12
	 && p_staff.stafflines.length <= 2)
		y -= 6				/* semibreve a bit lower */

	// draw the rest
	if (!s.notes[0].invis)		// if not head replacement
		xygl(x, y + yb, rest_tb[i])

	if (s.dots) {
		x += 8;
		y += yb + 3
		j = s.dots
		i = (s.dur_orig / 12) >> ((5 - s.nflags) - j)
		while (j-- > 0) {
			xygl(x, y, (i & (1 << j)) ? "dot" : "dot+")
			x += 3.5
		}
	}
	set_color();
	anno_a.push(s)
}

// -- draw a multi-measure rest --
// (the staves are defined)
function draw_mrest(s) {
    var	x1, x2, s2,
	p_st = staff_tb[s.st],
	y = p_st.y + (p_st.topbar + p_st.botbar) / 2,
	p = s.nmes.toString()

	// output an old multimeasure rest
	function omrest() {
	    var	x = s.x,
		y = p_st.y + 12,
		n = s.nmes,
		k = n >> 2			// number of rests

		if (n & 3) {
			k++
			if (n & 3 == 3)
				k++
		}
//dx = 6
		x -= 3 * (k - 1)
		while (n >= 4) {
			xygl(x, y, "r00")
			n -= 4
			x += 6
		}
		if (n >= 2) {
			xygl(x, y, "r0")
			n -= 2
			x += 6
		}
		if (n)
			xygl(x + 2, y, "r1")
	} // omrest()

	set_scale(s)

	s2 = s			// search the start of the previous time sequence
	while (!s2.seqst)
		s2 = s2.ts_prev
	s2 = s2.ts_prev
	while (!s2.seqst)
		s2 = s2.ts_prev
	x1 = s2.x + 20

	s2 = s.ts_next		// search the next symbol on the same staff
	if (s2.staff != s.staff)
		s2 = s.next
	x2 = s2.x - 20

	s.x = (x1 + x2) / 2
	anno_start(s)
	if (!cfmt.oldmrest || s.nmes > cfmt.oldmrest) {
		out_XYAB('<path d="mX Y', x1 + .6, y - 2.7)
		output += 'v2.7h-1.4v-10.8h1.4v2.7h'
			+ ((x2 - x1 - 2.8) / stv_g.scale).toFixed(1)
			+ 'v-2.7h1.4v10.8h-1.4v-2.7z"/>\n'
	} else {
		omrest()		// old multirest
	}
    if (s.tacet)
	out_XYAB('<text x ="X" y="Y" style="font-size:12px;font-weight:700"\
 text-anchor="middle">A</text>\n',
		s.x, y + 18, s.tacet)
    else
	out_XYAB('<text x ="X" y="Y" text-anchor="middle">A</text>\n',
		s.x, y + 22, m_gl(p))
	anno_a.push(s)
} // draw_mrest()

function grace_slur(s) {
    var	yy, x0, y0, x3, y3, bet1, bet2, dy1, dy2, last, below,
	so = s,
	g = s.extra

	while (1) {
		if (!g.next)
			break			/* (keep the last note) */
		g = g.next
	}
	last = g

	below = ((g.stem >= 0 || s.multi < 0) && g.notes[0].pit <= 28)
			|| g.notes[0].pit < 16
	if (below) {
		yy = 127
		for (g = s.extra; g; g = g.next) {
			if (g.y < yy) {
				yy = g.y;
				last = g
			}
		}
		x0 = last.x;
		y0 = last.y - 5
		if (s.extra != last) {
			x0 -= 4;
			y0 += 1
		}
		s = s.next;
		x3 = s.x - 1
		if (s.stem < 0 && s.nflags > -2)
			x3 -= 4;
		y3 = 3 * (s.notes[0].pit - 18) - 5;
		dy1 = (x3 - x0) * .4
		if (dy1 > 3)
			dy1 = 3;
		dy2 = dy1;
		bet1 = .2;
		bet2 = .8
		if (y0 > y3 + 7) {
			x0 = last.x - 1;
			y0 += .5;
			y3 += 6.5;
			x3 = s.x - 5.5;
			dy1 = (y0 - y3) * .8;
			dy2 = (y0 - y3) * .2;
			bet1 = 0
		} else if (y3 > y0 + 4) {
			y3 = y0 + 4;
			x0 = last.x + 2;
			y0 = last.y - 4
		}
	} else {				// slur above
		yy = -127
		for (g = s.extra; g; g = g.next) {
			if (g.y > yy) {
				yy = g.y;
				last = g
			}
		}
		x0 = last.x;
		y0 = last.y + 5
		if (s.extra != last) {
			x0 -= 4;
			y0 -= 1
		}
		s = s.next;
		x3 = s.x - 1
		if (s.stem >= 0 && s.nflags > -2)
			x3 -= 2;
		y3 = 3 * (s.notes[s.nhd].pit - 18) + 5;
		dy1 = (x0 - x3) * .4
		if (dy1 < -3)
			dy1 = -3;
		dy2 = dy1;
		bet1 = .2;
		bet2 = .8
		if (y0 < y3 - 7) {
			x0 = last.x - 1;
			y0 -= .5;
			y3 -= 6.5;
			x3 = s.x - 5.5;
			dy1 = (y0 - y3) * .8;
			dy2 = (y0 - y3) * .2;
			bet1 = 0
		} else if (y3 < y0 - 4) {
			y3 = y0 - 4;
			x0 = last.x + 2;
			y0 = last.y + 4
		}
	}

	so.slur = {
		x0: x0,
		y0: y0,
		x1: bet1 * x3 + (1 - bet1) * x0 - x0,
		y1: y0 - bet1 * y3 - (1 - bet1) * y0 + dy1,
		x2: bet2 * x3 + (1 - bet2) * x0 - x0,
		y2: y0 - bet2 * y3 - (1 - bet2) * y0 + dy2,
		x3: x3 - x0,
		y3: y0 - y3
	}
	y0 -= so.slur.y1
	g = so.extra
//fixme: useless?
//	y_set(s.st, !below, x0, x3 - x0, y0)
	if (below) {
		if (y0 < g.ymn)
			g.ymn = y0
	} else {
		if (y0 > g.ymx)
			g.ymx = y0
	}
} // grace_slur()

/* -- draw grace notes -- */
/* (the staves are defined) */
function draw_gracenotes(s) {
    var	x1, y1,
	last, note,
	bm = {},
	g = s.extra

	/* draw the notes */
//	bm.s2 = undefined			/* (draw flags) */
	while (1) {
		if (g.beam_st && !g.beam_end) {
			if (self.calculate_beam(bm, g))
				draw_beams(bm)
		}
		anno_start(g)
		draw_note(g, !bm.s2)
		if (g == bm.s2)
			bm.s2 = null			/* (draw flags again) */
		anno_a.push(s)
//		if (g.sls || g.sl2)
//			slur = true
		if (!g.next)
			break			/* (keep the last note) */
		g = g.next
	}
	last = g

	// if an acciaccatura, draw a bar 
	if (s.sappo) {
		g = s.extra
		if (!g.next) {			/* if one note */
			x1 = 9
			y1 = g.stem > 0 ? 5 : -5
		} else {			/* many notes */
			x1 = (g.next.x - g.x) * .5 + 4
			y1 = (g.ys + g.next.ys) * .5 - g.y
			if (g.stem > 0)
				y1 -= 1
			else
				y1 += 1
		}
		note = g.notes[g.stem < 0 ? 0 : g.nhd]
		out_acciac(g.x, y_head(g, note),
				x1, y1, g.stem > 0)
	}

	/* slur */
	g = s.slur
	if (g) {
		anno_start(s, 'slur')
		xypath(g.x0, g.y0 + staff_tb[s.st].y)
		output += 'c' + g.x1.toFixed(1) + ' ' + g.y1.toFixed(1) +
			' ' + g.x2.toFixed(1) + ' ' + g.y2.toFixed(1) +
			' ' + g.x3.toFixed(1) + ' ' + g.y3.toFixed(1) + '"/>\n'
		anno_stop(s, 'slur')
	}
}

/* -- set the y offset of the dots -- */
function setdoty(s, y_tb) {
	var m, m1, y

	/* set the normal offsets */
	for (m = 0; m <= s.nhd; m++) {
		y = 3 * (s.notes[m].pit - 18)	/* note height on staff */
		if ((y % 6) == 0) {
			if (s.dot_low)
				y -= 3
			else
				y += 3
		}
		y_tb[m] = y
	}
	/* dispatch and recenter the dots in the staff spaces */
	for (m = 0; m < s.nhd; m++) {
		if (y_tb[m + 1] > y_tb[m])
			continue
		m1 = m
		while (m1 > 0) {
			if (y_tb[m1] > y_tb[m1 - 1] + 6)
				break
			m1--
		}
		if (3 * (s.notes[m1].pit - 18) - y_tb[m1]
				< y_tb[m + 1] - 3 * (s.notes[m + 1].pit - 18)) {
			while (m1 <= m)
				y_tb[m1++] -= 6
		} else {
			y_tb[m + 1] = y_tb[m] + 6
		}
	}
}

// get the y offset of a note head
// (when the staves are defined)
function y_head(s, note) {
	return staff_tb[s.st].y + 3 * (note.pit - 18)
}

/* -- draw m-th head with accidentals and dots -- */
/* (the staves are defined) */
// sets {x,y}_note
function draw_basic_note(s, m, y_tb) {
    var	i, p, yy, dotx, doty, inv, head, dots, nflags,
		old_color = false,
		note = s.notes[m],
		staffb = staff_tb[s.st].y,	/* bottom of staff */
	x = s.x,
		y = 3 * (note.pit - 18),	/* note height on staff */
		shhd = note.shhd * stv_g.scale,
		x_note = x + shhd,
		y_note = y + staffb

//	/* special case for voice unison */
//	if (s.nohdi1 != undefined
//	 && m >= s.nohdi1 && m < s.nohdi2)
//		return

	if (note.dur == s.dur) {
		head = s.head
		dots = s.dots
		nflags = s.nflags
	} else {
		i = identify_note(s, note.dur)
		head = i[0]
		dots = i[1]
		nflags = i[2]
	}

	/* draw the head */
	if (note.invis) {
		;
	} else if (note.map && note.map[0]) {
		i = head;
		p = note.map[0][i]		// heads
		if (!p)
			p = note.map[0][note.map[0].length - 1]
		i = p.indexOf('/')
		if (i >= 0) {			// stem dependant
			if (s.stem >= 0)
				p = p.slice(0, i)
			else
				p = p.slice(i + 1)
		}
	} else if (s.type == C.CUSTOS) {
		p = "custos"
	} else {
		switch (head) {
		case C.OVAL:
			p = "HD"
			break
		case C.OVALBARS:
			if (s.head != C.SQUARE) {
				p = "HDD"
				break
			}
			// fall thru
		case C.SQUARE:
			if (nflags > -4) {
				p = "breve"
			} else {
				p = "longa"
				inv = s.stem > 0
			}

			/* don't display dots on last note of the tune */
			if (!tsnext && s.next
			 && s.next.type == C.BAR && !s.next.next)
				dots = 0
			x_note += 1
			break
		case C.EMPTY:
			p = "Hd"		// white note
			break
		default:			// black note
			p = "hd"
			break
		}
	}
	if (note.color != undefined)
		old_color = set_color(note.color)
	if (p) {
		if (s.grace || inv) {
			if (s.grace)
				g_open(x_note, y_note, 0, .66, 0)
			else
				g_open(x_note, y_note, 0, 1, -1)
			x_note = y_note = 0
		}
		if (!self.psxygl(x_note, y_note, p))
			xygl(x_note, y_note, p)
		if (s.grace || inv)
			g_close()
	}

	/* draw the dots */
/*fixme: to see for grace notes*/
	// (s.dots may be removed in tablatures - see strtab)
	if (dots && (s.dots || note.dur != s.dur)) {
		dotx = x + (6.6 + s.xmx) * stv_g.scale
		if (y_tb[m] == undefined) {
			y_tb[m] = 3 * (s.notes[m].pit - 18)
			if ((s.notes[m].pit & 1) == 0)
				y_tb[m] += 3
		}
		doty = y_tb[m] + staffb
		i = (note.dur / 12) >> ((5 - nflags) - dots)
		while (dots-- > 0) {
			xygl(dotx, doty, (i & (1 << dots)) ? "dot" : "dot+")
			dotx += 3.5
		}
	}

	/* draw the accidental */
	if (note.acc) {
		x -= note.shac * stv_g.scale
		if (!s.grace) {
			draw_acc(x, y + staffb, note.acc)
		} else {
			g_open(x, y + staffb, 0, .75);
			draw_acc(0, 0, note.acc)
			g_close()
		}
	}
	if (old_color != false)
		set_color(old_color)
}

/* -- draw a note or a chord -- */
/* (the staves are defined) */
function draw_note(s,
		   fl) {		// draw flags
    var	s2, i, m, y, slen, c, nflags,
	y_tb = new Array(s.nhd + 1),
	note = s.notes[s.stem < 0 ? s.nhd : 0],	// master note head
	x = s.x,
	x_st = s.x + note.shhd * stv_g.scale,
	y = y_head(s, note),
	staffb = staff_tb[s.st].y

	if (s.dots)
		setdoty(s, y_tb)

	/* draw the stem and flags */
	if (!s.stemless) {
		slen = s.ys - s.y;
		nflags = s.nflags
		if (s.ntrem)
			nflags -= s.ntrem
		if (!fl || nflags <= 0) {	/* stem only */
			if (s.nflags > 0) {	/* (fix for PS low resolution) */
				if (s.stem >= 0)
					slen -= 1
				else
					slen += 1
			}
			out_stem(x_st, y, slen, s.grace)
		} else {				/* stem and flags */
			out_stem(x_st, y, slen, s.grace,
				 nflags, s.fmt.straightflags)
		}
	} else if (s.xstem) {				/* cross-staff stem */
		s2 = s.ts_prev;
		slen = (s2.stem > 0 ? s2.y : s2.ys) - s.y;
		slen += staff_tb[s2.st].y - staffb;
		out_stem(x_st, y, slen)
	}

	/* draw the tremolo bars */
	if (fl && s.trem1) {
		var	ntrem = s.ntrem || 0,
			x1 = x;
		slen = 3 * (s.notes[s.stem > 0 ? s.nhd : 0].pit - 18)
		if (s.head == C.FULL || s.head == C.EMPTY) {
			x1 += (s.grace ? GSTEM_XOFF : 3.5) * s.stem
			if (s.stem > 0)
				slen += 6 + 5.4 * ntrem
			else
				slen -= 6 + 5.4
		} else {
			if (s.stem > 0)
				slen += 5 + 5.4 * ntrem
			else
				slen -= 5 + 5.4
		}
		slen /= s.p_v.scale;
		out_trem(x1, staffb + slen, ntrem)
	}

	/* draw the note heads */
	for (m = 0; m <= s.nhd; m++)
		draw_basic_note(s, m, y_tb)
}

// find where to start a long decoration
function prev_scut(s) {
	while (s.prev) {
		s = s.prev
		if (s.rbstart)
			return s
	}

	/* return a symbol of any voice starting before the start of the voice */
	s = s.p_v.sym
	while (s.type != C.CLEF)
		s = s.ts_prev		/* search a main voice */
	if (s.next && s.next.type == C.KEY)
		s = s.next
	if (s.next && s.next.type == C.METER)
		return s.next
	return s
}

/* -- decide whether a slur goes up or down (same voice) -- */
function slur_direction(k1, k2) {
    var	s, some_upstem, low, dir

	// check if slur sequence in a multi-voice staff
	function slur_multi(s1, s2) {
//		while (1) {
//			if (s1.multi)		// if multi voice
//				//fixme: may change
//				return s1.multi
//			if (s1 == s2)
//				break
//			s1 = s1.next
//		}
		if (s1.multi)
			return s1.multi
		if (s2.multi)
			return s2.multi
		return 0
	} // slur_multi()

	if (k1.grace && k1.stem > 0)
		return -1

	dir = slur_multi(k1, k2)
	if (dir)
		return dir

	for (s = k1; ; s = s.next) {
		if (s.type == C.NOTE) {
			if (!s.stemless) {
				if (s.stem < 0)
					return 1
				some_upstem = true
			}
			if (s.notes[0].pit < 22)	/* if under middle staff */
				low = true
		}
//		if (s == k2)
		if (s.time == k2.time)		// (k2 may be a grace note)
			break
	}
	if (!some_upstem && !low)
		return 1
	return -1
}

/* -- output a slur / tie -- */
function slur_out(x1, y1, x2, y2, dir, height, dotted) {
	var	dx, dy, dz,
		alfa = .3,
		beta = .45;

	/* for wide flat slurs, make shape more square */
	dy = y2 - y1
	if (dy < 0)
		dy = -dy;
	dx = x2 - x1
	if (dx > 40. && dy / dx < .7) {
		alfa = .3 + .002 * (dx - 40.)
		if (alfa > .7)
			alfa = .7
	}

	/* alfa, beta, and height determine Bezier control points pp1,pp2
	 *
	 *           X====alfa===|===alfa=====X
	 *	    /		 |	       \
	 *	  pp1		 |	        pp2
	 *	  /	       height		 \
	 *	beta		 |		 beta
	 *      /		 |		   \
	 *    p1		 m		     p2
	 *
	 */

	var	mx = .5 * (x1 + x2),
		my = .5 * (y1 + y2),
		xx1 = mx + alfa * (x1 - mx),
		yy1 = my + alfa * (y1 - my) + height;
	xx1 = x1 + beta * (xx1 - x1);
	yy1 = y1 + beta * (yy1 - y1)

	var	xx2 = mx + alfa * (x2 - mx),
		yy2 = my + alfa * (y2 - my) + height;
	xx2 = x2 + beta * (xx2 - x2);
	yy2 = y2 + beta * (yy2 - y2);

//	dy = 1.6 * dir
	dy = 2 * dir;
	dz = .2 + .001 * dx
	if (dz > .6)
		dz = .6;
	dz *= dir
	dx *= .03
//	if (dx > 10.)
//		dx = 10.

//	var scale_y = stv_g.st < 0 ? stv_g.scale : 1
	var scale_y = 1			// (see set_dscale())
	if (!dotted)
		output += '<path d="M'
	else
		output += '<path class="stroke" stroke-dasharray="5,5" d="M';
	out_sxsy(x1, ' ', y1);
	output += 'c' +
		((xx1 - x1) / stv_g.scale).toFixed(1) + ' ' +
		((y1 - yy1) / scale_y).toFixed(1) + ' ' +
		((xx2 - x1) / stv_g.scale).toFixed(1) + ' ' +
		((y1 - yy2) / scale_y).toFixed(1) + ' ' +
		((x2 - x1) / stv_g.scale).toFixed(1) + ' ' +
		((y1 - y2) / scale_y).toFixed(1)

	if (!dotted)
		output += '\n\tv' +
			(-dz).toFixed(1) + 'c' +
			((xx2 - dx - x2) / stv_g.scale).toFixed(1) + ' ' +
			((y2 + dz - yy2 - dy) / scale_y).toFixed(1) + ' ' +
			((xx1 + dx - x2) / stv_g.scale).toFixed(1) + ' ' +
			((y2 + dz - yy1 - dy) / scale_y).toFixed(1) + ' ' +
			((x1 - x2) / stv_g.scale).toFixed(1) + ' ' +
			((y2 - y1) / scale_y).toFixed(1)
	output += '"/>\n'
}

// draw a slur between two chords / notes
/* (the staves are not yet defined) */
/* (delayed output) */
/* (not a pretty routine, this) */
function draw_slur(path,	// list of symbols under the slur
		   sl,		// slur variables: type, end symbol, note
		   recurr) {	// recurrent call when slur on two staves
    var	i,
	k, g, x1, y1, x2, y2, height, addy, s_st2,
	a, y, z, h, dx, dy,
	ty = sl.ty,
	dir = (ty & 0x07) == C.SL_ABOVE ? 1 : -1,
	n = path.length,
	i1 = 0,
	i2 = n - 1,
	not1 = sl.nts,		// if the slur starts on a note
	k1 = path[0],
	k2 = path[i2],
	nn = 1

	set_dscale(k1.st)

	for (i = 1; i < n; i++) {
		k = path[i]
		if (k.type == C.NOTE || k.type == C.REST) {
			nn++
			if (k.st != k1.st
			 && !s_st2)
				s_st2 = k
		}
	}

	// if slur on 2 staves, define it, but don't output it now
	// this will be done in draw_sl2()
	if (s_st2 && !recurr) {			// if not 2nd call to draw_slur()
		if (!gene.a_sl)
			gene.a_sl = []

		// replace the symbols of the other staff
		// by symbols in the current staff but with updated y offsets
		h = 24 + k1.fmt.sysstaffsep		// delta y
		if (s_st2.st > k1.st)
			h = -h
		for (i = 0; i < n; i++) {
			k = path[i]
			if (k.st == k1.st) {
				if (k.dur)
					a = k		// (used for types // and \\)
				continue
			}
			k = clone(k)
			if (path[i] == s_st2)
				s_st2 = k
			path[i] = k
			if (k.dur) {
				k.notes = clone(k.notes)
				k.notes[0] = clone(k.notes[0])
				if (sl.ty & C.SL_CENTER) {
					if (k.st != a.st) {
						sl.ty = (sl.ty & ~0x07)
							 | (a.st < k.st
								? C.SL_BELOW
								: C.SL_ABOVE)
						z = k1.ymn
						h = k2.ymx
						if (k.st < a.st) {
							for (i1 = 1; i1 < i; i1++) {
								a = path[i1]
								if (a.ymn < z)
									z = a.ymn
							}
							for (i1 = i; i1 < i2; i1++) {
								a = path[i1]
								if (a.ymx > h)
									h = a.ymx
							}
						} else {
							for (i1 = 1; i1 < i; i1++) {
								a = path[i1]
								if (a.ymx > h)
									h = a.ymx
							}
							for (i1 = i; i1 < i2; i1++) {
								a = path[i1]
								if (a.ymn < z)
									z = a.ymn
							}
						}
						h += z
						a = k
					}
					k.y = h - k.y
					k.notes[0].pit = (k.y / 3 | 0) + 18
					k.ys = h - k.ys
					y = k.ymx
					k.ymx = h - k.ymn
					k.ymn = h - y
					k.stem = -k.stem
				} else {
					k.notes[0].pit += h / 3 | 0
					k.ys += h
					k.y += h
					k.ymx += h
					k.ymn += h
				}
			}
//			k.st = k1.st	// keep the staff number for draw_sl2()
		}

		ty = k1.st > s_st2.st ? '/' : '\\'
		if (sl.ty & C.SL_CENTER)
			ty = ty + ty			// type = // or \\
		else if (k1.st == k2.st)
			ty = ty == '/' ? '/\\' : '\\/'	// type = /\ or \/
		else
			ty += dir > 0 ? '+' : '-'	// type = .+ or .-

	    var	savout = output
		output = ""
		draw_slur(path, sl, 1 /*true*/)
		gene.a_sl.push([k1, s_st2, ty, output])
		output = savout
		return
	}

	/* fix endpoints */
	x1 = k1.x
	if (k1.notes && k1.notes[0].shhd)
		x1 += k1.notes[0].shhd;
	x2 = k2.x
	if (k2.notes)
		x2 += k2.notes[0].shhd

	if (not1) {					// start on a note
		y1 = 3 * (not1.pit - 18) + 2 * dir
		x1 += 3
	} else {					// start on a chord
		y1 = dir > 0 ? k1.ymx + 2 : k1.ymn - 2
		if (k1.type == C.NOTE) {
			if (dir > 0) {
				if (k1.stem > 0) {
					x1 += 5
					if (k1.beam_end
					 && k1.nflags >= -1	/* if with a stem */
//fixme: check if at end of tuplet
					 && !k1.in_tuplet) {
						if (k1.nflags > 0) {
							x1 += 2;
							y1 = k1.ys - 3
						} else {
							y1 = k1.ys - 6
						}
					} else {
						y1 = k1.ys + 3
					}
				} else {
					y1 = k1.y + 8
				}
			} else {
				if (k1.stem < 0) {
					x1 -= 1
					if (k2.grace) {
						y1 = k1.y - 8
					} else if (k1.beam_end
						&& k1.nflags >= -1
						&& (!k1.in_tuplet
						 || k1.ys < y1 + 3)) {
						if (k1.nflags > 0) {
							x1 += 2;
							y1 = k1.ys + 3
						} else {
							y1 = k1.ys + 6
						}
					} else {
						y1 = k1.ys - 3
					}
				} else {
					y1 = k1.y - 5
				}
			}
		}
	}

	if (sl.nte) {					// slur ending on a note
		y2 = 3 * (sl.nte.pit - 18) + 2 * dir
		x2 -= 3
	} else {					// end on a chord
		y2 = dir > 0 ? k2.ymx + 2 : k2.ymn - 2
		if (k2.type == C.NOTE) {
			if (dir > 0) {
				if (k2.stem > 0) {
					x2 += 1
					if (k2.beam_st
					 && k2.nflags >= -1
					 && !k2.in_tuplet)
						y2 = k2.ys - 6
					else
						y2 = k2.ys + 3
				} else {
					y2 = k2.y + 8
				}
			} else {
				if (k2.stem < 0) {
					x2 -= 5
					if (k2.beam_st
					 && k2.nflags >= -1
					 && !k2.in_tuplet)
//						|| k2.ys < y2 + 3))
						y2 = k2.ys + 6
					else
						y2 = k2.ys - 3
				} else {
					y2 = k2.y - 5
				}
			}
		}
	}

	if (k1.type != C.NOTE) {
		y1 = y2 + 1.2 * dir;
		x1 = k1.x + k1.wr * .5
		if (x1 > x2 - 12)
			x1 = x2 - 12
	}

	if (k2.type != C.NOTE) {
		if (k1.type == C.NOTE)
			y2 = y1 + 1.2 * dir
		else
			y2 = y1
		if (k1 != k2)
			x2 = k2.x - k2.wl * .3
	}

	if (nn >= 3) {
		k = path[1]
		if (k.type != C.BAR
		 && k.x < x1 + 48) {
			if (dir > 0) {
				y = k.ymx - 2
				if (y1 < y)
					y1 = y
			} else {
				y = k.ymn + 2
				if (y1 > y)
					y1 = y
			}
		}
		k = path[i2 - 1]
		if (k.type != C.BAR
		 && k.x > x2 - 48) {
			if (dir > 0) {
				y = k.ymx - 2
				if (y2 < y)
					y2 = y
			} else {
				y = k.ymn + 2
				if (y2 > y)
					y2 = y
			}
		}
	}

	a = (y2 - y1) / (x2 - x1)		/* slur steepness */
	if (a > SLUR_SLOPE || a < -SLUR_SLOPE) {
		a = a > SLUR_SLOPE ? SLUR_SLOPE : -SLUR_SLOPE
		if (a * dir > 0)
			y1 = y2 - a * (x2 - x1)
		else
			y2 = y1 + a * (x2 - x1)
	}

	/* for big vertical jump, shift endpoints */
	y = y2 - y1
	if (y > 8)
		y = 8
	else if (y < -8)
		y = -8
	z = y
	if (z < 0)
		z = -z;
	dx = .5 * z;
	dy = .3 * y
	if (y * dir > 0) {
		x2 -= dx;
		y2 -= dy
	} else {
		x1 += dx;
		y1 += dy
	}

	/* special case for grace notes */
	if (k1.grace)
		x1 = k1.x - GSTEM_XOFF * .5
	if (k2.grace)
		x2 = k2.x + GSTEM_XOFF * .5

	h = 0;
	a = (y2 - y1) / (x2 - x1)
	if (k1 != k2
	 && k1.v == k2.v) {
	    addy = y1 - a * x1
	    for (i = 1; i < i2; i++) {
		k = path[i]
		switch (k.type) {
		case C.NOTE:
		case C.REST:
			if (dir > 0) {
				y = 3 * (k.notes[k.nhd].pit - 18) + 6
				if (y < k.ymx)
					y = k.ymx;
				y -= a * k.x + addy
				if (y > h)
					h = y
			} else {
				y = 3 * (k.notes[0].pit - 18) - 6
				if (y > k.ymn)
					y = k.ymn;
				y -= a * k.x + addy
				if (y < h)
					h = y
			}
			break
		case C.GRACE:
			for (g = k.extra; g; g = g.next) {
				if (dir > 0) {
//					y = 3 * (g.notes[g.nhd].pit - 18) + 6
//					if (y < g.ymx)
						y = g.ymx;
					y -= a * g.x + addy
					if (y > h)
						h = y
				} else {
//					y = 3 * (g.notes[0].pit - 18) - 6
//					if (y > g.ymn)
						y = g.ymn;
					y -= a * g.x + addy
					if (y < h)
						h = y
				}
			}
			break
		}
	    }
	    y1 += .45 * h;
	    y2 += .45 * h;
	    h *= .65
	}

	if (nn > 3)
		height = (.08 * (x2 - x1) + 12) * dir
	else
		height = (.03 * (x2 - x1) + 8) * dir
	if (dir > 0) {
		if (height < 3 * h)
			height = 3 * h
		if (height > 40)
			height = 40
	} else {
		if (height > 3 * h)
			height = 3 * h
		if (height < -40)
			height = -40
	}

	y = y2 - y1
	if (y < 0)
		y = -y
	if (dir > 0) {
		if (height < .8 * y)
			height = .8 * y
	} else {
		if (height > -.8 * y)
			height = -.8 * y
	}
	height *= k1.fmt.slurheight;

//	anno_start(k1_o, 'slur');
	slur_out(x1, y1, x2, y2, dir, height, ty & C.SL_DOTTED);
//	anno_stop(k1_o, 'slur');

	/* have room for other symbols */
	dx = x2 - x1;
	a = (y2 - y1) / dx;
/*fixme: it seems to work with .4, but why?*/
//	addy = y1 - a * x1 + .4 * height
//fixme: the following code seems better!
	addy = y1 - a * x1
	if (height > 0)
		addy += 3 * Math.sqrt(height) - 2
	else
		addy -= 3 * Math.sqrt(-height) - 2
	for (i = 0; i <= i2; i++) {
		k = path[i]
		if (k.st != k1.st || k.type == C.BAR)
			continue
		y = a * k.x + addy
		if (k.ymx < y)
			k.ymx = y
		else if (k.ymn > y)
			k.ymn = y
		if (recurr)			// no room when slur on 2 staves
			continue
		if (i == i2) {
			dx = x2
			if (sl.nte)
				dx -= 5;
		} else {
			dx = k.x + k.wr
		}
		if (i != 0)
			x1 = k.x
		if (!i || i == i2)
			y -= height / 3
		dx -= x1 - k.wl
		y_set(k1.st, dir > 0, x1 - k.wl, dx, y)
	}
}

/* -- draw the slurs between 2 symbols --*/
function draw_slurs(s, last) {
    var	gr1, i, m, note, sls, nsls

	// draw a slur knowing the start and stop elements
	function draw_sls(s,		// start symbol
			sl) {		// slur variables
	    var	k, v, i, dir, s3,
		path = [],
		s2 = sl.se			// slur end

		if (last && s2.time > last.time)
			return			// will be drawn next time

		// handle slurs without start or end
		switch (sl.loc) {
		case 'i':			// no start
			s = prev_scut(s)
			break
		case 'o':			// no end
			for (s3 = gr1 || s; s3.ts_next; s3 = s3.ts_next)
				;
			s2 = s3
			for (; s3; s3 = s3.ts_prev) {
				if (s3.v == s.v) {
					s2 = s3
					break
				}
				if (s3.st == s.st)
					s2 = s3
				if (s3.ts_prev.time != s2.time)
					break
			}
			break
		}

		// if the slur continues on the next music line,
		// stop it at the end of the current line
		if (s.p_v.s_next && s2.time >= tsnext.time) {
		  if (s2.time == tsnext.time) {
		    if (s2.grace) {
			for (s3 = tsnext; s3 && s3.time == s2.time; s3 = s3.ts_next) {
				if (s3.type == C.GRACE) {
					s3 = null
					break
				}
			}
		    } else {
			for (s3 = tsnext; s3.time == s2.time; s3 = s3.ts_next) {
				if (s3 == s2) {
					s3 = null	// end of slur in next line
					break
				}
			}
		    }
		  } else {
			s3 = null
		  }
		    if (!s3) {
			s.p_v.sls.push(sl);		// continuation on next line
			s2 = s.p_v.s_next.prev		// one voice
			while (s2.next)
				s2 = s2.next;		// search the ending bar
			sl = Object.create(sl);		// new slur
		    }
		}

		// set the slur position
		switch (sl.ty & 0x07) {
		case C.SL_ABOVE: dir = 1; break
		case C.SL_BELOW: dir = -1; break
		default:
			dir = s.v != s2.v ?
				1 :		// always above ?
				slur_direction(s, s2)
			sl.ty &= ~0x07
			sl.ty |= dir > 0 ? C.SL_ABOVE : C.SL_BELOW
			break
		}

		// build the path of the symbols under the slur
		if (s.v == s2.v) {
			v = s.v
		} if (!cur_sy.voices[s.v] || !cur_sy.voices[s2.v]) {
			v = s.v > s2.v ? s.v : s2.v
		} else if (dir *			// if slur on first voice
			(cur_sy.voices[s.v].range <= cur_sy.voices[s2.v].range ?
				1 : -1) > 0)
			v = s.v
		else
			v = s2.v

		if (gr1				// if start on a grace note
		 && !(s2.grace			// and not end in the same
		   && s.v == s2.v		// grace note sequence
		   && s.time == s2.time)) {
			do {
				path.push(s);	// add all grace notes
				s = s.next
			} while (s);
			s = gr1.next
		} else {
			path.push(s);
			if (s.grace)
				s = s.next
			else
				s = s.ts_next
		}

		if (!s2.grace) {		// if end on a normal note
			while (s) {
				if (s.v == v)
					path.push(s)
				if (s == s2)
					break
				s = s.ts_next
			}
		} else if (s.grace) {		// if start/end in the same sequence
			while (1) {
//				if (s.v == v)
					path.push(s)
				if (s == s2)
					break
				s = s.next
			}
		} else {			// end on a grace note
			k = s2
			while (k.prev)
				k = k.prev	// .extra pointer
			while (1) {
				if (s.v == v)
					path.push(s)
				if (s.extra == k)
					break
				s = s.ts_next
			}
			s = k
			while (1) {
				path.push(s)
				if (s == s2)
					break
				s = s.next
			}
		}

		// if some nested slurs/tuplets, draw them
		for (i = 1; i < path.length - 1; i++) {
			s = path[i]
			if (s.sls)
				draw_slurs(s, last)
			if (s.tp)
				draw_tuplet(s)
		}
		draw_slur(path, sl)
		return 1			// slur drawn, remove it
	} // draw_sls()

	// code of draw_slurs()
	while (1) {
		if (!s || s == last) {
			if (!gr1		// if end of grace notes
			 || !(s = gr1.next)	// return to normal notes
			 || s == last)
				break
			gr1 = null
		}
		if (s.type == C.GRACE) {	// if start of grace notes
			gr1 = s;		// continue in the grace note sequence
			s = s.extra
			continue
		}
		if (s.sls) {			// slurs from the chord
			sls = s.sls
			s.sls = null
			nsls = []
			for (i = 0; i < sls.length; i++) {
				if (!draw_sls(s, sls[i]))
					nsls.push(sls[i])
			}
			if (nsls.length)
				s.sls = nsls
		}
		s = s.next
	}
}

/* -- draw a tuplet -- */
/* (the staves are not yet defined) */
/* (delayed output) */
/* See http://moinejf.free.fr/abcm2ps-doc/tuplets.html
 * for the value of 'tp.f' */
function draw_tuplet(s1) {
    var	s2, s3, g, stu, std, nb_only,
	x1, x2, y1, y2, xm, ym, a, s0, yy, yx, dy, a, dir, r,
	tp = s1.tp.shift()		// tuplet parameters

	if (!s1.tp.length)
		delete s1.tp		// last tuplet

	// treat the slurs and the nested tuplets
	stu = std = s1.st
	for (s2 = s1; s2; s2 = s2.next) {
		switch (s2.type) {
		case C.GRACE:
			if (!s2.sl1)
				continue
			for (g = s2.extra; g; g = g.next) {
				if (g.sls)
					draw_slurs(g)
			}
			// fall thru
		default:
			continue
		case C.NOTE:
		case C.REST:
			break
		}
		if (s2.sls)
			draw_slurs(s2)
		if (s2.st < stu) {
			std = stu
			stu = s2.st
		} else if (s2.st > std) {
			std = s2.st
		}
		if (s2.tp)
			draw_tuplet(s2)
		if (s2.tpe)
			break
	}

	if (s2)
		s2.tpe--

	if (tp.f[0] == 1)		// if 'when' == never
		return			// accept tuplets on many lines

	if (!s2) {
		error(1, s1, "No end of tuplet in this music line")
		return
	}

	dir = tp.f[3]				// 'where'
	if (!dir) {				// if auto
		s3 = s1
		while (s3 && !s3.stem)		// (may have tuplets of rests!)
			s3 = s3.next
		dir = (s3 && s3.stem < 0) ? C.SL_BELOW : C.SL_ABOVE
	}
	set_dscale(dir == C.SL_ABOVE ? stu : std)

	if (s1 == s2				// tuplet with 1 note (!)
	 || tp.f[1] == 2) {			// what == nothing
		nb_only = true
	} else if (tp.f[1] == 1) {			/* 'what' == slur */
		nb_only = true;
		draw_slur([s1, s2], {ty: dir})
	} else {

		/* search if a bracket is needed */
		if (tp.f[0] != 2		// if 'when' != always
		 && s1.type == C.NOTE && s2.type == C.NOTE) {
			nb_only = true
			for (s3 = s1; ; s3 = s3.next) {
				if (s3.type != C.NOTE
				 && s3.type != C.REST) {
					if (s3.type == C.GRACE
					 || s3.type == C.SPACE)
						continue
					nb_only = false
					break
				}
				if (s3 == s2)
					break
				if (s3.beam_end) {
					nb_only = false
					break
				}
			}
			if (nb_only
			 && !s1.beam_st
			 && !s1.beam_br1
			 && !s1.beam_br2) {
				for (s3 = s1.prev; s3; s3 = s3.prev) {
					if (s3.type == C.NOTE
					 || s3.type == C.REST) {
						if (s3.nflags >= s1.nflags)
							nb_only = false
						break
					}
				}
			}
			if (nb_only && !s2.beam_end) {
				for (s3 = s2.next; s3; s3 = s3.next) {
					if (s3.type == C.NOTE
					 || s3.type == C.REST) {
						if (!s3.beam_br1
						 && !s3.beam_br2
						 && s3.nflags >= s2.nflags)
							nb_only = false
						break
					}
				}
			}
		}
	}

	/* if number only, draw it */
	if (nb_only) {
		if (tp.f[2] == 1)		/* if 'which' == none */
			return
		set_font("tuplet")
		xm = (s2.x + s1.x) / 2
		if (dir == C.SL_ABOVE)		// 8 = width around the middle
			ym = y_get(stu, 1, xm - 4, 8)
		else
			ym = y_get(std, 0, xm - 4, 8) -
					gene.curfont.size

		if (s1.stem * s2.stem > 0) {
			if (s1.stem > 0)
				xm += 4
			else
				xm -= 4
		}

		yy = ym + gene.curfont.size * .22
		if (tp.f[2] == 0)		// if 'which' == number
			xy_str(xm, yy, tp.p.toString(), 'c')
		else
			xy_str(xm, yy, tp.p + ':' + tp.q, 'c')

		for (s3 = s1; ; s3 = s3.next) {
			if (s3.x >= xm)
				break
		}
		if (dir == C.SL_ABOVE) {
			ym += gene.curfont.size
			if (s3.ymx < ym)
				s3.ymx = ym;
			y_set(stu, 1, xm - 3, 6, ym)
		} else {
			if (s3.ymn > ym)
				s3.ymn = ym;
			y_set(std, 0, xm - 3, 6, ym)
		}
		return
	}

	// here, 'what' is square bracket

/*fixme: two staves not treated*/
/*fixme: to optimize*/

	// first, get the x offsets
	x1 = s1.x - 4

	// end the bracket according to the last note duration
	if (s2.dur > s2.prev.dur) {
		s3 = s2.next
		if (!s3	// maybe a note in an overlay voice
		 || s3.time != s2.time + s2.dur) {
			for (s3 = s2.ts_next; s3; s3 = s3.ts_next) {
				if (s3.seqst
				 && s3.time >= s2.time + s2.dur)
					break
			}
		}
//fixme: s3 cannot be null (bar at end of staff)
		x2 = s3 ? s3.x - s3.wl - 5 : realwidth - 6
	} else {
		x2 = s2.x + 4
		r = s2.stem >= 0 ? 0 : s2.nhd
		if (s2.notes[r].shhd > 0)
			x2 += s2.notes[r].shhd
		if (s2.st == stu
		 && s2.stem > 0)
			x2 += 3.5
	}

    // above
    if (dir == C.SL_ABOVE) {
	if (s1.st >= s2.st) {
		if (s1.stem > 0)
			x1 += 3
		ym = y_get(s1.st, 1, x1 - 4, 8)
		y1 = ym > staff_tb[s1.st].topbar + 2
			? ym
			: staff_tb[s1.st].topbar + 2
	} else {
		y1 = staff_tb[s1.st].topbar + 2
	}
	if (s2.st >= s1.st) {
		ym = y_get(s2.st, 1, x2 - 4, 8)
		y2 = ym > staff_tb[s2.st].topbar + 2
			? ym
			: staff_tb[s2.st].topbar + 2
	} else {
		y2 = staff_tb[s2.st].topbar + 2
	}

	xm = .5 * (x1 + x2);
	ym = .5 * (y1 + y2);

	a = (y2 - y1) / (x2 - x1);
	s0 = 3 * (s2.notes[s2.nhd].pit - s1.notes[s1.nhd].pit) / (x2 - x1)
	if (s0 > 0) {
		if (a < 0)
			a = 0
		else if (a > s0)
			a = s0
	} else {
		if (a > 0)
			a = 0
		else if (a < s0)
			a = s0
	}
	a = s1.fmt.beamslope * a / (s1.fmt.beamslope + Math.abs(a))
	if (a * a < .1 * .1)
		a = 0

	/* shift up bracket if needed */
	dy = 0
	for (s3 = s1; ; s3 = s3.next) {
		if (!s3.dur			/* not a note or a rest */
		 || s3.st != stu) {
			if (s3 == s2)
				break
			continue
		}
		yy = ym + (s3.x - xm) * a;
		yx = y_get(stu, 1, s3.x - 4, 8) + 2
		if (yx - yy > dy)
			dy = yx - yy
		if (s3 == s2)
			break
	}

	ym += dy;
	y1 = ym + a * (x1 - xm);
	y2 = ym + a * (x2 - xm);

	/* shift the slurs / decorations */
	ym += 6
	for (s3 = s1; ; s3 = s3.next) {
		if (s3.st == stu) {
			yy = ym + (s3.x - xm) * a
			if (s3.ymx < yy)
				s3.ymx = yy
			y_set(stu, 1, s3.x - 3, 6, yy)
		}
		if (s3 == s2)
			break
	}

    // below
    } else {	/* lower voice of the staff: the bracket is below the staff */
	if (s1.st <= s2.st) {
		ym = y_get(s1.st, 0, x1 - 4, 8)
		y1 = ym < -2
			? ym
			: -2
	} else {
		y1 = -2
	}
	if (s2.st <= s1.st) {
		if (s2.stem < 0)
			x2 -= 3
		ym = y_get(s2.st, 0, x2 - 4, 8)
		y2 = ym < -2
			? ym
			: -2
	} else {
		y2 = -2
	}

	xm = .5 * (x1 + x2);
	ym = .5 * (y1 + y2);

	a = (y2 - y1) / (x2 - x1);
	s0 = 3 * (s2.notes[0].pit - s1.notes[0].pit) / (x2 - x1)
	if (s0 > 0) {
		if (a < 0)
			a = 0
		else if (a > s0)
			a = s0
		if (a > .35)
			a = .35
	} else {
		if (a > 0)
			a = 0
		else if (a < s0)
			a = s0
		if (a < -.35)
			a = -.35
	}
	if (a * a < .1 * .1)
		a = 0

	/* shift down the bracket if needed */
	dy = 0
	for (s3 = s1; ; s3 = s3.next) {
		if (!s3.dur			/* not a note nor a rest */
		 || s3.st != std) {
			if (s3 == s2)
				break
			continue
		}
		yy = ym + (s3.x - xm) * a;
		yx = y_get(std, 0, s3.x - 4, 8)
		if (yx - yy < dy)
			dy = yx - yy
		if (s3 == s2)
			break
	}

	ym += dy - 8
	y1 = ym + a * (x1 - xm);
	y2 = ym + a * (x2 - xm);

	/* shift the slurs / decorations */
	ym -= 2
	for (s3 = s1; ; s3 = s3.next) {
		if (s3.st == std) {
			yy = ym + (s3.x - xm) * a
			if (s3.ymn > yy)
				s3.ymn = yy;
			y_set(std, 0, s3.x - 3, 6, yy)
		}
		if (s3 == s2)
			break
	}
    } /* lower voice */

	if (tp.f[2] == 1) {			/* if 'which' == none */
		out_tubr(x1, y1 + 4, x2 - x1, y2 - y1, dir == C.SL_ABOVE);
		return
	}
	out_tubrn(x1, y1, x2 - x1, y2 - y1, dir == C.SL_ABOVE,
		tp.f[2] == 0 ? tp.p.toString() : tp.p + ':' +  tp.q);

	if (dir == C.SL_ABOVE)
		y_set(stu, 1, xm - 3, 6, yy + 2)
	else
		y_set(std, 0, xm - 3, 6, yy)
}

// -- draw a ties --
function draw_tie(not1, not2,
			job) {	// -: start and end
				// 1: no starting note
				// 2: no ending note
				// 3: no start for clef or staff change
    var	m, x1, s, y, h, time,
	p = job == 2 ? not1.pit : not2.pit,
	dir = (not1.tie_ty & 0x07) == C.SL_ABOVE ? 1 : -1,
	s1 = not1.s,
	st = s1.st,
	s2 = not2.s,
	x2 = s2.x,
	sh = not1.shhd			// head shift

	for (m = 0; m < s1.nhd; m++)
		if (s1.notes[m] == not1)
			break
	if (dir > 0) {
		if (m < s1.nhd && p + 1 == s1.notes[m + 1].pit)
			if (s1.notes[m + 1].shhd > sh)
				sh = s1.notes[m + 1].shhd
	} else {
		if (m > 0 && p == s1.notes[m - 1].pit + 1)
			if (s1.notes[m - 1].shhd > sh)
				sh = s1.notes[m - 1].shhd
	}
	x1 = s1.x + sh // * .6

	if (job != 2) {
		for (m = 0; m < s2.nhd; m++)
			if (s2.notes[m] == not2)
				break
		sh = s2.notes[m].shhd
		if (dir > 0) {
			if (m < s2.nhd && p + 1 == s2.notes[m + 1].pit)
				if (s2.notes[m + 1].shhd < sh)
					sh = s2.notes[m + 1].shhd
		} else {
			if (m > 0 && p == s2.notes[m - 1].pit + 1)
				if (s2.notes[m - 1].shhd < sh)
					sh = s2.notes[m - 1].shhd
		}
		x2 += sh // * .6
	}

	switch (job) {
	default:
		if (p < not2.pit || dir < 0)
			p = not1.pit
		break
	case 3:
		dir = -dir
	case 1:				/* no starting note */
		x1 = s2.prev ? (s2.prev.x + s2.wr) : s1.x
		if (s1.st != s2.st)
			st = s2.st
		x1 += (x2 - x1) * .4
		if (x1 > x2 - 20)
			x1 = x2 - 20
		break
	case 2:				 // no ending note
		x2 = s1.next ? s1.next.x : realwidth
		if (x2 != realwidth)
			x2 -= (x2 - x1) * .4
		if (x2 < x1 + 16)
			x2 = x1 + 16
		break
	}
	if (x2 - x1 > 20) {
		x1 += 3.5
		x2 -= 3.5
	} else {
		x1 += 1.5
		x2 -= 1.5
	}

	if (s1.dots && !(not1.pit & 1)
	 && ((dir > 0 && !s1.dot_low)
	  || (dir < 0 && s1.dot_low)))
		x1 += 5

	y = staff_tb[st].y + 3 * (p - 18) + .8 * dir
	h = (.15 * (x2 - x1) + 14) * dir * s1.fmt.tieheight
//	anno_start(k1, 'slur')
	slur_out(x1, y, x2, y, dir, h, not1.tie_ty & C.SL_DOTTED)
//	anno_stop(k1, 'slur')
} // draw_tie()

/* -- draw all ties between neighboring notes -- */
function draw_all_ties(p_voice) {
    var s, s1, s2, clef_chg, x, dx, m, not1, not2,
	tim2 = 0

	/* search the start of ties */
//	clef_chg = false
	s1 = p_voice.sym
	set_color(s1.color)
	for ( ; s1; s1 = s1.next) {
		if (s1.ti2			// if end of tie
		 && !s1.invis
		 && s1.time != tim2) {		// and new end
			for (m = 0; m <= s1.nhd; m++) {
				not2 = s1.notes[m]
				not1 = not2.tie_s
				if (!not1
				 || not1.s.v != s1.v)	// (already done)
					continue
				draw_tie(not1, not2, 1)
			}
		}
		if (!s1.ti1			// if not start of tie
		 || s1.invis)
			continue

		// get the end of the tie(s)
		if (s1.type == C.GRACE) {
			for (s = s1.extra; s; s = s.next) {
			    for (m = 0; m <= s1.nhd; m++) {
				not1 = s.notes[m]
				not2 = not1.tie_e
				if (!not2)
					continue
				draw_tie(not1, not2)
				tim2 = not2.s.time
			    }
			}
			continue
		}

	    for (m = 0; m <= s1.nhd; m++) {
		not1 = s1.notes[m]
		not2 = not1.tie_e
		if (!not2) {
			if (not1.tie_ty)
				draw_tie(not1, not1, 2)
			continue
		}
		s2 = not2.s
		if (tsnext && s2.time >= tsnext.time) {	// if end in next line
			draw_tie(not1, not2, 2)
			continue
		}
		tim2 = s2.time

		// check if some clef changes (can occur in an other voice)
		for (s = s1.ts_next; s != s2; s = s.ts_next) {
			if (s.st != s1.st)
				continue
			if (s.type == C.CLEF) {
				clef_chg = true
				break
			}
		}

		/* ties with clef or staff change */
		if (clef_chg || s1.st != s2.st) {
			draw_tie(not1, not2, 2)
			draw_tie(not1, not2, 3)
			clef_chg = false
		} else {
			draw_tie(not1, not2)
		}
	    }
	}
}

/* -- draw the symbols near the notes -- */
/* (the staves are not yet defined) */
/* order:
 * - scaled
 *   - beams
 *   - decorations near the notes
 *   - decorations tied to the notes
 *   - tuplets and slurs
 * - not scaled
 *   - measure numbers
 *   - lyrics
 *   - staff decorations
 *   - chord symbols
 *   - repeat brackets
 *   - parts and tempos
 * The buffer output is delayed until the definition of the staff system
 */
function draw_sym_near() {
    var	p_voice, p_st, s, v, st, y, g, w, i, st, dx, top, bot, ymn,
	output_sav = output;

	// set the staff offsets of a beam
	function set_yab(s1, s2) {
	    var y,
		k = realwidth / YSTEP,
		i = (s1.x / k) | 0,
		j = (s2.x / k) | 0,
		a = (s1.ys - s2.ys) / (s1.xs - s2.xs),
		b = s1.ys - s1.xs * a,
		p_st = staff_tb[s1.st]

		k *= a
		if (s1.stem > 0) {
			while (i <= j) {
				y = k * i + b
				if (p_st.top[i] < y)
					p_st.top[i] = y
				i++
			}
		} else {
			while (i <= j) {
				y = k * i + b
				if (p_st.bot[i] > y)
					p_st.bot[i] = y
				i++
			}
		}
	} // set_yab()

	output = ""
	YSTEP = Math.ceil(realwidth / 2)

	// initialize the min/max vertical offsets in the staves
	for (st = 0; st <= nstaff; st++) {
		p_st = staff_tb[st]
		p_st.top = new Float32Array(YSTEP)
		p_st.bot = new Float32Array(YSTEP)
		for (i = 0; i < YSTEP; i++) {
			p_st.top[i] = 0
			p_st.bot[i] = 24
		}
//		p_st.top.fill(0.)
//		p_st.bot.fill(24.)
	}

	/* calculate the beams but don't draw them (the staves are not yet defined) */
	for (v = 0; v < voice_tb.length; v++) {
		var	bm = {},
			first_note = true;

		p_voice = voice_tb[v]
		for (s = p_voice.sym; s; s = s.next) {
			switch (s.type) {
			case C.GRACE:
				for (g = s.extra; g; g = g.next) {
					if (g.beam_st && !g.beam_end) {
						self.calculate_beam(bm, g)
						if (bm.s2)
							set_yab(g, bm.s2)
					}
				}
				if (!s.p_v.ckey.k_bagpipe	// no slur when bagpipe
				 && s.fmt.graceslurs
				 && !s.gr_shift			// tied to previous note
				 && !s.sl1			// explicit slur
				 && !s.ti1			// some tie
				 && s.next
				 && s.next.type == C.NOTE)
					grace_slur(s)
				break
			}
		}
		for (s = p_voice.sym; s; s = s.next) {
			switch (s.type) {
			case C.NOTE:
				if ((s.beam_st && !s.beam_end)
				 || (first_note && !s.beam_st)) {
					first_note = false;
					self.calculate_beam(bm, s)
					if (bm.s2)
						set_yab(s, bm.s2)
				}
				break
			}
		}
	}

	set_tie_room();
	draw_deco_near()

	/* set the min/max vertical offsets */
	for (s = tsfirst; s; s = s.ts_next) {
		if (s.invis)
			continue
		switch (s.type) {
		case C.GRACE:
			for (g = s.extra; g; g = g.next) {
				y_set(s.st, true, g.x - 2, 4, g.ymx + 1);
				y_set(s.st, false, g.x - 2, 4,
//fixme: hack for slur/accidental far under the staff
//						g.ymn - 1)
						g.ymn - 5)
			}
			continue
		case C.MREST:
			y_set(s.st, true, s.x + 16, 32, s.ymx + 2)
			continue
		default:
			y_set(s.st, true, s.x - s.wl, s.wl + s.wr, s.ymx + 2);
			y_set(s.st, false, s.x - s.wl, s.wl + s.wr, s.ymn - 2)
			// fall thru
		case C.PART:
		case C.TEMPO:
		case C.STAVES:
			continue
		case C.NOTE:
			break
		}

		// (permit closer staves)
		if (s.stem > 0) {
			if (s.stemless) {
				dx = -5;
				w = 10
			} else if (s.beam_st) {
				dx = 3;
				w = s.beam_end ? 4 : 10
			} else {
				dx = -8;
				w = s.beam_end ? 11 : 16
			}
			y_set(s.st, true, s.x + dx, w, s.ymx);
			ymn = s.ymn
			if (s.notes[0].acc	// set room for the accidental
			 && ymn > 3 * (s.notes[0].pit - 18) - 9)
				ymn = 3 * (s.notes[0].pit - 18) - 9
			y_set(s.st, false, s.x - s.wl, s.wl + s.wr, ymn)
		} else {
			y_set(s.st, true, s.x - s.wl, s.wl + s.wr, s.ymx);
			if (s.stemless) {
				dx = -5;
				w = 10
			} else if (s.beam_st) {
				dx = -6;
				w = s.beam_end ? 4 : 10
			} else {
				dx = -8;
				w = s.beam_end ? 5 : 16
			}
			dx += s.notes[0].shhd;
			y_set(s.st, false, s.x + dx, w, s.ymn)
		}

		/* have room for the accidentals */
		if (s.notes[s.nhd].acc) {
			y = 3 * (s.notes[s.nhd].pit - 18)
				+ (s.notes[s.nhd].acc == -1	// flat
					? 11 : 10)
			y_set(s.st, true, s.x - 10, 10, y)
		}
		if (s.notes[0].acc) {
			y = 3 * (s.notes[0].pit - 18)
				- (s.notes[0].acc == -1		// flat
					? 5 : 10)
			y_set(s.st, false, s.x - 10, 10, y)
		}
	}

	draw_deco_note()

	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v];
		s = p_voice.sym
		if (!s)
			continue
		set_color(s.color);
		st = p_voice.st;
//  if (st == undefined) {
//error(1, s, "BUG: no staff for voice " + p_voice.id)
//    continue
//  }

		// draw the slurs and tuplets
		for ( ; s; s = s.next) {
			if (s.play)
				continue
			if (s.tp)
				draw_tuplet(s)
			if (s.sls || s.sl1)
				draw_slurs(s)
		}
	}
	set_color()

	/* set the top and bottom out of the staves */
	for (st = 0; st <= nstaff; st++) {
		p_st = staff_tb[st];
		top = p_st.topbar + 2;
		bot = p_st.botbar - 2
/*fixme:should handle stafflines changes*/
		for (i = 0; i < YSTEP; i++) {
			if (top > p_st.top[i])
				p_st.top[i] = top
			if (bot < p_st.bot[i])
				p_st.bot[i] = bot
		}
	}

	if (cfmt.measurenb >= 0)
		draw_measnb();

	/* if any lyric, draw them now as unscaled */
	set_dscale(-1)
//	set_sscale(-1)
	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v]
		if (p_voice.have_ly) {
			draw_all_lyrics()
			break
		}
	}

	draw_deco_staff()

	draw_partempo()			// draw the parts and tempo indications if any

	set_dscale(-1);
	output = output_sav
}

/* -- draw the name/subname of the voices -- */
function draw_vname(indent, stl) {
    var	p_voice, n, st, v, a_p, p, y, h, h2,
	staff_d = []

	if (!gene.vnt)
		return

//	for (st = stl.length; st >= 0; st--) {
	for (st = stl.length; --st >= 0; ) {
		if (stl[st])
			break
	}
	if (st < 0)
		return

	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v]
		if (!cur_sy.voices[v])
			continue
		st = cur_sy.voices[v].st
		if (!stl[st])
			continue
		p = gene.vnt == 1 ? p_voice.nm : p_voice.snm
		if (!p)
			continue
		delete p_voice.new_name
		if (!staff_d[st])
			staff_d[st] = p
		else
			staff_d[st] += "\n" + p
	}
	if (!staff_d.length)
		return
	set_font("voice");
	h = gene.curfont.size
	h2 = h / 2
	indent = -indent * .5			/* center */
	for (st = 0; st < staff_d.length; st++) {
		if (!staff_d[st])
			continue
		a_p = staff_d[st].split("\n");
		y = staff_tb[st].y
			+ staff_tb[st].topbar * .5
				* staff_tb[st].staffscale
			+ h2 * (a_p.length - 2) + h *.22

		// if instrument with 2 staves, center the voice name
		if ((cur_sy.staves[st].flags & OPEN_BRACE)
		 && st + 1 < staff_tb.length
		 && (cur_sy.staves[st + 1].flags & CLOSE_BRACE)
		 && !staff_d[st + 1])
			y -= (staff_tb[st].y - staff_tb[st + 1].y) * .5
		for (n = 0; n < a_p.length; n++) {
			p = a_p[n];
			xy_str(indent, y, p, "c");
			y -= h
		}
	}
}

// -- set the y offset of the staves and return the height of the whole system --
function set_staff() {
    var	i, st, prev_staff, v, fmt, s,
	y, staffsep, dy, maxsep, mbot, val, p_voice, p_staff,
	sy = cur_sy

	// the last values of {,max}{,sys}staffsep are in the last format
	fmt = tsnext ? tsnext.fmt : cfmt

	/* set the scale of the voices */
	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v]
		if (p_voice.scale != 1)
			p_voice.scale_str = 
				'transform="scale(' + p_voice.scale + ')"'
	}

	// search the top staff
	for (st = 0; st <= nstaff; st++) {
		if (gene.st_print[st])
			break
	}
	y = 0
	if (st > nstaff)
		return y

		p_staff = staff_tb[st]
		for (i = 0; i < YSTEP; i++) {
			val = p_staff.top[i]
			if (y < val)
				y = val
		}

	/* set the vertical offset of the 1st staff */
	y *= p_staff.staffscale;
	staffsep = tsfirst.fmt.staffsep / 2 +
			p_staff.topbar * p_staff.staffscale
	if (y < staffsep)
		y = staffsep
	if (y < p_staff.ann_top)	// absolute annotation
		y = p_staff.ann_top;
	p_staff.y = -y;

	/* set the offset of the other staves */
	for (prev_staff = 0; prev_staff < st; prev_staff++)
		staff_tb[prev_staff].y = -y
	if (!gene.st_print[st])		// no staff
		return y

	var sy_staff_prev = sy.staves[prev_staff]
	for (st++; st <= nstaff; st++) {
		if (!gene.st_print[st])
			continue
		p_staff = staff_tb[st]
		staffsep = sy_staff_prev.sep || fmt.sysstaffsep;
		maxsep = sy_staff_prev.maxsep || fmt.maxsysstaffsep;

		dy = 0
		if (p_staff.staffscale == staff_tb[prev_staff].staffscale) {
			for (i = 0; i < YSTEP; i++) {
				val = p_staff.top[i] -
						staff_tb[prev_staff].bot[i]
				if (dy < val)
					dy = val
			}
			dy *= p_staff.staffscale
		} else {
			for (i = 0; i < YSTEP; i++) {
				val = p_staff.top[i] * p_staff.staffscale
				  - staff_tb[prev_staff].bot[i]
					* staff_tb[prev_staff].staffscale
				if (dy < val)
					dy = val
			}
		}
		staffsep += p_staff.topbar * p_staff.staffscale
		if (dy < staffsep)
			dy = staffsep;
		maxsep += p_staff.topbar * p_staff.staffscale
		if (dy > maxsep)
			dy = maxsep;
		y += dy;
		p_staff.y = -y;

		while (!gene.st_print[++prev_staff])
			staff_tb[prev_staff].y = -y
		while (1) {
			sy_staff_prev = sy.staves[prev_staff]
			if (sy_staff_prev)
				break
			sy = sy.next
		}
	}
	mbot = 0
	for (i = 0; i < YSTEP; i++) {
		val = staff_tb[prev_staff].bot[i]
		if (mbot > val)
			mbot = val
	}
	if (mbot > p_staff.ann_bot) 	// absolute annotation
		mbot = p_staff.ann_bot;
	mbot *= staff_tb[prev_staff].staffscale

	/* output the staff offsets */
	for (st = 0; st <= nstaff; st++) {
		p_staff = staff_tb[st];
		dy = p_staff.y
		if (p_staff.staffscale != 1) {
			p_staff.scale_str =
				'transform="translate(0,' +
					(posy - dy).toFixed(1) + ') ' +
				'scale(' + p_staff.staffscale + ')"'
		}
	}

	if (mbot == 0) {
		for (st = nstaff; st >= 0; st--) {
			if (gene.st_print[st])
				break
		}
		if (st < 0)		/* no symbol in this system ! */
			return y
	}
	dy = -mbot;
	staffsep = fmt.staffsep * .5
	if (dy < staffsep)
		dy = staffsep;
	maxsep = fmt.maxstaffsep * .5
	if (dy > maxsep)
		dy = maxsep;

	// return the height of the whole staff system
	return y + dy
}

/* -- draw the staff systems and the measure bars -- */
function draw_systems(indent) {
	var	s, s2, st, x, x2, res, sy,
		xstaff = [],
		stl = [],		// all staves in the line
		bar_bot = [],
		bar_height = [],
		bar_ng = [],		// number of gaps
		ba = [],		// bars [symbol, bottom, height]
		sb = "",
		thb = ""

	/* -- set the bottom and height of the measure bars -- */
	function bar_set() {
	    var	st, sc, i, j, l, stlines, b, hlmap,
		dy = 0

		for (st = 0; st <= cur_sy.nstaff; st++) {
			if (xstaff[st] < 0) {
				bar_bot[st] = bar_height[st] = 0
				continue
			}
			sc = staff_tb[st].staffscale;
			stlines = cur_sy.staves[st].stafflines
			l = stlines.length
			for (i = 0; i < l; i++) {
				if (stlines[i] != '.' && stlines[i] != '-')
					break
			}
			bar_bot[st] = staff_tb[st].y + 6 * (
						i == l - 1 ? (l - 2) :
						i >= l - 2 ? (l - 3) :
						i) * sc
			if (!dy) {
				dy = staff_tb[st].y + 6 * (
						i == l ? (l + 1) :
						i >= l - 2 ? l :
						(l - 1)) * sc
			}
			bar_height[st] = dy - bar_bot[st];
			bar_ng[st] = l - i		// number of gaps
				 && (l - 1 - i || 2)

			// define the helper lines
			if (stlines[l-1]!= '.') {	// if any staff line
				staff_tb[st].hll = 17 + i * 2	// pitch of lowest note
							// without helper line
							// ('D' when standard staff)
				if (i == l)
					staff_tb[st].hll -= 2
				staff_tb[st].hlmap =
					hlmap = new Int8Array((l - i + 1) * 2 + 2)
				for (j = 1; i < l; i++, j += 2) {
					switch (stlines[i]) {
					case '|':
					case '[':
					case "'":
//					case ':':
						hlmap[j - 1] = 1	// no helper line
						hlmap[j] = 1
						hlmap[j + 1] = 1
						break
					}
				}
			}

			dy = (cur_sy.staves[st].flags & STOP_BAR) ?
					0 : bar_bot[st]
		}

		// if in the middle of the tune, check the previous bar(s)
		i = ba.length
		if (!i)
			return
		while (--i >= 0) {
			b = ba[i]
			st = b[0].st
			if (b[1] > bar_bot[st])
				b[1] = bar_bot[st]
			if (b[2] < bar_height[st])
				b[2] = bar_height[st]
			if (b[3] < bar_ng[st])
				b[3] = bar_ng[st]
			if (b[0].seqst)		// end of time sequence
				break
		}
	} // bar_set()

	/* -- draw a staff -- */
	function draw_staff(st, x1, x2) {
	    var	w, i, dy, ty,
			y = 0,
			ln = "",
		tycl = {
		"|": "slW",		// normal
		"[": "slthW",		// thick
		"'": "sltnW",		// thin
		":": "sldW"		// dash
		},
		stafflines = cur_sy.staves[st].stafflines,
			l = stafflines.length,
			il = 6 * staff_tb[st].staffscale // interline

		if (!/[\[|':]/.test(stafflines))	// '
			return				// no line
		w = x2 - x1;
		set_sscale(-1)

		// check if default staff
		if (cache && cache.st_l == stafflines
		 && staff_tb[st].staffscale == 1
		 && cache.st_w == (w | 0)) {
			xygl(x1, staff_tb[st].y, 'stdef' + cfmt.fullsvg)
			return
		}
		for (i = 0; i < l; i++, y -= il) {
			if (stafflines[i] == '.')
				continue
			dy = 0
			for (; i < l; i++, y -= il, dy -= il) {
				switch (stafflines[i]) {
				case '.':
				case '-':
					continue
				case ty:
					ln += 'm-' + w.toFixed(1) +
						' ' + dy.toFixed(2) +
						'h' + w.toFixed(1);
					dy = 0
					continue
				}
				if (ty != undefined)
					ln += '"/>\n';
				ty = stafflines[i]
				ln += '<path class="' + tycl[ty] +
					'" d="m0 ' + y + 'h' + w.toFixed(1);
				dy = 0
			}
			ln += '"/>'
		}
		y = staff_tb[st].y
		if (!cache
		 && w > get_lwidth() - 10
		 && staff_tb[st].staffscale == 1) {
			cache = {
				st_l: stafflines,
				st_w: w | 0
			}
			i = 'stdef' + cfmt.fullsvg;
			if (ln.indexOf('<path', 1) < 0)
				glyphs[i] = ln.replace('path', 'path id="' + i + '"')
			else
				glyphs[i] = '<g id="' + i + '">\n' + ln + '\n</g>';
			xygl(x1, y, i)
			return
		}
		out_XYAB('<g transform="translate(X, Y)">\n' + ln + '\n</g>\n', x1, y)
	} // draw_staff()

	// draw a measure bar
	function draw_bar(s, bot, h, ng) {
	    var	i, s2, yb, w,
		bar_type = s.bar_type,
		st = s.st,
		p_staff = staff_tb[st],
		top = ng >= 3 ? 6 * ng : (4 - ng) * 6,
		x = s.x

		// don't put a line between the staves if there is no bar above
		if (st != 0
		 && s.ts_prev
//fixme: 's.ts_prev.st != st - 1' when floating voice in lower staff
//	 && (s.ts_prev.type != C.BAR || s.ts_prev.st != st - 1))
		 && s.ts_prev.type != C.BAR)
			h = top * p_staff.staffscale

		s.ymx = s.ymn + h;

		set_sscale(-1)
		anno_start(s)
		if (s.color)
			set_color(s.color);

		// compute the middle vertical offset of the staff
		yb = bot + top / 2

		// if measure repeat, draw the '%' like glyphs
		if (s.bar_mrep) {
			set_sscale(st)
			if (s.bar_mrep == 1) {
				for (s2 = s.prev; s2.type != C.REST; s2 = s2.prev)
					;
				xygl(s2.x, yb, "mrep")
			} else {
				xygl(x, yb, "mrep2")
				if (s.v == cur_sy.top_voice)
					nrep_out(x, yb + p_staff.topbar, s.bar_mrep)
			}
			set_sscale(-1)
		}

		if (bar_type == '||:')
			bar_type = '[|:'

		for (i = bar_type.length; --i >= 0; ) {
			switch (bar_type[i]) {
			case "|":
				if (s.bar_dotted) {
					w = top / 6 <= 9
					    ? [0, 0, 4, 3.6, 4.8, 4.3, 4, 4.7, 4.4, 4.9]
							[top / 6]
						: 5
					out_XYAB(
			'<path class="bW" stroke-dasharray="A,A" d="MX YvG"/>\n',
						x, bot, w * p_staff.staffscale, -h)
				} else if (s.color) {
					out_XYAB('<path class="bW" d="MX YvF"/>\n',
						x, bot, -h)
				} else {
					sb += 'M' + sx(x).toFixed(1)
						+ ' ' + self.sy(bot).toFixed(1)
						+ 'v' + (-h).toFixed(1)
				}
				break
			default:
//			case "[":
//			case "]":
				x -= 3;
				if (s.color)
					out_XYAB('<path class="bthW" d="MX YvF"/>\n',
						x + 1.5, bot, -h)
				else
					thb += 'M' + sx(x + 1.5).toFixed(1)
						+ ' ' + self.sy(bot).toFixed(1)
						+ 'v' + (-h).toFixed(1)
				break
			case ":":
				x -= 2;
				set_sscale(st);
				if (ng & 1) {
					xygl(x, yb + 6, "rdot")
					xygl(x, yb - 6, "rdot")
				} else {
					xygl(x, yb - 12, "rdots")
				}
				set_sscale(-1)
				break
			}
			x -= 3
		}
		set_color();
		anno_stop(s)
	} // draw_bar()

	// output all the bars
	function out_bars() {
	    var	i, b,
		l = ba.length

		for (i = 0; i < l; i++) {
			b = ba[i]		// symbol, bottom, height, top
			draw_bar(b[0], b[1], b[2], b[3])
		}

		set_sscale(-1)
		if (sb)			// single bars
			output += '<path class="bW" d="'
				+ sb
				+ '"/>\n'

		if (thb)		// thick bars [x, y, h]
			output += '<path class="bthW" d="'
				+ thb
				+ '"/>\n'
	} // out_bars()

	// set the helper lines of rests
	function hl_rest(s) {
	    var	j,
		stlines = cur_sy.staves[s.st].stafflines,
		p_st = staff_tb[s.st],
		i = 5 - s.nflags,		// rest_tb index (5 = C_XFLAGS)
		x = s.x,
		y = s.y

		if (i < 6)	// no ledger line if rest smaller than minim
			return

		if (i == 7 && y == 12
		 && stlines.length <= 2)
			y -= 6			// semibreve a bit lower

		j = y / 6
		switch (i) {
		default:
			switch (stlines[j + 1]) {
			case '|':
			case '[':
			case "'":
			case ':':
				break
			default:
				set_hl(p_st, j + 1, x, -7, 7)
				break
			}
			if (i == 9) {		// longa
				y -= 6
				j--
			}
			break
		case 7:				// semibreve
			y += 6
			j++
		case 6:				// minim
			break
		}
		switch (stlines[j]) {
		case '|':
		case '[':
		case "'":
		case ':':
			break
		default:
			set_hl(p_st, j, x, -7, 7)
			break
		}
	} // hl_rest()

	// return the left x offset of a new staff
	// s is the %%staves
	function st1(st, s) {
	    var	tim = s.time

		do {			// search a voice of this staff
			s = s.ts_next
		} while (s.st != st)
		while (s.prev		// search the first symbol of this voice
		    && s.prev.time >= tim)
			s = s.prev
		if (s.bar_type)
			return s.x
		return s.x - s.wl
	} // st1()

	// ---- draw_systems() ----

	/* draw the staff, skipping the staff breaks */
	for (st = 0; st <= nstaff; st++) {
		stl[st] = cur_sy.st_print[st]		// staff at start of line
		xstaff[st] = !stl[st] ? -1 : 0;
	}
	bar_set();
	draw_lstaff(0)
	for (s = tsfirst; s; s = s.ts_next) {
		switch (s.type) {
		case C.STAVES:
			sy = s.sy
			for (st = 0; st <= nstaff; st++) {
				x = xstaff[st]
				if (x < 0) {		// no staff yet
					if (sy.st_print[st]) {
						xstaff[st] = st1(st, s)
						stl[st] = true
					}
					continue
				}
				if (sy.st_print[st]	// if not staff stop
				 && cur_sy.staves[st]
				 && sy.staves[st].stafflines ==
						cur_sy.staves[st].stafflines)
					continue
				if (s.ts_prev.bar_type) {
					x2 = s.ts_prev.x
					if (sy.staves[st].stafflines.length >
					    cur_sy.staves[st].stafflines.length)
						x2 -= s.ts_prev.wl - 4
				} else {
					x2 = (s.ts_prev.x + s.x) / 2
					xstaff[st] = -1
				}
				draw_staff(st, x, x2)
				xstaff[st] = sy.st_print[st] ? x2 : -1
			}
			cur_sy = sy;
			bar_set()
			continue
		case C.BAR:		// display the bars after the staves
			if (s.invis || !s.bar_type
			 || !cur_sy.st_print[s.st])
				break
			if (s.second
			 && (!s.ts_prev
			  || (s.ts_prev.type == C.BAR
			   && s.ts_prev.st == s.st)))
				break
			ba.push([s, bar_bot[s.st], bar_height[s.st], bar_ng[s.st]])
			break
		case C.STBRK:
			if (cur_sy.voices[s.v]
			 && cur_sy.voices[s.v].range == 0) {
				if (s.xmx > 14
				 && s.next			// if not at end of line
				 && s.next.type == C.CLEF) {	// and before a clef

					/* draw the left system if stbrk in all voices */
					var nv = 0
					for (var i = 0; i < voice_tb.length; i++) {
						if (cur_sy.voices[i]
						  && cur_sy.voices[i].range > 0)
							nv++
					}
					for (s2 = s.ts_next; s2; s2 = s2.ts_next) {
						if (s2.type != C.STBRK)
							break
						nv--
					}
					if (nv == 0)
						draw_lstaff(s.x)
				}
			}
			st = s.st;
			x = xstaff[st]
			if (x >= 0) {
				s2 = s.prev
				if (!s2)
					break
				x2 = s2.type == C.BAR ?
					s2.x :
					s.x - s.xmx
				if (x >= x2)
					break
				draw_staff(st, x, x2)
				xstaff[st] = s.x
			}
			break
		case C.GRACE:
			for (s2 = s.extra; s2; s2 = s2.next)
				self.draw_hl(s2)
			break
		case C.NOTE:
			if (!s.invis)
				self.draw_hl(s)
			break
		case C.REST:
			if (s.fmr		// if full measure rest
			 || (s.rep_nb && s.rep_nb >= 0))
				center_rest(s)
			if (!s.invis)
				hl_rest(s)
			break
//		default:
//fixme:does not work for "%%staves K: M: $" */
//removed for K:/M: in empty staves
//			if (!cur_sy.st_print[st])
//				s.invis = true
//			break
		}
	}

	// draw the end of the staves
	for (st = 0; st <= nstaff; st++) {
		x = xstaff[st]
		if (x < 0 || x >= realwidth)
			continue
		draw_staff(st, x, realwidth)
	}

	// the ledger lines
	draw_all_hl()

	// and the bars
	out_bars()

	draw_vname(indent, stl)

//	set_sscale(-1)
}

/* -- draw remaining symbols when the staves are defined -- */
// (possible hook)
Abc.prototype.draw_symbols = function(p_voice) {
	var	bm = {},
		s, x, y, st;

//	bm.s2 = undefined
	for (s = p_voice.sym; s; s = s.next) {
		if (s.invis) {
			switch (s.type) {
			case C.CLEF:
				if (s.time >= staff_tb[s.st].clef.time)
					staff_tb[s.st].clef = s
				continue
			case C.KEY:
				p_voice.ckey = s
			default:
				continue
			case C.NOTE:	// (beams may start on invisible notes)
				break
			}
		}
		st = s.st
		x = s.x;
		set_color(s.color)
		switch (s.type) {
		case C.NOTE:
//--fixme: recall set_scale if different staff
			set_scale(s)
			if (s.beam_st && !s.beam_end) {
				if (self.calculate_beam(bm, s))
					draw_beams(bm)
			}
			if (!s.invis) {
				anno_start(s);
				draw_note(s, !bm.s2);
				anno_a.push(s)
			}
			if (s == bm.s2)
				bm.s2 = null
			break
		case C.REST:
			if (!gene.st_print[st])
				break
			draw_rest(s);
			break
		case C.BAR:
			break			/* drawn in draw_systems */
		case C.CLEF:
			if (s.time >= staff_tb[st].clef.time) {
				if (s.x == staff_tb[st].clef.x
				 && s.v != staff_tb[st].clef.v)
					break
				staff_tb[st].clef = s
			}
			if (!gene.st_print[st])
				break
			set_color();
			set_sscale(st);
			anno_start(s);
			y = staff_tb[st].y
			if (s.clef_name)
				xygl(x, y + s.y, s.clef_name)
			else if (!s.clef_small)
				xygl(x, y + s.y, s.clef_type + "clef")
			else
				xygl(x, y + s.y, "s" + s.clef_type + "clef")
			if (s.clef_octave) {
/*fixme:break the compatibility and avoid strange numbers*/
				if (s.clef_octave > 0) {
					y += s.ymx + 1
					if (s.clef_small)
						y -= 2
				} else {
					y += s.ymn - 2 //+2
//					if (s.clef_small)
//						y += 1
				}
				xygl(x - 2, y, (s.clef_octave == 7
						|| s.clef_octave == -7)
					? "oct" : "oct2")
			}
			anno_a.push(s)
			break
		case C.METER:
			p_voice.meter = s
			if (s.second
			 || !staff_tb[s.st].topbar)
				break
			set_color();
			set_sscale(s.st);
			anno_start(s);
			draw_meter(s);
			anno_a.push(s)
			break
		case C.KEY:
			p_voice.ckey = s
			if (s.second
			 || !staff_tb[s.st].topbar)
				break
			set_color();
			set_sscale(s.st);
			anno_start(s);
			self.draw_keysig(x, s);
			anno_a.push(s)
			break
		case C.MREST:
			draw_mrest(s)
			break
		case C.GRACE:
			set_scale(s);
			draw_gracenotes(s)
			break
		case C.SPACE:
		case C.STBRK:
			break			/* nothing */
		case C.CUSTOS:
			set_scale(s);
			draw_note(s, 0)
			break
		case C.BLOCK:			// no width
		case C.REMARK:
		case C.STAVES:
		case C.TEMPO:
			break
		default:
			error(2, s, "draw_symbols - Cannot draw symbol " + s.type)
			break
		}
	}
	set_scale(p_voice.sym);
}

/* -- draw all symbols -- */
function draw_all_sym() {
    var	p_voice, v,
	n = voice_tb.length

	// draw the slurs on 2 staves
	// sl = [symbol of 1st staff, symbol of 2nd staff, slur type, <path .../>
	function draw_sl2() {
	    var	i, a, d, dy, dy2, dy2o, dz, n, sl

		while (1) {
			sl = gene.a_sl.shift()
			if (!sl)
				break

			// extract the path header and the values
			i = sl[3].indexOf('d="M') + 4
			output += sl[3].slice(0, i)	// <path .. >d="M

			a = new Float32Array(sl[3].slice(i).match(/[\d.-]+/g))

			// update the starting point of the slur
			a[1] -= staff_tb[sl[0].st].y	// absolute vertical offset

// [0][1] = M
// [2][3] [4][5] [6][7] = c
// [8] = v			second curve if not dotted
// [9][10] [11][12] [13][14] = c
//
// y:      3-------5
//	  / 12---10 \
//	 / /       \ \
//	/ /         \ \ 7
//     1 14          \| 8
//
// x:  0   2       4    6
//       13 11    9	

			// deltas between staves, original and now
			dy2o = sl[0].fmt.sysstaffsep + 24
			dy2 = staff_tb[sl[1].st].y - staff_tb[sl[0].st].y

			switch (sl[2]) {		// slur type
			case "//":			// '~' like
			case "\\\\":

				// get the middle of the '~' slur (* 2)
				d = -(sl[1].prev.prev.y + staff_tb[sl[0].st].y
					+ sl[1].prev.next.y + staff_tb[sl[1].st].y)
					- 2 * (a[1] - posy)
				a[5] = d - a[5]
				a[7] = d - a[7]
				if (a.length > 8) {
					d = sl[2][0] == '/' ? 3 : -3
					a[8] = -a[8]
					a[10] = -a[3] + d
					a[12] = -a[5] + d
					a[14] = -a[7]
				}
				break
			case "/\\":
			case "\\/":
				d = sl[2][0] == '/'
					? dy2 - dy2o - 10
					: dy2 + dy2o + 10
				a[3] += d
				a[5] += d
				if (a.length > 8) {
					a[10] += d
					a[12] += d
				}
				break
			default:			// /+, /-, \+ or \-
				d = sl[2][0] == '/' ? dy2 - dy2o : -dy2 - dy2o
				a[5] += d
				a[7] += d
				if (a.length > 8) {
					a[12] -= d
					a[14] -= d
				}
				break
			}

			// output the slur
			output += a[0].toFixed(1) + ' ' + a[1].toFixed(1)
				+ 'c' + a[2].toFixed(1) + ' ' + a[3].toFixed(1)
				+ ' ' + a[4].toFixed(1) + ' ' + a[5].toFixed(1)
				+ ' ' + a[6].toFixed(1) + ' ' + a[7].toFixed(1)
			if (a.length > 8)
				output += 'v' + a[8].toFixed(1)
					+ 'c' + a[9].toFixed(1)
						+ ' ' + a[10].toFixed(1)
					+ ' ' + a[11].toFixed(1)
						+ ' ' + a[12].toFixed(1)
					+ ' ' + a[13].toFixed(1)
						+ ' ' + a[14].toFixed(1)
			output += '"/>\n'
		}
	} // draw_sl2()

	for (v = 0; v < n; v++) {
		p_voice = voice_tb[v]
		if (p_voice.sym
		 && p_voice.sym.x != undefined) {
			self.draw_symbols(p_voice)
			draw_all_ties(p_voice);
// no need to reset the scale as in abcm2ps
			set_color()
		}
	}

	self.draw_all_deco()
	glout()			// output the symbols
	anno_put()		// before outputting the symbol annotations

	set_sscale(-1)				/* restore the scale */

	if (gene.a_sl)		// if slurs on two staves
		draw_sl2()
}

/* -- set the tie directions for one voice -- */
function set_tie_dir(s) {
    var i, ntie, dir, sec, pit, ty, s2

	for ( ; s; s = s.next) {
		if (!s.ti1)
			continue

		sec = ntie = 0;
		pit = 128
		for (i = 0; i <= s.nhd; i++) {
			if (s.notes[i].tie_ty) {
				ntie++
				if (pit < 128
				 && s.notes[i].pit <= pit + 1)
					sec++;
				pit = s.notes[i].pit
				s2 = s.notes[i].tie_e
			}
		}

		if (s2 && s.stem * s2.stem < 0)
			dir = pit >= 22	// up if above middle staff
				? C.SL_ABOVE : C.SL_BELOW
		else if (s.multi)
			dir = s.multi > 0 ? C.SL_ABOVE : C.SL_BELOW
		else
			dir = s.stem < 0 ? C.SL_ABOVE : C.SL_BELOW

		// if other voice, set the ties in opposite direction
		if (s.multi) {
			for (i = 0; i <= s.nhd; i++) {
				ty = s.notes[i].tie_ty
				if (!((ty & 0x07) == C.SL_AUTO))
					continue
				s.notes[i].tie_ty = (ty & C.SL_DOTTED) | dir
			}
			continue
		}

		/* if one note, set the direction according to the stem */
		if (ntie <= 1) {
			for (i = 0; i <= s.nhd; i++) {
				ty = s.notes[i].tie_ty
				if (ty) {
					if ((ty & 0x07) == C.SL_AUTO)
						s.notes[i].tie_ty =
							(ty & C.SL_DOTTED) | dir
					break
				}
			}
			continue
		}
		if (!sec) {
			if (ntie & 1) {
/* in chords with an odd number of notes, the outer noteheads are paired off
 * center notes are tied according to their position in relation to the
 * center line */
				ntie = (ntie - 1) / 2;
				dir = C.SL_BELOW
				for (i = 0; i <= s.nhd; i++) {
					ty = s.notes[i].tie_ty
					if (!ty)
						continue
					if (ntie == 0) {	/* central tie */
						if (s.notes[i].pit >= 22)
							dir = C.SL_ABOVE
					}
					if ((ty & 0x07) == C.SL_AUTO)
						s.notes[i].tie_ty =
							(ty & C.SL_DOTTED) | dir
					if (ntie-- == 0)
						dir = C.SL_ABOVE
				}
				continue
			}
/* even number of notes, ties divided in opposite directions */
			ntie /= 2;
			dir = C.SL_BELOW
			for (i = 0; i <= s.nhd; i++) {
				ty = s.notes[i].tie_ty
				if (!ty)
					continue
				if ((ty & 0x07) == C.SL_AUTO)
					s.notes[i].tie_ty =
						(ty & C.SL_DOTTED) | dir
				if (--ntie == 0)
					dir = C.SL_ABOVE
			}
			continue
		}
/*fixme: treat more than one second */
/*		if (nsec == 1) {	*/
/* When a chord contains the interval of a second, tie those two notes in
 * opposition; then fill in the remaining notes of the chord accordingly */
			pit = 128
			for (i = 0; i <= s.nhd; i++) {
				if (s.notes[i].tie_ty) {
					if (pit < 128
					 && s.notes[i].pit <= pit + 1) {
						ntie = i
						break
					}
					pit = s.notes[i].pit
				}
			}
			dir = C.SL_BELOW
			for (i = 0; i <= s.nhd; i++) {
				ty = s.notes[i].tie_ty
				if (!ty)
					continue
				if (ntie == i)
					dir = C.SL_ABOVE
				if ((ty & 0x07) == C.SL_AUTO)
					s.notes[i].tie_ty =
						(ty & C.SL_DOTTED) | dir
			}
/*fixme..
			continue
		}
..*/
/* if a chord contains more than one pair of seconds, the pair farthest
 * from the center line receives the ties drawn in opposition */
	}
}

/* -- have room for the ties out of the staves -- */
function set_tie_room() {
	var p_voice, s, s2, v, dx, y, dy

	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v];
		s = p_voice.sym
		if (!s)
			continue
		s = s.next
		if (!s)
			continue
		set_tie_dir(s)
		for ( ; s; s = s.next) {
			if (!s.ti1)
				continue
			if (s.notes[0].pit < 20
			 && s.notes[0].tie_ty
			 && (s.notes[0].tie_ty & 0x07) == C.SL_BELOW)
				;
			else if (s.notes[s.nhd].pit > 24
			      && s.notes[s.nhd].tie_ty
			      && (s.notes[s.nhd].tie_ty & 0x07) == C.SL_ABOVE)
				;
			else
				continue
			s2 = s.next
			while (s2 && s2.type != C.NOTE)
				s2 = s2.next
			if (s2) {
				if (s2.st != s.st)
					continue
				dx = s2.x - s.x - 10
			} else {
				dx = realwidth - s.x - 10
			}
			if (dx < 100)
				dy = 9
			else if (dx < 300)
				dy = 12
			else
				dy = 16
			if (s.notes[s.nhd].pit > 24) {
				y = 3 * (s.notes[s.nhd].pit - 18) + dy
				if (s.ymx < y)
					s.ymx = y
				if (s2 && s2.ymx < y)
					s2.ymx = y;
				y_set(s.st, true, s.x + 5, dx, y)
			}
			if (s.notes[0].pit < 20) {
				y = 3 * (s.notes[0].pit - 18) - dy
				if (s.ymn > y)
					s.ymn = y
				if (s2 && s2.ymn > y)
					s2.ymn = y;
				y_set(s.st, false, s.x + 5, dx, y)
			}
		}
	}
}
// abc2svg music font
var musicfont = 'url("data:application/octet-stream;base64,\
AAEAAAAOAIAAAwBgRkZUTZjuVTkAAFesAAAAHEdERUYAFQAUAABXkAAAABxPUy8yWLldDAAAAWgA\
AABWY21hcI+tzq4AAAQEAAAD1mN2dCAAIgKIAAAH3AAAAARnYXNw//8AAwAAV4gAAAAIZ2x5Zjpw\
qQYAAAkEAABFtGhlYWQZC66+AAAA7AAAADZoaGVhCWn/GgAAASQAAAAkaG10eNmK+y4AAAHAAAAC\
RGxvY2GUUqVMAAAH4AAAASRtYXhwANgBEgAAAUgAAAAgbmFtZSB54KwAAE64AAADIXBvc3Rcker6\
AABR3AAABasAAQAAAAEAALjJexZfDzz1AAsEAAAAAADRlyIXAAAAAOPSSjP/OPzvBUsEiAAAAAgA\
AgAAAAAAAAABAAAEiPzvAFwEJf84/XQFSwABAAAAAAAAAAAAAAAAAAAAkQABAAAAkQDhAAUAAAAA\
AAIAAAABAAEAAABAAC4AAAAAAAEBggGQAAUAAAKZAswAAACPApkCzAAAAesAMwEJAAACAAUDAAAA\
AAAAAAAAARAAAAAAAAAAAAAAAFBmRWQAQAAA7LcDOP84AFwEiAMRAAAAAQAAAAAAAAF2ACIAAAAA\
AVUAAAGQAAACWAAAAFcAAAAjAAAAJQAAACT//wBkAAAAZAAABCMAAAQlAAAB4P/cA7oAAAMLAAAC\
0gAAAr//ugHWAAADCwAAAw4AAAMn/8gAyAAAAWgAAAGuAAABIgAAAZAAAAF8AAABkAAAAZAAAAGB\
AAABkAAAAZAAAAGBAAABnwAAAZ///wH0AAABBAAUAQQACgJrACQCEgAAAcIAAAFCAAABQAAAAUr/\
/gEsAAACMAAAAUoAAAFKAAAAZAAAAUAAAAFAAAABQAAAAUAAAABkAAABNgAAAOYAAAE2AAABOwAA\
ATsAAAE7AAABOwAAATsAAAE7AAABOwAAATsAAAE7AAABOwAAAQ0AAADIAAAA/wAAAQsAFAFuAAAA\
jAAAAIwAAAENADIBbv/1AKkAAAE6AAABQP/9AFAAAAFUAAAAZAAAARgAAAJYAAAAtgAAAZAABQCC\
AAAAggAAASwAAAEsAAAA7gAAAP8AAAFJAAABjwAAAdgAAAHYAAACM//wAyD/4QF7/7QBuP/bARb/\
fgET/9sA3AAAAOj/5AK//7QCM/+0Ar//tAMr/9sBX//bAmn/fgFf/34Caf9+AV8AAAH9AAUBtQAA\
AbUAAAJEAA0CRAANARgAAAE2AAABLP//ASwAAAD6AAAAyAAAARj/OAD6AAAAyAAABA0AAAIcAAwB\
9AAAAfQAAAH0AAAB9AAAAfQAAAH0AAACHAAAAPoAAAD6/+gBwgAAAUgAAAFAAAACCgAAAgoAAABk\
AAAAAAADAAAAAwAAABwAAQAAAAAC0AADAAEAAAAcAAQCtAAAAFwAQAAFABwAAAAg4ADgMOA54Ejg\
UOBc4GLgaeCM4JXgpOCp4LPhAeG74efiAOJJ4mTia+KD5KzkwOTR5OrlAeUx5TnlbeWC5dDl4uYY\
5iTmMOZQ5lXpGOld6gLqpOyp7Lf//wAAAAAAIOAA4DDgOOBD4FDgXOBi4GngeuCU4KDgqeCz4QHh\
ueHn4fLiQOJg4mrigOSg5MDkzuTh5QDlIOU55WblguXQ5eLmEOYk5jDmUOZV6RDpXeoC6qTsouy3\
//8AA//kIAUf1gAAAAAfvx+0H68fqQAAAAAAAB+DH3ofLQAAHkoAAAAAAAAAAAAAAAAblAAAAAAA\
AAAAGzgAABr1GqgalwAAGloaTxowGiwAABcrFocV5gAAE9kAAQAAAAAAAAAAAFQAVgAAAAAAAAAA\
AFgAfAB+AAAAAAAAAIAAAACCAJ4AsAC4ALoAwAAAANYA3ADuAPAAAAEQAAAAAAAAARgAAAAAAAAA\
AAEgAAAAAAAAASoAAAAAAAcACAAJAAoACwAMAA0ADgATABQAFQAWABcAAAAYABkAGgAbABwAHQAe\
AB8AIAAhACIAIwAkACUAJgAnACgAKQAqACsALwAAADAAMgAAADMAAAAAADQAAAA1AAAAAAA2AAAA\
NwA4ADkAOgA7ADwAPQA+AD8AQABBAEIAQwBEAEUARgBHAEgASQBKAEsATABNAE4ATwAAAFAAAABR\
AAAAAAAAAFIAAAAAAAAAUwBVAAAAAABWAFcAWABZAFoAWwBcAF0AXgBfAGAAYQBiAGMAZABlAGYA\
ZwBoAAAAAAAAAGkAagBrAGwAbQAAAG4AbwBwAHIAcwAAAHQAAAAAAHUAdgB6AAAAewAAAHwAAAAA\
AAAAfQCCAIMAhAAAAIUAhgAAAAAAhwCLAIwAAACNAAAAjgAAAI8AAAEGAAADAAAAAAAAAAECAAAA\
AgAAAAAAAAAAAAAAAAAAAAEAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
AAAAAAAAAAAAAAAAAAAAAAAAIgKIAAAAKgAqACoANgA+AG4AegCGAJIAsADCATYBkgICAkYC0gNk\
A8QD2AR2BQgFYAWgBiIGRAZYBqoG+gcaB2AHoAfaCCYIZgieCO4JAgkoCU4JgAmcCb4J5gn8ChYK\
TApaCmYKcgqECqAKwgrQCuQK9gsGC1ILYgt8C5YLzgwGDFQMoA0GDWgN5g5eDoQOng7ODvgPUA9q\
D4QPqhAEECQQYhCKEJ4QqhC4EMgQ8BEYEVARXBFoEXQRgBGiEcgR/hJMEqwTIBNGE3QTyBQ8FJAU\
0BUUFWoWhBdcF/IYpBlmGfgayhveHModDB1QHZodtB3YHeweAh4yHkIeVB5wHoYeqh7aH7YgciCc\
ILog6iEoIVohnCG4IdIh+CIaIkgiYiKMIsgi2gACACIAAAEyAqoAAwAHAC6xAQAvPLIHBADtMrEG\
Bdw8sgMCAO0yALEDAC88sgUEAO0ysgcGAfw8sgECAO0yMxEhESczESMiARDuzMwCqv1WIgJmAAAB\
AAAAAAGRAZAAAwAAMREhEQGRAZD+cAABAAAAAAAAAAAAAAAAMQAAAQAAAAAAVwQDACAAABE1NjU0\
JyY1NDcGFRQXFhUUBxYVFAcGFRQXJjU0NzY1NDUjElc/FSVNTSUVP1cSIwIDAhhDNmA5NGY6Mksi\
OWFNYRgYZkxgOSVKMjpmNDlgNkgAAQAAAAAAIwPoAAMAABEzESMjIwPo/BgAAQAAAfQAJQPoAAMA\
ABEzESMlJQPo/gwAAf//A2QAJARgAAMAABEzByMkASQEYPwAAgAAAUAAZAKeAAcADwAAEiImNDYy\
FhQCIiY0NjIWFEcqHR0qHR0qHR0qHQI6HSodHSr+6R0qHR0qAAAAAQAA/84AZAAyAAcAABYiJjQ2\
MhYURyodHSodMh0qHR0qAAAABQAAAAAEJAGuAC8ANwA/AEcAUwAAITUzHgEzMjY1NCcuBDU0NjMy\
Fhc3MxcjLgEjIgYVFB4DFx4BFRQGIyInByAiJjQ2MhYUBCImNDYyFhQBETMyNjQmIwM1MxEjNTMy\
FhUUIwJOHhVPMik7lBkaKhYRWT0kJxkeHgceD0owHzkQIhkyCE5NW09FLiMBmyodHSod/eoqHR0q\
Hf6JKDxGRjzcRkbccYn6oDxLICEtKAcIFBQjFUNNCw4ZmzpIKBsPFw8JCwIVNzM6TiAgHSodHSod\
HSodHSoBaf6YYaZh/noeAWgeZ2vSAAUAAAAABCQBrgAaACIAKgAyAD4AACEiJjU0NjMyFhc3MxcH\
JiMiBhQWMzI2NxcOATIiJjQ2MhYUBCImNDYyFhQBETMyNjQmIwM1MxEjNTMyFhUUIwMCZ3WCWiUp\
Gx4eCCEkXjg2Njg2TREjFFmxKh0dKh396iodHSod/okoPEZGPNxGRtxxifprZ2V3DBIepgSMbZht\
ST4KSlEdKh0dKh0dKh0dKgFp/phhpmH+eh4BaB5na9IAAAAD/9wAAgHeArMABwAPAE0AAAAiJjQ2\
MhYUBCImNDYyFhQXNDYzMhYVFAcWMzI2NTQvAQMnEy4BNTQ+ATc2MzIWFRQGIyImNTQ3JiMiBhUU\
HwETFwMeARUUDgEHBiMiJgGeIBgYIBj+fiAYGCAYWxsUEx4sFykmNiZ7zyvRWkgcExQmMzA4GxQT\
HiwXKSY2JnrUK9VaSBwTFCYzMDgBUhggGBggVBggGBgg0xIcGhEdDhctJi0mZf7eIAElR3E4Fi0R\
ERM4IRIcGhEdDhctJi0mZQEmH/7XR3I4Fi0RERM4AAUAAP9WA7wDYgAXABsAHwAjACcAAAEzFR4B\
FzMVIw4BBxUjNS4BJyM1Mz4BNxEjFhcTETY3JzMmJwMRBgcBxDRwnwmsrAmfcDRwnwmsrAmecZQH\
jTSOBpSUBo40jgYDYqsLtoA0f7cLq6sLt380grQL/ov0FAEI/vgU9DT0FP74AQoU9gAAAAAEAAD9\
bwKnBIgACwBEAE4AYwAAAQYVFBc+ATU0Jw4BExcVFAYjIiY1NDYzMhYUBgcWMzI2PQEnBiMiJjU0\
Nz4GPwEmNTQ2NxYVFAYHFzYzMhYVFCc0JiMiBiMTPgEnDgEVFBYXLgE1NDcnDgEHHgEzMjcBbAcF\
SHU2OUJLF09NUl9AMi9BPy8tGC9AFxwNmNs6DSQgLh0xEhcWDWxJYlx5FBQLcYhOYlACBwIhW0Hi\
NkYnHT0/phGPbAECoXkKFgNTNy0jWjGVSHINB177bOwDTFxTQS1IO1g3ARk8RgPpAsedhWYXMCUt\
GicOERCWZoyhBzrliKlfzwKcc866PmYB/p0SXfILRjEgQhIORUepLr1yl2eNowIAAgAA/fwC0gIA\
AGQAaAAAATI2NTQnJiMiBw4CByYnJicRIxEzETY3NjceAxcWMzI2NTQnJiMiBxYXFBYVFAYrASY1\
NDc2NzYzMhcWFxUUBgcGIyInBxc2MzIWFxYdAQYHBiMiJjU0NzMyFhUUBhUGBxYBMxEjAd4+Sg0a\
SUY8AgYKBCIaHi4cHC4eGiIGFAwZDyclMT0SJFIvMTINAjMhBUQFGlUnI15VNwhaSB8tND8iIj80\
QmYeKAg3Vl1MckQFITMCDzA1/k17e/4geEotLWxJBQ4bCmInKx/+BAQA/hEfKydiCyoXHQkbe0Ix\
NmIaECgDDQQeKxkyFAtEGQ1PNFMSTm8cDRdLShc+LDlDElM0UE48MhkrHgQOBCYQHAPe/AAAAAP/\
uv2lAsMA/wAqADYAQgAANzQ2MzIWFxYVFAYHDgEHNjc+ATc2NTQmJy4BIyIGBz4BMzIWFRQHBiMi\
JgUiJjU0NjMyFhUUBiciJjU0NjMyFhUUBhOLZ1VrKy9GVWbPleWFMTQTChEdHDQzO2EWGCMbLj0n\
ITEzRQKCFh0aFBUeGhoXGxwVFBwbHWKANDk+cn+6T2BNCD2FMWNQK2ZHUCMiF09GHhdBLzIgHlGK\
HBcWHB0VFh3yHhkVGhsUGR4AAAIAAP8GAXIA+gADAAcAADczEyMDMxMj3JQCltyUApb6/gwB9P4M\
AAAEAAD+CgIfA6oACQAgAGMAbgAAJRYXPgE1NCYjIgMCJw4BFRQXLgE1NDY3JicOAQceATMyFx4B\
HwEwHQEUIyImNTQ2MzIWFRQGBxYzMjY1NC8BBiMiJjU0Nz4BNz4CNyY1NDY3HgEVFAYHHgEXNjMy\
FxYVFAcGAwYVFBc+ATU0JwYBSRMGTUdWQg4NGAEsOR8gKkw7BQlxVQEFbYIDIgMGAgJ6NlMzKCU1\
MScVIiMsAQ0JFY2ZLg5MHgUjJxIOWUAvGUlhAggEEghcOTJjNmQDBjdeKV91xFsSTzM2Vv7gAQsQ\
CTQnKSYSQSk4ThA+Wlp5U3F+GiBAFxcbB39IMSQzNyQiKAEMMzUPCY0BkopqURxQGAQgIQ3CB25/\
EzNiW22HTBFuJAJDNmJ3MBsDVh4iOSQlezNGJiYAAAAAAgAA/mMCQgGaAGMAZwAAATI2NTQnJiMi\
Bw4BByYnJicRIxEzETY3NjceAxcWMzI2NTQnJiMiBxYXFBYVFAYrASY1NDc2NzYzMhcWFxUUBgcG\
IyInBxc2MzIWFxYdAQYHBiMiJjU0NzMyFhUUBhUGBxYBMxEjAX4yOwoVOjgwAgwEHRMYJRYWJRgT\
HQQRChMMIB0nMQ4cQyUnKAoCKhoENgQVRCMYSUYtBkg6GCUrMRsbNCg1UhggBi1GST1bNgQaKgIM\
Jiv+o2Ji/oBgOyQkVzsFHQtSHCIZ/moDM/50GSIcUggiEhcIFmI1KyhOFQ0gAgsDGCIUKBAJNRUL\
QCtBDj5aFgoSPDsTMiMuNQ9BK0A/MCgUIxgDCwMfDRYDGPzNAAAAAAP/yP4eAjYAzAAmAC8AOwAA\
NzQ2MzIXFhUUBw4BBzY3Njc2NTQnLgEjIgYHPgEzMhYVFAcGIyImBSImNDYyFhQGJyImNTQ2MzIW\
FRQGD3BSgjwjeEPGacBeRx4JLRgtIDBSChIWFiU5IBklLDkCAhIXFCIYFRUSFhUSERYVIU1eVzNa\
xmw7VwYzZEqMLylmMxoUQjYXDTwmKBoYU3UXJBYXIhjCGBQRFBUQExkAAAAAAwAAAAAAyADwAAkA\
FQArAAA3BhUUFjMyNjU0JyIGFRQeARc2NTQmByImNTQ2Ny4BNTQ2MzIWFRQHFhUUBlYsHhARFAIO\
EwoJECUUNCU1IyIRDCgeKTE3IzR0EB4UHhsRF4URDgoQCAwLHQ4X3CgeFxoLDxMQGiIfHSUOHB8g\
JgACAAD//wFnAQMAMABiAAAXIjU0MzIVFAYVFDMyNjU0IyIHBiMiNTQ3NjM2MzIWFRQHBgcOAQcG\
Fjc2MzIWFRQGJyI0OwEyNzI0MzY3PgE1NiMiBwYnJjc+ATc2OwIyFxYzMjc2BwYHBhUUMzIVFCsC\
1D4YGxIdFyweChQWCAsmBgkjSQ8FFhpICgYBAgUIDA4gI0P6CQkJFAUBAQ0XAQIIDgkIDA0KDwYR\
AjIEAgMGDgwIAggXBkcKAhUMDCcnATchGwcWBg5CIxwMDQ8WVAsBAgUQBwkQAgYLCgUCAyQgKDkB\
EgwEHz0BBQIVCQ4GBhIHGAJABwYCCBKtHQUFCAoIAAAAAAIAAP8GAa4A+gALABQAADMUFjMyNjU0\
JiMiBgc0NjIWFAYiJooqIyIrJyYlKIp9tH19tH1ieHlhZXV2YWeQkdKRkgAAAQAA/wYBIgD6AAkA\
ADE3MxEXFSM1NxFkfUHwQfr+Ph4UFB4BLAAAAAEAAP8GAY8A+gA8AAA3MhUUBw4DBzYzMhYzMjc+\
AjMOAgcGBwYjIiYjIgYjIjU0Jz4FNTQnIgcyFhUUBiMiNTQ+AcfIBQ02QG82EyAbZBwYHgUQDAEB\
BQUBBxAaKRp0FR9WAgcBAiw+RzwoU04aHCk3Hkw8WPp+Gg4hLh1ELQwjDgMNCwUWFgMpDhgnJhAB\
AiFFODwyOBhiATUlHh8pZyg5GQAAAQAA/wYBdQD6ADkAADcyFhUUBiMiJjU0NzYzMhcWFRQGBx4B\
FRQHBiMiJicmNDYzMhYVFAYjFjMyNjU0JicmNDc+ATQmIyJmGyInIRsyHzNZRiZERj0+UUskTSdX\
GCMyICIqJRsMPyQrSC4WFi9LKSQ8qhwXGyMrIy8aKhMiSC5ECwtFLUMnExYUHUwuIRsZHikxJyY6\
CAQiBAk3UDAAAAEAAP8GAZAA+gARAAAFFyM3NSM1NjUzATM/AREzFSMBRTLIMuGTo/77sAFjS0vR\
KSkxKPKA/o6Wkf7ZKAAAAAABAAD/BwF+APoALwAAFzYzMhYVFAYjFjMyNz4BNTQnJiMiBxMhDgEr\
AQc2MzIXHgEVFAcOAiMiJy4BNTQSHCEbKiAcGiQxHBMJHhwoTkgKAWILNSXVBjlCUzEhK0MWQCsl\
PCsQHl8gIBccICEeFB8gORwaNQEiJDp5Hh8VQSVPLxAQAhQJMhIjAAAAAAIAAP8GAYEA+gAJACwA\
ABcyNjU0JiMiBxYTFhUUBiMiJjU0NjMmIyIGFT4CMzIWFRQGIyImJz4BMzIWyCktKigsMAfdGyMY\
HiIbEBY3NS8VGC0eTE9xSGFmAQFsWzA/0kUsIjAlngGfGiYZKB4bDB4jeF8LCglANkRZgnhpkRIA\
AQAA/wYBkAD7ACgAADciDgMHNz4IMzIWMzI2Nw4EFSM2NzY3NjcGIyImYRQaFAkRBQoBDAILBQsJ\
DRAJL3UjGjsRG0UaHgiCAQgRaB4tER4lYKEFDgkbBnQBCwIJAQYBAwEmFw5Dp0FcQitFGzaHJzkK\
KAADAAD/BgGEAPoADgAcADQAABcOARUUFjMyNjU0LgM3PgE1NCYiBhUUHgMHLgE1NDY3MhYVFAYH\
HgEVFAYjIiY1NDaaNixYLCo/DyAdMT4zI0RSMwocEjFwMSlmSktlKjA6MnVNTHY5KhkkGx0wKR8O\
FxINE1oaIhwdMCggDxcTChU/GDw1M00BRjInNBcaOjU3SkgwJDUAAAIAAP8GAYEA+gAJACwAADci\
BhUUFjMyNyYDJjU0NjMyFhUUBiMWMzI2NQ4CIyImNTQ2MzIWFw4BIyImuSktKigsMAfdGyMYHiIb\
EBY3NS8VGC0eTE9xSGFmAQFsWzA/0kUsIjAlnv5hGiYZKB4bDB4jeF8LCglANkRZgnhpkRIAAQAA\
/wcBnwD+ACcAABcyNxcOASMiJjU0PgIzMhYVFAYjIiY1NDY3MjU0JiMiBhUUHgPveh4YEGVNWoMo\
QU4pRGInHSAtJSgKOh8zThQbJRvZngVqT49qQGU7Hks+JDMuHBksAQYLIXBqOlYtGwcAAAL///6i\
AZ8BXgAzADkAABcWMzI3NjcUFhUOASsBByM0Iy4BNTQ2NzUzFTMyFhUUBiMiJjU+ATsBMh4BMzY1\
NCYjIg8BBhUUFxDbEgI9JC0KGAprSwMBLQFSXFtULQhOVScdIC0CJBoBBAYGAgVFHgQMKz081gMn\
MEcBAgJfWmVrFI9XVokSZmJOOSQzLhwWJgECBwYRIQIWNI6RNgGJAAABAAD/BgH0APoACwAANTM1\
MxUzFSMVIzUj10bX10bXI9fXRtfXAAAAAQAU/gYA5AIAABMAABMWBwYnJgI1NBI3NhcWBwYCFRQS\
3AcNCQVJa2tJCQsHBzxGR/4WCAUDBlcBIH18ASJWCwcFCUn+54iG/uUAAAEACv4CANwB/QATAAAT\
NhI1NAInJjc2FxYSFRQCBwYnJhQ7R0Y8CQwKB0lra0kICwb+FkkBG4aIARlJCwQECVb+3nx9/uBX\
CQkEAAAEACT/VgJMAKoACwAPABMAHgAABTQmIyIGFRQWMzI2NzMRIwEzESMkFAYjIiY1NDYzMgGo\
VDwgNFc9IS9yMjL+CjIyAfV7ZmV8eWhmIDVOJx81SyPq/qwBVP6s5nhGSTk/QwAAAgAA/yQCEgDc\
AAMADwAANxUhNSUzFSE1MxEjNSEVIx4B1v4MHgHWHh7+Kh5BgoKbNzf+SDc3AAACAAD/fwHCAIEA\
CwATAAAFNCYjIgYVFBYzMj4BFAYiJjQ2MgFRWjYgNF03IS9xfch9fcgeNE8nHzRMI3RsS0tsSwAA\
AAIAAP92AUIAigAMABgAACU0JiMiBhUUHgEzMjYnMhYVFAYjIiY1NDYBIxocO5MEGxc7k2FAQHtH\
QEB7Lg4ZWygEDhVbhEwpP2BMKT9gAAAAAQAA/3kBQACHAAsAACUUBiMiJjU0NjMyFgFAeVkyPHpY\
MjwoRmk4J0VqOAAB//7/bwFMAJEACwAAJzcXNxcHFwcnByc3AhuMjBuGhhyLixyGcSB2dSBwcCF1\
dSFwAAAABQAA/2oBLACWAAUACwARABcAHwAAFwcWMzI3LwEGFRQXPwEmIyIHHwE2NTQnBjQ2MhYU\
BiKWRx0qKR9dRx0dXEgfKSodXEcdHfJYfFhYfBJIHR1aSR8pKh1YSB0dWkgfKSodhXxYWHxYAAAA\
AQAA/wYCMAD6AAMAABUBMwEBuHj+R/oB9P4MAAEAAP90AUoAjAADAAAxNxcHpaWljIyMAAEAAP90\
AUoAjAACAAAVGwGlpYwBGP7oAAEAAP/OAGQAMgAHAAAWIiY0NjIWFEcqHR0qHTIdKh0dKgAAAAEA\
AP95AUACqAAPAAARIREUBiMiJjU0NjMyFxEhAUB5WTI8elgxH/7eAqj9gEZpOCdFahwBxQAAAQAA\
/3kBQAKoABMAABEhERQGIyImNTQ2MzIXESE1ITUhAUB5WTI8elgxH/7eASL+3gKo/YBGaTgnRWoc\
ARF4PAAAAAABAAACMAFAAqgAAwAAESEVIQFA/sACqHgAAAAAAgAAAXwBQAKoAAMABwAAESEVIREh\
FSEBQP7AAUD+wAH0eAEseAAAAAEAAP/aAGQAPgAHAAAWIiY0NjIWFEcqHR0qHSYdKh0dKgAAAAEA\
AAMCATYDwAAFAAARIRUhFSMBNv7oHgPAHqAAAAAAAQAAAyoA5gQ4ADkAABMiJjU0NjMyFhUUDwEU\
MzI2NTQmKwEiNTQ7ATI2NTQmIyIVFBYVFCMiJjU0NjMyFhUUDgEVFBYVFAZQJykQDg8SCwwhFSQR\
DxIUFCgXJQ4OFQIhDBIlKyMtIyMUMwMqHhgOFhAMEgcHDSofDxkOECUVDRMNAwgIHBEMFR4iGhgj\
EwIBIg8jLQAAAAABAAADAgE2A8AABQAAARUjNSE1ATYe/ugDwL6gHgAAAAEAAPzvATsAAAAPAAAV\
NTMeBBUUBzY1NCYnHgY/UVA3LhKRcO/vNXBlbIlJYGlBSY/fKgABAAAAAAE7AxEADwAAMTUzPgE1\
NCcWFRQOAwcecJITLjdQUT8G7x/hk0dIZ15Iim1ncTUAAgAA/UQBPAAAABgAJgAAGQEzHgYVFAcW\
FRQHNjU0LgMjNR4DFzQ2NTQuAx4GJzM7OC4cEhMeBSk+SEAWCURNVhUBKT5IQf6pAVcbOTM3Oj1I\
JSwrKSs2ORkhN2RFNBirJFRDXSkEDAQ3ZUUzGQAAAAIAAP//ATwCvAAYACYAABURMzI+AzU0JxYV\
FAcWFRQOBQc1Mj4DNTQmNQ4DHhZASD4pBR4TEhwuODszJwYWQUg+KQEVVk1EAQFXGDRFZDchGTk2\
KykrLCVIPTo3MzkbqxkzRWU3BAwDKV1DUwAAAAADAAD9KgE8AJEAGwApADcAABkBMx4GFRQHFhUU\
BxYVFAc2NTQuAiM1HgMXNDY1NC4CIyceAxc0NjU0LgIjHgYnMzs4LhwSEhITHgU9V1UcCURNVhUB\
PFZVHQIJRE1WFQE8VlUd/pACARs5Mzc6PUglLCsnLSwrKSs2ORkhRHdIKakkVEFdKQQNA0R2SCmr\
JFNCXSkEDQNEdkgpAAADAAD/VgE8Ar0AHAApADYAABEzMj4DNTQnFhUUBxYVFAcWFRQOBQcjNzI+\
AjU0JjUOAycyPgI1NCY1DgMeFkBIPikFHhMSEhIcLjg7MycGHh4dVVc9ARVWTUQJHVVXPQEVVk1E\
AVcYNEVkNyEZOTYrKSssLScrLCVIPTo3MzkbqilJeEQEDAQpXUNUhilJeEQDDQQpXUNUAAQAAP1C\
ATwBVAAgAC4APABKAAAZATMeBhUUBxYVFAcWFRQHFhUUBzY1NC4DIzUeAxc0NjU0LgMnHgMXNDY1\
NC4DJx4DFzQ2NTQuAx4GJzM7OC4cEhISEhITHgUpPkhAFglETVYVASk+SEEWCURNVhUBKT5IQRYJ\
RE1WFQEpPkhB/qgCrBs5Mzc6PUglLCsnLSwrJy0sKykrNjkZITdkRTQYqyRUQ10pBAwEN2VFMxmr\
JFRDXSkDDgM3ZUUzGaskVENdKQQMBDdlRTMZAAQAAP6OATwCoAAfACwAOQBGAAAZATMyPgI1NCcW\
FRQHFhUUBxYVFAcWFRQOBQc1Mj4CNTQmNQ4DJzI+AjU0JjUOAycyPgI1NCY1DgMeHFVXPQUeExIS\
EhISHC44OzMnBh1VVz0BFVZNRAkdVVc9ARVWTUQJHVVXPQEVVk1E/o4CrClId0QhGTk2KykrLC0n\
KywtJyssJUg9OjczORuqKUl4RAMNBCldQ1SGKUl4RAMNBCldQ1SGKUl4RAMNBCldQ1QAAAAFAAD9\
VQE8AhIAJAAyAEAATgBcAAAZATMeBhUUBxYVFAcWFRQHFhUUBxYVFAc2NTQuAyM1HgMXNDY1NC4D\
Jx4DFzQ2NTQuAyceAxc0NjU0LgMnHgMXNDY1NC4DHgYnMzs4LhwSEhISEhISEx4FKT5IQBYJRE1W\
FQEpPkhBFglETVYVASk+SEEWCURNVhUBKT5IQRYJRE1WFQEpPkhB/rsDVxs5Mzc6PUglLCsnLSwr\
Jy0sKyctLCspKzY5GSE3ZEU0GKskVENdKQMNBDdlRTMZqyRUQ10pBAwEN2VFMxmrJFRDXSkDDgM3\
ZUUzGaskVENdKQQMBDdlRTMZAAAFAAD9vAE8AnkAIwAwAD0ASgBXAAAZATMyPgI1NCcWFRQHFhUU\
BxYVFAcWFRQHFhUUDgUHNTI+AjU0JjUOAycyPgI1NCY1DgMnMj4CNTQmNQ4DJzI+AjU0JjUOAx4c\
VVc9BR4TEhISEhISEhwuODszJwYdVVc9ARVWTUQJHVVXPQEVVk1ECR1VVz0BFVZNRAkdVVc9ARVW\
TUT9vANXKUh3RCEZOTYrKSssLScrLC0nKywtJyssJUg9OjczORuqKUl4RAMNBCldQ1SGKUl4RAMN\
BCldQ1SGKUl4RAMNBCldQ1SGKUl4RAMNBCldQ1QAAAACAAD/ZADhAbAACgAWAAA3IgYdATY3NjU0\
JjcyFhUUBwYjETMRNmcUKyImKx0HIzlLUkQoI3omE7kPODsvGyYmMiNJTFICTP68NAAAAgAA/oYA\
xQF6AAMADAAAFzc1BxEVNxEjNQcRNxyQkKkZrAFlLZYtAUnoNP3A4jMCQwEAAAIAAP6YAP8BaAAD\
AB8AADcVNzUDIzUHNTc1BzU3NTMVNzUzFTcVBxU3FQcVIzUHU1paHjU1NTUeWh01NTU1HVpGpxun\
/jejD1wPpw9aD6ifHKujD1wPpw9aD6ifHAAAAAEAFP+EAQsAegAeAAAXNSYnBzAVIzUzNycwIzUz\
FRYXNzA1MxUjBgcXMDMVwygMM0g5MzM5SCESNEg5IRM0OXw7Jg0zO0oyMkg5IhEzOUciETRIAAQA\
AP9qAWwBsAAOABwAKwA6AAA3DgEdATI3Njc2NTQnJiM3MhYVFAcGBwYjETMRNhcOAR0BMjc2NzY1\
NCcmIzcyFhUUBwYHDgEjETMRNk4RHg4eHwwEChARGR0rCRgrNS8fGdERHRAeHQsGCxAPFh8qCxko\
FjcWHht9AR4QxikrNA0ZHhQVJjkhEiA5NEACRv7BMiYBHRHGKS8wExMcFhUmNiQWHD4vGyUCRv7B\
MgAAAQAA/wYAjAD6AA4AADcVBhUUFxUuAzQ+AoxQUBolMhsbMiX6FEOjpkAUDx86WnBaOh8AAAEA\
AP8GAIwA+gAOAAA1HgMUDgIHNTY1NCcaJTIbGzIlGlBQ+g8fOlpwWjofDxRApqNDAAACADL/ZAEN\
AbAACgAWAAA3IgYVFBcWFzU0JicyFxEzESInJjU0NqsXIC4uGiozOiMjOlJPOXomGzBFQgPLEh4m\
NAFE/bRSUEUjMgAABP/1/2oBbAGwAA4AHQAsADsAADcjIgcGFRQXFhcWMzU0JicyFxEzESImJyYn\
JjU0NhcOAR0BMjc2NzY1NCcmIzcyFhUUBwYHDgEjETMRNlcBERAKBAwfHg4eKzAZHxY3FysYCSvp\
ER0QHh0LBgsQDxYfKgsZKBY3Fh4bfRUUHhkNNCspxhAeJzIBP/26JRs0OSASITkmAR0RxikvMBMT\
HBYVJjYkFhw+LxslAkb+wTIAAAAAAQAA/sAAqQFAABMAABMzFTcVBxU3FQcVIzUHNTc1BzU3RB5H\
R0dHHkREREQBQKIOXA5/DloPqKIOXA5/DloPAAMAAP6YAToBaAAjACcAKwAANzUzFTcVBxU3FQcV\
IzUHFSM1DwEjNQc1NzUHNTc1MxU3NTMVAzUHFTcVNzXpHjMzMzMePR48AR4zMzMzHj0eHj1bPcCo\
ng9cD58PWg+1qhKspBCong9cD58PWg+1qhKspP79nhGfuJ4RnwAB//0AAAE/APQAGAAANwYjIiY1\
ND8BNi8BJjU0NjMyMRcFFhUUBxICAwcJBs8ODs0ICwcBAgEfDg4BARAICgNJBwZPAwsKEgFrBg4N\
BQAAAAEAAAAAAFAAUAAJAAA1NDYyFhQGIyImFyIXFxEQGCgRFxciFxgAAAABAAAAAAFUADIAAwAA\
MTUhFQFUMjIAAAABAAAAAABkARgAAwAAMwMzAygoZCgBGP7oAAAAAQAAAAABGAE1AAUAADEbASMn\
B4yMQVhaATX+y8bGAAACAAAAAAJYAUoADgAZAAAxNDYzMh4CFSMuASIGByEiJjQ2MzIWFRQGs3k5\
a1UzDwui4KILARwXJSUXGSMjmLIsUYBNboaGbiQwJCQYGSMAAAEAAAAAALYBLQAYAAATMhYXFhUU\
Bw4BIzAnJjU0NjU0Iy4BNTQ2VhsbEBoyGUQQBgFHFBsoLQEtDBEdMD08HS0DAQIIaxMPASYcHjEA\
AAAAAgAFAAABjgH1ABEAIwAANxM2MzIXFhUUBwMGIyInJjU0JxM2MzIXFhUUBwMGIyInJjU0mM0L\
CgYDCwXMCQsEBguLzQoLBgMLBcwIDAQGCyMBwBICBQoGDP4/EQMGDAcHAcASAgUKBgz+PxEDBgwH\
AAEAAP8GAIIA+gADAAA1MxEjgoL6/gwAAAEAAAAAAIIA+gADAAA1MxUjgoL6+gAAAAEAAP+DASwA\
AAADAAAxIRUhASz+1H0AAAEAAAAAASwAfQADAAA1IRUhASz+1H19AAEAAP5+AOsBhwATAAATFwcX\
JiMiBhUUFyY1NDYzMhcnNym9Z2wyNB8mOHg0JSIih2QBh+XZzy4kHTU0S00jLRW8tAAAAQAA/w0B\
AADAABYAADcOAiMiJjU0NjIWFRQHMjY3NjIXAyerAxkaEys3JjgpFyIzIQIVA5YwPAEHBCkoHyAe\
GR0bISwCAv5vEAAAAAEAAP4MAUgAwAAkAAAXBiMiJjU0NjMyFhUUBzI/AQYjIiY1NDYzMhYVFAcy\
NzYyFwMnqyghKzcnGxwpF0ELPDYYKzcnGxwpF0guAhUDxS3EDCgoICAfGR0bIsoMKSgfIB4ZHRtN\
AgL9bgwAAAEAAP4MAY8BwAA2AAA3BiMiJjU0NjMyFhUUBzI/ASIOASMiJjU0NjMyFhUUBzI3NjIX\
AScTBiMiJjU0NjMyFhUUBzI39igfKzcnGxwpFz8LOgEgHBMrNycbHCkXSC4BFgP+9C1VKCErNycb\
HCkXQQs8DCgoICAfGR0bIssJBCkoHyAeGR0bTQIC/G4MASQMKCggIB8ZHRsiAAAAAAEAAP0MAdoB\
wABFAAATBiMiJjU0NjMyFhUUBzI/AQYjIiY1NDYzMhYVFAcyPwEGIyImNTQ2MzIWFRQHMj8BIg4B\
IyImNTQ2MhYVFAcyNzYyFwEnqyghKzcnGxwpF0ELOighKzcnGxwpF0ELOigfKzcnGxwpFz8LOgEg\
HBMrNyY4KRdILgIVA/6pLf48DCgoICAfGR0bIsoMKCggIB8ZHRsiygwoKCAgHxkdGyLLCQQpKB8g\
HhkdG00CAvtuDAAAAAEAAP0MAhkCrgBWAAAlBiMiJjU0NjMyFhUUBzI/AQYjIiY1NDYzMhYVFAcy\
PwEiDgEjIiY1NDYzMhYVFAcyNzYyFwEnEwYjIiY1NDYzMhYVFAcyPwEGIyImNTQ2MzIWFRQHMjcB\
PyghKzcnGxwpF0ELNigfKzcnGxwpFz8LNAEgHBMrNycbHCkXSC4BFgP+ai1VKCErNycbHCkXQQs6\
KCErNycbHCkXQQs0DCgoICAfGR0bIsQMKCggIB8ZHRsixwkEKSgfIB4ZHRtNAgL6gAwBJAwoKCAg\
HxkdGyLIDCgoICAfGR0bIgAD//D/BgImAPoABwAPABMAADYiJjQ2MhYUACImNDYyFhQFATMBUDIj\
IzIjAYgyIyMyI/3SAbh+/kdLIzIjIzL+zyMyIyMyWgH0/gwABP/h/wYDBwD6AAcADwATABcAADYi\
JjQ2MhYUACImNDYyFhQFATMBMwEzAUEyIyMyIwJ3MiMjMiP84wG4e/5HeQG4e/5HSyMyIyMy/s8j\
MiMjMloB9P4MAfT+DAAC/7T/iAF8ARgAEQA7AAA3FjMyNjc2NTQnJiMiBgcGFRQXIicHMzIUKwEi\
NDsBEzY1NCMiDgMHBiY3Njc2MzIWFz4BMzIWFRQGxQIFEjIODQ8CBBI1Cw8nKhktNAsL4QsLS2gG\
CwgMDwsZCgUbBTEPFyUjJAcdJiMeLVkoATUkICYlBQEzHCckKS4geh4eAR0SDA8HFBIsEAgPCVgQ\
GRMaHg80MElrAAAB/9v/9gG+ARgAUwAANwYHBisBIj8BNiYjIgYHBiY3PgMzMhc2MzIXPgEzMhYV\
FA8BBhUUMzI3PgU3NhYHDgIjIiY1ND8BNjU0IyIPAQYHJwYmPwE2NTQjIgdQBwgEBDUNDUIEBggN\
FiQFFQQUECIfEjcLJCQtCQspExkkBS8ECAEEBQsHDAMNAQYVBhIXLR8VGQU0ARUbCEEIDyYNCARD\
ARUbCBURAwEapw0PGjkIDAklGjASKCgoEBgjGgsPfQsJDgIDCQYPBRIBCQ0LHx8aFhMNDYgCBA4U\
qxYBAQEPCKsCBA4UAAAAAf9+/2ABXgG4AEEAAAciJjU0NjMyFhUUBwYVFDMyPgc3IyI1NDsBPgEz\
MhYVFAYjIiY1NDc2NCMiDgcHMzIUKwEOATIgMBcTEhcSChkLEA8LDQoODRQKNRMRQRRpNCAwFxMS\
FxIKGQcMCgcIBQYDBgE2ExM/IXagJiAaIhQPDgsHDQ4GERMlJDw3VScVE0tfJiAaIhQPDgsGHAUL\
ChQNGg0eBijFwQAAAf/bAAABEwETACoAADc+ASYjIgYPAQYHBisBIj8BNiYjIgYHBiY3PgEzMhYX\
NjMyFhUUIyImNTTQBQMDBRQkCT8HCAQENQ0NQgQGCA4XIgUVBCE4IhsdBB8kGiArDxvnAwcELBic\
EQMBGqMNDxo1CAwJPEAaDSceGTcWDRQAAAABAAAAAADcARgAMQAAMyImNTQ2MhYVFAcWMzI2NTQu\
AicmNTQ2MzIWFRQGIyImNTQ3JiMiBhUUHgIXFhUUUB4yFRoXEAwTFiEJCxgGOjctIjYWEA0WBw8R\
DxkREh4FMCsbEBYQDBIQEBYSCw8HDQQlMCMoJBgQGBQOAw4TEQ0JEwwRAyArVQAAAf/k//wA5wEP\
ADwAACcGLgE/ASIGIyImDgEHBicmNz4BNx4BMzI2MzIXFhQPAQYVFDMyNjMyFxY3NiciNTQ2MzIV\
FAYrAS4BIyIKBgsBBbAFHwwDFAwfBQ8EAwgMCwEOLxUiKwQIBQsHngICAQ0GGiMNCAUHJBINJige\
HRglCA4DBAgNBsEGBgIyBQ0LCRIeMAIBBgsBAREHpwYCAwMaCg4NAx0OFTceLwMYAAX/tP+IBUsB\
GAAQACIAtQDGANcAACUWMzI2NzY0JyYjIgYHBhUUBRYzMjY3NjU0JyYjIgYHBhUUFyInBzMyFCsB\
IjQ7ARM2NTQjIg4DBwYmNzY3NjMyFhc+ATMyFz4BMzIWFz4BMzIXPgEzMhYXPgEzMhc+ATMyFhc+\
ATMyFhUUBiMiJwczMhQrASI0OwETNjU0IyIGBxUUBiMiJwczMhQrASI0OwETNjU0IyIGBxUUBiMi\
JwczMhQrASI0OwETNjU0IyIGBxUUBiUWMzI2NzY0JyYjIgYHBhUUBRYzMjY3NjQnJiMiBgcGFRQC\
CgIFEjIODQ8CBBI1Cw/+ywIFEjIODQ8CBBI1Cw8TFhktNAsL4QsLS2gGCwgMDwsZCgUbBTEPFyUj\
JAcdJiMvExIiGyMkBx0mIy8TEiIbIyQHHSYjLxMSIhsjJAcdJiMeLWtJFhktNAsL4QsLS2gGCw4U\
FGtJFhktNAsL4QsLS2gGCw4UFGtJFhktNAsL4QsLS2gGCw4UFGsDgwIFEjIODQ8CBBI1Cw/+ywIF\
EjIODQ8CBBI1Cw8oATUkIUoFATMcJyQpBgE1JCAmJQUBMxwnJCkuIHoeHgEdEgwPBxQSLBAIDwlY\
EBkTGh4PMhwWExoeDzIcFhMaHg8yHBYTGh4PNDBHbSB6Hh4BHRIMDxgjAUdtIHoeHgEdEgwPGCMB\
R20geh4eAR0SDA8YIwFHbSgBNSQhSgUBMxwnJCkGATUkIUoFATMcJyQpAAT/tP+IBAYBGABvAIAA\
kQCjAAAhIicHMzIUKwEiNDsBEzY1NCMiBgcVFAYjIicHMzIUKwEiNDsBEzY1NCMiBgcVFAYjIicH\
MzIUKwEiNDsBEzY1NCMiDgMHBiY3Njc2MzIWFz4BMzIXPgEzMhYXPgEzMhc+ATMyFhc+ATMyFhUU\
BicWMzI2NzY0JyYjIgYHBhUUBRYzMjY3NjQnJiMiBgcGFRQFFjMyNjc2NTQnJiMiBgcGFRQDUhYZ\
LTQLC+ELC0toBgsOFBRrSRYZLTQLC+ELC0toBgsOFBRrSRYZLTQLC+ELC0toBgsIDA8LGQoFGwUx\
DxclIyQHHSYjLxMSIhsjJAcdJiMvExIiGyMkBx0mIx4ta0wCBRIyDg0PAgQSNQsP/ssCBRIyDg0P\
AgQSNQsP/ssCBRIyDg0PAgQSNQsPIHoeHgEdEgwPGCMBR20geh4eAR0SDA8YIwFHbSB6Hh4BHRIM\
DwcUEiwQCA8JWBAZExoeDzIcFhMaHg8yHBYTGh4PNDBHbSgBNSQhSgUBMxwnJCkGATUkIUoFATMc\
JyQpBgE1JCAmJQUBMxwnJCkAAAP/tP+IAsEBGABMAF4AbwAAMyInBzMyFCsBIjQ7ARM2NTQjIg4D\
BwYmNzY3NjMyFhc+ATMyFz4BMzIWFz4BMzIWFRQGIyInBzMyFCsBIjQ7ARM2NTQjIgYHFRQGJxYz\
MjY3NjU0JyYjIgYHBhUUBRYzMjY3NjQnJiMiBgcGFRTIFhktNAsL4QsLS2gGCwgMDwsZCgUbBTEP\
FyUjJAcdJiMvExIiGyMkBx0mIx4ta0kWGS00CwvhCwtLaAYLDhQUa0wCBRIyDg0PAgQSNQsPAVUC\
BRIyDg0PAgQSNQsPIHoeHgEdEgwPBxQSLBAIDwlYEBkTGh4PMhwWExoeDzQwR20geh4eAR0SDA8Y\
IwFHbSgBNSQgJiUFATMcJyQpBgE1JCFKBQEzHCckKQAAAAL/2/+IAysBGAByAIMAACU2NzYzMhYX\
PgEzMhYVFAYjIicHMzIUKwEiNDsBEzY1NCMiDgMHDgEjIiY1ND8BNjU0IyIPAQYHJwYmPwE2NTQj\
Ig8BBgcGKwEiPwE2JiMiBgcGJjc+AzMyFzYzMhc+ATMyFhUUDwEGFRQzMjc+ARcWMzI2NzY0JyYj\
IgYHBhUUAa0xFBgiIyQHHSYjHi1rSRYZLTQLC+ELC0toBgsHDxIOGAgaPC0VGQU0ARUbCEEIDyYN\
CARDARUbCEQHCAQENQ0NQgQGCA0WJAUVBBQQIh8SNwskJC0JCykTGSQFLwQIAQQPJdECBRIyDg0P\
AgQSNQsPd2wYHRMaHg80MEdtIHoeHgEdEgwPDR8bNRA2OBYTDQ2IAgQOFKsWAQEBDwirAgQOFKwR\
AwEapw0PGjkIDAklGjASKCgoEBgjGgsPfQsJDgIINTkBNSQhSgUBMxwnJCkAAAAAAv/b/2ADGQG4\
AFMAlQAANwYHBisBIj8BNiYjIgYHBiY3PgMzMhc2MzIXPgEzMhYVFA8BBhUUMzI3PgU3NhYHDgIj\
IiY1ND8BNjU0IyIPAQYHJwYmPwE2NTQjIgcTIiY1NDYzMhYVFAcGFRQzMj4HNyMiNTQ7AT4BMzIW\
FRQGIyImNTQ3NjQjIg4HBzMyFCsBDgFQBwgEBDUNDUIEBggNFiQFFQQUECIfEjcLJCQtCQspExkk\
BS8ECAEEBQsHDAMNAQYVBhIXLR8VGQU0ARUbCEEIDyYNCARDARUbCPUgMBcTEhcSChkLEA8LDQoO\
DRQKNRMRQRRpNCAwFxMSFxIKGQcMCgcIBQYDBgE2FBQ/IXYVEQMBGqcNDxo5CAwJJRowEigoKBAY\
IxoLD30LCQ4CAwkGDwUSAQkNCx8fGhYTDQ2IAgQOFKsWAQEBDwirAgQOFP6fJiAaIhQPDgsHDQ4G\
ERMlJDw3VScVE0tfJiAaIhQPDgsGHAULChQNGg0eBijFwQAAAAH/fv9gAmkBuAB0AAAlIw4BIyIm\
NTQ2MzIWFRQHBhUUMzI+BzcjIjU0OwE+ATMyFhUUBiMiJjU0NzY0IyIHBgcXPgEzMhYVFAYjIiY1\
NDc2NCMiDgcHMzIUKwEOASMiJjU0NjMyFhUUBwYVFDMyPgcBX5shdl8gMBcTEhcSChkLEA8LDQoO\
DRQKNRMRQRRpNCAwFxMSFxIKGSYXAwGbFGk0IDAXExIXEgoZBwwKBwgFBgMGATYUFD8hdl8gMBcT\
EhcSChkLEA8LDQoPDRTmxcEmIBoiFA8OCwcNDgYREyUkPDdVJxUTS18mIBoiFA8OCwYccwwGAUtf\
JiAaIhQPDgsGHAULChQNGg0eBijFwSYgGiIUDw4LBw0OBhETJSQ8N1UAAAAB/37/YAN0AbgAqgAA\
EzM+ATMyFhUUBiMiJjU0NzY0IyIHBgcXPgEzMhYVFAYjIiY1NDc2NCMiDgcHMzIUKwEOASMiJjU0\
NjMyFhUUBwYVFDMyPgc3Iw4BIyImNTQ2MzIWFRQHBhUUMzI+BzcjDgEjIiY1NDYzMhYVFAcGFRQz\
Mj4HNyMiNTQ7AT4BMzIWFRQGIyImNTQ3NjQjIg4CBwbMnBRpNCAwFxMSFxIKGSYXAwGbFGk0IDAX\
ExIXEgoZBwwKBwgFBgMGATYTEz8hdl8gMBcTEhcSChkLEA8LDQoPDRQKmyF2XyAwFxMSFxIKGQsQ\
DwsNCg4NFQqbIXZfIDAXExIXEgoZCxAPCw0KDg0UCjUTEUEUaTQgMBcTEhcSChkOFQ4IBgIBDktf\
JiAaIhQPDgsGHHMMBgFLXyYgGiIUDw4LBhwFCwoUDRoNHgYoxcEmIBoiFA8OCwcNDgYREyUkPDdV\
J8XBJiAaIhQPDgsHDQ4GERMlJDs4VSfFwSYgGiIUDw4LBw0OBhETJSQ8N1UnFRNLXyYgGiIUDw4L\
BhwTJyIbCgAB/37/YASAAbgA4AAAARc+ATMyFhUUBiMiJjU0NzY0IyIHBgcXPgEzMhYVFAYjIiY1\
NDc2NCMiDgcHMzIUKwEOASMiJjU0NjMyFhUUBwYVFDMyPgc3Iw4BIyImNTQ2MzIWFRQHBhUUMzI+\
BzcjDgEjIiY1NDYzMhYVFAcGFRQzMj4HNyMOASMiJjU0NjMyFhUUBwYVFDMyPgc3IyI1NDsBPgEz\
MhYVFAYjIiY1NDc2NCMiBwYHFz4BMzIWFRQGIyImNTQ3NjQjIg4HAdicFGk0IDAXExIXEgoZJhcD\
AZsUaTQgMBcTEhcSChkHDAoHCAUGAwYBNhMTPyF2XyAwFxMSFxIKGQsQDwsNCg8NFAqbIXZfIDAX\
ExIXEgoZCxAPCw0KDg0UCpshdl8gMBcTEhcSChkLEA8LDQoPDRQKmyF2XyAwFxMSFxIKGQsQDwsN\
Cg4NFAo1ExFBFGk0IDAXExIXEgoZJhcDAZsUaTQgMBcTEhcSChkHDAoHCAUGAwYBDwFLXyYgGiIU\
Dw4LBhxzDAYBS18mIBoiFA8OCwYcBQsKFA0aDR4GKMXBJiAaIhQPDgsHDQ4GERMlJDw3VSfFwSYg\
GiIUDw4LBw0OBhETJSM8N1YnxcEmIBoiFA8OCwcNDgYREyUkPDdVJ8XBJiAaIhQPDgsHDQ4GERMl\
JDw3VScVE0tfJiAaIhQPDgsGHHMMBgFLXyYgGiIUDw4LBhwFCgsTDhkOHQAAAAADAAD/YALfAbgA\
NgBxALYAADMiJjU0NjMyFhUUBxYzMjY1NC4DJy4CNTQ2MzIWFRQGIyImNTQ3JiMiBhUUHgIXHgEV\
FCUGLgE/ASYjIgYjIg4BBwYnJjc+ATcWMzI2MzIXFhQPAQYVFB4BFxY+AScuATU0NjMyFRQGKwEu\
ASMiBSImNTQ2MzIWFRQHDgEeARUUFjI+BzcjIjU0OwE+ATMyFhUUBiMiJjU0NzY0IyIOBwczMhQr\
AQ4BUB4yEgwOFwwGGBYhAwwFFwMUGBQ3LSI2FhANFgUQDg8ZERIeBRsXASYGCwEFrgoUBRoJBRAS\
BRAFAwcLDAExGiAoBwIUCweaBBoqDQUJBQIDJBQMJisgBhc1CRP+tCAwFxMSFxIEAQECBhYQDwsN\
Cg4NFAo1ExFBFGk0IDAXExIXEgoZBwwKBwgFBgMGATYTEz8hdisbEBYNCxgMEhYSCQwNBA4CDRIe\
DyMtJBgQGBQOBgoUEQ0JEwwRAxIfFVoDBAgNBr8FARgfBA0LCBMeLgQDCAIBEQejBQUHAwcLAwQN\
BggIFAsTNx4qAg2yJiAaIhQPDgsCBQQGAwgGBhETJSQ8N1UnFRNLXyYgGiIUDw4LBhwFCwoUDRoN\
HgYoxcEAAgAF//sB/AGaAAkALAAAAQ8BBhUUMzI2NwcOASMiJjU0PwEjNTM/AQc3MhU2MzIWFRQG\
IiY1NDcGDwEjATZ/OQIUGEQSDCkyHyIiAzdpcxZZJpgZIDUYHRggFgk3EEJIAQkHuAgDFRcPKBkU\
JBoLC7MgSi54Ci0pHBUSGxEOEhMPJ9gAAQAA//0BtQDUAC8AACUyNTQnBiImNT4BMzIWFRQHBiMi\
LwEmIyIVFBc2MzIWFRQGByInJjU0NzYzFh8BFgFwLRoQHBQBFwkkLSkXHiYeohoRLhkQDw0VFA0d\
GBwoFiIqF6IcMTkgExAWDQ4WMzUzJBUVehI6IBIQFw4PEgIaIi0zJBMCEHoTAAEAAP/NAbUBAwA2\
AAAXIiY1NDc2MxYfATUzFRcWMzI2NTQnBiMiNT4BMzIWFRQHBiMiLwEVIzUnJiMiBhUUFzYzMhUU\
TSAtKBYgKBcuHlwiDxUcFhQSHAEPCSAtKRccJB4uHlwgDxYcFRQTHANDJjMkEwIQJGmARxcpHCcQ\
DBsPFUImMyQVFSRsg0cWKB4nDwwdIAABAA0AAAJFAOAACwAANyc3FzcXNxcHJwcnIhWOZXhqTRaS\
aXRpLhmZfHx8VBehfHx8AAAAAQAN/8sCRQERABMAACUHJwcnNxc3NTMXNxc3FwcnBxUjARZAaUsV\
jmUWGwFGak8UkmkZG0ZGfE4ZmXwXlntKfFUYoXwblgAAAQAAAAABGAEYAAsAADM1IzUzNTMVMxUj\
FXt7eyJ7e3sie3siewAAAAEAAP6OATYAAAAKAAARNT4ENzMUBiQxTDQ0Dx7A/o48Bw8rPW9JjtoA\
AAAAAf//AAABLQCgAB0AADc+AjMyHgEXFjMyNzYWBw4CIyIuAScmIyIHBiYBCRApHBgmJg8JCh4Y\
BA4CCBEpHBgkJRIHCB0dBQ1GGSEgITEKBiQGBwcZIh8hMQoEIwYIAAAAAQAAAAABLAEsAAcAADER\
IREjNSMVASwj5gEs/tS0tAABAAAAAAD6AcIABgAAMwMzGwEzA2lpKFVVKGkBwv6YAWj+PgACAAAA\
AADIAMgABwAPAAA2MjY0JiIGFBYiJjQ2MhYURT4sLD4sdFI7O1I7GSw+LCw+RTtSOztSAAH/OAAA\
AMgAyAALAAAjNDYyFhUjNCYiBhXIdqR2HmCUYFJ2dlJKYGBKAAAAAgAAAAAAtAEsAAcAFQAANjI2\
NCYiBhQXNS4BNTQ2MhYVFAYHFUseGxseGxgdKzdGNysdeDU2NTU2rWQINScoPDwoJzUIZAAAAgAA\
AAAAyAEsAA8AHwAANy4BNTQ2MhYVFAYHHQEjNTc+ATU0JiIGFRQWFz0BMxVUJDA7UjswJCAgGSIs\
PiwiGSBmBTglKTs7KSU4BQFlZRkGKRsfLCwfGykGAUlJAAAABAAA//wD9AJ/AIMAjQCZAKMAADc+\
ATU0Jy4BNTQ+Aj8CDgEVFDMyNxcOASMiJjU0PgIzMhYVFAYjIiYnNx4BMzI1NC4CJwcGFRQeAhUU\
Bg8BHgI7ATI3JjU0NzYzMhYVFAcGBx4BMzI2NTQ2Ny4CPQEeARUUBiMiJwYjIi4BJw4BIiYnJiMi\
DgEHBiMiNTQ2BSImNDYzMhYUBiU+ATU0JyYjIgYVFAU2NTQmJw4BFRSYNkUFA1IDBAUBAj1iaiAe\
HRoVKSUeLR8+cEh9cjIuHDYSGBEUFDMMHEAtGwkdIh0fEBAOKR8MDREiIRwiTBsjCh08EyAbFjFD\
XSCBXrq0UUJBIyQ8ITMWDiwoIBscGhIKFBkGWiEKMANcCxMTCwwSEf4PMyQEBRUcLgE8WhcSPzBa\
GD8gCgwIdCIFDg4MBASlBGMsIzwNQi8mGiFHRCxRNzA1MCsOHhEyChoiGgJCJBseNiEsFSZPFBQK\
KRoeNSg1JS4rICETOTAXEioZUl8ZLFk0BgE8sWtGXzk6FRQSJhkWIC0LFQQ6Bw04TxIYEhIYEoAv\
LxsHDhI5Kx50BYEiSRUdWEQ/AAACAAwACgHTAc8ACgCPAAAlNCYjIgYUFjMyNicOASMiJjQ2MzIW\
FzY1NCcmIyImNDYzMhceARcWMzI1NCcuATU0NjMyFhUUBgcUMzI3PgE3NjMyFhUUBiMiBgcGFRQz\
MjYzMhYUBiMiJiMiBhUUFx4BFxYVFAYjIicuAScmIyIVFBYVFAYjIiY0NjU0IyIHDgEHBiMiJjU0\
NzYzMjc2NTQBFhgPEBUWDxAXiRkmDhkbGhkNKhglDBQYHRwZFxIQCwMUCxIUAQInHhQSGyMBFhAN\
EQENDBoTHhsSGxUNECEbKw4cGx0ZDycUFxILFDgNDhkXExQMARMRChIqIBMSHSYXDQ4SAxESDBQa\
DQwWIxIN7hAUEyIWFQoBJRkqGyUCAxYOChMcKB0MCz4WDRgNCBcnDxcaGxYRIxkqEBM4Dw4bFBEj\
BgsODxYnHSgaJggKFgoSAwsNGRMbDgs5FQ8fHjATFBgaJDEXJA4SPQwHFhQYDg0SDQwaAAAAAwAA\
/wYB9AD6AAcADwAXAAAEIiY0NjIWFCQUFjI2NCYiAjQ2MhYUBiIBEzIjIzIj/vd4qnh4qqWS0JKS\
0DwjMiMjMm6qeHiqeP7L0JKS0JIAAAAAAgAA/wYB9AD6AAcADwAANhQWMjY0JiICNDYyFhQGIi14\
qnh4qqWS0JKS0FWqeHiqeP7L0JKS0JIAAAAAAwAA/qIB9AFeAAUAFgAcAAAXEQ4BFBYTNTMVHgEU\
BgcVIzUuATU0NhM+ATQmJ+NNaWlNLWGDg2EtYIODjU5paU7MAZgIdpx2Ab1lZQiPxI8IZWUJj2Fi\
j/5DCHWedQgAAgAA/wYB0gD6AAcAKQAABCImNDYyFhQ3FhUUBwYjIicmIyIGFBYzMjc2MzIXFhUU\
BwYjIiY0NjMyARMyIyMyI5kCCwUGDQozd1V4eFV4MgYSBwMMA0CVaJKSaJQ8IzIjIzKbBgQPBgMO\
X3iqeF8NAgcMBgZ4ktCSAAAAAAEAAP8GAdIA+gAhAAAlFhUUBwYjIicmIyIGFBYzMjc2MzIXFhUU\
BwYjIiY0NjMyAc8CCwUGDQozd1V4eFV4MgYSBwMMA0CVaJKSaJSCBgQPBgMOX3iqeF8NAgcMBgZ4\
ktCSAAACAAD+ogHSAV4AJAAqAAAlFhUUBwYjIicmJxE2NzYzMhcWFRQHBgcVIzUuATU0Njc1MxUW\
Bw4BFBYXAc8CCwUGDQouZmYuBhIHAwwDO4QtYIODYC2EsU1paU2CBgQPBgMOVAr+aAdXDQIHDAYG\
cAdlZQmPYWKPCGVlCSQIdpx2CAAAAAACAAD9EgFKAL4AAwAPAAA3FSE1JTMVITUzESMRIRUjHgEO\
/tQeAQ4eHv7yHkaMjHgyMvxUAmIyAAEAAAAAAlYBcgALAAA1Nxc3FzcXAScHJweJVFZSryL+/FRW\
UzVBuXNzcekW/qR0dHBHAAAB/+gAvQESATcAFwAAJj4BMzIWMjc2MzIVFA4BIyImIgcGIyI1GDAh\
HBRVKBQDBw4wIRwUVSgUBAcN9jARPRQDBwwwET0UBAgAAAAAAgAA/4kBwgCLAAsAEwAABTQmIyIG\
FRQWMzI+ARQGIiY0NjIBUVo2IDRdNyEvcX3IfX3IFDRPJx80TCN0bEtLbEsAAAACAAD/bAFIAqgA\
DQAcAAAlJiMiBhUUFxYzMjY1NBMzERQGIyInJjU0NjMyFwEkDSU8lwYLJjyXAh1+SE8kD35IQCRE\
F2ErCgkXYSsJAm79bkNnQx4dQ2ctAAAAAAEAAP95AUACqAANAAABMxEUBiMiJjU0NjMyFwEiHnlZ\
Mjx6WDEfAqj9gEZpOCdFahwAAAABAAD/eQIKAqgAGgAAAREUBiMiJjU0NjMyFxE1Mx4EFRQHNjU0\
AUB5WTI8elgxHx4GLjk4JTISAbn+b0ZpOCdFahwBTu81XEdOdUlIckFJ7wAAAAACAAD/eQILAqgA\
HwAoAAAlNREzHgQVFAcWFRQHNjU0JiMRFAYjIiY1NDYzMhMeARc0NjU0JgEiHgkwODYjFRYiBXY4\
eVkyPHpYMT0OhRsBdmvmAVckRztCWDMlMjAkLkEZIV+e/tZGaTgnRWoBdjuiNQMOA1+fAAABAAD/\
zgBkADIABwAAFiImNDYyFhRHKh0dKh0yHSodHSoAAAAAAA4ArgABAAAAAAAAAIMBCAABAAAAAAAB\
AAcBnAABAAAAAAACAAcBtAABAAAAAAADACMCBAABAAAAAAAEAAcCOAABAAAAAAAFAAgCUgABAAAA\
AAAGAAcCawADAAEECQAAAQYAAAADAAEECQABAA4BjAADAAEECQACAA4BpAADAAEECQADAEYBvAAD\
AAEECQAEAA4CKAADAAEECQAFABACQAADAAEECQAGAA4CWwBDAG8AcAB5AHIAaQBnAGgAdAAgAFwA\
MgA1ADEAIAAyADAAMQA4AC0AMgAwADIANQAgAEoAZQBhAG4ALQBGAHIAYQBuAGMAbwBpAHMAIABN\
AG8AaQBuAGUALgAgAFQAaABpAHMAIABmAG8AbgB0ACAAaQBzACAAbABpAGMAZQBuAHMAZQBkACAA\
dQBuAGQAZQByACAAdABoAGUAIABTAEkATAAgAE8AcABlAG4AIABGAG8AbgB0ACAATABpAGMAZQBu\
AHMAZQAgAFwAKABoAHQAdABwADoALwAvAHMAYwByAGkAcAB0AHMALgBzAGkAbAAuAG8AcgBnAC8A\
TwBGAEwAXAApAC4AAENvcHlyaWdodCBcMjUxIDIwMTgtMjAyNSBKZWFuLUZyYW5jb2lzIE1vaW5l\
LiBUaGlzIGZvbnQgaXMgbGljZW5zZWQgdW5kZXIgdGhlIFNJTCBPcGVuIEZvbnQgTGljZW5zZSBc\
KGh0dHA6Ly9zY3JpcHRzLnNpbC5vcmcvT0ZMXCkuAABhAGIAYwAyAHMAdgBnAABhYmMyc3ZnAABS\
AGUAZwB1AGwAYQByAABSZWd1bGFyAABGAG8AbgB0AEYAbwByAGcAZQAgADIALgAwACAAOgAgAGEA\
YgBjADIAcwB2AGcAIAA6ACAAMQAyAC0AMgAtADIAMAAyADUAAEZvbnRGb3JnZSAyLjAgOiBhYmMy\
c3ZnIDogMTItMi0yMDI1AABhAGIAYwAyAHMAdgBnAABhYmMyc3ZnAABWAGUAcgBzAGkAbwBuACAA\
AFZlcnNpb24gAABhAGIAYwAyAHMAdgBnAABhYmMyc3ZnAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAA\
AAAAAAAAAAAAAAAAAJEAAAABAAIBAgADAQMBBAEFAQYBBwEIAQkBCgELAQwBDQEOAQ8BEAERARIB\
EwEUARUBFgEXARgBGQEaARsBHAEdAR4BHwEgASEBIgEjASQBJQEmAScBKAEpASoBKwEsAS0BLgEv\
ATABMQEyATMBNAE1ATYBNwE4ATkBOgE7ATwBPQE+AT8BQAFBAUIBQwFEAUUBRgFHAUgBSQFKAUsB\
TAFNAU4BTwFQAVEBUgFTAVQBVQFWAVcBWAFZAVoBWwFcAV0BXgFfAWABYQFiAWMBZAFlAWYBZwFo\
AWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQB\
hQGGAYcBiAGJAYoBiwGMAY0BjgYubm9kZWYHdW5pRTAwMAd1bmlFMDMwB3VuaUUwMzgHdW5pRTAz\
OQd1bmlFMDQzB3VuaUUwNDQHdW5pRTA0NQd1bmlFMDQ2B3VuaUUwNDcHdW5pRTA0OAd1bmlFMDUw\
B3VuaUUwNUMHdW5pRTA2Mgd1bmlFMDY5B3VuaUUwN0EHdW5pRTA3Qgd1bmlFMDdDB3VuaUUwN0QH\
dW5pRTA3RQd1bmlFMDgwB3VuaUUwODEHdW5pRTA4Mgd1bmlFMDgzB3VuaUUwODQHdW5pRTA4NQd1\
bmlFMDg2B3VuaUUwODcHdW5pRTA4OAd1bmlFMDg5B3VuaUUwOEEHdW5pRTA4Qgd1bmlFMDhDB3Vu\
aUUwOTQHdW5pRTA5NQd1bmlFMEEwB3VuaUUwQTEHdW5pRTBBMgd1bmlFMEEzB3VuaUUwQTQHdW5p\
RTBBOQd1bmlFMEIzB3VuaUUxMDEHdW5pRTFCOQd1bmlFMUJCB3VuaUUxRTcHdW5pRTFGMgd1bmlF\
MUY0B3VuaUUxRjcHdW5pRTFGOQd1bmlFMUZDB3VuaUUxRkUHdW5pRTFGRgd1bmlFMjAwB3VuaUUy\
NDAHdW5pRTI0MQd1bmlFMjQyB3VuaUUyNDMHdW5pRTI0NAd1bmlFMjQ1B3VuaUUyNDYHdW5pRTI0\
Nwd1bmlFMjQ4B3VuaUUyNDkHdW5pRTI2MAd1bmlFMjYxB3VuaUUyNjIHdW5pRTI2Mwd1bmlFMjY0\
B3VuaUUyNmEHdW5pRTI2Ygd1bmlFMjgwB3VuaUUyODEHdW5pRTI4Mgd1bmlFMjgzB3VuaUU0QTAH\
dW5pRTRBMgd1bmlFNEE0B3VuaUU0QTgHdW5pRTRBQwd1bmlFNEMwB3VuaUU0Q0UHdW5pRTREMQd1\
bmlFNEUxB3VuaUU0RTIHdW5pRTRFMwd1bmlFNEU0B3VuaUU0RTUHdW5pRTRFNgd1bmlFNEU3B3Vu\
aUU0RTgHdW5pRTRFOQd1bmlFNEVBB3VuaUU1MDAHdW5pRTUwMQd1bmlFNTIwB3VuaUU1MjEHdW5p\
RTUyMgd1bmlFNTIzB3VuaUU1MjQHdW5pRTUyNQd1bmlFNTI5B3VuaUU1MkEHdW5pRTUyQgd1bmlF\
NTJDB3VuaUU1MkQHdW5pRTUyRgd1bmlFNTMwB3VuaUU1MzEHdW5pRTUzOQd1bmlFNTY2B3VuaUU1\
NjcHdW5pRTU2OQd1bmlFNTZDB3VuaUU1NkQHdW5pRTU4Mgd1bmlFNUQwB3VuaUU1RTIHdW5pRTYx\
MAd1bmlFNjEyB3VuaUU2MTQHdW5pRTYxOAd1bmlFNjI0B3VuaUU2MzAHdW5pRTY1MAd1bmlFNjU1\
B3VuaUU5MTAHdW5pRTkxMQd1bmlFOTEyB3VuaUU5MTQHdW5pRTkxNQd1bmlFOTE4B3VuaUU5NUQH\
dW5pRUEwMgd1bmlFQUE0B3VuaUVDQTIHdW5pRUNBMwd1bmlFQ0E1B3VuaUVDQTcHdW5pRUNBOQd1\
bmlFQ0I3AAAAAAH//wACAAEAAAAAAAAADAAUAAQAAAACAAAAAQAAAAEAAAAAAAEAAAAA44To7gAA\
AADRlyIXAAAAAOPSSjM=\
") format("truetype")'
// abc2svg - format.js - formatting functions
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

    var	font_scale_tb = {
		serif: 1,
		serifBold: 1,
		'sans-serif': 1,
		'sans-serifBold': 1,
		Palatino: 1.1,
		monospace: 1
	},
	txt_ff = "text,serif",		// text font-family (serif for compatibility)
	ff = {},			// font-face's from %%beginsvg
	fmt_lock = {}

var cfmt = {
	"abc-version": "1",		// default: old version
	annotationfont: {name: "text,sans-serif", size: 12},
	aligncomposer: 1,
	beamslope: .4,			// max slope of a beam
//	botmargin: .7 * IN,		// != 1.8 * CM,
	bardef: {
		"[":	"",		// invisible
		"[]":	"",
		"|:":	"[|:",
		"|::":	"[|::",
		"|:::":	"[|:::",
		":|":	":|]",
		"::|":	"::|]",
		":::|":	":::|]",
		"::":	":][:"
	},
	breaklimit: .7,
	breakoneoln: true,
	cancelkey: true,
	composerfont: { name: txt_ff, style: "italic", size: 14 },
	composerspace: 6,
//	contbarnb: false,
	decoerr: true,
	dynalign: true,
	footerfont: { name: txt_ff, size: 16 },
	fullsvg: '',
	gchordfont: { name: "text,sans-serif", size: 12 },
	gracespace: new Float32Array([6, 8, 11]),	// left, inside, right
	graceslurs: true,
	headerfont: { name: txt_ff, size: 16 },
	historyfont: { name: txt_ff, size: 16 },
	hyphencont: true,
	indent: 0,
	infofont: {name: txt_ff, style: "italic", size: 14 },
	infoname: 'R "Rhythm: "\n\
B "Book: "\n\
S "Source: "\n\
D "Discography: "\n\
N "Notes: "\n\
Z "Transcription: "\n\
H "History: "',
	infospace: 0,
	keywarn: true,
	leftmargin: 1.4 * CM,
	lineskipfac: 1.1,
	linewarn: true,
	maxshrink: .65,		// nice scores
	maxstaffsep: 2000,
	maxsysstaffsep: 2000,
	measrepnb: 1,
	measurefont: {name: txt_ff, style: "italic", size: 10},
	measurenb: -1,
	musicfont: {name: "music", src: musicfont, size: 24},
	musicspace: 6,
//	notespacingfactor: "1.3, 38",
	partsfont: {name: txt_ff, size: 15},
	parskipfac: .4,
	partsspace: 8,
//	pageheight: 29.7 * CM,
	pagewidth: 21 * CM,
	"propagate-accidentals": "o",		// octave
	printmargin: 0,
	rightmargin: 1.4 * CM,
	rbmax: 4,
	rbmin: 2,
	repeatfont: {name: txt_ff, size: 9},
	scale: 1,
	slurheight: 1.0,
	spatab: 	// spacing table (see "notespacingfactor" and set_space())
		new Float32Array([	// default = "1.3, 38"
			10.2, 13.3, 17.3, 22.48, 29.2,
			38,
			49.4, 64.2, 83.5, 108.5]),
	staffsep: 46,
	stemheight: 21,			// one octave
	stretchlast: .25,
	stretchstaff: true,
	subtitlefont: {name: txt_ff, size: 16},
	subtitlespace: 3,
	sysstaffsep: 34,
	systnames: -1,			// (for compatibility)
	systvoices: 3,
	tempofont: {name: txt_ff, weight: "bold", size: 12},
	textfont: {name: txt_ff, size: 16},
//	textoption: undefined,
	textspace: 14,
	tieheight: 1.0,
	titlefont: {name: txt_ff, size: 20},
//	titleleft: false,
	titlespace: 6,
	titletrim: true,
//	transp: 0,			// global transpose
//	topmargin: .7 * IN,
	topspace: 22,
	tuplets: [0, 0, 0, 0],
	tupletfont: {name: txt_ff, style: "italic", size: 10},
	vocalfont: {name: txt_ff, weight: "bold", size: 13},
	vocalspace: 10,
	voicefont: {name: txt_ff, weight: "bold", size: 13},
//	voicescale: 1,
	writefields: "CMOPQsTWw",
	wordsfont: {name: txt_ff, size: 16},
	wordsspace: 5,
	"writeout-accidentals": "n"
}

// parameters that are used in the symbols
var sfmt = {
bardef: true,
barsperstaff: true,
beamslope: true,
breaklimit: true,
bstemdown: true,
cancelkey: true,
dynalign: true,
flatbeams: true,
gracespace: true,
hyphencont: true,
keywarn: true,
maxshrink: true,
maxstaffsep: true,
measrepnb: true,
rbmax: true,
rbmin: true,
shiftunison: true,
slurheight: true,
squarebreve: true,    
staffsep: true,
systvoices: 1, //true
stemheight: true,
stretchlast: true,
stretchstaff: true,
tieheight: true,
timewarn: true,
trimsvg: 1, //true
vocalspace: true
} // sfmt

function get_bool(param) {
	return !param || !/^(0|n|f)/i.test(param) // accept void as true !
}

// %%font <font> [<encoding>] [<scale>]
function get_font_scale(param) {
    var	i, font,
	a = info_split(param)	// a[0] = font name

	if (a.length <= 1)
		return
	var scale = +a[a.length - 1]

	if (isNaN(scale) || scale <= 0.5) {
		syntax(1, "Bad scale value in %%font")
		return
	}
	font_scale_tb[a[0]] = scale
}

// set the width factor of a font
function set_font_fac(font) {
    var scale = font_scale_tb[font.fname || font.name]

	if (!scale)
		scale = 1.1;
	font.swfac = font.size * scale
}

// %%xxxfont fontname|* [encoding] [size|*]
function param_set_font(xxxfont, p) {
    var	font, n, a, ft2, k

	// "setfont-<n>" goes to "u<n>font"
	if (xxxfont[xxxfont.length - 2] == '-') {
		n = xxxfont[xxxfont.length - 1]
		if (n < '1' || n > '9')
			return
		xxxfont = "u" + n + "font"
	}

	// fill the values
	font = {}
	a = p.match(/\s+(no)?box(\s|$)/)
	if (a) {				// if box
		if (a[1]) {
			font.box = false	// nobox
			font.pad = 0
		} else {
			font.box = true
			font.pad = 2.5
		}
		p = p.replace(a[0], a[2])
	}
	a = p.match(/\s+padding=([\d.]+)(\s|$)/)
	if (a) {				// if padding
		font.pad = a[1] ? +a[1] : 0
		p = p.replace(a[0], a[2])
	}

	a = p.match(/\s+class=(.*?)(\s|$)/)
	if (a) {
		font.class = a[1];
		p = p.replace(a[0], a[2])
	}
	a = p.match(/\s+wadj=(.*?)(\s|$)/)
	if (a) {
	    if (typeof document == "undefined")	// useless if in browser
		switch (a[1]) {
		case 'none':
			font.wadj = ''
			break
		case 'space':
			font.wadj = 'spacing'
			break
		case 'glyph':
			font.wadj = 'spacingAndGlyphs'
			break
		default:
			syntax(1, errs.bad_val, "%%" + xxxfont)
			break
		}
		p = p.replace(a[0], a[2])
	}

	// the font size is the last item
	a = p.match(/\s+([0-9.]+|\*)$/)
	if (a) {
		if (a[1] != "*")
			font.size = +a[1]
		p = p.replace(a[0], "")
	}

	// accept local(..) and url(...) as the font source
	if ((p[0] == 'u' && p.slice(0, 4) == "url(")
	 || (p[0] == 'l' && p.slice(0, 6) == "local(")) {
		n = p.indexOf(')', 1)
		if (n < 0) {
			syntax(1, "No end of url in font family")
			return
		}

		font.src = p.slice(0, n + 1)
		font.fid = abc2svg.font_tb.length
		abc2svg.font_tb.push(font)
		font.name = 'ft' + font.fid
		p = p.replace(font.src, '')
	}

		// extract the font attributes
		a = p.match(/[- ]?[nN]ormal/)
		if (a) {
			font.normal = true
			p = p.replace(a[0], '')
		}

		// font weight
		a = p.match(abc2svg.ft_re)
		if (a) {
			font.weight = abc2svg.ft_w[a[0].replace(/[ -]/, '')
					.toLowerCase()]
			p = p.replace(a[0], '')
		}

		a = p.match(/[- ]?[iI]talic/)
		if (a) {
			font.style = "italic"
			p = p.replace(a[0], '')
		}
		a = p.match(/[- ]?[oO]blique/)
		if (a) {
			font.style = "oblique"
			p = p.replace(a[0], '')
		}

	if (!font.src) {			// if no url(...)

		// here is the font family
		p = p.trim()

		if (p == '*')
			p = ''
		p = p.replace(/Times-Roman|Times/, "serif")
			.replace("Helvetica", "sans-serif")
			.replace("Courier", "monospace")
			.replace("music", cfmt.musicfont.name)
//hack: the font "Figurato" is used for figured bass
			if (p.indexOf("Fig") > 0)
				font.figb = true
	}
	if (p && !font.name)
		font.name = p

	if (font.size)
		set_font_fac(font)

	// keep the previous attributes if no font name or no size
	if (!font.name || !font.size) {
		ft2 = cfmt[xxxfont]
		for (k in ft2) {
			if (!ft2.hasOwnProperty(k)
			 || font[k] != undefined)
				continue
			switch (k) {
			case "fid":
			case "used":
			case "src":
				break
			case "style":
			case "weight":
				if (font.normal)
					break
				// fall thru
			default:
				font[k] = ft2[k]
				break
			}
		}
		if (!font.swfac)
			set_font_fac(font)
	}
	if (font.pad == undefined)
		font.pad = 0
	font.fname = font.name
	if (font.weight >= 700)
		font.fname += 'Bold'

	cfmt[xxxfont] = font
}

// get a length with a unit - return the number of pixels
function get_unit(param) {
    var	v = param.toLowerCase().match(/(-?[\d.]+)(.*)/)
	if (!v)
		return NaN

	v[1] = +v[1]
	switch (v[2]) {
	case "cm":
		return v[1] * CM
	case "in":
		return v[1] * IN
	case "pt":		// paper point in 1/72 inch
		return v[1] / .75
	case "px":		// screen pixel in 1/96 inch
	case "":
		return v[1]
	}
	return NaN
}

// set the name of an info or a part
function set_infoname(cmd, param) {
//fixme: check syntax: '<letter> ["string"]'
    var	tmp = cfmt[cmd] ? cfmt[cmd].split("\n") : "",
		letter = param[0]

	for (var i = 0; i < tmp.length; i++) {
		var infoname = tmp[i]
		if (infoname[0] != letter)
			continue
		if (param.length == 1)
			tmp.splice(i, 1)
		else
			tmp[i] = param
		cfmt[cmd] = tmp.join('\n')
		return
	}
	if (cfmt[cmd])
		cfmt[cmd] += "\n" + param
	else
		cfmt[cmd] = param
}

// get the text option
var textopt = {
	align: 'j',
	center: 'c',
	fill: 'f',
	justify: 'j',
	obeylines: 'l',
	ragged: 'f',
	right: 'r',
	skip: 's',
// abcm2ps compatibility
	"0": 'l',
	"1": 'j',
	"2": 'f',
	"3": 'c',
	"4": 's',
	"5": 'r'
}
function get_textopt(v) {
    var	i = v.indexOf(' ')
	if (i > 0)
		v = v.slice(0, i)
	return textopt[v]
}

/* -- position of a voice element -- */
var posval = {
	above: C.SL_ABOVE,
	auto: 0,		// !! not C.SL_AUTO !!
	below: C.SL_BELOW,
	down: C.SL_BELOW,
	hidden: C.SL_HIDDEN,
	opposite: C.SL_HIDDEN,
	under: C.SL_BELOW,
	up: C.SL_ABOVE
}

/* -- set the position of elements in a voice -- */
function set_pos(k, v) {		// keyword, value
	k = k.slice(0, 3)
	if (k == "ste")
		k = "stm"
	set_v_param("pos", '"' + k + ' ' + v + '"')
}

// set/unset the fields to write
function set_writefields(parm) {
	var	c, i,
		a = parm.split(/\s+/)

	if (get_bool(a[1])) {
		for (i = 0; i < a[0].length; i++) {	// set
			c = a[0][i]
			if (cfmt.writefields.indexOf(c) < 0)
				cfmt.writefields += c
		}
	} else {
		for (i = 0; i < a[0].length; i++) {	// unset
			c = a[0][i]
			if (cfmt.writefields.indexOf(c) >= 0)
				cfmt.writefields = cfmt.writefields.replace(c, '')
		}
	}
}

// set a voice specific parameter
function set_v_param(k, v) {
	k = [k + '=', v]
	if (parse.state < 3)
		memo_kv_parm(curvoice ? curvoice.id : '*', k)
	else if (curvoice)
		set_kv_parm(k)
	else
		memo_kv_parm('*', k)
}

function set_page() {
	if (!img.chg)
		return
	img.chg = false;
	img.lm = cfmt.leftmargin - cfmt.printmargin
	if (img.lm < 0)
		img.lm = 0;
	img.rm = cfmt.rightmargin - cfmt.printmargin
	if (img.rm < 0)
		img.rm = 0;
	img.width = cfmt.pagewidth - 2 * cfmt.printmargin

	// must have 100pt at least as the staff width
	if (img.width - img.lm - img.rm < 100) {
		error(0, undefined, "Bad staff width");
		img.width = img.lm + img.rm + 150
	}
	set_posx()
} // set_page()

// set a format parameter
// (possible hook)
Abc.prototype.set_format = function(cmd, param) {
	var f, f2, v, i

//fixme: should check the type and limits of the parameter values
	if (/.+font(-[\d])?$/.test(cmd)) {
		if (cmd == "soundfont")
			cfmt.soundfont = param
		else
			param_set_font(cmd, param)
		return
	}

	// duplicate the global parameters if already used by symbols
	if (sfmt[cmd] && parse.ufmt)
		cfmt = Object.create(cfmt)

	switch (cmd) {
	case "aligncomposer":
	case "barsperstaff":
	case "infoline":
	case "measurenb":
	case "rbmax":
	case "rbmin":
	case "measrepnb":
	case "shiftunison":
	case "systnames":
	case "systvoices":
		v = parseInt(param)
		if (isNaN(v)) {
			syntax(1, "Bad integer value");
			break
		}
		if (cmd == "systnames") {	// compatibility
			switch (v) {
			case -1: v = 3; break
			case 1: v = 2; break
			case 2: v = 1; break
			}
			cmd = "systvoices"
		}
		cfmt[cmd] = v
		break
	case "abc-version":
	case "bgcolor":
	case "fgcolor":
	case "propagate-accidentals":
	case "writeout-accidentals":
		cfmt[cmd] = param
		break
	case "beamslope":
	case "breaklimit":			// float values
	case "lineskipfac":
	case "maxshrink":
	case "pagescale":
	case "parskipfac":
	case "scale":
	case "slurheight":
	case "stemheight":
	case "tieheight":
		f = +param
		if (isNaN(f) || !param || f < 0) {
			syntax(1, errs.bad_val, '%%' + cmd)
			break
		}
		switch (cmd) {
		case "scale":			// old scale
			f /= .75
		case "pagescale":
			if (f < .1)
				f = .1		// smallest scale
			cmd = "scale";
			img.chg = true
			break
		}
		cfmt[cmd] = f
		break
	case "annotationbox":
	case "gchordbox":
	case "measurebox":
	case "partsbox":
		param_set_font(cmd.replace("box", "font"),	// font
			"* * " + (get_bool(param) ? "box" : "nobox"))
		break
	case "altchord":
	case "bstemdown":
	case "breakoneoln":
	case "cancelkey":
	case "checkbars":
	case "contbarnb":
	case "custos":
	case "decoerr":
	case "flatbeams":
	case "graceslurs":
	case "graceword":
	case "hyphencont":
	case "keywarn":
	case "linewarn":
	case "squarebreve":
	case "splittune":
	case "straightflags":
	case "stretchstaff":
	case "timewarn":
	case "titlecaps":
	case "titleleft":
	case "trimsvg":
		cfmt[cmd] = get_bool(param)
		break
	case "dblrepbar":
		param = ":: " + param
		// fall thru
	case "bardef":			// %%bardef oldbar newbar
		v = param.split(/\s+/)
		if (v.length != 2) {
			syntax(1, errs.bad_val, "%%bardef")
		} else {
			if (parse.ufmt)
				cfmt.bardef = Object.create(cfmt.bardef)	// new object
			cfmt.bardef[v[0]] = v[1]
		}
		break
	case "chordalias":
		v = param.split(/\s+/)
		if (!v.length)
			syntax(1, errs.bad_val, "%%chordalias")
		else
			abc2svg.ch_alias[v[0]] = v[1] || ""
		break
	case "composerspace":
	case "indent":
	case "infospace":
	case "maxstaffsep":
	case "maxsysstaffsep":
	case "musicspace":
	case "partsspace":
	case "staffsep":
	case "subtitlespace":
	case "sysstaffsep":
	case "textspace":
	case "titlespace":
	case "topspace":
	case "vocalspace":
	case "wordsspace":
		f = get_unit(param)	// normally, unit in points - 72 DPI accepted
		if (isNaN(f) || f < 0)
			syntax(1, errs.bad_val, '%%' + cmd)
		else
			cfmt[cmd] = f
		break
	case "page-format":
		user.page_format = get_bool(param)
		break
	case "print-leftmargin":	// to remove
		syntax(0, "$1 is deprecated - use %%printmargin instead", '%%' + cmd)
		cmd = "printmargin"
		// fall thru
	case "printmargin":
//	case "botmargin":
	case "leftmargin":
//	case "pageheight":
	case "pagewidth":
	case "rightmargin":
//	case "topmargin":
		f = get_unit(param)	// normally unit in cm or in - 96 DPI
		if (isNaN(f)) {
			syntax(1, errs.bad_val, '%%' + cmd)
			break
		}
		cfmt[cmd] = f;
		img.chg = true
		break
	case "concert-score":
		if (cfmt.sound != "play")
			cfmt.sound = "concert"
		break
	case "writefields":
		set_writefields(param)
		break
	case "volume":
		cmd = "dynamic"
		// fall thru
	case "dynamic":
	case "gchord":
	case "gstemdir":
	case "ornament":
	case "stemdir":
	case "vocal":
		set_pos(cmd, param)
		break
	case "font":
		get_font_scale(param)
		break
	case "fullsvg":
		if (parse.state != 0) {
			syntax(1, errs.not_in_tune, "%%fullsvg")
			break
		}
//fixme: should check only alpha, num and '_' characters
		cfmt[cmd] = param
		break
	case "gracespace":
		v = param.split(/\s+/)
		for (i = 0; i < 3; i++)
			if (isNaN(+v[i])) {
				syntax(1, errs.bad_val, "%%gracespace")
				break
			}
		if (parse.ufmt)
			cfmt[cmd] = new Float32Array(3)
		for (i = 0; i < 3; i++)
			cfmt[cmd][i] = +v[i]
		break
	case "tuplets":
		v = param.split(/\s+/)
		f = v[3]
		if (f)			// if 'where'
			f = posval[f]	// translate the keyword
		if (f)
			v[3] = f
		if (curvoice)
			curvoice.tup = v
		else
			cfmt[cmd] = v
		break
	case "infoname":
	case "partname":
		set_infoname(cmd, param)
		break
	case "notespacingfactor":
		v = param.match(/([.\d]+)[,\s]*(\d+)?/)
		if (v) {
			f = +v[1]
			if (isNaN(f) || f < 1 || f > 2) {
				f = 0
			} else if (v[2]) {
				f2 = +v[2]
				if (isNaN(f))
					f = 0
			} else {
				f2 = cfmt.spatab[5]
			}
		}
		if (!f) {
			syntax(1, errs.bad_val, "%%" + cmd)
			break
		}
		cfmt[cmd] = param		// (for dump)

		// in the table 'spatab',
		// the width of notes is indexed by log2(note_length)
		cfmt.spatab = new Float32Array(10)
		i = 5;				// index of crotchet
		do {
			cfmt.spatab[i] = f2
			f2 /= f
		} while (--i >= 0)
		i = 5;
		f2 = cfmt.spatab[i]
		for ( ; ++i < cfmt.spatab.length; ) {
			f2 *= f;
			cfmt.spatab[i] = f2
		}
		break
	case "play":
		cfmt.sound = "play"		// without clef
		break
	case "pos":
		cmd = param.match(/(\w*)\s+(.*)/)
		if (!cmd || !cmd[2]) {
			syntax(1, "Error in %%pos")
			break
		}
		if (cmd[1].slice(0, 3) == 'tup'		// special case for %%pos tuplet
		 && curvoice) {				// inside tune
			if (!curvoice.tup)
				curvoice.tup = cfmt.tuplets
			else
				curvoice.tup = Object.create(curvoice.tup)
			v = posval[cmd[2]]
			switch (v) {
			case C.SL_ABOVE:
				curvoice.tup[3] = 1
				break
			case C.SL_BELOW:
				curvoice.tup[3] = 2
				break
			case C.SL_HIDDEN:
				curvoice.tup[2] = 1
				break
			}
			break
		}
		if (cmd[1].slice(0, 3) == "vol")
			cmd[1] = "dyn"			// compatibility
		set_pos(cmd[1], cmd[2])
		break
	case "sounding-score":
		if (cfmt.sound != "play")
			cfmt.sound = "sounding"
		break
	case "staffwidth":
		v = get_unit(param)
		if (isNaN(v)) {
			syntax(1, errs.bad_val, '%%' + cmd)
			break
		}
		if (v < 100) {
			syntax(1, "%%staffwidth too small")
			break
		}
		v = cfmt.pagewidth - v - cfmt.leftmargin
		if (v < 2) {
			syntax(1, "%%staffwidth too big")
			break
		}
		cfmt.rightmargin = v;
		img.chg = true
		break
	case "textoption":
		cfmt[cmd] = get_textopt(param)
		break
	case "dynalign":
	case "quiet":
	case "singleline":
	case "stretchlast":
	case "titletrim":
		v = param == '' ? 1 : +param
		if (isNaN(v))
			v = +get_bool(param)
		if (cmd[1] == 't') {		// stretchlast
			if (v < 0 || v > 1) {
				syntax(1, errs.bad_val, '%%' + cmd)
				break
			}
		}
		cfmt[cmd] = v
		break
	case "combinevoices":
		syntax(1, "%%combinevoices is deprecated - use %%voicecombine instead")
		break
	case "voicemap":
		set_v_param("map", param)
		break
	case "voicescale":
		set_v_param("scale", param)
		break
	case "unsizedsvg":
		if (get_bool(param))
			user.imagesize = ""
		else
			delete user.imagesize
		break
	// deprecated
	case "rbdbstop":
		v = get_bool(param)
		if (v && cfmt["abc-version"] >= "2.2")
			cfmt["abc-version"] = "1"
		else if (!v && cfmt["abc-version"] < "2.2")
			cfmt["abc-version"] = "2.2"
		break
	default:		// memorize all global commands
		if (!parse.state)		// (needed for modules)
			cfmt[cmd] = param
		break
	}

	// check if already a same format
	if (sfmt[cmd] && parse.ufmt) {
		// to do...
		parse.ufmt = false
	}
}

// font stuff

// build a font style
function st_font(font) {
    var	n = font.name,
	r = ""

	if (font.weight)
		r += font.weight + " "
	if (font.style)
		r += font.style + " "
	if (n.indexOf('"') < 0 && n.indexOf(' ') > 0)
		n = '"' + n + '"'
	return r + font.size.toFixed(1) + 'px ' + n
}
function style_font(font) {
	return 'font:' + st_font(font)
}
Abc.prototype.style_font = style_font

// build a font class
function font_class(font) {
    var	f = 'f' + font.fid + cfmt.fullsvg
	if (font.class)
		f += ' ' + font.class
	if (font.box)
		f += ' ' + 'box'
	return f
}

// use the font
function use_font(font) {
	if (!font.used) {
		font.used = true;
		if (font.fid == undefined) {	// if default font
			font.fid = abc2svg.font_tb.length
			abc2svg.font_tb.push(font)
			if (!font.swfac)
				set_font_fac(font)
			if (!font.pad)
				font.pad = 0
		}

			// set the pointer to the width of the characters
		if (!font.cw_tb) {
			font.cw_tb = !font.name ? ssw_tb
				: font.name.indexOf("ans") > 0
					? ssw_tb		// sans-serif
					: font.name.indexOf("ono") > 0
						? mw_tb		// monospace
						: sw_tb		// serif
		}
		add_fstyle(".f" + font.fid +
			(cfmt.fullsvg || "") +
			"{" + style_font(font) + "}")
		if (font.src)
			add_fstyle("@font-face{\n\
 font-family:" + font.name + ";\n\
 src:" + font.src + "}")
		if (font == cfmt.musicfont)	// add more music font style
			add_fstyle(".f" + font.fid
				+ (cfmt.fullsvg || "")
				+ ' text,tspan{white-space:pre}')
		if (ff.text && !ff.used && font.name.indexOf("text") >= 0) {
			font_style += ff.text	// add font-face's from %%beginsvg
			ff.used = 1 //true
		}
	}
}

// get the font of the 'xxxfont' parameter
function get_font(fn) {
    var	font, font2, fid, st

	fn += "font"
	font = cfmt[fn]
	if (!font) {
		syntax(1, "Unknown font $1", fn)
		return gene.curfont
	}

	if (!font.name || !font.size) {		// if incomplete user font
		font2 = Object.create(gene.deffont)
		if (font.name)
			font2.name = font.name
		if (font.normal) {
			if (font2.weight)	// !! don't use delete !!
				font2.weight = null
			if (font2.style)
				font2.style = null
		}
			if (font.weight)
				font2.weight = font.weight
			if (font.style)
				font2.style = font.style
		if (font.src)
			font2.src = font.src
		if (font.size)
			font2.size = font.size
		st = st_font(font2)
		if (font.class) {
			font2.class = font.class
			st += ' '+ font.class
		}
		fid = abc2svg.font_st[st]
		if (fid != undefined)
			return abc2svg.font_tb[fid]
		abc2svg.font_st[st] = abc2svg.font_tb.length	// will be the font id
		font2.fid = font2.used = undefined
		font = font2
	}
	use_font(font)
	return font
}
// abc2svg - front.js - ABC parsing front-end
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

    var	sav = {},	// save global (between tunes) definitions
	mac = {},	// macros (m:)
	maci = {},	// first letters of macros
	modone = {}	// hooks done by module

// translation table from the ABC draft version 2.2
var abc_utf = {
	"=D": "Đ",
	"=H": "Ħ",
	"=T": "Ŧ",
	"=d": "đ",
	"=h": "ħ",
	"=t": "ŧ",
	"/O": "Ø",
	"/o": "ø",
//	"/D": "Đ",
//	"/d": "đ",
	"/L": "Ł",
	"/l": "ł",
	"vL": "Ľ",
	"vl": "ľ",
	"vd": "ď",
	".i": "ı",
	"AA": "Å",
	"aa": "å",
	"AE": "Æ",
	"ae": "æ",
	"DH": "Ð",
	"dh": "ð",
//	"ng": "ŋ",
	"OE": "Œ",
	"oe": "œ",
	"ss": "ß",
	"TH": "Þ",
	"th": "þ"
}

// accidentals as octal values (abcm2ps compatibility)
var oct_acc = {
	"1": "\u266f",
	"2": "\u266d",
	"3": "\u266e",
	"4": "&#x1d12a;",
	"5": "&#x1d12b;"
}

// convert the escape sequences to utf-8
function cnv_escape(src, flag) {
	var	c, c2,
		dst = "",
		i, j = 0

	while (1) {
		i = src.indexOf('\\', j)
		if (i < 0)
			break
		dst += src.slice(j, i);
		c = src[++i]
		if (!c)
			return dst + '\\'
		switch (c) {
		case '0':
		case '2':
			if (src[i + 1] != '0')
				break
			c2 = oct_acc[src[i + 2]]
			if (c2) {
				dst += c2;
				j = i + 3
				continue
			}
			break
		case 'u':
			j = Number("0x" + src.slice(i + 1, i + 5));
			if (isNaN(j) || j < 0x20) {
				dst += src[++i] + "\u0306"	// breve accent
				j = i + 1
				continue
			}
			c = String.fromCharCode(j)
			if (c == '\\') {
				i += 4
				break
			}
			dst += c
			j = i + 5
			continue
		case 't':			// TAB
			dst += '\t';
			j = i + 1
			continue
		case 'n':			// new line (voice name)
			dst += '\n';
			j = i + 1
			continue
		default:
			c2 = abc_utf[src.slice(i, i + 2)]
			if (c2) {
				dst += c2;
				j = i + 2
				continue
			}

			// try unicode combine characters
			c2 = src[i + 1]
			if (!c2)
				break	// !! the next test is true if c2 is undefined !!
			if (!/[A-Za-z]/.test(c2))
				break
			switch (c) {
			case '`':
				dst += c2 + "\u0300"	// grave
				j = i + 2
				continue
			case "'":
				dst += c2 + "\u0301"	// acute
				j = i + 2
				continue
			case '^':
				dst += c2 + "\u0302"	// circumflex
				j = i + 2
				continue
			case '~':
				dst += c2 + "\u0303"	// tilde
				j = i + 2
				continue
			case '=':
				dst += c2 + "\u0304"	// macron
				j = i + 2
				continue
			case '_':
				dst += c2 + "\u0305"	// overline
				j = i + 2
				continue
			case '.':
				dst += c2 + "\u0307"	// dot
				j = i + 2
				continue
			case '"':
				dst += c2 + "\u0308"	// dieresis
				j = i + 2
				continue
			case 'o':
				dst += c2 + "\u030a"	// ring
				j = i + 2
				continue
			case 'H':
				dst += c2 + "\u030b"	// hungarumlaut
				j = i + 2
				continue
			case 'v':
				dst += c2 + "\u030c"	// caron
				j = i + 2
				continue
//			case ',':
//				dst += c2 + "\u0326"	// comma below
//				j = i + 2
//				continue
			case 'c':
				dst += c2 + "\u0327"	// cedilla
				j = i + 2
				continue
			case ';':
				dst += c2 + "\u0328"	// ogonek
				j = i + 2
				continue
			}
			break
		}
		if (flag == 'w')	// if lyrics line (w:)
			dst += '\\'	// keep the backslash
		dst += c
		j = i + 1
	}
	return dst + src.slice(j)
}

// ABC include
var include = 0

function do_include(fn) {
	var file, parse_sav

	if (!user.read_file) {
		syntax(1, "No read_file support")
		return
	}
	if (include > 2) {
		syntax(1, "Too many include levels")
		return
	}
	file = user.read_file(fn)
	if (!file) {
		syntax(1, "Cannot read file '$1'", fn)
		return
	}
	include++;
	parse_sav = clone(parse);
	tosvg(fn, file);
	parse_sav.state = parse.state;
	parse_sav.ckey = parse.ckey
	parse = parse_sav;
	include--
}

// parse ABC code
function tosvg(in_fname,		// file name
		file,			// file content
		bol, eof) {		// beginning/end of file
	var	i, c, eol, end,
		select,
		line0, line1,
		last_info, opt, text, a, b, s,
		pscom,
		txt_add = '\n'		// for "+:"

	// check if a tune is selected
	function tune_selected() {
		var	re, res,
			i = file.indexOf('K:', bol)

		if (i < 0) {
//			syntax(1, "No K: in tune")
			return false
		}
		i = file.indexOf('\n', i)
		if (parse.select.test(file.slice(parse.bol, i)))
			return true
		re = /\n\w*\n/;
		re.lastIndex = i;
		res = re.exec(file)
		if (res)
			eol = re.lastIndex
		else
			eol = eof
		return false
	} // tune_selected()

	// remove the comment at end of text
	// if flag, handle the escape sequences
	// if flag is 'w' (lyrics), keep the '\'s
	function uncomment(src, flag) {
		if (!src)
			return src
	    var	i = src.indexOf('%')
		if (i == 0)
			return ''
		if (i > 0)
			src = src.replace(/([^\\])%.*/, '$1')
				 .replace(/\\%/g, '%');
		src = src.replace(/\s+$/, '')
		if (flag && src.indexOf('\\') >= 0)
			return cnv_escape(src, flag)
		return src
	} // uncomment()

	// set the sequence showing the source and save it in sav.src
	function set_src(stag, se) {
	    var	r, t,
		etag = ""

		if (!se)
			se = file.indexOf('\n\n', bol)	// end of tune
		if (se < 0)
			se = eof
		if (typeof stag != "object") {		// set the tag after source
			if (stag[0] != 'b' && stag[0] != 'a' && stag[0] != '+'
			 && stag[0] != '*')
				stag = 'b' + stag	// default: source before
			if (stag[1] != '<')		// (if bool)
				stag = stag[0] + "<pre>"
			r = stag.match(/<\/?[^>]*>/g)
			while (1) {
				t = r.pop()
				if (!t)
					break
				if (t[1] == '/' || t.slice(-2) == '/>')
					r.pop()		// skip this stop/start tag
				else
					etag += '</' + t.slice(1)
			}
			cfmt.show_source = stag = [stag, etag]
		}
		t = stag[0].slice(1)
			+ clean_txt(file.slice(bol, se))
			+ stag[1]
		if (stag[0][0] == '+' && sav.src)
			sav.src += t
		else
			sav.src = t
	} // set_src()

	function end_tune() {
		parse.bol = bol				// (for multi V:)
		generate()
		cfmt = sav.cfmt;
		info = sav.info;
		char_tb = sav.char_tb;
		glovar = sav.glovar;
		maps = sav.maps;
		mac = sav.mac;
		maci = sav.maci;
		parse.tune_v_opts = null;
		parse.scores = null;
		parse.ufmt = false
		delete parse.pq
		init_tune()
		img.chg = true;
		set_page();
		if (cfmt.show_source) {
			user.img_out("</div>")
			if (cfmt.show_source[0][0] == 'a')
				user.img_out(sav.src)
		}
	} // end_tune()

	// get %%voice
	function do_voice(select, in_tune) {
	    var	opt, bol
		if (select == "end")
			return		// end of previous %%voice

		// get the options
		if (in_tune) {
			if (!parse.tune_v_opts)
				parse.tune_v_opts = {};
			opt = parse.tune_v_opts
		} else {
			if (!parse.voice_opts)
				parse.voice_opts = {};
			opt = parse.voice_opts
		}
		opt[select] = []
		while (1) {
			bol = ++eol
			if (file[bol] != '%')
				break
			eol = file.indexOf('\n', eol);
			if (file[bol + 1] != line1)
				continue
			bol += 2
			if (eol < 0)
				text = file.slice(bol)
			else
				text = file.slice(bol, eol);
			a = text.match(/\S+/)
			switch (a[0]) {
			default:
				opt[select].push(uncomment(text, true))
				continue
			case "score":
			case "staves":
			case "tune":
			case "voice":
				bol -= 2
				break
			}
			break
		}
		eol = parse.eol = bol - 1
	} // do_voice()

	// apply the options to the current tune
	function tune_filter() {
	    var	o, opts, j, pc, h,
		i = file.indexOf('K:', bol)

		i = file.indexOf('\n', i);
		h = file.slice(parse.bol, i)	// tune header

		for (i in parse.tune_opts) {
			if (!parse.tune_opts.hasOwnProperty(i))
				continue
			if (!(new RegExp(i)).test(h))
				continue
			opts = parse.tune_opts[i]
			for (j = 0; j < opts.t_opts.length; j++) {
				pc = opts.t_opts[j]
				switch (pc.match(/\S+/)[0]) {
				case "score":
				case "staves":
					if (!parse.scores)
						parse.scores = [];
					parse.scores.push(pc)
					break
				default:
					self.do_pscom(pc)
					break
				}
			}
			opts = opts.v_opts
			if (!opts)
				continue
			for (j in opts) {
				if (!opts.hasOwnProperty(j))
					continue
				if (!parse.tune_v_opts)
					parse.tune_v_opts = {};
				if (!parse.tune_v_opts[j])
					parse.tune_v_opts[j] = opts[j]
				else
					parse.tune_v_opts[j] =
						parse.tune_v_opts[j].
								concat(opts[j])
			}
		}
	} // tune_filter()

	// export functions and/or set module hooks
	if (abc2svg.mhooks) {
		for (i in abc2svg.mhooks) {
			if (!modone[i]) {
				modone[i] = 1 //true
				abc2svg.mhooks[i](self)
			}
		}
	}

	// initialize
	parse.file = file;		// used for errors
	parse.fname = in_fname

	// scan the file
	if (bol == undefined)
		bol = 0
	if (!eof)
		eof = file.length
	if (file.slice(bol, bol + 5) == "%abc-")
		cfmt["abc-version"] = /[1-9.]+/.exec(file.slice(bol + 5, bol + 10))
	for ( ; bol < eof; bol = parse.eol + 1) {
		eol = file.indexOf('\n', bol)	// get a line
		if (eol < 0 || eol > eof)
			eol = eof;
		parse.eol = eol

		// remove the ending white spaces
		while (1) {
			eol--
			switch (file[eol]) {
			case ' ':
			case '\t':
				continue
			}
			break
		}
		eol++
		if (eol == bol) {		// empty line
			if (parse.state == 1) {
				parse.istart = bol;
				syntax(1, "Empty line in tune header - ignored")
			} else if (parse.state >= 2) {
				end_tune()
				parse.state = 0
				if (parse.select) {	// skip to next tune
					eol = file.indexOf('\nX:', parse.eol)
					if (eol < 0)
						eol = eof
					parse.eol = eol
				}
			}
			continue
		}
		parse.istart = parse.bol = bol;
		parse.iend = eol;
		parse.line.index = 0;

		// check if the line is a pseudo-comment or I:
		line0 = file[bol];
		line1 = file[bol + 1]
		if ((line0 == 'I' && line1 == ':')
		  || line0 == '%') {
			if (line0 == '%' && parse.prefix.indexOf(line1) < 0)
				continue		// comment

			// change "%%abc xxxx" to "xxxx"
			if (file[bol + 2] == 'a'
			 && file[bol + 3] == 'b'
			 && file[bol + 4] == 'c'
			 && file[bol + 5] == ' ') {
				bol += 6;
				line0 = file[bol];
				line1 = file[bol + 1]
			} else {
				pscom = true
			}
		}

		// pseudo-comments
		if (pscom) {
			pscom = false;
			bol += 2		// skip %%/I:
			text = file.slice(bol, eol)
			a = text.match(/([^\s]+)\s*(.*)/)
			if (!a || a[1][0] == '%')
				continue
			switch (a[1]) {
			case "abcm2ps":
			case "ss-pref":
				parse.prefix = a[2]	// may contain a '%'
				continue
			case "abc-include":
				do_include(uncomment(a[2]))
				continue
			}

			// beginxxx/endxxx
			if (a[1].slice(0, 5) == 'begin') {
				b = a[1].substr(5);
				end = '\n' + line0 + line1 + "end" + b;
				i = file.indexOf(end, eol)
				if (i < 0) {
					syntax(1, "No $1 after %%$2",
							end.slice(1), a[1]);
					parse.eol = eof
					continue
				}
				self.do_begin_end(b, uncomment(a[2]),
					file.slice(eol + 1, i)
						.replace(/\n%[^%].*$/gm,'')
						.replace(/^%%/gm,''))
				parse.eol = file.indexOf('\n', i + 6)
				if (parse.eol < 0)
					parse.eol = eof
				continue
			}
			switch (a[1]) {
			case "show_source":
				b = uncomment(a[2])
				switch (b[0]) {
				case '*':
					i = file.indexOf('\n' + line0 + line1
							+ "show_source", eol)
					bol -= 2	// keep %%show_.. in the source
					set_src(b, i)
					user.img_out(sav.src)
					// fall thru
				case '0':
					b = ""
					// fall thru
				default:
					cfmt[a[1]] = b
					// fall thru
				}
				continue
			case "select":
				if (parse.state != 0) {
					syntax(1, errs.not_in_tune, "%%select")
					continue
				}
				select = uncomment(a[2])
				if (select[0] == '"')
					select = select.slice(1, -1);
				if (!select) {
					delete parse.select
					continue
				}
				select = select.replace(/\(/g, '\\(');
				select = select.replace(/\)/g, '\\)');
//				select = select.replace(/\|/g, '\\|');
				parse.select = new RegExp(select, 'm')
				continue
			case "tune":
				if (parse.state != 0) {
					syntax(1, errs.not_in_tune, "%%tune")
					continue
				}
				select = uncomment(a[2])

				// if void %%tune, free all tune options
				if (!select) {
					parse.tune_opts = {}
					continue
				}
				
				if (select == "end")
					continue	// end of previous %%tune

				if (!parse.tune_opts)
					parse.tune_opts = {};
				parse.tune_opts[select] = opt = {
						t_opts: []
//						v_opts: {}
					};
				while (1) {
					bol = eol
					if (file[bol + 1] != '%')
						break
					eol = file.indexOf('\n', eol + 1)
					if (file[bol + 2] != line1)
						continue
					text = file.slice(bol + 3,
							eol < 0 ? undefined : eol)
					a = text.match(/([^\s]+)\s*(.*)/)
					switch (a[1]) {
					case "tune":
						break
					case "voice":
						do_voice(uncomment(a[2],
								true), true)
						continue
					default:
						opt.t_opts.push(
							uncomment(text, true))
						continue
					}
					break
				}
				if (parse.tune_v_opts) {
					opt.v_opts = parse.tune_v_opts;
					parse.tune_v_opts = null
				}
				parse.eol = bol
				continue
			case "voice":
				if (parse.state != 0) {
					syntax(1, errs.not_in_tune, "%%voice")
					continue
				}
				select = uncomment(a[2])

				/* if void %%voice, free all voice options */
				if (!select) {
					parse.voice_opts = null
					continue
				}
				
				do_voice(select)
				continue
			}
			self.do_pscom(uncomment(text, true))
			continue
		}

		// music line (or free text)
		if (line1 != ':' || !/[A-Za-z+]/.test(line0)) {
			last_info = undefined;
			if (parse.state < 2)
				continue
			parse.line.buffer = uncomment(file.slice(bol, eol))
			if (parse.line.buffer)
				parse_music_line()
			continue
		}

		// information fields
		bol += 2
		while (1) {
			switch (file[bol]) {
			case ' ':
			case '\t':
				bol++
				continue
			}
			break
		}
		if (line0 == '+') {
			if (!last_info) {
				syntax(1, "+: without previous info field")
				continue
			}
			txt_add = ' ';		// concatenate
			line0 = last_info
		}
		text = uncomment(file.slice(bol, eol), line0)

		switch (line0) {
		case 'X':			// start of tune
			if (parse.state != 0) {
				syntax(1, errs.ignored, line0)
				continue
			}
			if (parse.select
			 && !tune_selected()) {	// skip to the next tune
				eol = file.indexOf('\nX:', parse.eol)
				if (eol < 0)
					eol = eof;
				parse.eol = eol
				continue
			}

			sav.cfmt = clone(cfmt);
			sav.info = clone(info, 2)	// (level 2 for info.V[])
			sav.char_tb = clone(char_tb);
			sav.glovar = clone(glovar);
			sav.maps = clone(maps, 1);
			sav.mac = clone(mac);
			sav.maci = clone(maci);
			if (cfmt.show_source) {
				bol -= 2
				set_src(cfmt.show_source)
				if (cfmt.show_source[0][0] == 'b')
					user.img_out(sav.src)
				user.img_out('<div class="source">')
			}
			info.X = text;
			parse.state = 1			// tune header
			if (parse.tune_opts)
				tune_filter()
			continue
		case 'T':
			switch (parse.state) {
			case 0:
				continue
			case 1:
			case 2:
				text = trim_title(text, info.T)
				if (info.T == undefined)	// (keep empty T:)
					info.T = text
				else
					info.T += "\n" + text
				continue
			}
			s = new_block("title");
			s.text = text
			continue
		case 'K':
			switch (parse.state) {
			case 0:
				continue
			case 1:				// tune header
				info.K = text
				break
			}
			do_info(line0, text)
			continue
		case 'W':
			if (parse.state == 0
			 || cfmt.writefields.indexOf(line0) < 0)
				break
			if (info.W == undefined)
				info.W = text
			else
				info.W += txt_add + text
			break

		case 'm':
			if (parse.state >= 2) {
				syntax(1, errs.ignored, line0)
				continue
			}
			a = text.match(/(.*?)[= ]+(.*)/)
			if (!a || !a[2]) {
				syntax(1, errs.bad_val, "m:")
				continue
			}
			mac[a[1]] = a[2];
			maci[a[1][0]] = true	// first letter
			break

		// info fields in tune body only
		case 's':
			if (parse.state != 3
			 || cfmt.writefields.indexOf(line0) < 0)
				break
			get_sym(text, txt_add == ' ')
			break
		case 'w':
			if (parse.state != 3
			 || cfmt.writefields.indexOf(line0) < 0)
				break
			get_lyrics(text, txt_add == ' ')
			break
		case '|':			// "|:" starts a music line
			if (parse.state < 2)
				continue
			parse.line.buffer = text
			parse_music_line()
			continue
		default:
			if ("ABCDFGHNOSZ".indexOf(line0) >= 0) {
				if (parse.state >= 2) {
					syntax(1, errs.ignored, line0)
					continue
				}
//				if (cfmt.writefields.indexOf(c) < 0)
//					break
				if (!info[line0])
					info[line0] = text
				else
					info[line0] += txt_add + text
				break
			}

			// info field which may be embedded
			do_info(line0, text)
			continue
		}
		txt_add = '\n';
		last_info = line0
	}
	if (include)
		return
	if (parse.state == 1) {
		syntax(1, "End of file in tune header")
		get_key("C")
	}
	if (parse.state >= 2)
		end_tune();
	if (sav.src && cfmt.show_source[0] == '+') {
		user.img_out(sav.src)		// source of all tunes
		sav.src = null
	}
	parse.state = 0
}
Abc.prototype.tosvg = tosvg
// abc2svg - music.js - music generation
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

var	gene,
	staff_tb,
	nstaff,			// current number of staves
	tsnext,			// next line when cut
	realwidth,		// real staff width while generating
	insert_meter,		// insert the time signature
	spf_last,		// spacing for last short line

	smallest_duration

/* -- decide whether to shift heads to other side of stem on chords -- */
/* this routine is called only once per tune */

// distance for no overlap - index: [prev acc][cur acc]
//var dt_tb = [
//	[5, 5, 5, 5],		/* dble sharp */
//	[5, 6, 6, 6],		/* sharp */
//	[5, 6, 5, 6],		/* natural */
//	[5, 5, 5, 5]		/* flat / dble flat */
//]

// accidental x offset - index = note head type
var dx_tb = new Float32Array([
	9.5,		// FULL
	9.5,		// EMPTY
	13,		// OVAL
	16,		// OVALBARS
	16		// SQUARE
])

// head width  - index = note head type
var hw_tb = new Float32Array([
	4.7,		// FULL
	5,		// EMPTY
	6,		// OVAL
	7.2,		// OVALBARS
	7.5		// SQUARE
])

/* head width for voice overlap - index = note head type */
var w_note = new Float32Array([
	2.5,		// FULL
	3,		// EMPTY
	4.5,		// OVAL
	6,		// OVALBARS
	6.5		// SQUARE
])

// get head type, dots, flags of note/rest for a duration
function identify_note(s, dur_o) {
    var	r = abc2svg.hdn[dur_o]
	if (r)				// in cache?
		return r

    var	head, flags,
	dots = 0,
	dur = dur_o

	if (dur % 12 != 0)
		error(1, s, "Invalid note duration $1", dur);
	dur /= 12			/* see C.BLEN for values */
	if (!dur)
		error(1, s, "Note too short")
	for (flags = 5; dur; dur >>= 1, flags--) {
		if (dur & 1)
			break
	}
	dur >>= 1
	while (dur >> dots > 0)
		dots++

	flags -= dots
	if (flags >= 0) {
		head = C.FULL
	} else switch (flags) {
	default:
		error(1, s, "Note too long")
		flags = -4
		/* fall thru */
	case -4:
		head = C.SQUARE
		break
	case -3:
		head = s.fmt.squarebreve ? C.SQUARE : C.OVALBARS
		break
	case -2:
		head = C.OVAL
		break
	case -1:
		head = C.EMPTY
		break
	}
	abc2svg.hdn[dur_o] =
		r = [head, dots, flags]
	return r
}

function set_head_shift(s) {
	var	i, i1, i2, d, ps, dx,
		dx_head = dx_tb[s.head],
		dir = s.stem,
		n = s.nhd

	if (!n)
		return			// single note

	/* set the head shifts */
	dx = dx_head * .74
	if (s.grace)
		dx *= .6
	if (dir >= 0) {
		i1 = 1;
		i2 = n + 1;
		ps = s.notes[0].pit
	} else {
		dx = -dx;
		i1 = n - 1;
		i2 = -1;
		ps = s.notes[n].pit
	}
	var	shift = false,
		dx_max = 0
	for (i = i1; i != i2; i += dir) {
		d = s.notes[i].pit - ps;
		ps = s.notes[i].pit
		if (!d) {
			if (shift) {		/* unison on shifted note */
				var new_dx = s.notes[i].shhd =
						s.notes[i - dir].shhd + dx
				if (dx_max < new_dx)
					dx_max = new_dx
				continue
			}
			if (i + dir != i2	/* second after unison */
//fixme: should handle many unisons after second
			 && ps + dir == s.notes[i + dir].pit) {
				s.notes[i].shhd = -dx
				if (dx_max < -dx)
					dx_max = -dx
				continue
			}
		}
		if (d < 0)
			d = -d
		if (d > 3 || (d >= 2 && s.head != C.SQUARE)) {
			shift = false
		} else {
			shift = !shift
			if (shift) {
				s.notes[i].shhd = dx
				if (dx_max < dx)
					dx_max = dx
			}
		}
	}
	s.xmx = dx_max				/* shift the dots */
}

// set the accidental shifts for a set of chords
// @grh = head width when grace notes
function acc_shift(notes, grh) {
    var	i, i1, i2, dx, dx1, dx2, ps, p1, acc, dxh,
	n = notes.length

	// set the shifts from the head shifts
	for (i = n - 1; --i >= 0; ) {	// (no shift on top)
		dx = notes[i].shhd
		if (!dx || dx > 0)
			continue
//fixme: '9' is the width of a quarter note
		dx = (grh || (notes[i].s ? dx_tb[notes[i].s.head] : 9))
			- dx
		ps = notes[i].pit
		for (i1 = n; --i1 >= 0; ) {
			if (!notes[i1].acc)
				continue
			p1 = notes[i1].pit
			if (p1 < ps - 3)
				break
			if (p1 > ps + 3)
				continue
			if (notes[i1].shac < dx)
				notes[i1].shac = dx
		}
	}

	// set the shifts of the highest and lowest notes
	for (i1 = n; --i1 >= 0; ) {
		if (notes[i1].acc) {
			p1 = notes[i1].pit	// top note with accidental
			dx1 = notes[i1].shac
			if (!dx1) {
				dx1 = notes[i1].shhd
				dxh = grh || dx_tb[notes[i1].s.head]
				if (dx1 < 0)
					dx1 = dxh - dx1
				else
					dx1 = dxh
			}
			break
		}
	}
	if (i1 < 0)				// no accidental
		return
	for (i2 = 0; i2 < i1; i2++) {
		if (notes[i2].acc) {
			ps = notes[i2].pit	// bottom note with accidental
			dx2 = notes[i2].shac
			if (!dx2) {
				dx2 = notes[i2].shhd
				dxh = grh || dx_tb[notes[i2].s.head]
				if (dx2 < 0)
					dx2 = dxh - dx2
				else
					dx2 = dxh
			}
			break
		}
	}
	if (i1 == i2) {			// only one accidental
		notes[i1].shac = dx1
		return
	}

	if (p1 > ps + 4) {		// if interval greater than a sixth
		if (dx1 > dx2)
			dx2 = dx1	// align the accidentals
		notes[i1].shac = notes[i2].shac = dx2
	} else {
		notes[i1].shac = dx1
		if (notes[i1].pit != notes[i2].pit
		 || notes[i1].acc != notes[i2].acc)
			dx1 += 7
		notes[i2].shac = dx2 = dx1
	}
	dx2 += 7

	// shift the remaining accidentals
	for (i = i1; --i > i2; ) {		// from top to bottom
		acc = notes[i].acc
		if (!acc)
			continue
		dx = notes[i].shac
		if (dx < dx2)
			dx = dx2
		ps = notes[i].pit
		for (i1 = n; --i1 > i; ) {
			if (!notes[i1].acc)
				continue
			p1 = notes[i1].pit
			if (p1 >= ps + 4) {	// pitch far enough
				if (p1 > ps + 4	// if more than a fifth
				 || acc < 0	// if flat/dble flat
				 || notes[i1].acc < 0)
					continue
			}
			if (dx > notes[i1].shac - 6) {
				dx1 = notes[i1].shac + 7
				if (dx1 > dx)
					dx = dx1
			}
		}
		notes[i].shac = dx
	}
}

/* set the horizontal shift of accidentals */
/* this routine is called only once per tune */
function set_acc_shft() {
    var	s, s2, st, i, acc, st, t, notes

	// search the notes with accidentals at the same time
	s = tsfirst
	while (s) {
		if (s.type != C.NOTE
		 || s.invis) {
			s = s.ts_next
			continue
		}
		st = s.st;
		t = s.time;
		acc = false
		for (s2 = s; s2; s2 = s2.ts_next) {
			if (s2.time != t
			 || s2.type != C.NOTE
			 || s2.st != st)
				break
			for (i = 0; i <= s2.nhd; i++) {
				if (s2.notes[i].acc) {
					s2.notes[i].s = s2
					acc = true
				}
			}
		}
		if (!acc) {
			s = s2
			continue
		}

		// build a pseudo chord and shift the accidentals
		notes = []
		for ( ; s != s2; s = s.ts_next) {
			if (!s.invis)
				Array.prototype.push.apply(notes, s.notes)
		}
		notes.sort(abc2svg.pitcmp)
		acc_shift(notes)
	}
}

// link a symbol before an other one
function lkvsym(s, next) {	// voice linkage
	s.next = next;
	s.prev = next.prev
	if (s.prev)
		s.prev.next = s
	else
		s.p_v.sym = s;
	next.prev = s
}
function lktsym(s, next) {	// time linkage
    var	old_wl

	s.ts_next = next
	if (next) {
		s.ts_prev = next.ts_prev
		if (s.ts_prev)
			s.ts_prev.ts_next = s;
		next.ts_prev = s
	} else {
//fixme
error(2, s, "Bad linkage")
		s.ts_prev = null
	}
	s.seqst = !s.ts_prev
		|| s.time != s.ts_prev.time
		|| (w_tb[s.ts_prev.type] != w_tb[s.type]
		 && !!w_tb[s.ts_prev.type])
	if (!next || next.seqst)
		return
	next.seqst = next.time != s.time ||
			(w_tb[s.type] != w_tb[next.type]
			 && !!w_tb[s.type])
	if (next.seqst) {
		old_wl = next.wl
		self.set_width(next)
		if (next.a_ly)
			ly_set(next)
		if (!next.shrink) {
			next.shrink = next.wl
			if (next.prev)
				next.shrink += next.prev.wr
		} else {
			next.shrink += next.wl - old_wl
		}
		next.space = 0
	}
}

/* -- unlink a symbol -- */
function unlksym(s) {
	if (s.next)
		s.next.prev = s.prev
	if (s.prev)
		s.prev.next = s.next
	else
		s.p_v.sym = s.next
	if (s.ts_next) {
		if (s.seqst) {
		    if (s.ts_next.seqst) {
			s.ts_next.shrink += s.shrink;
			s.ts_next.space += s.space
		    } else {
			s.ts_next.seqst = true;
			s.ts_next.shrink = s.shrink;
			s.ts_next.space = s.space
		    }
		} else {
			if (s.ts_next.seqst
			 && s.ts_prev && s.ts_prev.seqst
			 && !w_tb[s.ts_prev.type]) {
				s.ts_next.seqst = false
				s.shrink = s.ts_next.shrink
				s.space = s.ts_next.space
			}
		}
		s.ts_next.ts_prev = s.ts_prev
	}
	if (s.ts_prev)
		s.ts_prev.ts_next = s.ts_next
	if (tsfirst == s)
		tsfirst = s.ts_next
	if (tsnext == s)
		tsnext = s.ts_next
}

/* -- insert a clef change (treble or bass) before a symbol -- */
function insert_clef(s, clef_type, clef_line) {
	var	p_voice = s.p_v,
		new_s,
		st = s.st

	/* don't insert the clef between two bars */
	if (s.type == C.BAR && s.prev && s.prev.type == C.BAR
	 && s.prev.bar_type[0] != ':')
		s = s.prev;

	/* create the symbol */
	p_voice.last_sym = s.prev
	if (!p_voice.last_sym)
		p_voice.sym = null;
	p_voice.time = s.time;
	new_s = sym_add(p_voice, C.CLEF);
	new_s.next = s;
	s.prev = new_s;

	new_s.clef_type = clef_type;
	new_s.clef_line = clef_line;
	new_s.st = st;
	new_s.clef_small = true
	delete new_s.second;
	new_s.notes = []
	new_s.notes[0] = {
		pit: s.notes[0].pit
	}
	new_s.nhd = 0;

	/* link in time */
	while (!s.seqst)
		s = s.ts_prev;
	lktsym(new_s, s)
	if (s.soln) {			// move the start of line
		new_s.soln = true
		delete s.soln
	}
	return new_s
}

/* -- set the staff of the floating voices -- */
/* this function is called only once per tune */
function set_float() {
	var p_voice, st, staff_chg, v, s, s1, up, down

	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v]
//		if (!p_voice.floating)
//			continue
		staff_chg = false;
		st = p_voice.st
		for (s = p_voice.sym; s; s = s.next) {
			if (!s.floating) {
				while (s && !s.floating)
					s = s.next
				if (!s)
					break
				staff_chg = false
			}
			if (!s.dur) {
				if (staff_chg)
					s.st++
				continue
			}
			if (s.notes[0].pit >= 19) {		/* F */
				staff_chg = false
				continue
			}
			if (s.notes[s.nhd].pit <= 12) {	/* F, */
				staff_chg = true
				s.st++
				continue
			}
			up = 127
			for (s1 = s.ts_prev; s1; s1 = s1.ts_prev) {
				if (s1.st != st
				 || s1.v == s.v)
					break
				if (s1.type == C.NOTE)
				    if (s1.notes[0].pit < up)
					up = s1.notes[0].pit
			}
			if (up == 127) {
				if (staff_chg)
					s.st++
				continue
			}
			if (s.notes[s.nhd].pit > up - 3) {
				staff_chg = false
				continue
			}
			down = -127
			for (s1 = s.ts_next; s1; s1 = s1.ts_next) {
				if (s1.st != st + 1
				 || s1.v == s.v)
					break
				if (s1.type == C.NOTE)
				    if (s1.notes[s1.nhd].pit > down)
					down = s1.notes[s1.nhd].pit
			}
			if (down == -127) {
				if (staff_chg)
					s.st++
				continue
			}
			if (s.notes[0].pit < down + 3) {
				staff_chg = true
				s.st++
				continue
			}
			up -= s.notes[s.nhd].pit
			down = s.notes[0].pit - down
			if (!staff_chg) {
				if (up < down + 3)
					continue
				staff_chg = true
			} else {
				if (up < down - 3) {
					staff_chg = false
					continue
				}
			}
			s.st++
		}
	}
}

/* -- set the x offset of the grace notes -- */
function set_graceoffs(s) {
	var	next, m, dx, x,
		gspleft = s.fmt.gracespace[0],
		gspinside = s.fmt.gracespace[1],
		gspright = s.fmt.gracespace[2],
		g = s.extra;

	if (s.prev && s.prev.type == C.BAR)
		gspleft -= 3;
	x = gspleft;

	g.beam_st = true
	for ( ; ; g = g.next) {
		set_head_shift(g)
		acc_shift(g.notes, 6.5)
		dx = 0
		for (m = g.nhd; m >= 0; m--) {
			if (g.notes[m].shac - 2 > dx)
				dx = g.notes[m].shac - 2
		}
		x += dx;
		g.x = x

		if (g.nflags <= 0)
			g.beam_st = g.beam_end = true
		next = g.next
		if (!next) {
			g.beam_end = true
			break
		}
		if (next.nflags <= 0)
			g.beam_end = true
		if (g.beam_end) {
			next.beam_st = true;
			x += gspinside / 4
		}
		if (g.nflags <= 0)
			x += gspinside / 4
		if (g.y > next.y + 8)
			x -= 1.5
		x += gspinside
	}

	next = s.next
	if (next
	 && next.type == C.NOTE) {	/* if before a note */
		if (g.y >= 3 * (next.notes[next.nhd].pit - 18))
			gspright -= 1		// above, a bit closer
		else if (g.beam_st
		      && g.y < 3 * (next.notes[next.nhd].pit - 18) - 4)
			gspright += 2		// below with flag, a bit further
	}
	x += gspright;

	/* return the whole width */
	return x
}

// Compute the smallest spacing between symbols according to chord symbols
//	so that they stay at the same offset
// and, also, adjust the spacing due to the lyric words.
// Constraints:
// - assume the chord symbols are only in the first staff
// - treat only the first chord symbol of each symbol
// - the chord symbols under the staff are ignored
function set_w_chs(s) {
    var	i, ch, w0, s0, dw,
	x = 0,
	n = 0

	set_font("vocal")
	for ( ; s; s = s.ts_next) {
		if (s.seqst) {
			x += s.shrink;
			n++
		}
		if (s.a_ly)			// if some lyric
			ly_set(s)

		if (!s.a_gch)
			continue
		for (i = 0; i < s.a_gch.length; i++) {
			ch = s.a_gch[i]
			if (ch.type != 'g' || ch.y < 0) // upper chord symbol only
				continue
			if (w0) {		// width of the previous chord symbol
				if (w0 > x + ch.x) {
					if (s.prev // (if not at start of a secondary voice)
					 && s.prev.seqst
					 && s.prev.type == C.BAR) // don't move away
						n--		// the symbol from a bar
					dw = (w0 - x - ch.x) / n
					while (1) {
						s0 = s0.ts_next
						if (s0.shrink)
							s0.shrink += dw
						if (s0 == s
						 || s0.type == C.BAR)
							break
					}
				}
			}
			s0 = s;
			w0 = ch.text.wh[0];
			n = 0;
//			x = ch.font.box ? -2 : 0
			x = 0
			break
		}
	}
}

// compute the width needed by the left and right annotations
function gchord_width(s, wlnote, wlw) {
    var	gch, w, ix,
	arspc = 0

	for (ix = 0; ix < s.a_gch.length; ix++) {
		gch = s.a_gch[ix]
		switch (gch.type) {
		case '<':		/* left */
			w = gch.text.wh[0] + wlnote
			if (w > wlw)
				wlw = w
			break
		case '>':		/* right */
			w = gch.text.wh[0] + s.wr
			if (w > arspc)
				arspc = w
			break
		}
	}
	if (s.wr < arspc)
		s.wr = arspc

	return wlw
}

/* -- set the width of a symbol -- */
/* This routine sets the minimal left and right widths wl,wr
 * so that successive symbols are still separated when
 * no extra glue is put between them */
// (possible hook)
Abc.prototype.set_width = function(s) {
    var	s2, i, m, xx, w, wlnote, wlw, acc, nt,
	bar_type, meter, last_acc, n1, n2, esp, tmp

	if (s.play) {			// if play symbol
		s.wl = s.wr = 0
		return
	}

	switch (s.type) {
	case C.NOTE:
	case C.REST:

		/* set the note widths */
		s.wr = wlnote = s.invis ? 0 : hw_tb[s.head]

		/* room for shifted heads and accidental signs */
		if (s.xmx > 0)
			s.wr += s.xmx + 4;
		for (s2 = s.prev; s2; s2 = s2.prev) {
			if (w_tb[s2.type])
				break
		}
		if (s2) {
			switch (s2.type) {
			case C.BAR:
			case C.CLEF:
			case C.KEY:
			case C.METER:
				wlnote += 3
				break
			case C.STBRK:
				wlnote += 8
				break
			case C.NOTE:

				// change the spacing when stems in reverse directions
				if (s.stem * s2.stem < 0)
					wlnote += s.stem < 0 ? 3 : -3
				break
			}
		}
		w = 0				// width of the chord decorations
		for (m = 0; m <= s.nhd; m++) {
			nt = s.notes[m]
			xx = nt.shhd
			if (xx < 0) {
				if (wlnote < -xx + 5)
					wlnote = -xx + 5
			}
			acc = nt.acc
			if (acc
			 && (!s2
			  || s2.type != C.NOTE
			  || (s2.stem >= 0 && s2.notes[0].pit < nt.pit + 4)
			  || (s2.stem < 0 && s2.notes[s2.nhd].pit > nt.pit - 4))) {
				tmp = nt.shac +
					(typeof acc == "object" ? 5.5 : 3.5)
				if (s2 && s2.stem < 0
				 && s2.notes[s2.nhd].pit > nt.pit + 4)
					tmp -= 5
				if (wlnote < tmp)
					wlnote = tmp
			}
			if (nt.a_dd) {		// if decoration in chord
				tmp = deco_wch(nt)
				if (w < tmp)
					w = tmp
			}
		}
		wlnote += w
		if (s2) {
			switch (s2.type) {
			case C.BAR:
			case C.CLEF:
			case C.KEY:
			case C.METER:
				wlnote -= 3
				break
			}
		}

		/* room for the decorations */
		if (s.a_dd)
			wlnote = deco_width(s, wlnote)

		/* space for flag if stem goes up on standalone note */
		if (s.beam_st && s.beam_end
		 && s.stem > 0 && s.nflags > 0) {
			if (s.wr < s.xmx + 9)
				s.wr = s.xmx + 9
		}

		/* leave room for dots and set their offset */
		if (s.dots) {
		  if (s.wl == undefined)	// don't recompute if new music line
			switch (s.head) {
			case C.SQUARE:
			case C.OVALBARS:
				s.xmx += 3
				break
			case C.OVAL:
				s.xmx += 1
				break
			}
			if (s.wr < s.xmx + 8)
				s.wr = s.xmx + 8
			if (s.dots >= 2)
				s.wr += 3.5 * (s.dots - 1)
		}

		/* if a tremolo on 2 notes, have space for the small beam(s) */
		if (s.trem2 && s.beam_end
		 && wlnote < 20)
			wlnote = 20

		wlw = wlnote

		if (s2) {
			switch (s2.type) {
			case C.NOTE:

				/* make sure helper lines don't overlap */
				if ((s.y > 27 && s2.y > 27)
				 || (s.y < -3 && s2.y < -3)) {
					if (wlw < 6)
						wlw = 6
				}

				/* have ties wide enough */
				if (s2.tie) {
					if (wlw < 14)
						wlw = 14
				}
				break
			case C.CLEF:		/* extra space at start of line */
				if (s2.second
				 || s2.clef_small)
					break
				// fall thru
			case C.KEY:
				if (s.a_gch)
					wlw += 4 // have some room for the chord symbols
				// fall thru
			case C.METER:
				wlw += 3
				break
			}
		}

		/* leave room for guitar chord */
		if (s.a_gch)
			wlw = gchord_width(s, wlnote, wlw)

		// ignore the lyrics for now

		/* if preceeded by a grace note sequence, adjust */
		if (s.prev && s.prev.type == C.GRACE) {
			s.wl = wlnote - 4.5
		} else {
			s.wl = wlw
		}
		return
	case C.SPACE:
		xx = s.width / 2;
		s.wr = xx
		if (s.a_gch)
			xx = gchord_width(s, xx, xx)
		if (s.a_dd)
			xx = deco_width(s, xx)
		s.wl = xx
		return
	case C.BAR:
		bar_type = s.bar_type
			switch (bar_type) {
			case "|":
				w = 5		// 3 + 2
				break
			case "[":		// repeat number on secondary staff
				w = 0
				break
			default:
				w = 2 + 2.8 * bar_type.length
				for (i = 0; i < bar_type.length; i++) {
					switch (bar_type[i]) {
					case "[":
					case "]":
						w += 1
						// fall thru
					case ":":
						w += 2
						break
					}
				}
				if (bar_type[0] == ":"		// if "c3 :|"
				 && s.prev && s.prev.dots)
					w += 4
				break
			}
			s.wl = w
			if (s.next
			 && s.next.type != C.METER)
				s.wr = 7
			else
				s.wr = 5
//			s.notes[0].shhd = (w - 5) * -.5

		// special case for (mainly) "|| !invisible! |:"
		if (s.invis)
//fixme
//		 && s.prev && s.prev.bar_type)
			s.wl = s.wr = 2

			/* if preceeded by a grace note sequence, adjust */
			s2 = s.prev
			if (s2 && s2.type == C.GRACE)
				s.wl -= 6
			for ( ; s2; s2 = s2.prev) {
				if (w_tb[s2.type]) {
					if (s2.type == C.STBRK)
						s.wl -= 12
					break
				}
			}

		if (s.a_dd)
			s.wl = deco_width(s, s.wl)

		/* have room for the repeat numbers / chord indication */
		if (s.text && s.text.length < 4
		 && s.next && s.next.a_gch) {
			set_font("repeat");
			s.wr += strwh(s.text)[0] + 2
		}
		if (cfmt.measurenb > 0 && s.bar_num
			 && !(s.bar_num % cfmt.measurenb))
				s.wr += 4
		return
	case C.CLEF:
// (there may be invisible clefs in empty staves)
		if (s.invis) {
			s.wl = s.wr = 1		// (!! not 0 !!)
			return
		}
		if (s.prev && s.prev.type == C.STBRK) {
			s.wl = 6
			s.wr = 13
			delete s.clef_small
			return
		}
		s.wl = s.clef_small ? 11 : 12
		s.wr = s.clef_small ? 8 : 13
		return
	case C.KEY:
		if (s.invis)
			break				// no width
		s.wl = 0
		esp = 3
			n1 = s.k_sf			/* new key sig */
			if (s.k_old_sf && (s.fmt.cancelkey || n1 == 0))
				n2 = s.k_old_sf	/* old key */
			else
				n2 = 0
			if (n1 * n2 >= 0) {		/* if no natural */
				if (n1 < 0)
					n1 = -n1
				if (n2 < 0)
					n2 = -n2
				if (n2 > n1)
					n1 = n2
			} else {
				n1 -= n2
				if (n1 < 0)
					n1 = -n1;
				esp += 3	/* see extra space in draw_keysig() */
			}
		if (s.k_bagpipe == 'p')		// K:Hp - add the g natural
			n1++
		if (s.k_a_acc) {
			n2 = s.k_a_acc.length
			if (s.exp)
				n1 = n2			// no key signature
			else
				n1 += n2
			if (n2)
				last_acc = s.k_a_acc[0].acc
			for (i = 1; i < n2; i++) {
				acc = s.k_a_acc[i]
				if (acc.pit > s.k_a_acc[i - 1].pit + 6
				 || acc.pit < s.k_a_acc[i - 1].pit - 6)
					n1--		// no clash
				else if (acc.acc != last_acc)
					esp += 3;
				last_acc = acc.acc
			}
		}
		if (!n1)
			break			// no width
		s.wr = 5.5 * n1 + esp
		if (s.prev && !s.prev.bar_type)
			s.wl += 2
		return
	case C.METER:
		s.x_meter = []
		if (!s.a_meter.length)
			break				// no width
		wlw = 0
		for (i = 0; i < s.a_meter.length; i++) {
			meter = s.a_meter[i]
			switch (meter.top[0]) {
			case 'C':
			case 'c':
			case 'o':
				s.x_meter[i] = wlw
				wlw += 14
				break
			default:
				w = 0
				if (!meter.bot
				 || meter.top.length > meter.bot.length)
					meter = meter.top
				else
					meter = meter.bot;
				for (m = 0; m < meter.length; m++) {
					switch (meter[m]) {
					case '(':
						wlw += 2
						w += 6
						break
					case ')':
						wlw -= 2
						w += 6
						break
					case '1':
						w += 6
						break
					case ' ':
						w += 2
						// fall thru
					case '.':
					case '|':
						break
					default:
						w += 12
						break
					}
				}
				s.x_meter[i] = wlw
				wlw += w
				break
			}
		}
		s.wl = 1
		s.wr = wlw + 4
		return
	case C.MREST:
		s.wl = 6;
		s.wr = 66
		return
	case C.GRACE:
		if (s.invis)
			break
		s.wl = set_graceoffs(s);
		s.wr = 0
		if (s.a_ly)
			ly_set(s)
		return
	case C.STBRK:
		s.wl = s.xmx
		s.wr = 8
		return
	case C.CUSTOS:
		s.wl = s.wr = 4
		return
	case C.TEMPO:		// no width, but build the tempo string
		tempo_build(s)
		break
	case C.BLOCK:				// no width
	case C.REMARK:
	case C.STAVES:
		break
	default:
		error(2, s, "set_width - Cannot set width for symbol $1", s.type)
		break
	}
	s.wl = s.wr = 0

	// move the invisible symbol to the next time sequence
	if (s.seqst && s.ts_next)
		s.ts_next.seqst = 0
}

// convert delta time to natural spacing
function time2space(s, len) {
    var i, l, space

	if (smallest_duration >= C.BLEN / 2) {
		if (smallest_duration >= C.BLEN)
			len /= 4
		else
			len /= 2
	} else if (!s.next && len >= C.BLEN) {
		len /= 2
	}
	if (len >= C.BLEN / 4) {
		if (len < C.BLEN / 2)
			i = 5
		else if (len < C.BLEN)
			i = 6
		else if (len < C.BLEN * 2)
			i = 7
		else if (len < C.BLEN * 4)
			i = 8
		else
			i = 9
	} else {
		if (len >= C.BLEN / 8)
			i = 4
		else if (len >= C.BLEN / 16)
			i = 3
		else if (len >= C.BLEN / 32)
			i = 2
		else if (len >= C.BLEN / 64)
			i = 1
		else
			i = 0
	}
	l = len - ((C.BLEN / 16 / 8) << i)
	space = cfmt.spatab[i]
	if (l) {
		if (l < 0) {
			space = cfmt.spatab[0] * len / (C.BLEN / 16 / 8)
		} else {
			if (i >= 9)
				i = 8
			space += (cfmt.spatab[i + 1] - cfmt.spatab[i]) *
					l / ((C.BLEN / 16 / 8) << i)
		}
	}
	return space
}

// set the natural space
function set_space(s, ptime) {
    var	space, len, s2, stemdir

	len = s.time - ptime		// time skip

	if (!len) {
		switch (s.type) {
		case C.MREST:
			return s.wl
///*fixme:do same thing at start of line*/
//		case C.NOTE:
//		case C.REST:
//			if (s.ts_prev.type == C.BAR) {
//				if (s.nflags < -2)
//					return cfmt.spatab[0]
//				return cfmt.spatab[2]
//			}
//			break
		}
		return 0
	}
	if (s.ts_prev.type == C.MREST)
//		return s.ts_prev.wr + 16
//				+ 3		// (bar wl=5 wr=8)
		return 71	// 66 (mrest.wl) + 5 (bar.wl)

	space = time2space(s, len)

	while (!s.dur) {
		switch (s.type) {
		case C.BAR:
			// (hack to have quite the same note widths between measures)
			if (!s.next)
				space *= .9
			return space * .9 - 3
		case C.CLEF:
			return space - s.wl - s.wr
		case C.BLOCK:			// no space
		case C.REMARK:
		case C.STAVES:
		case C.TEMPO:
			s = s.ts_next
			if (!s)
				return space
			continue
		case C.NOTE:
			break
		default:
			return space
		}
		break
	}

	/* reduce spacing within a beam */
	if (len <= C.BLEN / 4) {
		s2 = s
		while (s2) {
			if (!s2.beam_st) {
				space *= .9		// ex fnnp
				break
			}
			s2 = s2.ts_next
			if (!s2 || s2.seqst)
				break
		}
	}

	/* decrease spacing when stem down followed by stem up */
/*fixme:to be done later, after x computed in sym_glue*/
	if (s.nflags >= -1
	 && s.stem > 0) {
		stemdir = true

		for (s2 = s.ts_prev;
		     s2 && s2.time == ptime;
		     s2 = s2.ts_prev) {
			if (s2.type == C.NOTE
			 && (s2.nflags < -1 || s2.stem > 0)) {
				stemdir = false
				break
			}
		}
		if (stemdir) {
			for (s2 = s.ts_next;
			     s2 && s2.time == s.time;
			     s2 = s2.ts_next) {
				if (s2.type == C.NOTE
				 && (s2.nflags < -1 || s2.stem < 0)) {
					stemdir = false
					break
				}
			}
			if (stemdir)
				space *= .9
		}
	}
	return space
}

// set the spacing inside tuplets or L: factor
function set_sp_tup(s, s_et) {
    var	tim = s.time,
	ttim = s_et.time - tim,
	sp = time2space(s, ttim),	// whole time spacing
	s2 = s,
	wsp = 0

	// compute the whole spacing
	while (1) {
		s2 = s2.ts_next
		if (s2.seqst) {
			wsp += s2.space
			if (s2.bar_type)
				wsp += 10	// (fixme: not exact)
		}
		if (s2 == s_et)
			break
	}
	sp = (sp + wsp) / 2 / ttim	// mean spacing per time unit

	while (1) {
		s = s.ts_next
		if (s.seqst) {
			s.space = sp * (s.time - tim)
			tim = s.time
		}
		if (s == s_et)
			break
	}
}

// return an empty bar
function _bar(s) {
	return {
		type: C.BAR,
		bar_type: "|",
		fname: s.fname,
		istart: s.istart,
		iend: s.iend,
		v: s.v,
		p_v: s.p_v,
		st: s.st,
		dur: 0,
		time: s.time + (s.dur || 0),
		nhd: 0,
		notes: [{
			pit: s.notes ? s.notes[0].pit : 22
		}],
		seqst: true,
		invis: true,
		prev: s,
		fmt: s.fmt
	}
} // _bar()

// create an invisible bar for end of music lines
function add_end_bar(s) {
	if (s.type == C.KEY && !s.k_sf		// if an invisible key
	 && !s.k_old_sf && !s.k_a_acc
	 && s.prev && s.prev.bar_type) {	// before a bar
		unlksym(s)			// remove it
		return
	}

    var b = _bar(s),
	sn = s.ts_next		// start of next line

	b.wl = 0
	b.wr = 0
	b.ts_prev = s
	b.next = s.next
	b.ts_next = s.ts_next

	if (s.next)			// (must not be the end of the voice)
		s.next.prev = b
//	if (s.ts_next)
		s.ts_next.ts_prev = b
	s.next = s.ts_next = b
	b.shrink = sn.shrink
	sn.shrink = sn.wl + 10
	b.space = sn.space * .9 - 3
}

/* -- set the width and space of all symbols -- */
// this function is called once for the whole tune
// and once more for each new music line
function set_allsymwidth(first) {
    var	val, st, s_chs, stup, itup,
	s = tsfirst,
	s2 = s,
	xa = 0,
	xl = [],
	wr = [],
	maxx = xa,
	tim = s.time

	/* loop on all symbols */
	while (1) {
		itup = 0
		do {
			if ((s.a_gch || s.a_ly) && !s_chs)
				s_chs = s;
			self.set_width(s);
			st = s.st
			if (xl[st] == undefined)
				xl[st] = 0
			if (wr[st] == undefined)
				wr[st] = 0;
			if (s.prev && s.prev.st != st) {
				xl[st] = xl[s.prev.st]
				wr[st] = wr[s.prev.st]
			}
			val = xl[st] + wr[st] + s.wl
			if (val > maxx)
				maxx = val
			if (s.dur && s.dur != s.notes[0].dur)	// if in tuplet
				itup = 1
			s = s.ts_next
		} while (s && !s.seqst);

		// set the spaces of the time sequence
		s2.shrink = maxx - xa
		s2.space = s2.ts_prev ? set_space(s2, tim) : 0

		// adjust the spacing when after a spacer (y)
		if (s2.space == 0 && s2.ts_prev
		 && s2.ts_prev.type == C.SPACE && s2.ts_prev.seqst)
			s2.space = s2.ts_prev.space /= 2

		if (itup) {
			if (!first)
				break
			if (!stup)
				stup = s2
		} else if (stup && stup.v == s2.v) {
			set_sp_tup(stup, s2)
			stup = null
		}

		if (!s2.shrink) {
		    if (s2.type == C.CLEF
		     && !s2.ts_prev.bar_type) {
			delete s2.seqst;		/* no space */
			s2.time = tim
		    } else {
			s2.shrink = s2.wl		// cannot be null
			maxx += s2.wl
		    }
		}
		tim = s2.time
		if (!s)
			break

		// update the min left space per staff
		s = s2
		do {
			wr[s.st] = 0
			s = s.ts_next
		} while (!s.seqst)

		xa = maxx
		do {
			st = s2.st;
			xl[st] = xa
			if (s2.wr > wr[st])
				wr[st] = s2.wr
			s2 = s2.ts_next
		} while (!s2.seqst)
	}

	if (stup)
		set_sp_tup(stup, s2)

	// let the chord symbols at the same offset
	// and adjust the spacing due to the lyrics
	if (s_chs)
		set_w_chs(s_chs)
}

// insert a rest, this one replacing a sequence or a measure
function to_rest(so) {
    var	s = clone(so)

	s.prev.next = so.ts_prev = so.prev = s.ts_prev.ts_next = s
	s.next = s.ts_next = so
	so.seqst = false
	so.invis = so.play = true

	s.type = C.REST
// just keep nl and seqst
	delete s.in_tuplet
	delete s.tp
	delete s.a_dd
	delete s.a_gch
	delete s.sls
//fixme: what if chord / slur in notes / ... ?
/*fixme: should set many parameters for set_width*/
//	set_width(s)
	return s
}

/* -- set the repeat sequences / measures -- */
function set_repeat(s) {	// first note
    var	s2, s3, i, j, dur,
	n = s.repeat_n,
	k = s.repeat_k,
	st = s.st,
	v = s.v

	s.repeat_n = 0				// treated

	/* treat the sequence repeat */
	if (n < 0) {				/* number of notes / measures */
		n = -n;
		i = n				/* number of notes to repeat */
		for (s3 = s.prev; s3; s3 = s3.prev) {
			if (!s3.dur) {
				if (s3.type == C.BAR) {
					error(1, s3, "Bar in repeat sequence")
					return
				}
				continue
			}
			if (--i <= 0)
				break
		}
		if (!s3) {
			error(1, s, errs.not_enough_n)
			return
		}
		dur = s.time - s3.time;

		i = k * n		/* whole number of notes/rests to repeat */
		for (s2 = s; s2; s2 = s2.next) {
			if (!s2.dur) {
				if (s2.type == C.BAR) {
					error(1, s2, "Bar in repeat sequence")
					return
				}
				continue
			}
			if (--i <= 0)
				break
		}
		if (!s2
		 || !s2.next) {		/* should have some symbol */
			error(1, s, errs.not_enough_n)
			return
		}
		for (s2 = s.prev; s2 != s3; s2 = s2.prev) {
			if (s2.type == C.NOTE) {
				s2.beam_end = true
				break
			}
		}
		for (j = k; --j >= 0; ) {
			i = n			/* number of notes/rests */
			if (s.dur)
				i--;
			s2 = s.ts_next
			while (i > 0) {
				if (s2.st == st) {
					s2.invis = s2.play = true
					if (s2.seqst && s2.ts_next.seqst)
						s2.seqst = false
					if (s2.v == v
					 && s2.dur)
						i--
				}
				s2 = s2.ts_next
			}
			s = to_rest(s)
			s.dur = s.notes[0].dur = dur;
			s.rep_nb = -1;		// single repeat
			s.beam_st = true;
			self.set_width(s)
			s.head = C.SQUARE;
			for (s = s2; s; s = s.ts_next) {
				if (s.st == st
				 && s.v == v
				 && s.dur)
					break
			}
		}
		return
	}

	/* check the measure repeat */
	i = n				/* number of measures to repeat */
	for (s2 = s.prev.prev ; s2; s2 = s2.prev) {
		if (s2.type == C.BAR
		 || s2.time == tsfirst.time) {
			if (--i <= 0)
				break
		}
	}
	if (!s2) {
		error(1, s, errs.not_enough_m)
		return
	}

	dur = s.time - s2.time		/* repeat duration */

	if (n == 1)
		i = k			/* repeat number */
	else
		i = n			/* check only 2 measures */
	for (s2 = s; s2; s2 = s2.next) {
		if (s2.type == C.BAR) {
			if (--i <= 0)
				break
		}
	}
	if (!s2) {
		error(1, s, errs.not_enough_m)
		return
	}

	/* if many 'repeat 2 measures'
	 * insert a new %%repeat after the next bar */
	i = k				/* repeat number */
	if (n == 2 && i > 1) {
		s2 = s2.next
		if (!s2) {
			error(1, s, errs.not_enough_m)
			return
		}
		s2.repeat_n = n;
		s2.repeat_k = --i
	}

	/* replace */
	dur /= n
	if (n == 2) {			/* repeat 2 measures (once) */
		s3 = s
		for (s2 = s.ts_next; ; s2 = s2.ts_next) {
			if (s2.st != st)
				continue
			if (s2.type == C.BAR) {
				if (s2.v == v)
					break
				continue
			}
			s2.invis = s2.play = true
			if (s2.seqst && s2.ts_next.seqst)
				s2.seqst = false
		}
		s3 = to_rest(s3)
		s3.dur = s3.notes[0].dur = dur;
		s3.invis = true
		s2.bar_mrep = 2
		s3 = s2.next;
		for (s2 = s3.ts_next; ; s2 = s2.ts_next) {
			if (s2.st != st)
				continue
			if (s2.type == C.BAR) {
				if (s2.v == v)
					break
				continue
			}
			if (!s2.dur)
				continue
			s2.invis = s2.play = true
			if (s2.seqst && s2.ts_next.seqst)
				s2.seqst = false
		}
		s3 = to_rest(s3)
		s3.dur = s3.notes[0].dur = dur;
		s3.invis = true;
		self.set_width(s3)
		return
	}

	/* repeat 1 measure */
	s3 = s
	for (j = k; --j >= 0; ) {
		for (s2 = s3.ts_next; ; s2 = s2.ts_next) {
			if (s2.st != st)
				continue
			if (s2.type == C.BAR) {
				if (s2.v == v)
					break
				continue
			}
			if (!s2.dur)
				continue
			s2.invis = s2.play = true
			if (s2.seqst && s2.ts_next.seqst)
				s2.seqst = false
		}
		s3 = to_rest(s3)

		s3.dur = s3.notes[0].dur = dur;
		s3.beam_st = true
		if (k == 1) {
			s3.rep_nb = 1
			break
		}
		s3.rep_nb = k - j + 1;	// number to print above the repeat rest
		s3 = s2.next
	}
}

/* add a custos before the symbol of the next line */
function custos_add(s) {
	var	p_voice, new_s, i,
		s2 = s

	while (1) {
		if (s2.type == C.NOTE)
			break
		s2 = s2.next
		if (!s2)
			return
	}

	p_voice = s.p_v;
	p_voice.last_sym = s.prev;
//	if (!p_voice.last_sym)
//		p_voice.sym = null;
	p_voice.time = s.time;
	new_s = sym_add(p_voice, C.CUSTOS);
	new_s.next = s;
	s.prev = new_s;
	new_s.wl = 0			// (needed here for lktsym)
	new_s.wr = 4
	lktsym(new_s, s);

	new_s.shrink = s.shrink
	if (new_s.shrink < 8 + 4)
		new_s.shrink = 8 + 4;
	new_s.space = s2.space;

	new_s.head = C.FULL
	new_s.stem = s2.stem
	new_s.nhd = s2.nhd;
	new_s.notes = []
	for (i = 0; i < s2.notes.length; i++) {
		new_s.notes[i] = {
			pit: s2.notes[i].pit,
			shhd: 0,
			dur: C.BLEN / 4
		}
	}
	new_s.stemless = true
}

/* -- define the beginning of a new music line -- */
function set_nl(s) {			// s = start of line
    var	p_voice, done, tim, ptyp

	// divide the left repeat (|:) or variant bars (|1)
	// the new bars go in the next line
	function bardiv(so) {		// start of next line
	    var s, s1, s2, t1, t2, i

	    function new_type(s) {
	    var	t = s.bar_type.match(/(:*)([^:]*)(:*)/)
			// [1] = starting ':'s, [2] = middle, [3] = ending ':'s

		if (!t[3]) {		// if start of variant
			// |1 -> | [1
			// :|]1 -> :|] [1
			t1 = t[1] + t[2]
			t2 = '['
		} else if (!t[1]) {	// if left repeat only
			// x|: -> || [|:
			t1 = '||'
			t2 = '[|' + t[3]
		} else {
			// :][: -> :|] [|:
			i = (t[2].length / 2) | 0
			t1 = t[1] + '|' + t[2].slice(0, i)
			t2 = t[2].slice(i) +'|' + t[3]
		}
	    } // new_typ()

		// change or add a bar for the voice in the previous line
		function eol_bar(s,		// bar |:
				 so,		// start of new line
				 sst) {		// first bar (for seqst)
		    var	s1, s2, s3

			// check if a bar in the previous line
			for (s1 = so.ts_prev ; s1.time == s.time; s1 = s1.ts_prev) {
				if (s1.v != s.v)
					continue
				if (s1.bar_type) {
					if (s1.bar_type != '|')
						return	// don't change
					s2 = s1		// last symbol in previous line
					break
				}
				if (!s3)
					s3 = s1.next	// possible anchor for the new bar
			}
			if (!s2) {			// if no symbol in previous line
				s2 = clone(s)
				if (!s3)
					s3 = s
				s2.next = s3
				s2.prev = s3.prev
				if (s2.prev)
					s2.prev.next = s2
				s3.prev = s2
				s2.ts_prev = so.ts_prev	// time linkage
				s2.ts_prev.ts_next = s2
				s2.ts_next = so
				so.ts_prev = s2
				if (s == sst)		// if first inserted bar
					s2.seqst = 1 //true
				if (s2.seqst) {
					for (s = s2.ts_next; !s.seqst; s = s.ts_next)
						;
					s2.shrink = s.shrink
					s.shrink = s2.wr + s.wl
					s2.space = s.space
					s.space = 0
				}
				delete s2.part
			}
			s2.bar_type = "||"
		} // eol_bar()

		// check if there is a left repeat bar at start of the new line
		s = so				// start of new music line
		while (s && s.time == so.time) {
			if (s.bar_type && s.bar_type.slice(-1) == ':') {
				s2 = s
				break
			}
			s = s.ts_next
		}
		if (s2) {
			s = s2
			while (1) {		// loop on all voices
				eol_bar(s2, so, s)
				s2 = s2.ts_next
				if (!s2 || s2.seqst)
					break
			}
			return so
		}

		s = so
		while (s.ts_prev
		 && s.ts_prev.time == so.time) {
			s = s.ts_prev
			if (s.bar_type)
				s1 = s		// first previous bar
			else if (!s1 && s.type == C.GRACE && s.seqst)
				so = s		// if grace note after a bar
						// move the start of line
		}
		if (!s1
		 || !s1.bar_type
		 || (s1.bar_type.slice(-1) != ':'
		  && !s1.text))
			return so

		// search the new start of the next line
		for (so = s1; so.time == s1.time; so = so.ts_prev) {
			switch (so.ts_prev.type) {
			case C.KEY:
			case C.METER:
//			case C.PART:
			case C.TEMPO:
			case C.STAVES:
			case C.STBRK:
				continue
			}
			break
		}

		// put the new bar before the end of music line
		s = s1				// keep first bar
		while (1) {
			new_type(s1)
			s2 = clone(s1)
			s2.bar_type = t1
			s1.bar_type = t2
			s2.ts_prev = so.ts_prev
			s2.ts_prev.ts_next = s2
			s2.ts_next = so
			so.ts_prev = s2
			if (s1 == s)
				s2.seqst = 1 //true
			s2.next = s1
			if (s2.prev)
				s2.prev.next = s2
			s1.prev = s2
			if (s1.rbstop)
				s2.rbstop = s1.rbstop
			if (s1.text) {
				s1.invis = 1 //true
				delete s1.xsh
				delete s2.text
				delete s2.rbstart
			}
			delete s2.part
			delete s1.a_dd
			delete s1.a_gch
			do {
				s1 = s1.ts_next
			} while (!s1.seqst && !s1.bar_type)
			if (s1.seqst)
				break
		}
		return so
	} // bardiv()

	// set the start of line marker
	function set_eol(s) {
		if (cfmt.custos && voice_tb.length == 1)
			custos_add(s)
		s.nl = true
		s = s.ts_prev
		if (s.type != C.BAR)
			add_end_bar(s)
	} // set_eol()

	// put the warning symbols
	// the new symbols go in the previous line
	function do_warn(s) {		// start of next line
	    var s1, s2, s3, s4, w

		// advance in the next line
		for (s2 = s; s2 && s2.time == s.time; s2 = s2.ts_next) {
			switch (s2.type) {
			case C.KEY:
				if (!s2.fmt.keywarn
				 || s2.invis)
					continue
				for (s1 = s.ts_prev; s1 ;s1 = s1.ts_prev) {
					if (s1.type != C.METER)
						break
				}
				// fall thru
			case C.METER:
				if (s2.type == C.METER) {
					if (!s.fmt.timewarn)
						continue
					s1 = s.ts_prev
				}
				// fall thru
			case C.CLEF:
				if (!s2.prev)		// start of voice
					continue
				if (s2.type == C.CLEF) {
					if (s2.clef_none) // if 'K: clef=none' after bar
						break
					for (s1 = s.ts_prev; s1; s1 = s1.ts_prev) {
						switch (s1.type) {
						case C.BAR:
							if (s1.bar_type[0] == ':')
								break
							// fall thru
						case C.KEY:
						case C.METER:
							continue
						}
						break
					}
				}

				// put the warning symbol at end of line
				s3 = clone(s2)		// duplicate the K:/M:/clef

				lktsym(s3, s1.ts_next)	// time link

				s1 = s3
				while (1) {
					s1 = s1.ts_next
					if (s1.v == s2.v)
						break
				}
				lkvsym(s3, s1)		// voice link

				// care with spacing
				if (s3.seqst) {
					self.set_width(s3)
					s3.shrink = s3.wl
					s4 = s3.ts_prev
					w = 0
					while (1) {
						if (s4.wr > w)
							w = s4.wr
						if (s4.seqst)
							break
						s4 = s4.ts_prev
					}
					s3.shrink += w
					s3.space = 0
					s4 = s3
					while (1) {
						if (s4.ts_next.seqst)
							break
						s4 = s4.ts_next
					}
					w = 0
					while (1) {
						if (s4.wl > w)
							w = s4.wl
						s4 = s4.ts_next
						if (s4.seqst)
							break
					}
					s4.shrink = s3.wr + w
				}
				delete s3.part
				continue
			}
			if (w_tb[s2.type])
				break		// symbol with a width
		}
	} // do_warn()

	// divide the left repeat and variant bars
	s = bardiv(s)

	// add the warning symbols at the end of the previous line
	do_warn(s)

	/* if normal symbol, cut here */
	if (s.ts_prev.type != C.STAVES) {
		set_eol(s)
		return s
	}

	/* go back to handle the staff breaks at end of line */
	for (s = s.ts_prev; s; s = s.ts_prev) {
		if (s.seqst && s.type != C.CLEF)
			break
	}
	done = 0
	ptyp = s.type
	for ( ; ; s = s.ts_next) {
		if (!s)
			return s
		if (s.type == ptyp)
			continue
		ptyp = s.type
		if (done < 0)
			break
		switch (s.type) {
		case C.STAVES:
			if (!s.ts_prev)
				return // null		// no music yet
			if (s.ts_prev.type == C.BAR)
				break
			while (s.ts_next) {
				if (w_tb[s.ts_next.type]
				 && s.ts_next.type != C.CLEF)
					break
				s = s.ts_next
			}
			if (!s.ts_next || s.ts_next.type != C.BAR)
				continue
			s = s.ts_next
			// fall thru
		case C.BAR:
			if (done)
				break
			done = 1;
			continue
		case C.STBRK:
			if (!s.stbrk_forced)
				unlksym(s)	/* remove */
			else
				done = -1	// keep the next symbols on the next line
			continue
		case C.CLEF:
			if (done)
				break
			continue
		default:
			if (!done || (s.prev && s.prev.type == C.GRACE))
				continue
			break
		}
		break
	}
	set_eol(s)
	return s
}

/* get the width of the starting clef and key signature */
// return
//	r[0] = width of clef and key signature
//	r[1] = width of the meter
function get_ck_width() {
    var	r0, r1,
	p_voice = voice_tb[0]

	self.set_width(p_voice.clef);
	self.set_width(p_voice.ckey);
	self.set_width(p_voice.meter)
	return [p_voice.clef.wl + p_voice.clef.wr +
			p_voice.ckey.wl + p_voice.ckey.wr,
		p_voice.meter.wl + p_voice.meter.wr]
}

// get the width of the symbols up to the next soln or eof
// also, set a x (nice spacing) to all symbols
// two returned values: width of nice spacing, width with max shrinking
function get_width(s, next) {
    var	shrink, space,
	w = 0,
	wmx = 0,
	sp_fac = (1 - s.fmt.maxshrink)

	while (s != next) {
		if (s.seqst) {
			shrink = s.shrink
			wmx += shrink
			if ((space = s.space) < shrink)
				w += shrink
			else
				w += shrink * s.fmt.maxshrink
					+ space * sp_fac
			s.x = w
		}
		s = s.ts_next
	}
	if (next)
		wmx += next.wr		// big key signatures may be wide enough
	return [w, wmx]
}

/* -- search where to cut the lines according to the staff width -- */
function set_lines(	s,		/* first symbol */
			next,		/* symbol of the next line / null */
			lwidth,		/* w - (clef & key sig) */
			indent) {	/* for start of tune */
    var	first, s2, s3, s4, s5, x, xmin, xmid, xmax, wwidth, shrink, space,
	nlines,
	last = next ? next.ts_prev : null,
	ws = get_width(s, next)		// 2 widths: nice and shrunk

	// split a big lyric word on two music lines
	function ly_split(s, wmax) {
	    var	i, wh,
		s2 = clone(s),
		p = s.a_ly[0].t,		// lyric word
		w = 0,
		j = 0

		gene.deffont = s.a_ly[0].font
		while (1) {
			i = p.indexOf(' ', j) + 1
			if (i <= 0)
				break
			wh = strwh(p.slice(j, i))
			w += wh[0]
			if (w > wmax)
				break
			j = i
		}
		s.a_ly[0].t = new String(p.slice(0, j - 1))
		s2.a_ly = clone(s.a_ly)
		s2.a_ly[0] = clone(s.a_ly[0])
		s2.a_ly[0].t = new String(p.slice(j))
		if (abc2svg.el) {
			strwh(s.a_ly[0].t)
			strwh(s2.a_ly[0].t)
		} else {
			s.a_ly[0].t.wh = strwh(s.a_ly[0].t)
			s2.a_ly[0].t.wh = strwh(s2.a_ly[0].t)
		}
		w = s.a_ly[0].t.wh[0]		// new length of the words
		s.wr = wmax
		s2.wr -= w

		lkvsym(s2, s2.next)		// voice linkage

		s2.time += .1
//		s2.dur -= .1
		s2.nl = 0 //false
		while (!s.seqst)
			s = s.ts_prev
		s2.x = s.x + w
		s2.shrink = w - s2.wl
		s = s2.ts_next
		while (s) {
			if (s.seqst) {
				s.wl -= w
				s.shrink -= w
				break
			}
			s = s.ts_next
		}
		lktsym(s2, s2.ts_next)		// time linkage
	} // ly_split()

	// -- set_lines --

	// take care of big key signatures at end of line
	if (s.fmt.keywarn && next
	 && next.type == C.KEY && !last.dur) {
		ws[0] += next.wr
		ws[1] += next.wr
	}

	// check if the symbols can enter in one line (with max shrink)
	if (ws[1] + indent < lwidth) {
		if (next)
			next = set_nl(next)
		return next || last
	}

	/* loop on cutting the tune into music lines */
	wwidth = ws[0] + indent
	while (1) {
		nlines = Math.ceil(wwidth / lwidth)
		if (nlines <= 1) {
			if (next)
				next = set_nl(next)
			return next || last
		}

		s2 = first = s;
		xmin = s.x
		xmax = xmin + lwidth;
		xmid = xmin + wwidth / nlines;
		xmin += wwidth / nlines * s.fmt.breaklimit;
		for (s = s.ts_next; s != next ; s = s.ts_next) {
			if (!s.x)
				continue
			if (s.type == C.BAR)
				s2 = s
			if (s.x >= xmin)
				break
		}
		s4 = s			// keep first symbol with x greater than xmin
//fixme: can this occur?
		if (s == next) {
			if (s)
				s = set_nl(s)
			return s
		}

		// if the width of the symbol is greater than
		//			 the remaining width in the staff
		// and if there are lyrics, split these lyrics on 2 staves
	    if (s.x > xmax
	     && s.prev.a_ly) {
		s3 = s = s.prev
		while (!s3.seqst)
			s3 = s3.ts_prev
		ly_split(s, xmax - s3.x)
	    } else {

		/* try to cut on a measure bar */
		s3 = null
		for ( ; s != next; s = s.ts_next) {
			x = s.x
			if (!x)
				continue
			if (x > xmax)
				break
			if (s.type != C.BAR)
				continue

			// cut on the bar closest to the middle
			if (x < xmid) {
				s3 = s		// closest bar before middle
				continue
			}
			if (!s3 || x - xmid < xmid - s3.x)
				s3 = s		// closest bar after middle
			break
		}

		// no bar, try to avoid to cut a beam or a tuplet */
		if (!s3) {
			s = s4			// restart after xmin

		    var	beam = 0,
			bar_time = s2.time

			xmax -= 8; // (left width of the inserted bar in set_allsymwidth)
			s5 = s
			for ( ; s != next; s = s.ts_next) {
				if (s.seqst) {
					x = s.x
					if (x + s.wr >= xmax)
						break
					if (!beam && !s.in_tuplet
					 && (xmid - s5.x > x - xmid
					  || (s.time - bar_time)
							% (C.BLEN / 4) == 0))
						s3 = s
				}
				if (s.beam_st)
					beam |= 1 << s.v
				if (s.beam_end)
					beam &= ~(1 << s.v)
				s5 = s		// start of new time sequence
			}
			if (s3) {
				do {		// cut on the previous sequence
					s3 = s3.ts_prev
				} while (!s3.seqst)
			}
		}

		// cut anyhere
		if (!s3) {
			s3 = s = s4
			for ( ; s != next; s = s.ts_next) {
				x = s.x
				if (!x)
					continue
				if (x + s.wr >= xmax)
					break
				if (s3 && x >= xmid) {
					if (xmid - s3.x > x - xmid)
						s3 = s
					break
				}
				s3 = s
			}
		}
		s = s3
	    } // ly_split call
		while (s.ts_next) {
			s = s.ts_next
			if (s.seqst)
				break
		}

		if (s.nl) {		/* already set here - advance */
			error(0, s,
			    "Line split problem - adjust maxshrink and/or breaklimit");
			nlines = 2
			for (s = s.ts_next; s != next; s = s.ts_next) {
				if (!s.x)
					continue
				if (--nlines <= 0)
					break
			}
		}
		s = set_nl(s)
		if (!s
		 || (next && s.time >= next.time))
			break
		wwidth -= s.x - first.x;
		indent = 0
	}
	return s
}

/* -- cut the tune into music lines -- */
function cut_tune(lwidth, lsh) {
    var	s2, i, mc,
	pg_sav = {			// save the page parameters
		leftmargin: cfmt.leftmargin,
		rightmargin: cfmt.rightmargin,
		pagewidth: cfmt.pagewidth,
		scale: cfmt.scale
	},
	indent = lsh[1] - lsh[2],	// extra width of the first line
	ckw = get_ck_width(),		// width of the starting symbols
	s = tsfirst

	lwidth -= lsh[2]		// width of the lines
	if (cfmt.indent && cfmt.indent > lsh[1])
		indent += cfmt.indent

	// adjust the line width according to the starting symbols
	lwidth -= ckw[0]
	indent += ckw[1]

	if (cfmt.custos && voice_tb.length == 1)
		lwidth -= 12

	/* if asked, count the measures and set the EOLNs */
	i = s.fmt.barsperstaff
	if (i) {
		for (s2 = s; s2; s2 = s2.ts_next) {
			if (s2.type != C.BAR
			 || !s2.bar_num
			 || --i > 0)
				continue
			while (s2.ts_next && s2.ts_next.type == C.BAR)
				s2 = s2.ts_next
			if (s2.ts_next)
				s2.ts_next.soln = true
			i = s.fmt.barsperstaff
		}
	}

	/* cut at explicit end of line, checking the line width */
	s2 = s
	for ( ; s; s = s.ts_next) {
		if (s.type == C.BLOCK) {
			switch (s.subtype) {
			case "leftmargin":
			case "rightmargin":
			case "pagescale":
			case "pagewidth":
			case "scale":
			case "staffwidth":
				if (!s.soln)
					self.set_format(s.subtype, s.param)
				break
			case "mc_start":
				mc = {
					lm: cfmt.leftmargin,
					rm: cfmt.rightmargin
				}
				break
			case "mc_new":
			case "mc_end":
				if (!mc)
					break
				cfmt.leftmargin = mc.lm
				cfmt.rightmargin = mc.rm
				img.chg = 1 //true
				break
			}
		}
		if (!s.ts_next) {
			s = null
		} else if (!s.soln) {
			continue
		} else {
			s.soln = false
//fixme what if new line wanted?
			if (s.time == s2.time)
				continue	// empty music line!
			while (!s.seqst)
				s = s.ts_prev
		}
		set_page()
		lwidth = get_lwidth() - lsh[1] - ckw[0]
		s2 = set_lines(s2, s, lwidth, indent)
		if (!s2)
			break

		s = s2.type == C.BLOCK
			? s2.ts_prev		// don't miss a parameter
			: s
		indent = 0
	}

	// restore the page parameters at start of line
	cfmt.leftmargin = pg_sav.leftmargin
	cfmt.rightmargin = pg_sav.rightmargin
	cfmt.pagewidth = pg_sav.pagewidth
	cfmt.scale = pg_sav.scale
	img.chg = 1
	set_page()
}

/* -- set the y values of some symbols -- */
function set_yval(s) {
//fixme: staff_tb is not yet defined
//	var top = staff_tb[s.st].topbar
//	var bot = staff_tb[s.st].botbar
	switch (s.type) {
	case C.CLEF:
		s.y = (s.clef_line - 1) * 6
		if (s.second
		 || s.invis) {
//			s.ymx = s.ymn = (top + bot) / 2
			s.ymx = s.ymn = 12
			break
		}
		switch (s.clef_type) {
		default:			/* treble / perc */
			s.ymx = s.y + 25
			s.ymn = s.y - 14
			break
		case "c":
			s.ymx = s.y + 12
			s.ymn = s.y - 11
			break
		case "b":
			s.ymx = s.y + 4
			s.ymn = s.y - 11//12
			break
		}
		if (s.clef_small) {
			s.ymx -= 3
			s.ymn += 2
		}
		if (s.ymx < 24)
			s.ymx = 24
//		if (s.ymn > -1)
//			s.ymn = -1
		if (s.ymn > 0)
			s.ymn = 0
//		s.y += s.clef_line * 6
//		if (s.y > 0)
//			s.ymx += s.y
//		else if (s.y < 0)
//			s.ymn += s.y
		if (s.clef_octave) {
			if (s.clef_octave > 0)
				s.ymx += 4
			else
				s.ymn -= 4
		}
		break
	case C.KEY:
		if (s.k_sf > 2)
			s.ymx = 24 + 10
		else if (s.k_sf > 0)
			s.ymx = 24 + 6
		else
			s.ymx = 24 + 2;
		s.ymn = -2
		break
	default:
//		s.ymx = top;
		s.ymx = 24;
		s.ymn = 0
		break
	}
}

// set the pitch of the notes under an ottava sequence
function set_ottava() {
    var	s, s1, st, o, d,
	m = nstaff + 1,
	staff_d = new Int8Array(m)

	// update the pitches of a symbol
	function sym_ott(s, d) {
	    var	g, m, note

		switch (s.type) {
		case C.REST:
			if (voice_tb.length == 1)
				break
		case C.NOTE:
			if (!s.p_v.ckey.k_drum) {
				for (m = s.nhd; m >= 0; m--) {
					note = s.notes[m];
					if (!note.opit)
						note.opit = note.pit;
					note.pit += d
				}
			}
			break
		case C.GRACE:
			for (g = s.extra; g; g = g.next) {
				if (!s.p_v.ckey.k_drum) {
					for (m = 0; m <= g.nhd; m++) {
						note = g.notes[m]
						if (!note.opit)
							note.opit = note.pit
						note.pit += d
					}
				}
			}
			break
		}
	} // sym_ott()

	// remove the ottava decorations of a symbol
	function deco_rm(s) {
		for (var i = s.a_dd.length; --i >= 0;) {
			if (s.a_dd[i].name.match(/1?[85][vm][ab]/))
				s.a_dd.splice(i, 1)
		}
	} // deco_rm()

	for (s = tsfirst; s; s = s.ts_next) {
		st = s.st
		o = s.ottava
		if (o) {				// some ottava start or stop
			if (o[0]) {
				if (staff_d[st] && !o[1]) {
					sym_ott(s, staff_d[st])
					deco_rm(s)
					continue	// same ottava
				}
			} else if (!staff_d[st]) {
				deco_rm(s)
				continue		// already no ottava
			}
			s1 = s
			while (s1 && !s1.seqst)
				s1 = s1.ts_prev
			if (s1) {			// update the previous symbols
				while (s1 != s) {
					if (s1.st == st) {
						if (o[1])
							sym_ott(s1, -staff_d[st])
						if (o[0])
							sym_ott(s1, -o[0] * 7)
					}
					s1 = s1.ts_next
				}
			}
			if (o[0]) {			// ottava start
				staff_d[st] = -o[0] * 7
			} else {
				staff_d[st] = 0
			}
		}
		if (staff_d[st])
			sym_ott(s, staff_d[st])
	}
}

// expand the multi-rests as needed
function mrest_expand() {
    var	s, s2

	// expand a multi-rest into a set of rest + bar
	function mexp(s) {
	    var	bar, s3, s4, tim, nbar,
		nb = s.nmes,
		dur = s.dur / nb,
		s2 = s.next

		// get the bar (there may be some other symbols before the bar)
		while (s2 && !s2.bar_type)
			s2 = s2.next
		if (!s2)
			return error(1, s, "Lack of bar after multi-measure rest")
		bar = s2
		while (!s2.bar_num)		// get the bar number
			s2 = s2.ts_prev
		nbar = s2.bar_num - s.nmes

		// change the multi-rest into a single rest
		s.type = C.REST
		s.notes[0].dur = s.dur = s.dur_orig = dur
		s.nflags = -2
		s.head = C.FULL
		s.fmr = 1			// full measure rest

		/* add the bar(s) and rest(s) */
		tim = s.time + dur
		s3 = s
		while (--nb > 0) {

			// add the bar
			s2 = clone(bar)
			delete s2.soln
			delete s2.a_gch
			delete s2.a_dd
			delete s2.text
			delete s2.rbstart
			delete s2.rbstop
			lkvsym(s2, s.next)	// before symbol at end of rests

			s2.time = tim
			while (s3.time < tim)
				s3 = s3.ts_next	// bar at end of measure
			if (s3.time == tim)
				while (!s3.bar_type
				    && s3.ts_next && s3.ts_next.time == tim)
					s3 = s3.ts_next
			while (s3 && s3.v < s.v && s3.type == C.BAR)
				s3 = s3.ts_next	// keep in order
			if (s3) {
				if (s3.bar_type)
					s3.seqst = 0 //false
				lktsym(s2, s3)
				if (s3.type == C.BAR)
					delete s3.bar_num
			} else {
				s3 = s
				while (s3.ts_next)
					s3 = s3.ts_next
				s3.ts_next = s2
				s2.ts_prev = s3
				s2.ts_next = null
			}
			nbar++
			if (s2.seqst) {
				s2.bar_num = nbar
				s4 = s2.ts_next
			} else {
				delete s2.bar_num
				s4 = s2.ts_prev
			}
			s2.bar_type = s4.bar_type || "|"
			if (s4.bar_num && !s4.seqst)
				delete s4.bar_num

			// add the rest
			s4 = clone(s)
			delete s4.a_dd
			delete s4.soln
			delete s4.a_gch
			delete s4.part
			if (s2.next) {
				s4.next = s2.next
				s4.next.prev = s4
			} else {
				s4.next = null
			}
			s2.next = s4
			s4.prev = s2
			s4.time = tim

			while (s3 && !s3.dur && s3.time == tim)
				s3 = s3.ts_next
			while (s3 && s3.v < s.v) {
				s3 = s3.ts_next	// keep in order
				if (s3 && s3.seqst)
					break
			}
			if (s3) {
				if (s3.dur)
					s3.seqst = 0 //false
				lktsym(s4, s3)
			} else {
				s3 = s
				while (s3.ts_next)
					s3 = s3.ts_next
				s3.ts_next = s4
				s4.ts_prev = s3
				s4.ts_next = null
			}

			tim += dur
			s = s3 = s4
		}
	} // mexp()

	for (s = tsfirst; s; s = s.ts_next) {
		if (s.type != C.MREST)
			continue
		if (!s.seqst && w_tb[s.ts_prev.type]) {
			s2 = s
		} else {
			s2 = s.ts_next
			while (!s2.seqst) {
				if (s2.type != C.MREST
				 || s2.nmes != s.nmes)
					break
				s2 = s2.ts_next
			}
		}
		if (!s2.seqst) {
			while (s.type == C.MREST) {
				mexp(s)
				s = s.ts_next
			}
		} else {
			s = s2.ts_prev
		}
	}
} // mrest_expand()

// set the clefs (treble or bass) in a 'auto clef' sequence
// return the starting clef type
function set_auto_clef(st, s_start, clef_type_start) {
    var	s, time, s2, s3,
	max = 14,				// "A,"
	min = 18				// "E"

	/* get the max and min pitches in the sequence */
	for (s = s_start; s; s = s.ts_next) {
		if (s.type == C.STAVES && s != s_start)
			break
		if (s.st != st)
			continue
		if (s.type != C.NOTE) {
			if (s.type == C.CLEF) {
				if (s.clef_type != 'a')
					break
				unlksym(s)
			}
			continue
		}
		if (s.notes[0].pit < min)
			min = s.notes[0].pit
		if (s.notes[s.nhd].pit > max)
			max = s.notes[s.nhd].pit
	}

	if (min >= 19					/* upper than 'F' */
	 || (min >= 13 && clef_type_start != 'b'))	/* or 'G,' */
		return 't'
	if (max <= 13					/* lower than 'G,' */
	 || (max <= 19 && clef_type_start != 't'))	/* or 'F' */
		return 'b'

	/* set clef changes */
	if (clef_type_start == 'a') {
		if ((max + min) / 2 >= 16)
			clef_type_start = 't'
		else
			clef_type_start = 'b'
	}
	var	clef_type = clef_type_start,
		s_last = s,
		s_last_chg = null
	for (s = s_start; s != s_last; s = s.ts_next) {
		if (s.type == C.STAVES && s != s_start)
			break
		if (s.st != st || s.type != C.NOTE)
			continue

		/* check if a clef change may occur */
		time = s.time
		if (clef_type == 't') {
			if (s.notes[0].pit > 12		/* F, */
			 || s.notes[s.nhd].pit > 20) {	/* G */
				if (s.notes[0].pit > 20
				 || s.notes[s.nhd].pit > 20)
					s_last_chg = s
				continue
			}
			s2 = s.ts_prev
			if (s2
			 && s2.time == time
			 && s2.st == st
			 && s2.type == C.NOTE
			 && s2.notes[0].pit >= 19)	/* F */
				continue
			s2 = s.ts_next
			if (s2
			 && s2.st == st
			 && s2.time == time
			 && s2.type == C.NOTE
			 && s2.notes[0].pit >= 19)	/* F */
				continue
		} else {
			if (s.notes[0].pit <= 12	/* F, */
			 || s.notes[s.nhd].pit < 20) {	/* G */
				if (s.notes[s.nhd].pit <= 12
				 || s.notes[0].pit <= 12)
					s_last_chg = s
				continue
			}
			s2 = s.ts_prev
			if (s2
			 && s2.time == time
			 && s2.st == st
			 && s2.type == C.NOTE
			 && s2.notes[0].pit <= 13)	/* G, */
				continue
			s2 = s.ts_next
			if (s2
			 && s2.st == st
			 && s2.time == time
			 && s2.type == C.NOTE
			 && s2.notes[0].pit <= 13)	/* G, */
				continue
		}

		/* if first change, change the starting clef */
		if (!s_last_chg) {
			clef_type = clef_type_start =
					clef_type == 't' ? 'b' : 't';
			s_last_chg = s
			continue
		}

		/* go backwards and search where to insert a clef change */
		s3 = s
		for (s2 = s.ts_prev; s2 != s_last_chg; s2 = s2.ts_prev) {
			if (s2.st != st)
				continue
			if (s2.type == C.BAR) {
				s3 = s2.bar_type[0] != ':' ? s2 : s2.next
				break
			}
			if (s2.type != C.NOTE)
				continue

			/* have a 2nd choice on beam start */
			if (s2.beam_st
			 && !s2.p_v.second)
				s3 = s2
		}

		/* no change possible if no insert point */
		if (s3.time == s_last_chg.time) {
			s_last_chg = s
			continue
		}
		s_last_chg = s;

		/* insert a clef change */
		clef_type = clef_type == 't' ? 'b' : 't';
		s2 = insert_clef(s3, clef_type, clef_type == "t" ? 2 : 4);
		s2.clef_auto = true
//		s3.prev.st = st
	}
	return clef_type_start
}

/* set the clefs */
/* this function is called once at start of tune generation */
/*
 * global variables:
 *	- staff_tb[st].clef = clefs at start of line (here, start of tune)
 *				(created here, updated on clef draw)
 *	- voice_tb[v].clef = clefs at end of generation
 *				(created on voice creation, updated here)
 */
function set_clefs() {
    var	s, s2, st, v, p_voice, g, new_type, new_line, p_staff, pit,
	staff_clef = new Array(nstaff + 1),	// st -> { clef, autoclef }
	sy = cur_sy,
	mid = []

	// create the staff table
	staff_tb = new Array(nstaff + 1)
	for (st = 0; st <= nstaff; st++) {
		staff_clef[st] = {
			autoclef: true
		}
		staff_tb[st] = {
			output: "",
			sc_out: ""
		}
	}

	for (st = 0; st <= sy.nstaff; st++)
		mid[st] = (sy.staves[st].stafflines.length - 1) * 3

	for (s = tsfirst; s; s = s.ts_next) {
		if (s.repeat_n)
			set_repeat(s)

		switch (s.type) {
		case C.STAVES:
			sy = s.sy			// new system
			for (st = 0; st <= nstaff; st++)
				staff_clef[st].autoclef = true
			for (v = 0; v < voice_tb.length; v++) {
				if (!sy.voices[v])
					continue
				p_voice = voice_tb[v];
				st = sy.voices[v].st
				if (!sy.voices[v].second) {
					sy.staves[st].staffnonote = p_voice.staffnonote
					if (p_voice.staffscale)
						sy.staves[st].staffscale = p_voice.staffscale
					if (sy.voices[v].sep)
						sy.staves[st].sep = sy.voices[v].sep
					if (sy.voices[v].maxsep)
						sy.staves[st].maxsep = sy.voices[v].maxsep
				}
				s2 = p_voice.clef
				if (!s2.clef_auto)
					staff_clef[st].autoclef = false
			}
			for (st = 0; st <= sy.nstaff; st++)
				mid[st] = (sy.staves[st].stafflines.length - 1) * 3
			for (v = 0; v < voice_tb.length; v++) {
				if (!sy.voices[v]
				 || sy.voices[v].second)	// main voices
					continue
				p_voice = voice_tb[v];
				st = sy.voices[v].st;
				s2 = p_voice.clef
				if (s2.clef_auto) {
//fixme: the staff may have other voices with explicit clefs...
//					if (!staff_clef[st].autoclef)
//						???
					new_type = set_auto_clef(st, s,
						staff_clef[st].clef ?
							staff_clef[st].clef.clef_type :
							'a');
					new_line = new_type == 't' ? 2 : 4
					set_yval(p_voice.clef)
				} else {
					new_type = s2.clef_type;
					new_line = s2.clef_line
				}
				if (!staff_clef[st].clef) {	// new staff
					if (s2.clef_auto) {
						if (s2.clef_type != 'a')
							p_voice.clef =
								clone(p_voice.clef);
						p_voice.clef.clef_type = new_type;
						p_voice.clef.clef_line = new_line
						set_yval(p_voice.clef)
					}
					staff_tb[st].clef =
						staff_clef[st].clef = p_voice.clef
					continue
				}
								// old staff
				if (new_type == staff_clef[st].clef.clef_type
				 && new_line == staff_clef[st].clef.clef_line)
					continue
				g = s.ts_prev
				while (g
				 && g.time == s.time
				 && (g.v != v || g.st != st))
					g = g.ts_prev
				if (!g || g.time != s.time) {
					g = s.ts_next
					while (g && (g.v != v || g.st != st))
						g = g.ts_next
					if (!g || g.time != s.time)
						g = s
				}
				if (g.type != C.CLEF) {
					g = insert_clef(g, new_type, new_line)
					if (s2.clef_auto)
						g.clef_auto = true
				}
				staff_clef[st].clef = p_voice.clef = g
			}
			continue
		default:
			s.mid = mid[s.st]
			continue
		case C.CLEF:
			break
		}

		if (s.clef_type == 'a') {
			s.clef_type = set_auto_clef(s.st,
						s.ts_next,
						staff_clef[s.st].clef.clef_type);
			s.clef_line = s.clef_type == 't' ? 2 : 4
			set_yval(s)
		}

		p_voice = s.p_v;
		p_voice.clef = s
		st = s.st
// may have been inserted on %%staves
//		if (s.clef_auto) {
//			unlksym(s)
//			continue
//		}

		if (staff_clef[st].clef) {
			if (s.clef_type == staff_clef[st].clef.clef_type
			 && s.clef_line == staff_clef[st].clef.clef_line) {
//				unlksym(s)
				continue
			}
		} else {

			// the voice moved to a new staff with a forced clef
			staff_tb[st].clef = s
		}
		staff_clef[st].clef = s
	}

	/* set a pitch to the symbols of voices with no note */
	sy = cur_sy
	for (v = 0; v < voice_tb.length; v++) {
		if (!sy.voices[v])
			continue
		s2 = voice_tb[v].sym
		if (!s2 || s2.notes[0].pit != 127)
			continue
		st = sy.voices[v].st
		switch (staff_tb[st].clef.clef_type) {
		default:
			pit = 22		/* 'B' */
			break
		case "c":
			pit = 16		/* 'C' */
			break
		case "b":
			pit = 10		/* 'D,' */
			break
		}
		for (s = s2; s; s = s.next)
			s.notes[0].pit = pit
	}
}

/* set the pitch of the notes according to the clefs
 * and set the vertical offset of the symbols */
/* this function is called at start of tune generation and
 * then, once per music line up to the old sequence */

var delta_tb = {
	t: 0 - 2 * 2,
	c: 6 - 3 * 2,
	b: 12 - 4 * 2,
	p: 0 - 3 * 2
}

/* upper and lower space needed by rests */
var rest_sp = [
	[18, 18],
	[12, 18],
	[12, 12],
	[10, 12],
	[10, 10],
	[10, 10],			/* crotchet */
	[8, 4],
	[9, 0],
	[9, 4],
	[6, 8]
]

// set the offsets of a rest
function roffs(s) {
	s.ymx = s.y + rest_sp[5 - s.nflags][0]
	s.ymn = s.y - rest_sp[5 - s.nflags][1]
} // roffs()

// (possible hook)
Abc.prototype.set_pitch = function(last_s) {
	var	s, s2, g, st, delta, pitch, note,
		dur = C.BLEN,
		m = nstaff + 1,
		staff_delta = new Int16Array(m * 2),	// delta clef
		sy = cur_sy

	// set the starting clefs of the staves
	for (st = 0; st <= nstaff; st++) {
		s = staff_tb[st].clef;
		staff_delta[st] = delta_tb[s.clef_type] + s.clef_line * 2
		if (s.clefpit)
			staff_delta[st] += s.clefpit
		if (cfmt.sound) {
			if (s.clef_octave && !s.clef_oct_transp)
				staff_delta[st] += s.clef_octave
		} else {
			if (s.clef_oct_transp)
				staff_delta[st] -= s.clef_octave
		}
	}

	for (s = tsfirst; s != last_s; s = s.ts_next) {
		st = s.st
		switch (s.type) {
		case C.CLEF:
			staff_delta[st] = delta_tb[s.clef_type] +
						s.clef_line * 2
			if (s.clefpit)
				staff_delta[st] += s.clefpit
			if (cfmt.sound) {
				if (s.clef_octave && !s.clef_oct_transp)
					staff_delta[st] += s.clef_octave
			} else {
				if (s.clef_oct_transp)
					staff_delta[st] -= s.clef_octave
			}
			set_yval(s)
			break
		case C.GRACE:
			for (g = s.extra; g; g = g.next) {
				delta = staff_delta[g.st]
				if (delta
				 && !s.p_v.ckey.k_drum) {
					for (m = 0; m <= g.nhd; m++) {
						note = g.notes[m];
						note.opit = note.pit
						note.pit += delta
					}
				}
				g.ymn = 3 * (g.notes[0].pit - 18) - 2;
				g.ymx = 3 * (g.notes[g.nhd].pit - 18) + 2
			}
			set_yval(s)
			break
		case C.KEY:
			s.k_y_clef = staff_delta[st] /* keep the y delta */
			/* fall thru */
		default:
			set_yval(s)
			break
		case C.MREST:
			if (s.invis)
				break
			s.y = 12;
			s.ymx = 24 + 15;
			s.ymn = -2
			break
		case C.REST:
			s.y = 12
			if (s.rep_nb > 1		// if measure repeat
			 || s.bar_mrep) {
				s.ymx = 38		// (24 + 14)
				s.ymn = 0
				break
			}
			roffs(s)
			// fall thru
		case C.NOTE:
			delta = staff_delta[st]
			if (delta
			 && !s.p_v.ckey.k_drum) {
				for (m = s.nhd; m >= 0; m--) {
					note = s.notes[m]
					note.opit = note.pit
					note.pit += delta
				}
			}
			if (s.dur < dur)
				dur = s.dur
			break
		}
	}
	if (!last_s)
		smallest_duration = dur
}

/* -- set the stem direction when multi-voices -- */
/* this function is called only once per tune */
// (possible hook)
Abc.prototype.set_stem_dir = function() {
	var	t, u, i, st, rvoice, v,
		v_st,			// voice -> staff 1 & 2
		st_v, vobj,		// staff -> (v, ymx, ymn)*
		v_st_tb,		// array of v_st
		st_v_tb = [],		// array of st_v
		s = tsfirst,
		sy = cur_sy,
		nst = sy.nstaff

	while (s) {
		for (st = 0; st <= nst; st++)
			st_v_tb[st] = []
		v_st_tb = []

		/* get the max/min offsets in the delta time */
/*fixme: the stem height is not calculated yet*/
		for (u = s; u; u = u.ts_next) {
			if (u.type == C.BAR)
				break;
			if (u.type == C.STAVES) {
				if (u != s)
					break
				sy = s.sy
				for (st = nst; st <= sy.nstaff; st++)
					st_v_tb[st] = []
				nst = sy.nstaff
				continue
			}
			if ((u.type != C.NOTE && u.type != C.REST)
			 || u.invis)
				continue
			st = u.st;
/*fixme:test*/
if (st > nst) {
	var msg = "*** fatal set_stem_dir(): bad staff number " + st +
			" max " + nst;
	error(2, null, msg);
	throw new Error(msg)
}
			v = u.v;
			v_st = v_st_tb[v]
			if (!v_st) {
				v_st = {
					st1: -1,
					st2: -1
				}
				v_st_tb[v] = v_st
			}
			if (v_st.st1 < 0) {
				v_st.st1 = st
			} else if (v_st.st1 != st) {
				if (st > v_st.st1) {
					if (st > v_st.st2)
						v_st.st2 = st
				} else {
					if (v_st.st1 > v_st.st2)
						v_st.st2 = v_st.st1;
					v_st.st1 = st
				}
			}
			st_v = st_v_tb[st];
			rvoice = sy.voices[v].range;
			for (i = st_v.length; --i >= 0; ) {
				vobj = st_v[i]
				if (vobj.v == rvoice)
					break
			}
			if (i < 0) {
				vobj = {
					v: rvoice,
					ymx: 0,
					ymn: 24
				}
				for (i = 0; i < st_v.length; i++) {
					if (rvoice < st_v[i].v) {
						st_v.splice(i, 0, vobj)
						break
					}
				}
				if (i == st_v.length)
					st_v.push(vobj)
			}

			if (u.type != C.NOTE)
				continue
			if (u.ymx > vobj.ymx)
				vobj.ymx = u.ymx
			if (u.ymn < vobj.ymn)
				vobj.ymn = u.ymn

			if (u.xstem) {
				if (u.ts_prev.st != st - 1
				 || u.ts_prev.type != C.NOTE) {
					error(1, s, "Bad !xstem!");
					u.xstem = false
/*fixme:nflags KO*/
				} else {
					u.ts_prev.multi = 1;
					u.multi = 1;
					u.stemless = true
				}
			}
		}

		for ( ; s != u; s = s.ts_next) {
			if (s.multi)
				continue
			switch (s.type) {
			default:
				continue
			case C.REST:
				// handle %%voicecombine 0
				if ((s.combine != undefined && s.combine < 0)
				 || !s.ts_next || s.ts_next.type != C.REST
				 || s.ts_next.st != s.st
				 || s.time != s.ts_next.time
				 || s.dur != s.ts_next.dur
				 || (s.a_dd && s.ts_next.a_dd)
				 || (s.a_gch && s.ts_next.a_gch)
				 || s.invis)
					break
				if (s.ts_next.a_dd)
					s.a_dd = s.ts_next.a_dd
				if (s.ts_next.a_gch)
					s.a_gch = s.ts_next.a_gch
				if (s.p_v.scale != 1
				 && s.ts_next.p_v.scale > s.p_v.scale)
				 	unlksym(s)
				else
					unlksym(s.ts_next)

				if ((!s.ts_prev.dur || s.ts_prev.time != s.time
				  || s.ts_prev.st != s.st)
				 && (s.ts_next.time != s.time
				  || s.ts_next.st != s.st))
					continue	// rest alone in the staff
				// fall thru
			case C.NOTE:
			case C.GRACE:
				break
			}

			st = s.st;
			v = s.v;
			v_st = v_st_tb[v];
			st_v = st_v_tb[st]
			if (v_st && v_st.st2 >= 0) {
				if (st == v_st.st1)
					s.multi = -1
				else if (st == v_st.st2)
					s.multi = 1
				continue
			}
			if (st_v.length <= 1) { /* voice alone on the staff */
//				if (s.multi)
//					continue
/*fixme:could be done in set_var()*/
				if (s.floating)
					s.multi = st == voice_tb[v].st ? -1 : 1
				continue
			}
			rvoice = sy.voices[v].range
			for (i = st_v.length; --i >= 0; ) {
				if (st_v[i].v == rvoice)
					break
			}
			if (i < 0)
				continue		/* voice ignored */
			if (i == st_v.length - 1) {
				s.multi = -1	/* last voice */
			} else {
				s.multi = 1	/* first voice(s) */

				/* if 3 voices, and vertical space enough,
				 * have stems down for the middle voice */
				if (i && i + 2 == st_v.length) {
					if (st_v[i].ymn - s.fmt.stemheight
							>= st_v[i + 1].ymx)
						s.multi = -1;

					/* special case for unison */
					t = s.ts_next
//fixme: pb with ../lacerda/evol-7.5.5.abc
					if (s.ts_prev
					 && s.ts_prev.time == s.time
					 && s.ts_prev.st == s.st
					 && s.notes[s.nhd].pit == s.ts_prev.notes[0].pit
					 && s.beam_st
					 && s.beam_end
					 && (!t
					  || t.st != s.st
					  || t.time != s.time))
						s.multi = -1
				}
			}
		}
		while (s && s.type == C.BAR)
			s = s.ts_next
	}
}

/* -- adjust the offset of the rests when many voices -- */
/* this function is called only once per tune */
function set_rest_offset() {
   var	s, s2, v, v_s, ymax, ymin, d,
		v_s_tb = [],
		sy = cur_sy

	// set a vertical offset on a line 
	function loffs(d) {
		return d > 0
			? Math.ceil(d / 6) * 6
			: -Math.ceil(-d / 6) * 6
	} // loffs()

	// shift a rest to the right
	function rshift() {
	    var	dx = s2.dots ? 15 : 10
		s2.notes[0].shhd = dx
		s2.xmx = dx
		d = (d + v_s.d) / 2
		d = loffs(d)
		s2.y += d
		s2.ymx += d
		s2.ymn += d
		v_s.d = 0
	} // rshift()

	// -- set_rest_off --
	for (s = tsfirst; s; s = s.ts_next) {
		if (s.invis)
			continue
		switch (s.type) {
		case C.STAVES:
			sy = s.sy
			// fall thru
		default:
			continue
		case C.REST:
			if (s.invis || !s.multi)
				continue
			v_s = v_s_tb[s.v]
			if (!v_s) {
				v_s_tb[s.v] = v_s = { d: 0}
			} else if (v_s.d) {
				s2 = v_s.s	// set the offsets of the previous rest
				d = loffs(v_s.d)
				s2.y += d
				s2.ymx += d
				s2.ymn += d
				v_s.d = 0
			}

			d = s.multi > 0 ? 0 : 24
				if (s.prev && s.prev.type == C.NOTE)
					d = (s.next && s.next.type == C.NOTE)
						? (s.prev.y + s.next.y) / 2
						: s.prev.y
				else if (s.next && s.next.type == C.NOTE)
					d = s.next.y
			else if (s.prev && s.prev.type == C.REST)
				d = s.prev.y
			if (s.multi > 0) {
				if (d >= 12)
					v_s.d = d - s.y
			} else {
				if (d <= 12)
					v_s.d = d - s.y
			}

			v_s.s = s
			v_s.st = s.st
			v_s.end_time = s.time + s.dur
			if (s.fmr)			// if full meeasure rest
				v_s.end_time -= s.p_v.wmeasure * .3
			if (s.seqst)
				continue
			s2 = s.ts_prev
			if (s2.st != s.st
			 || s2.invis)
				continue
			d = s2.ymn
			if (v_s_tb[s2.v] && v_s_tb[s2.v].d
			 && v_s_tb[s2.v] >= s.time)
				d += v_s_tb[s2.v].d
			if (s.ymx <= d)
				continue
			if (s2.type == C.NOTE) {
				v_s.d = d - s.ymx
				break
			}
			if (s2.type == C.REST
			 && s2.y < 18
			 && s.y >= 6)
				v_s.d = (d - s.ymx) / 2
			break
		case C.NOTE:
			if (s.invis || !s.multi)
				continue
			break
		}

		// check if any clash with a rest
		for (v = 0; v < v_s_tb.length; v++) {
			v_s = v_s_tb[v]
			if (!v_s
			 || v_s.st != s.st
			 || v == s.v
			 || v_s.end_time <= s.time)
				continue
			s2 = v_s.s				// rest
			if (sy.voices[v].range > sy.voices[s.v].range) {
				if (s2.ymx + v_s.d <= s.ymn)
					continue
				d = s.ymn - s2.ymx		// rest must go down
//				if (s2.time < s.time) {
					if (s.type == C.REST) {
						if (!v_s_tb[s.v])
							v_s_tb[s.v] = {d: 0}
						if (v_s_tb[s.v].d < 6)
							v_s_tb[s.v].d = 6
						d = -6
					} else {
						d /= 2
						if (s2.fmr)
							d -= 6
					}
//				}
				if (v_s.d) {
					if (v_s.d > 0) {	// if it was go up
						rshift()	// shift the rest
						continue
					}
					if (d >= v_s.d)
						continue
				}
			} else {
				if (s2.ymn + v_s.d >= s.ymx)
					continue
				d = s.ymx - s2.ymn		// rest must go up
				if (s.type == C.REST		// if rest
				 && s2 == s.ts_prev		// just under a rest
				 && s.y == s2.y) {		// at a same offset
					if (!v_s_tb[s.v])
						v_s_tb[s.v] = {d: 0}
					if (v_s_tb[s.v].d > -6)
						v_s_tb[s.v].d = -6
					d = 6
				} else if (s2.time < s.time) {
					d = s.ymx - s2.y
				}
				if (v_s.d) {
					if (v_s.d < 0) {	// if it was go down
						rshift()	// shift the rest
						continue
					}
					if (d <= v_s.d)
						continue
				}
			}
			v_s.d = d
		}
	}

	// update the offsets of the last rests
	for (v = 0; v < v_s_tb.length; v++) {
		v_s = v_s_tb[v]
		if (v_s && v_s.d) {
			s2 = v_s.s
			d = loffs(v_s.d)
			s2.y += d
			s2.ymx += d
			s2.ymn += d
		}
	}
}

/* -- create a starting symbol -- */
// last_s = symbol at same time
function new_sym(s, p_v, last_s) {
	s.p_v = p_v
	s.v = p_v.v
	s.st = p_v.st
	s.time = last_s.time

	if (p_v.last_sym) {
		s.next = p_v.last_sym.next
		if (s.next)
			s.next.prev = s;
		p_v.last_sym.next = s;
		s.prev = p_v.last_sym
	}
	p_v.last_sym = s;

	lktsym(s, last_s)
}

/* -- init the symbols at start of a music line -- */
function init_music_line() {
   var	p_voice, s, s1, s2, s3, last_s, v, st, shr, shrmx, shl,
	shlp, p_st, top,
	nv = voice_tb.length,
	fmt = tsfirst.fmt

	/* initialize the voices */
	for (v = 0; v < nv; v++) {
		if (!cur_sy.voices[v])
			continue
		p_voice = voice_tb[v];
		p_voice.st = cur_sy.voices[v].st
		p_voice.second = cur_sy.voices[v].second;
		p_voice.last_sym = p_voice.sym;

	// move the first clefs, key signatures and time signatures
	// to the staves
	   for (s = p_voice.sym; s && s.time == tsfirst.time; s = s.next) {
		switch (s.type) {
		case C.CLEF:
		case C.KEY:
		case C.METER:
			switch (s.type) {
			case C.CLEF:
				staff_tb[s.st].clef = s
				break
			case C.KEY:
				s.p_v.ckey = s
				break
			case C.METER:
				s.p_v.meter = s
				insert_meter = cfmt.writefields.indexOf('M') >= 0
					&& s.a_meter.length
				break
			}
			if (s.part)
				s.next.part = s.part
			unlksym(s)
			// fall thru
		case C.TEMPO:
		case C.BLOCK:
		case C.REMARK:
			continue
		}
		break
	    }
	}

	// generate the starting clefs, key signatures and time signatures

	// add a clef at start of the main voices
	last_s = tsfirst
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v]
		if (!cur_sy.voices[v]
		 || (cur_sy.voices[v].second
		  && !p_voice.bar_start))	// needed for correct linkage
			continue
		st = cur_sy.voices[v].st
		if (!staff_tb[st]
		 || !staff_tb[st].clef)
			continue
		s = clone(staff_tb[st].clef);
		s.v = v;
		s.p_v = p_voice;
		s.st = st;
		s.time = tsfirst.time;
		s.prev = null;
		s.next = p_voice.sym
		if (s.next)
			s.next.prev = s;
		p_voice.sym = p_voice.last_sym = s
		s.ts_next = last_s;
		if (last_s)
			s.ts_prev = last_s.ts_prev
		else
			s.ts_prev = null
		if (!s.ts_prev) {
			tsfirst = s;
		} else {
			s.ts_prev.ts_next = s
			delete s.seqst
		}
		if (last_s)
			last_s.ts_prev = s
		delete s.clef_small;
		delete s.part
		s.second = cur_sy.voices[v].second
// (fixme: needed for sample5 X:3 Fugue & staffnonote.html)
		if (!cur_sy.st_print[st])
			s.invis = true
		else if (!s.clef_none)
			delete s.invis
		s.fmt = fmt
	}

	/* add keysig */
	for (v = 0; v < nv; v++) {
		if (!cur_sy.voices[v]
		 || cur_sy.voices[v].second
		 || !cur_sy.st_print[cur_sy.voices[v].st])
			continue
		p_voice = voice_tb[v]
		s2 = p_voice.ckey
		if (s2.k_sf || s2.k_a_acc) {
			s = clone(s2)
			new_sym(s, p_voice, last_s)
			delete s.invis
			delete s.part
			s.k_old_sf = s2.k_sf	// no key cancel
			s.fmt = fmt
		}
	}

	/* add time signature (meter) if needed */
	if (insert_meter) {
		for (v = 0; v < nv; v++) {
			p_voice = voice_tb[v];
			s2 = p_voice.meter
			if (!cur_sy.voices[v]
			 || cur_sy.voices[v].second
			 || !cur_sy.st_print[cur_sy.voices[v].st])
//			 || !s2.a_meter.length)
				continue
			s = clone(s2)
			new_sym(s, p_voice, last_s)
			delete s.part
			s.fmt = fmt
		}
		insert_meter = false		// no meter any more
	}

	// add an invisible bar for the various continued elements
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v]
		if (p_voice.sls.length) {
			s = {
				type: C.BAR,
				fname: last_s.fname,
				bar_type: "|",
				dur: 0,
				multi: 0,
				invis: true,
				sls: p_voice.sls,
				fmt: fmt
			}
			new_sym(s, p_voice, last_s)
			p_voice.sls = []
		}
	}

	// add a bar for the continuation of repeat brackets
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v];
		s2 = p_voice.bar_start;
		p_voice.bar_start = null

		// check if bracket stop at this time
		for (s = last_s; s && s.time == last_s.time; s = s.ts_next) {
			if (s.rbstop) {
				s2 = null
				break
			}
		}

		if (!s2)
			continue
		if (!cur_sy.voices[v]
		 || !cur_sy.st_print[cur_sy.voices[v].st])
			continue

		if (p_voice.last_sym.type == C.BAR) {
			if (!p_voice.last_sym.rbstop)
				p_voice.last_sym.rbstart = 1
		} else {
			new_sym(s2, p_voice, last_s)
			s2.fmt = fmt
		}
	}

	// compute the spacing of the added symbols
	self.set_pitch(last_s);

	s = tsfirst
	s.seqst = true

	for (s = last_s; s.ts_next && !s.ts_next.seqst; s = s.ts_next)
		;
	if (s.ts_next		// a bit further in case different keys per voice
	 && s.ts_next.type != C.CLEF	// (the clef may move in allsymwidth)
	 && !s.tp			// (start of a tuplet)
	 && !s.ts_next.a_ly)		// (don't update next .shrink)
		for (s = s.ts_next; s.ts_next && !s.ts_next.seqst; s = s.ts_next)
			;
	s2 = s.ts_next
	s.ts_next = null
	set_allsymwidth()
	s.ts_next = s2
} // init_music_line()

// check if the tune ends on a measure bar
function check_end_bar() {
    var	s2,
	s = tsfirst
	while (s.ts_next)
		s = s.ts_next
	if (s.type != C.BAR) {
		s2 = _bar(s)
		s2.ts_prev = s

		s.next = s.ts_next = s2
	}
} // check_end_bar()

/* -- set a pitch in all symbols and the start/stop of the beams -- */
// and sort the pitches in the chords
// and build the chord symbols / annotations
// this function is called only once per tune
function set_words(p_voice) {
	var	s, s2, nflags, lastnote, res,
		start_flag = true,
		pitch = 127			/* no note */

	// adjust the duration of the notes in a decoration !trem1..4!
	function trem_adj(s) {
		s.prev.trem2 = true
		s.prev.head = ++s.head
		if (--s.nflags > 0) {
			s.nflags += s.ntrem
		} else {
			if (s.nflags <= -2) {
				s.stemless = true
				s.prev.stemless = true
			}
			s.nflags = s.ntrem
		}
		s.prev.nflags = s.nflags
	} // trem_adj()

	for (s = p_voice.sym; s; s = s.next) {
		if (s.type == C.NOTE) {
			pitch = s.notes[0].pit
			break
		}
	}
	for (s = p_voice.sym; s; s = s.next) {
		if (s.a_gch)
			self.gch_build(s)
		switch (s.type) {
		case C.MREST:
			start_flag = true
			break
		case C.BAR:
			res = s.fmt.bardef[s.bar_type]
			if (res)
				s.bar_type = res
			if (!s.beam_on)
				start_flag = true
			if (!s.next && s.prev
			 && !s.invis
			 && s.prev.head == C.OVALBARS)
				s.prev.head = C.SQUARE
			break
		case C.GRACE:
			for (s2 = s.extra; s2; s2 = s2.next) {
				s2.notes.sort(abc2svg.pitcmp)
				res = identify_note(s2, s2.dur_orig)
				s2.head = res[0]
				s2.dots = res[1]
				s2.nflags = res[2]
				if (s2.trem2
				 && (!s2.next || s2.next.trem2))
					trem_adj(s2)
			}
			break
		case C.NOTE:
		case C.REST:
			res = identify_note(s, s.dur_orig);
			s.head = res[0];
			s.dots = res[1];
			s.nflags = res[2]
			if (s.nflags <= -2)
				s.stemless = true

			if (s.xstem)
				s.nflags = 0	// beam break
			if (s.trem1) {
				if (s.nflags > 0)
					s.nflags += s.ntrem
				else
					s.nflags = s.ntrem
			}
			if (s.next && s.next.trem2)
				break
			if (s.trem2) {
				trem_adj(s)
				break
			}

			nflags = s.nflags

			if (s.ntrem)
				nflags -= s.ntrem
			if (s.type == C.REST && s.beam_end
			 && !s.beam_on) {
//				s.beam_end = false;
				start_flag = true
			}
			if (start_flag
			 || nflags <= 0) {
				if (lastnote) {
					lastnote.beam_end = true;
					lastnote = null
				}
				if (nflags <= 0) {
					s.beam_st = s.beam_end = true
				} else if (s.type == C.NOTE || s.beam_on) {
					s.beam_st = true;
					start_flag = false
				}
			}
			if (s.beam_end)
				start_flag = true
			if (s.type == C.NOTE || s.beam_on)
				lastnote = s
			break
		}
		if (s.type == C.NOTE) {
			if (s.nhd)
				s.notes.sort(abc2svg.pitcmp)
			pitch = s.notes[0].pit
//			if (s.prev
//			 && s.prev.type != C.NOTE) {
//				s.prev.notes[0].pit = (s.prev.notes[0].pit
//						    + pitch) / 2
			for (s2 = s.prev; s2; s2 = s2.prev) {
				if (s2.type != C.REST)
					break
				s2.notes[0].pit = pitch
			}
		} else {
			if (!s.notes) {
				s.notes = []
				s.notes[0] = {}
				s.nhd = 0
			}
			s.notes[0].pit = pitch
		}
	}
	if (lastnote)
		lastnote.beam_end = true
}

/* -- set the end of the repeat sequences -- */
function set_rb(p_voice) {
    var	s2, n,
	s = p_voice.sym

	while (s) {
		if (s.type != C.BAR || !s.rbstart || s.norepbra) {
			s = s.next
			continue
		}
		n = 0;
		s2 = null
		for (s = s.next; s; s = s.next) {
			if (s.type != C.BAR)
				continue
			if (s.rbstop)
				break
			if (!s.next) {
				s.rbstop = 2	// right repeat with end
				break
			}
			n++
			if (n == s.fmt.rbmin)
				s2 = s
			if (n == s.fmt.rbmax) {
				if (s2)
					s = s2;
				s.rbstop = 1	// right repeat without end
				break
			}
		}
	}
}

/* -- initialize the generator -- */
// this function is called only once per tune

var delpit = [0, -7, -14, 0]

function set_global() {
    var	p_voice, v,
	nv = voice_tb.length,
	sy = cur_sy,
	st = sy.nstaff

	insert_meter = cfmt.writefields.indexOf('M') >= 0

	/* get the max number of staves */
	while (1) {
		sy = sy.next
		if (!sy)
			break
		if (sy.nstaff > st)
			st = sy.nstaff
	}
	nstaff = st;

	// there must be a bar at end of tune
	check_end_bar()

	/* set the pitches, the words (beams) and the repeat brackets */
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v];
		set_words(p_voice)
		p_voice.ckey = p_voice.key	// starting key
// (test removed because v.second may change after %%staves)
//		if (!p_voice.second && !p_voice.norepbra)
			set_rb(p_voice)
	}

	/* set the staff of the floating voices */
	if (nv > 1) {
		set_float()

	// expand the multi-rests as needed
		if (glovar.mrest_p)
			mrest_expand()
	}

	if (glovar.ottava && cfmt.sound != "play")
		set_ottava();

	// set the clefs and adjust the pitches of all symbol
	set_clefs();
	self.set_pitch(null)
}

// get the left offsets of the first and other staff systems
// return left shift [no name, first music line, other lines
function get_lshift() {
    var	st, v, p_v, p1, po, fnt, w,
	sy = cur_sy,
	lsh = [0, 0, 0],
	nv = voice_tb.length

	// get the max width of a voice name/subname
	function get_wx(p, wx) {
	    var	w, j,
		i = 0

		p += '\n'
		while (1) {
			j = p.indexOf("\n", i)
			if (j < 0)
				break
			w = strwh(p.slice(i, j))[0] + 12
			if (w > wx)
				wx = w
			if (j < 0)
				break
			i = j + 1
		}
		return wx
	} // get_wx()

	for (v = 0; v < nv; v++) {
		p_v = voice_tb[v]
		p1 = p_v.nm
		po = p_v.snm
		if ((p1 || po) && !fnt) {
			set_font("voice")
			fnt = gene.deffont
		}
		if (p1) {
			w = get_wx(p1, lsh[1])
			if (w > lsh[1])
				lsh[1] = w
		}
		if (po) {
			w = get_wx(po, lsh[2])
			if (w > lsh[2])
				lsh[2] = w
		}
	}
	// add the width of the braces/brackets
	w = 0
	while (sy) {
		for (st = 0; st <= sy.nstaff; st++) {
			if (sy.staves[st].flags
					& (OPEN_BRACE2 | OPEN_BRACKET2)) {
				w = 12
				break
			}
			if (sy.staves[st].flags & (OPEN_BRACE | OPEN_BRACKET))
				w = 6
		}
		if (w == 12)
			break
		sy = sy.next
	}
	lsh[0] = w
	lsh[1] += w
	lsh[2] += w
	return lsh
} // get_lshift()

/* -- return the left indentation of the staves -- */
function set_indent(lsh) {
    var	st, v, w, p_voice, p, i, j, font,
	vnt = 0,
	fmt = tsnext ? tsnext.fmt : cfmt

	// name or subname?
	if (fmt.systvoices) {		// put the voice names in the staff system
	    for (v = voice_tb.length; --v >= 0; ) {
		p_voice = voice_tb[v]
		if (!cur_sy.voices[v]
		 || !gene.st_print[p_voice.st])
			continue
		if (p_voice.nm
		 && (fmt.systvoices == 1
		  || (p_voice.new_name && fmt.systvoices == 3))) {
			vnt = 1		// full name
			break
		}
		if (p_voice.snm)
			vnt = 2		// subname
	    }
	}
	gene.vnt = vnt			// voice name type for draw
	return lsh[vnt]
}

/* -- decide on beams and on stem directions -- */
/* this routine is called only once per tune */
function set_beams(sym) {
    var	s, t, g, beam, s_opp, n, m, mid_p, pu, pd,
	laststem = -1

	for (s = sym; s; s = s.next) {
		if (s.type != C.NOTE) {
			if (s.type != C.GRACE)
				continue
			g = s.extra
			if (g.stem == 2) {	/* opposite gstem direction */
				s_opp = s
				continue
			}
			if (!s.stem)
				s.stem = s.multi || 1
			for (; g; g = g.next) {
				g.stem = s.stem;
				g.multi = s.multi
			}
			continue
		}

		if (!s.stem && s.multi)
			s.stem = s.multi
		if (!s.stem) {			// if note alone on the staff
			mid_p = s.mid / 3 + 18

			/* notes in a beam have the same stem direction */
			if (beam) {
				s.stem = laststem
			} else if (s.beam_st && !s.beam_end) {	// beam start
				beam = true;

				// the stem direction is the one of the note
				// farthest from the middle line
						pu = s.notes[s.nhd].pit;
						pd = s.notes[0].pit
						for (g = s.next; g; g = g.next) {
							if (g.type != C.NOTE)
								continue
							if (g.stem || g.multi) // if forced direction
								s.stem = g.stem || g.multi
							if (g.notes[g.nhd].pit > pu)
								pu = g.notes[g.nhd].pit
							if (g.notes[0].pit < pd)
								pd = g.notes[0].pit
							if (g.beam_end)
								break
						}
					if (!s.stem && g.beam_end) {
							if (pu + pd < mid_p * 2) {
								s.stem = 1
							} else if (pu + pd > mid_p * 2) {
								s.stem = -1
							} else {
								if (s.fmt.bstemdown)
									s.stem = -1
							}
						}
				if (!s.stem)
					s.stem = laststem
			} else {				// no beam
				n = (s.notes[s.nhd].pit + s.notes[0].pit) / 2
				if (n == mid_p && s.nhd > 1) {
					for (m = 0; m < s.nhd; m++) {
						if (s.notes[m].pit >= mid_p)
							break
					}
					n = m * 2 < s.nhd ? mid_p - 1 : mid_p + 1
				}
				if (n < mid_p)
					s.stem = 1
				else if (n > mid_p || s.fmt.bstemdown)
					s.stem = -1
				else
					s.stem = laststem
			}
		} else {			/* stem set by set_stem_dir */
			if (s.beam_st && !s.beam_end)
				beam = true
		}
		if (s.beam_end)
			beam = false;
		laststem = s.stem;

		if (s_opp) {			/* opposite gstem direction */
			for (g = s_opp.extra; g; g = g.next)
				g.stem = -laststem;
			s_opp.stem = -laststem;
			s_opp = null
		}
	}
}

// check if there may be one head for unison when voice overlap
function same_head(s1, s2) {
    var	i1, i2, l1, l2, head, i11, i12, i21, i22, sh1, sh2,
	shu = s1.fmt.shiftunison || 0

	if (shu >= 3)
		return false
	if ((l1 = s1.dur) >= C.BLEN)
		return false
	if ((l2 = s2.dur) >= C.BLEN)
		return false
	if (s1.stemless && s2.stemless)
		return false
	if (s1.dots != s2.dots) {
		if (shu & 1
		 || s1.dots * s2.dots != 0)
			return false
	}
	if (s1.stem * s2.stem > 0)
		return false

	/* check if a common unison */
	i1 = i2 = 0
	if (s1.notes[0].pit > s2.notes[0].pit) {
//fixme:dots
		if (s1.stem < 0)
			return false
		while (s2.notes[i2].pit != s1.notes[0].pit) {
			if (++i2 > s2.nhd)
				return false
		}
	} else if (s1.notes[0].pit < s2.notes[0].pit) {
//fixme:dots
		if (s2.stem < 0)
			return false
		while (s2.notes[0].pit != s1.notes[i1].pit) {
			if (++i1 > s1.nhd)
				return false
		}
	}
	if (s2.notes[i2].acc != s1.notes[i1].acc)
		return false;
	i11 = i1;
	i21 = i2;
	sh1 = s1.notes[i1].shhd;
	sh2 = s2.notes[i2].shhd
	do {
//fixme:dots
		i1++;
		i2++
		if (i1 > s1.nhd) {
//fixme:dots
//			if (s1.notes[0].pit < s2.notes[0].pit)
//				return false
			break
		}
		if (i2 > s2.nhd) {
//fixme:dots
//			if (s1.notes[0].pit > s2.notes[0].pit)
//				return false
			break
		}
		if (s2.notes[i2].acc != s1.notes[i1].acc)
			return false
		if (sh1 < s1.notes[i1].shhd)
			sh1 = s1.notes[i1].shhd
		if (sh2 < s2.notes[i2].shhd)
			sh2 = s2.notes[i2].shhd
	} while (s2.notes[i2].pit == s1.notes[i1].pit)
//fixme:dots
	if (i1 <= s1.nhd) {
		if (i2 <= s2.nhd)
			return false
		if (s2.stem > 0)
			return false
	} else if (i2 <= s2.nhd) {
		if (s1.stem > 0)
			return false
	}
	i12 = i1;
	i22 = i2;

	head = 0
	if (l1 != l2) {
		if (l1 < l2) {
			l1 = l2;
			l2 = s1.dur
		}
		if (l1 < C.BLEN / 2) {
			if (s2.dots)
				head = 2
			else if (s1.dots)
				head = 1
		} else if (l2 < C.BLEN / 4) {	/* (l1 >= C.BLEN / 2) */
//			if (shu == 2)
//			 || s1.dots != s2.dots)
			if (shu & 2)
				return false
			head = s2.dur >= C.BLEN / 2 ? 2 : 1
		} else {
			return false
		}
	}
	if (!head)
		head = s1.p_v.scale < s2.p_v.scale ? 2 : 1
	if (head == 1) {
		for (i2 = i21; i2 < i22; i2++) {
			s2.notes[i2].invis = true
			delete s2.notes[i2].acc
		}
		for (i2 = 0; i2 <= s2.nhd; i2++)
			s2.notes[i2].shhd += sh1
	} else {
		for (i1 = i11; i1 < i12; i1++) {
			s1.notes[i1].invis = true
			delete s1.notes[i1].acc
		}
		for (i1 = 0; i1 <= s1.nhd; i1++)
			s1.notes[i1].shhd += sh2
	}
	if (s1.dots == s2.dots)			// let the dots in one voice
		s2.dots = 0
	return true
}

/* handle unison with different accidentals */
function unison_acc(s1, s2, i1, i2) {
    var	m, d, acc

	acc = s2.notes[i2].acc
	if (!acc) {
		d = w_note[s2.head] * 2 + s2.xmx + s1.notes[i1].shac + 2
		acc = s1.notes[i1].acc
		if (typeof acc == "object")	// microtone
			d += 2
		if (s2.dots)
			d += 6
		for (m = 0; m <= s1.nhd; m++) {
			s1.notes[m].shhd += d;
			s1.notes[m].shac -= d
		}
		s1.xmx += d
	} else {
		d = w_note[s1.head] * 2 + s1.xmx + s2.notes[i2].shac + 2
		if (typeof acc == "object")	// microtone
			d += 2
		if (s1.dots)
			d += 6
		for (m = 0; m <= s2.nhd; m++) {
			s2.notes[m].shhd += d;
			s2.notes[m].shac -= d
		}
		s2.xmx += d
		if (s1.notes[i1].acc)
			s1.notes[i1].shac -= 7
//fixme: why not dx_tb[s2.head] ?
	}
}

var MAXPIT = 48 * 2

/* set the left space of a note/chord */
function set_left(s) {
	var	m, i, j, shift,
		w_base = w_note[s.head],
		w = w_base,
		left = []

	for (i = 0; i < MAXPIT; i++)
		left.push(-100)

	/* stem */
	if (s.nflags > -2) {
		if (s.stem > 0) {
			w = -w;
			i = s.notes[0].pit * 2;
			j = (Math.ceil((s.ymx - 2) / 3) + 18) * 2
		} else {
			i = (Math.ceil((s.ymn + 2) / 3) + 18) * 2;
			j = s.notes[s.nhd].pit * 2
		}
		if (i < 0)
			i = 0
		if (j >= MAXPIT)
			j = MAXPIT - 1
		while (i <= j)
			left[i++] = w
	}

	/* notes */
	shift = s.notes[s.stem > 0 ? 0 : s.nhd].shhd;	/* previous shift */
	for (m = 0; m <= s.nhd; m++) {
		w = -s.notes[m].shhd + w_base + shift;
		i = s.notes[m].pit * 2
		if (i < 0)
			i = 0
		else if (i >= MAXPIT - 1)
			i = MAXPIT - 2
		if (w > left[i])
			left[i] = w
		if (s.head != C.SQUARE)
			w -= 1
		if (w > left[i - 1])
			left[i - 1] = w
		if (w > left[i + 1])
			left[i + 1] = w
	}

	return left
}

/* set the right space of a note/chord */
function set_right(s) {
	var	m, i, j, k, shift,
		w_base = w_note[s.head],
		w = w_base,
		flags = s.nflags > 0 && s.beam_st && s.beam_end,
		right = []

	for (i = 0; i < MAXPIT; i++)
		right.push(-100)

	/* stem and flags */
	if (s.nflags > -2) {
		if (s.stem < 0) {
			w = -w;
			i = (Math.ceil((s.ymn + 2) / 3) + 18) * 2;
			j = s.notes[s.nhd].pit * 2;
			k = i + 4
		} else {
			i = s.notes[0].pit * 2;
			j = (Math.ceil((s.ymx - 2) / 3) + 18) * 2
		}
		if (i < 0)
			i = 0
		if (j > MAXPIT)
			j = MAXPIT
		while (i < j)
			right[i++] = w
	}

	if (flags) {
		if (s.stem > 0) {
			if (s.xmx == 0)
				i = s.notes[s.nhd].pit * 2
			else
				i = s.notes[0].pit * 2;
			i += 4
			if (i < 0)
				i = 0
			for (; i < MAXPIT && i <= j - 4; i++)
				right[i] = 11
		} else {
			i = k
			if (i < 0)
				i = 0
			for (; i < MAXPIT && i <= s.notes[0].pit * 2 - 4; i++)
				right[i] = 3.5
		}
	}

	/* notes */
	shift = s.notes[s.stem > 0 ? 0 : s.nhd].shhd	/* previous shift */
	for (m = 0; m <= s.nhd; m++) {
		w = s.notes[m].shhd + w_base - shift;
		i = s.notes[m].pit * 2
		if (i < 0)
			i = 0
		else if (i >= MAXPIT - 1)
			i = MAXPIT - 2
		if (w > right[i])
			right[i] = w
		if (s.head != C.SQUARE)
			w -= 1
		if (w > right[i - 1])
			right[i - 1] = w
		if (w > right[i + 1])
			right[i + 1] = w
	}

	return right
}

/* -- shift the notes horizontally when voices overlap -- */
/* this routine is called only once per tune */
function set_overlap() {
    var	s, s1, s2, s3, i, i1, i2, m, sd, t, dp,
	d, d2, dr, dr2, dx,
	left1, right1, left2, right2, right3, pl, pr,
	sy = cur_sy

	// invert the voices
	function v_invert() {
		s1 = s2;
		s2 = s;
		d = d2;
		pl = left1;
		pr = right1;
		dr2 = dr
	}

	for (s = tsfirst; s; s = s.ts_next) {
		if (s.type != C.NOTE
		 || s.invis) {
			if (s.type == C.STAVES)
				sy = s.sy
			continue
		}

		// set the dot vertical offset of secondary voices
		if (s.second)
			s.dot_low = 1 //true

		/* treat the stem on two staves with different directions */
		if (s.xstem
		 && s.ts_prev.stem < 0) {
			for (m = 0; m <= s.nhd; m++) {
				s.notes[m].shhd -= 7;		// stem_xoff
				s.notes[m].shac += 16
			}
		}

		/* search the next note at the same time on the same staff */
		s2 = s
		while (1) {
			s2 = s2.ts_next
			if (!s2)
				break
			if (s2.time != s.time) {
				s2 = null
				break
			}
			if (s2.type == C.NOTE
			 && !s2.invis
			 && s2.st == s.st)
				break
		}
		if (!s2)
			continue
		s1 = s

		/* no shift if no overlap */
		if (s1.ymn > s2.ymx
		 || s1.ymx < s2.ymn)
			continue

		if (same_head(s1, s2))
			continue

		// special case when only a second and no dots
	    if (!s1.dots && !s2.dots)
		if ((s1.stem > 0 && s2.stem < 0
		  && s1.notes[0].pit == s2.notes[s2.nhd].pit + 1)
		 || (s1.stem < 0 && s2.stem > 0
		  && s1.notes[s1.nhd].pit + 1 == s2.notes[0].pit)) {
			if (s1.stem < 0) {
				s1 = s2;
				s2 = s
			}
			d = s1.notes[0].shhd + 7
			for (m = 0; m <= s2.nhd; m++)	// shift the lower note(s)
				s2.notes[m].shhd += d
			s2.xmx += d
			s1.xmx = s2.xmx		// align the dots
			continue
		}

		/* compute the minimum space for 's1 s2' and 's2 s1' */
		right1 = set_right(s1);
		left2 = set_left(s2);

		s3 = s1.ts_prev
		if (s3 && s3.time == s1.time
		 && s3.st == s1.st && s3.type == C.NOTE && !s3.invis) {
			right3 = set_right(s3)
			for (i = 0; i < MAXPIT; i++) {
				if (right3[i] > right1[i])
					right1[i] = right3[i]
			}
		} else {
			s3 = null
		}
		d = -10
		for (i = 0; i < MAXPIT; i++) {
			if (left2[i] + right1[i] > d)
				d = left2[i] + right1[i]
		}

		if (d < -3			// no clash if no dots clash
		 && ((s2.notes[0].pit & 1)
		  || !(s1.dots || s2.dots)
		  || (!(s1.notes[s1.nhd].pit == s2.notes[0].pit + 2
		    && s1.dot_low)
		   && !(s1.notes[s1.nhd].pit + 2 == s2.notes[0].pit
		    && s2.dot_low))))
			continue

		right2 = set_right(s2);
		left1 = set_left(s1)
		if (s3) {
			right3 = set_left(s3)
			for (i = 0; i < MAXPIT; i++) {
				if (right3[i] > left1[i])
					left1[i] = right3[i]
			}
		}
		d2 = dr = dr2 = -100
		for (i = 0; i < MAXPIT; i++) {
			if (left1[i] + right2[i] > d2)
				d2 = left1[i] + right2[i]
			if (right2[i] > dr2)
				dr2 = right2[i]
			if (right1[i] > dr)
				dr = right1[i]
		}

		/* check for unison with different accidentals
		 * and clash of dots */
		t = 0;
		i1 = s1.nhd;
		i2 = s2.nhd
		while (1) {
			dp = s1.notes[i1].pit - s2.notes[i2].pit
			switch (dp) {
			case 2:
				if (!(s1.notes[i1].pit & 1))
					s1.dot_low = false
				break
			case 1:
				if (s1.notes[i1].pit & 1)
					s2.dot_low = true
				else
					s1.dot_low = false
				break
			case 0:
				if (s1.notes[i1].acc != s2.notes[i2].acc) {
					t = -1
					break
				}
				if (s2.notes[i2].acc) {
					if (!s1.notes[i1].acc)
						s1.notes[i1].acc = s2.notes[i2].acc
					s2.notes[i2].acc = 0
				}
				if (s1.dots && s2.dots
				 && (s1.notes[i1].pit & 1))
					t = 1
				break
			case -1:
				if (s1.notes[i1].pit & 1)
					s2.dot_low = false
				else
					s1.dot_low = true
				break
			case -2:
				if (!(s1.notes[i1].pit & 1))
					s2.dot_low = false
				break
			}
			if (t < 0)
				break
			if (dp >= 0) {
				if (--i1 < 0)
					break
			}
			if (dp <= 0) {
				if (--i2 < 0)
					break
			}
		}

		if (t < 0) {	/* unison and different accidentals */
			unison_acc(s1, s2, i1, i2)
			continue
		}

		sd = 0;
		if (s1.dots) {
			if (!s2.dots
			 || !t)			// if no dot clash
				sd = 1		// align the dots
		} else if (s2.dots) {
			if (d2 + dr < d + dr2)
				sd = 1		/* align the dots */
		}
		pl = left2;
		pr = right2
		if (!s3 && d2 + dr < d + dr2)
			v_invert()
		d += 3
		if (d < 0)
			d = 0;			// (not return!)

		/* handle the previous shift */
		m = s1.stem >= 0 ? 0 : s1.nhd;
		d += s1.notes[m].shhd;
		m = s2.stem >= 0 ? 0 : s2.nhd;
		d -= s2.notes[m].shhd

		/*
		 * room for the dots
		 * - if the dots of v1 don't shift, adjust the shift of v2
		 * - otherwise, align the dots and shift them if clash
		 */
		if (s1.dots) {
			dx = 7.7 + s1.xmx +		// x 1st dot
				3.5 * s1.dots - 3.5 +	// x last dot
				3;			// some space
			if (!sd) {
				d2 = -100;
				for (i1 = 0; i1 <= s1.nhd; i1++) {
					i = s1.notes[i1].pit
					if (!(i & 1)) {
						if (!s1.dot_low)
							i++
						else
							i--
					}
					i *= 2
					if (i < 1)
						i = 1
					else if (i >= MAXPIT - 1)
						i = MAXPIT - 2
					if (pl[i] > d2)
						d2 = pl[i]
					if (pl[i - 1] + 1 > d2)
						d2 = pl[i - 1] + 1
					if (pl[i + 1] + 1 > d2)
						d2 = pl[i + 1] + 1
				}
				if (dx + d2 + 2 > d)
					d = dx + d2 + 2
			} else {
				if (dx < d + dr2 + s2.xmx) {
					d2 = 0
					for (i1 = 0; i1 <= s1.nhd; i1++) {
						i = s1.notes[i1].pit
						if (!(i & 1)) {
							if (!s1.dot_low)
								i++
							else
								i--
						}
						i *= 2
						if (i < 1)
							i = 1
						else if (i >= MAXPIT - 1)
							i = MAXPIT - 2
						if (pr[i] > d2)
							d2 = pr[i]
						if (pr[i - 1] + 1 > d2)
							d2 = pr[i - 1] = 1
						if (pr[i + 1] + 1 > d2)
							d2 = pr[i + 1] + 1
					}
					if (d2 > 4.5
					 && 7.7 + s1.xmx + 2 < d + d2 + s2.xmx)
						s2.xmx = d2 + 3 - 7.7
				}
			}
		}

		for (m = s2.nhd; m >= 0; m--) {
			s2.notes[m].shhd += d
//			if (s2.notes[m].acc
//			 && s2.notes[m].pit < s1.notes[0].pit - 4)
//				s2.notes[m].shac -= d
		}
		s2.xmx += d
		if (sd)
			s1.xmx = s2.xmx		// align the dots
	}
}

/* -- set the stem height -- */
/* this routine is called only once per tune */
// (possible hook)
Abc.prototype.set_stems = function() {
	var s, s2, g, slen, scale,ymn, ymx, nflags, ymin, ymax

	for (s = tsfirst; s; s = s.ts_next) {
		if (s.type != C.NOTE) {
			if (s.type != C.GRACE)
				continue
			ymin = ymax = s.mid
			for (g = s.extra; g; g = g.next) {
				slen = GSTEM
				if (g.nflags > 1)
					slen += 1.2 * (g.nflags - 1);
				ymn = 3 * (g.notes[0].pit - 18);
				ymx = 3 * (g.notes[g.nhd].pit - 18)
				if (s.stem >= 0) {
					g.y = ymn;
					g.ys = ymx + slen;
					ymx = Math.round(g.ys)
				} else {
					g.y = ymx;
					g.ys = ymn - slen;
					ymn = Math.round(g.ys)
				}
				ymx += 4
				ymn -= 4
				if (ymn < ymin)
					ymin = ymn
				else if (ymx > ymax)
					ymax = ymx;
				g.ymx = ymx;
				g.ymn = ymn
			}
			s.ymx = ymax;
			s.ymn = ymin
			continue
		}

		/* shift notes in chords (need stem direction to do this) */
		set_head_shift(s);

		/* if start or end of beam, adjust the number of flags
		 * with the other end */
		nflags = s.nflags
		if (s.beam_st && !s.beam_end) {
			if (s.feathered_beam)
				nflags = ++s.nflags
			for (s2 = s.next; /*s2*/; s2 = s2.next) {
				if (s2.type == C.NOTE) {
					if (s.feathered_beam)
						s2.nflags++
					if (s2.beam_end)
						break
				}
			}
/*			if (s2) */
			    if (s2.nflags > nflags)
				nflags = s2.nflags
		} else if (!s.beam_st && s.beam_end) {
//fixme: keep the start of beam ?
			for (s2 = s.prev; /*s2*/; s2 = s2.prev) {
				if (s2.beam_st)
					break
			}
/*			if (s2) */
			    if (s2.nflags > nflags)
				nflags = s2.nflags
		}

		/* set height of stem end */
		slen = s.fmt.stemheight
		switch (nflags) {
//		case 2: slen += 0; break
		case 3:	slen += 4; break
		case 4:	slen += 8; break
		case 5:	slen += 12; break
		}
		if ((scale = s.p_v.scale) != 1)
			slen *= (scale + 1) * .5;
		ymn = 3 * (s.notes[0].pit - 18)
		if (s.nhd > 0) {
			slen -= 2;
			ymx = 3 * (s.notes[s.nhd].pit - 18)
		} else {
			ymx = ymn
		}
		if (s.ntrem)
			slen += 2 * s.ntrem		/* tremolo */
		if (s.decstm != null) {			// if deco on the stem
			if (nflags <= 0) {
				if (slen < s.decstm + 6)
					slen = s.decstm + 6
			} else {
			    var	t = nflags * 4		// beams

				if (s.beam_st & s.beam_end)
					t += 2		// flags
				if (slen < s.decstm + 4 + t)
					slen = s.decstm + 4 + t
			}
		}
		if (s.stemless) {
			if (s.stem >= 0) {
				s.y = ymn;
				s.ys = ymx
			} else {
				s.ys = ymn;
				s.y = ymx
			}
			s.ymx = ymx + 4;
			s.ymn = ymn - 4
		} else if (s.stem >= 0) {
			if (s.notes[s.nhd].pit > 26
			 && (nflags <= 0
			  || !s.beam_st
			  || !s.beam_end)) {
				slen -= 2
				if (s.notes[s.nhd].pit > 28)
					slen -= 2
			}
			s.y = ymn
			if (s.notes[0].tie)
				ymn -= 3;
			s.ymn = ymn - 4;
			s.ys = ymx + slen
			if (s.ys < s.mid)
				s.ys = s.mid;
			s.ymx = (s.ys + 2.5) | 0
		} else {			/* stem down */
			if (s.notes[0].pit < 18
			 && (nflags <= 0
			  || !s.beam_st || !s.beam_end)) {
				slen -= 2
				if (s.notes[0].pit < 16)
					slen -= 2
			}
			s.ys = ymn - slen
			if (s.ys > s.mid)
				s.ys = s.mid;
			s.ymn = (s.ys - 2.5) | 0;
			s.y = ymx
/*fixme:the tie may be lower*/
			if (s.notes[s.nhd].tie)
				ymx += 3;
			s.ymx = ymx + 4
		}
	}
}

// generate a block symbol
var blocks = []		// array of delayed block symbols

// (possible hook)
Abc.prototype.block_gen = function(s) {
	switch (s.subtype) {
	case "leftmargin":
	case "rightmargin":
	case "pagescale":
	case "pagewidth":
	case "scale":
	case "staffwidth":
		self.set_format(s.subtype, s.param)
		break
	case "mc_start":		// multicol start
		if (multicol) {
			error(1, s, "No end of the previous %%multicol")
			break
		}
		multicol = {
			state: parse.state,
			posy: posy,
			maxy: posy,
			lm: cfmt.leftmargin,
			rm: cfmt.rightmargin,
			w: cfmt.pagewidth,
			sc: cfmt.scale
		}
		break
	case "mc_new":			// multicol new
		if (!multicol || multicol.state != parse.state) {
			error(1, s, "%%multicol new without start")
			break
		}
		if (posy > multicol.maxy)
			multicol.maxy = posy
		cfmt.leftmargin = multicol.lm
		cfmt.rightmargin = multicol.rm
		cfmt.pagewidth = multicol.w
		cfmt.scale = multicol.sc
		posy = multicol.posy
		img.chg = 1 //true
		break
	case "mc_end":			// multicol end
		if (!multicol || multicol.state != parse.state) {
			error(1, s, "%%multicol end without start")
			break
		}
		if (posy < multicol.maxy)
			posy = multicol.maxy
		cfmt.leftmargin = multicol.lm
		cfmt.rightmargin = multicol.rm
		cfmt.pagewidth = multicol.w
		cfmt.scale = multicol.sc
		multicol = undefined
		blk_flush()
		img.chg = 1 //true
		break
	case "ml":
		blk_flush()
		user.img_out(s.text)
		break
	case "newpage":
		if (!user.page_format)
			break
		blk_flush()
		if (blkdiv < 0)		// split the tune
			user.img_out('</div>')
		blkdiv = 2		// start the next SVG in a new page
		break
	case "sep":
		set_page();
		vskip(s.sk1);
		output += '<path class="stroke"\n\td="M';
		out_sxsy((img.width -s.l) / 2 - img.lm, ' ', 0)
		output += 'h' + s.l.toFixed(1) + '"/>\n';
		vskip(s.sk2);
		break
	case "text":
		set_font(s.font)
		use_font(s.font)
		write_text(s.text, s.opt)
		break
	case "title":
		write_title(s.text, true)
		break
	case "vskip":
		vskip(s.sk);
		break
	}
}

/* -- define the start and end of a piece of tune -- */
/* tsnext becomes the beginning of the next line */
function set_piece() {
    var	s, last, p_voice, st, v, nv, tmp, non_empty,
	non_empty_gl = [],
	sy = cur_sy

	function reset_staff(st) {
		var	p_staff = staff_tb[st],
			sy_staff = sy.staves[st]

		if (!p_staff)
			p_staff = staff_tb[st] = {}
		p_staff.y = 0;			// staff system not computed yet
		p_staff.stafflines = sy_staff.stafflines;
		p_staff.staffscale = sy_staff.staffscale;
		p_staff.ann_top = p_staff.ann_bot = 0
	} // reset_staff()

	// adjust the empty flag of brace systems
	function set_brace() {
		var	st, i, empty_fl,
			n = sy.staves.length

		// if a system brace has empty and non empty staves, keep all staves
		for (st = 0; st < n; st++) {
			if (!(sy.staves[st].flags & (OPEN_BRACE | OPEN_BRACE2)))
				continue
			empty_fl = 0;
			i = st
			while (st < n) {
				empty_fl |= non_empty[st] ? 1 : 2
				if (sy.staves[st].flags & (CLOSE_BRACE | CLOSE_BRACE2))
					break
				st++
			}
			if (empty_fl == 3) {	// if both empty and not empty staves
				while (i <= st) {
					non_empty[i] = true;
					non_empty_gl[i++] = true
				}
			}
		}
	} // set_brace()

	// set the top and bottom of the staves
	function set_top_bot() {
	    var	st, p_staff, i, l

		for (st = 0; st <= nstaff; st++) {
			p_staff = staff_tb[st]

			// ledger lines
			// index = line number
			// values = [x symbol, x start, x stop]
			p_staff.hlu = []	// above the staff
			p_staff.hld = []	// under the staff

			l = p_staff.stafflines.length;
			p_staff.topbar = 6 * (l - 1)

			for (i = 0; i < l - 1; i++) {
				switch (p_staff.stafflines[i]) {
				case '.':
				case '-':
					continue
				}
				break
			}
			p_staff.botbar = i * 6
			if (i >= l - 2) {		// 0, 1 or 2 lines
				if (p_staff.stafflines[i] != '.') {
					p_staff.botbar -= 6;
					p_staff.topbar += 6
				} else {		// no line: big bar
					p_staff.botbar -= 12;
					p_staff.topbar += 12
					continue	// no helper line
				}
			}
			if (!non_empty_gl[st])
				continue
		}
	} // set_top_bot()

	// remove the staff system at start of line
	if (tsfirst.type == C.STAVES) {
		s = tsfirst
		tsfirst = tsfirst.ts_next
		tsfirst.ts_prev = null
		if (s.seqst)
			tsfirst.seqst = true
		s.p_v.sym = s.next
		if (s.next)
			 s.next.prev = null
	}

	/* reset the staves */
	nstaff = sy.nstaff
	for (st = 0; st <= nstaff; st++)
		reset_staff(st);
	non_empty = new Uint8Array(nstaff + 1)

	/*
	 * search the next end of line,
	 * and mark the empty staves
	 */
	for (s = tsfirst; s; s = s.ts_next) {
		if (s.nl)
			break
		switch (s.type) {
		case C.STAVES:
			set_brace();
			sy.st_print = non_empty
			sy = s.sy;
			while (nstaff < sy.nstaff)
				reset_staff(++nstaff)
			non_empty = new Uint8Array(nstaff + 1)
			continue

		// the block symbols will be treated after music line generation
		case C.BLOCK:
			if (!s.play) {
				blocks.push(s)
				unlksym(s)
			} else if (s.ts_next && s.ts_next.shrink)
				s.ts_next.shrink = 0
			continue
		}
		st = s.st
		if (st > nstaff) {
			switch (s.type) {
			case C.CLEF:
				staff_tb[st].clef = s	// clef warning/change for new staff
				break
			case C.KEY:
				s.p_v.ckey = s
				break
//useless ?
			case C.METER:
				s.p_v.meter = s
				break
			}
			unlksym(s)
			continue
		}
		if (non_empty[st])
			continue
		switch (s.type) {
		default:
			continue
		case C.BAR:
			if (s.bar_mrep
			 || sy.staves[st].staffnonote > 1)
				break
			continue
		case C.GRACE:
			break
		case C.NOTE:
		case C.REST:
		case C.SPACE:
		case C.MREST:
			if (sy.staves[st].staffnonote > 1)
				break
			if (s.invis)
				continue
			if (sy.staves[st].staffnonote
			 || s.type == C.NOTE)
				break
			continue
		}
		non_empty_gl[st] = non_empty[st] = true
	}
	tsnext = s;

	/* set the last empty staves */
	set_brace()
	sy.st_print = non_empty

	/* define the offsets of the measure bars */
	set_top_bot()

	// if not the end of the tune, set the end of the music line
	if (tsnext) {
		s = tsnext;
		delete s.nl;
		last = s.ts_prev;
		last.ts_next = null;

		// and the end of the voices
		nv = voice_tb.length
		for (v = 0; v < nv; v++) {
			p_voice = voice_tb[v]
			if (p_voice.sym
			 && p_voice.sym.time <= tsnext.time) {
				for (s = last; s; s = s.ts_prev) {
					if (s.v == v) {
						p_voice.s_next = s.next;
						s.next = null;
						break
					}
				}
				if (s)
					continue
			}
			p_voice.s_next = p_voice.sym;
			p_voice.sym = null
		}
	}

	// initialize the music line
	init_music_line()

	// keep the array of the staves to be printed
	gene.st_print = non_empty_gl
}

/* -- position the symbols along the staff -- */
// (possible hook)
Abc.prototype.set_sym_glue = function(width) {
    var	g, x, some_grace, stretch,
	cnt = 4,
	xmin = 0,		// sigma shrink = minimum spacing
	xx = 0,			// sigma natural spacing
	xs = 0,			// sigma unexpandable elements with no space
	xse = 0,		// sigma unexpandable elements with space
	ll = !tsnext ||		// last line? yes
		(tsnext.type == C.BLOCK	// no, but followed by %%command
		 && !tsnext.play)
		|| blocks.length,	//	(abcm2ps compatibility)
	s = tsfirst,
	spf = 1,		// spacing factor
	xx0 = 0

	/* calculate the whole space of the symbols */
	for ( ; s; s = s.ts_next) {
		if (s.type == C.GRACE && !some_grace)
			some_grace = s
		if (s.seqst) {
			xmin += s.shrink
			if (xmin > width) {
			    if (cfmt.singleline)
				width = xmin
			    else
				error(1, s, "Line too much shrunk $1 $2 $3",
					xmin.toFixed(1),
					xx.toFixed(1),
					width.toFixed(1))
//				break
			}
			if (s.space) {
				if (s.space < s.shrink) {
					xse += s.shrink;
					xx += s.shrink
				} else {
//					xx += s.space * spf + s.shrink * (1 - spf)
					xx += s.space
					xx0 += s.shrink
				}
			} else {
				xs += s.shrink
			}
		}
	}

	// can occur when bar alone in a staff system
	if (!xx) {
		realwidth = 0
		return
	}

	// stretch or not?
	s = tsfirst

	if (ll) {
		if ((xx - xx0 + xs) / width > (1 - s.fmt.stretchlast))
			stretch = 1 //true
	} else if (s.fmt.stretchstaff) {
		stretch = 1 //true
	}

	// strong shrink
	if (xmin >= width) {
		x = 0
		for ( ; s; s = s.ts_next) {
			if (s.seqst)
				x += s.shrink;
			s.x = x
		}
//		realwidth = width
		spf_last = .65
	} else {
		if (stretch) {
			if (xx == xse)			// if no space
				xx += 10
			spf = (width - xs - xse) / (xx - xse)
		} else {
			spf = spf_last
			if (ll && spf < s.fmt.stretchlast)
				spf = s.fmt.stretchlast
			else if (!ll)
				spf = 1 - cfmt.maxshrink * .75
			if (spf > (width - xs) / xx)
				spf = (width - xs) / xx
		}
		while (--cnt >= 0) {
			xx = 0;
			xse = 0;
			x = 0
			for (s = tsfirst; s; s = s.ts_next) {
				if (s.seqst) {
					if (s.space) {
						if (s.space * spf <= s.shrink) {
							xse += s.shrink;
							xx += s.shrink;
							x += s.shrink
						} else {
							xx += s.space;
							x += s.space * spf
						}
					} else {
						x += s.shrink
					}
				}
				s.x = x
			}
			if (!stretch && x < width)
				break
			if (Math.abs(x - width) < 0.1)
				break
			if (xx == xse)			// if no space
				xx += 10
			spf = (width - xs - xse) / (xx - xse)
		}
		spf_last = spf
	}
	realwidth = x

	/* set the x offsets of the grace notes */
	for (s = some_grace; s; s = s.ts_next) {
		if (s.type != C.GRACE)
			continue
		if (s.gr_shift)
			x = s.prev.x + s.prev.wr
		else
			x = s.x - s.wl
		for (g = s.extra; g; g = g.next)
			g.x += x
	}
}

// set the starting symbols of the voices for the new music line
function set_sym_line() {
    var	p_v, s,
	v = voice_tb.length

	// set the first symbol of each voice
	while (--v >= 0) {
		p_v = voice_tb[v]
		if (p_v.sym && p_v.s_prev) {
			p_v.sym.prev = p_v.s_prev
			p_v.s_prev.next = p_v.sym
		}
		s = p_v.s_next			// (set in set_piece)
		p_v.s_next = null
		p_v.sym = s
		if (s) {
			if (s.prev)
				s.prev.next = s
			p_v.s_prev = s.prev	// (save for play)
			s.prev = null
		} else {
			p_v.s_prev = null
		}
	}
}

// set the left offset the images
function set_posx() {
	posx = img.lm / cfmt.scale
}

// initialize the start of generation / new music line
// and output the inter-staff blocks if any
function gen_init() {
	var	s = tsfirst,
		tim = s.time

	for ( ; s; s = s.ts_next) {
		if (s.time != tim) {
			set_page()
			return
		}
		switch (s.type) {
		case C.NOTE:
		case C.REST:
		case C.MREST:
		case C.SPACE:
			set_page()
			return
		default:
			continue
		case C.STAVES:
			cur_sy = s.sy
//			break
			continue
		case C.BLOCK:
			if (s.play)
				continue	// keep for play
			self.block_gen(s)
			break
		}
		unlksym(s)
		if (s.p_v.s_next == s)
			s.p_v.s_next = s.next
	}
	tsfirst = null			/* no more notes */
}

/* -- generate the music -- */
// (possible hook)
Abc.prototype.output_music = function() {
    var v, lwidth, indent, lsh, line_height, ts1st, tslast, p_v, meter1,
	nv = voice_tb.length

	set_global()
	if (nv > 1)			// if many voices
		self.set_stem_dir()	// set the stems direction in 'multi'

	for (v = 0; v < nv; v++)
		set_beams(voice_tb[v].sym);	/* decide on beams */

	self.set_stems()		// set the stem lengths

	set_acc_shft()			// set the horizontal offset of accidentals
	if (nv > 1) {			// if many voices
		set_rest_offset();	/* set the vertical offset of rests */
		set_overlap();		/* shift the notes on voice overlap */
	}
	set_allsymwidth(1)		// set the width of all symbols

	// output the blocks and define the page layout
	gen_init()
	if (!tsfirst)
		return

	lsh = get_lshift()

	/* if single line, adjust the page width */
	if (cfmt.singleline) {
		v = get_ck_width();
		lwidth = lsh[0] + v[0] + v[1] + get_width(tsfirst, null)[0]
		v = cfmt.singleline == 2	// if as wide as the page width
			? get_lwidth() : lwidth
		if (v > lwidth)
			lwidth = v
		else
			img.width = lwidth * cfmt.scale + img.lm + img.rm + 2
	} else {

	/* else, split the tune into music lines */
		lwidth = get_lwidth();
		cut_tune(lwidth, lsh)
	}

	// save symbol pointers for play
	ts1st = tsfirst
	v = nv
	while (--v >= 0)
		voice_tb[v].osym = voice_tb[v].sym
	meter1 = ts1st.p_v.meter

	spf_last = .65				// last spacing factor
	while (1) {				/* loop per music line */
		set_piece();
		indent = set_indent(lsh)
		if (!line_height
		 && cfmt.indent
		 && indent < cfmt.indent)
		 	indent = cfmt.indent
		self.set_sym_glue(lwidth - indent)
		if (realwidth) {
			if (img.wx < realwidth)
				img.wx = realwidth
			if (indent) {
				img.wx += indent
				posx += indent
			}
			draw_sym_near();		// delayed output
			line_height = set_staff();
		    if (line_height) {			// if some music
			draw_systems(indent);
			draw_all_sym();
			delayed_update();
				vskip(line_height)
		    }
			if (indent)
				posx -= indent;
		}

		blk_flush()
		while (blocks.length)
			self.block_gen(blocks.shift())
		if (tslast)
			tslast.ts_next.ts_prev = tslast
		if (!tsnext)
			break
		tsnext.ts_prev.ts_next =		// (restore for play)
			tsfirst = tsnext

		// next line
		gen_init()
		if (!tsfirst)
			break
		tslast = tsfirst.ts_prev
		tsfirst.ts_prev = null;
		set_sym_line();
		lwidth = get_lwidth()	// the image size may have changed
	}

	// restore for play
//--fixme: no, good links, but playback crashes!!!
//	tsfirst = ts1st.ts_next				// skip staves
	tsfirst = ts1st
	v = nv
	while (--v >= 0) {
		p_v = voice_tb[v]
		if (p_v.sym && p_v.s_prev)
			p_v.sym.prev = p_v.s_prev
		p_v.sym = p_v.osym
	}
	ts1st.p_v.meter = meter1
}
// abc2svg - parse.js - ABC parse
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

var	a_gch,		// array of parsed guitar chords
	a_dcn = [],	// array of parsed decoration names
	multicol,	// multi column object
	maps = {}	// maps object - see set_map()
var	qplet_tb = new Int8Array([ 0, 1, 3, 2, 3, 0, 2, 0, 3, 0 ]),
	ntb = "CDEFGABcdefgab"

// set the source references of a symbol
function set_ref(s) {
	s.fname = parse.fname;
	s.istart = parse.istart;
	s.iend = parse.iend
}

// -- %% pseudo-comment

// clef definition (%%clef, K: and V:)
function new_clef(clef_def) {
	var	s = {
			type: C.CLEF,
			clef_line: 2,
			clef_type: "t",
			v: curvoice.v,
			p_v: curvoice,
			time: curvoice.time,
			dur: 0,
			clef_small : 1 //true
		},
		i = 1

	set_ref(s)

	switch (clef_def[0]) {
	case '"':
		i = clef_def.indexOf('"', 1);
		s.clef_name = clef_def.slice(1, i);
		i++
		break
	case 'a':
		if (clef_def[1] == 'u') {	// auto
			s.clef_type = "a";
			s.clef_auto = true;
			i = 4
			break
		}
		i = 4				// alto
	case 'C':
		s.clef_type = "c";
		s.clef_line = 3
		break
	case 'b':				// bass
		i = 4
	case 'F':
		s.clef_type = "b";
		s.clef_line = 4
		break
	case 'n':				// none
		i = 4
		s.invis = true
		s.clef_none = 1 //true
		break
	case 't':
		if (clef_def[1] == 'e') {	// tenor
			s.clef_type = "c";
			s.clef_line = 4
			break
		}
		i = 6
	case 'G':
//		s.clef_type = "t"		// treble
		break
	case 'p':
		i = 4
	case 'P':				// perc
		s.clef_type = "p";
		s.clef_line = 3;
		break
	default:
		syntax(1, "Unknown clef '$1'", clef_def)
		return //undefined
	}
	if (clef_def[i] >= '1' && clef_def[i] <= '9') {
		s.clef_line = +clef_def[i]
		i++
	}

	// handle the octave (+/-8 - ^/_8)
	delete curvoice.snd_oct
	if (clef_def[i + 1] != '8'
	 && clef_def[i + 1] != '1')
		return s
	switch (clef_def[i]) {			// octave
	case '^':
		s.clef_oct_transp = true
	case '+':
		s.clef_octave = clef_def[i + 1] == '8' ? 7 : 14
		if (!s.clef_oct_transp)		// MIDI higher octave
			curvoice.snd_oct = clef_def[i + 1] == 8 ? 12 : 24
		break
	case '_':
		s.clef_oct_transp = true
	case '-':
		s.clef_octave = clef_def[i + 1] == '8' ? -7 : -14
		if (!s.clef_oct_transp)		// MIDI lower octave
			curvoice.snd_oct = clef_def[i + 1] == 8 ? -12 : -24
		break
	}
	return s
}

// convert an interval to a base-40 interval
function get_interval(param, score) {
    var	i, val, tmp, note, pit

	tmp = new scanBuf;
	tmp.buffer = param
	pit = []
	for (i = 0; i < 2; i++) {
		note = tmp.buffer[tmp.index] ? parse_acc_pit(tmp) : null
		if (!note) {
			if (i != 1 || !score) {
				syntax(1, errs.bad_transp)
				return
			}
			pit[i] = 242			// 'c' (C5)
		} else {
			if (typeof note.acc == "object") {
				syntax(1, errs.bad_transp)
				return
			}
			pit[i] = abc2svg.pab40(note.pit, note.acc)
		}
	}
	return pit[1] - pit[0]
}

// transpose a note for the score
// Return the transposed real accidental
function nt_trans(nt,
		  a) {			// real accidental
    var	ak, an, d, b40, n

	if (typeof a == "object") {		// if microtonal accidental
		n = a[0]			// numerator
		d = a[1]			// denominator
		a = n > 0 ? 1 : -1		// base accidental for transpose
	}

	b40 = abc2svg.pab40(nt.pit, a)
		+ curvoice.tr_sco		// base-40 transposition

	nt.pit = abc2svg.b40p(b40)		// new pitch
	an = abc2svg.b40a(b40)			// new accidental

	if (!d) {				// if not a microtonal accidental
		if (an == -3)			// if triple sharp/flat
			return an
		if (a && !an)
			an = 3			// needed for %%map
		a = an
		if (!nt.acc			// if no old accidental
		 && !curvoice.ckey.k_none)	// and normal key
			a = 0			// no accidental
		nt.acc = a
		return an
	}

	// set the microtonal accidental after transposition
	switch (an) {
	case -2:
		if (n > 0)
			n -= d * 2
		else
			n -= d
		break
	case -1:
		if (n > 0)
			n -= d
		break
	case 0:
	case 3:
		if (n > 0)
			n -= d
		else
			n += d
		break
	case 1:
		if (n < 0)
			n += d
		break
	case 2:
		if (n < 0)
			n += d * 2
		else
			n += d
		break
	}
	nt.acc = [n, d]
	return an
} // nt_trans()

// set the linebreak character
function set_linebreak(param) {
	var i, item

	for (i = 0; i < 128; i++) {
		if (char_tb[i] == "\n")
			char_tb[i] = nil	// remove old definition
	}
	param = param.split(/\s+/)
	for (i = 0; i < param.length; i++) {
		item = param[i]
		switch (item) {
		case '!':
		case '$':
		case '*':
		case ';':
		case '?':
		case '@':
			break
		case "<none>":
			continue
		case "<EOL>":
			item = '\n'
			break
		default:
			syntax(1, "Bad value '$1' in %%linebreak - ignored",
					item)
			continue
		}
		char_tb[item.charCodeAt(0)] = '\n'
	}
}

// set a new user character (U: or %%user)
function set_user(parm) {
    var	k, c, v,
	a = parm.match(/(.)[=\s]*(\[I:.+\]|".+"|!.+!)$/)

	if (!a) {
		syntax(1, 'Lack of starting [, ! or " in U: / %%user')
		return
	}
	c = a[1];
	v = a[2]
	if (c[0] == '\\') {
		if (c[1] == 't')
			c = '\t'
		else if (!c[1])
			c = ' '
	}

	k = c.charCodeAt(0)
	if (k >= 128) {
		syntax(1, errs.not_ascii)
		return
	}
	switch (char_tb[k][0]) {
	case '0':			// nil
	case 'd':
	case 'i':
	case ' ':
		break
	case '"':
	case '!':
	case '[':
		if (char_tb[k].length > 1)
			break
		// fall thru
	default:
		syntax(1, "Bad user character '$1'", c)
		return
	}
	switch (v) {
	case "!beambreak!":
		v = " "
		break
	case "!ignore!":
		v = "i"
		break
	case "!nil!":
	case "!none!":
		v = "d"
		break
	}
	char_tb[k] = v
}

// get a stafflines value
function get_st_lines(param) {
	if (!param)
		return
	if (/^[\]\[|.':-]+$/.test(param))	// '
		return param.replace(/\]/g, '[')

    var	n = +param
	switch (n) {
	case 0: return "..."
	case 1: return "..|"
	case 2: return ".||"
	case 3: return ".|||"
	}
	if (isNaN(n) || n < 0 || n > 16)
		return //undefined
	return "||||||||||||||||".slice(0, n)
}

// create a block symbol in the tune body
function new_block(subtype) {
    var	s = {
			type: C.BLOCK,
			subtype: subtype,
			dur: 0
		}

	sym_link(s)
	return s
}

// set the voice parameters
// (possible hook)
Abc.prototype.set_vp = function(a) {
    var	s, item, pos, val, clefpit,
	tr_p = 0

	while (1) {
		item = a.shift()
		if (!item)
			break
		if (item.slice(-1) == '='
		 && !a.length) {
			syntax(1, errs.bad_val, item)
			break
		}
		switch (item) {
		case "clef=":
			s = a.shift()		// keep last clef
			break
		case "clefpitch=":
			item = a.shift()		// (<note><octave>)
			if (item) {
				val = ntb.indexOf(item[0])
				if (val >= 0) {
					switch (item[1]) {
					case "'":
						val += 7
						break
					case ',':
						val -= 7
						if (item[2] == ',')
							val -= 7
						break
					}
					clefpit = 4 - val	// 4 = 'G'
					break
				}
			}
			syntax(1, errs.bad_val, item)
			break
		case "octave=":
			val = +a.shift()
			if (isNaN(val))
				syntax(1, errs.bad_val, item)
			else
				curvoice.octave = val
			break
		case "cue=":
			// (ignore cue=off)
//			curvoice.scale = a.shift() == 'on' ? .7 : 1
			if (a.shift() == 'on')
				curvoice.scale = .7
			break
		case "instrument=":

			// instrument=M/N => score=MN and sound=cN
			// (instrument=M == instrument=M/M)
			item = a.shift()
			val = item.indexOf('/')
			if (val < 0) {
				val = get_interval('c' + item)
				if (val == undefined)
					break
				curvoice.sound = val
				tr_p |= 2
				val = 0
			} else {
				val = get_interval('c' + item.slice(val + 1))
				if (val == undefined)
					break
				curvoice.sound = val
				tr_p |= 2
				val = get_interval(item.replace('/', ''))
				if (val == undefined)
					break
			}
			curvoice.score = cfmt.sound ? curvoice.sound : val
			tr_p |= 1
			break
		case "map=":			// %%voicemap
			curvoice.map = a.shift()
			break
		case "name=":
		case "nm=":
			curvoice.nm = a.shift()
			if (curvoice.nm[0] == '"')
				curvoice.nm = cnv_escape(curvoice.nm.slice(1, -1))
			curvoice.new_name = true
			break
		case "stem=":			// compatibility
		case "pos=":			// from %%pos only
			if (item == "pos=")
				item = a.shift()
					.slice(1, -1)	// always inside dble quotes
					.split(' ')
			else
				item = ["stm", a.shift()];
			val = posval[item[1]]
			if (val == undefined) {
				syntax(1, errs.bad_val, "%%pos")
				break
			}
			switch (item[2]) {
			case "align": val |= C.SL_ALIGN; break
			case "center": val |= C.SL_CENTER; break
			case "close": val |= C.SL_CLOSE; break
			}
			if (!pos)
				pos = {}
			pos[item[0]] = val
			break
		case "scale=":			// %%voicescale
			val = +a.shift()
			if (isNaN(val) || val < .5 || val > 2)
				syntax(1, errs.bad_val, "%%voicescale")
			else
				curvoice.scale = val
			break
		case "score=":
			if (cfmt.nedo) {
				syntax(1, errs.notransp)
				break
			}
			// score=MN
			// (score=M == score=Mc)
			item = a.shift()
			if (cfmt.sound)
				break
			val = get_interval(item, true)
			if (val != undefined) {
				curvoice.score = val
				tr_p |= 1
			}
			break
		case "shift=":
			if (cfmt.nedo) {
				syntax(1, errs.notransp)
				break
			}
			val = get_interval(a.shift())
			if (val != undefined) {
				curvoice.shift = val
				tr_p = 3
			}
			break
		case "sound=":
			if (cfmt.nedo) {
				syntax(1, errs.notransp)
				break
			}
// concert-score display: apply sound=
// sounding-score display: apply sound= only if M != c/C
// sound: apply sound=
			val = get_interval(a.shift())
			if (val == undefined)
				break
			curvoice.sound = val
			if (cfmt.sound)
				curvoice.score = val
			tr_p |= 2
			break
		case "subname=":
		case "sname=":
		case "snm=":
			curvoice.snm = a.shift()
			if (curvoice.snm[0] == '"')
				curvoice.snm = curvoice.snm.slice(1, -1);
			break
		case "stafflines=":
			val = get_st_lines(a.shift())
			if (val == undefined) {
				syntax(1, "Bad %%stafflines value")
				break
			}
			if (curvoice.st != undefined)
				par_sy.staves[curvoice.st].stafflines = val
			curvoice.stafflines = val
			break
		case "staffnonote=":
			val = +a.shift()
			if (isNaN(val))
				syntax(1, "Bad %%staffnonote value")
			else
				curvoice.staffnonote = val
			break
		case "staffscale=":
			val = +a.shift()
			if (isNaN(val) || val < .3 || val > 2)
				syntax(1, "Bad %%staffscale value")
			else
				curvoice.staffscale = val
			break
		case "tacet=":
			val = a.shift()
			curvoice.tacet = val || undefined
			break
		case "transpose=":		// (abcMIDI compatibility)
			val = get_transp(a.shift())
			if (val == undefined) {
				syntax(1, errs.bad_transp)
			} else {
				curvoice.sound = val
				if (cfmt.sound)
					curvoice.score = val
				tr_p = 2
			}
			break
		default:
			switch (item.slice(0, 4)) {
			case "treb":
			case "bass":
			case "alto":
			case "teno":
			case "perc":
				s = item
				break
			default:
				if ("GFC".indexOf(item[0]) >= 0)
					s = item
				else if (item.slice(-1) == '=')
					a.shift()
				break
			}
			break
		}
	}
	if (pos) {
		curvoice.pos = clone(curvoice.pos)
		for (item in pos)
			if (pos.hasOwnProperty(item))
				curvoice.pos[item] = pos[item]
	}

	if (s) {
		s = new_clef(s)
		if (s) {
			if (clefpit)
				s.clefpit = clefpit
			get_clef(s)
		}
	}

	// if transposition
	if (tr_p & 2) {			// curvoice.tr_sco is set in key_trans()
		tr_p = (curvoice.sound | 0) + (curvoice.shift | 0)
		if (tr_p)
			curvoice.tr_snd = abc2svg.b40m(tr_p + 122) - 36
							// semi-tone interval
		else if (curvoice.tr_snd)
			curvoice.tr_snd = 0
		curvoice.tr_snd40 = tr_p		// (for play chords)
	}
} // set_vp()

// set the K: / V: parameters
function set_kv_parm(a) {	// array of items
	if (!curvoice.init) {	// add the global parameters if not done yet
		curvoice.init = true
		if (info.V) {
			if (info.V[curvoice.id])
				a = info.V[curvoice.id].concat(a)
			if (info.V['*'])
				a = info.V['*'].concat(a)
		}
	}
	if (a.length)
		self.set_vp(a)
} // set_kv_parm()

// memorize the K:/V: parameters
function memo_kv_parm(vid,	// voice ID (V:) / '*' (K:/V:*)
			a) {	// array of items
	if (!a.length)
		return
	if (!info.V)
		info.V = {}
	if (info.V[vid])
		Array.prototype.push.apply(info.V[vid], a)
	else
		info.V[vid] = a
}

// K: key signature
// return the key and the voice/clef parameters
function new_key(param) {
    var	i, key_end, c, tmp, note,
	sf = "FCGDAEB".indexOf(param[0]) - 1,
	mode = 0,
	s = {
		type: C.KEY,
		dur: 0
	}

	set_ref(s);

	// tonic
	i = 1
    if (sf < -1) {
	switch (param[0]) {
	case 'H':				// bagpipe
		key_end = true
		if (param[1].toLowerCase() != 'p') {
			syntax(1, "Unknown bagpipe-like key")
			break
		}
		s.k_bagpipe = param[1];
		sf = param[1] == 'P' ? 0 : 2;
		i++

		// initialize the temperament if not done yet
		if (!cfmt.temper)
	// detune in cents for just intonation in A
	// (from https://patrickmclaurin.com/wordpress/?page_id=2420)
	//  C    ^C     D    _E     E     F    ^F     G    _A     A    _B     B
	// 15.3 -14.0  -2.0 -10.0   1.9  13.3 -16.0 -31.8 -12.0   0.0  11.4   3.8
	// but 'A' bagpipe = 480Hz => raise Math.log2(480/440)*1200 = 151
			cfmt.temper = new Float32Array([
   //	1.66, 1.37, 1.49, 1.41, 1.53, 1.63, 1.35, 1.19, 1.39, 1.51, 1.62, 1.55
   //   C    ^C     D    _E     E     F    ^F     G    _A      A     _B      B
11.62, 12.55,
     1.66, 2.37, 3.49, 0,
     1.66, 2.37, 3.49, 4.41, 5.53, 0,
		 3.49, 4.41, 5.53, 6.63, 7.35,
		       4.41, 5.53, 6.63, 7.35, 8.19, 0,
				   6.63, 7.35, 8.19, 9.39, 10.51, 0,
					       8.19, 9.39, 10.51, 11.62, 12.55, 0,
							   10.51, 11.62, 12.55,
									     1.66, 1.66
			])
		break
	case 'P':
		syntax(1, "K:P is deprecated");
		sf = 0;
		s.k_drum = true;
		key_end = true
		break
	case 'n':				// none
		if (param.indexOf("none") == 0) {
			sf = 0;
			s.k_none = true;
			i = 4
			break
		}
		// fall thru
	default:
		s.k_map = []
		s.k_mode = 0
		return [s, info_split(param)]
	}
    }

	if (!key_end) {
		switch (param[i]) {
		case '#': sf += 7; i++; break
		case 'b': sf -= 7; i++; break
		}
		param = param.slice(i).trim()
		switch (param.slice(0, 3).toLowerCase()) {
		default:
			if (param[0] != 'm'
			 || (param[1] != ' ' && param[1] != '\t'
			  && param[1] != '\n')) {
				key_end = true
				break
			}
			// fall thru ('m')
		case "aeo":
		case "m":
		case "min": sf -= 3;
			mode = 5
			break
		case "dor": sf -= 2;
			mode = 1
			break
		case "ion":
		case "maj": break
		case "loc": sf -= 5;
			mode = 6
			break
		case "lyd": sf += 1;
			mode = 3
			break
		case "mix": sf -= 1;
			mode = 4
			break
		case "phr": sf -= 4;
			mode = 2
			break
		}
		if (!key_end)
			param = param.replace(/\w+\s*/, '')

		// [exp] accidentals
		if (param.indexOf("exp ") == 0) {
			param = param.replace(/\w+\s*/, '')
			if (!param)
				syntax(1, "No accidental after 'exp'");
			s.exp = 1 //true
		}
		c = param[0]
		if (c == '^' || c == '_' || c == '=') {
			s.k_a_acc = [];
			tmp = new scanBuf;
			tmp.buffer = param
			do {
				note = parse_acc_pit(tmp)
				if (!note)
					break
				s.k_a_acc.push(note);
				c = param[tmp.index]
				while (c == ' ')
					c = param[++tmp.index]
			} while (c == '^' || c == '_' || c == '=');
			param = param.slice(tmp.index)
		} else if (s.exp && param.indexOf("none") == 0) {
			sf = 0
			param = param.replace(/\w+\s*/, '')
		}
	}

	if (sf < -7 || sf > 7) {
		syntax(1, "Key with double sharps/flats")
		if (sf > 7)
			sf -= 12
		else
			sf += 12
	}
	s.k_sf = sf;

	// set the map of the notes with accidentals
	s.k_map = s.k_bagpipe && !sf
		? abc2svg.keys[9]		// implicit F# and C#
		: abc2svg.keys[sf + 7]
	if (s.k_a_acc) {
		s.k_map = Array.prototype.slice.call(s.k_map)	// simple Array
		i = s.k_a_acc.length			// (for micro-accidentals)
		while (--i >= 0) {
			note = s.k_a_acc[i]
			s.k_map[(note.pit + 19) % 7] = note.acc
		}
	}
	s.k_mode = mode

	// key note as base-40
	s.k_b40 = [1,24,7,30,13,36,19, 2 ,25,8,31,14,37,20,3][sf + 7]

	return [s, info_split(param)]
}

// M: meter
function new_meter(p) {
    var	p_v,
	s = {
			type: C.METER,
			dur: 0,
			a_meter: []
		},
		meter = {},
		val, v,
		m1 = 0, m2,
		i = 0, j,
		wmeasure,
		in_parenth;

	set_ref(s)

	if (p.indexOf("none") == 0) {
		i = 4;				/* no meter */
		wmeasure = 1;	// simplify measure numbering and C.MREST conversion
	} else {
		wmeasure = 0
		while (i < p.length) {
			if (p[i] == '=')
				break
			switch (p[i]) {
			case 'C':
				meter.top = p[i++]
				if (!m1) {
					m1 = 4;
					m2 = 4
				}
				break
			case 'c':
			case 'o':
				meter.top = p[i++]
				if (!m1) {
					if (p[i - 1] == 'c') {
						m1 = 2;
						m2 = 4	// c = 2/4
					} else {
						m1 = 3;
						m2 = 4	// o = 3/4
					}
					switch (p[i]) {
					case '|':
						m2 /= 2	// c| = 2/2, o| = 3/2
						break
					case '.':
						m1 *= 3;
						m2 *= 2	// c. = 6/8, o. = 9/8
						break
					}
				}
				break
			case '.':
			case '|':
				m1 = 0;
				meter.top = p[i++]
				break
			case '(':
				if (p[i + 1] == '(') {	/* "M:5/4 ((2+3)/4)" */
					in_parenth = true;
					meter.top = p[i++];
					s.a_meter.push(meter);
					meter = {}
				}
				j = i + 1
				while (j < p.length) {
					if (p[j] == ')' || p[j] == '/')
						break
					j++
				}
				if (p[j] == ')' && p[j + 1] == '/') {	/* "M:5/4 (2+3)/4" */
					i++		/* remove the parenthesis */
					continue
				}			/* "M:5 (2+3)" */
				/* fall thru */
			case ')':
				in_parenth = p[i] == '(';
				meter.top = p[i++];
				s.a_meter.push(meter);
				meter = {}
				continue
			default:
				if (p[i] <= '0' || p[i] > '9') {
					syntax(1, "Bad char '$1' in M:", p[i])
					return
				}
				m2 = 2;			/* default when no bottom value */
				meter.top = p[i++]
				for (;;) {
					while (p[i] >= '0' && p[i] <= '9')
						meter.top += p[i++]
					if (p[i] == ')') {
						if (p[i + 1] != '/')
							break
						i++
					}
					if (p[i] == '/') {
						i++;
						if (p[i] <= '0' || p[i] > '9') {
							syntax(1, "Bad char '$1' in M:", p[i])
							return
						}
						meter.bot = p[i++]
						while (p[i] >= '0' && p[i] <= '9')
							meter.bot += p[i++]
						break
					}
					if (p[i] != ' ' && p[i] != '+')
						break
					if (i >= p.length
					 || p[i + 1] == '(')	/* "M:5 (2/4+3/4)" */
						break
					meter.top += p[i++]
				}
				m1 = eval(meter.top.replace(/ /g, '+'))
				break
			}
			if (!in_parenth) {
				if (meter.bot)
					m2 = +meter.bot
				wmeasure += m1 * C.BLEN / m2
			}
			s.a_meter.push(meter);
			meter = {}
			while (p[i] == ' ')
				i++
			if (p[i] == '+') {
				meter.top = p[i++];
				s.a_meter.push(meter);
				meter = {}
			}
		}
	}
	if (p[i] == '=') {
		val = p.substring(++i).match(/^(\d+)\/(\d+)$/)
		if (!val) {
			syntax(1, "Bad duration '$1' in M:", p.substring(i))
			return
		}
		wmeasure = C.BLEN * val[1] / val[2]
	}
	if (!wmeasure) {
		syntax(1, errs.bad_val, 'M:')
		return
	}
	s.wmeasure = wmeasure

	if (cfmt.writefields.indexOf('M') < 0)
		s.a_meter = []

	if (parse.state != 3) {
		info.M = p;
		glovar.meter = s
		if (parse.state) {

			/* in the tune header, change the unit note length */
			if (!glovar.ulen) {
				if (wmeasure <= 1
				 || wmeasure >= C.BLEN * 3 / 4)
					glovar.ulen = C.BLEN / 8
				else
					glovar.ulen = C.BLEN / 16
			}
			for (v = 0; v < voice_tb.length; v++) {
				voice_tb[v].meter = s;
				voice_tb[v].wmeasure = wmeasure
			}
		}
	} else {
		curvoice.wmeasure = wmeasure
		if (is_voice_sig())
			curvoice.meter = s
		else
			sym_link(s)

		// set the meter of the overlay voices
		for (p_v = curvoice.voice_down; p_v; p_v = p_v.voice_down)
			p_v.wmeasure = wmeasure
	}
}

// link P: or Q:
function link_pq(s, text) {
    var	p_v, s2

	if (curvoice.v == par_sy.top_voice) {
		sym_link(s)
	} else if (voice_tb[par_sy.top_voice].time == s.time) {
		p_v = curvoice
		curvoice = voice_tb[par_sy.top_voice]
		sym_link(s)
		curvoice = p_v
	} else if (voice_tb[par_sy.top_voice].time > s.time) {
		p_v = voice_tb[par_sy.top_voice]
		for (s2 = p_v.sym; ; s2 = s2.next) {
			if (s2.time >= s.time) {
				set_ref(s)
				s.fmt = cfmt
				s.next = s2
				s.prev = s2.prev
				if (s2.prev)
					s.prev.next = s
				else
					p_v.sym = s
				s2.prev = s
				s.v = s2.v
				s.p_v = p_v
				s.st = p_v.st
				break
			}
		}
	} else {
		set_ref(s)
		s.fmt = cfmt
		if (!parse.pq_d)
			parse.pq_d = []
		parse.pq_d.push(s)		// delayed insertion
	}
	if (!parse.pq)
		parse.pq = {}
	parse.pq[text] = s.time
} // link_pq()

/* Q: tempo */
function new_tempo(text) {
    var	i, c, d, nd,
	txt = text,			// (for info.Q)
	s = {
		type: C.TEMPO,
		dur: 0
	}

	// get a note duration
	function get_nd(p) {
	    var	n, d,
		nd = p.match(/(\d+)\/(\d+)/)

		if (nd) {
			d = +nd[2]
			if (d && !isNaN(d) && !(d & (d - 1))) {
				n = +nd[1]
				if (!isNaN(n))
					return C.BLEN * n / d
			}
		}
		syntax(1, "Invalid note duration $1", c)
	} // get_nd()

	set_ref(s)

	if (cfmt.writefields.indexOf('Q') < 0)
		s.invis = true			// don't display

	/* string before */
	if (text[0] == '"') {
		c = text.match(/"([^"]*)"/)		// "
		if (!c) {
			syntax(1, "Unterminated string in Q:")
			return
		}
		s.tempo_str1 = c[1]
		text = text.slice(c[0].length).replace(/^\s+/,'')
	}

	// string after
	if (text.slice(-1) == '"') {
		i = text.indexOf('"')
		s.tempo_str2 = text.slice(i + 1, -1)
		text = text.slice(0, i).replace(/\s+$/,'')
	}

	/* beat */
	i = text.indexOf('=')
	if (i > 0) {
		d = text.slice(0, i).split(/\s+/)
		text = text.slice(i + 1).replace(/^\s+/,'')
		while (1) {
			c = d.shift()
			if (!c)
				break
			nd = get_nd(c)
			if (!nd)
				return
			if (!s.tempo_notes)
				s.tempo_notes = []
			s.tempo_notes.push(nd)
		}

		// tempo value
		if (text.slice(0, 4) == "ca. ") {
			s.tempo_ca = 'ca. '
			text = text.slice(4)
		}
		i = text.indexOf('/')
		if (i > 0) {
			nd = get_nd(text)
			if (!nd)
				return
			s.new_beat = nd
		} else {
			s.tempo = +text
			if (!s.tempo || isNaN(s.tempo)) {
				syntax(1, "Bad tempo value")
				return
			}
		}
	}

	if (parse.state < 2			// if in tune header
	 || (!curvoice.time && !glovar.tempo)) {
		info.Q = txt
		glovar.tempo = s
		return
	}

	if (!glovar.tempo)
		syntax(0, "No previous tempo")
	s.time = curvoice.time
	text = 'Q' + (s.tempo_str1 ? 'S' : '') + s.time
						// accept [Q:"text"][Q:1/4=60]
	if (parse.pq
	 && parse.pq[text] == s.time)
		return				// already seen
	link_pq(s, text)
}

// treat the information fields which may embedded
function do_info(info_type, text) {
    var	s, d1, d2, a, vid, tim, v, p_v

	// skip this line if the current voice is ignored
	// but keep the time related definitions
	if (curvoice && curvoice.ignore) {
		switch (info_type) {
		default:
			return
		case 'P':
		case 'Q':
		case 'V':
			break
		}
	}

	switch (info_type) {

	// info fields in any state
	case 'I':
		self.do_pscom(text)
		break
	case 'L':
		a = text.match(/^1\/(\d+)(=(\d+)\/(\d+))?$/)
		if (a) {
			d1 = +a[1]
			if (!d1 || (d1 & (d1 - 1)) != 0)
				break
			d1 = C.BLEN / d1
			if (a[2]) {		// if '='
				d2 = +a[4]
				d2 = d2 ? +a[3] / d2 * C.BLEN : 0
			} else {
				d2 = d1
			}
		} else if (text == "auto") {
			d1 = d2 = -1
		}
		if (!d2) {
			syntax(1, "Bad L: value")
			break
		}
		if (parse.state <= 1) {
			glovar.ulen = d1
		} else {
			curvoice.ulen = d1;
			curvoice.dur_fact = d2 / d1
		}
		break
	case 'M':
		new_meter(text)
		break
	case 'U':
		set_user(text)
		break

	// fields in tune header or tune body
	case 'P':
		if (!parse.state)
			break
		if (parse.state == 1) {
			info.P = text
			break
		}
		s = {
			type: C.PART,
			text: text,
			time: curvoice.time
		}
	    if (info.P) {
		tim = parse.pq && parse.pq[text] // time of previous P: with same text
		if (tim == s.time)
			break				// already seen
		if (tim != null) {
			syntax(1, "Misplaced P:")	// different dates
			break
		}
	    }

		if (cfmt.writefields.indexOf('P') < 0)
			s.invis = 1 //true
		link_pq(s, text)
		break
	case 'Q':
		if (!parse.state)
			break
		new_tempo(text)
		break
	case 'V':
		get_voice(text)
		if (parse.state == 3)
			curvoice.ignore = !par_sy.voices[curvoice.v]
		break

	// key signature at end of tune header or in tune body
	case 'K':
		if (!parse.state)	// ignore if in file header
			break
		get_key(text)
		break

	// info in any state
	case 'N':
	case 'R':
		if (!info[info_type])
			info[info_type] = text
		else
			info[info_type] += '\n' + text
		break
	case 'r':
		if (!user.keep_remark
		 || parse.state != 3)
			break
		s = {
			type: C.REMARK,
			text: text,
			dur: 0
		}
		sym_link(s)
		break
	default:
		syntax(0, "'$1:' line ignored", info_type)
		break
	}
}

// music line parsing functions

/* -- adjust the duration and time of symbols in a measure when L:auto -- */
function adjust_dur(s) {
    var	s2, time, auto_time, i, fac;

	/* search the start of the measure */
	s2 = curvoice.last_sym
	if (!s2)
		return;

	/* the bar time is correct if there are multi-rests */
	if (s2.type == C.MREST
	 || s2.type == C.BAR)			/* in second voice */
		return
	while (s2.type != C.BAR && s2.prev)
		s2 = s2.prev;
	time = s2.time;
	auto_time = curvoice.time - time
	fac = curvoice.wmeasure / auto_time

	if (fac == 1)
		return				/* already good duration */

	for ( ; s2; s2 = s2.next) {
		s2.time = time
		if (!s2.dur || s2.grace)
			continue
		s2.dur *= fac;
		s2.dur_orig *= fac;
		time += s2.dur
		if (s2.type != C.NOTE && s2.type != C.REST)
			continue
		for (i = 0; i <= s2.nhd; i++)
			s2.notes[i].dur *= fac
	}
	curvoice.time = s.time = time
}

/* -- parse a bar -- */
function new_bar() {
	var	s2, c, bar_type,
		line = parse.line,
		s = {
			type: C.BAR,
			fname: parse.fname,
			istart: parse.bol + line.index,
			dur: 0,
			multi: 0		// needed for decorations
		}

	if (vover && vover.bar)			// end of voice overlay
		get_vover('|')
	if (glovar.new_nbar) {			// %%setbarnb
		s.bar_num = glovar.new_nbar;
		glovar.new_nbar = 0
	}
	bar_type = line.char()
	while (1) {
		c = line.next_char()
		switch (c) {
		case '|':
		case '[':
		case ']':
		case ':':
			bar_type += c
			continue
		}
		break
	}
	if (bar_type[0] == ':') {
		if (bar_type == ':') {		// ":" alone
			bar_type = '|';
			s.bar_dotted = true
		} else {
			s.rbstop = 2		// right repeat with end
		}
	}

	// set the annotations and the decorations
	if (a_gch)
		csan_add(s)
	if (a_dcn.length)
		deco_cnv(s)

	/* if the last element is '[', it may start
	 * a chord or an embedded header */
	if (bar_type.slice(-1) == '['
	 && !(/[0-9" ]/.test(c))) {		// "
		bar_type = bar_type.slice(0, -1);
		line.index--;
		c = '['
	}

	// check if a repeat variant
	if (c > '0' && c <= '9') {
		s.text = c
		while (1) {
			c = line.next_char()
			if ("0123456789,.-".indexOf(c) < 0)
				break
			s.text += c
		}
	} else if (c == '"' && bar_type.slice(-1) == '[') {
		s.text = ""
		while (1) {
			c = line.next_char()
			if (!c) {
				syntax(1, "No end of repeat string")
				return
			}
			if (c == '"') {
				line.index++
				break
			}
			s.text += c
		}
	}

	// ']' as the first character indicates a repeat bar stop
	if (bar_type[0] == ']') {
		s.rbstop = 2			// with end
		if (bar_type.length != 1)
			bar_type = bar_type.slice(1)
		else
			s.invis = true
	}

	s.iend = parse.bol + line.index

	if (s.text
	 && bar_type.slice(-1) == '['
	 && bar_type != '[')
		bar_type = bar_type.slice(0, -1)

	// there cannot be variants on a left repeat bar
	if (bar_type.slice(-1) == ':') {	// left repeat
		s.rbstop = 1			// end the bracket
		if (s.text) {
			syntax(1, "Variant ending on a left repeat bar")
			delete s.text
		}
		curvoice.tie_s_rep = null	// no tie anymore on new variant
	}

	// handle the accidentals (ties and repeat)
	if (s.text) {
		s.rbstart = s.rbstop = 2
		if (s.text[0] == '1') {
			curvoice.tie_s_rep = curvoice.tie_s
			if (curvoice.acc_tie)
				curvoice.acc_tie_rep = curvoice.acc_tie.slice()
			else if (curvoice.acc_tie_rep)
				curvoice.acc_tie_rep = null
		} else {
			curvoice.tie_s = curvoice.tie_s_rep
			if (curvoice.acc_tie_rep)
				curvoice.acc_tie = curvoice.acc_tie_rep.slice()
		}
		if (curvoice.norepbra
		 && !curvoice.second)
			s.norepbra = 1 //true
	}

	if (curvoice.ulen < 0)			// L:auto
		adjust_dur(s);

	// merge ":| |:" into "::" and other cases
	if ((bar_type == "[" || bar_type == "|:")
	 && !curvoice.eoln
	 && !s.a_gch && !s.invis) {		// no annotation nor invisible
		s2 = curvoice.last_sym

		// if the previous symbol is also a bar
		if (s2 && s2.type == C.BAR) {
//		&& !s2.a_gch && !s2.a_dd
//		&& !s.a_gch && !s.a_dd) {

				// remove the invisible variant bars
				// when no shift is needed
				if ((bar_type == "["
				  && !s2.text)
				 || s.norepbra) {
					if (s.text) {
						s2.text = s.text
						if (curvoice.st && !s.norepbra
						 && !(par_sy.staves[curvoice.st - 1]
								.flags & STOP_BAR))
							s2.xsh = 4	// volta shift
					}
//					if (s.a_gch)
//						s2.a_gch = s.a_gch
					if (s.norepbra)
						s2.norepbra = 1 //true
					if (s.rbstart)
						s2.rbstart = s.rbstart
					if (s.rbstop)
						s2.rbstop = s.rbstop
//--fixme: pb when on next line and empty staff above
					return
				}

				// merge back-to-back repeat bars
				if (bar_type == "|:") {
					switch (s2.bar_type) {
					case ":|":		// :| + |: => ::
						s2.bar_type = "::";
						s2.rbstop = 2
						return
					}
				}
		}
	}

	/* set some flags */
	switch (bar_type) {
	case "[":
	case "[]":
	case "[|]":
		s.invis = true;
		bar_type = s.rbstart ? "[" : "[]"
		break
	case ":|:":
	case ":||:":
		bar_type = "::"
		break
	case "||":
		if (cfmt["abc-version"] >= "2.2")
			break
		// fall thru - play repeat on double bar when old ABC version
	case "[|":
	case "|]":
		s.rbstop = 2
		break
	}
	s.bar_type = bar_type
	if (!curvoice.lyric_restart)
		curvoice.lyric_restart = s
	if (!curvoice.sym_restart)
		curvoice.sym_restart = s

	sym_link(s);

	s.st = curvoice.st			/* original staff */

	// possibly shift the volta bracket if not on the first staff
	if (s.text && s.st > 0 && !s.norepbra
	 && !(par_sy.staves[s.st - 1].flags & STOP_BAR)
	 && bar_type != '[')
		s.xsh = 4			// volta shift

	if (!s.bar_dotted && !s.invis)
		curvoice.acc = []		// no accidental anymore
}

// parse %%staves / %%score
// return an array of [vid, flags] / null
function parse_staves(p) {
    var	v, vid,
	vids = {},
		a_vf = [],
		err = false,
		flags = 0,
		brace = 0,
		bracket = 0,
		parenth = 0,
		flags_st = 0,
	e,
	a = p.match(/[^[\]|{}()*+\s]+|[^\s]/g)

	if (!a) {
		syntax(1, errs.bad_val, "%%score")
		return // null
	}
	while (1) {
		e = a.shift()
		if (!e)
			break
		switch (e) {
		case '[':
			if (parenth || brace + bracket >= 2) {
				syntax(1, errs.misplaced, '[');
				err = true
				break
			}
			flags |= brace + bracket == 0 ? OPEN_BRACKET : OPEN_BRACKET2;
			bracket++;
			flags_st <<= 8;
			flags_st |= OPEN_BRACKET
			break
		case '{':
			if (parenth || brace || bracket >= 2) {
				syntax(1, errs.misplaced, '{');
				err = true
				break
			}
			flags |= !bracket ? OPEN_BRACE : OPEN_BRACE2;
			brace++;
			flags_st <<= 8;
			flags_st |= OPEN_BRACE
			break
		case '(':
			if (parenth) {
				syntax(1, errs.misplaced, '(');
				err = true
				break
			}
			flags |= OPEN_PARENTH;
			parenth++;
			flags_st <<= 8;
			flags_st |= OPEN_PARENTH
			break
		case '*':
			if (brace && !parenth && !(flags & (OPEN_BRACE | OPEN_BRACE2)))
				flags |= FL_VOICE
			break
		case '+':
			flags |= MASTER_VOICE
			break
		case ']':
		case '}':
		case ')':
			syntax(1, "Bad voice ID in %%score");
			err = true
			break
		default:	// get / create the voice in the voice table
			vid = e
			while (1) {
				e = a.shift()
				if (!e)
					break
				switch (e) {
				case ']':
					if (!(flags_st & OPEN_BRACKET)) {
						syntax(1, errs.misplaced, ']');
						err = true
						break
					}
					bracket--;
					flags |= brace + bracket == 0 ?
							CLOSE_BRACKET :
							CLOSE_BRACKET2;
					flags_st >>= 8
					continue
				case '}':
					if (!(flags_st & OPEN_BRACE)) {
						syntax(1, errs.misplaced, '}');
						err = true
						break
					}
					brace--;
					flags |= !bracket ?
							CLOSE_BRACE :
							CLOSE_BRACE2;
					flags &= ~FL_VOICE;
					flags_st >>= 8
					continue
				case ')':
					if (!(flags_st & OPEN_PARENTH)) {
						syntax(1, errs.misplaced, ')');
						err = true
						break
					}
					parenth--;
					flags |= CLOSE_PARENTH;
					flags_st >>= 8
					continue
				case '|':
					flags |= STOP_BAR
					continue
				}
				break
			}
			if (vids[vid]) {
				syntax(1, "Double voice in %%score")
				err = true
			} else {
				vids[vid] = true
				a_vf.push([vid, flags])
			}
			flags = 0
			if (!e)
				break
			a.unshift(e)
			break
		}
	}
	if (flags_st != 0) {
		syntax(1, "'}', ')' or ']' missing in %%score");
		err = true
	}
	if (err || !a_vf.length)
		return //null
	return a_vf
}

// split an info string
function info_split(text) {
	if (!text)
		return []
    var	a = text.match(/[^\s"=]+=?|"[^"]*"/g)	// "
	if (!a) {
//fixme: bad error text
		syntax(1, "Unterminated string")
		return []
	}
	return a
}

// parse a duration and return [numerator, denominator]
// 'line' is not always 'parse.line'
var reg_dur = /(\d*)(\/*)(\d*)/g		/* (stop comment) */

function parse_dur(line) {
	var res, num, den;

	reg_dur.lastIndex = line.index;
	res = reg_dur.exec(line.buffer)
	if (!res[0])
		return [1, 1];
	num = res[1] || 1;
	den = res[3] || 1
	if (!res[3])
		den *= 1 << res[2].length;
	line.index = reg_dur.lastIndex
	return [+num, +den]
}

// parse the note accidental and pitch
function parse_acc_pit(line) {
    var	note, acc, pit, d, nd,
	c = line.char()

	// optional accidental
	switch (c) {
	case '^':
		c = line.next_char()
		if (c == '^') {
			acc = 2;
			c = line.next_char()
		} else {
			acc = 1
		}
		break
	case '=':
		acc = 3;
		c = line.next_char()
		break
	case '_':
		c = line.next_char()
		if (c == '_') {
			acc = -2;
			c = line.next_char()
		} else {
			acc = -1
		}
		break
	}

	/* look for microtone value */
	if (acc == 1 || acc == -1) {
	    if ((c >= '1' && c <= '9')
	     || c == '/') {			// shortcut
		nd = parse_dur(line);
		if (acc < 0)
			nd[0] = -nd[0]
		if (cfmt.nedo && nd[1] == 1) {
			nd[0] *= 12
			nd[1] *= cfmt.nedo
		}
		acc = nd
		c = line.char()
	    }
	}

	/* get the pitch */
	pit = ntb.indexOf(c) + 16;
	c = line.next_char()
	if (pit < 16) {
		syntax(1, "'$1' is not a note", line.buffer[line.index - 1])
		return //undefined
	}

	// octave
	while (c == "'") {
		pit += 7;
		c = line.next_char()
	}
	while (c == ',') {
		pit -= 7;
		c = line.next_char()
	}
	note = {
		pit: pit,
		shhd: 0,
		shac: 0
	}
	if (acc)
		note.acc = acc
	return note
}

// return the mapping of a note
//
// The global 'maps' object is indexed by the map name.
// Its content is an object ('map') indexed from the map type:
// - normal = ABC note
// - octave = 'o' + ABC note in C..B interval
// - key    = 'k' + scale index
// - tonic  = 't' + mode index
// - any    = '*'
// The 'map' is stored in the note. It is an array of
//	[0] array of heads (glyph names)
//	[1] print (note)
//	[2] color
//	[3] play (note)
function set_map(p_v, note, acc,
		trp_p) {			// flag "do transpose?"
    var	nn = not2abc(note.pit, acc),
	map = maps[p_v.map]

	if (!map)
		return

	// test if 'nn' is in the map
	function map_p() {
		if (map[nn])
			return 1 //true
	    var	sf, d

		nn = 'o' + nn.replace(/[',]+/, '')	// '
		if (map[nn])
			return 1 //true
//fixme: useless
		d = abc2svg.keys[p_v.ckey.k_sf + 7][(note.pit + 75) % 7]
		d = (!d && acc == 3) ? 0 : acc
		nn = 'k' + ['__','_','','^','^^','='][d + 2]	// key chromatic
			+ ntb[(note.pit + 75 - p_v.ckey.k_sf * 11) % 7]
		if (map[nn])
			return 1 //true
		nn = nn.replace(/[_=^]/g,'')		// key diatonic
		if (map[nn])
			return 1 //true
		sf = p_v.ckey.k_sf + [0, 2, 4, -1, 1, 3, -2][p_v.ckey.k_mode]
		if (sf < -7)
			sf += 7
		else if (sf > 7)
			sf -= 7
		d = abc2svg.keys[sf + 7]
				[(note.pit + 75) % 7]
		if (d && acc == 3)
			d = -d
		else if (!d && !acc)
			d = 3
		else
			d = acc - d
		nn = 't' + ['__','_','=','^','^^','']	// tonic chromatic
				[d + 2]
			+ ntb[(note.pit + 75 - p_v.ckey.k_mode
				 - p_v.ckey.k_sf * 11) % 7]
		if (map[nn])
			return 1 //true
		nn = nn.replace(/[_=^]/g,'')		// tonic diatonic
		if (map[nn])
			return 1 //true
		nn = '*'				// any note
		return map[nn]
	} // map_p()

	if (!map_p())					// note in the map?
		return					// no
	map = map[nn]

	if (trp_p) {
		if (map[1] && map[1].notrp)
			note.notrp = 1 //true	// no transpose
		return
	}

	if (map[1]				// if note transpose
	 && !note.map) {			// for the first time
			note.pit = map[1].pit
			note.acc = map[1].acc
			if (map[1].notrp) {
				note.notrp = 1 //true	// no transpose
				note.noplay = 1 //true	// no play
			}
	}
	note.map = map

	if (map[2])				// if color
		note.color = map[2]
	nn = map[3]
	if (nn)					// if play map
		note.midi = pit2mid(nn.pit + 19, nn.acc)
}

/* -- parse note or rest with pitch and length -- */
// 'line' is not always 'parse.line'
function parse_basic_note(line, ulen) {
	var	nd,
		note = parse_acc_pit(line)

	if (!note)
		return //null

	// duration
	if (line.char() == '0') {		// compatibility
		parse.stemless = true;
		line.index++
	}
	nd = parse_dur(line);
	note.dur = ulen * nd[0] / nd[1]
	return note
}

function parse_vpos() {
	var	line = parse.line,
		ty = 0

	if (a_dcn.length && a_dcn[a_dcn.length - 1] == "dot") {
		ty = C.SL_DOTTED
		a_dcn.pop()
	}
	switch (line.next_char()) {
	case "'":
		line.index++
		return ty + C.SL_ABOVE
	case ",":
		line.index++
		return ty + C.SL_BELOW
	case '?':				// slur between staves (like ~)
		line.index++
		return ty + C.SL_CENTER
	}
	return ty + C.SL_AUTO
}

// on end of slur, create the slur
function slur_add(s, nt) {		// nt = note if slur ending on note
    var	i, s2, sl

	// go back and find the last start of slur
	for (i = curvoice.sls.length; --i >= 0; ) {
		sl = curvoice.sls[i]

		// the slur must not start and stop on a same symbol
		if (sl.ss == s)
			continue
		curvoice.sls.splice(i, 1)
		sl.se = s			// ending symbol
		if (nt)
			sl.nte = nt
		s2 = sl.ss			// start of slur
		if (!s2.sls)
			s2.sls = []
		s2.sls.push(sl)

		// set a flag if the slur starts on a grace note
		if (sl.grace)
			sl.grace.sl1 = true
		return
	}

	// the lack of a starting slur may be due to a repeat
	for (s2 = s.prev; s2; s2 = s2.prev) {
		if (s2.type == C.BAR
		 && s2.bar_type[0] == ':'
		 && s2.text) {
			if (!s2.sls)
				s2.sls = [];
			s2.sls.push({
//fixme: should go back to the bar "|1" and find the slur type...
				ty: C.SL_AUTO,
				ss: s2,
				se: s
			})
			if (nt)
				s2.sls[s2.sls.length - 1].nte = nt
			return
		}
	}
//	syntax(1, "End of slur without start")
	if (!s.sls)
		s.sls = [];
	s.sls.push({
		ty: C.SL_AUTO,
		se: s,
		loc: 'i'			// no slur start
	})
	if (nt)
		s.sls[s.sls.length - 1].nte = nt
}

// convert a diatonic pitch and accidental to a MIDI pitch with cents
function pit2mid(pit, acc) {
    var	p = [0, 2, 4, 5, 7, 9, 11][pit % 7],	// chromatic pitch
	o = ((pit / 7) | 0) * 12,		// octave
	p0, p1, s, b40

	if (curvoice.snd_oct)
		o += curvoice.snd_oct
	if (acc == 3)				// if natural accidental
		acc = 0
	if (acc) {
		if (typeof acc == "object") {
			s = acc[0] / acc[1]	// microtonal accidental
			if (acc[1] == 100)	// in cents
				return p + o + s
		} else {
			s = acc			// simple accidental
		}
	} else {
		if (cfmt.temper)
			return cfmt.temper[abc2svg.p_b40[pit % 7]] + o
		return p + o
	}
	if (!cfmt.nedo) {			// non equal temperament
		if (!cfmt.temper) {
			p += o + s		// standard temperament
			return p
		}
	} else {				// equal temperament
		p0 = cfmt.temper[abc2svg.p_b40[pit % 7]]	// main note
		if (typeof acc != "object") {	// if not a fraction
			b40 = abc2svg.p_b40[pit % 7] + acc
			p1 = cfmt.temper[b40]
			if (s > 0) {			// sharp
				if (p1 < p0)
					p1 += 12
			} else {
				if (p1 > p0)
					p1 -= 12
			}
			return p1 + o
		}

		if (acc[1] == cfmt.nedo) {	// fraction with the edo divider
			b40 = abc2svg.p_b40[pit % 7]
			return cfmt.temper[b40] + o + s
		}
	}

	p0 = cfmt.temper[abc2svg.p_b40[pit % 7]]	// main note
	if (s > 0) {					// sharp
		p1 = cfmt.temper[(abc2svg.p_b40[pit % 7] + 1) % 40]
		if (p1 < p0)
			p1 += 12
	} else {					// flat
		p1 = cfmt.temper[(abc2svg.p_b40[pit % 7] + 39) % 40]
		if (p1 > p0)
			p1 -= 12
		s = -s
	}
	return p0 + o + (p1 - p0) * s
} // pit2mid()

// handle the ties
// @s = tie ending smbol
// @tei_s = tie starting symbol
function do_ties(s, tie_s) {
    var	i, m, not1, not2, mid, g,
	nt = 0,
	se = (tie_s.time + tie_s.dur) == curvoice.time	// 'start-end' flag

	for (m = 0; m <= s.nhd; m++) {
		not2 = s.notes[m]
		mid = not2.midi
		if (tie_s.type != C.GRACE) {
			for (i = 0; i <= tie_s.nhd; i++) {
				not1 = tie_s.notes[i]
				if (!not1.tie_ty)
					continue
				if (not1.midi == mid
				 && (!se
				  || !not1.tie_e)) {	// (if unison)
					not2.tie_s = not1
					not2.s = s
					if (se) {
						not1.tie_e = not2
						not1.s = tie_s
					}
					nt++
					break
				}
			}
		} else {
			for (g = tie_s.extra; g; g = g.next) {
				not1 = g.notes[0]	// (fixme: only one note)
				if (!not1.tie_ty)
					continue
				if (not1.midi == mid) {
					g.ti1 = true
					not2.tie_s = not1
					not2.s = s
					not1.tie_e = not2
					not1.s = g
					nt++
					break
				}
			}
		}
	}

	if (!nt)
		error(1, tie_s, "Bad tie")
	else
		s.ti2 = true
} // do_ties()

// (possible hook)
Abc.prototype.new_note = function(grace, sls) {
    var	note, s, in_chord, c, tie_s, acc_tie,
	i, n, s2, nd, res, num, apit, div, ty,
	chdur = 1,
	dpit = 0,
	sl1 = [],
	line = parse.line,
	a_dcn_sav = a_dcn		// save parsed decoration names

	a_dcn = []
	parse.stemless = false;
	s = {
		type: C.NOTE,
		fname: parse.fname,
		stem: 0,
		multi: 0,
		nhd: 0,
		xmx: 0
	}
	s.istart = parse.bol + line.index

	if (curvoice.color)
		s.color = curvoice.color

	if (grace) {
		s.grace = true
	} else {
		if (curvoice.tie_s) {	// if tie from previous note / grace note
			tie_s = curvoice.tie_s
			curvoice.tie_s = null
		}
		if (a_gch)
			csan_add(s)
		if (parse.repeat_n) {
			s.repeat_n = parse.repeat_n;
			s.repeat_k = parse.repeat_k;
			parse.repeat_n = 0
		}
	}
	c = line.char()
	switch (c) {
	case 'X':
		s.invis = true
	case 'Z':
		s.type = C.MREST;
		c = line.next_char()
		s.nmes = (c > '0' && c <= '9') ? line.get_int() : 1;
		if (curvoice.wmeasure == 1) {
			error(1, s, "multi-measure rest, but no measure!")
			return
		}
		s.dur = curvoice.wmeasure * s.nmes

		// convert 'Z'/'Z1' to a whole measure rest
		if (s.nmes == 1) {
			s.type = C.REST;
			s.dur_orig = s.dur;
			s.fmr = 1		// full measure rest
			s.notes = [{
				pit: 18,
				dur: s.dur
			}]
		} else {
			glovar.mrest_p = true
			if (par_sy.voices.length == 1) {
				s.tacet = curvoice.tacet
				delete s.invis	// show the 'H' when 'Xn'
			}
		}
		break
	case 'y':
		s.type = C.SPACE;
		s.invis = true;
		s.dur = 0;
		c = line.next_char()
		if (c >= '0' && c <= '9')
			s.width = line.get_int()
		else
			s.width = 10
		if (tie_s) {
			curvoice.tie_s = tie_s
			tie_s = null
		}
		break
	case 'x':
		s.invis = true
	case 'z':
		s.type = C.REST;
		line.index++;
		nd = parse_dur(line);
		s.dur_orig = ((curvoice.ulen < 0) ?
					C.BLEN :
					curvoice.ulen) * nd[0] / nd[1];
		if (s.dur_orig < 12) {
			error(0, s, "Bad note duration $1", s.dur_orig)
			s.dur_orig = 12
		}
		s.dur = s.dur_orig * curvoice.dur_fact;
		if (s.dur == curvoice.wmeasure)
			s.fmr = 1		// full measure rest
		s.notes = [{
			pit: 18,
			dur: s.dur_orig
		}]
		break
	case '[':			// chord
		in_chord = true;
		c = line.next_char()
		i = line.buffer.indexOf(']', line.index)
		if (i < 0) {
			syntax(1, "No end of chord")
			return
		}
		n = line.index			// save the parser index
		line.index = i + 1		// set the parser to the end of chord
		nd = parse_dur(line)
		chdur = nd[0] / nd[1]		// length factor of the chord
		in_chord = reg_dur.lastIndex	// hack: index after the chord length
		line.index = n			// restore the parser index
		// fall thru
	default:			// accidental, chord, note
		if (curvoice.acc_tie) {
			acc_tie = curvoice.acc_tie
			curvoice.acc_tie = null
		}
		s.notes = []

		// loop on the chord
		while (1) {

			// when in chord, get the slurs and decorations
			if (in_chord) {
				while (1) {
					if (!c)
						break
					i = c.charCodeAt(0);
					if (i >= 128) {
						syntax(1, errs.not_ascii)
						return //null
					}
					ty = char_tb[i]
					switch (ty[0]) {
					case '(':
						sl1.push(parse_vpos());
						c = line.char()
						continue
					case '!':
						if (ty.length > 1)
							a_dcn.push(ty.slice(1, -1))
						else
							get_deco()	// line -> a_dcn
						c = line.next_char()
						continue
					}
					break
				}
			}
			note = parse_basic_note(line,
					s.grace ? C.BLEN / 4 :
					curvoice.ulen < 0 ?
						C.BLEN :
						curvoice.ulen)
			if (!note)
				return //null

			note.dur *= chdur		// chord factor
			if (note.dur < 12) {
				error(0, s, "Bad note duration $1", note.dur)
				note.dur = 12
			}

			if (curvoice.octave)
				note.pit += curvoice.octave * 7

			// get the real accidental
			apit = note.pit + 19		// pitch from C-1
			i = note.acc
			if (!i) {
				if (cfmt["propagate-accidentals"][0] == 'p')
					i = curvoice.acc[apit % 7]
				else
					i = curvoice.acc[apit]
				if (!i)
					i = curvoice.ckey.k_map[apit % 7] || 0
			}

			if (i
			 && !curvoice.ckey.k_drum) {
				if (cfmt["propagate-accidentals"][0] == 'p')
					curvoice.acc[apit % 7] = i
				else if (cfmt["propagate-accidentals"][0] != 'n')
					curvoice.acc[apit] = i
			}

			if (acc_tie && acc_tie[apit])
				i = acc_tie[apit]	// tied note

			// set the MIDI pitch
			if (!note.midi)		// if not map play
				note.midi = pit2mid(apit, i)

			// transpose
			if (curvoice.tr_sco) {
				set_map(curvoice, note, i, 1)	// possible transpose?
			    if (!note.notrp) {			// yes
				i = nt_trans(note, i)
				if (i == -3) {		// if triple sharp/flat
					error(1, s, "triple sharp/flat")
					i = note.acc > 0 ? 1 : -1
					note.pit += i
					note.acc = i
				}
				dpit = note.pit + 19 - apit
			    }
			}
			if (curvoice.tr_snd)
				note.midi += curvoice.tr_snd
			if (curvoice.map)
				set_map(curvoice, note, i)

//fixme: does not work if transposition
			if (i) {
				switch (cfmt["writeout-accidentals"][1]) {
				case 'd':			// added
					s2 = curvoice.ckey
					if (!s2.k_a_acc)
						break
					for (n = 0; n < s2.k_a_acc.length; n++) {
						if ((s2.k_a_acc[n].pit - note.pit)
								% 7 == 0) {
							note.acc = i
							break
						}
					}
					break
				case 'l':			// all
					note.acc = i
					break
				}
			}

			// starting slurs
			if (sl1.length) {
				while (1) {
					i = sl1.shift()
					if (!i)
						break
					curvoice.sls.push({
						ty: i,
						ss: s,
						nts: note	// starting note
					})
				}
			}
			s.notes.push(note)
			if (!in_chord)
				break

			// in chord: get the ending slurs and the ties
			c = line.char()
			while (1) {
				switch (c) {
				case ')':
					slur_add(s, note)
					c = line.next_char()
					continue
				case '-':
					note.tie_ty = parse_vpos()
					note.s = s
					curvoice.tie_s = s
					s.ti1 = true
					if (curvoice.acc[apit]
					 || (acc_tie
					  && acc_tie[apit])) {
						if (!curvoice.acc_tie)
							curvoice.acc_tie = []
						i = curvoice.acc[apit]
						if (acc_tie && acc_tie[apit])
							i = acc_tie[apit]
						curvoice.acc_tie[apit] = i
					}
					c = line.char()
					continue
				case '.':
					c = line.next_char()
					switch (c) {
					case '-':
					case '(':
						a_dcn.push("dot")
						continue
					}
					syntax(1, "Misplaced dot")
					break
				}
				break
			}
			if (a_dcn.length) {
				s.time = curvoice.time	// (needed for !tie)!
				dh_cnv(s, note)
			}

			if (c == ']') {
				line.index = in_chord
				s.nhd = s.notes.length - 1
				break
			}
		}

		// handle the starting slurs
		if (sls.length) {
			while (1) {
				i = sls.shift()
				if (!i)
					break
				curvoice.sls.push({
					ty: i,
					ss: s
					// no starting note
				})
				if (grace)
					curvoice.sls[curvoice.sls.length - 1].grace =
										grace
			}
		}

		// the duration of the chord is the duration of the 1st note
		s.dur_orig = s.notes[0].dur;
		s.dur = s.notes[0].dur * curvoice.dur_fact
		break
	}
	if (s.grace && s.type != C.NOTE) {
		syntax(1, errs.bad_grace)
		return //null
	}

	if (s.notes) {				// if note or rest
		if (!s.fmr) {			// (but not full measure rest)
			n = s.dur_orig / 12	// check its duration
			i = 0
			while (!(n & 1)) {
				n >>= 1
				i++
			}
			if ((n + 1) & n)
				error(0, s, "Non standard note duration $1",
					n + '/' + (1 << (6 - i)))
		}
		if (!grace) {
			switch (curvoice.pos.stm & 0x07) {
			case C.SL_ABOVE: s.stem = 1; break
			case C.SL_BELOW: s.stem = -1; break
			case C.SL_HIDDEN: s.stemless = true; break
			}

			// adjust the symbol duration
			num = curvoice.brk_rhythm
			if (num) {
				curvoice.brk_rhythm = 0;
				s2 = curvoice.last_note
				if (num > 0) {
					n = num * 2 - 1;
					s.dur = s.dur * n / num;
					s.dur_orig = s.dur_orig * n / num
					for (i = 0; i <= s.nhd; i++)
						s.notes[i].dur =
							s.notes[i].dur * n / num;
					s2.dur /= num;
					s2.dur_orig /= num
					for (i = 0; i <= s2.nhd; i++)
						s2.notes[i].dur /= num
				} else {
					num = -num;
					n = num * 2 - 1;
					s.dur /= num;
					s.dur_orig /= num
					for (i = 0; i <= s.nhd; i++)
						s.notes[i].dur /= num;
					s2.dur = s2.dur * n / num;
					s2.dur_orig = s2.dur_orig * n / num
					for (i = 0; i <= s2.nhd; i++)
						s2.notes[i].dur =
							s2.notes[i].dur * n / num
				}
				curvoice.time = s2.time + s2.dur;

				// adjust the time of the grace notes, bars...
				for (s2 = s2.next; s2; s2 = s2.next)
					s2.time = curvoice.time
			}
		} else {		/* grace note - adjust its duration */
			div = curvoice.ckey.k_bagpipe ? 8 : 4
			for (i = 0; i <= s.nhd; i++)
				s.notes[i].dur /= div;
			s.dur /= div;
			s.dur_orig /= div
			if (grace.stem)
				s.stem = grace.stem
		}

		curvoice.last_note = s

		// get the possible ties and end of slurs
		c = line.char()
		while (1) {
			switch (c) {
			case '.':
				if (line.buffer[line.index + 1] != '-')
					break
				a_dcn.push("dot")
				line.index++
				// fall thru
			case '-':
				ty = parse_vpos()
				for (i = 0; i <= s.nhd; i++) {
					s.notes[i].tie_ty = ty
					s.notes[i].s = s
				}
				curvoice.tie_s = grace || s
				curvoice.tie_s.ti1 = true
				for (i = 0; i <= s.nhd; i++) {
					note = s.notes[i]
					apit = note.pit + 19	// pitch from C-1
						- dpit		// (if transposition)
					if (curvoice.acc[apit]
					 || (acc_tie
					  && acc_tie[apit])) {
						if (!curvoice.acc_tie)
							curvoice.acc_tie = []
						n = curvoice.acc[apit]
						if (acc_tie && acc_tie[apit])
							n = acc_tie[apit]
						curvoice.acc_tie[apit] = n
					}
				}
				c = line.char()
				continue
			}
			break
		}

		// handle the ties ending on this chord/note
		if (tie_s)		// if tie from previous note / grace note
			do_ties(s, tie_s)
	}

	sym_link(s)

	if (!grace) {
		if (!curvoice.lyric_restart)
			curvoice.lyric_restart = s
		if (!curvoice.sym_restart)
			curvoice.sym_restart = s
	}

	if (a_dcn_sav.length) {
		a_dcn = a_dcn_sav
		deco_cnv(s, s.prev)
	}
	if (grace && s.ottava)
		grace.ottava = s.ottava
	if (parse.stemless)
		s.stemless = true
	s.iend = parse.bol + line.index
	return s
}

// adjust the duration of the elements in a tuplet
function tp_adj(s, fact) {
    var	d,
	tim = s.time,
	to = curvoice.time - tim,	// previous delta time
	tt = to * fact			// new delta time

	curvoice.time = tim + tt
	while (1) {
//fixme: tuplets in grace notes?
		s.in_tuplet = true
		if (!s.grace) {
			s.time = tim
			if (s.dur) {
				d = Math.round(s.dur * tt / to)	// new duration
				to -= s.dur		// old remaining time
				s.dur = d
				tt -= s.dur		// new remaining time
				tim += s.dur
			}
		}
		if (!s.next) {
			if (s.tpe)
				s.tpe++
			else
				s.tpe = 1
			break
		}
		s = s.next
	}
} // tp_adj()

// get a decoration
function get_deco() {
    var	c,
	line = parse.line,
	i = line.index,		// in case no deco end
	dcn = ""

	while (1) {
		c = line.next_char()
		if (!c) {
			line.index = i
			syntax(1, "No end of decoration")
			return
		}
		if (c == '!')
			break
		dcn += c
	}
	a_dcn.push(dcn)
} // get_deco()

// characters in the music line (ASCII only)
var nil = "0",
    char_tb = [
	nil, nil, nil, nil,		/* 00 - .. */
	nil, nil, nil, nil,
	nil, " ", "\n", nil,		/* . \t \n . */
	nil, nil, nil, nil,
	nil, nil, nil, nil,
	nil, nil, nil, nil,
	nil, nil, nil, nil,
	nil, nil, nil, nil,		/* .. - 1f */
	" ", "!", '"', "i",		/* (sp) ! " # */
	"\n", nil, "&", nil,		/* $ % & ' */
	"(", ")", "i", nil,		/* ( ) * + */
	nil, "-", "!dot!", nil,		/* , - . / */
	nil, nil, nil, nil, 		/* 0 1 2 3 */
	nil, nil, nil, nil, 		/* 4 5 6 7 */
	nil, nil, "|", "i",		/* 8 9 : ; */
	"<", "n", "<", "i",		/* < = > ? */
	"i", "n", "n", "n",		/* @ A B C */
	"n", "n", "n", "n", 		/* D E F G */
	"!fermata!", "d", "d", "d",	/* H I J K */
	"!emphasis!", "!lowermordent!",
		"d", "!coda!",		/* L M N O */
	"!uppermordent!", "d",
		"d", "!segno!",		/* P Q R S */
	"!trill!", "d", "d", "d",	/* T U V W */
	"n", "d", "n", "[",		/* X Y Z [ */
	"\\","|", "n", "n",		/* \ ] ^ _ */
	"i", "n", "n", "n",	 	/* ` a b c */
	"n", "n", "n", "n",	 	/* d e f g */
	"d", "d", "d", "d",		/* h i j k */
	"d", "d", "d", "d",		/* l m n o */
	"d", "d", "d", "d",		/* p q r s */
	"d", "!upbow!",
		"!downbow!", "d",	/* t u v w */
	"n", "n", "n", "{",		/* x y z { */
	"|", "}", "!gmark!", nil,	/* | } ~ (del) */
] // char_tb[]

function parse_music_line() {
	var	grace, last_note_sav, a_dcn_sav, no_eol, s, tps,
		tp = [],
		tpn = -1,
		sls = [],
		line = parse.line

	// check if a transposing macro matches a source sequence
	// if yes return the base note
	function check_mac(m) {
	    var	i, j, b

		for (i = 1, j = line.index + 1; i < m.length; i++, j++) {
			if (m[i] == line.buffer[j])
				continue
			if (m[i] != 'n')		// search the base note
				return //undefined
			b = ntb.indexOf(line.buffer[j])
			if (b < 0)
				return //undefined
			while (line.buffer[j + 1] == "'") {
				b += 7;
				j++
			}
			while (line.buffer[j + 1] == ',') {
				b -= 7;
				j++
			}
		}
		line.index = j
		return b
	} // check_mac()

	// convert a note as a number into a note as a ABC string
	function n2n(n) {
	    var	c = ''

		while (n < 0) {
			n += 7;
			c += ','
		}
		while (n >= 14) {
			n -= 7;
			c += "'"
		}
		return ntb[n] + c
	} // n2n()

	// expand a transposing macro
	function expand(m, b) {
		if (b == undefined)		// if static macro
			return m
	    var	c, i,
		r = "",				// result
		n = m.length

		for (i = 0; i < n; i++) {
			c = m[i]
			if (c >= 'h' && c <= 'z') {
				r += n2n(b + c.charCodeAt(0) - 'n'.charCodeAt(0))
			} else {
				r += c
			}
		}
		return r
	} // expand()

	// parse a macro
	function parse_mac(k, m, b) {
	    var	te, ti, curv, s,
		line_sav = line,
		istart_sav = parse.istart;

		parse.line = line = new scanBuf;
		parse.istart += line_sav.index;

		// if the macro is not displayed
		if (cfmt.writefields.indexOf('m') < 0) {

			// build the display sequence from the original sequence
			line.buffer = k.replace('n', n2n(b))
			s = curvoice.last_sym
			ti = curvoice.time		// start time
			parse_seq(true)
			if (!s)
				s = curvoice.sym
			for (s = s.next ; s; s = s.next)
				s.noplay = true
			te = curvoice.time		// end time
			curv = curvoice

			// and put the macro sequence in a play specific voice
			curvoice = clone_voice(curv.id + '-p')
			if (!par_sy.voices[curvoice.v]) {
				curvoice.second = true
				par_sy.voices[curvoice.v] = {
					st: curv.st,
					second: true,
					range: curvoice.v
				}
			}
			curvoice.time = ti
			s = curvoice.last_sym
			parse.line = line = new scanBuf
			parse.istart += line_sav.index
			line.buffer = expand(m, b)
			parse_seq(true)
			if (curvoice.time != te)
				syntax(1, "Bad length of the macro sequence")
			if (!s)
				s = curvoice.sym
			for ( ; s; s = s.next)
				s.invis = s.play = true
			curvoice = curv
		} else {
			line.buffer = expand(m, b)
			parse_seq(true)
		}

		parse.line = line = line_sav
		parse.istart = istart_sav
	} // parse_mac()

	// parse a music sequence
	function parse_seq(in_mac) {
	    var	c, idx, type, k, s, dcn, i, n, text, note

		while (1) {
			c = line.char()
			if (!c)
				break

			// check if start of a macro
			if (!in_mac && maci[c]) {
				n = undefined
				for (k in mac) {
					if (!mac.hasOwnProperty(k)
					 || k[0] != c)
						continue
					if (k.indexOf('n') < 0) {
						if (line.buffer.indexOf(k, line.index)
								!= line.index)
							continue
						line.index += k.length
					} else {
						n = check_mac(k)
						if (n == undefined)
							continue
					}
					parse_mac(k, mac[k], n)
					n = 1
					break
				}
				if (n)
					continue
			}

			idx = c.charCodeAt(0)
			if (idx >= 128) {
				syntax(1, errs.not_ascii)
				line.index++
				break
			}

			type = char_tb[idx]
			switch (type[0]) {
			case ' ':			// beam break
				s = curvoice.last_note
				if (s) {
					s.beam_end = true
					if (grace)
						grace.gr_shift = true
				}
				break
			case '\n':			// line break
				if (cfmt.barsperstaff)
					break
				curvoice.eoln = true
				break
			case '&':			// voice overlay
				if (grace) {
					syntax(1, errs.bad_grace)
					break
				}
				c = line.next_char()
				if (c == ')') {
					get_vover(c)	// full overlay stop
					break
				}
				get_vover('&')
				continue
			case '(':			// slur start - tuplet - vover
				c = line.next_char()
				if (c > '0' && c <= '9') {	// tuplet
					if (grace) {
						syntax(1, errs.bad_grace)
						break
					}
				    var	pplet = line.get_int(),
					qplet = qplet_tb[pplet],
					rplet = pplet

					c = line.char()
					if (c == ':') {
						c = line.next_char()
						if (c > '0' && c <= '9') {
							qplet = line.get_int();
							c = line.char()
						}
						if (c == ':') {
							c = line.next_char()
							if (c > '0' && c <= '9') {
								rplet = line.get_int();
								c = line.char()
							} else {
								syntax(1, "Invalid 'r' in tuplet")
								continue
							}
						}
					}
					if (qplet == 0 || qplet == undefined)
						qplet = (curvoice.wmeasure % 9) == 0 ?
									3 : 2;
					if (tpn < 0)
						tpn = tp.length	// new tuplet
					tp.push({
						p: pplet,
						q: qplet,
						r: rplet,
						ro: rplet,
						f: curvoice.tup || cfmt.tuplets
					})
					continue
				}
				if (c == '&') {		// voice overlay start
					if (grace) {
						syntax(1, errs.bad_grace)
						break
					}
					get_vover('(')
					break
				}
				line.index--;
				sls.push(parse_vpos())
				continue
			case ')':			// slur end
				s = curvoice.last_sym
				if (s) {
					switch (s.type) {
					case C.SPACE:
						if (!s.notes) {
							s.notes = []
							s.notes[0] = {}
						}
					case C.NOTE:
					case C.REST:
						break
					case C.GRACE:

						// stop the slur on the last grace note
						for (s = s.extra; s.next; s = s.next)
							;
						break
					default:
						s = null
						break
					}
				}
				if (!s) {
					syntax(1, errs.bad_char, c)
					break
				}
				slur_add(s)
				break
			case '!':			// start of decoration
				if (type.length > 1)	// decoration letter
					a_dcn.push(type.slice(1, -1))
				else
					get_deco()	// (line -> a_dcn)
				break
			case '"':
				if (grace) {
					syntax(1, errs.bad_grace)
					break
				}
				parse_gchord(type)
				break
			case '[':
				if (type.length > 1) {	// U: [I:xxx]
					self.do_pscom(type.slice(3, -1))
					break
				}
			    var c_next = line.buffer[line.index + 1]

				if ('|[]: "'.indexOf(c_next) >= 0
				 || (c_next >= '1' && c_next <= '9')) {
					if (grace) {
						syntax(1, errs.bar_grace)
						break
					}
					new_bar()
					continue
				}
				if (line.buffer[line.index + 2] == ':') {
					if (grace) {
						syntax(1, errs.bad_grace)
						break
					}
					i = line.buffer.indexOf(']', line.index + 1)
					if (i < 0) {
						syntax(1, "Lack of ']'")
						break
					}
					text = line.buffer.slice(line.index + 3, i).trim()

					parse.istart = parse.bol + line.index;
					parse.iend = parse.bol + ++i;
					line.index = 0;
					do_info(c_next, text);
					line.index = i
					continue
				}
				// fall thru ('[' is start of chord)
			case 'n':				// note/rest
				s = self.new_note(grace, sls)
				if (!s)
					continue

				// handle the tuplets
				if (grace || !s.notes)
					continue

				if (tpn >= 0) {		// new tuplet
					s.tp = tp.slice(tpn)
					tpn = -1
					if (tps)
						s.tp[0].s = tps	// if nested
					tps = s
				} else if (!tps) {
					continue	// no tuplet active
				}

				k = tp[tp.length - 1]
				if (--k.r > 0)
					continue	// not end of tuplet yet

				while (1) {
					tp_adj(tps, k.q / k.p)
					i = k.ro	// number of notes of this tuplet
					if (k.s)
						tps = k.s  // start of upper tuplet

					tp.pop()		// previous level
					if (!tp.length) {
						tps = null	// done
						break
					}
					k = tp[tp.length - 1]
					k.r -= i
					if (k.r > 0)
						break
				}
				continue
			case '<':				/* '<' and '>' */
				if (!curvoice.last_note) {
					syntax(1, "No note before '<'")
					break
				}
				if (grace) {
					syntax(1, "Cannot have a broken rhythm in grace notes")
					break
				}
				n = c == '<' ? 1 : -1
				while (c == '<' || c == '>') {
					n *= 2;
					c = line.next_char()
				}
				curvoice.brk_rhythm = n
				continue
			case 'i':				// ignore
				break
			case '{':
				if (grace) {
					syntax(1, "'{' in grace note")
					break
				}
				last_note_sav = curvoice.last_note;
				curvoice.last_note = null;
				a_dcn_sav = a_dcn;
				a_dcn = []
				grace = {
					type: C.GRACE,
					fname: parse.fname,
					istart: parse.bol + line.index,
					dur: 0,
					multi: 0
				}
				if (curvoice.color)
					grace.color = curvoice.color
				switch (curvoice.pos.gst & 0x07) {
				case C.SL_ABOVE: grace.stem = 1; break
				case C.SL_BELOW: grace.stem = -1; break
				case C.SL_HIDDEN: grace.stem = 2; break	/* opposite */
				}
				sym_link(grace);
				c = line.next_char()
				if (c == '/') {
					grace.sappo = true	// acciaccatura
					break
				}
				continue
			case '|':
				if (grace) {
					syntax(1, errs.bar_grace)
					break
				}
				new_bar()
				continue
			case '}':
				if (curvoice.ignore) {
					grace = null
					break
				}
				s = curvoice.last_note
				if (!grace || !s) {
					syntax(1, errs.bad_char, c)
					break
				}
				if (a_dcn.length)
					syntax(1, "Decoration ignored");
				grace.extra = grace.next;
				grace.extra.prev = null;
				grace.next = null;
				curvoice.last_sym = grace;
				grace = null
				if (!s.prev			// if one grace note
				 && !curvoice.ckey.k_bagpipe) {
					for (i = 0; i <= s.nhd; i++)
						s.notes[i].dur *= 2;
					s.dur *= 2;
					s.dur_orig *= 2
				}
				curvoice.last_note = last_note_sav;
				a_dcn = a_dcn_sav
				break
			case "\\":
				if (!line.buffer[line.index + 1]) {
					no_eol = true
					break
				}
				// fall thru
			default:
				syntax(1, errs.bad_char, c)
				break
			}
			line.index++
		}
	} // parse_seq()

	if (parse.state != 3)		// if not in tune body
		return

	if (parse.tp) {
		tp = parse.tp
		tpn = parse.tpn
		tps = parse.tps
		parse.tp = null
	}

	parse_seq()

	if (tp.length) {
		parse.tp = tp
		parse.tps = tps
		parse.tpn = tpn
	}
	if (sls.length)
		syntax(1, "Start of slur without note")
	if (grace) {
		syntax(1, "No end of grace note sequence");
		curvoice.last_sym = grace.prev;
		curvoice.last_note = last_note_sav
		if (grace.prev)
			grace.prev.next = null
	}
	if (!no_eol && !cfmt.barsperstaff && !vover
	 && char_tb['\n'.charCodeAt(0)] == '\n')
		curvoice.eoln = true
	if (curvoice.eoln && cfmt.breakoneoln && curvoice.last_note)
		curvoice.last_note.beam_end = true
}
// abc2svg - subs.js - text output
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

// add font styles
    var	sheet
var add_fstyle = abc2svg.el
    ? function(s) {
    var	e

	font_style += "\n" + s
	if (!abc2svg.styles) {
		e = document.createElement('style')
		document.head.appendChild(e)
		abc2svg.styles = e
	}
	sheet = abc2svg.styles.sheet
	s = s.match(/[^{]+{[^}]+}/g)	// insert each style
	while (1) {
		e = s.shift()
		if (!e)
			break
		sheet.insertRule(e, sheet.cssRules.length)
	}
    } // add_fstyle()
    : function(s) { font_style += "\n" + s }

// width of characters according to the font type
// these tables were created from the font 'Liberation'

// serif
  var
    sw_tb = new Float32Array([
	.000,.000,.000,.000,.000,.000,.000,.000,	// 00
	.000,.000,.000,.000,.000,.000,.000,.000,
	.000,.000,.000,.000,.000,.000,.000,.000,	// 10
	.000,.000,.000,.000,.000,.000,.000,.000,
	.250,.333,.408,.500,.500,.833,.778,.333,	// 20
	.333,.333,.500,.564,.250,.564,.250,.278,
	.500,.500,.500,.500,.500,.500,.500,.500,	// 30
	.500,.500,.278,.278,.564,.564,.564,.444,
	.921,.722,.667,.667,.722,.611,.556,.722,	// 40
	.722,.333,.389,.722,.611,.889,.722,.722,
	.556,.722,.667,.556,.611,.722,.722,.944,	// 50
	.722,.722,.611,.333,.278,.333,.469,.500,
	.333,.444,.500,.444,.500,.444,.333,.500,	// 60
	.500,.278,.278,.500,.278,.778,.500,.500,
	.500,.500,.333,.389,.278,.500,.500,.722,	// 70
	.500,.500,.444,.480,.200,.480,.541,.500]),
// sans-serif
    ssw_tb = new Float32Array([
	.000,.000,.000,.000,.000,.000,.000,.000,	// 00
	.000,.000,.000,.000,.000,.000,.000,.000,
	.000,.000,.000,.000,.000,.000,.000,.000,	// 10
	.000,.000,.000,.000,.000,.000,.000,.000,
	.278,.278,.355,.556,.556,.889,.667,.191,	// 20
	.333,.333,.389,.584,.278,.333,.278,.278,
	.556,.556,.556,.556,.556,.556,.556,.556,	// 30
	.556,.556,.278,.278,.584,.584,.584,.556,
       1.015,.667,.667,.722,.722,.667,.611,.778,	// 40
	.722,.278,.500,.667,.556,.833,.722,.778,
	.667,.778,.722,.667,.611,.722,.667,.944,	// 50
	.667,.667,.611,.278,.278,.278,.469,.556,
	.333,.556,.556,.500,.556,.556,.278,.556,	// 60
	.556,.222,.222,.500,.222,.833,.556,.556,
	.556,.556,.333,.500,.278,.556,.500,.722,	// 70
	.500,.500,.500,.334,.260,.334,.584,.512]),
// monospace
    mw_tb = new Float32Array([
	.0,.0,.0,.0,.0,.0,.0,.0,		// 00
	.0,.0,.0,.0,.0,.0,.0,.0,
	.0,.0,.0,.0,.0,.0,.0,.0,		// 10
	.0,.0,.0,.0,.0,.0,.0,.0,
	.52,.52,.52,.52,.52,.52,.52,.52,	// 20
	.52,.52,.52,.52,.52,.52,.52,.52,
	.52,.52,.52,.52,.52,.52,.52,.52,	// 30
	.52,.52,.52,.52,.52,.52,.52,.52,
	.52,.52,.52,.52,.52,.52,.52,.52,	// 40
	.52,.52,.52,.52,.52,.52,.52,.52,
	.52,.52,.52,.52,.52,.52,.52,.52,	// 50
	.52,.52,.52,.52,.52,.52,.52,.52,
	.52,.52,.52,.52,.52,.52,.52,.52,	// 60
	.52,.52,.52,.52,.52,.52,.52,.52,
	.52,.52,.52,.52,.52,.52,.52,.52,	// 70
	.52,.52,.52,.52,.52,.52,.52,.52])

/* -- return the character width -- */
function cwid(c, font) {
	var i = c.charCodeAt(0)		// utf-16

	if (i >= 0x80) {		// if not ASCII
		if (i >= 0x300 && i < 0x370)
			return 0;	// combining diacritical mark
		i = 0x61		// 'a'
	}
	return (font || gene.curfont).cw_tb[i]
}
// return the character width with the current font
function cwidf(c) {
	return cwid(c) * gene.curfont.swfac
}

// make XML clean
function clean_txt(p) {
	return p.replace(/<|>|&[^&\s]*?;|&/g, function(c) {
		switch (c) {
		case '<': return "&lt;"
		case '>': return "&gt;"
		case '&': return "&amp;"
		}
		return c		// &xxx;
	})
} // clean_txt()

// estimate the width and height of a string ..
var strwh

(function() {
    if (typeof document != "undefined"
     && abc2svg.el) {

    // .. by the browser

	// change the function
	strwh = function(str) {
		if (str.wh)
			return str.wh

	    var	c,
		el = abc2svg.el,	// hidden <span> created by edit/abcweb/...
		font = gene.curfont,
		h = font.size,
		w = 0,
		n = str.length,
		i0 = 0,
		i = 0

		if (!el.parentElement)		// insert back the <span> in the document
			document.body.appendChild(el)
		el.className = font_class(font)

		if (typeof str == "object") {	// if string already converted
			el.innerHTML = str
			str.wh = [ el.clientWidth, el.clientHeight ]
			return str.wh
		}
		str = clean_txt(str)

		while (1) {
			i = str.indexOf('$', i)
			if (i >= 0) {
				c = str[i + 1]
				if (c == '0') {
					font = gene.deffont
				} else if (c >= '1' && c <= '9') {
					font = get_font("u" + c)
				} else {
					i++
					continue
				}
				el.className = font_class(font)
			}

			el.innerHTML = str.slice(i0, i >= 0 ? i : undefined)
			w += el.clientWidth
//fixme: bad width if space(s) at end of string
			if (el.clientHeight > h)
				h = el.clientHeight

			if (i < 0)
				break
			i += 2;
			i0 = i
		}
		return [w, h]
	}
    } else {

    // .. by internal tables
    strwh = function(str) {
    var	font = gene.curfont,
	swfac = font.swfac,
	h = font.size,
	w = 0,
	i, j, c,
	n = str.length

	for (i = 0; i < n; i++) {
		c = str[i]
		switch (c) {
		case '$':
			c = str[i + 1]
			if (c == '0') {
				font = gene.deffont
			} else if (c >= '1' && c <= '9') {
				font = get_font("u" + c)
			} else {
				c = '$'
				break
			}
			i++;
			swfac = font.swfac
			if (font.size > h)
				h = font.size
			continue
		case '&':
			if (str[i + 1] == ' ')
				break		// normal '&'
			j = str.indexOf(';', i)
			if (j > 0 && j - i < 10) {
				i = j;
				c = 'a'		// XML character reference
			}
			break
		}
		w += cwid(c, font) * swfac
	}
	return [w, h]
    }
  }
})()

// convert a string to a SVG text, handling the font changes
// The string size is memorized into the String.
function str2svg(str) {
	// check if the string is already converted
	if (typeof str == "object")
		return str

    var	n_font, wh,
	o_font = gene.deffont,
	c_font = gene.curfont,
	o = ""

	// start a '<tspan>' element
	function tspan(nf, of) {
	    var	cl

		if (nf.class
		 && nf.name == of.name
		 && nf.size == of.size
		 && nf.weight == of.weight
		 && nf.style == of.style)
			cl = nf.class		// change only the class
		 else
			cl = font_class(nf)

		return '<tspan\n\tclass="' + cl + '">'
	} // tspan()

	if (c_font != o_font)
		o = tspan(c_font, o_font)
	o += str.replace(/<|>|&[^&\s]*?;|&|\$./g, function(c){
			switch (c) {
			case '<': return "&lt;"
			case '>': return "&gt;"
			case '&': return "&amp;"
			default:
				if (c[0] != '$')
					break
				if (c[1] == '0')
					n_font = gene.deffont
				else if (c[1] >= '1' && c[1] <= '9')
					n_font = get_font("u" + c[1])
				else
					break
				c = ''
				if (n_font == c_font)
					return c
				if (c_font != o_font)
					c = "</tspan>"
				c_font = n_font
				if (c_font == o_font)
					return c
				return c + tspan(c_font, o_font)
			}
			return c		// &xxx;
		})
	if (c_font != o_font)
		o += "</tspan>"

	// convert to String and memorize the string width and height
	o = new String(o)
	if (abc2svg.el)
		strwh(o)		// browser
	else
		o.wh = strwh(str)	// CLI

	gene.curfont = c_font	// keep the current font for the next paragraph

	return o
} // str2svg()

// set the default and current font
function set_font(xxx) {
	if (typeof xxx == "string")
		xxx = get_font(xxx)
	gene.curfont = gene.deffont = xxx
}

// output a string handling the font changes
function out_str(str) {
	output += str2svg(str)
}

// output a string, handling the font changes
// the action is:
//	'c' align center
//	'r' align right
//	'j' justify - w is the line width
//	otherwise align left
function xy_str(x, y,
		str,		// string or object String with attribute 'wh'
		action,		// default: align left
		w,		// needed for justify
		wh) {		// optional [width, height]
	if (!wh)
		wh = str.wh || strwh(str)
	if (cfmt.singleline || cfmt.trimsvg) {
	    var wx = wh[0]
		switch (action) {
		case 'c':
			wx = wh[0] / 2
			break
		case 'j':
			wx = w
			break
		case 'r':
			wx = 0
			break
		}
		if (img.wx < x + wx)
			img.wx = x + wx
	}

	output += '<text class="' + font_class(gene.deffont)
	if (action != 'j' && str.length > 5
	 && gene.deffont.wadj)
		output += '" lengthAdjust="' + gene.deffont.wadj +
			'" textLength="' + wh[0].toFixed(1);
	output += '" x="';
	out_sxsy(x, '" y="', y)
	switch (action) {
	case 'c':
		output += '" text-anchor="middle">'
		break
	case 'j':
		output += '" textLength="' + w.toFixed(1) + '">'
		break
	case 'r':
		output += '" text-anchor="end">'
		break
	default:
		output += '">'
		break
	}
	out_str(str);
	output += "</text>\n"
}

// move last capitalized word to front when after a comma
function trim_title(title, is_subtitle) {
	var i

	if (cfmt.titletrim) {
		i = title.lastIndexOf(", ")
		if (i < 0 || title[i + 2] < 'A' || title[i + 2] > 'Z') {
			i = 0
		} else if (cfmt.titletrim == 1) {	// (true) compatibility
			if (i < title.length - 7
			 || title.indexOf(' ', i + 3) >= 0)
				i = 0
		} else {
			if (i < title.length - cfmt.titletrim - 2)
				i = 0
		}
		if (i)
			title = title.slice(i + 2).trim() + ' ' + title.slice(0, i)
	}
	if (!is_subtitle
	 && cfmt.writefields.indexOf('X') >= 0)
		title = info.X + '.  ' + title
	if (cfmt.titlecaps)
		return title.toUpperCase()
	return title
}

// return the width of the music line
function get_lwidth() {
	if (img.chg)
		set_page()
	return (img.width - img.lm - img.rm
					- 2)	// for bar thickness at eol
			/ cfmt.scale
}

// header generation functions
function write_title(title, is_subtitle) {
    var	h, wh

	if (!title)
		return
	set_page();
	if (is_subtitle) {
		set_font("subtitle");
		h = cfmt.subtitlespace
	} else {
		set_font("title");
		h = cfmt.titlespace
	}
	wh = strwh(title)
	wh[1] += gene.curfont.pad * 2
	vskip(wh[1] + h + gene.curfont.pad)
	h = gene.curfont.pad + wh[1] * .22	// + descent
	if (cfmt.titleleft)
		xy_str(0, h, title, null, null, wh)
	else
		xy_str(get_lwidth() / 2, h, title, "c", null, wh)
}

/* -- output a header format '111 (222)' -- */
function put_inf2r(x, y, str1, str2, action) {
	if (!str1) {
		if (!str2)
			return
		str1 = str2;
		str2 = null
	}
	if (!str2)
		xy_str(x, y, str1, action)
	else
		xy_str(x, y, str1 + ' (' + str2 + ')', action)
}

/* -- write a text block (%%begintext / %%text / %%center) -- */
function write_text(text, action) {
	if (action == 's')
		return				// skip
	set_page();

    var	wh, font, o,
	strlw = get_lwidth(),
		sz = gene.curfont.size,
		lineskip = sz * cfmt.lineskipfac,
		parskip = sz * cfmt.parskipfac,
		i, j, x, words, w, k, ww, str;

	switch (action) {
	default:
//	case 'c':
//	case 'r':
		font = gene.curfont
		switch (action) {
		case 'c': x = strlw / 2; break
		case 'r': x = strlw - font.pad; break
		default: x = font.pad; break
		}
		j = 0
		while (1) {
			i = text.indexOf('\n', j)
			if (i == j) {			// new paragraph
				vskip(parskip);
				blk_flush()
				use_font(gene.curfont)
				while (text[i + 1] == '\n') {
					vskip(lineskip);
					i++
				}
				if (i == text.length)
					break
			} else {
				if (i < 0)
					str = text.slice(j)
				else
					str = text.slice(j, i)
				ww = strwh(str)
				vskip(ww[1] * cfmt.lineskipfac
					+ font.pad * 2)
				xy_str(x, font.pad + ww[1] * .2, str, action)
				if (i < 0)
					break
			}
			j = i + 1
		}
		vskip(parskip);
		blk_flush()
		break
	case 'f':
	case 'j':
		j = 0
		while (1) {
			i = text.indexOf('\n\n', j)
			if (i < 0)
				words = text.slice(j)
			else
				words = text.slice(j, i);
			words = words.split(/\s+/);
			w = k = wh = 0
			for (j = 0; j < words.length; j++) {
				ww = strwh(words[j] + ' ')	// &nbsp;
				w += ww[0]
				if (w >= strlw) {
					vskip(wh * cfmt.lineskipfac)
					xy_str(0, ww[1] * .2,
						words.slice(k, j).join(' '),
						action, strlw,
						[w - ww[0], ww[1]])
					k = j;
					w = ww[0]
					wh = 0
				}
				if (ww[1] > wh)
					wh = ww[1]
			}
			if (w != 0) {			// last line
				vskip(wh * cfmt.lineskipfac)
				xy_str(0, ww[1] * .2, words.slice(k).join(' '))
			}
			vskip(parskip);
			blk_flush()
			if (i < 0)
				break
			while (text[i + 2] == '\n') {
				vskip(lineskip);
				i++
			}
			if (i == text.length)
				break
			use_font(gene.curfont);
			j = i + 2
		}
		break
	}
}

/* -- output the words after tune -- */
function put_words(words) {
    var	p, i, j, nw, w, lw, x1, x2, i1, i2, do_flush,
	maxn = 0,			// max number of characters per line
	n = 1				// number of verses

	// output a line of words after tune
	function put_wline(p, x) {
	    var i = 0,
		k = 0

		if (p[0] == '$'		// if font change
		 && p[1] >= '0' && p[1] <= '9') {
			gene.curfont = p[1] == '0' ? gene.deffont
						: get_font("u" + p[1])
			p = p.slice(2)
		}

		if ((p[i] >= '0' && p[i] <= '9') || p[i + 1] == '.') {
			while (i < p.length) {
				i++
				if (p[i] == ' '
				 || p[i - 1] == ':'
				 || p[i - 1] == '.')
					break
			}
			k = i
			while (p[i] == ' ')
				i++
		}

	    var	y = gene.curfont.size * .22		// descent
		if (k != 0)
			xy_str(x, y, p.slice(0, k), 'r')
		if (i < p.length)
			xy_str(x + 5, y, p.slice(i), 'l')
	} // put_wline()

	// estimate the width of the lines
	words = words.split('\n')
	nw = words.length
	for (i = 0; i < nw; i++) {
		p = words[i]
		if (!p) {
			while (i + 1 < nw && !words[i + 1])
				i++
			n++
		} else if (p.length > maxn) {
			maxn = p.length
			i1 = i		// keep this line
		}
	}
	if (i1 == undefined)
		return			// no text in the W: lines!

	set_font("words")
	vskip(cfmt.wordsspace)
	svg_flush()

	w = get_lwidth() / 2		// half line width
	lw = strwh(words[i1])[0]
	i1 = i2 = 0
	if (lw < w) {			// if 2 columns
		j = n >> 1
		for (i = 0; i < nw; i++) {
			p = words[i]
			if (!p) {
				if (--j <= 0)
					i1 = i
				while (i + 1 < nw && !words[i + 1])
					i++
				if (j <= 0) {
					i2 = i + 1
					break
				}
			}
		}
		n >>= 1
	}
	if (i2) {
		x1 = (w - lw) / 2 + 10
		x2 = x1 + w
	} else {				// one column
		x2 = w - lw / 2 + 10
	}

	do_flush = true
	for (i = 0; i < i1 || i2 < nw; i++, i2++) {
		vskip(cfmt.lineskipfac * gene.curfont.size)
		if (i < i1) {
			p = words[i]
			if (p)
				put_wline(p, x1)
			else
				use_font(gene.curfont)
		}
		if (i2 < nw) {
			p = words[i2]
			if (p) {
				put_wline(p, x2)
			} else {


				if (--n == 0) {
					if (i < i1) {
						n++
					} else if (i2 < nw - 1) {

						// center the last verse
						x2 = w - lw / 2 + 10
						svg_flush()
					}
				}
			}
		}

		if (!words[i + 1] && !words[i2 + 1]) {
			if (do_flush) {
				svg_flush()
				do_flush = false
			}
		} else {
			do_flush = true
		}
	}
}

/* -- output history -- */
function put_history() {
	var	i, j, c, str, font, h, w, wh, head,
		names = cfmt.infoname.split("\n"),
		n = names.length

	for (i = 0; i < n; i++) {
		c = names[i][0]
		if (cfmt.writefields.indexOf(c) < 0)
			continue
		str = info[c]
		if (!str)
			continue
		if (!font) {
			font = true;
			set_font("history");
			vskip(cfmt.textspace);
			h = gene.curfont.size * cfmt.lineskipfac
		}
		head = names[i].slice(2)
		if (head[0] == '"')
			head = head.slice(1, -1);
		vskip(h);
		wh = strwh(head);
		xy_str(0, wh[1] * .22, head, null, null, wh);
		w = wh[0];
		str = str.split('\n');
		xy_str(w, wh[1] * .22, str[0])
		for (j = 1; j < str.length; j++) {
			if (!str[j]) {			// new paragraph
				vskip(gene.curfont.size * cfmt.parskipfac)
				continue
			}
			vskip(h);
			xy_str(w, wh[1] * .22, str[j])
		}
		vskip(h * cfmt.parskipfac)
		use_font(gene.curfont)
	}
}

// build a new sequence of the parts with clearer names
function part_seq() {
    var	i,
	o = ""

	for (i = 0; i < info.P.length; i++) {
		if (i)
			o += ' '
		o += partname(info.P[i])[1]
	}
	return o
} // part_seq()

// get the meaningful names of a part (P:)
function partname(c) {
    var	i, r, tmp

    if (cfmt.partname) {
	tmp = cfmt.partname.split('\n')

	for (i = 0; i < tmp.length; i++) {
		if (tmp[i][0] == c) {
			r = tmp[i].match(/.\s+(\S+)\s*(.+)?/)
			break
		}
	}
    }
	if (!r)
		return [0, c, c]
	if (!r[2])
		r[2] = r[1]
	if (r[2][0] == '"')
		r[2] = r[2].slice(1, -1)
	return r
} // partname()

/* -- output the tune heading -- */
// (possible hook)
Abc.prototype.tunhd = function() {
    var	i, j, area, composer, origin, rhythm, down1, down2, p,
		lwidth = get_lwidth()

	vskip(cfmt.topspace)

	/* titles */
	if (info.T
	 && cfmt.writefields.indexOf('T') >= 0) {
		i = 0
		while (1) {
			j = info.T.indexOf("\n", i)
			if (j < 0) {
				write_title(info.T.substring(i), i != 0)
				break
			}
			write_title(info.T.slice(i, j), i != 0);
			i = j + 1
		}
	}

	/* rhythm, composer, origin */
	down1 = down2 = 0
	if (parse.ckey.k_bagpipe
	 && !cfmt.infoline
	 && cfmt.writefields.indexOf('R') >= 0)
		rhythm = info.R
	if (rhythm) {
		set_font("composer");
		down1 = cfmt.composerspace + gene.curfont.size + 2
		xy_str(0, -down1 + gene.curfont.size *.22, rhythm)
	}
	area = info.A
	if (cfmt.writefields.indexOf('C') >= 0)
		composer = info.C
	if (cfmt.writefields.indexOf('O') >= 0)
		origin = info.O
	if (composer || origin || cfmt.infoline) {
		var xcomp, align;

		set_font("composer");
		if (cfmt.aligncomposer < 0) {
			xcomp = 0;
			align = ' '
		} else if (cfmt.aligncomposer == 0) {
			xcomp = lwidth * .5;
			align = 'c'
		} else {
			xcomp = lwidth;
			align = 'r'
		}
		if (composer || origin) {
			down2 = cfmt.composerspace + 2
			i = 0
			while (1) {
				down2 += gene.curfont.size
				if (composer)
					j = composer.indexOf("\n", i)
				else
					j = -1
				if (j < 0) {
					put_inf2r(xcomp, -down2 + gene.curfont.size *.22,
						composer ? composer.substring(i) : null,
						origin,
						align)
					break
				}
				xy_str(xcomp, -down2 + gene.curfont.size *.22,
					composer.slice(i, j), align);
				i = j + 1
			}
		}

		rhythm = rhythm ? null : info.R
		if ((rhythm || area) && cfmt.infoline) {

			/* if only one of rhythm or area then do not use ()'s
			 * otherwise output 'rhythm (area)' */
			set_font("info");
			down2 += cfmt.infospace + gene.curfont.size
			put_inf2r(lwidth, -down2 + gene.curfont.size *.22,
				rhythm, area, 'r')
		}
	}

	/* parts */
	if (info.P
	 && cfmt.writefields.indexOf('P') >= 0) {
		set_font("parts");
		i = cfmt.partsspace + gene.curfont.size + gene.curfont.pad
		if (down1 + i > down2)
			down2 = down1 + i
		else
			down2 += i
		p = info.P
		if (cfmt.partname)
			p = part_seq()
		xy_str(0, -down2 + gene.curfont.size *.22, p)
		down2 += gene.curfont.pad
	} else if (down1 > down2) {
		down2 = down1
	}
	vskip(down2 + cfmt.musicspace)
} // tunhd()

// output the tune header
function write_heading() {
	vskip(cfmt.topspace)
	self.tunhd()
} // write_heading()
// abc2svg - svg.js - svg functions
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

var	output = "",		// output buffer
	style = '\
\n.stroke{stroke:currentColor;fill:none}\
\n.bW{stroke:currentColor;fill:none;stroke-width:1}\
\n.bthW{stroke:currentColor;fill:none;stroke-width:3}\
\n.slW{stroke:currentColor;fill:none;stroke-width:.7}\
\n.slthW{stroke:currentColor;fill:none;stroke-width:1.5}\
\n.sltnW{stroke:currentColor;fill:none;stroke-width:.25}\
\n.sldW{stroke:currentColor;fill:none;stroke-width:.7;stroke-dasharray:5,10}\
\n.sW{stroke:currentColor;fill:none;stroke-width:.7}\
\n.box{outline:1px solid black;outline-offset:1px}',
	font_style = '',
	posx = cfmt.leftmargin / cfmt.scale,	// default x offset of the images
	posy = 0,		// y offset in the block
	img = {			// image
		width: cfmt.pagewidth,	// width
		lm: cfmt.leftmargin,	// left and right margins
		rm: cfmt.rightmargin,
		wx: 0,			// used width between the left and right margins
		chg: 1 //true
	},
	defined_glyph = {},
	defs = '',
	fulldefs = '',		// unreferenced defs as <filter>
	stv_g = {		/* staff/voice graphic parameters */
		scale: 1,
		stsc: 1,	// staff scale
		vsc: 1,		// voice scale
		dy: 0,
		st: -1,
		v: -1,
		g: 0
//		color: undefined
	},
	blkdiv = 0		// block of contiguous SVGs
				// -1: block started
				//  0: no block
				//  1: start a block
				//  2: start a new page

// glyphs in music font
var tgls = {
 "mtr ": {x:0, y:0, c:"\u0020"},	// space
  brace: {x:0, y:0, c:"\ue000"},
  lphr: {x:0, y:23, c:"\ue030"},
  mphr: {x:0, y:23, c:"\ue038"},
  sphr: {x:0, y:25, c:"\ue039"},
  short: {x:0, y:32, c:"\ue038"},
  tick: {x:0, y:25, c:"\ue039"},
  rdots: {x:0, y:0, c:"\ue043"},	// repeat dots
  rdot: {x:0, y:0, c:"\ue044"},		// single repeat dot
  dsgn: {x:-12, y:0, c:"\ue045"},	// D.S.
  dcap: {x:-12, y:0, c:"\ue046"},	// D.C.
  sgno: {x:-5, y:0, c:"\ue047"},	// segno
  coda: {x:-10, y:0, c:"\ue048"},
  tclef: {x:-8, y:0, c:"\ue050"},
  cclef: {x:-8, y:0, c:"\ue05c"},
  bclef: {x:-8, y:0, c:"\ue062"},
  pclef: {x:-6, y:0, c:"\ue069"},
  spclef: {x:-6, y:0, c:"\ue069"},
  stclef: {x:-8, y:0, c:"\ue07a"},
  scclef: {x:-8, y:0, c:"\ue07b"},
  sbclef: {x:-7, y:0, c:"\ue07c"},
  oct: {x:0, y:2, c:"\ue07d"},		// 8 for clefs
  oct2: {x:0, y:2, c:"\ue07e"},		// 15 for clefs
  mtr0: {x:0, y:0, c:"\ue080"},		// meters
  mtr1: {x:0, y:0, c:"\ue081"},
  mtr2: {x:0, y:0, c:"\ue082"},
  mtr3: {x:0, y:0, c:"\ue083"},
  mtr4: {x:0, y:0, c:"\ue084"},
  mtr5: {x:0, y:0, c:"\ue085"},
  mtr6: {x:0, y:0, c:"\ue086"},
  mtr7: {x:0, y:0, c:"\ue087"},
  mtr8: {x:0, y:0, c:"\ue088"},
  mtr9: {x:0, y:0, c:"\ue089"},
  mtrC: {x:0, y:0, c:"\ue08a"},		// common time (4/4)
  "mtrC|": {x:0, y:0, c:"\ue08b"},	// cut time (2/2)
  "mtr+":  {x:0, y:0, c:"\ue08c"},
  "mtr(":  {x:0, y:0, c:"\ue094"},
  "mtr)":  {x:0, y:0, c:"\ue095"},
  HDD: {x:-7, y:0, c:"\ue0a0"},
  breve: {x:-7, y:0, c:"\ue0a1"},
  HD: {x:-5.2, y:0, c:"\ue0a2"},
  Hd: {x:-3.8, y:0, c:"\ue0a3"},
  hd: {x:-3.7, y:0, c:"\ue0a4"},
  ghd: {x:2, y:0, c:"\ue0a4", sc:.66},	// grace note head
  pshhd: {x:-3.7, y:0, c:"\ue0a9"},
  pfthd: {x:-3.7, y:0, c:"\ue0b3"},
  x: {x:-3.7, y:0, c:"\ue0a9"},		// 'x' note head
  "circle-x": {x:-3.7, y:0, c:"\ue0b3"}, // 'circle-x' note head
  srep: {x:-5, y:0, c:"\ue101"},
  "dot+": {x:-5, y:0, sc:.7, c:"\ue101"},
  diamond: {x:-4, y:0, c:"\ue1b9"},
  triangle: {x:-4, y:0, c:"\ue1bb"},
  dot: {x:-1, y:0, c:"\ue1e7"},
  flu1: {x:-.3, y:0, c:"\ue240"},	// flags
  fld1: {x:-.3, y:0, c:"\ue241"},
  flu2: {x:-.3, y:0, c:"\ue242"},
  fld2: {x:-.3, y:0, c:"\ue243"},
  flu3: {x:-.3, y:3.5, c:"\ue244"},
  fld3: {x:-.3, y:-4, c:"\ue245"},
  flu4: {x:-.3, y:8, c:"\ue246"},
  fld4: {x:-.3, y:-9, c:"\ue247"},
  flu5: {x:-.3, y:12.5, c:"\ue248"},
  fld5: {x:-.3, y:-14, c:"\ue249"},
 "acc-1": {x:-1, y:0, c:"\ue260"},		// flat
 "cacc-1": {x:-18, y:0, c:"\ue26a\ue260\ue26b"}, // courtesy flat (note deco)
 "sacc-1": {x:-1, y:0, sc:.7, c:"\ue260"},	// small flat (editorial)
  acc3: {x:-1, y:0, c:"\ue261"},		// natural
 "cacc3": {x:-18, y:0, c:"\ue26a\ue261\ue26b"},	// courtesy natural (note deco)
  sacc3: {x:-1, y:0, sc:.7, c:"\ue261"},	// small natural (editorial)
  acc1: {x:-2, y:0, c:"\ue262"},		// sharp
 "cacc1": {x:-18, y:0, c:"\ue26a\ue262\ue26b"},	// courtesy sharp (note deco)
  sacc1: {x:-2, y:0, sc: .7, c:"\ue262"},	// small sharp (editorial)
  acc2: {x:-3, y:0, c:"\ue263"},	// double sharp
 "acc-2": {x:-3, y:0, c:"\ue264"},	// double flat
 "acc-1_2": {x:-2, y:0, c:"\ue280"},	// quarter-tone flat
 "acc-3_2": {x:-3, y:0, c:"\ue281"},	// three-quarter-tones flat
  acc1_2: {x:-1, y:0, c:"\ue282"},	// quarter-tone sharp
  acc3_2: {x:-3, y:0, c:"\ue283"},	// three-quarter-tones sharp
  accent: {x:-3, y:2, c:"\ue4a0"},
  stc: {x:0, y:-2, c:"\ue4a2"},		// staccato
  emb: {x:0, y:-2, c:"\ue4a4"},
  wedge: {x:0, y:0, c:"\ue4a8"},
  marcato: {x:-3, y:-2, c:"\ue4ac"},
  hld: {x:-7, y:-2, c:"\ue4c0"},		// fermata
  brth: {x:0, y:0, c:"\ue4ce"},
  caes: {x:0, y:8, c:"\ue4d1"},
  r00: {x:-1.5, y:0, c:"\ue4e1"},
  r0: {x:-1.5, y:0, c:"\ue4e2"},
  r1: {x:-3.5, y:-6, c:"\ue4e3"},
  r2: {x:-3.2, y:0, c:"\ue4e4"},
  r4: {x:-3, y:0, c:"\ue4e5"},
  r8: {x:-3, y:0, c:"\ue4e6"},
  r16: {x:-4, y:0, c:"\ue4e7"},
  r32: {x:-4, y:0, c:"\ue4e8"},
  r64: {x:-4, y:0, c:"\ue4e9"},
  r128: {x:-4, y:0, c:"\ue4ea"},
//  mrest: {x:-10, y:0, c:"\ue4ee"},
  mrep: {x:-6, y:0, c:"\ue500"},
  mrep2: {x:-9, y:0, c:"\ue501"},
  p: {x:-3, y:0, c:"\ue520"},
  f: {x:-3, y:0, c:"\ue522"},
  pppp: {x:-15, y:0, c:"\ue529"},
  ppp: {x:-14, y:0, c:"\ue52a"},
  pp: {x:-8, y:0, c:"\ue52b"},
  mp: {x:-8, y:0, c:"\ue52c"},
  mf: {x:-8, y:0, c:"\ue52d"},
  ff: {x:-7, y:0, c:"\ue52f"},
  fff: {x:-10, y:0, c:"\ue530"},
  ffff: {x:-14, y:0, c:"\ue531"},
  sfz: {x:-10, y:0, c:"\ue539"},
  trl: {x:-3, y:-3, c:"\ue566"},	// trill
  turn: {x:-5, y:0, c:"\ue567"},
  turnx: {x:-5, y:0, c:"\ue569"},
  umrd: {x:-6, y:2, c:"\ue56c"},
  lmrd: {x:-6, y:2, c:"\ue56d"},
  dplus: {x:-3, y:0, c:"\ue582"},	// plus
  sld: {x:-3, y:2, c:"\ue5d0"},		// slide
  grm: {x:-3, y:-2, c:"\ue5e2"},	// grace mark
  dnb: {x:-3, y:0, c:"\ue610"},		// down bow
  upb: {x:-2, y:0, c:"\ue612"},		// up bow
  opend: {x:-2, y:-2, c:"\ue614"},	// harmonic
  roll: {x:0, y:0, c:"\ue618"},
  thumb: {x:-2, y:-2, c:"\ue624"},
  snap: {x:-2, y:-2, c:"\ue630"},
  ped: {x:-10, y:0, c:"\ue650"},
  pedoff: {x:-5, y:0, c:"\ue655"},
 "mtro.": {x:0, y:0, c:"\ue910"},	// tempus perfectum prolatione perfecta
  mtro:   {x:0, y:0, c:"\ue911"},		// tempus perfectum
 "mtro|": {x:0, y:0, c:"\ue912"},	// tempus perfectum (twice as fast)
 "mtrc.": {x:0, y:0, c:"\ue914"},	// tempus imperfectum prolatione perfecta
  mtrc:   {x:0, y:0, c:"\ue915"},	// tempus imperfectum
 "mtrc|": {x:0, y:0, c:"\ue918"},	// tempus imperfectum (twice as fast)
  longa: {x:-4.7, y:0, c:"\ue95d"},
  custos: {x:-4, y:3, c:"\uea02"},
  ltr: {x:2, y:6, c:"\ueaa4"}		// long trill element
}

// glyphs to put in <defs>
var glyphs = {
}

// convert a meter string to a SmuFL encoded string
function m_gl(s) {
	return s.replace(/./g,
		function(e) {
		    var	m = tgls["mtr" + e]
//fixme: !! no m.x nor m.y yet !!
//			if (!m.x && !m.y)
				return m ? m.c : 0
//			return '<tspan dx="'+ m.x.toFixed(1) +
//				'" dy="' + m.y.toFixed(1) +
//				'">' +
//				m.c + '</tspan>'
		})
}

// mark a glyph as used and add it in <defs>
function def_use(gl) {
	var	i, j, g

	if (defined_glyph[gl])
		return
	defined_glyph[gl] = true;
	g = glyphs[gl]
	if (!g) {
//throw new Error("unknown glyph: " + gl)
		error(1, null, "Unknown glyph: '$1'", gl)
		return	// fixme: the xlink is set
	}
	j = 0
	while (1) {
		i = g.indexOf('xlink:href="#', j)
		if (i < 0)
			break
		i += 13;
		j = g.indexOf('"', i);
		def_use(g.slice(i, j))
	}
	defs += '\n' + g
}

// add user defs from %%beginsvg
function defs_add(text) {
	var	i, j, gl, tag, is,
		ie = 0

	// remove XML comments
	text = text.replace(/<!--.*?-->/g, '')

	while (1) {
		is = text.indexOf('<', ie);
		if (is < 0)
			break
		i = text.indexOf('id="', is)
		if (i < 0)
			break
		i += 4;
		j = text.indexOf('"', i);
		if (j < 0)
			break
		gl = text.slice(i, j);
		ie = text.indexOf('>', j);
		if (ie < 0)
			break
		if (text[ie - 1] == '/') {
			ie++
		} else {
			i = text.indexOf(' ', is);
			if (i < 0)
				break
			tag = text.slice(is + 1, i);
			ie = text.indexOf('</' + tag + '>', ie)
			if (ie < 0)
				break
			ie += 3 + tag.length
		}
		if (text.substr(is, 7) == '<filter')
			fulldefs += text.slice(is, ie) + '\n'
		else
			glyphs[gl] = text.slice(is, ie)
	}
}

// output the stop/start of a graphic sequence
function set_g() {

	// close the previous sequence
	if (stv_g.started) {
		stv_g.started = false;
		glout()
		output += "</g>\n"
	}

	// check if new sequence needed
	if (stv_g.scale == 1 && !stv_g.color)
		return

	// open the new sequence
	glout()
	output += '<g '
	if (stv_g.scale != 1) {
		if (stv_g.st < 0)
			output += voice_tb[stv_g.v].scale_str
		else if (stv_g.v < 0)
			output += staff_tb[stv_g.st].scale_str
		else
			output += 'transform="translate(0,' +
					(posy - stv_g.dy).toFixed(1) +
				') scale(' + stv_g.scale + ')"'
	}
	if (stv_g.color) {
		if (stv_g.scale != 1)
			output += ' ';
		output += 'color="' + stv_g.color + '"'
	}
	output += ">\n";
	stv_g.started = true
}

/* set the color */
function set_color(color) {
	if (color == stv_g.color)
		return undefined	// same color
	var	old_color = stv_g.color;
	stv_g.color = color;
	set_g()
	return old_color
}

/* -- set the staff scale (only) -- */
function set_sscale(st) {
	var	new_scale, dy

	if (st != stv_g.st && stv_g.scale != 1)
		stv_g.scale = 1
	new_scale = st >= 0 ? staff_tb[st].staffscale : 1
	if (st >= 0 && new_scale != 1)
		dy = staff_tb[st].y
	else
		dy = posy
	if (new_scale == stv_g.scale && dy == stv_g.dy
	 && stv_g.st == st && stv_g.vsc == 1)
		return
	stv_g.stsc =
		stv_g.scale = new_scale
	stv_g.vsc = 1
	stv_g.dy = dy;
	stv_g.st = st;
	stv_g.v = -1;
	set_g()
}

/* -- set the voice or staff scale -- */
function set_scale(s) {
    var	new_dy = posy,
	st = staff_tb[s.st].staffscale == 1 ? -1 : s.st,
	new_scale = s.p_v.scale

	if (st >= 0) {
		new_scale *= staff_tb[st].staffscale
		new_dy = staff_tb[st].y
	}
	if (new_scale == stv_g.scale && stv_g.dy == new_dy)
		return
	stv_g.scale = new_scale;
	stv_g.vsc = s.p_v.scale
	stv_g.dy = new_dy;
	stv_g.st = st
	stv_g.v = s.v;
	set_g()
}

// -- set the staff output buffer and scale when delayed output
function set_dscale(st, no_scale) {
	if (output) {
		if (stv_g.started) {	// close the previous sequence
			stv_g.started = false
			glout()
			output += "</g>\n"
		}
		if (stv_g.st < 0) {
			staff_tb[0].output += output
		} else if (stv_g.scale == 1) {
			staff_tb[stv_g.st].output += output
		} else {
			staff_tb[stv_g.st].sc_out += output
		}
		output = ""
	}
	if (st < 0)
		stv_g.scale = 1
	else
		stv_g.scale = no_scale ? 1 : staff_tb[st].staffscale;
	stv_g.st = st;
	stv_g.dy = 0
}

// update the y offsets of delayed output
function delayed_update() {
	var st, new_out, text

	for (st = 0; st <= nstaff; st++) {
		if (staff_tb[st].sc_out) {
			output += '<g ' + staff_tb[st].scale_str + '>\n' +
				staff_tb[st].sc_out + '</g>\n';
			staff_tb[st].sc_out = ""
		}
		if (!staff_tb[st].output)
			continue
		output += '<g transform="translate(0,' +
				(-staff_tb[st].y).toFixed(1) +
				')">\n' +
			staff_tb[st].output +
			'</g>\n';
		staff_tb[st].output = ""
	}
}

// output the annotations
function anno_out(s, t, f) {
	if (s.istart == undefined)
		return
	var	type = s.type,
		h = s.ymx - s.ymn + 4,
		wl = s.wl || 2,
		wr = s.wr || 2

	if (s.grace)
		type = C.GRACE

	f(t || abc2svg.sym_name[type], s.istart, s.iend,
		s.x - wl - 2, staff_tb[s.st].y + s.ymn + h - 2,
		wl + wr + 4, h, s);
}

function a_start(s, t) {
	anno_out(s, t, user.anno_start)
}
function a_stop(s, t) {
	anno_out(s, t, user.anno_stop)
}
function empty_function() {
}
	// the values are updated on generate()
    var	anno_start = empty_function,
	anno_stop = empty_function

// output the stop user annotations
function anno_put() {
    var	s
	while (1) {
		s = anno_a.shift()
		if (!s)
			break
		switch (s.type) {
		case C.CLEF:
		case C.METER:
		case C.KEY:
		case C.REST:
			if (s.type != C.REST || s.rep_nb) {
				set_sscale(s.st)
				break
			}
			// fall thru
		case C.GRACE:
		case C.NOTE:
		case C.MREST:
			set_scale(s)
			break
//		default:
//			continue
		}
		anno_stop(s)
	}
} // anno_put()

// output a string with x, y, a and b
// In the string,
//	X and Y are replaced by scaled x and y
//	A and B are replaced by a and b as string
//	F and G are replaced by a and b as float
function out_XYAB(str, x, y, a, b) {
	x = sx(x);
	y = sy(y);
	output += str.replace(/X|Y|A|B|F|G/g, function(c) {
		switch (c) {
		case 'X': return x.toFixed(1)
		case 'Y': return y.toFixed(1)
		case 'A': return a
		case 'B': return b
		case 'F': return a.toFixed(1)
//		case 'G':
		default: return b.toFixed(1)
		}
		})
}

// open / close containers
function g_open(x, y, rot, sx, sy) {
	glout()
	out_XYAB('<g transform="translate(X,Y', x, y);
	if (rot)
		output += ') rotate(' + rot.toFixed(2)
	if (sx) {
		output += ') scale(' + sx
		if (sy)
			output += ', ' + sy
	}
	output += ')">\n';
	stv_g.g++
}
function g_close() {
	glout()
	stv_g.g--;
	output += '</g>\n'
}

// external SVG string
Abc.prototype.out_svg = function(str) { output += str }

// exported functions for the annotation
function sx(x) {
	if (stv_g.g)
		return x
	return (x + posx) / stv_g.scale
}
Abc.prototype.sx = sx
function sy(y) {
	if (stv_g.g)
		return -y
	if (stv_g.scale == 1)
		return posy - y
	if (stv_g.v >= 0)
		return (stv_g.dy - y) / stv_g.vsc
	return stv_g.dy - y	// staff scale only
}
Abc.prototype.sy = sy;
Abc.prototype.sh = function(h) {
	if (stv_g.st < 0)
		return h / stv_g.scale
	return h
}
// for absolute X,Y coordinates
Abc.prototype.ax = function(x) { return x + posx }
Abc.prototype.ay = function(y) {
	if (stv_g.st < 0)
		return posy - y
	return posy + (stv_g.dy - y) * stv_g.scale - stv_g.dy
}
Abc.prototype.ah = function(h) {
	if (stv_g.st < 0)
		return h
	return h * stv_g.scale
}
// output scaled (x + <sep> + y)
function out_sxsy(x, sep, y) {
	x = sx(x);
	y = sy(y);
	output += x.toFixed(1) + sep + y.toFixed(1)
}
Abc.prototype.out_sxsy = out_sxsy

// define the start of a path
function xypath(x, y, fill) {
	if (fill)
		out_XYAB('<path d="mX Y', x, y)
	else
		out_XYAB('<path class="stroke" d="mX Y', x, y)
}
Abc.prototype.xypath = xypath

// draw all the helper/ledger lines
	function draw_all_hl() {
	    var	st, p_st

		function hlud(hla, d) {
		    var	hl, hll, i, xp, dx2, x2,
			n = hla.length

			if (!n)
				return
			for (i = 0; i < n; i++) {	// for all lines
				hll = hla[i]
				if (!hll || !hll.length)
					continue
				xp = sx(hll[0][0])	// previous x
				output +=
				    '<path class="stroke" stroke-width="1" d="M' +
					xp.toFixed(1) + ' ' +
					sy(p_st.y + d * i).toFixed(1)
				dx2 = 0
				while (1) {
					hl = hll.shift()
					if (!hl)
						break
					x2 = sx(hl[0])
					output += 'm' +
						(x2 - xp + hl[1] - dx2).toFixed(2) +
						' 0h' + (-hl[1] + hl[2]).toFixed(2)
					xp = x2
					dx2 = hl[2]
				}
				output += '"/>\n'
			}
		} // hlud()

		for (st = 0; st <= nstaff; st++) {
			p_st = staff_tb[st]
			if (!p_st.hlu)
				continue	// (staff not yet displayed)
			set_sscale(st)
			hlud(p_st.hlu, 6)
			hlud(p_st.hld, -6)
		}
	} // draw_all_hl()

// output the list of glyphs and the stems
// [0] = x glyph
// [1] = y glyph
// [2] = glyph code
// [3] = x, y, h of stem (3 values per stem)
var gla = [[], [], "", [], [], []]
function glout() {
    var	e,
	v = []

	// glyphs (notes, accidentals...)
    if (gla[0].length) {
	while (1) {
		e = gla[0].shift()
		if (e == undefined)
			break
		v.push(e.toFixed(1))
	}
	output += '<text x="' + v.join(',')

	v = []
	while (1) {
		e = gla[1].shift()
		if (e == undefined)
			break
		v.push(e.toFixed(1))
	}
	output += '"\ny="' + v.join(',')

	output += '"\n>' + gla[2] + '</text>\n'
	gla[2] = ""
    }

	// stems
	if (!gla[3].length)
		return
	output += '<path class="sW" d="'
	while (1) {
		e = gla[3].shift()
		if (e == undefined)
			break
		output += 'M' + e.toFixed(1) +
			' ' + gla[3].shift().toFixed(1) +
			'v' + gla[3].shift().toFixed(1)
	}
	output += '"/>\n'
} // glout()

// output a glyph
function xygl(x, y, gl) {
// (avoid ps<->js loop)
//	if (psxygl(x, y, gl))
//		return
	if (glyphs[gl]) {
		def_use(gl)
		out_XYAB('<use x="X" y="Y" xlink:href="#A"/>\n', x, y, gl)
	} else {
	    var	tgl = tgls[gl]
		if (tgl) {
			x += tgl.x * stv_g.scale;
			y -= tgl.y
			if (tgl.sc) {
				out_XYAB('<text transform="translate(X,Y) scale(A)">B</text>\n',
					x, y, tgl.sc, tgl.c);
			} else {
//				out_XYAB('<text x="X" y="Y">A</text>\n', x, y, tgl.c)
				gla[0].push(sx(x))
				gla[1].push(sy(y))
				gla[2] += tgl.c
			}
		} else if (gl != 'nil') {
			error(1, null, 'no definition of $1', gl)
		}
	}
}
// - specific functions -
// gua gda (acciaccatura)
function out_acciac(x, y, dx, dy, up) {
	if (up) {
		x -= 1;
		y += 4
	} else {
		x -= 5;
		y -= 4
	}
	out_XYAB('<path class="stroke" d="mX YlF G"/>\n',
		x, y, dx, -dy)
}
// staff system brace
function out_brace(x, y, h) {
//fixme: '-6' depends on the scale
	x += posx - 6;
	y = posy - y;
	h /= 24;
	output += '<text transform="translate(' +
				x.toFixed(1) + ',' + y.toFixed(1) +
			') scale(2.5,' + h.toFixed(2) +
			')">' + tgls.brace.c + '</text>\n'
}

// staff system bracket
function out_bracket(x, y, h) {
	x += posx - 5;
	y = posy - y - 3;
	h += 2;
	output += '<path d="m' + x.toFixed(1) + ' ' + y.toFixed(1) + '\n\
	c10.5 1 12 -4.5 12 -3.5c0 1 -3.5 5.5 -8.5 5.5\n\
	v' + h.toFixed(1) + '\n\
	c5 0 8.5 4.5 8.5 5.5c0 1 -1.5 -4.5 -12 -3.5"/>\n'
}
// hyphen
function out_hyph(x, y, w) {
	var	n, a_y,
		d = 25 + ((w / 20) | 0) * 3

	if (w > 15.)
		n = ((w - 15) / d) | 0
	else
		n = 0;
	x += (w - d * n - 5) / 2;
	out_XYAB('<path class="stroke" stroke-width="1.2"\n\
	stroke-dasharray="5,A"\n\
	d="mX YhB"/>\n',
		x, y + 4,		// set the line a bit upper
		Math.round((d - 5) / stv_g.scale), d * n + 5)
}
// stem [and flags]
function out_stem(x, y, h, grace,
		  nflags, straight) {	// optional
//fixme: dx KO with half note or longa
	var	dx = grace ? GSTEM_XOFF : 3.5,
		slen = -h

	if (h < 0)
		dx = -dx;		// down
	x += dx * stv_g.scale
	if (stv_g.v >= 0)
		slen /= voice_tb[stv_g.v].scale;
	gla[3].push(sx(x))
	gla[3].push(sy(y))
	gla[3].push(slen)
	if (!nflags)
		return

	y += h
	if (h > 0) {				// up
		if (!straight) {
			if (!grace) {
				xygl(x, y, "flu" + nflags)
				return
			} else {		// grace
				output += '<path d="'
				if (nflags == 1) {
					out_XYAB('MX Yc0.6 3.4 5.6 3.8 3 10\n\
	1.2 -4.4 -1.4 -7 -3 -7\n', x, y)
				} else {
					while (--nflags >= 0) {
						out_XYAB('MX Yc1 3.2 5.6 2.8 3.2 8\n\
	1.4 -4.8 -2.4 -5.4 -3.2 -5.2\n', x, y);
						y -= 3.5
					}
				}
			}
		} else {			// straight
			output += '<path d="'
			if (!grace) {
				while (--nflags >= 0) {
					out_XYAB('MX Yl7 3.2 0 3.2 -7 -3.2z\n',
						x, y);
					y -= 5.4
				}
			} else {		// grace
				while (--nflags >= 0) {
					out_XYAB('MX Yl3 1.5 0 2 -3 -1.5z\n',
						x, y);
					y -= 3
				}
			}
		}
	} else {				// down
		if (!straight) {
			if (!grace) {
				xygl(x, y, "fld" + nflags)
				return
			} else {		// grace
				output += '<path d="'
				if (nflags == 1) {
					out_XYAB('MX Yc0.6 -3.4 5.6 -3.8 3 -10\n\
	1.2 4.4 -1.4 7 -3 7\n', x, y)
				} else {
					while (--nflags >= 0) {
						out_XYAB('MX Yc1 -3.2 5.6 -2.8 3.2 -8\n\
	1.4 4.8 -2.4 5.4 -3.2 5.2\n', x, y);
						y += 3.5
					}
				}
			}
		} else {			// straight
			output += '<path d="'
			if (!grace) {
				while (--nflags >= 0) {
					out_XYAB('MX Yl7 -3.2 0 -3.2 -7 3.2z\n',
						x, y);
					y += 5.4
				}
//			} else {		// grace
//--fixme: error?
			}
		}
	}
	output += '"/>\n'
}
// tremolo
function out_trem(x, y, ntrem) {
	out_XYAB('<path d="mX Y\n\t', x - 4.5, y)
	while (1) {
		output += 'l9 -3v3l-9 3z'
		if (--ntrem <= 0)
			break
		output += 'm0 5.4'
	}
	output += '"/>\n'
}
// tuplet bracket - the staves are not defined
function out_tubr(x, y, dx, dy, up) {
	var	h = up ? -3 : 3;

	y += h;
	dx /= stv_g.scale;
	output += '<path class="stroke" d="m';
	out_sxsy(x, ' ', y);
	output += 'v' + h.toFixed(1) +
		'l' + dx.toFixed(1) + ' ' + (-dy).toFixed(1) +
		'v' + (-h).toFixed(1) + '"/>\n'
}
// tuplet bracket with number - the staves are not defined
function out_tubrn(x, y, dx, dy, up, str) {
    var	dxx,
	sw = str.length * 10,
	h = up ? -3 : 3;

	set_font("tuplet")
	xy_str(x + dx / 2, y + dy / 2 - gene.curfont.size * .1,
		str, 'c')
		dx /= stv_g.scale
	if (!up)
		y += 6;
	output += '<path class="stroke" d="m';
	out_sxsy(x, ' ', y);
	dxx = dx - sw + 1
	if (dy > 0)
		sw += dy / 8
	else
		sw -= dy / 8
	output += 'v' + h.toFixed(1) +
		'm' + dx.toFixed(1) + ' ' + (-dy).toFixed(1) +
		'v' + (-h).toFixed(1) + '"/>\n' +
		'<path class="stroke" stroke-dasharray="' +
		(dxx / 2).toFixed(1) + ' ' + sw.toFixed(1) +
		'" d="m';
	out_sxsy(x, ' ', y - h);
	output += 'l' + dx.toFixed(1) + ' ' + (-dy).toFixed(1) + '"/>\n'

}
// underscore line
function out_wln(x, y, w) {
	out_XYAB('<path class="stroke" stroke-width="0.8" d="mX YhF"/>\n',
		x, y + 1, w)
}

// decorations with string
var deco_str_style = {
crdc:	{				// cresc., decresc., dim., ...
		dx: 0,
		dy: 5,
		style: 'font:italic 14px text,serif',
		anchor: ' text-anchor="middle"'
	},
dacs:	{				// long repeats (da capo, fine...)
		dx: 0,
		dy: 3,
		style: 'font:bold 15px text,serif',
		anchor: ' text-anchor="middle"'
	},
pf:	{
		dx: 0,
		dy: 5,
		style: 'font:italic bold 16px text,serif',
		anchor: ' text-anchor="middle"'
	}
}
deco_str_style.at = deco_str_style.crdc

function out_deco_str(x, y, de) {
    var	name = de.dd.glyph			// class

	if (name == 'fng') {
		out_XYAB('\
<text x="X" y="Y" style="font-size:14px">A</text>\n',
			x - 2, y + 1, m_gl(de.dd.str))
		return
	}

	if (name == '@') {			// compatibility
		name = 'at'
	} else if (!/^[A-Za-z][A-Za-z\-_]*$/.test(name)) {
		error(1, de.s, "No function for decoration '$1'", de.dd.name)
		return
	}

    var	f,
		a_deco = deco_str_style[name]

	if (!a_deco)
		a_deco = deco_str_style.crdc	// default style
	else if (a_deco.style)
		style += "\n." + name + "{" + a_deco.style + "}",
		delete a_deco.style

	x += a_deco.dx;
	y += a_deco.dy;
	out_XYAB('<text x="X" y="Y" class="A"B>', x, y,
		name, a_deco.anchor || "");
	set_font("annotation");
	out_str(de.dd.str)
	output += '</text>\n'
}

function out_arp(x, y, val) {
	g_open(x, y, 270);
	x = 0;
	val = Math.ceil(val / 6)
	while (--val >= 0) {
		xygl(x, 6, "ltr");
		x += 6
	}
	g_close()
}
function out_cresc(x, y, val, defl) {
	x += val * stv_g.scale
	val = -val;
	out_XYAB('<path class="stroke"\n\
	d="mX YlF ', x, y, val)
	if (defl.nost)
		output += '-2.2m0 -3.6l' + (-val).toFixed(1) + ' -2.2"/>\n'
	else
		output += '-4l' + (-val).toFixed(1) + ' -4"/>\n'

}
function out_dim(x, y, val, defl) {
	out_XYAB('<path class="stroke"\n\
	d="mX YlF ', x, y, val)
	if (defl.noen)
		output += '-2.2m0 -3.6l' + (-val).toFixed(1) + ' -2.2"/>\n'
	else
		output += '-4l' + (-val).toFixed(1) + ' -4"/>\n'
}
function out_ltr(x, y, val) {
	y += 4;
	val = Math.ceil(val / 6)
	while (--val >= 0) {
		xygl(x, y, "ltr");
		x += 6
	}
}
Abc.prototype.out_lped = function(x, y, val, defl) {
	if (!defl.nost)
		xygl(x, y, "ped");
	if (!defl.noen)
		xygl(x + val + 6, y, "pedoff")
}
function out_8va(x, y, val, defl) {
	if (val < 18) {
		val = 18
		x -= 4
	}
	if (!defl.nost) {
		out_XYAB('<text x="X" y="Y" \
style="font:italic bold 12px text,serif">8\
<tspan dy="-4" style="font-size:10px">va</tspan></text>\n',
			x - 8, y);
		x += 12;
		val -= 12
	}
	y += 6;
	out_XYAB('<path class="stroke" stroke-dasharray="6,6" d="mX YhF"/>\n',
		x, y, val)
	if (!defl.noen)
		out_XYAB('<path class="stroke" d="mX Yv6"/>\n', x + val, y)
}
function out_8vb(x, y, val, defl) {
	if (val < 18) {
		val = 18
		x -= 4
	}
	if (!defl.nost) {
		out_XYAB('<text x="X" y="Y" \
style="font:italic bold 12px text,serif">8\
<tspan dy=".5" style="font-size:10px">vb</tspan></text>\n',
			x - 8, y);
		x += 10
		val -= 10
	}
//	y -= 2;
	out_XYAB('<path class="stroke" stroke-dasharray="6,6" d="mX YhF"/>\n',
		x, y, val)
	if (!defl.noen)
		out_XYAB('<path class="stroke" d="mX Yv-6"/>\n', x + val, y)
}
function out_15ma(x, y, val, defl) {
	if (val < 25) {
		val = 25
		x -= 6
	}
	if (!defl.nost) {
		out_XYAB('<text x="X" y="Y" \
style="font:italic bold 12px text,serif">15\
<tspan dy="-4" style="font-size:10px">ma</tspan></text>\n',
			x - 10, y);
		x += 20;
		val -= 20
	}
	y += 6;
	out_XYAB('<path class="stroke" stroke-dasharray="6,6" d="mX YhF"/>\n',
		x, y, val)
	if (!defl.noen)
		out_XYAB('<path class="stroke" d="mX Yv6"/>\n', x + val, y)
}
function out_15mb(x, y, val, defl) {
	if (val < 24) {
		val = 24
		x -= 5
	}
	if (!defl.nost) {
		out_XYAB('<text x="X" y="Y" \
style="font:italic bold 12px text,serif">15\
<tspan dy=".5" style="font-size:10px">mb</tspan></text>\n',
			x - 10, y);
		x += 18
		val -= 18
	}
//	y -= 2;
	out_XYAB('<path class="stroke" stroke-dasharray="6,6" d="mX YhF"/>\n',
		x, y, val)
	if (!defl.noen)
		out_XYAB('<path class="stroke" d="mX Yv-6"/>\n', x + val, y)
}
var deco_val_tb = {
	arp:	out_arp,
	cresc:	out_cresc,
	dim:	out_dim,
	ltr:	out_ltr,
	lped:	function(x, y, val, defl) {
			self.out_lped(x, y, val, defl)
		},
	"8va":	out_8va,
	"8vb":	out_8vb,
	"15ma":	out_15ma,
	"15mb": out_15mb
}

function out_deco_val(x, y, name, val, defl) {
	if (deco_val_tb[name])
		deco_val_tb[name](x, y, val, defl)
	else
		error(1, null, "No function for decoration '$1'", name)
}

function out_glisq(x2, y2, de) {
    var	ar, a, len,
	de1 = de.start,
		x1 = de1.x,
		y1 = de1.y + staff_tb[de1.st].y,
		dx = x2 - x1,
		dy = self.sh(y1 - y2)

	if (!stv_g.g)
		dx /= stv_g.scale

	ar = Math.atan2(dy, dx)
	a = ar / Math.PI * 180
	len = (dx - (de1.s.dots ? 13 + de1.s.xmx : 8)
		- 8 - (de.s.notes[0].shac || 0))
			/ Math.cos(ar)

	g_open(x1, y1, a);
	x1 = de1.s.dots ? 13 + de1.s.xmx : 8;
	len = len / 6 | 0
	if (len < 1)
		len = 1
	while (--len >= 0) {
		xygl(x1, 0, "ltr");
		x1 += 6
	}
	g_close()
}

function out_gliss(x2, y2, de) {
    var	ar, a, len,
	de1 = de.start,
		x1 = de1.x,
		y1 = de1.y + staff_tb[de1.st].y,
		dx = x2 - x1,
		dy = self.sh(y1 - y2)

	if (!stv_g.g)
		dx /= stv_g.scale

	ar = Math.atan2(dy, dx)
	a = ar / Math.PI * 180
	len = (dx - (de1.s.dots ? 13 + de1.s.xmx : 8)
		- 8 - (de.s.notes[0].shac || 0))
			/ Math.cos(ar)

	g_open(x1, y1, a);
	xypath(de1.s.dots ? 13 + de1.s.xmx : 8, 0)
	output += 'h' + len.toFixed(1) + '" stroke-width="1"/>\n';
	g_close()
}

var deco_l_tb = {
	glisq: out_glisq,
	gliss: out_gliss
}

function out_deco_long(x, y, de) {
    var	s, p_v, m, nt, i,
	name = de.dd.glyph,
	de1 = de.start

	if (!deco_l_tb[name]) {
		error(1, null, "No function for decoration '$1'", name)
		return
	}

	// if no start or no end, get the y offset of the other end
	p_v = de.s.p_v				// voice
	if (de.defl.noen) {			// if no end
		s = p_v.s_next			// start of the next music line
		while (s && !s.dur)
			s = s.next
		if (s) {
			for (m = 0; m <= s.nhd; m++) {
				nt = s.notes[m]
				if (!nt.a_dd)
					continue
				for (i = 0; i < nt.a_dd.length; i++) {
					if (nt.a_dd[i].name == de.dd.name) {
						y = 3 * (nt.pit - 18)
							+ staff_tb[de.s.st].y
						break
					}
				}
			}
		}
		x += 8				// (there is no note width)
	} else if (de.defl.nost) {		// no start
		s = p_v.s_prev			// end of the previous music line
		while (s && !s.dur)
			s = s.prev
		if (s) {
			for (m = 0; m <= s.nhd; m++) {
				nt = s.notes[m]
				if (!nt.a_dd)
					continue
				for (i = 0; i < nt.a_dd.length; i++) {
					if (nt.a_dd[i].name == de1.dd.name) {
						de1.y = 3 * (nt.pit - 18)
						break
					}
				}
			}
		}
		de1.x -= 8			// (there is no note width)
	}
	deco_l_tb[name](x, y, de)
}

// add a tempo note in 'str' and return its number of characters
function tempo_note(str, s, dur, dy) {
    var	p,
	elts = identify_note(s, dur)

	switch (elts[0]) {		// head
	case C.OVAL:
		p = "\ueca2"
		break
	case C.EMPTY:
		p = "\ueca3"
		break
	default:
		switch (elts[2]) {	// flags
		case 2:
			p = "\ueca9"
			break
		case 1:
			p = "\ueca7"
			break
		default:
			p = "\ueca5"
			break
		}
		break
	}
	str.push('<tspan\nclass="' +
			font_class(cfmt.musicfont) +
		'" style="font-size:' +
		(gene.curfont.size * 1.3).toFixed(1) + 'px"' +
		dy + '>' +
		p + '</tspan>'
		+ (elts[1] ? '\u2009.' : ''))		// dot
	return elts[1] ? 2 : 1
} // tempo_note()

// build the tempo string
function tempo_build(s) {
    var	i, j, bx, p, wh, dy, h,
	w = 0,
	str = []

	if (s.tempo_str)	// already done
		return

	// the music font must be defined
	if (!cfmt.musicfont.used)
		get_font("music")

	set_font("tempo")
	h = gene.curfont.size
	if (s.tempo_str1) {
		str.push(s.tempo_str1)
		w += strwh(s.tempo_str1)[0]
	}
	if (s.tempo_notes) {
		dy = ' dy="-1"'			// notes a bit higher
		h *= 1.3
		for (i = 0; i < s.tempo_notes.length; i++) {
			j = tempo_note(str, s, s.tempo_notes[i], dy)
			w += j * gene.curfont.swfac
			dy = ''
		}
		str.push('<tspan dy="1">=</tspan>')
		w += cwidf('=')
		if (s.tempo_ca) {
			str.push(s.tempo_ca)
			w += strwh(s.tempo_ca)[0]
			j = s.tempo_ca.length + 1
		}
		if (s.tempo) {			// with a number of beats per minute
			str.push(s.tempo)
			w += strwh(s.tempo.toString())[0]
		} else {			// with a beat as a note
			j = tempo_note(str, s, s.new_beat, ' dy="-1"')
			w += j * gene.curfont.swfac
			dy = 'y'
		}
	}
	if (s.tempo_str2) {
		if (dy)
			str.push('<tspan\n\tdy="1">' +
					s.tempo_str2 + '</tspan>')
		else
			str.push(s.tempo_str2)
		w += strwh(s.tempo_str2)[0]
	}

	// build the string
	s.tempo_str = str.join(' ')
	w += cwidf(' ') * (str.length - 1)
	s.tempo_wh = [w, h]
} // tempo_build()

// output a tempo
function writempo(s, x, y) {
    var	bh

	set_font("tempo")
	if (gene.curfont.box) {
		gene.curfont.box = false
		bh = s.tempo_wh[1] + 2
	}

//fixme: xy_str() cannot be used because <tspan> in s.tempo_str
//fixme: then there cannot be font changes by "$n" in the Q: texts
	output += '<text class="' + font_class(gene.curfont) +
		'" x="'
	out_sxsy(x, '" y="', y + gene.curfont.size * .22)
	output += '">' + s.tempo_str + '</text>\n'

	if (bh) {
		gene.curfont.box = true
		output += '<rect class="stroke" x="'
		out_sxsy(x - 2, '" y="', y + bh - 1)
		output += '" width="' + (s.tempo_wh[0] + 4).toFixed(1) +
			'" height="' + bh.toFixed(1) +
			'"/>\n'
	}

	// don't display anymore
	s.invis = true
} // writempo()

// update the vertical offset
function vskip(h) {
	posy += h
}

// clear the styles
function clr_sty() {
	font_style = ''
	if (cfmt.fullsvg) {
		defined_glyph = {}
		for (var i = 0; i < abc2svg.font_tb.length; i++)
			abc2svg.font_tb[i].used = 0 //false
		ff.used = 0 //false		// clear the font-face
	} else {
		style =
			fulldefs = ''
	}
} // clr_sty()

// create the SVG image of the block
function svg_flush() {
	if (multicol || !user.img_out || posy == 0)
		return

    var	i, font,
	fmt = tsnext ? tsnext.fmt : cfmt,
	w = Math.ceil((fmt.trimsvg || fmt.singleline == 1)
		? (cfmt.leftmargin + img.wx * cfmt.scale + cfmt.rightmargin + 2)
		: img.width),
	head = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1"\n\
	xmlns:xlink="http://www.w3.org/1999/xlink"\n\
	fill="currentColor" stroke-width=".7"',
	g = ''

	glout()

	if (cfmt.fgcolor)
		head += ' color="' + cfmt.fgcolor + '"'
	font = get_font("music")
	head += ' class="' + font_class(font) +
		' tune' + tunes.length + '"\n'	// tune index for play

	posy *= cfmt.scale
	if (user.imagesize != undefined)
		head += user.imagesize
	else
		head += ' width="' + w
			+ 'px" height="' + posy.toFixed(2) + 'px"'
	head += ' viewBox="0 0 ' + w + ' '
		+ posy.toFixed(2) + '">\n'
	head += fulldefs
	if (cfmt.bgcolor)
		head += '<rect width="100%" height="100%" fill="'
			+ cfmt.bgcolor + '"/>\n'

	if (style || font_style)
		head += '<style>' + font_style + style + '\n</style>\n'

	if (defs)
		head += '<defs>' + defs + '\n</defs>\n'

	// if %%pagescale != 1, do a global scale
	// (with a container: transform scale in <svg> does not work
	//	the same in all browsers)
	// the class is used to know that the container is global
	if (cfmt.scale != 1) {
		head += '<g class="g" transform="scale(' +
			cfmt.scale + ')">\n';
		g = '</g>\n'
	}

	if (psvg)			// if PostScript support
		psvg.ps_flush(true);	// + setg(0)

	// start a block if needed
	if (parse.state == 1 && user.page_format && !blkdiv)
		blkdiv = 1		// new tune
	if (blkdiv > 0) {
		user.img_out(blkdiv == 1 ?
			'<div class="nobrk">' :
			'<div class="nobrk newpage">')
		blkdiv = -1		// block started
	} else if (blkdiv < 0 && cfmt.splittune) {
		i = 1			// header and first music line
		blkdiv = 0
	}
	user.img_out(head + output + g + "</svg>");
	if (i)
		user.img_out("</div>")
	output = ""

	clr_sty()
	defs = '';
	posy = 0
	img.wx = 0			// space used between the margins
}

// mark the end of a <div> block
function blk_flush() {
	svg_flush()
	if (blkdiv < 0 && !parse.state) {
		user.img_out('</div>')
		blkdiv = 0
	}
}
Abc.prototype.blk_flush = blk_flush
// abc2svg - tune.js - tune generation
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

var	par_sy,		// current staff system for parse
	cur_sy,		// current staff system for generation
	voice_tb,
	curvoice,
	staves_found,
	vover,		// voice overlay
	tsfirst

/* apply the %%voice options of the current voice */
function voice_filter() {
    var	opt

	function vfilt(opts, opt) {
	    var	i,
		sel = new RegExp(opt)

		if (sel.test(curvoice.id)
		 || sel.test(curvoice.nm)) {
			for (i = 0; i < opts.length; i++)
				self.do_pscom(opts[i])
		}
	}

	// global
	if (parse.voice_opts)
	    for (opt in parse.voice_opts) {
		if (parse.voice_opts.hasOwnProperty(opt))
			vfilt(parse.voice_opts[opt], opt)
	}

	// tune
	if (parse.tune_v_opts)
	    for (opt in parse.tune_v_opts) {
		if (parse.tune_v_opts.hasOwnProperty(opt))
			vfilt(parse.tune_v_opts[opt], opt)
	}
}

/* -- link a ABC symbol into the current voice -- */
// if a voice is ignored (not in %%staves) don't link the symbol
//	but update the time for P: and Q:
function sym_link(s) {
    var	tim = curvoice.time

	if (!s.fname)
		set_ref(s)
    if (!curvoice.ignore) {
	s.prev = curvoice.last_sym
	if (curvoice.last_sym)
		curvoice.last_sym.next = s
	else
		curvoice.sym = s
    } else if (s.bar_type) {
		curvoice.last_bar = s
    }
	curvoice.last_sym = s
	s.v = curvoice.v;
	s.p_v = curvoice;
	s.st = curvoice.cst;
	s.time = tim
	if (s.dur && !s.grace)
		curvoice.time += s.dur;
	parse.ufmt = true
	s.fmt = cfmt				// global parameters
	s.pos = curvoice.pos
	if (curvoice.second)
		s.second = true
	if (curvoice.floating)
		s.floating = true
	if (curvoice.eoln) {
		s.soln = true
		curvoice.eoln = false
	}
}

/* -- add a new symbol in a voice -- */
function sym_add(p_voice, type) {
	var	s = {
			type:type,
			dur:0
		},
		s2,
		p_voice2 = curvoice;

	curvoice = p_voice;
	sym_link(s);
	curvoice = p_voice2;
	s2 = s.prev
	if (!s2)
		s2 = s.next
	if (s2) {
		s.fname = s2.fname;
		s.istart = s2.istart;
		s.iend = s2.iend
	}
	return s
}

/* -- sort all symbols by time and vertical sequence -- */
// weight of the symbols !! depends on the symbol type !!
var w_tb = new Uint8Array([
	6,	// bar
	2,	// clef
	8,	// custos
	6,	// sm (sequence marker, after bar)
	7,	// grace
	3,	// key
	4,	// meter
	9,	// mrest
	9,	// note
	0,	// part
	9,	// rest
	5,	// space (before bar)
	0,	// staves
	1,	// stbrk
	0,	// tempo
	0,	// (free)
	0,	// block
	0	// remark
])

function sort_all() {
    var	s, s2, time, w, wmin, ir, fmt, v, p_voice, prev,
	fl, new_sy,
	nv = voice_tb.length,
	vtb = [],
	vn = [],			// voice indexed by range
	sy = cur_sy			// first staff system

	// check if different bars at the same time
	function b_chk() {
	    var	bt, s, s2, v, t,
		ir = 0

		while (1) {
			v = vn[ir++]
			if (v == undefined)
				break
			s = vtb[v]
			if (!s || !s.bar_type || s.invis
			 || s.time != time)
				continue
			if (!bt) {
				bt = s.bar_type
				if (s.text && bt == '|')
					t = s.text
				continue
			}
			if (s.bar_type != bt)
				break
			if (s.text && !t && bt == '|') {
				t = s.text
				break
			}
		}

		if (v == undefined)
			return			// no problem

		// change "::" to ":| |:"
		// and    "|1" to "| [1"
		if (bt == "::" || bt == ":|"
		 || t) {
			ir = 0
			bt = t ? '|' : "::"
			while (1) {
				v = vn[ir++]
				if (v == undefined)
					break
				s = vtb[v]
				if (!s || s.invis
				 || s.bar_type != bt
				 || (bt == '|' && !s.text))
					continue
				s2 = clone(s)
				if (bt == "::") {
					s.bar_type = ":|"
					s2.bar_type = "|:"
				} else {
//					s.bar_type = '|'
					delete s.text
					delete s.rbstart
					s2.bar_type = '['
					s2.invis = 1 //true
					s2.xsh = 0
				}
				s2.next = s.next
				if (s2.next)
					s2.next.prev = s2
				s2.prev = s
				s.next = s2
			}
		} else {
			error(1, s, "Different bars $1 and $2",
				(bt + (t || '')), (s.bar_type + (s.text || '')))
		}
	} // b_chk()

	// set the first symbol of each voice
	for (v = 0; v < nv; v++) {
		s = voice_tb[v].sym
		vtb[v] = s
		if (sy.voices[v]) {
			vn[sy.voices[v].range] = v
			if (!prev && s) {
				fmt = s.fmt
				p_voice = voice_tb[v]
				prev = {	// symbol defining the first staff system
					type: C.STAVES,
					fname: parse.fname,
					dur: 0,
					v: v,
					p_v: p_voice,
					time: 0,
					st: 0,
					sy: sy,
					next: s,
					fmt: fmt,
					seqst: true
				}
			}
		}
	}

	if (!prev)
		return					// no symbol yet

	// insert the first staff system in the first voice
	p_voice.sym = tsfirst = s = prev
	if (s.next)
		s.next.prev = s
	else
		p_voice.last_sym = s

	// if Q: from tune header, put it at start of the music
	// (after the staff system)
	s = glovar.tempo
	if (s) {
		s.v = v = p_voice.v
		s.p_v = p_voice
		s.st = 0
		s.time = 0
		s.prev = prev
		s.next = prev.next
		if (s.next)
			s.next.prev = s
		else
			p_voice.last_sym = s
		s.prev.next = s
		s.fmt = fmt
		glovar.tempo = null
		vtb[v] = s
	}

	// if only one voice, quickly create the time links
	if (nv == 1) {
		s = tsfirst
		s.ts_next = s.next
		while (1) {
			s = s.next
			if (!s)
				return
			if (s.time != s.prev.time
			 || w_tb[s.prev.type])
				s.seqst = 1 //true
			if (s.type == C.PART) {		// move the part
				s.prev.next =
					s.prev.ts_next = s.next
				if (s.next) {
					s.next.part = s	// to the next symbol
					s.next.prev = s.prev
					if (s.soln)
						s.next.soln = 1 //true
					if (s.seqst)
						s.next.seqst = 1 //true
				}
				continue
			}
			s.ts_prev = s.prev
			s.ts_next = s.next
		}
		// not reached
	}

	// loop on the symbols of all voices
	while (1) {
		if (new_sy) {
			sy = new_sy;
			new_sy = null;
			vn.length = 0
			for (v = 0; v < nv; v++) {
				if (!sy.voices[v])
					continue
				vn[sy.voices[v].range] = v
			}
		}

		/* search the min time and symbol weight */
		wmin = time = 10000000		// big int
		ir = 0
		while (1) {
			v = vn[ir++]
			if (v == undefined)
				break
			s = vtb[v]
			if (!s || s.time > time)
				continue
			w = w_tb[s.type]
			if (s.type == C.GRACE
			 && s.next
			 && s.next.type == C.BAR)
				w = 5			// < bar
			if (s.time < time) {
				time = s.time;
				wmin = w
			} else if (w < wmin) {
				wmin = w
			}
		}

		if (wmin > 127)
			break			// done

		// check the type of the measure bars
		if (wmin == 6)			// !! weight of bars
			b_chk()

		/* link the vertical sequence */
		ir = 0
		while (1) {
			v = vn[ir++]
			if (v == undefined)
				break
			s = vtb[v]
			if (!s
			 || s.time != time)
				continue
			w = w_tb[s.type]
			if (s.type == C.GRACE
			 && s.next
			 && s.next.type == C.BAR)
				w = 5			// < bar
			if (w != wmin)
				continue
			if (!w
			 && s.type == C.PART) {		// move the part
				if (s.prev)
					s.prev.next = s.next
				else
					s.p_v.sym = s.next
				vtb[v] = s.next
				if (s.next) {
					s.next.part = s	// to the next symbol
					s.next.prev = s.prev
					if (s.soln)
						s.next.soln = 1 //true
//				} else {
// ignored
				}
				continue
			}
			if (s.type == C.STAVES)
				new_sy = s.sy
			if (fl) {
				fl = 0;
				s.seqst = true
			}
			s.ts_prev = prev
			prev.ts_next = s
			prev = s

			vtb[v] = s.next
		}
		if (wmin)			// if some width
			fl = 1 //true		// start a new sequence
	}
}

// adjust some voice elements
// (possible hook)
Abc.prototype.voice_adj = function (sys_chg) {
    var	p_voice, s, s2, v, sl

	// insert the delayed P: and Q: in the top_voice
	function ins_pq() {
	    var	s, s2,
		p_v = voice_tb[par_sy.top_voice]

		while (1) {
			s = parse.pq_d.shift()
			if (!s)
				break
			for (s2 = p_v.sym; ; s2 = s2.next) {
				if (s2.time >= s.time
				 && s2.dur) {
					s.next = s2
					s.prev = s2.prev
					s.prev.next =
						s2.prev = s
					s.v = s2.v
					s.p_v = p_v
					s.st = s2.st
					break
				}
			}
		}
	} // ins_pq()

	// set the duration of the notes under a feathered beam
	function set_feathered_beam(s1) {
		var	s, s2, t, d, b, i, a,
			d = s1.dur,
			n = 1

		/* search the end of the beam */
		for (s = s1; s; s = s.next) {
			if (s.beam_end || !s.next)
				break
			n++
		}
		if (n <= 1) {
			delete s1.feathered_beam
			return
		}
		s2 = s;
		b = d / 2;		/* smallest note duration */
		a = d / (n - 1);	/* delta duration */
		t = s1.time
		if (s1.feathered_beam > 0) {	/* !beam-accel! */
			for (s = s1, i = n - 1;
			     s != s2;
			     s = s.next, i--) {
				d = ((a * i) | 0) + b;
				s.dur = d;
				s.time = t;
				t += d
			}
		} else {				/* !beam-rall! */
			for (s = s1, i = 0;
			     s != s2;
			     s = s.next, i++) {
				d = ((a * i) | 0) + b;
				s.dur = d;
				s.time = t;
				t += d
			}
		}
		s.dur = s.time + s.dur - t;
		s.time = t
	} // end set_feathered_beam()

	// terminate voice cloning
	if (curvoice && curvoice.clone) {
		parse.istart = parse.eol
		do_cloning()
	}

	// if only one voice and a time skip,
	// fill the voice with the sequence "Z |" (multi-rest and bar)
	if (par_sy.one_v)			// if one voice
		fill_mr_ba(voice_tb[par_sy.top_voice])

	if (parse.pq_d)
		ins_pq()			// insert delayed P: and Q:

	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v]
		if (!sys_chg) {			// if not %%score
			delete p_voice.eoln
			while (1) {		// set the end of slurs
				sl = p_voice.sls.shift()
				if (!sl)
					break
				s = sl.ss
//					error(1, s, "Lack of ending slur(s)")
					if (!s.sls)
						s.sls = []
				sl.loc = 'o'		// no slur end
				s.sls.push(sl)
			}
		} // not %%score
		for (s = p_voice.sym; s; s = s.next) {
			if (s.time >= staves_found)
				break
		}
		for ( ; s; s = s.next) {

			// if the symbol has a sequence weight smaller than the bar one
			// and if there a time skip,
			// add an invisible bar before it
			if (w_tb[s.type] < 5
			 && s.type != C.STAVES
			 && s.type != C.CLEF
			 && s.time			// not at start of tune
			 && (!s.prev || s.time > s.prev.time + s.prev.dur)) {
				s2 = {
					type: C.BAR,
					bar_type: "[]",
					v: s.v,
					p_v: s.p_v,
					st: s.st,
					time: s.time,
					dur:0,
					next: s,
					prev: s.prev,
					fmt: s.fmt,
					invis: 1
				}
				if (s.prev)
					s.prev.next = s2
				else
					voice_tb[s.v].sym = s2
				s.prev = s2
			}

			switch (s.type) {
			case C.GRACE:
				if (!cfmt.graceword)
					continue
				for (s2 = s.next; s2; s2 = s2.next) {
					switch (s2.type) {
					case C.SPACE:
						continue
					case C.NOTE:
						if (!s2.a_ly)
							break
						s.a_ly = s2.a_ly;
						s2.a_ly = null
						break
					}
					break
				}
				continue
			case C.NOTE:
				if (s.feathered_beam)
					set_feathered_beam(s)
				break
			}
		}
	}
}

/* -- create a new staff system -- */
function new_syst(init) {
    var	st, v, sy_staff, p_voice,
	sy_new = {
		voices: [],
		staves: [],
		top_voice: 0
	}

	if (init) {				/* first staff system */
		cur_sy = par_sy = sy_new
		return
	}

	// update the previous system
	for (v = 0; v < voice_tb.length; v++) {
	    if (par_sy.voices[v]) {
		st = par_sy.voices[v].st
		sy_staff = par_sy.staves[st]
		p_voice = voice_tb[v]

		sy_staff.staffnonote = p_voice.staffnonote
		if (p_voice.staffscale)
			sy_staff.staffscale = p_voice.staffscale;
	    }
	}
	for (st = 0; st < par_sy.staves.length; st++) {
		sy_new.staves[st] = clone(par_sy.staves[st]);
		sy_new.staves[st].flags = 0
	}
	par_sy.next = sy_new;
	par_sy = sy_new
}

/* -- set the bar numbers -- */
// (possible hook)
Abc.prototype.set_bar_num = function() {
    var	s, s2, rep_tim, k, n, nu, txt,
	tim = 0,			// time of the previous bar
	bar_num = gene.nbar,
	bar_tim = 0,			// time of previous repeat variant
	ptim = 0,			// time of previous bar
	wmeasure = voice_tb[cur_sy.top_voice].meter.wmeasure

	// check the measure duration
	function check_meas() {
	    var	s3

		if (tim > ptim + wmeasure
		 && s.prev.type != C.MREST)
			return 1 //true

		// the measure is too short,
		// check if there is a bar a bit further
		for (s3 = s.next; s3 && s3.time == s.time; s3 = s3.next)
			;
		for ( ; s3 && !s3.bar_type; s3 = s3.next)
			;
		return s3 && (s3.time - bar_tim) % wmeasure
	}

	// don't count a bar at start of tune
	for (s = tsfirst; ; s = s.ts_next) {
		if (!s)
			return
		switch (s.type) {
		case C.METER:
			wmeasure = s.wmeasure
			// fall thru
		case C.CLEF:
		case C.KEY:
		case C.STBRK:
			continue
		case C.BAR:
			if (s.bar_num)
				bar_num = s.bar_num	// %%setbarnb)
			break
		}
		break
	}

	// at start of tune, check for an anacrusis
	for (s2 = s.ts_next; s2; s2 = s2.ts_next) {
		if (s2.type == C.BAR && s2.time
		 && !s2.invis && !s2.bar_dotted) {
			if (s2.time < wmeasure) {	// if anacrusis
				s = s2
				bar_tim = s.time
			}
			break
		}
	}

	// set the measure number on the top bars
	for ( ; s; s = s.ts_next) {
		switch (s.type) {
		case C.METER:
			if (wmeasure != 1)		// if not M:none
				bar_num += (s.time - bar_tim) / wmeasure
			bar_tim = s.time
			wmeasure = s.wmeasure
			while (s.ts_next && s.ts_next.wmeasure)
				s = s.ts_next
			break
		case C.BAR:
			if (s.time <= tim)
				break			// already seen
			tim = s.time

			nu = 1 //true			// no num update
			txt = ""
			for (s2 = s; s2; s2 = s2.next) {
				if (s2.time > tim)
					break
				if (!s2.bar_type)
					continue
				if (s2.bar_type != '[')
					nu = 0 //false	// do update
				if (s2.text)
					txt = s2.text
			}
			if (s.bar_num) {
				bar_num = s.bar_num	// (%%setbarnb)
				ptim = bar_tim = tim
				break
			}
			if (wmeasure == 1) {		// if M:none
				if (s.bar_dotted)
					break
				if (txt) {
					if (!cfmt.contbarnb) {
						if (txt[0] == '1')
							rep_tim = bar_num
						else
							bar_num = rep_tim
					}
				}
				if (!nu)
					s.bar_num = ++bar_num
				break
			}

			n = bar_num + (tim - bar_tim) / wmeasure
			k = n - (n | 0)
			if (cfmt.checkbars
			 && k
			 && check_meas())
				error(0, s, "Bad measure duration")
			if (tim > ptim + wmeasure) {	// if more than one measure
				n |= 0
				k = 0
				bar_tim = tim		// re-synchronize
				bar_num = n
			}

			if (txt) {
				if (txt[0] == '1') {
					if (!cfmt.contbarnb)
						rep_tim = tim - bar_tim
					if (!nu)
						s.bar_num = n
				} else {
					if (!cfmt.contbarnb)
						bar_tim = tim - rep_tim
					n = bar_num + (tim - bar_tim) / wmeasure
					if (n == (n | 0))
						s.bar_num = n
				}
			} else if (n == (n | 0)) {
				s.bar_num = n
			}
			if (!k)
				ptim = tim
			break
		}
	}
}

// convert a note to ABC
function not2abc(pit, acc) {
    var	i,
	nn = ''

	if (acc) {
		if (typeof acc != "object") {
			nn = ['__', '_', '', '^', '^^', '='][acc + 2]
		} else {
			i = acc[0]
			if (i > 0) {
				nn += '^'
			} else {
				nn += '_'
				i = -i
			}
			nn += i + '/' + acc[1]
		}
	}
	nn += ntb[(pit + 75) % 7]
	for (i = pit; i >= 23; i -= 7)
		nn += "'"
	for (i = pit; i < 16; i += 7)
		nn += ","
	return nn
} // not2abc()

// note mapping
// %%map map_name note [print [note_head]] [param]*
function get_map(text) {
	if (!text)
		return

    var	i, note, notes, map, tmp, ns,
	ty = '',
	a = text.split(/\s+/)

	if (a.length < 3) {
		syntax(1, errs.not_enough_p)
		return
	}
	ns = a[1]
	if (ns != '*') {
 		if (ns.indexOf("octave,") == 0	// remove the octave part
		 || ns.indexOf("key,") == 0
		 || !ns.indexOf("tonic,")) {
			ty = ns[0]
			ns = ns.split(',')[1].toUpperCase()
		}
		tmp = new scanBuf
		tmp.buffer = ns
		note = parse_acc_pit(tmp)
		if (!note) {
			syntax(1, "Bad note in %%map")
			return
		}
		ns = ty + not2abc(note.pit, note.acc)
	}

	notes = maps[a[0]]
	if (!notes)
		maps[a[0]] = notes = {}
	map = notes[ns]
	if (!map)
		notes[ns] = map = []

	// try the optional 'print' and 'heads' parameters
	a.shift()
	a.shift()
	if (!a.length)
		return
	a = info_split(a.join(' '))
	i = 0
	if (a[0].indexOf('=') < 0) {
		if (a[0][0] != '*') {
			tmp = new scanBuf;		// print
			tmp.buffer = a[0];
			map[1] = parse_acc_pit(tmp)
		}
		if (!a[1])
			return
		i++
		if (a[1].indexOf('=') < 0) {
			map[0] = a[1].split(',')	// heads
			i++
		}
	}

	for (; i < a.length; i++) {
		switch (a[i]) {
		case "heads=":
			if (!a[++i]) {
				syntax(1, errs.not_enough_p)
				break
			}
			map[0] = a[i].split(',')
			break
		case "print=":
		case "play=":
		case "print_notrp=":
			if (!a[++i]) {
				syntax(1, errs.not_enough_p)
				break
			}
			tmp = new scanBuf;
			tmp.buffer = a[i];
			note = parse_acc_pit(tmp)
			if (a[i - 1][5] == '_')		// if print no transpose
				note.notrp = 1 //true
			if (a[i - 1][1] == 'r')
				map[1] = note
			else
				map[3] = note
			break
		case "color=":
			if (!a[++i]) {
				syntax(1, errs.not_enough_p)
				break
			}
			map[2] = a[i]
			break
		}
	}
}

// get a abcm2ps/abcMIDI compatible transposition value as a base-40 interval
// The value may be
// - [+|-]<number of semitones>[s|f]
// - <note1>[<note2>]  % <note2> default is 'c'
function get_transp(param) {
	if (param[0] == '0')
		return 0
	if ("123456789-+".indexOf(param[0]) >= 0) {	// by semi-tone
	    var	val = parseInt(param)
		if (isNaN(val) || val < -36 || val > 36) {
//fixme: no source reference...
			syntax(1, errs.bad_transp)
			return
		}
		val += 36
		val = ((val / 12 | 0) - 3) * 40 + abc2svg.isb40[val % 12]
		if (param.slice(-1) == 'b')
			val += 4
		return val
	}
	// return undefined
} // get_transp()

/* -- process a pseudo-comment (%% or I:) -- */
// (possible hook)
Abc.prototype.do_pscom = function(text) {
    var	h1, val, s, cmd, param, n, k, b

	cmd = text.match(/[^\s]+/)
	if (!cmd)
		return
	cmd = cmd[0];

	// ignore the command if the voice is ignored,
	// but not if %%score/%%staves!
	if (curvoice && curvoice.ignore) {
		switch (cmd) {
		case "staves":
		case "score":
			break
		default:
			return
		}
	}

	param = text.replace(cmd, '').trim()

	if (param.slice(-5) == ' lock') {
		fmt_lock[cmd] = true;
		param = param.slice(0, -5).trim()
	} else if (fmt_lock[cmd]) {
		return
	}

	switch (cmd) {
	case "clef":
		if (parse.state >= 2) {
			s = new_clef(param)
			if (s)
				get_clef(s)
		}
		return
	case "deco":
		deco_add(param)
		return
	case "linebreak":
		set_linebreak(param)
		return
	case "map":
		get_map(param)
		return
	case "maxsysstaffsep":
	case "sysstaffsep":
		if (parse.state == 3) {
			val = get_unit(param)
			if (isNaN(val)) {
				syntax(1, errs.bad_val, "%%" + cmd)
				return
			}
			par_sy.voices[curvoice.v][cmd[0] == 'm' ? "maxsep" : "sep"] =
					val
			return
		}
		break
	case "multicol":
		switch (param) {
		case "start":
		case "new":
		case "end":
			break
		default:
			syntax(1, "Unknown keyword '$1' in %%multicol", param)
			return
		}
		s = {
			type: C.BLOCK,
			subtype: "mc_" + param,
			dur: 0
		}
		if (parse.state >= 2) {
			if (curvoice.clone)
				do_cloning()
			curvoice = voice_tb[0]
			curvoice.eoln = 1 //true
			sym_link(s)
			return
		}
		set_ref(s)
		self.block_gen(s)
		return
	case "ottava":
		if (parse.state != 3)
			return
		n = parseInt(param)
		if (isNaN(n) || n < -2 || n > 2
		 || (!n && !curvoice.ottava)) {
			syntax(1, errs.bad_val, "%%ottava")
			return
		}
		k = n
		if (n) {
			curvoice.ottava = n
		} else {
			n = curvoice.ottava
			curvoice.ottava = 0
		}
		a_dcn.push(["15mb", "8vb", "", "8va", "15ma"][n + 2]
			+ (k ? '(' : ')'))
		return
	case "repbra":
		if (curvoice)
			curvoice.norepbra = !get_bool(param)
		return
	case "repeat":
		if (parse.state != 3)
			return
		if (!curvoice.last_sym) {
			syntax(1, "%%repeat cannot start a tune")
			return
		}
		if (!param.length) {
			n = 1;
			k = 1
		} else {
			b = param.split(/\s+/);
			n = parseInt(b[0]);
			k = parseInt(b[1])
			if (isNaN(n) || n < 1
			 || (curvoice.last_sym.type == C.BAR
			  && n > 2)) {
				syntax(1, "Incorrect 1st value in %%repeat")
				return
			}
			if (isNaN(k)) {
				k = 1
			} else {
				if (k < 1) {
					syntax(1, "Incorrect 2nd value in %%repeat")
					return
				}
			}
		}
		parse.repeat_n = curvoice.last_sym.type == C.BAR ? n : -n;
		parse.repeat_k = k
		return
	case "sep":
		var	h2, len, values, lwidth;

		set_page();
		lwidth = img.width - img.lm - img.rm;
		h1 = h2 = len = 0
		if (param) {
			values = param.split(/\s+/);
			h1 = get_unit(values[0])
			if (values[1]) {
				h2 = get_unit(values[1])
				if (values[2])
					len = get_unit(values[2])
			}
			if (isNaN(h1) || isNaN(h2) || isNaN(len)) {
				syntax(1, errs.bad_val, "%%sep")
				return
			}
		}
		if (h1 < 1)
			h1 = 14
		if (h2 < 1)
			h2 = h1
		if (len < 1)
			len = 90
		if (parse.state >= 2) {
			if (curvoice.clone)
				do_cloning()
			s = new_block(cmd);
			s.x = (lwidth - len) / 2 / cfmt.scale;
			s.l = len / cfmt.scale;
			s.sk1 = h1;
			s.sk2 = h2
			return
		}
		vskip(h1);
		output += '<path class="stroke"\n\td="M';
		out_sxsy((lwidth - len) / 2 / cfmt.scale, ' ', 0);
		output += 'h' + (len / cfmt.scale).toFixed(1) + '"/>\n';
		vskip(h2);
		blk_flush()
		return
	case "setbarnb":
		val = parseInt(param)
		if (isNaN(val) || val < 1) {
			syntax(1, "Bad %%setbarnb value")
			break
		}
		glovar.new_nbar = val
		return
	case "staff":
		if (parse.state != 3)
			return
		if (curvoice.clone)
			do_cloning()
		val = parseInt(param)
		if (isNaN(val)) {
			syntax(1, "Bad %%staff value '$1'", param)
			return
		}
		var st
		if (param[0] == '+' || param[0] == '-')
			st = curvoice.cst + val
		else
			st = val - 1
		if (st < 0 || st > nstaff) {
			syntax(1, "Bad %%staff number $1 (cur $2, max $3)",
					st, curvoice.cst, nstaff)
			return
		}
		delete curvoice.floating;
		curvoice.cst = st
		return
	case "staffbreak":
		if (parse.state != 3)
			return
		if (curvoice.clone)
			do_cloning()
		s = {
			type: C.STBRK,
			dur:0
		}
		if (param.slice(-1) == 'f') {
			s.stbrk_forced = true
			param = param.replace(/\sf$/, '')
		}
		if (param) {
			val = get_unit(param)
			if (isNaN(val)) {
				syntax(1, errs.bad_val, "%%staffbreak")
				return
			}
			s.xmx = val
		} else {
			s.xmx = 14
		}
		sym_link(s)
		return
	case "tacet":
		if (param[0] == '"')
			param = param.slice(1, -1)
		// fall thru
	case "stafflines":
	case "staffscale":
	case "staffnonote":
		set_v_param(cmd, param)
		return
	case "staves":
	case "score":
		if (!parse.state)
			return
		if (parse.scores && parse.scores.length > 0) {
			text = parse.scores.shift();
			cmd = text.match(/([^\s]+)\s*(.*)/);
			param = cmd[2]
			cmd = cmd[1]
		}
		get_staves(cmd, param)
		return
	case "center":
	case "text":
		k = cmd[0] == 'c' ? 'c' : cfmt.textoption
		set_font("text")
		if (parse.state >= 2) {
			if (curvoice.clone)
				do_cloning()
			s = new_block("text")
			s.text = param
			s.opt = k
			s.font = cfmt.textfont
			return
		}
		write_text(param, k)
		return
	case "transpose":		// (abcm2ps compatibility)
		if (cfmt.sound)
			return
		val = get_transp(param)
		if (val == undefined) {		// accept note interval
			val = get_interval(param)
			if (val == undefined)
				return
		}
		switch (parse.state) {
		case 0:
			cfmt.transp = 0
			// fall thru
		case 1:
			cfmt.transp = (cfmt.transp || 0) + val
			return
		}
		curvoice.shift = val
		key_trans()
		return
	case "tune":
//fixme: to do
		return
	case "user":
		set_user(param)
		return
	case "voicecolor":
		if (curvoice)
			curvoice.color = param
		return
	case "vskip":
		val = get_unit(param)
		if (isNaN(val)) {
			syntax(1, errs.bad_val, "%%vskip")
			return
		}
		if (val < 0) {
			syntax(1, "%%vskip cannot be negative")
			return
		}
		if (parse.state >= 2) {
			if (curvoice.clone)
				do_cloning()
			s = new_block(cmd);
			s.sk = val
			return
		}
		vskip(val);
		return
	case "newpage":
	case "leftmargin":
	case "rightmargin":
	case "pagescale":
	case "pagewidth":
	case "printmargin":
	case "scale":
	case "staffwidth":
		if (parse.state >= 2) {
			if (curvoice.clone)
				do_cloning()
			s = new_block(cmd);
			s.param = param
			return
		}
		if (cmd == "newpage") {
			blk_flush()
			if (user.page_format)
				blkdiv = 2	// start the next SVG in a new page
			return
		}
		break
	}
	self.set_format(cmd, param)
}

// treat the %%beginxxx / %%endxxx sequences
// (possible hook)
Abc.prototype.do_begin_end = function(type,
			opt,
			text) {
	var i, j, action, s

	if (curvoice && curvoice.clone)
		do_cloning()
	switch (type) {
	case "js":
		js_inject(text)
		break
	case "ml":
		if (cfmt.pageheight) {
			syntax(1, "Cannot have %%beginml with %%pageheight")
			break
		}
		if (parse.state >= 2) {
			s = new_block(type);
			s.text = text
		} else {
			blk_flush()
			if (user.img_out)
				user.img_out(text)
		}
		break
	case "svg":
		j = 0
		while (1) {
			i = text.indexOf('<style', j)
			if (i < 0)
				break
			i = text.indexOf('>', i)
			j = text.indexOf('</style>', i)
			if (j < 0) {
				syntax(1, "No </style> in %%beginsvg sequence")
				break
			}
			s = text.slice(i + 1, j).replace(/\s+$/gm, '')
			if (cfmt.fullsvg) {
				i = s.match(/@font-face[^}]*}/)
				if (i && i[0].indexOf("text") > 0) {
					ff.text = "\n"
						+ i[0]	// assume only one @font-face
					s = s.replace(i[0], '')
				}
			}
			if (s && s != "\n")
				style += s
		}
		j = 0
		while (1) {
			i = text.indexOf('<defs>\n', j)
			if (i < 0)
				break
			j = text.indexOf('</defs>', i)
			if (j < 0) {
				syntax(1, "No </defs> in %%beginsvg sequence")
				break
			}
			defs_add(text.slice(i + 6, j))
		}
		break
	case "text":
		action = get_textopt(opt);
		if (!action)
			action = cfmt.textoption
		set_font("text")
		if (text.indexOf('\\') >= 0)
			text = cnv_escape(text)
		if (parse.state > 1) {
			s = new_block(type);
			s.text = text
			s.opt = action
			s.font = cfmt.textfont
			break
		}
		write_text(text, action)
		break
	}
}

/* -- generate a piece of tune -- */
function generate() {
    var s, v, p_voice;

	if (a_dcn.length) {
		syntax(1, "Decoration(s) without symbol: $1", a_dcn)
		a_dcn = []
	}

	if (parse.tp) {
		syntax(1, "No end of tuplet")
		s = parse.tps
		if (s)
			delete s.tp
		delete parse.tp
	}

	if (vover) {
		syntax(1, "No end of voice overlay");
		get_vover(vover.bar ? '|' : ')')
	}

	self.voice_adj()
	sort_all()			/* define the time / vertical sequences */

    if (tsfirst) {
	for (v = 0; v < voice_tb.length; v++) {
		if (!voice_tb[v].key)
			voice_tb[v].key = parse.ckey	// set the starting key
	}
	if (user.anno_start)
		anno_start = a_start
	if (user.anno_stop)
		anno_stop = a_stop
	self.set_bar_num()

	if (info.P)
		tsfirst.parts = info.P	// for play

	// give the parser result to the application
	if (user.get_abcmodel)
		user.get_abcmodel(tsfirst, voice_tb, abc2svg.sym_name, info)

	if (user.img_out)		// if SVG generation
		self.output_music()
    } // (tsfirst)

	// finish the generation
	set_page()			// the page layout may have changed
	if (info.W)
		put_words(info.W)
	put_history()
	parse.state = 0			// file header
	blk_flush()			// (force end of block)

	if (tsfirst) {		// if non void, keep tune data for upper layers
		tunes.push([tsfirst, voice_tb, info, cfmt])
		tsfirst = null
	}
}

// transpose the current key of the voice (called on K: or V:)
function key_trans() {
    var	i, n, a_acc, b40, d,
	s = curvoice.ckey,			// current key
	ti = s.time || 0

	if (s.k_bagpipe || s.k_drum)
		return				// no transposition

	// set the score transposition
	n = (curvoice.score | 0)		// new transposition
		+ (curvoice.shift | 0)
		+ (cfmt.transp | 0)
	if ((curvoice.tr_sco | 0) == n) {	// if same transposition
		s.k_sf = curvoice.ckey.k_sf
		return
	}

	// get the current key or create a new one
	if (is_voice_sig()) {			// if no symbol yet
		curvoice.key = s		// new root key of the voice
	} else if (curvoice.time != ti) {	// if no K: at this time
		s = clone(s.orig || s)		// new key
		if (!curvoice.new)
			s.k_old_sf = curvoice.ckey.k_sf
		sym_link(s)
	}
	curvoice.ckey = s			// current key

	if (cfmt.transp && curvoice.shift)	// if %%transpose and shift=
		syntax(0, "Mix of old and new transposition syntaxes");

	// define the new key
	curvoice.tr_sco = n			// b40 interval

	n = abc2svg.b40l5[(n + 202) % 40]	// transpose in the line of fifth
		+ s.orig.k_sf			// + old = new sf
	if (n < -7) {
		n += 12
		curvoice.tr_sco -= 4
	} else if (n > 7) {
		n -= 12
		curvoice.tr_sco += 4
	}
	if (!s.k_none)
		s.k_sf = n
	for (b40 = 0; b40 < 40; b40++) {
		if (abc2svg.b40l5[b40] == n)
			break
	}
	s.k_b40 = b40

	// transpose the accidental list
	if (!s.k_a_acc)
		return
	d = b40 - s.orig.k_b40
	a_acc = []
	for (i = 0; i < s.k_a_acc.length; i++) {
		b40 = abc2svg.pab40(s.k_a_acc[i].pit, s.k_a_acc[i].acc) + d
		a_acc[i] = {
			pit: abc2svg.b40p(b40),
			acc: abc2svg.b40a(b40) || 3
		}
	}
	s.k_a_acc = a_acc
}

// fill a voice with a multi-rest and a bar
function fill_mr_ba(p_v) {
    var	v, p_v2,
	mxt = 0

	for (v = 0; v < voice_tb.length; v++) {
		if (voice_tb[v].time > mxt) {
			p_v2 = voice_tb[v]
			mxt = p_v2.time
		}
	}
	if (p_v.time >= mxt)
		return

    var	p_v_sav = curvoice,
	dur = mxt - p_v.time,
	s = {
		type: C.MREST,
		stem: 0,
		multi: 0,
		nhd: 0,
		xmx: 0,
		frm: 1, //true			// full measure rest
		dur: dur,
		dur_orig: dur,
		nmes: dur / p_v.wmeasure,
		notes: [{
			pit: 18,
			dur: dur
		}],
		tacet: p_v.tacet
	},
	s2 = {
		type: C.BAR,
		bar_type: '|',
		dur: 0,
		multi: 0
	}

	if (p_v2.last_sym.bar_type)
		s2.bar_type = p_v2.last_sym.bar_type
//	s2.soln = p_v2.last_sym.soln

	glovar.mrest_p = 1 //true

	curvoice = p_v
	sym_link(s)
	sym_link(s2)

	curvoice = p_v_sav
} // fill_mr_ba()

/* -- get staves definition (%%staves / %%score) -- */
function get_staves(cmd, parm) {
    var	s, p_voice, p_voice2, i, flags, v, vid, a_vf, eoln,
	st, range,
	nv = voice_tb.length,
	maxtime = 0

	// if sequence with many voices, load the other voices
	if (curvoice && curvoice.clone) {
//		i = parse.eol
//		parse.eol = parse.bol		// remove the %%staves line
		do_cloning()
//		parse.eol = i
	}

	if (parm) {
		a_vf = parse_staves(parm)	// => array of [vid, flags]
		if (!a_vf)
			return
	} else if (staves_found < 0) {
		syntax(1, errs.bad_val, '%%' + cmd)
		return
	}

	/* create a new staff system */
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v]
		if (p_voice.eoln) {
			eoln = 1
			delete p_voice.eoln
		}
		if (p_voice.time > maxtime)
			maxtime = p_voice.time
	}
	if (!maxtime) {				// if first %%staves
		par_sy.staves = []
		par_sy.voices = []
	} else {
//		if (nv)					// if many voices
		self.voice_adj(1)

		// synchronize the voices
		for (v = 0; v < nv; v++) {
			p_voice = voice_tb[v]
//fixme: does not work if measure bar and %%staves delta time < measure duration
			if (maxtime - p_voice.time >= p_voice.meter.wmeasure)
				p_voice.acc = []	// no accidental anymore
			p_voice.time = maxtime
			p_voice.lyric_restart = p_voice.last_sym
			p_voice.sym_restart = p_voice.last_sym
		}

		/*
		 * create a new staff system and
		 * link the 'staves' symbol in a voice which is seen from
		 * the previous system - see sort_all
		 */
	   if (!par_sy.voices[curvoice.v])
		for (v = 0; v < par_sy.voices.length; v++) {
			if (par_sy.voices[v]) {
				curvoice = voice_tb[v]
				break
			}
		}

		curvoice.eoln = eoln
		s = {
			type: C.STAVES,
			dur: 0
		}

		sym_link(s);		// link the staves in this voice
		par_sy.nstaff = nstaff;

		// if no parameter, duplicate the current staff system
		if (!parm) {
			s.sy = clone(par_sy, 2)		// clone the staves and voices
			par_sy.next = s.sy
			par_sy = s.sy
			staves_found = maxtime
			curvoice = voice_tb[par_sy.top_voice]
			return
		}

		new_syst();
		s.sy = par_sy
	}

	staves_found = maxtime

	/* initialize the (old) voices */
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v]
		delete p_voice.second
		delete p_voice.floating
		if (p_voice.ignore) {
			p_voice.ignore = 0 //false
			s = p_voice.sym
			if (s) {
				while (s.next)
					s = s.next
			}
			p_voice.last_sym = s	// set back the last symbol
		}
	}
	range = 0
	for (i = 0; i < a_vf.length; i++) {
		vid = a_vf[i][0];
		p_voice = new_voice(vid);
		v = p_voice.v

		a_vf[i][0] = p_voice;

		// set the range and add the overlay voices
		while (1) {
			par_sy.voices[v] = {
				range: range++
			}
			p_voice = p_voice.voice_down
			if (!p_voice)
				break
			v = p_voice.v
		}
	}
	par_sy.top_voice = a_vf[0][0].v
	if (a_vf.length == 1)
		par_sy.one_v = 1 //true			// one voice

	/* change the behavior from %%staves to %%score */
	if (cmd[1] == 't') {				/* if %%staves */
		for (i = 0; i < a_vf.length; i++) {
			flags = a_vf[i][1]
			if (!(flags & (OPEN_BRACE | OPEN_BRACE2)))
				continue
			if ((flags & (OPEN_BRACE | CLOSE_BRACE))
					== (OPEN_BRACE | CLOSE_BRACE)
			 || (flags & (OPEN_BRACE2 | CLOSE_BRACE2))
					== (OPEN_BRACE2 | CLOSE_BRACE2))
				continue
			if (a_vf[i + 1][1] != 0)
				continue
			if ((flags & OPEN_PARENTH)
			 || (a_vf[i + 2][1] & OPEN_PARENTH))
				continue

			/* {a b c} -> {a *b c} */
			if (a_vf[i + 2][1] & (CLOSE_BRACE | CLOSE_BRACE2)) {
				a_vf[i + 1][1] |= FL_VOICE

			/* {a b c d} -> {(a b) (c d)} */
			} else if (a_vf[i + 2][1] == 0
				&& (a_vf[i + 3][1]
					& (CLOSE_BRACE | CLOSE_BRACE2))) {
				a_vf[i][1] |= OPEN_PARENTH;
				a_vf[i + 1][1] |= CLOSE_PARENTH;
				a_vf[i + 2][1] |= OPEN_PARENTH;
				a_vf[i + 3][1] |= CLOSE_PARENTH
			}
		}
	}

	/* set the staff system */
	st = -1
	for (i = 0; i < a_vf.length; i++) {
		flags = a_vf[i][1]
		if ((flags & (OPEN_PARENTH | CLOSE_PARENTH))
				== (OPEN_PARENTH | CLOSE_PARENTH)) {
			flags &= ~(OPEN_PARENTH | CLOSE_PARENTH);
			a_vf[i][1] = flags
		}
		p_voice = a_vf[i][0]
		if (flags & FL_VOICE) {
			p_voice.floating = true;
			p_voice.second = true
		} else {
			st++;
			if (!par_sy.staves[st]) {
				par_sy.staves[st] = {
					staffscale: 1
				}
			}
			par_sy.staves[st].stafflines = p_voice.stafflines || "|||||",
			par_sy.staves[st].flags = 0
		}
		v = p_voice.v;
		p_voice.st = p_voice.cst =
				par_sy.voices[v].st = st;
		par_sy.staves[st].flags |= flags
		if (flags & OPEN_PARENTH) {
			p_voice2 = p_voice
			while (i < a_vf.length - 1) {
				p_voice = a_vf[++i][0];
				v = p_voice.v
				if (a_vf[i][1] & MASTER_VOICE) {
					p_voice2.second = true
					p_voice2 = p_voice
				} else {
					p_voice.second = true;
				}
				p_voice.st = p_voice.cst
						= par_sy.voices[v].st
						= st
				if (a_vf[i][1] & CLOSE_PARENTH)
					break
			}
			par_sy.staves[st].flags |= a_vf[i][1]
		}
	}
	if (st < 0)
		st = 0
	par_sy.nstaff = nstaff = st

	/* change the behaviour of '|' in %%score */
	if (cmd[1] == 'c') {				/* if %%score */
		for (st = 0; st < nstaff; st++)
			par_sy.staves[st].flags ^= STOP_BAR
	}

	nv = voice_tb.length
	st = 0
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v]
		if (par_sy.voices[v])
			st = p_voice.st
		else
			p_voice.st = st	// (this avoids later crashes)

		// if first %%staves
		// update the staff of the symbols with no time
		if (!maxtime) {
			for (s = p_voice.sym; s; s = s.next)
				s.st = st
		}

		if (!par_sy.voices[v])
			continue

		// set the staff of the overlay voices
		p_voice2 = p_voice.voice_down
		while (p_voice2) {
			p_voice2.second = 1 //true
			i = p_voice2.v
			p_voice2.st = p_voice2.cst =
					par_sy.voices[i].st = st
			p_voice2 = p_voice2.voice_down
		}

		par_sy.voices[v].second = p_voice.second;
		st = p_voice.st
		if (st > 0 && p_voice.norepbra == undefined
		 && !(par_sy.staves[st - 1].flags & STOP_BAR))
			p_voice.norepbra = true
	}

	curvoice = parse.state >= 2 ? voice_tb[par_sy.top_voice] : null
}

	// get a voice or create a clone of the current voice
	function clone_voice(id) {
		var v, p_voice

		for (v = 0; v < voice_tb.length; v++) {
			p_voice = voice_tb[v]
			if (p_voice.id == id)
				return p_voice		// found
		}
		p_voice = clone(curvoice);
		p_voice.v = voice_tb.length;
		p_voice.id = id;
		p_voice.sym = p_voice.last_sym = null;

		p_voice.key = clone(curvoice.key)
		p_voice.sls = []

		delete p_voice.nm
		delete p_voice.snm
		delete p_voice.new_name
		delete p_voice.lyric_restart
		delete p_voice.lyric_cont
		delete p_voice.sym_restart
		delete p_voice.sym_cont
		delete p_voice.have_ly
		delete p_voice.tie_s

		voice_tb.push(p_voice)
		return p_voice
	} // clone_voice()

/* -- get a voice overlay -- */
function get_vover(type) {
    var	p_voice2, p_voice3, range, s, time, v, v2, v3, s2

	/* treat the end of overlay */
	if (type == '|'
	 || type == ')')  {
		if (!curvoice.last_note) {
			syntax(1, errs.nonote_vo)
			if (vover) {
				curvoice = vover.p_voice
				vover = null
			}
			return
		}
		curvoice.last_note.beam_end = true
		if (!vover) {
			syntax(1, "Erroneous end of voice overlay")
			return
		}
		if (curvoice.time != vover.p_voice.time) {
		    if (!curvoice.ignore)
			syntax(1, "Wrong duration in voice overlay");
			if (curvoice.time > vover.p_voice.time)
				vover.p_voice.time = curvoice.time
		}
		curvoice.acc = []		// no accidental anymore

		// if the last symbols are spaces, move them to the main voice
		p_voice2 = vover.p_voice	// main voice
		s = curvoice.last_sym
		if (s.type == C.SPACE && p_voice2.last_sym.type != C.SPACE) {
			s.p_v = p_voice2
			s.v = s.p_v.v
			while (s.prev.type == C.SPACE) {
				s = s.prev
				s.p_v = p_voice2
				s.v = s.p_v.v
			}
			s2 = s.prev
			s2.next = null
			s.prev = p_voice2.last_sym
			s.prev.next = s
			p_voice2.last_sym = curvoice.last_sym
			curvoice.last_sym = s2
		}

		curvoice = p_voice2
		vover = null
		return
	}

	/* treat the full overlay start */
	if (type == '(') {
		if (vover) {
			syntax(1, "Voice overlay already started")
			return
		}
		vover = {
			p_voice: curvoice,
			time: curvoice.time
		}
		return
	}

	/* (here is treated a new overlay - '&') */
	/* create the extra voice if not done yet */
	if (!curvoice.last_note) {
		syntax(1, errs.nonote_vo)
		return
	}
	curvoice.last_note.beam_end = true;
	p_voice2 = curvoice.voice_down
	if (!p_voice2) {
		p_voice2 = clone_voice(curvoice.id + 'o');
		curvoice.voice_down = p_voice2;
		p_voice2.time = 0;
		p_voice2.second = true;
		p_voice2.last_note = null
		v2 = p_voice2.v;
	    if (par_sy.voices[curvoice.v]) {	// if voice in the staff system
		par_sy.voices[v2] = {
			st: curvoice.st,
			second: true
		}
		range = par_sy.voices[curvoice.v].range
		for (v = 0; v < par_sy.voices.length; v++) {
			if (par_sy.voices[v]
			 && par_sy.voices[v].range > range)
				par_sy.voices[v].range++
		}
		par_sy.voices[v2].range = range + 1
	    }
	}
	p_voice2.ulen = curvoice.ulen
	p_voice2.dur_fact = curvoice.dur_fact
	p_voice2.acc = []			// no accidental

	if (!vover) {				/* first '&' in a measure */
		time = p_voice2.time
	    if (curvoice.ignore)
		s = curvoice.last_bar
	    else
		for (s = curvoice.last_sym; s; s = s.prev) {
			if (s.type == C.BAR
			 || s.time <= time)	/* (if start of tune) */
				break
		}
		vover = {
			bar: (s && s.bar_type) ? s.bar_type : '|',
			p_voice: curvoice,
			time: s ? s.time : curvoice.time
		}
	} else {
		if (curvoice != vover.p_voice
		 && curvoice.time != vover.p_voice.time) {
			syntax(1, "Wrong duration in voice overlay")
			if (curvoice.time > vover.p_voice.time)
				vover.p_voice.time = curvoice.time
		}
	}
	p_voice2.time = vover.time;
	curvoice = p_voice2
}

// check if a clef, key or time signature may go at start of the current voice
function is_voice_sig() {
	var s

	if (curvoice.time)
		return false
	if (!curvoice.last_sym)
		return true
	for (s = curvoice.last_sym; s; s = s.prev)
		if (w_tb[s.type])
			return false
	return true
}

// treat a clef found in the tune body
function get_clef(s) {
    var	s2, s3

	// special case for percussion
	if (s.clef_type == 'p') {		// if percussion clef
		s2 = curvoice.ckey
		s2.k_drum = 1 //true
		s2.k_sf = 0
		s2.k_b40 = 2
		s2.k_map = abc2svg.keys[7]
		if (!curvoice.key)
			curvoice.key = s2	// new root key
	}

	if (!curvoice.time		// (force a clef when new voice)
	 && is_voice_sig()) {
		curvoice.clef = s
		s.fmt = cfmt
		return
	}

	// if not clef=none,
	// move the clef before a key and/or a (not right repeat) bar
    if (s.clef_none)
	s2 = null
    else
	for (s2 = curvoice.last_sym;
	     s2 && s2.time == curvoice.time;
	     s2 = s2.prev) {
		if (w_tb[s2.type])
			break
	}
	if (s2
	 && s2.time == curvoice.time		// if no time skip
	 && s2.k_sf != undefined) {
		s3 = s2				// move before a key signature
		s2 = s2.prev
	}
	if (s2
	 && s2.time == curvoice.time
	 && s2.bar_type && s2.bar_type[0] != ':')
		s3 = s2				// move before a measure bar
	if (s3) {
		s2 = curvoice.last_sym
		curvoice.last_sym = s3.prev
		sym_link(s)
		s.next = s3
		s3.prev = s
		curvoice.last_sym = s2
		if (s.soln) {
			delete s.soln
			curvoice.eoln = true
		}
	} else {
		sym_link(s)
	}
}

// treat K: (kp = key signature + parameters)
function get_key(parm) {
    var	v, p_voice,
//		[s_key, a] = new_key(parm)	// KO with nodejs
		a = new_key(parm),
		s_key = a[0],
		s = s_key,
		empty = s.k_sf == undefined && !s.k_a_acc

	a = a[1]

	if (empty)
		s.invis = 1 //true		// don't display empty K:
	else
		s.orig = s			// new transposition base

	if (parse.state == 1) {			// in tune header (first K:)
		parse.ckey = s			// root key
		if (empty) {
			s_key.k_sf = 0;
			s_key.k_none = true
			s_key.k_map = abc2svg.keys[7]
		}
		for (v = 0; v < voice_tb.length; v++) {
			p_voice = voice_tb[v];
			p_voice.ckey = clone(s_key)
		}
		if (a.length) {
			memo_kv_parm('*', a)
			a = []
		}
		if (!glovar.ulen)
			glovar.ulen = C.BLEN / 8;
		goto_tune()
	} else if (!empty) {
		if (curvoice.tr_sco)
			curvoice.tr_sco = undefined
		s.k_old_sf = curvoice.ckey.k_sf	// memorize the previous key
		curvoice.ckey = s
		sym_link(s)
	}

	// set the voice parameters
	if (!curvoice) {			// if first K:
		if (!voice_tb.length) {
			curvoice = new_voice("1")
		    var	def = 1 // true
		} else {
			curvoice = voice_tb[staves_found < 0 ? 0 : par_sy.top_voice]
		}
	}

	p_voice = curvoice.clone
	if (p_voice)
		curvoice.clone = null		// don't stop the multi-voice sequence
	get_voice(curvoice.id + ' ' + a.join(' '))
	if (p_voice)
		curvoice.clone = p_voice

	if (def)
		curvoice.default = 1 //true
}

// get / create a new voice
function new_voice(id) {
    var	v, p_v_sav,
	p_voice = voice_tb[0],
	n = voice_tb.length

	// if first explicit voice and no music, replace the default V:1
	if (n == 1
	 && p_voice.default) {
		delete p_voice.default
		if (!p_voice.time) {		// if no symbol yet
			p_voice.id = id
			p_voice.init = 0	// set back the global voice parameters
			return p_voice		// default voice
		}
	}
	for (v = 0; v < n; v++) {
		p_voice = voice_tb[v]
		if (p_voice.id == id)
			return p_voice		// old voice
	}

	p_voice = {
		v: v,
		id: id,
		time: staves_found >= 0 ? staves_found : 0,
		new: true,
		pos: {
//			dyn: 0,
//			gch: 0,
//			gst: 0,
//			orn: 0,
//			stm: 0,
//			tup: 0,
//			voc: 0,
//			vol: 0
		},
		scale: 1,
//		st: 0,
//		cst: 0,
		ulen: glovar.ulen,
		dur_fact: 1,
//		key: clone(parse.ckey),		// key at start of tune (parse / gene)
//		ckey: clone(parse.ckey),	// current key (parse / gene)
		meter: clone(glovar.meter),
		wmeasure: glovar.meter.wmeasure,
		staffnonote: 1,
		clef: {
			type: C.CLEF,
			clef_auto: true,
			clef_type: "a",		// auto
			time: 0
		},
		acc: [],		// accidentals of the measure (parse)
		sls: [],		// slurs - used in parsing and in generation
		hy_st: 0
	}

	voice_tb.push(p_voice);

	if (parse.state == 3) {
//		p_voice.key = parse.ckey	// (done later in music.js)
		p_voice.ckey = clone(parse.ckey)
		if (p_voice.ckey.k_bagpipe
		 && !p_voice.pos.stm) {
			p_voice.pos = clone(p_voice.pos)
			p_voice.pos.stm &= ~0x07
			p_voice.pos.stm |= C.SL_BELOW
		}
	}
	
//	par_sy.voices[v] = {
//		range: -1
//	}

	return p_voice
}

// this function is called at program start and on end of tune
function init_tune() {
	nstaff = -1;
	voice_tb = [];
	curvoice = null;
	new_syst(true);
	staves_found = -1;
	gene = {}
	a_de = []			// remove old decorations
	cross = {}			// new cross voice decorations
}

// treat V: with many voices
function do_cloning() {
    var	i,
	clone = curvoice.clone,
	vs = clone.vs,
	a = clone.a,
	bol = clone.bol,
	eol = parse.bol,
	parse_sav = parse,
	file = parse.file

	delete curvoice.clone

	if (file[eol - 1] == '[')	// if stop on [V:xx]
		eol--

	// insert the music sequence in each voice
	include++;
	for (i = 0; i < vs.length; i++) {
		parse = Object.create(parse_sav) // create a new parse context
		parse.line = Object.create(parse_sav.line)
		get_voice(vs[i] + ' ' + a.join(' '))
		tosvg(parse.fname, file, bol, eol)
	}
	include--
	parse = parse_sav	// restore the parse context
}

// treat a 'V:' info
function get_voice(parm) {
    var	v, vs,
	a = info_split(parm),
	vid = a.shift()

	if (!vid)
		return				// empty V:

	// if end of sequence with many voices, load the other voices
	if (curvoice && curvoice.clone)
		do_cloning()

	if (vid.indexOf(',') > 0)		// if many voices
		vs = vid.split(',')
	else
		vs = [vid]

	if (parse.state < 2) {			// memorize the voice parameters
		while (1) {
			vid = vs.shift()
			if (!vid)
				break
			if (a.length)
				memo_kv_parm(vid, a)
			if (vid != '*' && parse.state == 1)
				curvoice = new_voice(vid)
		}
		return
	}

	if (vid == '*') {
		syntax(1, "Cannot have V:* in tune body")
		return
	}

	curvoice = new_voice(vs[0])

	// if many voices, memorize the start of sequence
	if (vs.length > 1) {
		vs.shift()
		curvoice.clone = {
			vs: vs,
			a: a.slice(0),		// copy the parameters
			bol: parse.iend
		}
		if (parse.file[curvoice.clone.bol - 1] != ']')
			curvoice.clone.bol++	// start of new line
	}

	set_kv_parm(a)

	key_trans()

	v = curvoice.v
	if (curvoice.new) {			// if new voice
		delete curvoice.new
		if (staves_found < 0) {		// if no %%score/%%staves
			curvoice.st = curvoice.cst = ++nstaff;
			par_sy.nstaff = nstaff;
			par_sy.voices[v] = {
				st: nstaff,
				range: v
			}
			par_sy.staves[nstaff] = {
				stafflines: curvoice.stafflines || "|||||",
				staffscale: 1
			}
		} else if (!par_sy.voices[v]) {
			curvoice.ignore = 1	// voice not declared in %%staves
			return
		}
	}

	if (!curvoice.filtered
	 && par_sy.voices[v]
	 && (parse.voice_opts
	  || parse.tune_v_opts)) {
		curvoice.filtered = true;
		voice_filter()
	}
}

// change state from 'tune header' to 'in tune body'
// curvoice is defined when called from get_voice()
function goto_tune() {
    var	v, p_voice

	set_page();
	write_heading();
	blk_flush()				// tune heading in a specific SVG

	if (glovar.new_nbar) {
		gene.nbar = glovar.new_nbar	// measure numbering
		glovar.new_nbar = 0
	} else {
		gene.nbar = 1
	}

	parse.state = 3				// in tune body

	// update some voice parameters
	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v];
		p_voice.ulen = glovar.ulen
		if (parse.ckey.k_bagpipe
		 && !p_voice.pos.stm) {
			p_voice.pos = clone(p_voice.pos)
			p_voice.pos.stm &= ~0x07
			p_voice.pos.stm |= C.SL_BELOW
		}
	}

	// initialize the voices when no %%staves/score	
	if (staves_found < 0) {
		v = voice_tb.length
		par_sy.nstaff =
			nstaff = v - 1
		while (--v >= 0) {
			p_voice = voice_tb[v];
			delete p_voice.new;		// old voice
			p_voice.st = p_voice.cst = v;
			par_sy.voices[v] = {
				st: v,
				range: v
			}
			par_sy.staves[v] = {
				stafflines: p_voice.stafflines || "|||||",
				staffscale: 1
			}
		}
	}
}
// abc2svg - lyrics.js - lyrics
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

// parse a symbol line (s:)
function get_sym(p, cont) {
	var s, c, i, j, d

	if (curvoice.ignore)
		return

	// get the starting symbol of the lyrics
	if (cont) {					// +:
		s = curvoice.sym_cont
		if (!s) {
			syntax(1, "+: symbol line without music")
			return
		}
	} else {
		if (curvoice.sym_restart) {		// new music
			curvoice.sym_start = curvoice.sym_restart;
			curvoice.sym_restart = null
		}
		s = curvoice.sym_start
		if (!s)
			s = curvoice.sym
		if (!s) {
			syntax(1, "s: without music")
			return
		}
	}

	/* scan the symbol line */
	i = 0
	while (1) {
		while (p[i] == ' ' || p[i] == '\t')
			i++;
		c = p[i]
		if (!c)
			break
		switch (c) {
		case '|':
			while (s && s.type != C.BAR)
				s = s.next
			if (!s) {
				syntax(1, "Not enough measure bars for symbol line")
				return
			}
			s = s.next;
			i++
			continue
		case '!':
		case '"':
			j = ++i
			i = p.indexOf(c, j)
			if (i < 0) {
				syntax(1, c == '!' ?
					"No end of decoration" :
					"No end of chord symbol/annotation");
				i = p.length
				continue
			}
			d = p.slice(j - 1, i + 1)
			break
		case '*':
			break
		default:
			d = c.charCodeAt(0)
			if (d < 128) {
				d = char_tb[d]
				if (d.length > 1
				 && (d[0] == '!' || d[0] == '"')) {
					c = d[0]
					break
				}
			}
			syntax(1, errs.bad_char, c)
			break
		}

		/* store the element in the next note */
		while (s && s.type != C.NOTE)
			s = s.next
		if (!s) {
			syntax(1, "Too many elements in symbol line")
			return
		}
		switch (c) {
		default:
//		case '*':
			break
		case '!':
			a_dcn.push(d.slice(1, -1))
			deco_cnv(s, s.prev)
			break
		case '"':
			parse.line.index = j + 2	// (+ 's:')
			parse_gchord(d)
			if (a_gch)			// if no error
				csan_add(s)
			break
		}
		s = s.next;
		i++
	}
	curvoice.sym_cont = s
}

/* -- parse a lyric (vocal) line (w:) -- */
function get_lyrics(p, cont) {
    var s, word, i, j, ly, dfnt, ln, c, cf

	if (curvoice.ignore)
		return
	if ((curvoice.pos.voc & 0x07) != C.SL_HIDDEN)
		curvoice.have_ly = true

	// get the starting symbol of the lyrics
	if (cont) {					// +:
		s = curvoice.lyric_cont
		if (!s) {
			syntax(1, "+: lyric without music")
			return
		}
		if (p[0] == '~') {			// +:~next~words
			while (!s.a_ly)
				s = s.prev
			ly = s.a_ly[curvoice.lyric_line]
			p = ly.t.replace(/ /g,'~') + p
		}
		dfnt = get_font("vocal")
		if (gene.deffont != dfnt) {	// if vocalfont change
			if (gene.curfont == gene.deffont)
				gene.curfont = dfnt
			gene.deffont = dfnt
		}
	} else {
		set_font("vocal")
		if (curvoice.lyric_restart) {		// new music
			curvoice.lyric_start = s = curvoice.lyric_restart;
			curvoice.lyric_restart = null;
			curvoice.lyric_line = 0
		} else {
			curvoice.lyric_line++;
			s = curvoice.lyric_start
		}
		if (!s)
			s = curvoice.sym
		if (!s) {
			syntax(1, "w: without music")
			return
		}
	}

	/* scan the lyric line */
	i = 0
	cf = gene.curfont
	while (1) {
		while (p[i] == ' ' || p[i] == '\t')
			i++
		if (!p[i])
			break
		ln = 0
		j = parse.istart + i + 2	// start index
		switch (p[i]) { 
		case '|':
			while (s && s.type != C.BAR)
				s = s.next
			if (!s) {
				syntax(1, "Not enough measure bars for lyric line")
				return
			}
			s = s.next;
			i++
			continue
		case '-':
		case '_':
			word = p[i]
			ln = p[i] == '-' ? 2 : 3	// line continuation
			break
		case '*':
			word = ""
			break
		default:
			word = "";
			while (1) {
				if (!p[i])
					break
				switch (p[i]) {
				case '_':
				case '*':
				case '|':
					i--
				case ' ':
				case '\t':
					break
				case '~':
					word += ' '
					i++
					continue
				case '-':
					ln = 1		// start of line
					break
				case '\\':
					if (!p[++i])
						continue
					word += p[i++]
					continue
				case '$':
					word += p[i++]
					c = p[i]
					if (c == '0')
						gene.curfont = gene.deffont
					else if (c >= '1' && c <= '9')
						gene.curfont = get_font("u" + c)
					// fall thru
				default:
					word += p[i++]
					continue
				}
				break
			}
			break
		}

		/* store the word in the next note */
		while (s && s.type != C.NOTE)
			s = s.next
		if (!s) {
			syntax(1, "Too many words in lyric line")
			return
		}
		if (word
		 && (s.pos.voc & 0x07) != C.SL_HIDDEN) {
			ly = {
				t: word,
				font: cf,
				istart: j,
				iend: j + word.length
			}
			if (ln)
				ly.ln = ln
			if (!s.a_ly)
				s.a_ly = []
			s.a_ly[curvoice.lyric_line] = ly
			cf = gene.curfont
		}
		s = s.next;
		i++
	}
	curvoice.lyric_cont = s
}

// install the words under a note
// (this function is called during the generation)
function ly_set(s) {
    var	i, j, ly, d, s1, s2, p, w, spw, xx, sz, shift, dw, r,
	s3 = s,				// start of the current time sequence
	wx = 0,
	wl = 0,
	n = 0,
	dx = 0,
	a_ly = s.a_ly,
	align = 0

	// get the available horizontal space before the next lyric words
	for (s2 = s.ts_next; s2; s2 = s2.ts_next) {
		if (s2.seqst) {
			dx += s2.shrink
			n++			// number of symbols without word
		}
		if (s2.bar_type) {		// stop on a bar
			dx += 3			// and take some of its spacing
			break
		}
		if (!s2.a_ly)
			continue
		i = s2.a_ly.length
		while (--i >= 0) {
			ly = s2.a_ly[i]
			if (!ly)
				continue
			if (!ly.ln || ly.ln < 2)
				break
		}
		if (i >= 0)
			break
	}

	// define the offset of the words
	for (i = 0; i < a_ly.length; i++) {
		ly = a_ly[i]
		if (!ly)
			continue
		gene.curfont = ly.font
		ly.t = str2svg(ly.t)
		p = ly.t.replace(/<[^>]*>/g, '')	// remove the XML tags
		if (ly.ln >= 2) {
			ly.shift = 0
			continue
		}
		spw = cwid(' ') * ly.font.swfac
		w = ly.t.wh[0]
		r = abc2svg.lypre.exec(p)
		if (s.type == C.GRACE) {		// %%graceword
			shift = s.wl
		} else if (r) {
			r = r[0]
			if (p[0] == '(') {
				sz = spw
			} else {
				set_font(ly.font)
				if (p[r.length] == ' '
				 || r.slice(-1) == ':')
					sz = strwh(p.slice(0, r.length))[0]
				else
					sz = w * .2
			}
			shift = (w - sz) * .4
			if (shift > 14)
				shift = 14
			shift += sz
			if (p[0] >= '0' && p[0] <= '9') {
				if (shift > align)
					align = shift
			}
		} else {
			shift = w * .4
			if (shift > 14)
				shift = 14
		}
		ly.shift = shift
		if (shift > wl)
			wl = shift		// max left space
		w += spw * 1.5			// space after the syllable
		w -= shift			// right width
		if (w > wx)
			wx = w			// max width
	}

	// set the left space
	while (!s3.seqst)
		s3 = s3.ts_prev
	if (s3.ts_prev && s3.ts_prev.bar_type)
		wl -= 4			// don't move too much the measure bar
	if (s3.wl < wl) {
		s3.shrink += wl - s3.wl
		s3.wl = wl
	}

	// if not room enough, shift the following notes to the right
	dx -= 6
	if (dx < wx && s2) {
		dx = (wx - dx) / n
		s1 = s.ts_next
		while (1) {
			if (s1.seqst) {
				s1.shrink += dx
				s3.wr += dx	// (needed for end of line)
				s3 = s1
			}
			if (s1 == s2)
				break
			s1 = s1.ts_next
		}
	}

	if (align > 0) {
		for (i = 0; i < a_ly.length; i++) {
			ly = a_ly[i]
			if (ly && ly.t[0] >= '0' && ly.t[0] <= '9')
				ly.shift = align
		}
	}
} // ly_set()

/* -- draw the lyrics under (or above) notes -- */
/* (the staves are not yet defined) */
function draw_lyric_line(p_voice, j, y) {
	var	p, lastx, w, s, s2, ly, lyl, ln,
		hyflag, lflag, x0, shift

	if (p_voice.hy_st & (1 << j)) {
		hyflag = true;
		p_voice.hy_st &= ~(1 << j)
	}
	for (s = p_voice.sym; /*s*/; s = s.next)
		if (s.type != C.CLEF
		 && s.type != C.KEY && s.type != C.METER)
			break
	lastx = s.prev ? s.prev.x : tsfirst.x;
	x0 = 0
	for ( ; s; s = s.next) {
		if (s.a_ly)
			ly = s.a_ly[j]
		else
			ly = null
		if (!ly) {
			switch (s.type) {
			case C.REST:
			case C.MREST:
				if (lflag) {
					out_wln(lastx + 3, y, x0 - lastx);
					lflag = false;
					lastx = s.x + s.wr
				}
			}
			continue
		}
		if (ly.font != gene.curfont)		/* font change */
			gene.curfont = ly.font
		p = ly.t;
		ln = ly.ln || 0
		w = p.wh[0]
		shift = ly.shift
		if (hyflag) {
			if (ln == 3) {			// '_'
				ln = 2
			} else if (ln < 2) {		// not '-'
				out_hyph(lastx, y, s.x - shift - lastx);
				hyflag = false;
				lastx = s.x + s.wr
			}
		}
		if (lflag
		 && ln != 3) {				// not '_'
			out_wln(lastx + 3, y, x0 - lastx + 3);
			lflag = false;
			lastx = s.x + s.wr
		}
		if (ln >= 2) {				// '-' or '_'
			if (x0 == 0 && lastx > s.x - 18)
				lastx = s.x - 18
			if (ln == 2)			// '-'
				hyflag = true
			else
				lflag = true;
			x0 = s.x - shift
			continue
		}
		x0 = s.x - shift;
		if (ln)					// '-' at end
			hyflag = true
		if (user.anno_start || user.anno_stop) {
			s2 = {
				p_v: s.p_v,
				st: s.st,
				istart: ly.istart,
				iend: ly.iend,
				ts_prev: s,
				ts_next: s.ts_next,
				x: x0,
				y: y,
				ymn: y,
				ymx: y + gene.curfont.size,
				wl: 0,
				wr: w
			}
			anno_start(s2, 'lyrics')
		}
		xy_str(x0, y, p)
		anno_stop(s2, 'lyrics')
		lastx = x0 + w
	}
	if (hyflag) {
		hyflag = false;
		x0 = realwidth - 10
		if (x0 < lastx + 10)
			x0 = lastx + 10;
		out_hyph(lastx, y, x0 - lastx)
		if (p_voice.s_next && p_voice.s_next.fmt.hyphencont)
			p_voice.hy_st |= (1 << j)
	}

	/* see if any underscore in the next line */
	for (p_voice.s_next; s; s = s.next) {
		if (s.type == C.NOTE) {
			if (!s.a_ly)
				break
			ly = s.a_ly[j]
			if (ly && ly.ln == 3) {		 // '_'
				lflag = true;
				x0 = realwidth - 15
				if (x0 < lastx + 12)
					x0 = lastx + 12
			}
			break
		}
	}
	if (lflag) {
		out_wln(lastx + 3, y, x0 - lastx + 3);
		lflag = false
	}
}

function draw_lyrics(p_voice, nly, a_h, y,
				incr) {	/* 1: below, -1: above */
	var	j, top,
		sc = staff_tb[p_voice.st].staffscale;

	set_font("vocal")
	if (incr > 0) {				/* under the staff */
		if (y > -tsfirst.fmt.vocalspace)
			y = -tsfirst.fmt.vocalspace;
		y *= sc
		for (j = 0; j < nly; j++) {
			y -= a_h[j] * 1.1;
			draw_lyric_line(p_voice, j,
				y + a_h[j] * .22)	// (descent)
		}
		return y / sc
	}

	/* above the staff */
	top = staff_tb[p_voice.st].topbar + tsfirst.fmt.vocalspace
	if (y < top)
		y = top;
	y *= sc
	for (j = nly; --j >= 0;) {
		draw_lyric_line(p_voice, j, y + a_h[j] * .22)
		y += a_h[j] * 1.1
	}
	return y / sc
}

// -- draw all the lyrics --
/* (the staves are not yet defined) */
function draw_all_lyrics() {
	var	p_voice, s, v, nly, i, x, y, w, a_ly, ly,
		lyst_tb = new Array(nstaff + 1),
		nv = voice_tb.length,
		h_tb = new Array(nv),
		nly_tb = new Array(nv),
		above_tb = new Array(nv),
		rv_tb = new Array(nv),
		top = 0,
		bot = 0,
		st = -1

	/* compute the number of lyrics per voice - staff
	 * and their y offset on the staff */
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v]
		if (!p_voice.sym)
			continue
		if (p_voice.st != st) {
			top = 0;
			bot = 0;
			st = p_voice.st
		}
		nly = 0
		if (p_voice.have_ly) {
			if (!h_tb[v])
				h_tb[v] = []
			for (s = p_voice.sym; s; s = s.next) {
				a_ly = s.a_ly
				if (!a_ly)
					continue
/*fixme:should get the real width*/
				x = s.x;
				w = 10
				for (i = 0; i < a_ly.length; i++) {
					ly = a_ly[i]
					if (ly) {
						x -= ly.shift;
						w = ly.t.wh[0]
						break
					}
				}
				y = y_get(p_voice.st, 1, x, w)
				if (top < y)
					top = y;
				y = y_get(p_voice.st, 0, x, w)
				if (bot > y)
					bot = y
				while (nly < a_ly.length)
					h_tb[v][nly++] = 0
				for (i = 0; i < a_ly.length; i++) {
					ly = a_ly[i]
					if (!ly)
						continue
					if (!h_tb[v][i]
					 || ly.t.wh[1] > h_tb[v][i])
						h_tb[v][i] = ly.t.wh[1]
				}
			}
		} else {
			y = y_get(p_voice.st, 1, 0, realwidth)
			if (top < y)
				top = y;
			y = y_get(p_voice.st, 0, 0, realwidth)
			if (bot > y)
				bot = y
		}
		if (!lyst_tb[st])
			lyst_tb[st] = {}
		lyst_tb[st].top = top;
		lyst_tb[st].bot = bot;
		nly_tb[v] = nly
		if (nly == 0)
			continue
		if (p_voice.pos.voc)
			above_tb[v] = (p_voice.pos.voc & 0x07) == C.SL_ABOVE
		else if (voice_tb[v + 1]
/*fixme:%%staves:KO - find an other way..*/
		      && voice_tb[v + 1].st == st
		      && voice_tb[v + 1].have_ly)
			above_tb[v] = true
		else
			above_tb[v] = false
		if (above_tb[v])
			lyst_tb[st].a = true
		else
			lyst_tb[st].b = true
	}

	/* draw the lyrics under the staves */
	i = 0
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v]
		if (!p_voice.sym)
			continue
		if (!p_voice.have_ly)
			continue
		if (above_tb[v]) {
			rv_tb[i++] = v
			continue
		}
		st = p_voice.st;
// don't scale the lyrics
		set_dscale(st, true)
		if (nly_tb[v] > 0)
			lyst_tb[st].bot = draw_lyrics(p_voice, nly_tb[v],
							h_tb[v],
							lyst_tb[st].bot, 1)
	}

	/* draw the lyrics above the staff */
	while (--i >= 0) {
		v = rv_tb[i];
		p_voice = voice_tb[v];
		st = p_voice.st;
		set_dscale(st, true);
		lyst_tb[st].top = draw_lyrics(p_voice, nly_tb[v],
						h_tb[v],
						lyst_tb[st].top, -1)
	}

	/* set the max y offsets of all symbols */
	for (v = 0; v < nv; v++) {
		p_voice = voice_tb[v]
		if (!p_voice.sym)
			continue
		st = p_voice.st;
		if (lyst_tb[st].a) {
			top = lyst_tb[st].top + 2
			for (s = p_voice.sym; s; s = s.next) {
/*fixme: may have lyrics crossing a next symbol*/
				if (s.a_ly) {
/*fixme:should set the real width*/
					y_set(st, 1, s.x - 2, 10, top)
				}
			}
		}
		if (lyst_tb[st].b) {
			bot = lyst_tb[st].bot - 2
			if (nly_tb[p_voice.v] > 0) {
				for (s = p_voice.sym; s; s = s.next) {
					if (s.a_ly) {
/*fixme:should set the real width*/
						y_set(st, 0, s.x - 2, 10, bot)
					}
				}
			} else {
				y_set(st, 0, 0, realwidth, bot)
			}
		}
	}
}
// abc2svg - gchord.js - chord symbols
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

// -- parse a chord symbol / annotation --
// the result is added in the global variable a_gch
// 'type' may be a single '"' or a string '"xxx"' created by U:
function parse_gchord(type) {
    var	c, text, gch, x_abs, y_abs,
	i, j, istart, iend,
		ann_font = get_font("annotation"),
		h_ann = ann_font.size,
		line = parse.line

	function get_float() {
		var txt = ''

		while (1) {
			c = text[i++]
			if ("1234567890.-".indexOf(c) < 0)
				return parseFloat(txt)
			txt += c
		}
	} // get_float()

	istart = parse.bol + line.index
	if (type.length > 1) {			// U:
		text = type.slice(1, -1);
		iend = istart + 1
	} else {
		i = ++line.index		// search the ending double quote
		while (1) {
			j = line.buffer.indexOf('"', i)
			if (j < 0) {
				syntax(1, "No end of chord symbol/annotation")
				return
			}
			if (line.buffer[j - 1] != '\\'
			 || line.buffer[j - 2] == '\\')	// (string ending with \\")
				break
			i = j + 1
		}
		text = cnv_escape(line.buffer.slice(line.index, j))
		line.index = j
		iend = parse.bol + line.index + 1
	}

	if (ann_font.pad)
		h_ann += ann_font.pad
	i = 0;
	type = 'g'
	while (1) {
		c = text[i]
		if (!c)
			break
		gch = {
			text: "",
			istart: istart,
			iend: iend,
			font: ann_font
		}
		switch (c) {
		case '@':
			type = c;
			i++;
			x_abs = get_float()
			if (c != ',') {
				syntax(1, "',' lacking in annotation '@x,y'");
				y_abs = 0
			} else {
				y_abs = get_float()
				if (c != ' ')
					i--
			}
			gch.x = x_abs;
			gch.y = y_abs
			break
		case '^':
			gch.pos = C.SL_ABOVE
			// fall thru
		case '_':
			if (c == '_')
				gch.pos = C.SL_BELOW
			// fall thru
		case '<':
		case '>':
			i++;
			type = c
			break
		default:
			switch (type) {
			case 'g':
				gch.font = get_font("gchord")
				gch.pos = curvoice.pos.gch || C.SL_ABOVE
				break
			case '^': 
				gch.pos = C.SL_ABOVE
				break
			case '_':
				gch.pos = C.SL_BELOW
				break
			case '@':
				gch.x = x_abs;
				y_abs -= h_ann;
				gch.y = y_abs
				break
			}
			break
		}
		gch.type = type
		while (1) {
			c = text[i]
			if (!c)
				break
			switch (c) {
			default:
				gch.text += c;
				i++
				continue
			case '&':			/* skip "&xxx;" */
				while (1) {
					gch.text += c;
					c = text[++i]
					switch (c) {
					default:
						continue
					case ';':
					case undefined:
					case '\\':
						break
					}
					break
				}
				if (c == ';') {
					i++;
					gch.text += c
					continue
				}
				break
			case '\n':		// abcm2ps compatibility
			case ';':
				break
			}
			i++
			break
		}
		gch.otext = gch.text	// save for play accompaniment
		if (!a_gch)
			a_gch = []
		a_gch.push(gch)
	}
}

// transpose a chord symbol
	function gch_tr1(p, tr) {
	    var	i, o, n, ip,
		csa = p.split('/')

		tr = abc2svg.b40l5[(tr + 202) % 40]	// transpose in the line of fifth
		for (i = 0; i < csa.length; i++) {	// main and optional bass
			p = csa[i];
			o = p.search(/[A-G]/)
			if (o < 0)
				continue		// strange chord symbol!
			ip = o + 1

//	bbb fb cb gb db ab eb bb  f c g d a e b f# c# g# d# a# e# b# f##
//	 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5  6  7  8  9 10 11 12  13
			n = "FCGDAEB".indexOf(p[o]) - 1
			if (p[ip] == '#' || p[ip] == '\u266f') {
				n += 7
				ip++
			} else if (p[ip] == 'b' || p[ip] == '\u266d') {
				n -= 7
				ip++
			}
			n += tr					// transpose

//			// remove chords with double sharps/flats
//			if ((!i && n > 7)			// main chord
//			 || (i && n > 12))			// bass
//				n -= 12
//			else if (i < -7)
//				n += 12

			csa[i] = p.slice(0, o)
				+ "FCGDAEB"[(n + 22) % 7]
				+ (n >= 13 ? '##'
					: n >= 6 ? '#'
					: n <= -9 ? 'bb'
					: n <= -2 ? 'b'
					: '')
				+ p.slice(ip)
		}
		return csa.join('/')
	} // gch_tr1

// parser: add the parsed list of chord symbols and annotations
//	to the symbol (note, rest or bar)
//	and transpose the chord symbols
function csan_add(s) {
    var	i, gch

	// there cannot be chord symbols on measure bars
	if (s.type == C.BAR) {
		for (i = 0; i < a_gch.length; i++) {
			if (a_gch[i].type == 'g') {
				error(1, s,
				       "There cannot be chord symbols on measure bars")
				a_gch.splice(i)
			}
		}
	}

	if (curvoice.tr_sco
	 || curvoice.tr_snd) {
		for (i = 0; i < a_gch.length; i++) {
			gch = a_gch[i]
			if (gch.type == 'g') {
				if (curvoice.tr_snd40)
					gch.otext = gch_tr1(gch.text, curvoice.tr_snd40)
				if (curvoice.tr_sco)
					gch.text = gch_tr1(gch.text, curvoice.tr_sco)
			}
		}
	}

	if (s.a_gch)
		s.a_gch = s.a_gch.concat(a_gch)
	else
		s.a_gch = a_gch
	a_gch = null
} // csan_add

// generator: build the chord symbols / annotations
// (possible hook)
Abc.prototype.gch_build = function(s) {

	/* split the chord symbols / annotations
	 * and initialize their vertical offsets */
	var	gch, wh, xspc, ix,
		y_left = 0,
		y_right = 0,
		GCHPRE = .4;		// portion of chord before note

	// change the accidentals in the chord symbols,
	// convert the escape sequences in annotations, and
	// set the offsets
	for (ix = 0; ix < s.a_gch.length; ix++) {
		gch = s.a_gch[ix]
		if (gch.type == 'g') {
			gch.text = gch.text.replace(/##|#|=|bb|b/g,
				function(x) {
					switch (x) {
					case '##': return "&#x1d12a;"
					case '#': return "\u266f"
					case '=': return "\u266e"
					case 'b': return "\u266d"
					}
					return "&#x1d12b;"
				});
		} else {
			if (gch.type == '@'
			 && !user.anno_start && !user.anno_stop) {
				set_font(gch.font)
				gch.text = str2svg(gch.text)
				continue		/* no width */
			}
		}

		/* set the offsets and widths */
		set_font(gch.font);
		gch.text = str2svg(gch.text)
		wh = gch.text.wh
		switch (gch.type) {
		case '@':
			break
		default:
//		case 'g':			// chord symbol
//		case '^':			/* above */
//		case '_':			/* below */
			xspc = wh[0] * GCHPRE
			if (xspc > 8)
				xspc = 8;
			gch.x = -xspc;
			break
		case '<':			/* left */
			gch.x = -(wh[0] + 6);
			y_left -= wh[1];
			gch.y = y_left + wh[1] / 2
			break
		case '>':			/* right */
			gch.x = 6;
			y_right -= wh[1];
			gch.y = y_right + wh[1] / 2
			break
		}
	}

	/* move upwards the top and middle texts */
	y_left /= 2;
	y_right /= 2
	for (ix = 0; ix < s.a_gch.length; ix++) {
		gch = s.a_gch[ix]
		switch (gch.type) {
		case '<':			/* left */
			gch.y -= y_left
			break
		case '>':			/* right */
			gch.y -= y_right
			break
		}
	}
}

// -- draw the chord symbols and annotations
// (the staves are not yet defined)
// (unscaled delayed output)
// (possible hook)
Abc.prototype.draw_gchord = function(i, s, x, y) {
	if (s.invis && s.play)	// play sequence: no chord nor annotation
		return
    var	y2,
	an = s.a_gch[i],
	h = an.text.wh[1],
	pad = an.font.pad,
	w = an.text.wh[0] + pad * 2,
	dy = h * .22			// descent

	if (an.font.figb) {
		h *= 2.4
		dy += an.font.size * 1.3
	}

	switch (an.type) {
	case '_':			// below
		y -= h + pad
		break
	case '^':			// above
		y += pad
		break
	case '<':			// left
	case '>':			// right
		if (an.type == '<') {
/*fixme: what symbol space?*/
			if (s.notes[0].acc)
				x -= s.notes[0].shac
			x -= pad
		} else {
			if (s.xmx)
				x += s.xmx
			if (s.dots)
				x += 1.5 + 3.5 * s.dots
			x += pad
		}
		y += (s.type == C.NOTE ?
				(((s.notes[s.nhd].pit + s.notes[0].pit) >> 1) -
						18) * 3 :
				12)		// fixed offset on rests and bars
			- h / 2
		break
	default:			// chord symbol
		if (y >= 0)
			y += pad
		else
			y -= h + pad
		break
	case '@':			// absolute
		y += (s.type == C.NOTE ?
				(((s.notes[s.nhd].pit + s.notes[0].pit) >> 1) -
						18) * 3 :
				12)		// fixed offset on rests and bars
			- h / 2
		if (y > 0) {
			y2 = y + h + pad + 2
			if (y2 > staff_tb[s.st].ann_top)
				staff_tb[s.st].ann_top = y2
		} else {
			y2 = y - 2
			if (y2 < staff_tb[s.st].ann_bot)
				staff_tb[s.st].ann_bot = y2
		}
		break
	}

	if (an.type != '@') {
		if (y >= 0)
			y_set(s.st, 1, x, w, y + h + pad + 2)
		else
			y_set(s.st, 0, x, w, y - pad)
	}

	use_font(an.font)
	set_font(an.font)
	set_dscale(s.st)
	if (user.anno_start)
		user.anno_start("annot", an.istart, an.iend,
			x - 2, y + h + 2, w + 4, h + 4, s)
	xy_str(x, y + dy, an.text)
	if (user.anno_stop)
		user.anno_stop("annot", an.istart, an.iend,
			x - 2, y + h + 2, w + 4, h + 4, s)
} // draw_gchord()

// draw all chord symbols
function draw_all_chsy() {
    var	s, san1, an, i, x, y, w,
	n_an = 0,		// max number of annotations
	minmax = new Array(nstaff + 1)

	// set a vertical offset to all the chord symbols/annotations
	function set_an_yu(j) {
	    var	an, i, s, x, y, w

		for (s = san1 ; s; s = s.ts_next) {
			an = s.a_gch
			if (!an)
				continue
			i = an.length - j - 1
			an = an[i]
			if (!an)
				continue
			if (an.pos == C.SL_ABOVE) {
				x = s.x + an.x
				w = an.text.wh[0]
				if (w && x + w > realwidth)
					x = realwidth - w // let the text in the page
				y = y_get(s.st, 1, x, w)	// y / staff
				if (an.type == 'g' && y < minmax[s.st].yup)
					y = minmax[s.st].yup
			} else if (an.pos == C.SL_BELOW
				|| an.pos == C.SL_HIDDEN) {
				continue
			} else {
				x = s.x + an.x
				y = an.y
			}
			self.draw_gchord(i, s, x, y)
		}
	} // set_an_yu()

	function set_an_yl(i) {
	    var	an, x, y, w

		for (var s = san1 ; s; s = s.ts_next) {
			an = s.a_gch
			if (!an)
				continue
			an = an[i]
			if (!an
			 || an.pos != C.SL_BELOW)
				continue
			x = s.x + an.x
			w = an.text.wh[0]
			if (w && x + w > realwidth)	// let the text inside the page
				x = realwidth - w
			y = y_get(s.st, 0, x, w) - 2	// y / staff
			if (an.type == 'g' && y > minmax[s.st].ydn)
				y = minmax[s.st].ydn
			self.draw_gchord(i, s, x, y)
		}
	} // set_an_yl()

	// get the number of chord symbols / annotations
	// and the vertical offset for the chord symbols
	for (i = 0; i <= nstaff; i++)
		minmax[i] = {
			ydn: staff_tb[i].botbar - 3,
			yup: staff_tb[i].topbar + 4
		}
	for (s = tsfirst; s; s = s.ts_next) {
		an = s.a_gch
		if (!an)
			continue
		if (!san1)
			san1 = s	// first chord symbol / annotation
		i = an.length
		if (i > n_an)
			n_an = i
		while (--i >= 0) {
			if (an[i].type == 'g') {
				an = an[i]
				x = s.x + an.x
				w = an.text.wh[0]
				if (w && x + w > realwidth)
					x = realwidth - w
				if (an.pos == C.SL_ABOVE) {
					y = y_get(s.st, true, x, w)
					if (y > minmax[s.st].yup)
						minmax[s.st].yup = y
				} else if (an.pos == C.SL_BELOW) {
					y = y_get(s.st, false, x, w) - 2
					if (y < minmax[s.st].ydn)
						minmax[s.st].ydn = y
				}
				break
			}
		}
	}
	if (!san1)
		return			// no chord symbol nor annotation

	// draw the elements
	set_dscale(-1)			// restore the scale parameters
	for (i = 0; i < n_an; i++) {
		set_an_yu(i)		// upper offsets
		set_an_yl(i)		// lower offsets
	}
} // draw_all_chsy()
// abc2svg - tail.js
//
// Copyright (C) 2014-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

// initialize
	init_tune()

// Abc functions used by the modules
Abc.prototype.a_de = function() { return a_de }
Abc.prototype.add_style = function(s) { style += s };
Abc.prototype.anno_a = anno_a
Abc.prototype.cfmt = function() { return cfmt };
Abc.prototype.clone = clone;
Abc.prototype.clr_sty = clr_sty
Abc.prototype.deco_put = function(nm, s) {
	a_dcn.push(nm)
	deco_cnv(s)
}
Abc.prototype.defs_add = defs_add
Abc.prototype.dh_put = function(nm, s, nt) {
	a_dcn.push(nm)
	dh_cnv(s, nt)
}
Abc.prototype.draw_meter = draw_meter
Abc.prototype.draw_note = draw_note;
Abc.prototype.errs = errs;
Abc.prototype.font_class = font_class;
Abc.prototype.gch_tr1 = gch_tr1;
Abc.prototype.get_bool = get_bool;
Abc.prototype.get_cur_sy = function() { return cur_sy };
Abc.prototype.get_curvoice = function() { return curvoice };
Abc.prototype.get_delta_tb = function() { return delta_tb };
Abc.prototype.get_decos = function() { return decos };
Abc.prototype.get_font = get_font;
Abc.prototype.get_font_style = function() { return font_style };
Abc.prototype.get_glyphs = function() { return glyphs };
Abc.prototype.get_img = function() { return img };
Abc.prototype.get_lwidth = get_lwidth
Abc.prototype.get_maps = function() { return maps };
Abc.prototype.get_multi = function() { return multicol };
Abc.prototype.get_newpage = function() {
	if (block.newpage) {
		block.newpage = false;
		return true
	}
};
Abc.prototype.get_parse = function() { return parse }
Abc.prototype.get_posy = function() { return posy }
Abc.prototype.get_staff_tb = function() { return staff_tb };
Abc.prototype.get_top_v = function() { return par_sy.top_voice };
Abc.prototype.get_tsfirst = function() { return tsfirst };
Abc.prototype.get_unit = get_unit;
Abc.prototype.get_user = function() { return user }
Abc.prototype.get_voice_tb = function() { return voice_tb };
Abc.prototype.glout = glout
Abc.prototype.glovar = function() { return glovar }
Abc.prototype.info = function() { return info };
Abc.prototype.new_block = new_block;
Abc.prototype.out_arp = out_arp;
Abc.prototype.out_deco_str = out_deco_str;
Abc.prototype.out_deco_val = out_deco_val;
Abc.prototype.out_ltr = out_ltr;
Abc.prototype.param_set_font = param_set_font;
Abc.prototype.part_seq = part_seq
Abc.prototype.psdeco = empty_function;
Abc.prototype.psxygl = empty_function;
Abc.prototype.set_cur_sy = function(sy) { cur_sy = sy };
Abc.prototype.set_curvoice = function(p_v) { curvoice = p_v }
Abc.prototype.set_dscale = set_dscale;
Abc.prototype.set_font = set_font;
Abc.prototype.set_a_gch = function(s, a) { a_gch = a; csan_add(s) }
Abc.prototype.set_hl = set_hl
Abc.prototype.set_map = set_map
Abc.prototype.set_page = set_page
Abc.prototype.set_pagef = function() { blkdiv = 1 }
Abc.prototype.set_realwidth = function(v) { realwidth = v }
Abc.prototype.set_scale = set_scale;
Abc.prototype.set_sscale = set_sscale
Abc.prototype.set_tsfirst = function(s) { tsfirst = s };
Abc.prototype.set_v_param = set_v_param;
Abc.prototype.str2svg = str2svg
Abc.prototype.strwh = strwh;
Abc.prototype.stv_g = function() { return stv_g };
Abc.prototype.svg_flush = svg_flush;
Abc.prototype.syntax = syntax;
Abc.prototype.tunes = tunes
Abc.prototype.unlksym = unlksym;
Abc.prototype.use_font = use_font;
Abc.prototype.vskip = vskip
Abc.prototype.xy_str = xy_str;
Abc.prototype.xygl = xygl;
Abc.prototype.y_get = y_get
Abc.prototype.y_set = y_set
}	// end of Abc()

// compatibility
var Abc = abc2svg.Abc

// nodejs
if (typeof module == 'object' && typeof exports == 'object') {
	exports.abc2svg = abc2svg;
	exports.Abc = Abc
}
// abc2svg - modules.js - module handling
//
// Copyright (C) 2018-2025 Jean-Francois Moine
//
// This file is part of abc2svg-core.
//
// abc2svg-core is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg-core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg-core.  If not, see <http://www.gnu.org/licenses/>.

// empty function
if (!abc2svg.loadjs) {
    abc2svg.loadjs = function(fn, onsuccess, onerror) {
	if (onerror)
		onerror(fn)
    }
}

abc2svg.modules = {
	ambitus: {},
	begingrid: { fn: 'grid3' },
	beginps: { fn: 'psvg' },
	break: {},
	capo: {},
	chordnames: {},
	clip: {},
	clairnote: { fn: 'clair' },
	voicecombine: { fn: 'combine' },
	diagram: { fn: 'diag' },
	equalbars: {},
	fit2box: {},
	gamelan: {},
	grid: {},
	grid2: {},
	jazzchord: {},
	jianpu: {},
	mdnn: {},
	MIDI: {},
	nns: {},
	pageheight: { fn: 'page' },
	pedline: {},
	percmap: { fn: 'perc' },
	playswing: { fn: 'swing' },
	roman: {},
	soloffs: {},
	sth: {},
	strtab: {},
	temperament: { fn: 'temper' },
	temponame: { fn: 'tempo' },
	tropt: {},
	titleformat: { fn: 'tunhd' },

	nreq: 0,

	// scan the file and find the required modules
	// @file: ABC file
	// @relay: (optional) callback function for continuing the treatment
	// @errmsg: (optional) function to display an error message if any
	//	This function gets one argument: the message
	// return true when all modules are loaded
	load: function(file, relay, errmsg) {

		function get_errmsg() {
			if (typeof user == 'object' && user.errmsg)
				return user.errmsg
			if (typeof abc2svg.printErr == 'function')
				return abc2svg.printErr
			if (typeof alert == 'function')
				return function(m) { alert(m) }
			if (typeof console == 'object')
				return console.log
			return function(){}
		} // get_errmsg()

		// call back functions for loadjs()
		function load_end() {
			if (--abc2svg.modules.nreq == 0)
				abc2svg.modules.cbf()
		}

		// test if some keyword in the file
	    var	m, i, fn,
		nreq_i = this.nreq,
		ls = file.match(/(%%|I:).+?\b/g)

		if (!ls)
			return true
		this.cbf = relay ||		// (only one callback function)
			function(){}
		this.errmsg = errmsg || get_errmsg()

		for (i = 0; i < ls.length; i++) {
			fn = ls[i].replace(/\n?(%%|I:)/, '')
			m = abc2svg.modules[fn]
			if (!m || m.loaded)
				continue

			m.loaded = true

			// load the module
			if (m.fn)
				fn = m.fn
			this.nreq++
			abc2svg.loadjs(fn + "-1.js",
					load_end,
					function () {
						abc2svg.modules.errmsg(
							'Error loading the module ' + fn)
						load_end()
					})
		}
		return this.nreq == nreq_i
	}
} // modules
abc2svg.version="v1.22.34";abc2svg.vdate="2025-11-22"
