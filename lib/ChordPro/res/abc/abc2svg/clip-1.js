//clip.js-module to handle the%%clip command
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.clip={get_clip:function(parm){var C=abc2svg.C
function get_symsel(a){var j,d,sq,b=a.match(/(\d+)([a-z]?)(:\d+\/\d+)?/)
if(!b)
return
if(b[2])
sq=b[2].charCodeAt(0)-0x61
if(!b[3])
return{m:b[1],t:0,sq:sq}
a=b[3].match(/:(\d+)\/(\d+)/)
if(!a||a[2]<1)
return
return{m:b[1],t:a[1]*C.BLEN/a[2],sq:sq}}
var b,c,a=parm.split(/[ -]/)
if(a.length!=3){this.syntax(1,this.errs.bad_val,"%%clip")
return}
if(!a[1])
b={m:0,t:0}
else
b=get_symsel(a[1]);c=get_symsel(a[2])
if(!b||!c){this.syntax(1,this.errs.bad_val,"%%clip")
return}
this.cfmt().clip=[b,c]},do_clip:function(){var C=abc2svg.C
voice_tb=this.get_voice_tb(),cfmt=this.cfmt()
function go_global_time(s,sel){var s2,bar_time,seq
if(sel.m<=1){if(sel.m==1){for(s2=s;s2;s2=s2.ts_next){if(s2.type==C.BAR&&s2.time!=0)
break}
if(s2.time<voice_tb[this.get_cur_sy().top_voice].meter.wmeasure)
s=s2}}else{for(;s;s=s.ts_next){if(s.type==C.BAR&&s.bar_num>=sel.m)
break}
if(!s)
return
if(sel.sq){seq=sel.sq
for(s=s.ts_next;s;s=s.ts_next){if(s.type==C.BAR&&s.bar_num==sel.m){if(--seq==0)
break}}
if(!s)
return}}
if(sel.t==0)
return s;bar_time=s.time+sel.t
while(s.time<bar_time){s=s.ts_next
if(!s)
return s}
do{s=s.ts_prev}while(!s.seqst)
return s}
var s,s2,sy,p_voice,v
s=this.get_tsfirst()
if(cfmt.clip[0].m>0||cfmt.clip[0].t>0){s=go_global_time(s,cfmt.clip[0])
if(!s){this.set_tsfirst(null)
return}
sy=this.get_cur_sy()
for(s2=this.get_tsfirst();s2!=s;s2=s2.ts_next){switch(s2.type){case C.CLEF:s2.p_v.clef=s2
break
case C.KEY:s2.p_v.key=this.clone(s2.as.u.key)
break
case C.METER:s2.p_v.meter=this.clone(s2.as.u.meter)
break
case C.STAVES:sy=s2.sy;this.set_cur_sy(sy)
break}}
for(v=0;v<voice_tb.length;v++){p_voice=voice_tb[v]
for(s2=s;s2;s2=s2.ts_next){if(s2.v==v){delete s2.prev
break}}
p_voice.sym=s2}
this.set_tsfirst(s)
delete s.ts_prev}
s=go_global_time(s,cfmt.clip[1])
if(!s)
return
do{s=s.ts_next
if(!s)
return}while(!s.seqst)
for(v=0;v<voice_tb.length;v++){p_voice=voice_tb[v]
for(s2=s.ts_prev;s2;s2=s2.ts_prev){if(s2.v==v){delete s2.next
break}}
if(!s2)
p_voice.sym=null}
delete s.ts_prev.ts_next},do_pscom:function(of,text){if(text.slice(0,5)=="clip ")
abc2svg.clip.get_clip.call(this,text)
else
of(text)},set_bar_num:function(of){of()
if(this.cfmt().clip)
abc2svg.clip.do_clip.call(this)},set_hooks:function(abc){abc.do_pscom=abc2svg.clip.do_pscom.bind(abc,abc.do_pscom);abc.set_bar_num=abc2svg.clip.set_bar_num.bind(abc,abc.set_bar_num)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.clip=abc2svg.clip.set_hooks
