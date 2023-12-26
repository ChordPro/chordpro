// abckbd2.js - other ABC keyboard
//
// Copyright (C) 2014-2017 Jean-Francois Moine
//
// This file is part of abc2svg.
//
// abc2svg is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with abc2svg.  If not, see <http://www.gnu.org/licenses/>.

// global variables
    var	abc_kb = false,		// keyboard state
	kbds,			// button/state
	oct = 4,
	dur = 4,		// crotchet (quarter/black note)
	chord

// constants
    var	
	dur_tb = ["////", "///", "//", "/", "", "2", "4", "8", "16" ],
	key = {					// US keyboard
		// keyboard switch
		"`": "`",

		// left: bar, accidentals, duration, octave
		a: "|", s: "=", d: "d-", f: "d+",
		z: "_", x: "^", c: "o-", v: "o+",

		// right: notes/rest
		j: "C",  k : "D",  l : "E", ";": "F",
		m: "G", ",": "A", ".": "B", "/": "z",

		// other keys
		g: "[]",		// chord start/stop
		h: ".",			// music dot
		"\n": "\n"
	}

// stop the keypress event
function stop_key(e) {
	e.stopImmediatePropagation();
	e.preventDefault();
	src_change()			// rendering update
}

// update the octave and duration flags
function kbd_upd() {
	var c = chord ? '[' : ""

	switch (oct) {
	case 2:	c += "C,,"; break
	case 3:	c += "C,"; break
//	case 4: 
	default: c += "C"; break
	case 5:	c += "c"; break
	case 6:	c += "c'"; break
	case 7:	c += "c''"; break
	}
	kbds.innerHTML = 'kbd ' + c + dur_tb[dur]
}

