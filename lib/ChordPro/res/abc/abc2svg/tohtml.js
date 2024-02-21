// abc2svg - tohtml.js - HTML+SVG generation
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

    var	init_done, pw, ml, mr, pkf, lkf, fn,
	h_sty = ""

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

abc2svg.abort = function(e) {
	if (!init_done)				// if empty document
		user.img_out('')
	abc.parse.state = 0			// force block flush
	abc.blk_flush()
	if (typeof abc2svg.printErr == 'function')
		abc2svg.printErr(e.message + "\n*** Abort ***\n" + e.stack)
	else
		abc2svg.print("<pre>" + e.message + "\n*** Abort ***\n" + e.stack + "</pre>")
	abc2svg.abc_end()
	abc2svg.quit()
}

function get_date() {
	return (new Date()).toUTCString()
} // get_date()

function header_footer(str) {
    var	c, d, i, t,
	j = 0,
	r = ["", "", ""]

	if (str[0] == '"')
		str = str.slice(1, -1)
	while (1) {
		i = str.indexOf('$', j)
		if (i < 0)
			break
		c = str[++i]
		switch (c) {
		case 'd':
			if (!abc2svg.get_mtime)
				break // cannot know the modification date of the file
			d = abc2svg.get_mtime(abc.parse.fname)
			break
		case 'D':
			d = get_date()
			break
		case 'F':
			d = abc.parse.fname
			break
		case 'I':
			str = str.replace('$', '')
			d = str[i]
		case 'T':
			t = abc.info()[c]
			d = t ? t.split('\n', 1)[0] : ''
			break
		case 'P':
			d = '\x0c'	// form feed
			break
		case 'V':
			d = "abc2svg-" + abc2svg.version
			break
		default:
			d = ''
			break
		}
		str = str.replace('$' + c, d)
		j = i
	}
	str = str.split('\n')
	for (j = 0; j < str.length; j++) {
		if (j != 0)
			for (i = 0; i < 3; i++)
				r[i] += '<br>'
		t = str[j].split('\t')
		if (t.length == 1) {
			r[1] += t[0]
		} else {
			for (i = 0; i < 3; i++) {
				if (t[i])
					r[i] += t[i]
			}
		}
	}
	return r
} // header_footer()

// set a paragraph style
function set_pstyle() {
    var	nml, nmr, nlkf, npkf, npw,
	cfmt = abc.cfmt(),
	psty = ''

	nml = cfmt.leftmargin
	if (nml != ml) {
		if (ml == undefined)
			ml = nml
		psty += 'margin-left:' + nml.toFixed(1) + 'px;'
	}
	nmr = cfmt.rightmargin
	if (nmr != mr) {
		if (mr == undefined)
			mr = nmr
		psty += 'margin-right:' + nmr.toFixed(1) + 'px;'
	}
	nlkf = cfmt.lineskipfac
	if (nlkf != lkf) {
		if (lkf == undefined)
			lkf = nlkf
		psty += 'line-height:' + ((nlkf * 100) | 0).toString() + '%;'
	}
	npkf = cfmt.parskipfac
	if (npkf != pkf) {
		if (pkf == undefined)
			pkf = npkf
		psty += 'margin-bottom:' + npkf.toFixed(2) + 'em;'
	}
	npw = cfmt.pagewidth
	if (npw != pw || nml != ml || nmr != mr) {
		if (pw == undefined)
			pw = npw
		psty += 'width:' + (npw - nml - nmr).toFixed(1) + 'px;'
	}
	return psty
}

