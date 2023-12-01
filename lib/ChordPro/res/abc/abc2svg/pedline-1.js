// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2021 Jean-Francois Moine - LGPL3+
//pedline.js-module to draw pedal lines instead of'Ped .. *'
abc2svg.pedline={draw_all_deco:function(of){var de,i,a_de=this.a_de()
if(!a_de.length)
return
if(this.cfmt().pedline){for(i=0;i<a_de.length;i++){de=a_de[i]
if(de.dd.name!="ped)")
continue
if(de.prev&&de.prev.dd.name=="ped)"){de.defl.nost=true
de.prev.defl.noen=true
de.x=de.prev.s.x-5
de.val=de.s.x-de.x-5
de.prev.val=de.x-de.prev.x}else{de.x-=3
de.val+=10}}}
of()},out_lped:function(of,x,y,val,defl){if(!this.cfmt().pedline){of(x,y,val,defl)
return}
this.xypath(x,y+16)
if(defl.nost){this.out_svg("l2.5 6")
val-=2.5}else{this.out_svg("v6")}
if(defl.noen){val-=2.5
this.out_svg("h"+val.toFixed(1)+'l2.5 -6"/>\n')}else{this.out_svg("h"+val.toFixed(1)+'v-6"/>\n')}},set_fmt:function(of,cmd,param){if(cmd=="pedline")
this.cfmt().pedline=this.get_bool(param)
else
of(cmd,param)},set_hooks:function(abc){abc.draw_all_deco=abc2svg.pedline.draw_all_deco.bind(abc,abc.draw_all_deco)
abc.out_lped=abc2svg.pedline.out_lped.bind(abc,abc.out_lped)
abc.set_format=abc2svg.pedline.set_fmt.bind(abc,abc.set_format)}}
abc2svg.modules.hooks.push(abc2svg.pedline.set_hooks)
abc2svg.modules.pedline.loaded=true
