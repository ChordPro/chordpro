//MIDI.js-module to handle the%%MIDI parameters
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.MIDI={do_midi:function(parm){function tb40(qs){var i,n1=[2,25,8,31,14,37,20,3,26,9,32,15,38,21,4,27,10,33,16,39],n2=[0,19,36,13,30,7,24,1,18,35,12,29,6,23,0,17],da=21-3*qs
b=new Float32Array(40)
for(i=0;i<n1.length;i++)
b[n1[i]]=(qs*i+da)%12
for(i=1;i<=n2.length;i++)
b[n2[i]]=12-(qs*i-da)%12
return b}
var n,v,s,maps,o,q,n,qs,a=parm.split(/\s+/),abc=this,cfmt=abc.cfmt(),curvoice=abc.get_curvoice()
if(curvoice){if(curvoice.ignore)
return
if(curvoice.chn==undefined)
curvoice.chn=curvoice.v<9?curvoice.v:curvoice.v+1}
switch(a[1]){case"chordname":if(!cfmt.chord)
cfmt.chord={}
if(!cfmt.chord.names)
cfmt.chord.names={}
cfmt.chord.names[a[2]]=a.slice(3)
break
case"chordprog":if(!cfmt.chord)
cfmt.chord={}
cfmt.chord.prog=a[2]
if(a[3]&&a[3].slice(0,7)=="octave=")
cfmt.chord.trans=Number(a[3].slice(7))
break
case"chordvol":v=Number(a[2])
if(isNaN(v)||v<0||v>127){abc.syntax(1,abc.errs.bad_val,"%%MIDI chordvol")
break}
if(!cfmt.chord)
cfmt.chord={}
cfmt.chord.vol=v/127
break
case"gchordon":case"gchordoff":if(!cfmt.chord)
cfmt.chord={}
if(abc.parse.state>=2&&curvoice){s=abc.new_block("midigch")
s.play=s.invis=1
s.on=a[1][7]=='n'}else{cfmt.chord.gchon=a[1][7]=='n'}
break
case"channel":v=parseInt(a[2])
if(isNaN(v)||v<=0||v>16){abc.syntax(1,abc.errs.bad_val,"%%MIDI channel")
break}
v--
if(abc.parse.state==3){s=abc.new_block("midiprog")
s.play=s.invis=1
curvoice.chn=s.chn=v}else{abc.set_v_param("channel",v)}
break
case"drummap":v=Number(a[3])
if(isNaN(v)){abc.syntax(1,abc.errs.bad_val,"%%MIDI drummap")
break}
n=["C","^C","D","_E","E","F","^F","G","^G","A","_B","B"][v%12]
while(v<60){n+=','
v+=12}
while(v>72){n+="'"
v-=12}
this.do_pscom("map MIDIdrum "+a[2]+" play="+n)
abc.set_v_param("mididrum","MIDIdrum")
break
case"program":if(a[3]!=undefined){abc2svg.MIDI.do_midi.call(abc,"MIDI channel "+a[2])
v=a[3]}else{v=a[2]}
v=parseInt(v)
if(isNaN(v)||v<0||v>127){abc.syntax(1,abc.errs.bad_val,"%%MIDI program")
break}
if(abc.parse.state==3){s=abc.new_block("midiprog");s.play=s.invis=1
s.instr=v
s.chn=curvoice.chn}else{abc.set_v_param("instr",v)}
break
case"control":n=parseInt(a[2])
if(isNaN(n)||n<0||n>127){abc.syntax(1,"Bad controller number in %%MIDI")
break}
v=parseInt(a[3])
if(isNaN(v)||v<0||v>127){abc.syntax(1,"Bad controller value in %%MIDI")
break}
if(abc.parse.state==3){s=abc.new_block("midictl");s.play=s.invis=1
s.ctrl=n;s.val=v}else{abc.set_v_param("midictl",a[2]+' '+a[3])}
break
case"temperamentequal":n=parseInt(a[2])
if(isNaN(n)||n<5||n>255){abc.syntax(1,abc.errs.bad_val,"%%MIDI "+a[1])
return}
if(n==53){s=abc.get_glyphs()
s.acc12_53='<text id="acc12_53" x="-1">&#xe282;</text>'
s.acc24_53='<text id="acc24_53" x="-1">&#xe282;\
 <tspan x="0" y="-10" style="font-size:8px">2</tspan></text>'
s.acc36_53='<text id="acc36_53" x="-1">&#xe262;\
 <tspan x="0" y="-10" style="font-size:8px">3</tspan></text>'
s.acc48_53='<text id="acc48_53" x="-1">&#xe262;</text>'
s.acc60_53='<g id="acc60_53">\n\
 <text style="font-size:1.2em" x="-1">&#xe282;</text>\n\
 <path class="stroke" stroke-width="1.6" d="M-2 1.5l7 -3"/>\n\
</g>'
s["acc-60_53"]='<text id="acc-60_53" x="-1">&#xe260;</text>'
s["acc-48_53"]='<g id="acc-48_53">\n\
 <text x="-1">&#xe260;</text>\n\
 <path class="stroke" stroke-width="1" d="M-3 -5.5l5 -2"/>\n\
</g>'
s["acc-36_53"]='<g id="acc-36_53">\n\
 <text x="-1">&#xe260;\
  <tspan x="0" y="-10" style="font-size:8px">3</tspan></text>\n\
 <path class="stroke" stroke-width="1" d="M-3 -5.5l5 -2"/>\n\
</g>'
s["acc-24_53"]='<text id="acc-24_53" x="-2">&#xe280;\
 <tspan x="0" y="-10" style="font-size:8px">2</tspan></text>'
s["acc-12_53"]='<text id="acc-12_53" x="-2">&#xe280;</text>'}
q=7.019550008653874,o=12
cfmt.nedo=n
qs=((n*q/o+.5)|0)*o/n
if(qs<6.85||qs>7.2)
abc.syntax(0,abc.errs.bad_val,"%%MIDI "+a[1])
cfmt.temper=tb40(qs)
break}},set_vp:function(of,a){var i,item,s,abc=this,curvoice=abc.get_curvoice()
of(a.slice(0))
for(i=0;i<a.length;i++){switch(a[i]){case"channel=":s=abc.new_block("midiprog")
s.play=s.invis=1
s.chn=curvoice.chn=a[++i]
break
case"instr=":s=abc.new_block("midiprog")
s.play=s.invis=1
s.instr=a[++i]
if(curvoice.chn==undefined){curvoice.chn=curvoice.v<9?curvoice.v:curvoice.v+1}
s.chn=curvoice.chn
break
case"midictl=":if(!curvoice.midictl)
curvoice.midictl=[]
item=a[++i].split(' ');curvoice.midictl[item[0]]=Number(item[1])
break
case"mididrum=":if(!curvoice.map)
curvoice.map={}
curvoice.map=a[++i]
break}}},do_pscom:function(of,text){if(text.slice(0,5)=="MIDI ")
abc2svg.MIDI.do_midi.call(this,text)
else
of(text)},set_hooks:function(abc){abc.do_pscom=abc2svg.MIDI.do_pscom.bind(abc,abc.do_pscom);abc.set_vp=abc2svg.MIDI.set_vp.bind(abc,abc.set_vp)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.MIDI=abc2svg.MIDI.set_hooks
