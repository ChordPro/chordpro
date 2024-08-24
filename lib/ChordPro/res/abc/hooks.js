// hooks.js - special purpose hooks
if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.hooks = {

    draw_symbols: function(of, p) {
	of(p)
	let staff_tb = abc.get_staff_tb()
	abc2svg.print( "<!-- staffbase:" + staff_tb[0].y + " -->" )
    },

    set_hooks: function(abc) {
	abc.draw_symbols = abc2svg.hooks.draw_symbols.bind(abc, abc.draw_symbols);
    }
}

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.hooks = abc2svg.hooks.set_hooks
