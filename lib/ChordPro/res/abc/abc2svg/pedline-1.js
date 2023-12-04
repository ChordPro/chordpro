//pedline.js-module to draw pedal lines instead of'Ped .. *'
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.pedline={draw_all_deco:function(of){var de,i,x,dp,ds,a_de=this.a_de()
if(!a_de.length)
return
if(this.cfmt().pedline){for(i=0;i<a_de.length;i++){de=a_de[i]
if(de.dd.name!="ped)")
continue
ds=de.start
dp=de.prev
if(dp&&dp.dd.name=="ped)"&&dp.s.v==ds.s.v){de.defl.nost=dp.defl.noen=2
de.x=ds.s.x-10
de.val=de.s.x-ds.s.x-3
dp.val=de.x-dp.x
if(de.y>dp.y)
de.y=dp.y
dp.y=de.y}else{de.x=ds.s.x-8
if(!de.defl.noen)
de.val=de.s.x-ds.s.x-de.s.wl}}}
of()},out_lped:function(of,x,y,val,defl){if(!this.cfmt().pedline){of(x,y,val,defl)
return}
this.xypath(x,y+8)
if(defl.nost){if(defl.nost==2){this.out_svg("l2.5 6")
val-=2.5}else{this.out_svg("m0 6")}}else{this.out_svg("v6")}
if(defl.noen){if(defl.noen==2){val-=2.5
this.out_svg("h"+val.toFixed(1)+'l2.5 -6')}else{this.out_svg("h"+val.toFixed(1))}}else{this.out_svg("h"+val.toFixed(1)+'v-6')}
this.out_svg('"/>\n')},set_fmt:function(of,cmd,param){if(cmd=="pedline")
this.cfmt().pedline=this.get_bool(param)
else
of(cmd,param)},set_hooks:function(abc){abc.draw_all_deco=abc2svg.pedline.draw_all_deco.bind(abc,abc.draw_all_deco)
abc.out_lped=abc2svg.pedline.out_lped.bind(abc,abc.out_lped)
abc.set_format=abc2svg.pedline.set_fmt.bind(abc,abc.set_format)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.pedline=abc2svg.pedline.set_hooks