// entry point from cmdline
abc2svg.abc_init = function(args) {
    var cfmt = abc.cfmt()

	// output a header or footer
	function gen_hf(type, str) {
	    var	i, page,
		lcr = ["l", "c", "r"],
//fixme: handle font changes?
		a = header_footer(clean_txt(str))

		abc2svg.print('<table class="' + type + '" width="100%"><tr>')
		for (i = 0; i < 3; i++) {
			str = a[i]
			if (!str)
				str = '&nbsp;'
//fixme
			if (str.indexOf('\x0c') >= 0) {
				str = str.replace('\x0c', '')
				page = " page"
			} else {
				page = ''
			}
			abc2svg.print('<td class="' + lcr[i] + page +
				'" width="33%">' +
				str + '</td>')
		}
		abc2svg.print('</table>')
	}

	user.page_format = true

	// output the html header
	user.img_out = function(str) {
		if (!str)
			return
		if (init_done) {
			abc2svg.print(str)
			return
		}
		if (/^<style>[^<]+<\/style>$/.test(str)) {
			h_sty = str.replace(/^<style>\n|<\/style>$/g,'')
			return
		}

		var	header = cfmt.header,
			footer = cfmt.footer,
			topmargin = cfmt.topmargin || "1cm",
			botmargin = cfmt.botmargin || "1cm",
			media_s = '@media print {\n\
	body {margin:0; padding:0; border:0}\n\
	.newpage {page-break-before: always}\n\
	div.nobrk {page-break-inside: avoid}\n\
}',
			media_f = '@media screen {\n\
	.header, .footer, .h-sp, .f-sp {display: none}\n\
}\n\
@media print {\n\
	body {margin:0; padding:0; border:0;\n\
		counter-reset: page;\n\
		counter-increment: page; }\n\
	.newpage {page-break-before: always}\n\
	div.nobrk {page-break-inside: avoid}\n\
	.header {\n\
		position: fixed;\n\
		top: ' + cfmt.headerfont.size + 'px;\n\
		height: ' + (cfmt.headerfont.size * 2) + 'px;\n\
		' + abc.style_font(cfmt.headerfont) + ';\n\
		left: ' + cfmt.leftmargin.toFixed(1) + 'px;\n\
		width: ' + (cfmt.pagewidth - cfmt.leftmargin
				- cfmt.rightmargin).toFixed(1) + 'px\n\
	}\n\
	.footer {\n\
		position: fixed;\n\
		bottom: 0;\n\
		height: ' + (cfmt.footerfont.size * 2) + 'px;\n\
		' + abc.style_font(cfmt.footerfont) + ';\n\
		left: ' + cfmt.leftmargin.toFixed(1) + 'px;\n\
		width: ' + (cfmt.pagewidth - cfmt.leftmargin
				- cfmt.rightmargin).toFixed(1) + 'px\n\
	}\n\
	.h-sp, .f-sp {height: '
			+ (cfmt.headerfont.size * 2) + 'px}\n\
	div.page:after {\n\
		counter-increment: page;\n\
		content: counter(page);\n\
	}\n\
	.l {text-align: left}\n\
	.c {text-align: center}\n\
	.r {text-align: right}\n\
}';

		// no margin / header / footer when SVG page formatting
		if (abc.page)
			topmargin = botmargin = header = footer = 0

		abc2svg.print('<!DOCTYPE html>\n\
<html>\n\
<meta charset="utf-8"/>\n\
<meta name="generator" content="abc2svg-' + abc2svg.version + '"/>\n\
<!-- CreationDate: ' + get_date() + '-->\n\
<style>\n\
body {width:' + cfmt.pagewidth.toFixed(0) +'px}\n\
svg {display:block}\n\
p {' + set_pstyle() + 'margin-top:0}\n\
p span {line-height:' + ((cfmt.lineskipfac * 100) | 0).toString() + '%}\n' +
			((header || footer) ? media_f : media_s))
// important for chrome and --headless (abctopdf)
		if (abc.page)
			abc2svg.print('@page{size:' +
				(cfmt.pagewidth / 96).toFixed(2) + 'in ' +
				(cfmt.pageheight / 96).toFixed(2) + 'in;margin:0}')

		abc2svg.print(h_sty + '</style>\n\
<title>' + fn.replace(/.*\//,'')
			+ '</title>\n\
<body>')
		if (header || footer) {
			if (header)
				gen_hf("header", header)
			if (footer)
				gen_hf("footer", footer)

			abc2svg.print('\
<table style="margin:0" width="100%">\n\
  <thead><tr><td>\n\
    <div class="h-sp">&nbsp;</div>\n\
  </td></tr></thead>\n\
  <tbody><tr><td>')
			init_done = 2		// with header/footer
		} else {
			init_done = 1
		}

		// output the first generated string
		abc2svg.print(str)
	}

	// get the main ABC source file name
	for (var i = 0; i < args.length; i++) {
	    var	a = args[i]

		if (a[0] == '-') {
			i++
			continue
		}
		fn = a
		break
	}
}

abc2svg.abc_end = function() {
    var	font_style = abc.get_font_style()

	if (!init_done)				// if empty document
		user.img_out('')
	if (user.errtxt)
		abc2svg.print("<pre>" + clean_txt(user.errtxt) + "</pre>")
	if (font_style)				// if some %%text at the end
		abc2svg.print('<style>\n' + font_style + '\n</style>')
	if (init_done == 2)			// if with header/footer
		abc2svg.print('\
    </td></tr></tbody>\n\
  <tfoot><tr><td>\n\
<div class="f-sp">&nbsp;</div>\n\
  </td></tr></tfoot>\n\
</table>')
	abc2svg.print('</html>')
}
