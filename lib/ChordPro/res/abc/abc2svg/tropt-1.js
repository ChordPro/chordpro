//tropt.js-module to optimize the notes after transposition
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.tropt={set_pitch:function(of,last_s){if(last_s){of(last_s)
return}
var v,p_v,s,m,nt,p,a,np,na,C=abc2svg.C,vo_tb=this.get_voice_tb(),nv=vo_tb.length
function ok(s,p){var nt,m
while(s){if(s.bar_type)
return 1
if(s.type==C.NOTE){for(m=0;m<=s.nhd;m++){nt=s.notes[m]
if(nt.pit==p)
return nt.acc}}
s=s.next}
return 1}
for(v=0;v<nv;v++){p_v=vo_tb[v]
if(!p_v.tropt||!p_v.key.k_none)
continue
for(s=p_v.sym;s;s=s.next){if(s.type!=C.NOTE)
continue
for(m=0;m<=s.nhd;m++){nt=s.notes[m]
if(nt.tie_s){nt.pit=nt.tie_s.pit
continue}
p=nt.pit%7
a=nt.acc
na=3
switch(a){case-1:switch(p){case 2:case 5:break
default:continue}
np=nt.pit-1
break
case-2:switch(p){case 2:case 5:na=-1
break}
np=nt.pit-1
break
case 1:switch(p){case 1:case 4:break
default:continue}
np=nt.pit+1
break
case 2:switch(p){case 1:case 4:na=1
break}
np=nt.pit+1
break
default:continue}
if(ok(s,np)){nt.pit=np
nt.acc=na}}}}
of(last_s)},do_pscom:function(of,text){if(text.indexOf("tropt ")==0)
this.set_v_param("tropt",text.split(/[ \t]/)[1])
else
of(text)},set_vp:function(of,a){var i,curvoice=this.get_curvoice()
for(i=0;i<a.length;i++){if(a[i]=="tropt="){curvoice.tropt=this.get_bool(a[i+1])
break}}
of(a)},set_hooks:function(abc){abc.do_pscom=abc2svg.tropt.do_pscom.bind(abc,abc.do_pscom)
abc.set_pitch=abc2svg.tropt.set_pitch.bind(abc,abc.set_pitch)
abc.set_vp=abc2svg.tropt.set_vp.bind(abc,abc.set_vp)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.tropt=abc2svg.tropt.set_hooks