// hadle a keypress
function key_press(e) {
	if (e.ctrlKey)
		return

    var st, en,
	kc = e.which,
	c = String.fromCharCode(kc),
	s = document.getElementById("source")

	// check if there is a note/chord/rest before the text cursor
	// if yes, return the start and stop indexes in 'st' & 'en'
	function get_note() {
	    var	ch
		if (!s.value)
			return		// no symbol
		en = st = s.selectionEnd
		while (1) {
			if (st == 0)
				break
			if (!s.value[--st].match(/[1-9,'/\]]/))	// '
				break
			if (s.value[st] == ']')
				ch = true
		}
		if (!s.value[st].match(/[A-Ga-gz]/))
			return // null
		if (ch) {
			while (1) {
				if (st == 0)
					return // null
				if (s.value[--st] == '[')
					break
			}
		}
		return s.value.slice(st, en)
	} // get_note()

	// --- key_press ---

	c = key[c]
	switch (c) {
	case undefined:
		if (kc == 0x08)		// 'delete' key
			break
		return
	case '`':			// keyboard switch
		abc_kb = !abc_kb;
		kbds.style.backgroundColor = abc_kb ? "#80ff80" : "#ffd0d0";
		stop_key(e)
		return
	}
	if (!abc_kb)
		return

	if (kc == 0x08) {		// 'delete' key
		c = get_note()
		if (!c)
			return
		s.value = s.value.slice(0, st) + s.value.slice(en);
		s.setSelectionRange(st, st);
		stop_key(e)
		return
	}

	switch (c[0]) {
	case "A":			// notes
	case "B":
	case "C":
	case "D":
	case "E":
	case "F":
	case "G":
		switch (oct) {
		case 2:	c = c + ",,"; break
		case 3:	c = c + ","; break
//		case 4: break
		case 5:	c = c.toLowerCase(); break
		case 6:	c = c.toLowerCase() + "'"; break
		case 7:	c = c.toLowerCase() + "''"; break
		}
		if (!chord)
			c += dur_tb[dur]
		break
	case "z":			// rest
		c += dur_tb[dur]
		break
	case "d":			// duration
		if (c[1] == '+') {
			if (dur < dur_tb.length - 1)
				dur++
		} else {
			if (dur > 0)
				dur--
		}
		kbd_upd();
		c = null
		break
	case "o":			// octave
		if (c[1] == '+') {
			if (oct < 7)
				oct++
		} else {
			if (oct > 2)
				oct--
		}
		kbd_upd();
		c = null
		break
	case '[':			// chord start/stop
		chord = !chord;
		kbd_upd();
		c = chord ? '[' : (']' + dur_tb[dur])
		break
	case '.':			// music dot
		c = get_note()
		if (!c)
			break
		if (!c.match(/2|3|4|6|\/\/|\//))
			c += "3/"
		else
			c = c.replace(/2|3|4|6|\/\/|\//, function(a) {
				switch (a) {
				case '2': return "3"
				case '3': return "7/"
				case '4': return "6"
				case '6': return "7"
				case '//': return "3///"
				case '/': return "3//"
				default: return "3/"
				}
			})
		s.value = s.value.slice(0, st) + c + s.value.slice(en);
		st += c.length;
		s.setSelectionRange(st, st);
		c = null
		break
	}
	if (c) {
		st = s.selectionStart;
		s.value = s.value.slice(0, st) + c + s.value.slice(st);
		st += c.length;
		s.setSelectionRange(st, st)
	}
	stop_key(e)
}

function kbd_init() {

// set the keyboard event in the ABC source
document.getElementById("source").addEventListener("keypress", key_press);

// add a keyboard help window
    var	tmp = document.createElement("div");

	tmp.id = "abckbd";
	tmp.className = "popup";
	tmp.style.width = "600px";
	tmp.innerHTML = 
'<div class="close" onclick="popshow(\'abckbd\')">x</div>\
<table>\
 <tr>\
	<td>kbd-<br/>-chg</td>\
  <td></td> <td></td> <td></td> <td></td> <td></td> <td></td>\
	<td></td> <td></td> <td></td> <td></td> <td></td> <td></td>\
 </tr>\
 <tr>\
	<td style="border:0"></td>\
  <td> </td> <td></td> <td></td> <td></td> <td></td> <td></td>\
	<td></td> <td></td> <td></td> <td></td> <td>  </td> <td>  </td>\
 </tr>\
 <tr>\
	<td style="border:0"></td>\
  <td>|</td> <td>=</td> <td>d-</td> <td>d+</td> <td>[]</td> <td>dot</td>\
	<td>C</td> <td>D</td> <td>E</td> <td>F</td> <td></td> <td></td>\
 </tr>\
 <tr>\
	<td style="border:0"></td>\
  <td>_</td> <td>^</td> <td>o-</td> <td>o+</td> <td></td> <td></td>\
	<td>G</td> <td>A</td> <td>B</td> <td>z</td>\
 </tr>\
 <tr>\
	<td style="border:0" colspan="3"></td>\
  <td colspan="6">space</td>\
 </tr>\
</table>';
	document.body.appendChild(tmp);

// add a button under 'File' that gives the keyboard state
// and raises the keyboard layout
	kbds = document.createElement("li");
	kbds.addEventListener('click', function() {popshow('abckbd', true)});
	kbds.className = "dropbutton";
	kbds.style.backgroundColor = "#ffd0d0";
	kbds.innerHTML = 'kbd c2';
	document.getElementById("er").parentNode.appendChild(kbds);

// add a help about the ABC keyboard
	tmp = document.createElement("div");
	tmp.id = "kbdhelp";
	tmp.className = "popup";
	tmp.style.width = "600px";
	tmp.innerHTML = 
'<div class="close" onclick="popshow(\'kbdhelp\')">x</div>\
<ul id="khlp">\
<li>The ABC keyboard is enabled/disabled by pressing the key \'<code>`</code>\'.<br/>\
The layout of the keyboard is displayed by clicking on the keyboard state<br/>\
(below <code>File</code>).</li>\
<li>When the keyboard is enabled:\
 <ul>\
 <li>the right hand enters the notes and rests,</li>\
 <li>the left hand enters the measure bars and the accidentals,<br/>\
	and also controls the duration \'<code>d-/d+</code>\'\
	and the octave \'<code>o-/o+</code>\',</li>\
 <li>\'<code>dot</code>\' adds a music <i>dot</i>,</li>\
 <li>\'<code>[]</code>\' starts/stops chords,</li>\
 <li>\'<code>space</code>\' inserts a beam break.</li>\
 </ul></li>\
</ul>';
	document.body.appendChild(tmp);

// add a button to display the help about the keyboard
	tmp = document.createElement("li");
	tmp.addEventListener('click', function() { popshow('kbdhelp', true)});
	tmp.innerHTML = 'Keyboard help';
    var help = document.getElementById("ha").parentNode;
	help.insertBefore(tmp, help.childNodes[2]);

	kbd_upd()
}

kbd_init()
