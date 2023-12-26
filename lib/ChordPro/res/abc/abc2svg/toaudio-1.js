// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2020 Jean-Francois Moine - LGPL3+
//toaudio.js-audio generation
function ToAudio(){var C=abc2svg.C,a_e,p_time,abc_time,play_factor
return{clear:function(){var a_pe=a_e;a_e=null
return a_pe},add:function(start,voice_tb){var i,n,dt,d,v,rep_st_s,rep_en_s,rep_nx_s,rep_st_fac,instr=[],s=start
function set_voices(){var v,p_v,s,mi
a_e.push(new Float32Array([0,0,-1,121,0,1,0]))
for(v=0;v<voice_tb.length;v++){p_v=voice_tb[v];mi=p_v.instr||0
if(p_v.midictl){for(s=p_v.sym;s;s=s.next)
if(s.dur)
break
if(!s)
continue
p_v.midictl.forEach(function(val,i){a_e.push(new Float32Array([s.istart,0,-1,i,val,1,v]))})}
instr[v]=mi}}
function do_tie(s,b40,d){var i,note,v=s.v,end_time=s.time+s.dur
for(s=s.ts_next;;s=s.ts_next){if(!s)
return d
if(s==rep_en_s){s=rep_nx_s
while(s&&s.v!=v)
s=s.ts_next
if(!s)
return d
end_time=s.time}
if(s.time!=end_time)
return d
if(s.type==C.NOTE&&s.v==v)
break}
i=s.notes.length
while(--i>=0){note=s.notes[i]
if(note.b40==b40){note.ti2=true
d+=s.dur/play_factor;return note.tie_ty?do_tie(s,b40,d):d}}
return d}
function gen_grace(s){var g,i,n,t,d,s2,next=s.next
if(s.sappo){d=C.BLEN/16}else if((!next||next.type!=C.NOTE)&&s.prev&&s.prev.type==C.NOTE){d=s.prev.dur/2}else{next.ts_prev.ts_next=next.ts_next;next.ts_next.ts_prev=next.ts_prev;for(s2=next.ts_next;s2;s2=s2.ts_next){if(s2.time!=next.time){next.ts_next=s2
next.ts_prev=s2.ts_prev;next.ts_prev.ts_next=next;s2.ts_prev=next
break}}
d=next.dur/12
if(d&(d-1)==0)
d=next.dur/2
else
d=next.dur/3;next.time+=d;next.dur-=d}
n=0
for(g=s.extra;g;g=g.next)
if(g.type==C.NOTE)
n++;d/=n*play_factor;t=p_time
for(g=s.extra;g;g=g.next){if(g.type!=C.NOTE)
continue
gen_notes(g,t,d);t+=d}}
function gen_notes(s,t,d){for(var i=0;i<=s.nhd;i++){var note=s.notes[i]
if(note.ti2)
continue
a_e.push(new Float32Array([s.istart,t,instr[s.v],note.midi,note.tie_ty?do_tie(s,note.b40,d):d,1,s.v]))}}
if(!a_e){a_e=[]
abc_time=p_time=0;play_factor=C.BLEN/4*120/60}else if(s.time<abc_time){abc_time=s.time}
set_voices()
while(s){if(s.tempo){d=0;n=s.tempo_notes.length
for(i=0;i<n;i++)
d+=s.tempo_notes[i];play_factor=d*s.tempo/60}
dt=s.time-abc_time
if(dt>0){p_time+=dt/play_factor;abc_time=s.time}
switch(s.type){case C.BAR:if(!s.seqst)
break
if(s==rep_en_s){s=rep_nx_s
abc_time=s.time}else if(s.bar_type[0]==':'){rep_nx_s=s
if(!rep_en_s)
rep_en_s=s
if(rep_st_s){s=rep_st_s
play_factor=rep_st_fac}else{s=start;set_voices()}
abc_time=s.time
break}
if(s.bar_type[s.bar_type.length-1]==':'){rep_st_s=s;rep_en_s=null
rep_st_fac=play_factor}else if(s.text&&s.text[0]=='1'){rep_en_s=s}
break
case C.GRACE:if(s.time==0&&abc_time==0){dt=0
if(s.sappo)
dt=C.BLEN/16
else if(!s.next||s.next.type!=C.NOTE)
dt=d/2;abc_time-=dt}
gen_grace(s)
break
case C.REST:case C.NOTE:d=s.dur
if(s.next&&s.next.type==C.GRACE){dt=0
if(s.next.sappo)
dt=C.BLEN/16
else if(!s.next.next||s.next.next.type!=C.NOTE)
dt=d/2;s.next.time-=dt;d-=dt}
d/=play_factor
if(s.type==C.NOTE)
gen_notes(s,p_time,d)
else
a_e.push(new Float32Array([s.istart,p_time,0,0,d,0,s.v]))
break
case C.BLOCK:switch(s.subtype){case"midictl":a_e.push(new Float32Array([s.istart,p_time,-1,s.ctrl,s.val,1,s.v]))
break
case"midiprog":instr[s.v]=s.instr
break}
break}
s=s.ts_next}}}}
if(typeof module=='object'&&typeof exports=='object')
exports.ToAudio=ToAudio
