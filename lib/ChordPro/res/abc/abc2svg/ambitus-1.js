// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2021 Jean-Francois Moine - LGPL3+
//ambitus.js-module to insert an ambitus at start of a voice
abc2svg.ambitus={do_ambitus:function(){var C=abc2svg.C,s,v,p_v,min,max,voice_tb=this.get_voice_tb()
for(v=0;v<voice_tb.length;v++){p_v=voice_tb[v];if(p_v.second)
continue
min=100;max=-100
for(s=p_v.sym;s;s=s.next){if(s.type!=C.NOTE)
continue
if(s.notes[s.nhd].pit>max)
max=s.notes[s.nhd].pit
if(s.notes[0].pit<min)
min=s.notes[0].pit}
if(min==100)
continue
s=p_v.clef;s.stem=1;s.head=C.FULL;s.stemless=true;s.nhd=1;s.notes=[{dur:C.BLEN/4,pit:min,shhd:0},{dur:C.BLEN/4,pit:max,shhd:0}]}},draw_symbols:function(of,p_voice){var staff_tb=this.get_staff_tb(),s=p_voice.sym
if(s.clef_type!=undefined&&s.nhd>0){s.x-=26;this.set_scale(s);this.draw_note(s)
if(s.notes[1].pit-s.notes[0].pit>4){this.xypath(s.x,3*(s.notes[1].pit-18)+staff_tb[s.st].y);this.out_svg('v'+
((s.notes[1].pit-s.notes[0].pit)*3).toFixed(1)+'" stroke-width=".6"/>\n')}
s.x+=26;s.nhd=0
p_voice.clef.nhd=0}
of(p_voice)},set_pitch:function(of,last_s){of(last_s)
if(!last_s&&this.cfmt().ambitus)
abc2svg.ambitus.do_ambitus.call(this)},set_fmt:function(of,cmd,param){if(cmd=="ambitus"){this.cfmt().ambitus=param
return}
of(cmd,param)},set_width:function(of,s){if(s.clef_type!=undefined&&s.nhd>0){s.wl=40;s.wr=12}else{of(s)}},set_hooks:function(abc){abc.draw_symbols=abc2svg.ambitus.draw_symbols.bind(abc,abc.draw_symbols);abc.set_pitch=abc2svg.ambitus.set_pitch.bind(abc,abc.set_pitch);abc.set_format=abc2svg.ambitus.set_fmt.bind(abc,abc.set_format);abc.set_width=abc2svg.ambitus.set_width.bind(abc,abc.set_width)}}
abc2svg.modules.hooks.push(abc2svg.ambitus.set_hooks);abc2svg.modules.ambitus.loaded=true
