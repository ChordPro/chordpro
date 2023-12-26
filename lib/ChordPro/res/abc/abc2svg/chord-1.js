// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2022 Jean-Francois Moine - LGPL3+
//chord.js-generation of accompaniment
abc2svg.ch_names={'':["C-E G C+","E-C G C+","G-C E G "],m:["C-e G C+","e-C G C+","G-C e G "],'7':["C-b-E G ","E-C G b ","G-E b C+","b-E G C+"],m7:["C-b-e G ","e-C G b ","G-e b C+","b-e G C+"],m7b5:["C-b-e g ","e-C g b ","g-e b C+","b-e g C+"],M7:["C-B-E G ","E-C G B ","G-E B C+","B-E G C+"],'6':["C-A-E G ","E-C A B ","A-E B C+","B-E A C+"],m6:["C-A-e G ","e-C A B ","A-e B C+","B-e A C+"],aug:["C-E a C+","E-C a C+","a-C E a "],aug7:["C-b-E a ","E-C a b ","a-E b C+","b-E a C+"],dim:["C-E g C+","E-C g C+","g-C E g "],dim7:["C-e g A ","e-C g A ","g-e A C+","A-C e G "],'9':["C-b-E G D+","E-C G b D+","G-E b C+D+","b-E G C+D+","D-G-C E b "],m9:["C-b-e G D+","e-C G b D+","G-e b C+D+","b-e G C+D+","D-G-C e b "],maj9:["C-B-E G D+","E-C G B D+","G-E B C+D+","B-E G C+D+","D-G-C E B "],M9:["C-B-E G D+","E-C G B D+","G-C E B D+","B-E G C+D+","D-G-C E B "],'11':["C-b-E G D+F+","E-C G b D+F+","G-E b C+D+F+","b-E G C+D+F+","D-G-C E b F+","F-D-G-C E b D+"],dim9:["C-A-e g d+","e-C g A d+","g-C e A d+","A-C e g d+","D-g-C e A "],sus4:["C-F G C+","F-C G C+","G-C F G "],sus9:["C-D G C+","D-C G C+","G-C D G "],'7sus4':["C-b-F G ","F-C G b ","G-F b C+","b-C F G "],'7sus9':["C-b-D G ","D-C G b ","G-D b C+","b-C D G "],'5':["C-G C+","G-G C+"]}
abc2svg.midlet="CdDeEFgGaAbB"
abc2svg.letmid={C:0,d:1,D:2,e:3,E:4,F:5,g:6,G:7,a:8,A:9,b:10,B:11}
abc2svg.chord=function(first,voice_tb,cfmt){var chnm,i,k,vch,s,gchon,cs_sel0=/[\[(][^)]*[\])]/,cs_sel1=/[^[(]*[\[(]|[\])][\s\S]*/g,C=abc2svg.C,trans=48+(cfmt.chord.trans?cfmt.chord.trans*12:0)
function chcr(b,ch){var i,v,r=[]
b=abc2svg.midlet[b]
i=ch.length
while(--i>0){if(ch[i][0]==b)
break}
ch=ch[i]
for(i=0;i<ch.length;i+=2){v=abc2svg.letmid[ch[i]]
switch(ch[i+1]){case'+':v+=12;break
case'-':v-=12;break}
r.push(v)}
return r}
function filter(a_cs,sel){var i,cs,tcs=""
for(i=0;i<a_cs.length;i++){cs=a_cs[i]
if(cs.type=='g')
tcs+=cs.otext}
if(!cs_sel0.test(tcs))
return tcs
return tcs.replace(sel?cs_sel1:cs_sel0,'')}
function gench(sb){var r,ch,b,m,n,not,a=filter(sb.a_gch,cfmt.altchord),s={v:vch.v,p_v:vch,type:C.NOTE,time:sb.time,notes:[]}
if(!a)
return
a=a.match(/([A-GN])([#♯b♭]?)([^/]*)\/?(.*)/)
if(!a)
return
r=abc2svg.letmid[a[1]]
if(r==undefined){if(a[1]!="N")
return
s.type=C.REST
ch=[0]
r=0}else{switch(a[2]){case"#":case"♯":r++;break
case"b":case"♭":r--;break}
if(!a[3]){ch=chnm[""]}else{ch=abc2svg.ch_alias[a[3]]
if(ch==undefined)
ch=a[3]
ch=chnm[ch]
if(!ch)
ch=a[3][0]=='m'?chnm.m:chnm[""]}
if(a[4]){b=a[4][0].toUpperCase()
b=abc2svg.letmid[b]
if(b!=undefined){switch(a[4][1]){case"#":case"♯":b++;if(b>=12)b=0;break
case"b":case"♭":b--;if(b<0)b=11;break}}}}
if(b==undefined)
b=0
ch=chcr(b,ch)
n=ch.length
r+=trans
for(m=0;m<n;m++){not={midi:r+ch[m]}
s.notes.push(not)}
s.nhd=n-1
s.prev=vch.last_sym
vch.last_sym.next=s
s.ts_next=sb.ts_next
sb.ts_next=s
s.ts_prev=sb
if(s.ts_next)
s.ts_next.ts_prev=s
vch.last_sym=s}
if(cfmt.chord.names){chnm=Object.create(abc2svg.ch_names)
for(k in cfmt.chord.names){vch=""
for(i=0;i<cfmt.chord.names[k].length;i++){s=cfmt.chord.names[k][i]
vch+=abc2svg.midlet[s%12]
vch+=i==0?"-":(s>=12?"+":" ")}
chnm[k]=[vch]}}else{chnm=abc2svg.ch_names}
vch={v:voice_tb.length,id:"_chord",time:0,sym:{type:C.REST,time:0},instr:cfmt.chord.prog||0,vol:cfmt.chord.vol||.6}
vch.last_sym=vch.sym
voice_tb.push(vch)
k=0
for(i=0;i<vch.v;i++){if(k<voice_tb[i].chn)
k=voice_tb[i].chn}
if(k==8)
k++
vch.chn=k+1
gchon=cfmt.chord.gchon
s=first
while(1){if(!s.ts_next){if(gchon)
vch.last_sym.dur=s.time-vch.last_sym.time
break}
s=s.ts_next
if(!s.a_gch){if(s.subtype=="midigch"){if(gchon&&!s.on)
vch.last_sym.dur=s.time-vch.last_sym.time
gchon=s.on}
continue}
if(!gchon)
continue
for(i=0;i<s.a_gch.length;i++){gch=s.a_gch[i]
if(gch.type!='g')
continue
vch.last_sym.dur=s.time-vch.last_sym.time
gench(s)
break}}}