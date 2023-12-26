//capo.js-module to add a capo chord line
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.capo={icb40:[0,5,6,11,16,17,22,23,28,33,34,39],gch_build:function(of,s){var t,i,gch,gch2,i2,abc=this,p_v=abc.get_curvoice(),a_gch=s.a_gch
if(p_v.capo&&a_gch){t=p_v.capo
i=0
while(1){gch=a_gch[i++]
if(!gch){of(s)
return}
if(gch.type=='g')
break}
gch2=Object.create(gch)
gch2.capo=false
gch2.text=abc.gch_tr1(gch2.text,-abc2svg.capo.icb40[t%12])
if(!p_v.capo_first){p_v.capo_first=true
gch2.text+="  (capo: "+t.toString()+")"}
gch2.font=abc.get_font(abc.cfmt().capofont?"capo":"annotation")
a_gch.splice(i,0,gch2)
gch.capo=true}
of(s)},set_fmt:function(of,cmd,param){if(cmd=="capo"){this.set_v_param("capo_",param)
return}
of(cmd,param)},set_vp:function(of,a){var i,v,p_v=this.get_curvoice()
for(i=0;i<a.length;i++){if(a[i]=="capo_="){v=Number(a[++i])
if(isNaN(v)||v<=0)
this.syntax(1,"Bad fret number in %%capo")
else
p_v.capo=v
break}}
of(a)},set_hooks:function(abc){abc.gch_build=abc2svg.capo.gch_build.bind(abc,abc.gch_build);abc.set_format=abc2svg.capo.set_fmt.bind(abc,abc.set_format)
abc.set_vp=abc2svg.capo.set_vp.bind(abc,abc.set_vp)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.capo=abc2svg.capo.set_hooks
