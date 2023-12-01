// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2022 Jean-Francois Moine - LGPL3+
//abc2svg-strtab.js-tablature for string instruments
abc2svg.strtab={draw_symbols:function(of,p_v){var s,m,not,stb,x,y,g,C=abc2svg.C,abc=this
function draw_heads(stb,s){var m,not,x,y
for(m=0;m<=s.nhd;m++){not=s.notes[m]
if(not.nb<0)
continue
x=s.x-3
if(not.nb>=10)
x-=3
y=3*(not.pit-18)
abc.out_svg('<text class="bg'+abc.bgn+'" x="')
abc.out_sxsy(x,'" y="',stb+y-2.5)
abc.out_svg('">'+not.nb+'</text>\n')}}
function draw_stems(stb,s){if(!s.tabst)
return
var s1,s2,nfl,l,y=stb+3*(s.notes[0].pit-19)*s.p_v.staffscale,h=(11+3*(s.notes[0].pit-18))*s.p_v.staffscale
abc.out_svg('<path class="sW" d="M')
abc.out_sxsy(s.x,' ',y)
abc.out_svg('v'+h.toFixed(1)+'"/>\n')
if(s.nflags<=0||!s.beam_end)
return
y-=h
if(s.beam_st){abc.out_svg('<text class="f'
+abc.get_font('music').fid
+'" transform="translate(')
abc.out_sxsy(s.x,',',y)
abc.out_svg(') scale('
+(s.grace?'.5,.5':'.7,.7')+')">'
+String.fromCharCode(0xe23f+2*s.nflags)
+'</text>\n')
return}
s2=s
nfl=s.nflags
while(1){if(s.nflags>nfl)
nfl=s.nflags
if(s.beam_st)
break
s=s.prev}
s1=s
l=(s2.x-s1.x).toFixed(1)
abc.out_svg('<path d="M')
abc.out_sxsy(s1.x,' ',y)
abc.out_svg('h'+l
+'v-3h-'+l
+'v3"/>\n')
if(nfl==1)
return
y+=5
while(1){while(s.nflags<2){s=s.next
if(s==s2)
break}
if(s==s2)
break
s1=s
while(s.next.nflags>=2){s=s.next
if(s==s2)
break}
l=(s.x-s1.x).toFixed(1)
abc.out_svg('<path d="M')
abc.out_sxsy(s1.x,' ',y)
abc.out_svg('h'+l
+'v-3h-'+l
+'v3"/>\n')
if(s==s2)
break
s=s.next
if(s==s2)
break}}
if(!p_v.tab){of(p_v)
return}
m=abc.cfmt().bgcolor||"white"
if(abc.bgt!=m){if(!abc.bgn)
abc.bgn=1
else
abc.bgn++
abc.bgt=m
abc.defs_add('\
<filter x="-0.1" y="0.1" width="1.2" height=".8" id="bg'+abc.bgn+'">\n\
<feFlood flood-color="'+m+'"/>\n\
<feComposite in="SourceGraphic" operator="over"/>\n\
</filter>')
abc.add_style('\n.bg'+abc.bgn+'{filter:url(#bg'+abc.bgn+')}')}
for(s=p_v.sym;s;s=s.next){switch(s.type){case C.KEY:case C.METER:case C.REST:s.invis=true
break}}
of(p_v)
abc.glout()
stb=abc.get_staff_tb()[p_v.st].y
abc.set_sscale(-1)
for(s=p_v.sym;s;s=s.next){switch(s.type){case C.GRACE:for(g=s.extra;g;g=g.next)
draw_stems(stb,g)
break
case C.NOTE:draw_stems(stb,s)
break}}
abc.set_scale(p_v.sym)
abc.out_svg('<g class="bn">\n')
for(s=p_v.sym;s;s=s.next){switch(s.type){case C.GRACE:for(g=s.extra;g;g=g.next)
draw_heads(stb,g)
break
case C.NOTE:draw_heads(stb,s)
break}}
abc.out_svg('</g>\n')},set_fmt:function(of,cmd,parm){if(cmd=="strtab"){if(!parm)
return
var p_v=this.get_curvoice()
if(!p_v){this.parse.tab=parm
return}
this.set_v_param("clef","tab")
if(parm.indexOf("diafret")>=0){this.set_v_param("diafret",true)
parm=parm.replace(/\s*diafret\s*/,"")}
this.set_v_param("strings",parm)
return}
of(cmd,parm)},set_stems:function(of){var p_v,i,m,nt,n,bi,bn,strss,g,C=abc2svg.C,abc=this,s=abc.get_tsfirst(),strs=[],lstr=[]
function set_pit(p_v,s,nt,i){var st=s.st
if(i>=0){nt.nb=(p_v.diafret?nt.pit:nt.midi)-p_v.tab[i]
if(p_v.diafret&&nt.acc)
n+='+'
nt.pit=i*2+18}else{nt.nb=-1
nt.pit=18}
nt.acc=0
nt.invis=true
if(!s.grace)
strss[i]=s.time+s.dur
if(s.dur<=C.BLEN/2&&!s.stemless){if(!lstr[st])
lstr[st]=[10]
if(lstr[st][0]>i){lstr[st][0]=i
lstr[st][1]=s}
s.stemless=true}}
function set_notes(p_v,s){var i,bi,bn,nt,m,n
s.stem=-1
if(!s.nhd&&s.a_dd){i=s.a_dd.length
while(--i>=0){bi=strnum(s.a_dd[i].name)
if(bi>=0){nt=s.notes[0]
set_pit(p_v,s,nt,bi)
break}}}
delete s.a_dd
if(s.sls){for(i=0;i<s.sls.length;i++){s.sls[i].ty&=~0x07
s.sls[i].ty|=C.SL_ABOVE}}
ls:for(m=0;m<=s.nhd;m++){nt=s.notes[m]
if(nt.sls){for(i=0;i<nt.sls.length;i++){nt.sls[i].ty&=~0x07
nt.sls[i].ty|=C.SL_ABOVE}}
if(nt.nb!=undefined)
continue
if(nt.a_dd){i=nt.a_dd.length
while(--i>=0){bi=strnum(nt.a_dd[i].name)
if(bi>=0){set_pit(p_v,s,nt,bi)
delete nt.a_dd
continue ls}}
delete nt.a_dd}
bn=100
bi=-1
i=p_v.tab.length
while(--i>=0){if(strss[i]&&strss[i]>s.time)
continue
n=(p_v.diafret?nt.pit:nt.midi)-
p_v.tab[i]
if(n>=0&&n<bn){bi=i
bn=n}}
set_pit(p_v,s,nt,bi)}
s.y=3*(nt.pit-18)
s.ymn=0}
function strnum(n){n=n.match(/^([1-9])s?$/)
return n?p_v.tab.length-n[1]:-1}
p_v=abc.get_voice_tb()
for(n=0;n<p_v.length;n++){if(!p_v[n].tab)
continue
m=p_v[n].capo
if(m){for(i=0;i<p_v[n].tab.length;i++)
p_v[n].tab[i]+=m}}
of()
for(;s;s=s.ts_next){if(s.seqst||(s.ts_prev&&s.ts_prev.type==C.GRACE)){for(i=0;i<lstr.length;i++){if(lstr[i]){lstr[i][1].tabst=1
lstr[i]=null}}}
p_v=s.p_v
if(!p_v.tab)
continue
strss=strs[s.st]
if(!strss)
strss=strs[s.st]=[]
switch(s.type){case C.KEY:case C.REST:case C.TIME:s.invis=true
default:delete s.a_dd
continue
case C.GRACE:if(p_v.pos.gst==C.SL_HIDDEN)
s.sappo=0
for(g=s.extra;g;g=g.next){if(p_v.pos.gst==C.SL_HIDDEN)
g.stemless=true
set_notes(p_v,g)}
break
case C.NOTE:set_notes(p_v,s)
break}}},set_vp:function(of,a){var i,e,g,tab,strs,ok,p_v=this.get_curvoice()
function abc2tab(p){var i,c,a,t=[]
if(p_v.diafret){for(i=0;i<p.length;i++){c=p[i]
c="CDEFGABcdefgab".indexOf(c)
if(c<0)
return
c+=16
while(1){if(p[i+1]=="'"){c+=7
i++}else if(p[i+1]==","){c-=7
i++}else{break}}
t.push(c)}}else{for(i=0;i<p.length;i++){c=p[i]
switch(c){case'^':case'_':a=c=='^'?1:-1
c=p[++i]
break
default:a=0
break}
c="CCDDEFFGGAABccddeffggaab".indexOf(c)
if(c<0)
return
c+=60+a
while(1){if(p[i+1]=="'"){c+=12
i++}else if(p[i+1]==","){c-=12
i++}else{break}}
t.push(c)}}
return t}
function str2tab(a){var str,p,o,t=[]
if(p_v.diafret){while(1){str=a.shift()
if(!str)
break
p="CDEFGAB".indexOf(str[0])
o=Number(str[1])
if(p<0||isNaN(o))
return
t.push(o*7+p-12)}}else{while(1){str=a.shift()
if(!str)
break
p="CCDDEFFGGAAB".indexOf(str[0])
if(p<0)
return
o=str[1]
switch(o){case'#':case'b':p+=o=='#'?1:-1
o=Number(str[2])
break
default:o=Number(str[1])
break}
if(isNaN(o))
return
t.push((o+1)*12+p)}}
return t}
for(i=0;i<a.length;i++){switch(a[i]){case"clef=":e=a[i+1]
if(e!="tab")
break
a.splice(i,1)
case"tab":a.splice(i,1)
i--
ok=true
break
case"strings=":strs=a[++i]
ok=true
break
case"nostems":p_v.pos.stm=abc2svg.C.SL_HIDDEN
p_v.pos.gst=abc2svg.C.SL_HIDDEN
break
case"capo=":p_v.capo=Number(a[++i])
break
case"diafret=":i++
case"diafret":p_v.diafret=true
break}}
if(ok){if(!strs&&this.parse.tab){strs=this.parse.tab
if(strs.indexOf("diafret")>=0){p_v.diafret=true
strs=strs.replace(/\s*diafret\s*/,"")}}
if(strs){e=strs.slice(-1)
if(e>='1'&&e<='9')
tab=str2tab(strs.split(','))
else
tab=abc2tab(strs)
if(!tab){this.syntax(1,"Bad strings in tablature")
ok=false}}else if(!p_v.tab){tab=p_v.diafret?[10,14,17]:[40,45,50,55,59,64]}else{tab=p_v.tab}}
if(ok){if(p_v.capo){p_v.tab=[]
for(i=0;i<tab.length;i++)
p_v.tab.push(tab[i]+p_v.capo)}else{p_v.tab=tab}
a.push("clef=")
g=this.get_glyphs()
if(tab.length==3){a.push('"tab3"')
if(!g.tab3)
g.tab3='<text id="tab3"\
 x="-4,-4,-4" y="-4,3,10"\
 style="font:bold 8px sans-serif">TAB</text>'}else if(tab.length==4){a.push('"tab4"')
if(!g.tab4)
g.tab4='<text id="tab4"\
 x="-4,-4,-4" y="-8,1,10"\
 style="font:bold 12px sans-serif">TAB</text>'}else if(tab.length==5){a.push('"tab5"')
if(!g.tab5)
g.tab5='<text id="tab5"\
 x="-4,-4,-4" y="-11,-2,7"\
 style="font:bold 12px sans-serif">TAB</text>'}else{a.push('"tab6"')
if(!g.tab6)
g.tab6='<text id="tab6"\
 x="-4,-4,-4" y="-14.5,-4,5.5"\
 style="font:bold 13px sans-serif">TAB</text>'}
a.push("stafflines=")
a.push("|||||||||".slice(0,tab.length))
p_v.staffscale=1.6}
of(a)},set_hooks:function(abc){abc.draw_symbols=abc2svg.strtab.draw_symbols.bind(abc,abc.draw_symbols)
abc.set_format=abc2svg.strtab.set_fmt.bind(abc,abc.set_format);abc.set_stems=abc2svg.strtab.set_stems.bind(abc,abc.set_stems)
abc.set_vp=abc2svg.strtab.set_vp.bind(abc,abc.set_vp)
var decos=abc.get_decos()
decos["1s"]="0 nul 0 0 0"
decos["2s"]="0 nul 0 0 0"
decos["3s"]="0 nul 0 0 0"
decos["4s"]="0 nul 0 0 0"
decos["5s"]="0 nul 0 0 0"
decos["6s"]="0 nul 0 0 0"
if(!user.nul)
user.nul=function(){}
abc.add_style("\n.bn{font:bold 7px sans-serif}")}}
abc2svg.modules.hooks.push(abc2svg.strtab.set_hooks)
abc2svg.modules.strtab.loaded=true