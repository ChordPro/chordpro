//perc.js-module to handle%%percmap
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.perc={do_perc:function(parm){var pits=new Int8Array([0,0,1,2,2,3,3,4,5,5,6,6]),accs=new Int8Array([3,1,3,-1,3,3,1,3,-1,3,-1,3])
var prn={"a-b-d":35,"a-s":38,"b-d-1":36,"ca":69,"cl":75,"co":56,"c-c":52,"c-c-1":49,"c-c-2":57,"c-h-h":42,"e-s":40,"h-a":67,"h-b":60,"h-c":39,"h-f-t":43,"h-m-t":48,"h-ti":65,"h-to":50,"h-w-b":76,"l-a":68,"l-b":61,"l-c":64,"l-f-t":41,"l-g":74,"l-m-t":47,"l-ti":66,"l-to":45,"l-w":72,"l-w-b":77,"m":70,"m-c":78,"m-h-c":62,"m-t":80,"o-c":79,"o-h-c":63,"o-h-h":46,"o-t":81,"p-h-h":44,"r-b":53,"r-c-1":51,"r-c-2":59,"s-c":55,"s-g":73,"s-s":37,"s-w":71,"t":54,"v":58}
function toabc(p){var i,j,s,pit
if(/^[_^]*[A-Ga-g][,']*$/.test(p))
return p
pit=Number(p)
if(isNaN(pit)){p=p.toLowerCase(p);s=p[0];i=0
while(1){j=p.indexOf('-',i)
if(j<0)
break
i=j+1;s+='-'+p[i]}
pit=prn[s]
if(!pit){switch(p[0]){case'c':switch(p[1]){case'a':pit=prn.ca;break
case'l':pit=prn.cl;break
case'o':pit=prn.co;break}
break
case'h':case'l':i=p.indexOf('-')
if(p[i+1]!='t')
break
switch(p[i+2]){case'i':case'o':pit=prn[s+p[i+2]]
break}
break}
if(!pit)
return}}
p=["C","^C","D","_E","E","F","^F","G","^G","A","_B","B"][pit%12]
while(pit<60){p+=','
pit+=12}
while(pit>=72){p+="'"
pit-=12}
return p}
var a=parm.split(/\s+/),p=a[1].replace(/[=_^]/,'')
this.do_pscom("map MIDIdrum "+a[1]+" play="+toabc(a[2])+" print="+p+
(a[3]?(" heads="+a[3]):''))
this.set_v_param("perc","MIDIdrum")},set_perc:function(a){var i,item,s,curvoice=this.get_curvoice()
for(i=0;i<a.length;i++){switch(a[i]){case"perc=":if(!curvoice.map)
curvoice.map={}
curvoice.map=a[i+1];s=this.new_block("midiprog")
s.play=s.invis=1
curvoice.chn=s.chn=9
break}}},do_pscom:function(of,text){if(text.slice(0,8)=="percmap ")
abc2svg.perc.do_perc.call(this,text)
else
of(text)},set_vp:function(of,a){abc2svg.perc.set_perc.call(this,a);of(a)},set_hooks:function(abc){abc.do_pscom=abc2svg.perc.do_pscom.bind(abc,abc.do_pscom);abc.set_vp=abc2svg.perc.set_vp.bind(abc,abc.set_vp)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.perc=abc2svg.perc.set_hooks
