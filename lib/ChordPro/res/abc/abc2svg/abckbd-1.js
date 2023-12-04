// abckbd.js - ABC keyboard
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
    var	abc_kb = false,				// keyboard state
	kbds					// button/state

// constants
    var	oct = 4,
	key = {					// US keyboard
		"1": "C4",
		"2": "D4",
		"3": "E4",
		"4": "F4",
		"5": "G4",
		"6": "A4",
		"7": "B4",
		"8": "z4",
//		"-": "-",
//		"=": "=",
		q: "C2",
		w: "D2",
		e: "E2",
		r: "F2",
		t: "G2",
		y: "A2",
		u: "B2",
		i: "z2",
//		"[": "[",
//		"]": "]",
		a: "C",
		s: "D",
		d: "E",
		f: "F",
		g: "G",
		h: "A",
		j: "B",
		k: "z",
		"'": "_",
		'\\': "#",
		z: "C/",
		x: "D/",
		c: "E/",
		v: "F/",
		b: "G/",
		n: "A/",
		m: "B/",
		",": "z/"
//		".": "."
//		"/": "/"
	}

function key_press(e) {
    var st, en

	if (e.ctrlKey)
		return

    var	kc = e.which
	if (kc == 96) {			// '`'
		abc_kb = !abc_kb;
		e.stopImmediatePropagation();
		e.preventDefault();
		kbds.style.backgroundColor = abc_kb ? "#80ff80" : "#ffd0d0"
		return
	}
	if (!abc_kb)
		return

    var	c = String.fromCharCode(kc),
	s = document.getElementById("source")

	function get_note() {
		if (!s.value)
			return
		st = s.selectionEnd
		while (1) {
			if (st == 0)
				break
			if (!s.value[--st].match(/[1-9,'/]/))	// '
				break
		}
		if (!s.value[st].match(/[A-Ga-gz]/))
			return // null
		en = st
		while (1) {
			if (++en >= s.value.length)
				break
			if (!s.value[en].match(/[1-9,'/]/))	// '
				break
		}
		return s.value.slice(st, en)
	} // get_note()

	// --- key_press ---

	if (key[c]) {
	    c = key[c]
	    if (c[0] >= "A" && c[0] <= "G") {
		switch (oct) {
		case 2:
			c = c[0] + ",," + (c[1] ? c[1] : '')
			break
		case 3:
			c = c[0] + "," + (c[1] ? c[1] : '')
			break
//		case 4:
//			break
		case 5:
			c = c.toLowerCase()
			break
		case 6:
			c = c[0].toLowerCase() + "'" + (c[1] ? c[1] : '')
			break
		}
	    }
	} else {
		switch (c) {
//		case '\n':
//			c = '\n'
//			break
		case 'l':
			oct = 2;
			c = null
			break
		case ';':
			oct = 3;
			c = null
			break
		case 'o':
			oct = 4;
			c = null
			break
		case "p":
			oct = 5;
			c = null
			break
		case '9':
			oct = 6;
			c = null
			break
		case '+':			// music dot
			c = get_note()
			if (!c)
				return
			if (c.length == 1)
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
			s.value = s.value.slice(0, st) + c +
				s.value.slice(en);
			st += c.length;
			s.setSelectionRange(st, st)
			c = null
			break
		case ' ':
			c = e.shiftKey ? ' ' : '|'
			break
		default:
			if (kc == 0x08) {	// del (KO vimb)
				c = get_note()
				if (c) {
					s.value = s.value.slice(0, st) +
						s.value.slice(en);
					s.setSelectionRange(st, st);
					c = null;
					src_change()
					break
				}
			}
			return
		}
	}
	if (c) {
		st = s.selectionStart;
		s.value = s.value.slice(0, st) + c + s.value.slice(st);
		st += c.length;
		s.setSelectionRange(st, st)
	}
	e.stopImmediatePropagation();
	e.preventDefault();
	src_change()
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
  <td>C4</td><td>D4</td><td>E4</td><td>F4</td><td>G4</td><td>A4</td><td>B4</td>\
	<td>z4</td><td>O6</td><td></td><td>-</td><td>+<br/>=</td>\
 </tr>\
 <tr>\
	<td style="border:0"></td>\
  <td>C2</td><td>D2</td><td>E2</td><td>F2</td><td>G2</td><td>A2</td><td>B2</td>\
	<td>z2</td><td>O4</td><td>O5</td><td>[</td><td>]</td>\
 </tr>\
 <tr>\
	<td style="border:0"></td>\
  <td>C</td> <td>D</td> <td>E</td> <td>F</td> <td>G</td> <td>A</td> <td>B</td>\
	<td>z</td><td>O2</td><td>O3</td><td>b</td><td>#</td>\
 </tr>\
 <tr>\
	<td style="border:0"></td>\
  <td>C/</td><td>D/</td><td>E/</td><td>F/</td><td>G/</td><td>A/</td><td>B/</td>\
	<td>z/</td><td>.</td><td>/</td>\
 </tr>\
 <tr>\
	<td style="border:0" colspan="3"></td>\
  <td colspan="6">space (beam break)<br/>| (measure bar)</td>\
 </tr>\
</table>';
	document.body.appendChild(tmp);

// add a button to the right of 'help' that gives the keyboard state
// and raises the keyboard layout
	kbds = document.createElement("li");
	kbds.addEventListener('click', function() {popshow('abckbd', true)});
	kbds.className = "dropbutton";
	kbds.style.backgroundColor ="#ffd0d0";
	kbds.innerHTML = 'ABC kbd';
	document.getElementById("nav").appendChild(kbds);

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
(to the right of <code>help</code>).</li>\n\
<li>When the keyboard is enabled:\
 <ul>\
 <li>non-shift/non-control characters are replaced by a ABC sequence,</li>\
 <li>\'<code>(shift-)+</code>\' adds a music <i>dot</i>,</li>\
 <li>\'<code>space</code>\' adds a measure bar,</li>\
 <li>\'<code>shift-space</code>\' adds a beam break.</li>\
 </ul></li>\
</ul>';
	document.body.appendChild(tmp);

// add a button to display the help about the keyboard
	tmp = document.createElement("li");
	tmp.addEventListener('click', function() { popshow('kbdhelp', true)});
	tmp.innerHTML = 'Keyboard help';
    var help = document.getElementById("ha").parentNode;
	help.insertBefore(tmp, help.childNodes[2])
}

kbd_init()
