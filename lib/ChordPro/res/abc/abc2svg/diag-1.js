// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2021 Jean-Francois Moine - LGPL3+
//diag.js-module to insert guitar chord diagrams
abc2svg.diag={cd4:{},cd6:{C:"x32010 ,0 x32010",Cm:"x03320 fr3 x03420 barre=5-1",C7:"x32310 ,0 x32410",Cm7:"003020 fr3 x03020 barre=5-1",CM7:"032000 ,0 x21000",Csus4:"x03340 fr3 x02340 barre=5-1",D:"000232 ,0 x00132",Dm:"000231 ,0 x00231",D7:"000212 ,0 x00312",Dm7:"000211 ,0 xx0211",DM7:"000222 ,0 xx0111",Dsus4:"000233 ,0 xx0134",E:"022100 ,0 023100",Em:"022000 ,0 023000",E7:"020100 ,0 020100",Em7:"022030 ,0 023040",EM7:"021100 ,0 031200",Esus4:"022200 ,0 023400",F:"033200 fr1 034200 barre=6-1",Fm:"033000 fr1 034000 barre=6-1",F7:"030200 fr1 030200 barre=6-1",Fm7:"030000 fr1 030000 barre=6-1",FM7:"xx3210 ,0 xx3210",Fsus4:"033300 fr1 023400 barre=6-1",G:"320003 ,0 230004",Gm:"033000 fr3 034000 barre=6-1",G7:"320001 ,0 320001",Gm7:"030000 fr3 030000 barre=6-1",GM7:"320002 ,0 310002",Gsus4:"033300 fr3 023400 barre=6-1",A:"002220 ,0 002340",Am:"002210 ,0 002310",A7:"002020 ,0 002030",Am7:"002010 ,0 002010",AM7:"002120 ,0 x02130",Asus4:"x02230 ,0 x02340",B:"x03330 fr2 002340 barre=5-1",Bm:"x03320 fr2 003410 barre=5-1",B7:"021202 ,0 x21304",Bm7:"003020 fr2 x03020 barre=5-1",BM7:"003230 fr2 x03240 barre=5-1",Bsus4:"x03340 fr2 x02340 barre=5-1",},do_diag:function(n){var glyphs=this.get_glyphs(),voice_tb=this.get_voice_tb(),decos=this.get_decos()
if(!glyphs.ddot){this.add_style("\
\n.fng {font:6px sans-serif}\
\n.frn {font:italic 7px sans-serif}")
glyphs.ddot='<circle id="ddot" class="fill" r="1.5"/>'}
if(!glyphs["fb"+n]){if(n==4){glyphs.fb4='<g id="fb4">\n\
<path class="stroke" stroke-width="0.4" d="\
M-6 -34h12m0 6h-12\
m0 6h12m0 6h-12\
m0 6h12"/>\n\
<path class="stroke" stroke-width="0.5" d="\
M-6 -34v24m4 0v-24\
m4 0v24m4 0v-24"/>\n\
</g>'
glyphs.nut4='<path id="nut4" class="stroke" stroke-width="1.6" d="\
M-6.2 -34.5h12.4"/>'}else{glyphs.fb6='<g id="fb6">\n\
<path class="stroke" stroke-width="0.4" d="\
M-10 -34h20m0 6h-20\
m0 6h20m0 6h-20\
m0 6h20"/>\n\
<path class="stroke" stroke-width="0.5" d="\
M-10 -34v24m4 0v-24\
m4 0v24m4 0v-24\
m4 0v24m4 0v-24"/>\n\
</g>'
glyphs.nut6='<path id="nut6" class="stroke" stroke-width="1.6" d="\
M-10.2 -34.5h20.4"/>'}}
function ch_cnv(t){var a=t.match(/[A-G][#♯b♭]?([^/]*)\/?/)
if(a&&a[1]){a[2]=abc2svg.ch_alias[a[1]]
if(a[2]!=undefined)
t=t.replace(a[1],a[2])}
return t.replace('/','.')}
function diag_add(nm){var dc,i,l,x,d=abc2svg.diag["cd"+n][nm]
if(!d)
return
nm=n+nm
d=d.split(' ')
x=2-2*n
dc='<g id="'+nm+'">\n\
<use xlink:href="#fb'+n+'"/>\n'
l=d[1].split(',')
if(!l[0]||l[0].slice(-1)==l[1])
dc+='<use xlink:href="#nut'+n+'"/>\n'
if(l[0])
dc+='<text x="'+(x-10).toString()
+'" y="'+((l[1]||1)*6-35)
+'" class="frn">'+l[0]+'</text>\n'
decos[nm]="3 "+nm+" 40 "+(l[0]?"30":"10")+" 0"
dc+='<text x="'+(n==6?'-12,-8,-4,0,4,8':'-8,-4,0,4')
+'" y="-36" class="fng">'
+d[2].replace(/[y0]/g,' ')
+'</text>\n'
for(i=0;i<n;i++){l=d[0][i]
if(l&&l!='x'&&l!='0')
dc+='<use x="'+(i*4+x)
+'" y="'+(l*6-37)
+'" xlink:href="#ddot"/>\n'}
if(d[3]){l=d[3].match(/barre=(\d)-(\d)/)
if(l)
dc+='<path id="barre" class="stroke"\
 stroke-width="1.4" d="M'+((n-l[1])*4+x-2)
+' -31h'+((l[1]-l[2])*4+4)+'"/>'}
dc+='</g>'
glyphs[nm]=dc}
var s,i,gch,nm
for(s=voice_tb[0].sym;s;s=s.next){if(!s.a_gch)
continue
for(i=0;i<s.a_gch.length;i++){gch=s.a_gch[i]
if(!gch||gch.type!='g'||gch.capo)
continue
nm=ch_cnv(gch.text)
if(!decos[n+nm])
diag_add(nm)
this.deco_put(n+nm,s)}}},output_music:function(of){var n=this.cfmt().diag
if(n)
abc2svg.diag.do_diag.call(this,n)
of()},set_fmt:function(of,cmd,param){var a,d,n,cfmt=this.cfmt()
switch(cmd){case"diagram":n=param
if(n=='0')
n=''
else if(n!='4')
n='6'
cfmt.diag=n
return
case"setdiag":n=cfmt.diag
if(!n)
n="6"
a=param.match(/(\S*)\s+(.*)/)
if(a&&a.length==3){d=a[2].split(' ')
if(d&&d.length>=3){abc2svg.diag["cd"+n][a[1].replace('/','.')]=a[2]
return}}
this.syntax(1,this.errs.bad_val,"%%setdiag")
return}
of(cmd,param)},set_hooks:function(abc){abc.output_music=abc2svg.diag.output_music.bind(abc,abc.output_music);abc.set_format=abc2svg.diag.set_fmt.bind(abc,abc.set_format)}}
abc2svg.modules.hooks.push(abc2svg.diag.set_hooks);abc2svg.modules.diagram.loaded=true
