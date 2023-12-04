// edit.js - file used in the abc2svg editor
//
// Copyright (C) 2014-2023 Jean-Francois Moine
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

window.onerror = function(msg, url, line) {
	if (typeof msg == 'string')
		alert("window error: " + msg +
			"\nURL: " + url +
			"\nLine: " + line)
	else if (typeof msg == 'object')
		alert("window error: " + msg.type + ' ' + msg.target.src)
	else
		alert("window error: " + msg)
	return false
}

// function called before the page is closed
window.onbeforeunload = function () {
	if (chg)			// if the textarea has been modified
		return ""		// ask close page confirmation
}

var	abc_images,			// image buffer
	abc_fname = ["noname.abc", ""],	// file names
	abc_mtime = [],			// associated last modification time
	abc,				// Abc object
	syms,				// music symbol at source index
	ctxMenu,			// context menu for play
	elt_ref = {},			// pointers to page HTML elements
	selx = [0, 0],			// selected source indexes
	selx_sav = [],			// (saved while playing/printing)
	play = {},			// play data
	pop,				// current popup message
	texts = {},			// language specific texts
	chg = 0,			// > 0 when the textarea is modified
	jsdir = document.currentScript ?
		document.currentScript.src.match(/.*\//) :
		(function() {
		     var s_a = document.getElementsByTagName('script')
			for (var k = 0; k < s_a.length; k++) {
				if (s_a[k].src.indexOf('edit-') >= 0)
					return s_a[k].src.match(/.*\//) || ''
			}
			return ""	// ??
		})()

// -- Abc create argument
var user = {
	// -- required methods
	// include a file (%%abc-include - only one)
	read_file: function(fn) {
		elt_ref["s" + srcidx].style.display = "inline"
		return elt_ref.src1.value
	},
	// insert the errors
	errbld: function(sev, txt, fn, idx) {
	    var	msg = sev + ' ' + clean_txt(txt)
		if (idx >= 0)
			elt_ref.diverr.innerHTML += '<b onclick="gotoabc(-1,' + idx +
				')" style="cursor: pointer; display: inline-block">' +
				msg + "</b><br/>\n"
		else
			elt_ref.diverr.innerHTML += msg + "<br/>\n"
	},
	// image output
	img_out: function(str) {
		abc_images += str
	},
	// -- optional methods
	// annotations
	anno_stop: function(type, start, stop, x, y, w, h, s) {
		if (["beam", "slur", "tuplet"].indexOf(type) >= 0)
			return
		syms[start] = s		// music symbol

		// create a rectangle
		abc.out_svg('<rect class="abcr _' + start +
			'_" x="');
		abc.out_sxsy(x, '" y="', y);
		abc.out_svg('" width="' + w.toFixed(2) +
			'" height="' + abc.sh(h).toFixed(2) + '"/>\n')
// with absolute coordinates, the rectangles would be inserted at the end
// of the images as:
//  '<rect class="abcr _' + start +
//	'_" x="' + abc.ax(x).toFixed(2) + '" y="' + abc.ay(y).toFixed(2) +
//	'" width="' + w.toFixed(2) +
//	'" height="' + abc.ah(h).toFixed(2) + '"/>\n'
	},
	// -- optional attributes
	page_format: true		// define the non-page-breakable blocks
    },
    srcidx = 0

// -- local functions

// Storage handling
function storage(t,		// session or local
		 k, v) {
	try {
		t = t ? localStorage : sessionStorage
		if (!t)
			return
		if (v)
			t.setItem(k, v)
		else if (v === 0)
			t.removeItem(k)
		else
			return t.getItem(k)
	} catch(e) {
	}
}

// replace <>& by XML character references
function clean_txt(txt) {
	return txt.replace(/<|>|&.*?;|&/g, function(c) {
		switch (c) {
		case '<': return "&lt;"
		case '>': return "&gt;"
		case '&': return "&amp;"
		}
		return c
	})
}

// load the language files ('edit-lang.js' and 'err-lang.js')
function loadlang(lang, no_memo) {
	abc2svg.loadjs('edit-' + lang + '.js', function() { loadtxt() });
	abc2svg.loadjs('err-' + lang + '.js')
	if (!no_memo)
		storage(true, "lang", lang == "en" ? 0 : lang)
}

// show/hide a popup message
function popshow(area, visible) {
	var e = document.getElementById(area)
	if (pop) {
		if (pop == e)
			visible = false
		else
			pop.style.visibility = 'hidden'
	}
	e.style.visibility = visible ? 'visible' : 'hidden';
	pop = visible ? e : null
}

// load the (ABC source or include) file in the textarea
function loadtune() {
	var files = document.getElementById("abcfile").files
//	if (!files.length) {
//		alert('Please select a file!')
//		return
//	}
	abc_fname[srcidx] = files[0].name

	var reader = new FileReader();

	// Closure to capture the file information
	reader.onloadend = function(evt) {
	    var	s = srcidx == 0 ? "source" : "src1";

		elt_ref[s].value = evt.target.result;
		elt_ref["s" + srcidx].value = abc_fname[srcidx];
		chg = -1			// no change yet
		src_change()
	}

	// Read the file as text
	reader.readAsText(files[0], "UTF-8")
}

// display the source 0 or 1
function selsrc(idx) {
	if (idx == srcidx)
		return
	var	o = srcidx ? "src" + srcidx : "source",
		n = idx ? "src" + idx : "source";
	elt_ref[o].style.display = "none";
	elt_ref[n].style.display = "inline";
	elt_ref["s" + srcidx].style.backgroundColor = "#ffd0d0";
	elt_ref["s" + idx].style.backgroundColor = "#80ff80";
	srcidx = idx
}

// render the textarea content to the right side
function render() {
    var	i, j,
	content = elt_ref.source.value;

	if (!content)
		return			// empty source

	// if include file not loaded yet, ask it
	i = content.indexOf('%%abc-include ')
	if (i >= 0) {
		var sl = elt_ref.s1
		if (!sl.value) {
			sl.style.display = "inline";
			j = content.indexOf('\n', i);
			sl.value = content.slice(i + 14, j);
			selsrc(1);
			alert(texts.load + sl.value)
			return
		}
	}
	elt_ref.diverr.innerHTML = '';
	selx[0] = selx[1] = 0;
	chg++					// textarea modified
	render2()
}
function render2() {
    var	content = elt_ref.source.value,
	def = (abc2svg.a_inc && abc2svg.a_inc["default.abc"]) || ''

	// load the required modules
	if (!abc2svg.modules.load(content + elt_ref.src1.value + def, render2))
		return

	// if page formatting, define a function to get the modification date
	if (abc2svg.modules.pageheight.loaded) {
		abc2svg.get_mtime = function(fn) {
		    var	files = document.getElementById("abcfile").files
			if (files && files[0].lastModified)
				return new Date(files[0].lastModified)
			return new Date()
		}
	}

	abc = new abc2svg.Abc(user);
	abc_images = '';

//	document.body.style.cursor = "wait";
	syms = []

	// insert the file default.abc if loaded
	if (abc2svg.a_inc && abc2svg.a_inc["default.abc"]) {
		try {
			abc.tosvg("default.abc", abc2svg.a_inc["default.abc"])
		} catch(e) {
			alert(e.message + '\nabc2svg tosvg bug - stack:\n' + e.stack)
			return
		}
	}

	// render the textarea
	try {
		abc.tosvg(abc_fname[0], content)
	} catch(e) {
		alert(e.message + '\nabc2svg tosvg bug - stack:\n' + e.stack)
		return
	}
	abc2svg.abc_end()		// close the page if %%pageheight

//	document.body.style.cursor = "auto";

	try {
		elt_ref.target.innerHTML = abc_images
	} catch(e) {
		alert(e.message + '\nabc2svg image bug - abort')
		return
	}

	// show the 'Error' button if some error
	document.getElementById("er").style.display =
				elt_ref.diverr.innerHTML ? 'inline' : 'none';
}

// get the source offset from the row and column numbers
function soffs(r, c) {
    var	m,
	s = elt_ref.source,
	o = 0
	while (--r >= 0) {
		o = s.value.indexOf('\n', o) + 1
		if (o <= 0)
			return s.value.length - 1
	}
	m = s.value.indexOf('\n', o)	// check if inside the line
	o += c
	if (o > m)
		o = m
	return o
} // soffs()

// select a source ABC element on error
function gotoabc(l, c) {
    var	s = elt_ref.source

	selsrc(0)
	if (l >= 0)
		c = soffs(l, Number(c))
	s.blur()			// unfocus
	s.setSelectionRange(c, c)	// just set the cursor (no range)
	s.focus()			// should scroll the textarea
	s.setSelectionRange(c, syms[c] ? syms[c].iend : c + 1)
}

// click in the target
function selsvg(evt) {
    var	v,
	cl = evt.target.getAttribute('class')

	play.loop = false;

//	evt.stopImmediatePropagation();
//	evt.preventDefault()

	// remove the context menu if active
	if (ctxMenu && ctxMenu.style.display == "block") {
		ctxMenu.style.display = "none"
		return
	}

	// stop playing
	if (play.playing && !play.stop) {
		play.stop = -1;
		play.abcplay.stop()
		return
	}

	// highlight the clicked element or clear the selection start
	s = elt_ref.source;
	s.blur();
	v = cl && cl.substr(0, 4) == 'abcr' ? Number(cl.slice(6, -1)) : 0
	s.setSelectionRange(v, v)	// just a cursor
	s.focus()
	if (v)
		s.setSelectionRange(v, syms[v].iend)
}

// set/clear a selection
function setsel(idx, v) {
    var i, elts, s,
	old_v = selx[idx];

	if (v == old_v)
		return
	if (old_v) {
		elts = document.getElementsByClassName('_' + old_v + '_');
		i = elts.length
		while (--i >= 0)
			elts[i].style.fillOpacity = 0
	}
	if (v) {
		elts = document.getElementsByClassName('_' + v + '_');
		i = elts.length
		while (--i >= 0)
			elts[i].style.fillOpacity = 0.4
	}

	selx[idx] = v
}

function do_scroll(elt) {
    var	x = 0,
	y = 0,
	b = elt.getBoundingClientRect(),		// box of the rectangle
	d = elt_ref.target.parentElement,		// <div> 'dright'
	r = elt.parentNode.getBoundingClientRect()	// box of the svg container

	if (b.x < d.offsetLeft		// x offset of the rectangle
	 || b.x + b.width > d.offsetLeft + d.clientWidth * .7)
		x = b.x - d.offsetLeft - d.clientWidth * .3

	if (r.y < d.offsetTop		// y offset of the svg container
	 || r.y + r.height > d.offsetTop + d.clientHeight * .7)
		y = r.y - d.offsetTop - d.clientHeight * .3

	if (x || y)
//		d.scrollBy(x, y)
		d.scrollBy({
			top: y,
			left: x,
			behavior: (x < 0 || y) ? 'instant' : 'smooth'
				// 'smooth', 'instant' or 'auto' (default)
		})
}

// source text selection callback
function seltxt(evt) {
    var	s, elts,
	e = 0,
	elt = elt_ref.source,
	start = elt.selectionStart,
	end = elt.selectionEnd

	play.loop = false

	if (!start) {
		if (end == elt.value.length)
			return			// select all
		setsel(0, 0);			// clear selection
		setsel(1, 0)
		return
	}

	if (syms) {
		syms.forEach(function(sym, is) {
			if (!s) {
				if (is >= start)
					s = is
			} else if (sym.iend <= end) {
				e = is
			}
		})
	}
	if (!s)
		return
	if (selx[0] != s)
		setsel(0, s)
	if (selx[1] != e)
		setsel(1, e);
	elts = document.getElementsByClassName('_' + s + '_')
	if (elts[0])
		do_scroll(elts[0])	// move the element in the screen
}

// open a new window for file save
function saveas() {
	var	s = srcidx == 0 ? "source" : "src1",
		source = elt_ref[s].value,

	// create a link for our script to 'click'
		link = document.createElement("a");

	if (abc_fname[srcidx] == "noname.abc")
		elt_ref["s" + srcidx].value =
			abc_fname[srcidx] = prompt(texts.fn, abc_fname[srcidx])
	link.download = abc_fname[srcidx];
//	link.innerHTML = "Hidden Link";
	link.href = "data:text/plain;charset=utf-8," +
			encodeURIComponent(source);

	// open in a new tab
//	link.target = '_blank';

	// when link is clicked call a function to remove it from
	// the DOM in case user wants to save a second file.
	link.onclick = destroyClickedElement;

	// make sure the link is hidden.
	link.style.display = "none";

	// add the link to the DOM
	document.body.appendChild(link);

	// click the new link
	link.click()

	chg = 0					// no change anymore
}

// destroy the clicked element
function destroyClickedElement(evt) {
	document.body.removeChild(evt.target)
}

// set the size of the font of the textarea
function setfont() {
    var	fs = document.getElementById("fontsize").value.toString();
	elt_ref.source.style.fontSize =
		elt_ref.src1.style.fontSize = fs + "px";
	storage(true, "fontsz", fs == "14" ? 0 : fs)
}

// playing
// set soundfont URL
function set_sfu(v) {
	play.abcplay.set_sfu(v)
	storage(true, "sfu", v == "Scc1t2" ? 0 : v)
}
// set_speed value = 1..20, 10 = no change
function set_speed(iv) {
    var	spvl = document.getElementById("spvl"),
	v = Math.pow(3,			// max 3 times lower/faster
			(iv - 10) * .1);
	play.abcplay.set_speed(v);
	spvl.innerHTML = v
}
// set volume
function set_vol(v) {
    var	gvl = document.getElementById("gvl");
	gvl.innerHTML = v.toFixed(2);
	play.abcplay.set_vol(v)
	storage(true, "volume", v == 0.7 ? 0 : v.toFixed(2))
}
function notehlight(i, on) {
	if (play.stop) {
		if (on)				// (should not occur anymore)
			return
		if (play.stop < 0)		// if first stop
			play.stop = i		// keep the last note reference
		if (i == selx[1])		// if end selection
			return			// don't remove highlight
	}
	var elts = document.getElementsByClassName('_' + i + '_');
	if (elts && elts[0]) {
		if (on)
			do_scroll(elts[0]);
		elts[0].style.fillOpacity = on ? 0.4 : 0
	}
}
function endplay(repv) {
	if (play.loop) {
		play.abcplay.play(play.si, play.ei)
		return
	}
	play.playing = false;
	play.repv = repv		// repeat variant number for continue

	// redisplay the selection
	selx[0] = selx[1] = 0;
	setsel(0, selx_sav[0]);
	setsel(1, selx_sav[1])
}

// start playing
//	-1: All (removed)
//	0: Tune
//	1: Selection
//	2: Loop
//	3: Continue
function play_tune(what) {
	if (!abc)
		return			// no generation yet
    var	i, si, ei, elt,
	C = abc2svg.C,
	tunes = abc.tunes

	if (play.playing) {
		if (!play.stop) {
			play.stop = -1;
			play.abcplay.stop()
		}
		return
	}

	// search a symbol to play
	function gnrn(sym, loop) {	// go to the next real note (not tied)
	    var	i
		while (1) {
			switch (sym.type) {
			case C.NOTE:
				i = sym.nhd + 1
				while (--i >= 0) {
					if (sym.notes[i].ti2)
						break
				}
				if (i < 0)
					return sym
				break
			case C.REST:
			case C.GRACE:
				return sym
			case C.BLOCK:
				switch (sym.subtype) {
				case "midictl":
				case "midiprog":
					return sym
				}
				break
			}
			if (!sym.ts_next) {
				if (!loop)
					return gprn(sym, 1)
				return sym
			}
			sym = sym.ts_next
		}
		// not reached
	}

	function gprn(sym, loop) {	// go to the previous real note (not tied)
	    var	i
		while (1) {
			switch (sym.type) {
//			case C.BAR:
//fixme: there may be a right repeat!
//			break
			case C.NOTE:
				i = sym.nhd + 1
				while (--i >= 0) {
					if (sym.notes[i].ti2)
						break
				}
				if (i < 0)
					return sym
				break
			case C.REST:
			case C.GRACE:
				return sym
			case C.BLOCK:
				switch (sym.subtype) {
				case "midictl":
				case "midiprog":
					return sym
				}
				break
			}
			if (!sym.ts_prev) {
				if (!loop)
					return gnrn(sym, 1)
				return sym
			}
			sym = sym.ts_prev
		}
		// not reached
	}

	function gsot(si) {		// go to the first symbol of a tune
	    var	sym = syms[si].p_v.sym

		while (!sym.seqst)
			sym = sym.ts_prev
		return sym
	}
	function get_se(si) {			// get the starting symbol
	    var	sym = syms[si]

		while (!sym.seqst)
			sym = sym.ts_prev
		return sym
	} // get_se()

	function get_ee(si) {			// get the ending symbol
	    var	sym = syms[si]

		while (sym.ts_next && !sym.ts_next.seqst)
			sym = sym.ts_next
		return sym
	} // get_ee()

	// start playing
	function play_start(si, ei) {
		if (!si)
			return
		selx_sav[0] = selx[0];		// remove the colors
		selx_sav[1] = selx[1];
		setsel(0, 0);
		setsel(1, 0);

		play.stop = 0;
		play.abcplay.play(si, ei, play.repv)
	}

	// play tune()
	ctxMenu.style.display = "none";	// remove the play menu

	play.playing = true;
	if (tunes.length) {		// if new display

		// generate the play data of all tunes
		while (1) {
			elt = tunes.shift()
			if (!elt)
				break
			play.abcplay.add(elt[0], elt[1], elt[3])
		}

		play.si = play.ei = null
		play.stop = 0
		play.loop = false
	}

	// if loop again
	if (what == 2 && play.loop) {
		play_start(play.si, play.ei)
		return
	}

	// get the starting and ending play indexes, and start playing

	if (what == 3 && play.stop > 0) {	// if stopped and continue
		play_start(get_se(play.stop), play.ei)
		return
	}
	if (what != 0 && selx[0] && selx[1]) {	// if full selection
		si = get_se(selx[0]);
		ei = get_ee(selx[1])
	} else if (what != 0 && selx[0]) {	// if selection without end
		si = get_se(selx[0]);
		ei = null
	} else if (what != 0 && selx[1]) {	// if selection without start
		si = gsot(selx[1])
		ei = get_ee(selx[1])
	} else {				// no selection => tune
		elt = play.click.svg		// (dummy)
		si = elt.getElementsByClassName('abcr') // symbols in the SVG
		if (!si.length) {
			play.playing = false
			return			// not in a tune!
		}
		i = Number(si[0].getAttribute('class').slice(6, -1))
		si = gsot(i)
		ei = null
	}

	if (what != 3) {		// if not continue
		play.si = si;
		play.ei = ei;
		play.loop = what == 2
		play.repv = 0
	}

	play_start(si, ei)
}

// set the version and initialize the playing engine
function edit_init() {
    var	a, i, e

	// loop until abc2svg is fully loaded
	if (typeof abc2svg != "object"
	 || !abc2svg.modules) {
		setTimeout(edit_init, 500)
		return
	}

// function to load javascript files
	abc2svg.loadjs = function(fn, relay, onerror) {
		var s = document.createElement('script');
		if (/:\/\//.test(fn))
			s.src = fn		// absolute URL
		else
			s.src = jsdir + fn;
		s.type = 'text/javascript'
		if (relay)
			s.onload = relay;
		s.onerror = onerror || function() {
			alert('error loading ' + fn)
		}
		document.head.appendChild(s)
	}

	// accept page formatting
	abc2svg.abc_end = function() {}

	function set_pref() {
	    var	v = storage(true, "fontsz")
		if (v) {
			elt_ref.source.style.fontSize =
				elt_ref.src1.style.fontSize =
					v + "px";
			document.getElementById("fontsize").value =
					Number(v)
		}

		// set the language
		// if not defined, get the one of the navigator
		v = storage(true, "lang");
		if (!v) {
			v = (navigator.languages ?
				navigator.languages[0] :
				navigator.language).split('-')[0]
			switch (v) {
			case "de":
			case "en":
			case "fr":
			case "it": break
			case "pt": v = "pt_BR"; break
			default: v = "en"; break
			}
		}
		loadlang(v, true)
	}

	document.getElementById("abc2svg").innerHTML =
		'abc2svg-' + abc2svg.version + ' (' + abc2svg.vdate + ')'

	// keep references on the page elements
	a = ["diverr", "source", "src1", "s0", "s1", "target"]
	for (i = 0; i < a.length; i++) {
		e = a[i]
		elt_ref[e] = document.getElementById(e)
	}

	// set the callback functions
	document.getElementById("saveas").onclick = saveas;
	elt_ref.s0.onclick = function(){selsrc(0)};
	elt_ref.s1.onclick = function(){selsrc(1)};
	elt_ref.target.onclick = selsvg;
	elt_ref.source.onselect = seltxt;

	// remove the selection on print
	window.onbeforeprint = function() {
		selx_sav[0] = selx[0];		// remove the colors
		selx_sav[1] = selx[1];
		setsel(0, 0);
		setsel(1, 0)
	};
	window.onafterprint = function() {
		setsel(0, selx_sav[0]);
		setsel(1, selx_sav[1])
	}

	// if playing is possible, load the playing script
	if (window.AudioContext || window.webkitAudioContext
	 || navigator.requestMIDIAccess) {
		abc2svg.loadjs("snd-1.js", function() {
			play.abcplay = AbcPlay({
					onend: endplay,
					onnote:notehlight,
					});
			document.getElementById("playdiv1").style.display =
				document.getElementById("playdiv3").style.display =
				document.getElementById("playdiv4").style.display =
					"list-item";

			document.getElementById("sfu").value = play.abcplay.set_sfu();
//			document.getElementById("spv").innerHTML =
//				Math.log(play.abcplay.set_speed()) / Math.log(3);
			document.getElementById("gvol").setAttribute("value",
				play.abcplay.set_vol() * 10)
			document.getElementById("gvl").setAttribute("value",
				(play.abcplay.set_vol() * 10).toFixed(2))
		});

		// display the play menu
		// This function is called on non left click
		function show_menu(evt) {
		    var	x, y,
			elt = evt.target,
			cl = elt.getAttribute('class')

			// if right click on an element, select it
			if (cl && cl.substr(0, 4) == 'abcr') {
				setsel(1, Number(cl.slice(6, -1)))
				evt.preventDefault()
				return
			}

			// if the play menu is already active
			// display the default context menu
			ctxMenu = document.getElementById("ctxMenu");
			if (ctxMenu.style.display == "block")
				return

			// otherwise, display the play menu
			evt.preventDefault()
			play.click = {	// keep the click references for 'play tune'
				svg: elt,
				Y: evt.pageY
			}

			ctxMenu.style.display = "block";
			x = evt.pageX - elt_ref.target.parentNode.offsetLeft
					+ elt_ref.target.parentNode.scrollLeft;
			y = evt.pageY + elt_ref.target.parentNode.scrollTop;
			ctxMenu.style.left = (x - 30) + "px";
			ctxMenu.style.top = (y - 10) + "px"
		} // showmenu

		e = elt_ref.target
//		e.onauxclick = show_menu	// right or middle buttons (KO in Safari)
		e.ondblclick = show_menu	// double click
		e.oncontextmenu = show_menu
	}
	set_pref()	// set the preferences from local storage
}

// drag and drop
function drag_enter(evt) {
	evt.stopImmediatePropagation();
	evt.preventDefault()	// allow drop
//fixme: "move" does not work
//	evt.dataTransfer.dropEffect = evt.ctrlKey ? "move" : "copy"
}
function drop(evt) {
	evt.stopImmediatePropagation();
	evt.preventDefault()
	// check if text
	var data = evt.dataTransfer.getData("text")
	if (data) {			// insert the text at the mouse location
	    var	x = evt.layerX,
		y = elt_ref.source.scrollTop + evt.layerY,
		h = elt_ref.source.offsetHeight / elt_ref.source.rows,
		w = elt_ref.source.offsetWidth / elt_ref.source.cols

		w = (x / w) | 0		// column
		h = (y / h) | 0		// row
		h = soffs(h, w)

	    var	e = evt.target
		e.value = e.value.slice(0, h)
			+ data
			+ e.value.slice(h)
		src_change()
		return
	}
	// check if file
	data = evt.dataTransfer.files	// FileList object.
	if (data.length) {
	    var reader = new FileReader(),
		s = srcidx == 0 ? "source" : "src1"

		elt_ref["s" + srcidx].value = abc_fname[srcidx] = data[0].name
		reader.onload = function(evt) {
			elt_ref[s].value = evt.target.result
			chg = -1			// no change yet
			src_change()
		}
		reader.readAsText(data[0],"UTF-8")
//		return
	}
}

// render the music 2 seconds after source change
var timer
function src_change() {
	clearTimeout(timer);
	if (!play.playing)
		timer = setTimeout(render, 2000)
}

// wait for scripts to be loaded
window.addEventListener("load", edit_init)
