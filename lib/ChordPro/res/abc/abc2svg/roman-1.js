//abc2svg-roman.js-convert the chord symbols to the RNN
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.roman={note_nm:"CDEFGAB",nm_M:["I","♯I","II","♭III","III","IV","♯IV","V","♯V","VI","♭VII","VII"],nm_m:["I","♭II","II","III","♯III","IV","♭V","V","VI","♯VI","VII","♯VII"],gch_build:function(of,s){var gch,ix,t,ty=this.cfmt().roman
function set_nm(p){var i,o,o2,a,n,csa=[]
i=p.indexOf('/')
while(i>0){if(p[i-1]!='<')
break
i=p.indexOf('/',i+1)}
if(i<0){csa.push(p)}else{csa.push(p.slice(0,i))
csa.push(p.slice(i+1))}
for(i=0;i<csa.length;i++){p=csa[i]
o=p.search(/[A-G]/)
if(o<0)
continue
a=0
o2=o+1
if(p[o2]=='#'||p[o2]=='♯'){a++
o2++}else if(p[o2]=='b'||p[o2]=='♭'){a--
o2++}
n=[0,2,4,5,7,9,11]
[abc2svg.roman.note_nm.indexOf(p[o])]
+a
+abc2svg.roman.tr
n=abc2svg.roman.nm[n%12]
if(ty==2&&p[o2]=='m'){n=n.toLowerCase()
o2++}
csa[i]=p.slice(0,o)
+n
+p.slice(o2)}
return csa.join('/')}
if(ty&&s.a_gch){for(ix=0;ix<s.a_gch.length;ix++){gch=s.a_gch[ix]
t=gch.text
if(gch.type=='g'&&t&&t[0]!='N'){t=set_nm(t)
if(t)
gch.text=t}}}
of(s)},o_mus:function(of){var tsfirst=this.get_tsfirst()
if(this.cfmt().roman){abc2svg.roman.tr=(tsfirst.p_v.key.k_sf+12)*5
if(tsfirst.p_v.key.k_mode){abc2svg.roman.tr+=3
abc2svg.roman.nm=abc2svg.roman.nm_m}else{abc2svg.roman.nm=abc2svg.roman.nm_M}}
of()},set_fmt:function(of,cmd,parm){var ty,cfmt=this.cfmt()
if(cmd=="roman"){if(!parm)
parm="1"
ty=Number(parm)
if(isNaN(ty))
this.syntax(1,this.errs.bad_val,"%%roman")
else
cfmt.roman=ty
return}
of(cmd,parm)},set_hooks:function(abc){abc.gch_build=abc2svg.roman.gch_build.bind(abc,abc.gch_build)
abc.output_music=abc2svg.roman.o_mus.bind(abc,abc.output_music)
abc.set_format=abc2svg.roman.set_fmt.bind(abc,abc.set_format)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.roman=abc2svg.roman.set_hooks
