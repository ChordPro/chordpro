//equalbars.js-module to set equal spaced measure bars
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.equalbars={output_music:function(of){this.equalbars_d=0;of()},set_fmt:function(of,cmd,parm){if(cmd!="equalbars"){of(cmd,parm)
return}
var fmt=this.cfmt()
fmt.equalbars=this.get_bool(parm)
fmt.stretchlast=1},set_sym_glue:function(of,width){var C=abc2svg.C,s,s2,d,w,i,n,x,g,t,t0,bars=[],tsfirst=this.get_tsfirst();of(width)
if(!this.cfmt().equalbars)
return
for(s2=tsfirst;s2;s2=s2.next){switch(s2.type){default:continue
case C.GRACE:case C.MREST:case C.NOTE:case C.REST:case C.SPACE:break}
break}
if(!s2)
return
t0=t=s2.time
for(s=s2;s.next;s=s.next){if(s.type==C.BAR&&s.seqst&&s.time!=t){bars.push([s,s.time-t]);t=s.time}}
if(s.time!=t)
bars.push([s,s.time-t])
else
bars[bars.length-1][0]=s
t=s.time
if(s.dur)
t+=s.dur;n=bars.length
if(n<=1)
return
if(s.x<width){w=0
x=0
for(i=0;i<n;i++){s=bars[i][0]
if(s.x-x>w)
w=s.x-x
x=s.x}
if(w*n<width)
width=w*n
this.set_realwidth(width)}
x=s2.type==C.GRACE?s2.extra.x:(s2.x-s2.wl)
if(this.equalbars_d<x)
this.equalbars_d=x
d=this.equalbars_d
w=(width-d)/(t-t0)
for(i=0;i<n;i++){do{if(s2.type==C.GRACE){for(g=s2.extra;g;g=g.next)
g.x=d+g.x-x}else{s2.x=d+s2.x-x}
s2=s2.ts_next}while(!s2.seqst)
s=bars[i][0];f=w*bars[i][1]/(s.x-x)
for(;s2!=s;s2=s2.ts_next){if(s2.type==C.GRACE){for(g=s2.extra;g;g=g.next)
g.x=d+(g.x-x)*f}else{s2.x=d+(s2.x-x)*f}}
d+=w*bars[i][1];x=s2.x
while(1){s2.x=d;s2=s2.ts_next
if(!s2||s2.seqst)
break}
if(!s2)
break}},set_hooks:function(abc){abc.output_music=abc2svg.equalbars.output_music.bind(abc,abc.output_music);abc.set_format=abc2svg.equalbars.set_fmt.bind(abc,abc.set_format);abc.set_sym_glue=abc2svg.equalbars.set_sym_glue.bind(abc,abc.set_sym_glue)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.equalbars=abc2svg.equalbars.set_hooks
