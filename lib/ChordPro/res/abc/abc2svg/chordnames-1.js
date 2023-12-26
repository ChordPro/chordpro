//abc2svg-chordnames.js-change the names of the chord symbols
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.chordnames={gch_build:function(of,s){var gch,ix,t,cfmt=this.cfmt()
if(s.a_gch&&cfmt.chordnames){for(ix=0;ix<s.a_gch.length;ix++){gch=s.a_gch[ix]
t=gch.text
if(gch.type!='g'||!t)
continue
if(t[0]=='n'||t[0]=='N')
t='N'
gch.text=t.replace(cfmt.chordnames.re,function(c){return cfmt.chordnames.o[c]})}}
of(s)},gimpl:'CDEFGABN',set_fmt:function(of,cmd,parm){var i,v,re=[],o={},cfmt=this.cfmt()
if(cmd=="chordnames"){parm=parm.split(',')
if(parm[0].indexOf(':')>0){for(i=0;i<parm.length;i++){v=parm[i].split(':')
if(!v[1])
continue
o[v[0]]=v[1]
re.push(v[0])}}else{for(i=0;i<parm.length;i++){v=abc2svg.chordnames.gimpl[i]
o[v]=parm[i]
re.push(v)}}
cfmt.chordnames={re:new RegExp(re.join('|'),'g'),o:o}
return}
of(cmd,parm)},set_hooks:function(abc){abc.gch_build=abc2svg.chordnames.gch_build.bind(abc,abc.gch_build)
abc.set_format=abc2svg.chordnames.set_fmt.bind(abc,abc.set_format)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.chordnames=abc2svg.chordnames.set_hooks
