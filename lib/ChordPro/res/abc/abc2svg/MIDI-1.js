// MIDI.js - module to handle the %%MIDI parameters
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
// This module is loaded when "%%MIDI" appears in a ABC source.
//
// Parameters (see abcMIDI for details)
//	%%MIDI channel n
//	%%MIDI program [channel] n
//	%%MIDI control k v
//	%%MIDI drummap ABC_note MIDI_pitch
//	%%MIDI temperamentequal nedo
//	%%MIDI chordname <chord_type> <list of MIDI pitches>
//	%%MIDI chordprog <#MIDI program> [octave=<n>]
//	%%MIDI chordvol <volume>
//	%%MIDI gchordon
//	%%MIDI gchordoff

// Using %%MIDI drummap creates a voicemap named "MIDIdrum".
// This name must be used if some print map is required:
//	%%MIDI drummap g 42
//	%%map MIDIdrum g heads=x
// A same effect may be done by
//	%%percmap g 42 x
// but this is not abcMIDI compatible!

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.MIDI = {

    // parse %%MIDI commands
    do_midi: function(parm) {

    // build the equal temperament as a b40 float array
    function tb40(qs) {
// b40	  C  D   E   F   G   A   B
//	[ 2, 8, 14, 19, 25, 31, 37 ]
    var	i,
//	      C  G  D  A  E  B ^F ^C ^G ^D ^A ^E ^B^^F^^C^^G^^D^^A^^E^^B
	n1 = [2,25, 8,31,14,37,20, 3,26, 9,32,15,38,21, 4,27,10,33,16,39],
//	      C  F _B _E _A _D _G _C _F__B__E__A__D__G__C__F
	n2 = [0,19,36,13,30, 7,24, 1,18,35,12,29, 6,23, 0,17],
	da = 21 - 3 * qs		// 21 = 12 (octave) + 9 (A)
	b = new Float32Array(40)

	for (i = 0; i < n1.length; i++)
		b[n1[i]] = (qs * i + da) % 12
	for (i = 1; i <= n2.length; i++)
		b[n2[i]] = 12 - (qs * i - da) % 12
	return b
    } // tb40()

    // do_midi()
    var	n, v, s, maps,
	o, q, n, qs,
	a = parm.split(/\s+/),
	abc = this,
	cfmt = abc.cfmt(),
	curvoice = abc.get_curvoice()

	if (curvoice) {
		if (curvoice.ignore)
			return
		if (curvoice.chn == undefined)
			curvoice.chn = curvoice.v < 9 ?
					curvoice.v :
					curvoice.v + 1
	}
	switch (a[1]) {
//	case "bassprog":	// %%MIDI bassprog <#MIDI program> [octave=<n>]
//		break
//	case "bassvol":		// %%MIDI bassvol <volume>
//		break
//	case "beatstring":	// %%MIDI beatstring <string of fmp>
//		break
	case "chordname":	// %%MIDI chordname <list of MIDI pitches>
				// example: %%MIDI chordname m 0 3 7
		if (!cfmt.chord)
			cfmt.chord = {}
		if (!cfmt.chord.names)
			cfmt.chord.names = {}
		cfmt.chord.names[a[2]] = a.slice(3)
		break
	case "chordprog":	// %%MIDI chordprog <#MIDI program> [octave=<n>]
		if (!cfmt.chord)
			cfmt.chord = {}
		cfmt.chord.prog = a[2]
		if (a[3] && a[3].slice(0, 7) == "octave=")
			cfmt.chord.trans = Number(a[3].slice(7))
		break
	case "chordvol":	// %%MIDI chordvol <volume>
		v = Number(a[2])
		if (isNaN(v) || v < 0 || v > 127) {
			abc.syntax(1, abc.errs.bad_val, "%%MIDI chordvol")
			break
		}
		if (!cfmt.chord)
			cfmt.chord = {}
		cfmt.chord.vol = v / 127
		break
//	case "drone":		// %%MIDI drone <#prog> <pit_1> <pit_2> <vol_1> <vol_2>
//				//	default: 70 45 33 80 80
//		break
//	case "droneon":		// %%MIDI droneon
//		break
//	case "droneoff":	// %%MIDI droneoff
//		break
//	case "gchord":		// %%MIDI gchord <list of letters and repeat numbers>
//				//	z rest
//				//	c chord
//				//	f fundamental
//				//	b fundamental + chord
//				// defaults:
//				//	M:2/4 or 4/4	fzczfzcz
//				//	M:3/4	fzczcz
//				//	M:6/8	fzcfzc
//				//	M:9/8	fzcfzcfzc
//		break
	case "gchordon":	// %%MIDI gchordon
	case "gchordoff":	// %%MIDI gchordoff
		if (!cfmt.chord)
			cfmt.chord = {}
		if (abc.parse.state >= 2
		 && curvoice) {
			s = abc.new_block("midigch")
			s.play = s.invis = 1 //true
			s.on = a[1][7] == 'n'
		} else {
			cfmt.chord.gchon = a[1][7] == 'n'
		}
		break
	case "channel":
		v = parseInt(a[2])
		if (isNaN(v) || v <= 0 || v > 16) {
			abc.syntax(1, abc.errs.bad_val, "%%MIDI channel")
			break
		}
		v--				// channel range 1..16 => 0..15
			if (abc.parse.state == 3) {
				s = abc.new_block("midiprog")
				s.play = s.invis = 1 //true
				curvoice.chn = s.chn = v
			} else {
				abc.set_v_param("channel", v)
			}
		break
	case "drummap":
//fixme: should have a 'MIDIdrum' per voice?
		v = Number(a[3])
		if (isNaN(v)) {
			abc.syntax(1, abc.errs.bad_val, "%%MIDI drummap")
			break
		}
		n = ["C","^C","D","_E","E","F","^F","G","^G","A","_B","B"][v % 12]
		while (v < 60) {
			n += ','
			v += 12
		}
		while (v > 72) {
			n += "'"
			v -= 12
		}
		this.do_pscom("map MIDIdrum " + a[2] + " play=" + n)
		abc.set_v_param("mididrum", "MIDIdrum")
		break
	case "program":
		if (a[3] != undefined) {	// with a channel
			abc2svg.MIDI.do_midi.call(abc, "MIDI channel " + a[2])
			v = a[3]
		} else {
			v = a[2];
		}
		v = parseInt(v)
		if (isNaN(v) || v < 0 || v > 127) {
			abc.syntax(1, abc.errs.bad_val, "%%MIDI program")
			break
		}
		if (abc.parse.state == 3) {
			s = abc.new_block("midiprog");
			s.play = s.invis = 1 //true
			s.instr = v
			s.chn = curvoice.chn
		} else {
			abc.set_v_param("instr", v)
		}
		break
	case "control":
		n = parseInt(a[2])
		if (isNaN(n) || n < 0 || n > 127) {
			abc.syntax(1, "Bad controller number in %%MIDI")
			break
		}
		v = parseInt(a[3])
		if (isNaN(v) || v < 0 || v > 127) {
			abc.syntax(1, "Bad controller value in %%MIDI")
			break
		}
		if (abc.parse.state == 3) {
			s = abc.new_block("midictl");
			s.play = s.invis = 1 //true
			s.ctrl = n;
			s.val = v
		} else {
			abc.set_v_param("midictl", a[2] + ' ' + a[3])
		}
		break
	case "temperamentequal":
		n = parseInt(a[2])
		if (isNaN(n) || n < 5 || n > 255) {
			abc.syntax(1, abc.errs.bad_val, "%%MIDI " + a[1])
			return
		}

		// define the Turkish accidentals (53-TET)
		if (n == 53) {
			s = abc.get_glyphs()

// #1
			s.acc12_53 = '<text id="acc12_53" x="-1">&#xe282;</text>'

// #2
			s.acc24_53 = '<text id="acc24_53" x="-1">&#xe282;\
	<tspan x="0" y="-10" style="font-size:8px">2</tspan></text>'

// #3
			s.acc36_53 = '<text id="acc36_53" x="-1">&#xe262;\
	<tspan x="0" y="-10" style="font-size:8px">3</tspan></text>'

// #4
			s.acc48_53 = '<text id="acc48_53" x="-1">&#xe262;</text>'

// #5
			s.acc60_53 = '<g id="acc60_53">\n\
	<text style="font-size:1.2em" x="-1">&#xe282;</text>\n\
	<path class="stroke" stroke-width="1.6" d="M-2 1.5l7 -3"/>\n\
</g>'

// b5
			s["acc-60_53"] = '<text id="acc-60_53" x="-1">&#xe260;</text>'

// b4
			s["acc-48_53"] = '<g id="acc-48_53">\n\
	<text x="-1">&#xe260;</text>\n\
	<path class="stroke" stroke-width="1" d="M-3 -5.5l5 -2"/>\n\
</g>'

// b3
			s["acc-36_53"] = '<g id="acc-36_53">\n\
	<text x="-1">&#xe260;\
		<tspan x="0" y="-10" style="font-size:8px">3</tspan></text>\n\
	<path class="stroke" stroke-width="1" d="M-3 -5.5l5 -2"/>\n\
</g>'

// b2
			s["acc-24_53"] = '<text id="acc-24_53" x="-2">&#xe280;\
	<tspan x="0" y="-10" style="font-size:8px">2</tspan></text>'

// b1
			s["acc-12_53"] = '<text id="acc-12_53" x="-2">&#xe280;</text>'
		}

		// define the detune values
		q = 7.019550008653874,	//  Math.log(3/2)/Math.log(2) * 12
					// = just intonation fifth
		o = 12			// octave
		cfmt.nedo = n		// octave divider
		qs = ((n * q / o + .5) | 0) * o / n	// new fifth

		// warn on bad fifth values
		if (qs < 6.85 || qs > 7.2)
			abc.syntax(0, abc.errs.bad_val, "%%MIDI " + a[1])

		cfmt.temper = tb40(qs)	// pitches / A in 100th of cents

		break
	}
    }, // do_midi()

    // set the MIDI parameters in the current voice
    set_vp: function(of, a) {
    var	i, item, s,
	abc = this,
	curvoice = abc.get_curvoice()

	// set the voice parameters before inserting any block
	of(a.slice(0))			// (copy because the parameters are removed)

	for (i = 0; i < a.length; i++) {
		switch (a[i]) {
		case "channel=":		// %%MIDI channel
			s = abc.new_block("midiprog")
			s.play = s.invis = 1 //true
			s.chn = curvoice.chn = a[++i]
			break
		case "instr=":			// %%MIDI program
			s = abc.new_block("midiprog")
			s.play = s.invis = 1 //true
			s.instr = a[++i]
			if (curvoice.chn == undefined) {
				curvoice.chn = curvoice.v < 9 ?
						curvoice.v :
						curvoice.v + 1
			}
			s.chn = curvoice.chn
			break
		case "midictl=":		// %%MIDI control
			if (!curvoice.midictl)
				curvoice.midictl = []
			item = a[++i].split(' ');
			curvoice.midictl[item[0]] = Number(item[1])
			break
		case "mididrum=":		// %%MIDI drummap note midipitch
			if (!curvoice.map)
				curvoice.map = {}
			curvoice.map = a[++i]
			break
		}
	}
    }, // set_vp()

    do_pscom: function(of, text) {
	if (text.slice(0, 5) == "MIDI ")
		abc2svg.MIDI.do_midi.call(this, text)
	else
		of(text)
    },

    set_hooks: function(abc) {
	abc.do_pscom = abc2svg.MIDI.do_pscom.bind(abc, abc.do_pscom);
	abc.set_vp = abc2svg.MIDI.set_vp.bind(abc, abc.set_vp)
    }
} // MIDI

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.MIDI = abc2svg.MIDI.set_hooks
