// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2022 Jean-Francois Moine - LGPL3+
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
function play2(out){var o
if(!out)
out=[]
o=audio5.get_outputs()
if(o)
Array.prototype.push.apply(out,o)
if(out.length==0){if(conf.onend)
conf.onend()
return}
if(out.length==1){o=0}else{o=-1
var pr="Use"
for(var i=0;i<out.length;i++)
pr+="\n "+i+": "+out[i]
var res=window.prompt(pr,'0')
if(res){o=Number(res)
if(isNaN(o)||o<0||o>=out.length)
o=-1}
if(!res||o<0){if(conf.onend)
conf.onend()
return}}
current=out[o]=='sf2'?audio5:midi5;abcplay.play=current.play;abcplay.stop=current.stop
if(current.set_output)
current.set_output(out[o]);if(abc2svg.pwait){if(typeof abc2svg.pwait=="boolean"){abc2svg.pwait=function(){abcplay.play(init.istart,init.i_iend,init.a_e)}}
return}
abcplay.play(init.istart,init.i_iend,init.a_e)}
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
var abcsf2=[]
function Audio5(i_conf){var conf=i_conf,onend=function(){},onnote=function(){},errmsg,ac,gain,params=[],rates=[],w_instr=0,evt_idx,iend,stime,timouts=[]
function js_instr_load(instr,done,fail){abc2svg.loadjs(conf.sfu+'/'+instr+'.js',function(){done(b64dcod(abcsf2[instr]))},fail)}
if(!conf.instr_load)
conf.instr_load=js_instr_load
var b64d=[]
function init_b64d(){var b64l='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/',l=b64l.length
for(var i=0;i<l;i++)
b64d[b64l[i]]=i
b64d['=']=0}
function b64dcod(s){var i,t,dl,a,l=s.length,j=0
dl=l*3/4
if(s[l-1]=='='){if(s[l-2]=='=')
dl--;dl--;l-=4}
a=new Uint8Array(dl)
for(i=0;i<l;i+=4){t=(b64d[s[i]]<<18)+
(b64d[s[i+1]]<<12)+
(b64d[s[i+2]]<<6)+
b64d[s[i+3]];a[j++]=(t>>16)&0xff;a[j++]=(t>>8)&0xff;a[j++]=t&0xff}
if(l!=s.length){t=(b64d[s[i]]<<18)+
(b64d[s[i+1]]<<12)+
(b64d[s[i+2]]<<6)+
b64d[s[i+3]];a[j++]=(t>>16)&0xff
if(j<dl)
a[j++]=(t>>8)&0xff}
return a}
function sample_cp(b,s){var i,n,a=b.getChannelData(0)
for(i=0;i<s.length;i++)
a[i]=s[i]/196608}
function sf2_create(parser,instr){var i,sid,gen,parm,sampleRate,sample,j,infos=[],instrument=parser.instrument,zone=parser.instrumentZone
i=instrument[0].instrumentBagIndex
j=instrument[1]?instrument[1].instrumentBagIndex:zone.length
while(i<j){infos.push({generator:parser.createInstrumentGenerator_(zone,i).generator})
i++}
rates[instr]=[]
for(i=0;i<infos.length;i++){gen=infos[i].generator;if(!gen.sampleID)
continue
sid=gen.sampleID.amount;sampleRate=parser.sampleHeader[sid].sampleRate;sample=parser.sample[sid];parm={attack:Math.pow(2,(gen.attackVolEnv?gen.attackVolEnv.amount:-12000)/1200),hold:Math.pow(2,(gen.holdVolEnv?gen.holdVolEnv.amount:-12000)/1200),decay:Math.pow(2,(gen.decayVolEnv?gen.decayVolEnv.amount:-12000)/1200)/3,sustain:gen.sustainVolEnv?(gen.sustainVolEnv.amount/1000):0,buffer:ac.createBuffer(1,sample.length,sampleRate)}
parm.hold+=parm.attack;parm.decay+=parm.hold;if(parm.sustain>=.4)
parm.sustain=0.01
else
parm.sustain=1-parm.sustain/.4
sample_cp(parm.buffer,sample)
if(gen.sampleModes&&(gen.sampleModes.amount&1)){parm.loopStart=parser.sampleHeader[sid].startLoop/sampleRate;parm.loopEnd=parser.sampleHeader[sid].endLoop/sampleRate}
var scale=(gen.scaleTuning?gen.scaleTuning.amount:100)/100,tune=(gen.coarseTune?gen.coarseTune.amount:0)+
(gen.fineTune?gen.fineTune.amount:0)/100+
parser.sampleHeader[sid].pitchCorrection/100-
(gen.overridingRootKey?gen.overridingRootKey.amount:parser.sampleHeader[sid].originalPitch)
for(j=gen.keyRange.lo;j<=gen.keyRange.hi;j++){rates[instr][j]=Math.pow(Math.pow(2,1/12),(j+tune)*scale);params[instr][j]=parm}}}
function load_instr(instr,a_e){w_instr++;conf.instr_load(instr,function(sf2_bin){var parser=new sf2.Parser(sf2_bin);parser.parse();sf2_create(parser,instr);if(--w_instr==0)
play_start(a_e)},function(){errmsg('could not find the instrument '+
((instr/128)|0).toString()+'-'+
(instr%128).toString());if(--w_instr==0)
play_start(a_e)})}
function load_res(a_e){var i,e,instr,v,bk=[]
for(i=evt_idx;i<iend;i++){e=a_e[i]
if(!e)
break
instr=e[2]
v=e[6]
if(bk[v]==undefined)
bk[v]=0
if(instr<0){switch(e[3]){case 0:bk[v]=(bk[v]&0x3fff)|(e[4]<<14)
break
case 32:bk[v]=(bk[v]&0x1fc07f)|(e[4]<<7)
break
case 121:bk=[]
break}}else{if(bk[v]){instr&=0x7f
instr|=bk[v]
e[2]=instr}
if(!params[instr]){params[instr]=[];load_instr(instr,a_e)}}}}
function note_run(e,t,d){var g,st,instr=e[2],key=e[3]|0,parm=params[instr][key],o=ac.createBufferSource();if(!parm)
return
o.buffer=parm.buffer
if(parm.loopStart){o.loop=true;o.loopStart=parm.loopStart;o.loopEnd=parm.loopEnd}
if(o.detune){var dt=(e[3]*100)%100
if(dt)
o.detune.value=dt}
o.playbackRate.value=rates[instr][key];g=ac.createGain();if(parm.hold<0.002){g.gain.setValueAtTime(1,t)}else{if(parm.attack<0.002){g.gain.setValueAtTime(1,t)}else{g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(1,t+parm.attack)}
g.gain.setValueAtTime(1,t+parm.hold)}
g.gain.exponentialRampToValueAtTime(parm.sustain,t+parm.decay);o.connect(g);g.connect(gain);o.start(t);o.stop(t+d)}
function play_next(a_e){var t,e,e2,maxt,st,d;if(a_e)
e=a_e[evt_idx]
if(!e||evt_idx>=iend){onend()
return}
if(conf.new_speed){stime=ac.currentTime-
(ac.currentTime-stime)*conf.speed/conf.new_speed;conf.speed=conf.new_speed;conf.new_speed=0}
timouts=[];t=e[1]/conf.speed;maxt=t+3
while(1){d=e[4]/conf.speed
if(e[2]>=0){if(e[5]!=0)
note_run(e,t+stime,d)
var i=e[0];st=(t+stime-ac.currentTime)*1000;timouts.push(setTimeout(onnote,st,i,true));setTimeout(onnote,st+d*1000,i,false)}
e=a_e[++evt_idx]
if(!e||evt_idx>=iend){setTimeout(onend,(t+stime-ac.currentTime+d)*1000)
return}
t=e[1]/conf.speed
if(t>maxt)
break}
timouts.push(setTimeout(play_next,(t+stime-ac.currentTime)*1000-300,a_e))}
function play_start(a_e){if(iend==0){onend()
return}
if(w_instr!=0)
return
gain.connect(ac.destination);stime=ac.currentTime+.2
-a_e[evt_idx][1]*conf.speed;play_next(a_e)}
init_b64d();if(!conf.sfu)
conf.sfu="Scc1t2"
return{get_outputs:function(){return(window.AudioContext||window.webkitAudioContext)?['sf2']:null},play:function(istart,i_iend,a_e){if(!a_e||istart>=a_e.length){onend()
return}
if(conf.onend)
onend=conf.onend
if(conf.onnote)
onnote=conf.onnote
errmsg=conf.errmsg||alert
function play_unlock(){var buf=ac.createBuffer(1,1,22050),src=ac.createBufferSource();src.buffer=buf;src.connect(ac.destination);src.noteOn(0)}
if(!gain){ac=conf.ac
if(!ac){conf.ac=ac=new(window.AudioContext||window.webkitAudioContext);if(/iPad|iPhone|iPod/.test(navigator.userAgent))
play_unlock()}
gain=ac.createGain();gain.gain.value=conf.gain}
iend=i_iend;evt_idx=istart;load_res(a_e);play_start(a_e)},stop:function(){iend=0
timouts.forEach(function(id){clearTimeout(id)})
play_next()
if(gain){gain.disconnect();gain=null}},set_vol:function(v){if(gain)
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
return null;return chunk};sf2.Riff.Parser.prototype.getNumberOfChunks=function(){return this.chunkList.length};return sf2}));function Midi5(i_conf){var conf=i_conf,onend=function(){},onnote=function(){},rf,op,v_i=[],bk=[],evt_idx,iend,stime,timouts=[]
function note_run(e,t,d){var k=e[3]|0,i=e[2],c=e[6]&0x0f,a=(e[3]*100)%100
if(bk[c]==128)
c=9
if(i!=v_i[c]){if(v_i[c]==undefined)
op.send(new Uint8Array([0xb0+c,121,0]));v_i[c]=i
op.send(new Uint8Array([0xc0+c,i&0x7f]))}
if(a&&Midi5.ma.sysexEnabled){op.send(new Uint8Array([0xf0,0x7f,0x7f,0x08,0x02,i&0x7f,0x01,k,k,a/.78125,0,0xf7]),t)}
op.send(new Uint8Array([0x90+c,k,127]),t);op.send(new Uint8Array([0x80+c,k,0]),t+d-20)}
function play_next(a_e){var t,e,e2,maxt,st,d,c
if(a_e)
e=a_e[evt_idx]
if(!op||evt_idx>=iend||!e){onend()
return}
if(conf.new_speed){stime=window-performance.now()-
(window.performance.now()-stime)*conf.speed/conf.new_speed;conf.speed=conf.new_speed;conf.new_speed=0}
timouts=[];t=e[1]/conf.speed*1000;maxt=t+3000
while(1){d=e[4]/conf.speed*1000
if(e[2]>=0){if(e[5]!=0)
note_run(e,t+stime,d)
st=t+stime-window.performance.now();timouts.push(setTimeout(onnote,st,e[0],true));setTimeout(onnote,st+d,e[0],false)}else{c=e[6]&0x0f
op.send(new Uint8Array([0xb0+c,e[3],e[4]]),t+stime)
if(bk[c]==undefined)
bk[c]=0
switch(e[3]){case 0:bk[c]=(bk[c]&0x7f)|(e[4]<<7)
break
case 32:bk[c]=(bk[c]&0x3f80)|e[4]
break
case 121:bk=[]
break}}
e=a_e[++evt_idx]
if(!e||evt_idx>=iend){setTimeout(onend,t+stime-window.performance.now()+d)
return}
t=e[1]/conf.speed*1000
if(t>maxt)
break}
timouts.push(setTimeout(play_next,(t+stime-window.performance.now())
-300,a_e))}
function send_outputs(access){var o,os,out=[];Midi5.ma=access;if(access&&access.outputs.size>0){os=access.outputs.values()
while(1){o=os.next()
if(!o||o.done)
break
out.push(o.value.name)}}
rf(out)}
return{get_outputs:function(f){if(!navigator.requestMIDIAccess){f()
return}
rf=f;navigator.requestMIDIAccess({sysex:true}).then(send_outputs,function(msg){navigator.requestMIDIAccess().then(send_outputs,function(msg){rf()})})},set_output:function(name){var o,os
if(!Midi5.ma)
return
os=Midi5.ma.outputs.values()
while(1){o=os.next()
if(!o||o.done)
break
if(o.value.name==name){op=o.value
break}}},play:function(istart,i_iend,a_e){if(!a_e||istart>=a_e.length){onend()
return}
if(conf.onend)
onend=conf.onend
if(conf.onnote)
onnote=conf.onnote;iend=i_iend;evt_idx=istart;if(0){op.send(new Uint8Array([0xf0,0x7f,0x7f,0x08,0x02,0x00,0x01,0x69,0x69,0x00,0,0xf7]),t)}
v_i=[];stime=window.performance.now()+200
-a_e[evt_idx][1]*conf.speed*1000;play_next(a_e)},stop:function(){iend=0
timouts.forEach(function(id){clearTimeout(id)})
play_next()
if(op&&op.clear)
op.clear()}}}
function follow(abc,user,playconf){var keep_types={note:true,rest:true}
user.anno_stop=function(type,start,stop,x,y,w,h){if(!keep_types[type])
return
abc.out_svg('<rect class="abcr _'+start+'_" x="');abc.out_sxsy(x,'" y="',y);abc.out_svg('" width="'+w.toFixed(2)+'" height="'+abc.sh(h).toFixed(2)+'"/>\n')}
playconf.onnote=function(i,on){var b,x,y,i,e,elts
if(abc2svg.mu)
elts=abc2svg.mu.d.getElementsByClassName('_'+i+'_')
else
elts=document.getElementsByClassName('_'+i+'_')
if(!elts||!elts.length)
return
e=elts[0]
e.style.fillOpacity=on?0.4:0
if(on&&!window.no_scroll){b=e.getBoundingClientRect()
if(b.top<0)
y=window.scrollY+b.top-
window.innerHeight/2
else if(b.bottom>window.innerHeight)
y=window.scrollY+b.bottom+
window.innerHeight/2
if(b.left<0)
x=window.scrollX+b.left-
window.innerWidth/2
else if(b.right>window.innerWidth)
x=window.scrollX+b.right+
window.innerWidth/2
if(x!=undefined||y!=undefined)
window.scrollTo(x||0,y||0)}}}
(function(){var sty=document.createElement("style")
sty.innerHTML=".abcr {fill: #d00000; fill-opacity: 0; z-index: 15}"
document.head.appendChild(sty)})()