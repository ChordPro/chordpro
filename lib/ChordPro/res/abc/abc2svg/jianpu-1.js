// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2023 Jean-Francois Moine - LGPL3+
//jianpu.js-module to output jiănpŭ(简谱)music sheets
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.jianpu={k_tb:["Cb","Gb","Db","Ab","Eb","Bb","F","C","G","D","A","E","B","F#","C#"],cde2fcg:new Int8Array([0,2,4,-1,1,3,5]),cgd2cde:new Int8Array([0,-4,-1,-5,-2,-6,-3,0,-4,-1,-5,-2,-6,-3,0]),acc2:new Int8Array([-2,-1,3,1,2]),acc_tb:["\ue264","\ue260",,"\ue262","\ue263","\ue261"],calc_beam:function(of,bm,s1){if(!s1.p_v.jianpu)
return of(bm,s1)},output_music:function(of){var p_v,v,C=abc2svg.C,abc=this,cur_sy=abc.get_cur_sy(),voice_tb=abc.get_voice_tb()
function ov_def(v){var s1,tim,s=p_v.sym
while(s){s1=s.ts_prev
if(!s.invis&&s.dur&&s1.v!=v&&s1.st==s.st&&s1.time==s.time){while(1){if(!s1.prev||s1.prev.bar_type)
break
s1=s1.prev}
while(!s1.bar_type){s1.dy=14
s1.notes[0].pit=30
if(s1.type==C.REST)
s1.combine=-1
s1=s1.next}
while(1){s.dy=-14
s.notes[0].pit=20
if(!s.next||s.next.bar_type||s.next.time>=s1.time)
break
s=s.next}}
s=s.next}}
function set_head(){var v,p_v,mt,s2,sk,s,tsfirst=abc.get_tsfirst()
for(v=0;v<voice_tb.length;v++){p_v=voice_tb[v]
if(p_v.jianpu)
break}
if(v>=voice_tb.length)
return
mt=p_v.meter.a_meter[0]
sk=p_v.key
s2=p_v.sym
s={type:C.BLOCK,subtype:"text",time:s2.time,dur:0,v:0,p_v:p_v,st:0,fmt:s2.fmt,seqst:true,text:(sk.k_mode+1)+"="+
(abc2svg.jianpu.k_tb[sk.k_sf+7+
abc2svg.jianpu.cde2fcg[sk.k_mode]]),font:abc.get_font("text")}
if(mt)
s.text+=' '+(mt.bot?(mt.top+'/'+mt.bot):mt.top)
s2=tsfirst
s.next=s2.next
if(s.next)
s.next.prev=s
s.prev=s2
s2.next=s
s.ts_next=s2.ts_next
s.ts_next.ts_prev=s
s.ts_prev=s2
s2.ts_next=s}
function slice(s){var n,s2,s3,jn=s.type==C.REST?0:8
if(s.dur>=C.BLEN)
n=3
else if(s.dur==C.BLEN/2)
n=1
else
n=2
s.notes[0].dur=s.dur=s.dur_orig=C.BLEN/4
delete s.fmr
while(--n>=0){s2={type:C.REST,v:s.v,p_v:s.p_v,st:s.st,dur:C.BLEN/4,dur_orig:C.BLEN/4,fmt:s.fmt,stem:0,multi:0,nhd:0,notes:[{dur:s.dur,pit:s.notes[0].pit,jn:jn}],xmx:0,noplay:true,time:s.time+C.BLEN/4,prev:s,next:s.next}
s.next=s2
if(s2.next)
s2.next.prev=s2
if(!s.ts_next){s.ts_next=s2
if(s.soln)
s.soln=false
s2.ts_prev=s
s2.seqst=true}else{for(s3=s.ts_next;s3;s3=s3.ts_next){if(s3.time<s2.time)
continue
if(s3.time>s2.time){s2.seqst=true
s3=s3.ts_prev}
s2.ts_next=s3.ts_next
s2.ts_prev=s3
if(s2.ts_next)
s2.ts_next.ts_prev=s2
s3.ts_next=s2
break}}
s=s2}}
function set_note(s,sf){var i,m,note,p,pit,a,nn,delta=abc2svg.jianpu.cgd2cde[sf+7]-2
s.stem=-1
s.stemless=true
if(s.sls){for(i=0;i<s.sls.length;i++)
s.sls[i].ty=C.SL_ABOVE}
for(m=0;m<=s.nhd;m++){note=s.notes[m]
p=note.pit
pit=p+delta
note.jn=((pit+77)%7)+1
note.pit=25
note.jo=(pit/7)|0
a=note.acc
if(a){nn=abc2svg.jianpu.cde2fcg[(p+5+16*7)%7]-sf
if(a!=3)
nn+=a*7
nn=((((nn+1+21)/7)|0)+2-3+32*5)%5
note.acc=abc2svg.jianpu.acc2[nn]}
if(note.sls){for(i=0;i<note.sls.length;i++)
note.sls[i].ty=C.SL_ABOVE}
if(note.tie_ty)
note.tie_ty=C.SL_ABOVE}
if(s.dur>=C.BLEN/2&&!s.invis)
slice(s)
if(s.a_dd){for(i=0;i<s.a_dd.length;i++){if(s.a_dd[i].glyph=="stc"){abc.deco_put("gstc",s)
s.a_dd[i]=s.a_dd.pop()}}}}
function set_sym(p_v){var s,g,sf=p_v.key.k_sf
delete p_v.key.k_a_acc
s=p_v.clef
s.invis=true
s.clef_type='t'
s.clef_line=2
for(s=p_v.sym;s;s=s.next){s.st=p_v.st
switch(s.type){case C.CLEF:s.invis=true
s.clef_type='t'
s.clef_line=2
default:continue
case C.KEY:sf=s.k_sf
s.a_gch=[{type:'@',font:abc.get_font("annotation"),wh:[10,10],x:-5,y:26,text:(s.k_mode+1)+"="+
(abc2svg.jianpu.k_tb[sf+7+
abc2svg.jianpu.cde2fcg[s.k_mode]])}]
continue
case C.REST:if(s.notes[0].jn)
continue
s.notes[0].jn=0
if(s.dur>=C.BLEN/2&&!s.invis)
slice(s)
continue
case C.NOTE:set_note(s,sf)
break
case C.GRACE:for(g=s.extra;g;g=g.next)
set_note(g,sf)
break}}}
set_head()
for(v=0;v<voice_tb.length;v++){p_v=voice_tb[v]
if(p_v.jianpu){set_sym(p_v)
if(p_v.second)
ov_def(v)}}
of()},draw_symbols:function(of,p_voice){var s,s2,nl,y,C=abc2svg.C,abc=this,dot="\ue1e7",staff_tb=abc.get_staff_tb(),out_svg=abc.out_svg,out_sxsy=abc.out_sxsy,xypath=abc.xypath
if(!p_voice.jianpu){of(p_voice)
return}
function draw_dur(s1,x,y,s2,n,nl){var s,s3,sc=s1.grace?.5:1
xypath(x-3,y+5)
out_svg('h'+((s2.x-s1.x)/sc+8).toFixed(1)+'"/>\n')
y-=2.5
while(++n<=nl){s=s1
while(1){if(s.nflags&&s.nflags>=n){s3=s
while(s!=s2){if(s.next.beam_br1||(s.next.beam_br2&&n>2)||(s.next.nflags&&s.next.nflags<n))
break
s=s.next}
draw_dur(s3,s3.x,y,s,n,nl)}
if(s==s2)
break
s=s.next}}}
function out_mus(x,y,p){out_svg('<text x="')
out_sxsy(x,'" y="',y)
out_svg('">'+p+'</text>\n')}
function out_txt(x,y,p){out_svg('<text class="fj" x="')
out_sxsy(x,'" y="',y)
out_svg('">'+p+'</text>\n')}
function draw_hd(s,x,y){var m,note,ym
for(m=0;m<=s.nhd;m++){note=s.notes[m]
out_txt(x-3.5,y+8,"01234567-"[note.jn])
if(note.acc)
out_mus(x-12,y+12,abc2svg.jianpu.acc_tb[note.acc+2])
if(note.jo>2){out_mus(x-1,y+22,dot)
if(note.jo>3){y+=3
out_mus(x-1,y+22,dot)}}else if(note.jo<2){ym=y+4
if(m==0&&s.nflags>0)
ym-=2.5*s.nflags
out_mus(x-1,ym,dot)
if(note.jo<1){ym-=3
out_mus(x-1,ym,dot)}}
y+=20}}
function draw_note(s){var sc=1,x=s.x,y=staff_tb[s.st].y
if(s.dy)
y+=s.dy
if(s.grace){out_svg('<g transform="translate(')
out_sxsy(x,',',y+15)
out_svg(') scale(.5)">\n')
abc.stv_g().g++
x=0
y=0
sc=.5}
draw_hd(s,x,y)
if(s.nflags>=0&&s.dots)
out_mus(x+8*sc,y+13*sc,dot)
if(s.grace){out_svg('</g>\n')
abc.stv_g().g--}}
for(s=p_voice.sym;s;s=s.next){if(s.invis)
continue
switch(s.type){case C.METER:abc.draw_meter(s)
break
case C.NOTE:case C.REST:draw_note(s)
break
case C.GRACE:for(g=s.extra;g;g=g.next)
draw_note(g)
break}}
for(s=p_voice.sym;s;s=s.next){if(s.invis)
continue
switch(s.type){case C.NOTE:case C.REST:nl=s.nflags
if(nl<=0)
continue
y=staff_tb[s.st].y
s2=s
while(s.next&&s.next.nflags>0){s=s.next
if(s.nflags>nl)
nl=s.nflags
if(s.beam_end)
break}
if(s.dy)
y+=s.dy
draw_dur(s2,s2.x,y,s,1,nl)
break}}},set_fmt:function(of,cmd,param){if(cmd=="jianpu"){this.set_v_param("jianpu",param)
return}
of(cmd,param)},set_pitch:function(of,last_s){of(last_s)
if(!last_s)
return
var C=abc2svg.C
for(var s=this.get_tsfirst();s;s=s.ts_next){if(!s.p_v.jianpu)
continue
switch(s.type){case C.KEY:if(s.prev.type==C.CLEF||s.v!=0)
s.a_gch=null
break
case C.NOTE:s.ymx=20*s.nhd+22
if(s.notes[s.nhd].jo>2){s.ymx+=3
if(s.notes[s.nhd].jo>3)
s.ymx+=2}
s.ymn=0
break}}},set_vp:function(of,a){var i,p_v=this.get_curvoice()
for(i=0;i<a.length;i++){if(a[i]=="jianpu="){p_v.jianpu=this.get_bool(a[++i])
if(p_v.jianpu)
this.set_vp(["staffsep=","20","sysstaffsep=","14","stafflines=","...","tuplets=","0 1 0 1"])
break}}
of(a)},set_width:function(of,s){of(s)
if(!s.p_v||!s.p_v.jianpu)
return
var w,m,note,C=abc2svg.C
switch(s.type){case C.CLEF:case C.KEY:s.wl=s.wr=.1
break
case C.NOTE:for(m=0;m<=s.nhd;m++){note=s.notes[m]
if(note.acc&&s.wl<14)
s.wl=14}
break}},set_hooks:function(abc){abc.calculate_beam=abc2svg.jianpu.calc_beam.bind(abc,abc.calculate_beam)
abc.draw_symbols=abc2svg.jianpu.draw_symbols.bind(abc,abc.draw_symbols)
abc.output_music=abc2svg.jianpu.output_music.bind(abc,abc.output_music)
abc.set_format=abc2svg.jianpu.set_fmt.bind(abc,abc.set_format)
abc.set_pitch=abc2svg.jianpu.set_pitch.bind(abc,abc.set_pitch)
abc.set_vp=abc2svg.jianpu.set_vp.bind(abc,abc.set_vp)
abc.set_width=abc2svg.jianpu.set_width.bind(abc,abc.set_width)
abc.get_glyphs().gstc='<circle id="gstc" cx="0" cy="-3" r="2"/>'
abc.get_decos().gstc="0 gstc 5 1 1"
abc.add_style("\n.fj{font:15px sans-serif}")}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.jianpu=abc2svg.jianpu.set_hooks
