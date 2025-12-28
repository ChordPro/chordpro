//snd-1.js-file to include in html pages with abc2svg-1.js for playing
function AbcPlay(i_conf){var conf=i_conf,init={},audio=ToAudio(),audio5,midi5,current,abcplay={clear:audio.clear,add:audio.add,set_sfu:function(v){if(v==undefined)
return conf.sfu
conf.sfu=v},set_speed:function(v){if(v==undefined)
return conf.speed
conf.new_speed=v},set_vol:function(v){if(v==undefined)
return conf.gain;conf.gain=v
if(current&&current.set_vol)
current.set_vol(v)},play:play,stop:vf}
function vf(){}
function play(istart,i_iend,a_e){init.istart=istart;init.i_iend=i_iend;init.a_e=a_e
if(midi5)
midi5.get_outputs(play2)
else
play2()}
function play2(out){var o,n=window.sessionStorage&&sessionStorage.getItem("audio")
if(!out)
out=[]
o=audio5.get_outputs()
if(o)
Array.prototype.push.apply(out,o)
if(out.length==0){if(conf.onend)
conf.onend()
return}
if(out.length==1){o=0}else{if(n){for(o=0;o<out.length;o++)
if(out[o]==n)
break}
if(!n||o>=out.length){o=-1
var pr="Use"
for(var i=0;i<out.length;i++)
pr+="\n "+i+": "+out[i]
var res=window.prompt(pr,'0')
if(res){o=Number(res)
if(isNaN(o)||o<0||o>=out.length)
o=-1}
if(!res||o<0){if(conf.onend)
conf.onend()
return}
if(window.sessionStorage)
sessionStorage.setItem("audio",out[o])}}
current=out[o]=='sf2'?audio5:midi5;abcplay.play=current.play;abcplay.stop=current.stop
if(current.set_output)
current.set_output(out[o]);abcplay.play(init.istart,init.i_iend,init.a_e)}
conf.gain=0.7;conf.speed=1;(function(){var v
try{if(!localStorage)
return}catch(e){return}
if(!conf.sfu){v=localStorage.getItem("sfu")
if(v)
conf.sfu=v}
v=localStorage.getItem("volume")
if(v)
conf.gain=Number(v)})()
if(typeof Midi5=="function")
midi5=Midi5(conf)
if(typeof Audio5=="function")
audio5=Audio5(conf);return abcplay}
if(typeof module=='object'&&typeof exports=='object')
exports.AbcPlay=AbcPlay
if(!abc2svg)
var abc2svg={}
abc2svg.tmp_tb={grave:30,lento:40,largo:50,adagio:66,andante:86,moderato:96,allegretto:112,allegro:130,vivace:150,presto:180,prestissimo:210}
function ToAudio(){return{add:function(first,voice_tb,cfmt){var toaud=this,C=abc2svg.C,p_time=0,abc_time=0,play_fac=C.BLEN/4*120/60,dt,s_m,d,s=first,rst=s,rst_fac,rsk=[],b_tim,b_typ
function get_beat(){var s=first.p_v.meter
if(!s.a_meter[0])
return C.BLEN/4
if(!s.a_meter[0].bot)
return(s.a_meter[1]&&s.a_meter[1].top=='|')?C.BLEN/2:C.BLEN/4
if(s.a_meter[0].bot=="8"&&s.a_meter[0].top%3==0)
return C.BLEN/8*3
return C.BLEN/s.a_meter[0].bot|0}
function def_beats(){var i,s2,s3,tim,beat=get_beat(),d=first.p_v.meter.wmeasure,nb=d/beat|0,v=voice_tb.length,p_v={id:"_beats",v:v,sym:{type:C.BLOCK,v:v,subtype:"midiprog",chn:9,instr:16384,ts_prev:first}},s={type:C.NOTE,v:v,p_v:p_v,dur:beat,nhd:0,notes:[{midi:37}]}
abc_time=-d
for(s2=first;s2;s2=s2.ts_next){if(s2.bar_type&&s2.time){nb=(2*d-s2.time)/beat|0
abc_time-=d-s2.time
break}}
s2=p_v.sym
for(s3=first;s3&&!s3.time;s3=s3.ts_next){if(s3.type==C.TEMPO){s3=Object.create(s3)
s3.v=v
s3.p_v=p_v
s3.prev=s3.ts_prev=s2
s2.next=s2.ts_next=s3
s2=s3
play_fac=set_tempo(s2)
break}}
voice_tb[v]=p_v
p_v.sym.p_v=p_v
first.time=s2.time=tim=abc_time
if(s3)
p_v.sym.time=tim
for(i=0;i<nb;i++){s3=Object.create(s)
s3.time=tim
s3.prev=s2
s2.next=s3
s3.ts_prev=s2
s2.ts_next=s3
s2=s3
tim+=beat}
s2.ts_next=first.ts_next
s2.ts_next.ts_prev=s2
first.ts_next=p_v.sym
rst=s2.ts_next}
function build_parts(first){var i,j,c,n,v,s=first,p=s.parts,st=[],r=""
for(i=0;i<p.length;i++){c=p[i]
switch(c){case'.':continue
case'(':st.push(r.length)
continue
case')':j=st.pop()
if(j==undefined)
j=r.length
continue}
if(c>='A'&&c<='Z'){j=r.length
r+=c
continue}
n=Number(c)
if(isNaN(n))
break
v=r.slice(j)
if(r.length+v.length*n>128)
continue
while(--n>0)
r+=v}
s.parts=r
s.p_s=[]
while(1){if(!s.ts_next){while(!s.seqst)
s=s.ts_prev
s.part1=first
break}
s=s.ts_next
if(s.part){s.part1=first
v=s.part.text[0]
for(i=0;i<first.parts.length;i++){if(first.parts[i]==v)
first.p_s[i]=s}}}}
function relink(s,dt){var s2
s.time+=dt
if(s.dur)
s.dur-=dt
s.seqst=1
if(dt<0){s2=s
do{s=s.prev}while(s&&!s.dur)
if(s){s.dur+=dt
s.pdur=s.dur/play_fac
if(s.ts_next==s2){s2=null}else{s=s2.ts_prev
while(s&&s.time>=s2.time)
s=s.ts_prev}}}else{s2=s.ts_next
while(s2&&s2.time<s.time)
s2=s2.ts_next}
if(s2){s.ts_prev.ts_next=s.ts_next
if(s.ts_next)
s.ts_next.ts_prev=s.ts_prev
s.ts_prev=s2.ts_prev
s.ts_next=s2
if(s2.ts_prev)
s2.ts_prev.ts_next=s
s.ts_next.ts_prev=s
if(s2.time==s.time)
s2.seqst=0}else if(s.ts_next){s.ts_next.seqst=1}}
function gen_grace(s){if(s.midgen)
return s
s.midgen=1
var g,i,n,t,d,prev,s2,next=s.next
n=0
for(g=s.extra;g;g=g.next)
n++
prev=s.prev
while(prev&&!prev.dur)
prev=prev.prev
if(prev&&(s.sappo||!next||next.type!=C.NOTE)){if(s.sappo){d=C.BLEN/16
if(d>prev.dur/3)
d=prev.dur/3}else{d=prev.dur/2}
s2=s.ts_next
relink(s,-d)
s.ptim-=d/play_fac}else{d=next.dur/12
if(!(d&(d-1)))
d=next.dur/2
else
d=next.dur/3
if(s.p_v.key.k_bagpipe)
d/=2
if(d/n<24)
d=24*n
if(s.sappo&&d>C.BLEN/16)
d=C.BLEN/16
relink(next,d)
s2=s.ts_next}
d/=n*play_fac
t=0
for(g=s.extra;g;g=g.next){g.dtim=t
g.pdur=d
t+=d}
return s2.ts_prev}
function set_tempo(s){if(!s.tempo&&!s.new_beat){var p=(s.tempo_str1||s.tempo_str2)
if(!p)
return play_fac
var upm=abc2svg.tmp_tb[p.toLowerCase()]
if(!upm)
return play_fac
upm*=C.BLEN/240
if(!s_m.a_meter)
return upm
if(!s_m.a_meter[0].bot)
return(s_m.a_meter[1]&&s_m.a_meter[1].top=='|')?upm*2:upm
if(s_m.a_meter[0].bot=="8"&&!(s_m.a_meter[0].top%3))
return upm/2*3
return upm*s_m.a_meter[0].bot/4}
var i,d=0,n=s.tempo_notes.length
for(i=0;i<n;i++)
d+=s.tempo_notes[i]
if(s.new_beat)
return play_fac*s.new_beat/d
return d*s.tempo/60}
function set_variant(s){var d,n=s.text.match(/[1-8]-[2-9]|[1-9,.]|[^\s]+$/g)
while(1){d=n.shift()
if(!d)
break
if(d[1]=='-')
for(i=d[0];i<=d[2];i++)
rsk[i]=s
else if(d>='1'&&d<='9')
rsk[Number(d)]=s
else if(d!=',')
rsk.push(s)}}
if(abc2svg.swing)
abc2svg.swing.swing(first,voice_tb,cfmt)
if(cfmt.chord)
abc2svg.chord(first,voice_tb,cfmt)
s_m=first.p_v.meter
if(cfmt.playbeats&&first.p_v.meter.wmeasure!=1)
def_beats()
if(s.parts)
build_parts(s)
rst_fac=play_fac
while(s){if(s.noplay){s=s.ts_next
continue}
dt=s.time-abc_time
if(dt!=0){p_time+=dt/play_fac
abc_time=s.time}
s.ptim=p_time
if(s.part){rst=s
rst_fac=play_fac}
switch(s.type){case C.BAR:if(s.time!=b_tim){b_tim=s.time
b_typ=0}
if(s.text&&rsk.length>1&&s.text[0]!='1'){if(b_typ&1)
break
b_typ|=1
set_variant(s)
play_fac=rst_fac
rst=rsk[0]}
if(s.bar_type[0]==':'){if(b_typ&2)
break
b_typ|=2
s.rep_p=rst
if(rst==rsk[0])
s.rep_v=rsk
rst=s}
if(s.text){if(s.text[0]=='1'){if(b_typ&1)
break
b_typ|=1
s.rep_s=rsk=[rst]
if(rst.bar_type&&rst.bar_type.slice(-1)!=':')
rst.bar_type+=':'
set_variant(s)
rst_fac=play_fac}}else if(s.bar_type.slice(-1)==':'){if(b_typ&4)
break
b_typ|=4
rst=s
rst_fac=play_fac}
break
case C.GRACE:s=gen_grace(s)
break
case C.REST:case C.NOTE:d=s.dur
d/=play_fac
s.pdur=d
break
case C.METER:s_m=s
break
case C.TEMPO:play_fac=set_tempo(s)
break}
s=s.ts_next}}}}
abc2svg.play_next=function(po){function do_tie(not_s,d){var i,s=not_s.s,C=abc2svg.C,v=s.v,end_time=s.time+s.dur,repv=po.repv
while(1){s=s.ts_next
if(!s||s.time>end_time)
break
if(s.type==C.BAR){if(s.rep_p){if(!po.repn){s=s.rep_p
end_time=s.time}}
if(s.rep_s){if(!s.rep_s[repv])
break
s=s.rep_s[repv++]
end_time=s.time}
while(s.ts_next&&!s.ts_next.dur)
s=s.ts_next
continue}
if(s.time<end_time||!s.ti2)
continue
i=s.notes.length
while(--i>=0){note=s.notes[i]
if(note.tie_s==not_s){d+=s.pdur/po.conf.speed
return note.tie_e?do_tie(note,d):d}}}
return d}
function set_ctrl(po,s2,t){var i,p_v=s2.p_v,s={subtype:"midictl",p_v:p_v,v:s2.v}
p_v.vol=p_v.pan=undefined
for(i in p_v.midictl){s.ctrl=Number(i)
s.val=p_v.midictl[i]
po.midi_ctrl(po,s,t)}
for(s=p_v.sym;s!=s2;s=s.next){if(s.subtype=="midictl"){po.midi_ctrl(po,s,t)}else if(s.subtype=='midiprog'){po.v_c[s.v]=s.chn
if(s.instr!=undefined)
po.c_i[po.v_c[s.v]]=s.instr
po.midi_prog(po,s)}}
i=po.v_c[s2.v]
if(i==undefined)
po.v_c[s2.v]=i=s2.v<9?s2.v:s2.v+1
if(po.c_i[i]==undefined)
po.c_i[i]=0
while(p_v.voice_down){p_v=p_v.voice_down
po.v_c[p_v.v]=i}
po.p_v[s2.v]=true}
function play_cont(po){var d,i,st,m,note,g,s2,t,maxt,now,p_v,C=abc2svg.C,s=po.s_cur
function var_end(s){var i,s2,s3,a=s.rep_v||s.rep_s
ti=0
for(i=1;i<a.length;i++){s2=a[i]
if(s2.time>ti){ti=s2.time
s3=s2}}
for(s=s3;s!=po.s_end;s=s.ts_next){if(s.time==ti)
continue
if(s.rbstop==2)
break}
po.repv=1
return s}
while(s.noplay){s=s.ts_next
if(!s||s==po.s_end){if(po.onend)
po.onend(po.repv)
return}}
t=po.stim+s.ptim/po.conf.speed
now=po.get_time(po)
if(po.conf.new_speed){po.stim=t-s.ptim/po.conf.new_speed
po.conf.speed=po.conf.new_speed
po.conf.new_speed=0}
maxt=t+po.tgen
po.timouts=[]
while(1){switch(s.type){case C.BAR:s2=null
if(s.rep_p){po.repv++
if(!po.repn&&(!s.rep_v||po.repv<=s.rep_v.length)){s2=s.rep_p
po.repn=true}else{if(s.rep_v)
s2=var_end(s)
po.repn=false
if(s.bar_type.slice(-1)==':')
po.repv=1}}
if(s.rep_s){s2=s.rep_s[po.repv]
if(s2){po.repn=false
if(s2==s)
s2=null}else{s2=var_end(s)
if(s2==po.s_end)
break}}
if(s.bar_type.slice(-1)==':'&&s.bar_type[0]!=':')
po.repv=1
if(s2){po.stim+=(s.ptim-s2.ptim)/po.conf.speed
s=s2
while(s&&!s.dur)
s=s.ts_next
if(!s)
break
t=po.stim+s.ptim/po.conf.speed
break}
if(!s.part1){while(s.ts_next&&!s.ts_next.seqst){s=s.ts_next
if(s.part1)
break}
if(!s.part1)
break}}
if(s&&s!=po.s_end&&!s.noplay){switch(s.type){case C.BAR:break
case C.BLOCK:if(s.subtype=="midictl"){po.midi_ctrl(po,s,t)}else if(s.subtype=='midiprog'){po.v_c[s.v]=s.chn
if(s.instr!=undefined)
po.c_i[po.v_c[s.v]]=s.instr
po.midi_prog(po,s)
p_v=s.p_v
while(p_v.voice_down){p_v=p_v.voice_down
po.v_c[p_v.v]=s.chn}}
break
case C.GRACE:if(!po.p_v[s.v])
set_ctrl(po,s,t)
for(g=s.extra;g;g=g.next){d=g.pdur/po.conf.speed
for(m=0;m<=g.nhd;m++){note=g.notes[m]
if(!note.noplay)
po.note_run(po,g,note.midi,t+g.dtim,d)}}
break
case C.NOTE:case C.REST:if(!po.p_v[s.v])
set_ctrl(po,s,t)
d=s.pdur/po.conf.speed
if(s.type==C.NOTE){for(m=0;m<=s.nhd;m++){note=s.notes[m]
if(note.tie_s||note.noplay)
continue
po.note_run(po,s,note.midi,t,note.tie_e?do_tie(note,d):d)}}
if(po.onnote&&s.istart){i=s.istart
st=(t-now)*1000
po.timouts.push(setTimeout(po.onnote,st,i,true))
if(d>2)
d-=.1
setTimeout(po.onnote,st+d*1000,i,false)}
break}}
while(1){if(!s||s==po.s_end||!s.ts_next||s.ts_next==po.s_end||po.stop){if(po.onend)
setTimeout(po.onend,(t-now+d)*1000,po.repv)
po.s_cur=s
return}
s=s.ts_next
if(s.part1&&po.i_p!=undefined){s2=s.part1.p_s[++po.i_p]
if(!s2){s=null
continue}
po.stim+=(s.ptim-s2.ptim)/po.conf.speed
s=s2
t=po.stim+s.ptim/po.conf.speed
po.repv=1}
if(!s.noplay)
break}
t=po.stim+s.ptim/po.conf.speed
if(t>maxt)
break}
po.s_cur=s
po.timouts.push(setTimeout(play_cont,(t-now)*1000
-300,po))}
function get_part(po){var s,i,s_p
for(s=po.s_cur;s;s=s.ts_prev){if(s.parts){po.i_p=-1
return}
s_p=s.part1
if(!s_p||!s_p.p_s)
continue
for(i=0;i<s_p.p_s.length;i++){if(s_p.p_s[i]==s){po.i_p=i
return}}}}
if(po.stop){if(po.onend)
po.onend(po.repv)
return}
get_part(po)
po.stim=po.get_time(po)+.3
-po.s_cur.ptim/po.conf.speed
po.p_v=[]
if(!po.repv)
po.repv=1
play_cont(po)}
if(typeof module=='object'&&typeof exports=='object')
exports.ToAudio=ToAudio
var abcsf2=[]
function Audio5(i_conf){var po,conf=i_conf,empty=function(){},errmsg,ac,gain,model,parser,presets,instr=[],params=[],rates=[],w_instr=0
var b64d=[]
function init_b64d(){var b64l='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/',l=b64l.length
for(var i=0;i<l;i++)
b64d[b64l[i]]=i
b64d['=']=0}
function b64dcod(s){var i,t,dl,a,l=s.length,j=0
dl=l*3/4
if(s[l-1]=='='){if(s[l-2]=='=')
dl--
dl--
l-=4}
a=new Uint8Array(dl)
for(i=0;i<l;i+=4){t=(b64d[s[i]]<<18)+
(b64d[s[i+1]]<<12)+
(b64d[s[i+2]]<<6)+
b64d[s[i+3]]
a[j++]=(t>>16)&0xff
a[j++]=(t>>8)&0xff
a[j++]=t&0xff}
if(l!=s.length){t=(b64d[s[i]]<<18)+
(b64d[s[i+1]]<<12)+
(b64d[s[i+2]]<<6)+
b64d[s[i+3]]
a[j++]=(t>>16)&0xff
if(j<dl)
a[j++]=(t>>8)&0xff}
return a}
function sample_cp(b,s){var i,n,a=b.getChannelData(0)
for(i=0;i<s.length;i++)
a[i]=s[i]/196608}
function sf2_create(instr,sf2par,sf2pre){function get_instr(i){var generator,instrument=sf2par.instrument,zone=sf2par.instrumentZone,j=instrument[i].instrumentBagIndex,jl=instrument[i+1]?instrument[i+1].instrumentBagIndex:zone.length,info=[]
while(j<jl){generator=sf2par.createInstrumentGenerator_(zone,j)
info.push({generator:generator.generator,})
j++}
return{info:info}}
var i,j,k,sid,gen,parm,sample,infos,sample_hdr,scale,tune,gparm={attack:.01,hold:.01,decay:.01,},b=instr>>7,p=instr%128,pr=sf2pre
rates[instr]=[]
for(i=0;i<pr.length;i++){gen=pr[i].header
if(gen.preset==p&&gen.bank==b)
break}
pr=pr[i]
if(!pr){errmsg('unknown instrument '+b+':'+p)
return}
pr=pr.info
for(k=0;k<pr.length;k++){gen=pr[k].generator
if(!gen.instrument)
continue
infos=get_instr(gen.instrument.amount).info
for(i=0;i<infos.length;i++){gen=infos[i].generator
j=gen.keyRange.lo
parm=params[instr][j]
parm=Object.create(parm||gparm)
if(gen.attackVolEnv)
parm.attack=Math.pow(2,gen.attackVolEnv.amount/1200)
if(gen.holdVolEnv)
parm.hold=Math.pow(2,gen.holdVolEnv.amount/1200)
if(gen.decayVolEnv)
parm.decay=Math.pow(2,gen.decayVolEnv.amount/1200)/4
if(gen.sustainVolEnv)
parm.sustain=gen.sustainVolEnv.amount/10
if(gen.initialAttenuation)
parm.atte=gen.initialAttenuation/10
if(gen.sampleModes&&gen.sampleModes.amount&1)
parm.sm=1
if(gen.sampleID){sid=gen.sampleID.amount
sample_hdr=sf2par.sampleHeader[sid]
sample=sf2par.sample[sid]
parm.buffer=ac.createBuffer(1,sample.length,sample_hdr.sampleRate)
sample_cp(parm.buffer,sample)
if(parm.sm){parm.loopStart=sample_hdr.startLoop/sample_hdr.sampleRate
parm.loopEnd=sample_hdr.endLoop/sample_hdr.sampleRate}
scale=(gen.scaleTuning?gen.scaleTuning.amount:100)/100,tune=(gen.coarseTune?gen.coarseTune.amount:0)+
(gen.fineTune?gen.fineTune.amount:0)/100+
sample_hdr.pitchCorrection/100-
(gen.overridingRootKey?gen.overridingRootKey.amount:sample_hdr.originalPitch)}
for(j=gen.keyRange.lo;j<=gen.keyRange.hi;j++){rates[instr][j]=Math.pow(Math.pow(2,1/12),(j+tune)*scale)
params[instr][j]=parm}}}}
function load_instr(instr){w_instr++
abc2svg.loadjs(conf.sfu+'/'+instr+'.js',function(){var sf2par=new sf2.Parser(b64dcod(abcsf2[instr]))
sf2par.parse()
var sf2pre=sf2par.getPresets()
sf2_create(instr,sf2par,sf2pre)
if(--w_instr==0)
play_start()},function(){errmsg('could not find the instrument '+
((instr/128)|0).toString()+'-'+
(instr%128).toString())
if(--w_instr==0)
play_start()})}
function def_instr(s,f,sf2par,sf2pre){var i,bk=[],nv=-1,vb=0
s=s.p_v.sym
while(s.ts_prev)
s=s.ts_prev
for(;s;s=s.ts_next){if(s.v>nv){nv=s.v
bk[nv]=0
if(s.p_v.midictl){if(s.p_v.midictl[0])
bk[s.v]=(bk[s.v]&~0x1fc000)
+(s.p_v.midictl[0]<<14)
if(s.p_v.midictl[32])
bk[s.v]=(bk[s.v]&~0x3f80)
+(s.p_v.midictl[32]<<7)}}
switch(s.subtype){case"midiprog":break
case"midictl":if(s.ctrl!=0&&s.ctrl!=32)
continue
if(bk[s.v]==undefined)
bk[s.v]=0
if(s.ctrl==0)
bk[s.v]=(bk[s.v]&~0x1fc000)
+(s.val<<14)
else
bk[s.v]=(bk[s.v]&~0x3f80)
+(s.val<<7)
default:continue}
vb|=1<<s.v
i=s.instr
if(i==undefined){if(s.chn!=9)
continue
i=bk[s.v]?0:128*128}
if(bk[s.v])
i+=bk[s.v]
if(!params[i]){params[i]=[]
f(i,sf2par,sf2pre)}}
nv=(2<<nv)-1
if(nv!=vb&&!params[0]){params[0]=[]
f(0,sf2par,sf2pre)}}
function load_res(s){if(abc2svg.sf2||conf.sfu.slice(-4)==".sf2"||conf.sfu.slice(-3)==".js"){if(abc2svg.sf2){if(!parser){parser=new sf2.Parser(b64dcod(abc2svg.sf2))
parser.parse()
presets=parser.getPresets()}}else if(!parser){w_instr++
if(conf.sfu.slice(-3)==".js"){abc2svg.loadjs(conf.sfu,function(){load_res(s)
if(--w_instr==0)
play_start()},function(){errmsg('could not load the sound file '
+conf.sfu)
if(--w_instr==0)
play_start()})
return}
var r=new XMLHttpRequest()
r.open('GET',conf.sfu,true)
r.responseType="arraybuffer"
r.onload=function(){if(r.status===200){parser=new sf2.Parser(new Uint8Array(r.response))
parser.parse()
presets=parser.getPresets()
load_res(s)
if(--w_instr==0)
play_start()}else{errmsg('could not load the sound file '
+conf.sfu)
if(--w_instr==0)
play_start()}}
r.onerror=function(){errmsg('could not load the sound file '
+conf.sfu)
if(--w_instr==0)
play_start()}
r.send()
return}
def_instr(s,sf2_create,parser,presets)}else{def_instr(s,load_instr)}}
function get_time(po){return po.ac.currentTime}
function midi_ctrl(po,s,t){switch(s.ctrl){case 0:if(po.v_b[s.v]==undefined)
po.v_b[s.v]=0
po.v_b[s.v]=(po.v_b[s.v]&~0x1fc000)
+(s.val<<14)
break
case 7:s.p_v.vol=s.val/127
break
case 10:s.p_v.pan=s.val/63.5-1
break
case 32:if(po.v_b[s.v]==undefined)
po.v_b[s.v]=0
po.v_b[s.v]=(po.v_b[s.v]&~0x3f80)
+(s.val<<7)
break}}
function midi_prog(po,s){var i=s.instr
po.v_c[s.v]=s.chn
if(i==undefined){if(s.chn!=9)
return
i=po.v_b[s.v]?0:128*128}
if(po.v_b[s.v])
i+=po.v_b[s.v]
po.c_i[s.chn]=i}
function note_run(po,s,key,t,d){var g,st,t2=t,c=po.v_c[s.v],instr=po.c_i[c],k=key|0,parm=params[instr][k],o=po.ac.createBufferSource(),v=s.p_v.vol==undefined?1:s.p_v.vol
if(!v||!parm)
return
o.buffer=parm.buffer
if(parm.sm){o.loop=true
o.loopStart=parm.loopStart
o.loopEnd=parm.loopEnd}
if(o.detune){var dt=(key*100)%100
if(dt)
o.detune.value=dt}
o.playbackRate.value=po.rates[instr][k]
g=po.ac.createGain()
if(parm.atte)
v/=Math.pow(10,parm.atte/20)
if(parm.hold<=.01){g.gain.setValueAtTime(v,t)}else{if(parm.attack<=.01){g.gain.setValueAtTime(v,t)}else{g.gain.setValueAtTime(.01,t)
t2+=parm.attack
g.gain.linearRampToValueAtTime(v,t2)}
t2+=parm.hold
g.gain.setValueAtTime(v,t2)}
if(parm.sustain&&parm.decay>.01){v=parm.sustain==100?.01:v/Math.pow(10,parm.sustain/20)
g.gain.exponentialRampToValueAtTime(v,t2+parm.decay)}
if(s.p_v.pan!=undefined){var p=po.ac.createStereoPanner()
p.pan.value=s.p_v.pan
o.connect(p)
p.connect(g)}else{o.connect(g)}
g.connect(po.gain)
o.start(t)
o.stop(t+d)}
function play_start(){if(po.stop){po.onend(repv)
return}
gain.connect(ac.destination)
abc2svg.play_next(po)}
init_b64d()
if(!conf.sfu)
conf.sfu="Scc1t2"
if(navigator.userAgentData&&navigator.userAgentData.getHighEntropyValues)
navigator.userAgentData.getHighEntropyValues(['model']).then(function(ua){model=ua.model})
else
model=navigator.userAgent
return{get_outputs:function(){return(window.AudioContext||window.webkitAudioContext)?['sf2']:null},play:function(i_start,i_end,i_lvl){errmsg=conf.errmsg||alert
function play_unlock(){var buf=ac.createBuffer(1,1,22050),src=ac.createBufferSource()
src.buffer=buf
src.connect(ac.destination)
src.start(0)}
if(!gain){ac=conf.ac
if(!ac){conf.ac=ac=new(window.AudioContext||window.webkitAudioContext)
if(/iPad|iPhone|iPod/.test(model))
play_unlock()}
gain=ac.createGain()
gain.gain.value=conf.gain}
while(i_start.noplay)
i_start=i_start.ts_next
po={conf:conf,onend:conf.onend||empty,onnote:conf.onnote||empty,s_end:i_end,s_cur:i_start,repv:i_lvl||0,tgen:2,get_time:get_time,midi_ctrl:midi_ctrl,midi_prog:midi_prog,note_run:note_run,timouts:[],v_c:[],c_i:[],v_b:[],ac:ac,gain:gain,rates:rates}
w_instr++
load_res(i_start)
if(--w_instr==0)
play_start()},stop:function(){po.stop=true
po.timouts.forEach(function(id){clearTimeout(id)})
abc2svg.play_next(po)
if(gain){gain.disconnect()
gain=null}},set_vol:function(v){if(gain)
gain.gain.value=v}}}
(function(root,factory){if(typeof exports==="object"){root.sf2=exports;factory(exports)}else if(typeof define==="function"&&define.amd){define(["exports"],function(exports){root.sf2=exports;return(root.sf2,factory(exports))})}else{root.sf2={};factory(root.sf2)}}(this,function(sf2){"use strict";sf2.Parser=function(input,options){options=options||{};this.input=input;this.parserOptions=options.parserOptions};sf2.Parser.prototype.parse=function(){var parser=new sf2.Riff.Parser(this.input,this.parserOptions),chunk;parser.parse();if(parser.chunkList.length!==1)
throw new Error('wrong chunk length');chunk=parser.getChunk(0);if(chunk===null)
throw new Error('chunk not found');this.parseRiffChunk(chunk);this.input=null};sf2.Parser.prototype.parseRiffChunk=function(chunk){var parser,data=this.input,ip=chunk.offset,signature;if(chunk.type!=='RIFF')
throw new Error('invalid chunk type:'+chunk.type);signature=String.fromCharCode(data[ip++],data[ip++],data[ip++],data[ip++]);if(signature!=='sfbk')
throw new Error('invalid signature:'+signature);parser=new sf2.Riff.Parser(data,{'index':ip,'length':chunk.size-4});parser.parse();if(parser.getNumberOfChunks()!==3)
throw new Error('invalid sfbk structure');this.parseInfoList(parser.getChunk(0));this.parseSdtaList(parser.getChunk(1));this.parsePdtaList(parser.getChunk(2))};sf2.Parser.prototype.parseInfoList=function(chunk){var parser,data=this.input,ip=chunk.offset,signature;if(chunk.type!=='LIST')
throw new Error('invalid chunk type:'+chunk.type);signature=String.fromCharCode(data[ip++],data[ip++],data[ip++],data[ip++]);if(signature!=='INFO')
throw new Error('invalid signature:'+signature);parser=new sf2.Riff.Parser(data,{'index':ip,'length':chunk.size-4});parser.parse()};sf2.Parser.prototype.parseSdtaList=function(chunk){var parser,data=this.input,ip=chunk.offset,signature;if(chunk.type!=='LIST')
throw new Error('invalid chunk type:'+chunk.type);signature=String.fromCharCode(data[ip++],data[ip++],data[ip++],data[ip++]);if(signature!=='sdta')
throw new Error('invalid signature:'+signature);parser=new sf2.Riff.Parser(data,{'index':ip,'length':chunk.size-4});parser.parse();if(parser.chunkList.length!==1)
throw new Error('TODO');this.samplingData=parser.getChunk(0)};sf2.Parser.prototype.parsePdtaList=function(chunk){var parser,data=this.input,ip=chunk.offset,signature;if(chunk.type!=='LIST')
throw new Error('invalid chunk type:'+chunk.type);signature=String.fromCharCode(data[ip++],data[ip++],data[ip++],data[ip++]);if(signature!=='pdta')
throw new Error('invalid signature:'+signature);parser=new sf2.Riff.Parser(data,{'index':ip,'length':chunk.size-4});parser.parse();if(parser.getNumberOfChunks()!==9)
throw new Error('invalid pdta chunk');this.parsePhdr((parser.getChunk(0)));this.parsePbag((parser.getChunk(1)));this.parsePmod((parser.getChunk(2)));this.parsePgen((parser.getChunk(3)));this.parseInst((parser.getChunk(4)));this.parseIbag((parser.getChunk(5)));this.parseImod((parser.getChunk(6)));this.parseIgen((parser.getChunk(7)));this.parseShdr((parser.getChunk(8)))};sf2.Parser.prototype.parsePhdr=function(chunk){var data=this.input,ip=chunk.offset,presetHeader=this.presetHeader=[],size=chunk.offset+chunk.size;if(chunk.type!=='phdr')
throw new Error('invalid chunk type:'+chunk.type);while(ip<size){presetHeader.push({presetName:String.fromCharCode.apply(null,data.subarray(ip,ip+=20)),preset:data[ip++]|(data[ip++]<<8),bank:data[ip++]|(data[ip++]<<8),presetBagIndex:data[ip++]|(data[ip++]<<8),library:(data[ip++]|(data[ip++]<<8)|(data[ip++]<<16)|(data[ip++]<<24))>>>0,genre:(data[ip++]|(data[ip++]<<8)|(data[ip++]<<16)|(data[ip++]<<24))>>>0,morphology:(data[ip++]|(data[ip++]<<8)|(data[ip++]<<16)|(data[ip++]<<24))>>>0})}};sf2.Parser.prototype.parsePbag=function(chunk){var data=this.input,ip=chunk.offset,presetZone=this.presetZone=[],size=chunk.offset+chunk.size;if(chunk.type!=='pbag')
throw new Error('invalid chunk type:'+chunk.type);while(ip<size){presetZone.push({presetGeneratorIndex:data[ip++]|(data[ip++]<<8),presetModulatorIndex:data[ip++]|(data[ip++]<<8)})}};sf2.Parser.prototype.parsePmod=function(chunk){if(chunk.type!=='pmod')
throw new Error('invalid chunk type:'+chunk.type);this.presetZoneModulator=this.parseModulator(chunk)};sf2.Parser.prototype.parsePgen=function(chunk){if(chunk.type!=='pgen')
throw new Error('invalid chunk type:'+chunk.type);this.presetZoneGenerator=this.parseGenerator(chunk)};sf2.Parser.prototype.parseInst=function(chunk){var data=this.input,ip=chunk.offset,instrument=this.instrument=[],size=chunk.offset+chunk.size;if(chunk.type!=='inst')
throw new Error('invalid chunk type:'+chunk.type);while(ip<size){instrument.push({instrumentName:String.fromCharCode.apply(null,data.subarray(ip,ip+=20)),instrumentBagIndex:data[ip++]|(data[ip++]<<8)})}};sf2.Parser.prototype.parseIbag=function(chunk){var data=this.input,ip=chunk.offset,instrumentZone=this.instrumentZone=[],size=chunk.offset+chunk.size;if(chunk.type!=='ibag')
throw new Error('invalid chunk type:'+chunk.type);while(ip<size){instrumentZone.push({instrumentGeneratorIndex:data[ip++]|(data[ip++]<<8),instrumentModulatorIndex:data[ip++]|(data[ip++]<<8)})}};sf2.Parser.prototype.parseImod=function(chunk){if(chunk.type!=='imod')
throw new Error('invalid chunk type:'+chunk.type);this.instrumentZoneModulator=this.parseModulator(chunk)};sf2.Parser.prototype.parseIgen=function(chunk){if(chunk.type!=='igen')
throw new Error('invalid chunk type:'+chunk.type);this.instrumentZoneGenerator=this.parseGenerator(chunk)};sf2.Parser.prototype.parseShdr=function(chunk){var data=this.input,ip=chunk.offset,samples=this.sample=[],sampleHeader=this.sampleHeader=[],size=chunk.offset+chunk.size,sampleName,start,end,startLoop,endLoop,sampleRate,originalPitch,pitchCorrection,sampleLink,sampleType;if(chunk.type!=='shdr')
throw new Error('invalid chunk type:'+chunk.type);while(ip<size){sampleName=String.fromCharCode.apply(null,data.subarray(ip,ip+=20));start=(data[ip++]<<0)|(data[ip++]<<8)|(data[ip++]<<16)|(data[ip++]<<24);end=(data[ip++]<<0)|(data[ip++]<<8)|(data[ip++]<<16)|(data[ip++]<<24);startLoop=(data[ip++]<<0)|(data[ip++]<<8)|(data[ip++]<<16)|(data[ip++]<<24);endLoop=(data[ip++]<<0)|(data[ip++]<<8)|(data[ip++]<<16)|(data[ip++]<<24);sampleRate=(data[ip++]<<0)|(data[ip++]<<8)|(data[ip++]<<16)|(data[ip++]<<24);originalPitch=data[ip++];pitchCorrection=(data[ip++]<<24)>>24;sampleLink=data[ip++]|(data[ip++]<<8);sampleType=data[ip++]|(data[ip++]<<8);var sample=new Int16Array(new Uint8Array(data.subarray(this.samplingData.offset+start*2,this.samplingData.offset+end*2)).buffer);startLoop-=start;endLoop-=start;if(sampleRate>0){var adjust=this.adjustSampleData(sample,sampleRate);sample=adjust.sample;sampleRate*=adjust.multiply;startLoop*=adjust.multiply;endLoop*=adjust.multiply}
samples.push(sample);sampleHeader.push({sampleName:sampleName,startLoop:startLoop,endLoop:endLoop,sampleRate:sampleRate,originalPitch:originalPitch,pitchCorrection:pitchCorrection,sampleLink:sampleLink,sampleType:sampleType})}};sf2.Parser.prototype.adjustSampleData=function(sample,sampleRate){var newSample,i,il,j,multiply=1;while(sampleRate<22050){newSample=new Int16Array(sample.length*2);for(i=j=0,il=sample.length;i<il;++i){newSample[j++]=sample[i];newSample[j++]=sample[i]}
sample=newSample;multiply*=2;sampleRate*=2}
return{sample:sample,multiply:multiply}};sf2.Parser.prototype.parseModulator=function(chunk){var data=this.input,ip=chunk.offset,size=chunk.offset+chunk.size,code,key,output=[];while(ip<size){ip+=2;code=data[ip++]|(data[ip++]<<8);key=sf2.Parser.GeneratorEnumeratorTable[code];if(key===undefined){output.push({type:key,value:{code:code,amount:data[ip]|(data[ip+1]<<8)<<16>>16,lo:data[ip++],hi:data[ip++]}})}else{switch(key){case'keyRange':case'velRange':case'keynum':case'velocity':output.push({type:key,value:{lo:data[ip++],hi:data[ip++]}});break;default:output.push({type:key,value:{amount:data[ip++]|(data[ip++]<<8)<<16>>16}});break}}
ip+=2;ip+=2}
return output};sf2.Parser.prototype.parseGenerator=function(chunk){var data=this.input,ip=chunk.offset,size=chunk.offset+chunk.size,code,key,output=[];while(ip<size){code=data[ip++]|(data[ip++]<<8);key=sf2.Parser.GeneratorEnumeratorTable[code];if(key===undefined){output.push({type:key,value:{code:code,amount:data[ip]|(data[ip+1]<<8)<<16>>16,lo:data[ip++],hi:data[ip++]}});continue}
switch(key){case'keynum':case'keyRange':case'velRange':case'velocity':output.push({type:key,value:{lo:data[ip++],hi:data[ip++]}});break;default:output.push({type:key,value:{amount:data[ip++]|(data[ip++]<<8)<<16>>16}});break}}
return output};sf2.Parser.prototype.getPresets=function(){var preset=this.presetHeader,zone=this.presetZone,output=[],bagIndex,bagIndexEnd,zoneInfo,presetGenerator,presetModulator,i,il,j,jl
for(i=0,il=preset.length;i<il;++i){j=preset[i].presetBagIndex
jl=preset[i+1]?preset[i+1].presetBagIndex:zone.length
zoneInfo=[];for(;j<jl;++j){presetGenerator=this.createPresetGenerator_(zone,j);presetModulator=this.createPresetModulator_(zone,j);zoneInfo.push({generator:presetGenerator.generator,modulator:presetModulator.modulator,})}
output.push({info:zoneInfo,header:preset[i],})}
return output};sf2.Parser.prototype.createInstrumentGenerator_=function(zone,index){var modgen=this.createBagModGen_(zone,zone[index].instrumentGeneratorIndex,zone[index+1]?zone[index+1].instrumentGeneratorIndex:this.instrumentZoneGenerator.length,this.instrumentZoneGenerator);return{generator:modgen.modgen,}};sf2.Parser.prototype.createInstrumentModulator_=function(zone,index){var modgen=this.createBagModGen_(zone,zone[index].presetModulatorIndex,zone[index+1]?zone[index+1].instrumentModulatorIndex:this.instrumentZoneModulator.length,this.instrumentZoneModulator);return{modulator:modgen.modgen}};sf2.Parser.prototype.createPresetGenerator_=function(zone,index){var modgen=this.createBagModGen_(zone,zone[index].presetGeneratorIndex,zone[index+1]?zone[index+1].presetGeneratorIndex:this.presetZoneGenerator.length,this.presetZoneGenerator);return{generator:modgen.modgen,}};sf2.Parser.prototype.createPresetModulator_=function(zone,index){var modgen=this.createBagModGen_(zone,zone[index].presetModulatorIndex,zone[index+1]?zone[index+1].presetModulatorIndex:this.presetZoneModulator.length,this.presetZoneModulator);return{modulator:modgen.modgen,}};sf2.Parser.prototype.createBagModGen_=function(zone,indexStart,indexEnd,zoneModGen){var modgen={unknown:[],'keyRange':{hi:127,lo:0}};var info,i,il;for(i=indexStart,il=indexEnd;i<il;++i){info=zoneModGen[i];if(info.type==='unknown')
modgen.unknown.push(info.value);else
modgen[info.type]=info.value}
return{modgen:modgen}};sf2.Parser.GeneratorEnumeratorTable=['startAddrsOffset','endAddrsOffset','startloopAddrsOffset','endloopAddrsOffset','startAddrsCoarseOffset','modLfoToPitch','vibLfoToPitch','modEnvToPitch','initialFilterFc','initialFilterQ','modLfoToFilterFc','modEnvToFilterFc','endAddrsCoarseOffset','modLfoToVolume',undefined,'chorusEffectsSend','reverbEffectsSend','pan',undefined,undefined,undefined,'delayModLFO','freqModLFO','delayVibLFO','freqVibLFO','delayModEnv','attackModEnv','holdModEnv','decayModEnv','sustainModEnv','releaseModEnv','keynumToModEnvHold','keynumToModEnvDecay','delayVolEnv','attackVolEnv','holdVolEnv','decayVolEnv','sustainVolEnv','releaseVolEnv','keynumToVolEnvHold','keynumToVolEnvDecay','instrument',undefined,'keyRange','velRange','startloopAddrsCoarseOffset','keynum','velocity','initialAttenuation',undefined,'endloopAddrsCoarseOffset','coarseTune','fineTune','sampleID','sampleModes',undefined,'scaleTuning','exclusiveClass','overridingRootKey'];sf2.Riff={};sf2.Riff.Parser=function(input,options){options=options||{};this.input=input;this.ip=options.index||0;this.length=options.length||input.length-this.ip;this.offset=this.ip;this.padding=options.padding!==undefined?options.padding:true;this.bigEndian=options.bigEndian!==undefined?options.bigEndian:false};sf2.Riff.Chunk=function(type,size,offset){this.type=type;this.size=size;this.offset=offset};sf2.Riff.Parser.prototype.parse=function(){var length=this.length+this.offset;this.chunkList=[];while(this.ip<length)
this.parseChunk()};sf2.Riff.Parser.prototype.parseChunk=function(){var input=this.input,ip=this.ip,size;this.chunkList.push(new sf2.Riff.Chunk(String.fromCharCode(input[ip++],input[ip++],input[ip++],input[ip++]),(size=this.bigEndian?((input[ip++]<<24)|(input[ip++]<<16)|(input[ip++]<<8)|(input[ip++])):((input[ip++])|(input[ip++]<<8)|(input[ip++]<<16)|(input[ip++]<<24))),ip));ip+=size;if(this.padding&&((ip-this.offset)&1)===1)
ip++;this.ip=ip};sf2.Riff.Parser.prototype.getChunk=function(index){var chunk=this.chunkList[index];if(chunk===undefined)
return null;return chunk};sf2.Riff.Parser.prototype.getNumberOfChunks=function(){return this.chunkList.length};return sf2}));function Midi5(i_conf){var po,conf=i_conf,empty=function(){},det_tb,rf,op
function get_time(po){return window.performance.now()/1000}
var mutone=function(k,a,t){if(!det_tb){if(!a)
return
det_tb={}}
if(!Midi5.ma.sysexEnabled){mutone=empty
return}
var old_a=det_tb[k]
if((!old_a&&!a)||old_a==a)
return
det_tb[k]=a
a*=163.84
po.op.send(new Uint8Array([0xf0,0x7f,0x7f,0x08,0x02,0,0x01,k,k,(a>>7)&0x7f,a&0x7f,0xf7]),t)}
function note_run(po,s,k,t,d){var j,a=(k*100)%100,c=po.v_c[s.v],i=po.c_i[c]
k|=0
t*=1000
d*=1000
mutone(k,a,t)
po.op.send(new Uint8Array([0x90+c,k,80]),t)
po.op.send(new Uint8Array([0x80+c,k,0]),t+d-20)}
function midi_ctrl(po,s,t){po.op.send(new Uint8Array([0xb0+po.v_c[s.v],s.ctrl,s.val]),t*1000)}
function midi_prog(po,s){var i,c=s.chn
po.v_c[s.v]=c
if(po.c_i[c]==undefined){po.op.send(new Uint8Array([0xb0+c,121,0]))
if(0){if(s.p_v.midictl){for(i in s.p_v.midictl)
po.op.send(new Uint8Array([0xb0+c,i,s.p_v.midictl[i]]))}}}
i=s.instr
if(i!=undefined){po.c_i[c]=i
po.op.send(new Uint8Array([0xc0+c,i&0x7f]))}}
function send_outputs(access){var o,os,out=[]
Midi5.ma=access
if(access&&access.outputs.size>0){os=access.outputs.values()
while(1){o=os.next()
if(!o||o.done)
break
out.push(o.value.name)}}
rf(out)}
return{get_outputs:function(f){if(!navigator.requestMIDIAccess){f()
return}
rf=f
navigator.requestMIDIAccess({sysex:true}).then(send_outputs,function(msg){rf()})},set_output:function(name){if(!Midi5.ma)
return
var o,os=Midi5.ma.outputs.values()
while(1){o=os.next()
if(!o||o.done)
break
if(o.value.name==name){op=o.value
break}}},play:function(i_start,i_end,i_lvl){po={conf:conf,onend:conf.onend||empty,onnote:conf.onnote||empty,s_end:i_end,s_cur:i_start,repv:i_lvl||0,tgen:2,get_time:get_time,midi_ctrl:midi_ctrl,midi_prog:midi_prog,note_run:note_run,timouts:[],op:op,v_c:[],c_i:[]}
abc2svg.play_next(po)},stop:function(){po.stop=true
po.timouts.forEach(function(id){clearTimeout(id)})
abc2svg.play_next(po)
if(op&&op.clear)
op.clear()}}}
function follow(abc,user,playconf){var keep_types={note:true,rest:true}
user.anno_stop=function(type,start,stop,x,y,w,h){if(!keep_types[type])
return
abc.out_svg('<rect class="abcr _'+start+'_" x="');abc.out_sxsy(x,'" y="',y);abc.out_svg('" width="'+w.toFixed(2)+'" height="'+abc.sh(h).toFixed(2)+'"/>\n')}
playconf.onnote=function(i,on){var b,e,elts,x=0,y=0
if(abc2svg.mu)
elts=abc2svg.mu.d.getElementsByClassName('_'+i+'_')
else
elts=document.getElementsByClassName('_'+i+'_')
if(!elts||!elts.length)
return
e=elts[0]
e.style.fillOpacity=on?0.4:0
if(on&&!window.no_scroll){b=e.getBoundingClientRect()
if(b.top<0||b.bottom>window.innerHeight*.8)
y=b.top-window.innerHeight*.3
if(b.left<0||b.right>window.innerWidth*.8)
x=b.left-window.innerWidth*.3
if(x||y)
window.scrollBy({top:y,left:x,behavior:(x<0||y)?'instant':'smooth'})}}}
(function(){var sty=document.createElement("style")
sty.innerHTML=".abcr {fill: #d00000; fill-opacity: 0; z-index: 15}"
document.head.appendChild(sty)})()
abc2svg.chnm={'':[0,4,7],'6':[0,4,7,9],'7':[0,4,7,10],M7:[0,4,7,11],aug:[0,4,8],aug7:[0,4,8,10],m:[0,3,7],m6:[0,3,7,9],m7:[0,3,7,10],mM7:[0,3,7,11],dim:[0,3,6],dim7:[0,3,6,9],m7b5:[0,3,6,10],'9':[0,4,7,10,14],'11':[0,4,7,10,14,17],sus4:[0,5,7]}
abc2svg.letmid={C:0,D:2,E:4,F:5,G:7,A:9,B:11}
abc2svg.chord=function(first,voice_tb,cfmt){var chnm,i,k,vch,s,gchon,s_ch,rhy,ti,dt,gchnb,md=first.p_v.meter.wmeasure,nextim=0,C=abc2svg.C,trans=48+(cfmt.chord.trans?cfmt.chord.trans*12:0)
function chcr(b,ch){var j,r=ch.slice(),i=r.length
if(b){while(--i>0){if(r[i]==b)
break}
if(i>0)
for(j=0;j<r.length;j++)
r[j]=ch[(j+i)%r.length]
else
r.unshift(b)}
r[0]-=12
return r}
function meterhy(s){if(!s.a_meter[0])
return'+'
var r,t=s.a_meter[0].top,b=s.a_meter[0].bot
switch(b){case'2':b=4
t*=2
case undefined:if(t[0]=='C')
t=4,b=4
case'4':if(t=='3')
return"fzczcz"
return"fzczfzczfzcz".slice(0,t*2)
case'8':return"fzcfzcfzcfzc".slice(0,t)}
return'z'}
function bld_rhy(p){var i,c,j=0
rhy=p[0]
for(i=1;i<p.length;i++){c=p[i]
if(c>='1'&&c<='9'){while(--c>0)
rhy+='+'
continue}
rhy+=c}
dt=md/rhy.length*gchnb}
function gench(sb,i){var r,ch,b,m,n,nt,a=sb.a_gch[i].otext
if(a.slice(-1)==')')
a=a.replace(/\(.*/,'')
a=a.replace(/\(|\)|\[|\]/g,'').replace(/♯/g,'#').replace(/♭/g,'b').match(/([A-G])([#b]?)([^/]*)\/?(.*)/)
if(!a)
return
r=abc2svg.letmid[a[1]]
if(r==undefined)
return
switch(a[2]){case"#":r++;break
case"b":r--;break}
if(!a[3]){ch=chnm[""]}else{ch=abc2svg.ch_alias[a[3]]
if(ch==undefined)
ch=a[3]
ch=chnm[ch]
if(!ch)
ch=a[3][0]=='m'?chnm.m:chnm[""]}
if(a[4]){b=a[4][0].toUpperCase()
b=abc2svg.letmid[b]
if(b!=undefined){switch(a[4][1]){case"#":b=(b+1)%12;break
case"b":b=(b+11)%12;break}
b=b-r
if(b<0)
b+=12}}
ch=chcr(b,ch)
n=ch.length
r+=trans
for(m=0;m<n;m++){nt=s_ch.notes[m]
if(!nt)
s_ch.notes[m]=nt=[]
nt.midi=r+ch[m]}
s_ch.nhd=n-1}
function set_dur(s2,tim){if(s2.dur||tim==s2.time||s2.nhd==undefined)
return
s2.dur=tim-s2.time
for(var m=0;m<=s2.nhd;m++)
s2.notes[m].dur=s2.dur}
function insch(s_next,tim){if(s_ch.nhd==undefined)
return
var s,m,s2=vch.last_sym,i=rhy[ti++]
switch(i){case'+':if(rhy!='+')
return
i='b'
ti=0
break
case undefined:case'z':set_dur(s2,tim)
return}
s={v:vch.v,p_v:vch,type:C.NOTE,notes:[]}
s.time=tim
switch(i){case'c':s.nhd=s_ch.nhd-1
for(m=0;m<=s.nhd;m++)
s.notes[m]={midi:s_ch.notes[m+1].midi}
break
default:i="GHIJKghijk".indexOf(i)
if(i<0||(i%5)>s_ch.nhd)
return
s.notes[0]={midi:s_ch.notes[i%5].midi}
if(i>=5)
s.notes[0].midi+=12
s.nhd=0
break
case'f':s.notes[0]={midi:s_ch.notes[0].midi}
s.nhd=0
break
case'b':s.nhd=s_ch.nhd
for(m=0;m<=s.nhd;m++)
s.notes[m]={midi:s_ch.notes[m].midi}
break}
s.prev=s2
s2.next=s
set_dur(s2,tim)
vch.last_sym=s
if(s_next){s.ts_next=s_next
s.ts_prev=s_next.ts_prev
s_next.ts_prev=s
s.ts_prev.ts_next=s}else{while(s2.ts_next)
s2=s2.ts_next
s2.ts_next=s
s.ts_prev=s2}}
chnm=abc2svg.chnm
if(cfmt.chord.names){for(k in cfmt.chord.names){chnm[k]=[]
for(i=0;i<cfmt.chord.names[k].length;i++)
chnm[k].push(+cfmt.chord.names[k][i])}}
k=0
for(i=0;i<voice_tb.length;i++){if(k<voice_tb[i].chn)
k=voice_tb[i].chn}
if(k==9)
k++
vch={v:voice_tb.length,id:"_chord",time:0,sym:{type:C.BLOCK,subtype:"midiprog",chn:k+1,instr:cfmt.chord.prog||0,time:0,dur:0,next:{type:C.BLOCK,subtype:"midictl",time:0,dur:0,ctrl:7,val:cfmt.chord.vol||75}}}
vch.sym.p_v=vch
vch.sym.v=vch.v
vch.sym.next.p_v=vch
vch.sym.next.v=vch.v
vch.sym.next.prev=vch.sym
vch.last_sym=vch.sym.next
voice_tb.push(vch)
s=first
while(s.type!=C.TEMPO&&s.ts_next&&!s.ts_next.dur)
s=s.ts_next
vch.sym.ts_prev=s
vch.sym.ts_next=vch.sym.next
vch.sym.next.ts_prev=vch.sym
vch.sym.next.ts_next=s.ts_next
if(s.ts_next)
s.ts_next.ts_prev=vch.sym.next
s.ts_next=vch.sym
s_ch={notes:[]}
gchon=cfmt.chord.gchon
gchnb=cfmt.chord.gchnb||1
s=first
bld_rhy(cfmt.chord.rhy||meterhy(s.p_v.meter))
ti=0
while(1){if(gchon){while(s.time>nextim){insch(s,nextim)
nextim+=rhy=='+'?100000:dt}
if(s.bar_type=="|"&&rhy!='+'&&nextim!=s.time){nextim=s.time
ti=0}}
if(gchon&&s.a_gch){for(i=0;i<s.a_gch.length;i++){if(s.a_gch[i].type!='g')
continue
gench(s,i)
if(rhy=='+')
nextim=s.time
break}}
if(!s.dur){if(s.bar_num){if(gchnb==1||!((s.bar_num-1)%gchnb))
ti=0}else if(s.wmeasure){md=s.wmeasure
if(rhy!='+')
bld_rhy(meterhy(s))}else if(s.subtype=="midigch"){if(s.on!=undefined){gchon=s.on
if(!gchon&&rhy=='+')
set_dur(vch.last_sym,s.time)}
if(s.gchnb)
gchnb=s.gchnb
if(gchon&&s.rhy)
bld_rhy(s.rhy)}}
if(!s.ts_next)
break
s=s.ts_next}
if(gchon){while(s.time+(s.dur||0)>nextim){insch(s.dur?null:s,nextim)
if(rhy=='+')
break
nextim+=dt}
set_dur(vch.last_sym,s.time+(s.dur||0))}}

