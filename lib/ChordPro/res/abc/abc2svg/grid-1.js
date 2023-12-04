//abc2svg-grid.js-module to insert a chord grid before or after a tune
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.grid={pl:'<path class="stroke" stroke-width="1" d="M',block_gen:function(of,s){if(s.subtype!="grid"){of(s)
return}
var abc=this,img,cls,cfmt=abc.cfmt(),grid=cfmt.grid
function build_grid(s,font){var i,k,l,nr,bar,w,hr,x0,x,y,yl,ps,d,lc='',chords=s.chords,bars=s.bars,parts=s.parts||[],wmx=s.wmx,cells=[],nc=grid.n
function set_chords(){var i,ch,pch='-'
for(i=0;i<chords.length;i++){ch=chords[i]
if(!ch[0])
ch[0]=pch
if(ch.length==0)
continue
if(ch.length==1){pch=ch[0]
continue}
if(ch.length==2){ch[2]=ch[1];ch[1]=null;pch=ch[2]
continue}
if(ch.length==3){pch=ch[2]
continue}
if(!ch[2])
ch[2]=ch[1]||ch[0];pch=ch[3]}}
function build_cell(cell,x,y,yl,hr){if(cell.length>1){abc.out_svg(abc2svg.grid.pl)
abc.out_sxsy(x-wmx/2,' ',yl)
abc.out_svg('l'+
wmx.toFixed(1)+' -'+hr.toFixed(1)+'"/>\n')
if(cell[1]){abc.out_svg(abc2svg.grid.pl)
abc.out_sxsy(x-wmx/2,' ',yl+hr)
abc.out_svg('l'+
(wmx/2).toFixed(1)+' '+(hr/2).toFixed(1)+'"/>\n')
abc.set_font('gs')
abc.xy_str(x-wmx/3,y,cell[0])
abc.xy_str(x,y+hr/3,cell[1])}else{abc.set_font('gs')
abc.xy_str(x-wmx*.2,y+hr/4,cell[0])}
if(cell.length>=3){if(cell[3]){abc.out_svg(abc2svg.grid.pl)
abc.out_sxsy(x,' ',yl+hr/2)
abc.out_svg('l'+
(wmx/2).toFixed(1)+' '+(hr/2).toFixed(1)+'"/>\n')
abc.set_font('gs')
abc.xy_str(x,y-hr/3,cell[2])
abc.xy_str(x+wmx/3,y,cell[3])}else{abc.set_font('gs')
abc.xy_str(x+wmx*.2,y-hr/4,cell[2])}}}else{abc.set_font('grid')
abc.xy_str(x,y,cell[0])}}
function draw_hl(){var i,i1,j,x,y=-1
for(i=0;i<=nr+1;i++){j=0
i1=i>0?i-1:0
while(1){while(j<=nc&&!d[i1][j])
j++
if(j>nc)
break
x=wmx*j
while(j<=nc&&d[i1][j])
j++
if(i&&i1<nr){while(j<=nc&&d[i1+1][j])
j++}
abc.out_svg('M')
abc.out_sxsy(x0+x,' ',y)
abc.out_svg('h'+(wmx*j-x).toFixed(1)+'\n')}
y-=hr}}
function draw_vl(){var i,i1,j,y,x=x0
for(i=0;i<=nc;i++){j=0
i1=i>0?i-1:0
while(1){while(j<=nr&&!d[j][i1])
j++
if(j>nr)
break
y=hr*j
while(j<=nr&&d[j][i1])
j++
abc.out_svg('M')
abc.out_sxsy(x,' ',-y-.5)
abc.out_svg('v'+(hr*j-y+1).toFixed(1)+'\n')}
x+=wmx}}
set_chords()
if(!grid.ls){cells=chords}else{bar=bars;bars=[]
ps=parts
parts=[]
for(i=0;i<grid.ls.length;i++){l=grid.ls[i]
if(l.indexOf('-')<0)
l=[l,l]
else
l=l.split('-')
for(k=l[0]-1;k<l[1];k++){if(!chords[k])
break
cells.push(chords[k]);bars.push(bar[k])
parts.push(ps[k])}}
bars.push(bar[k])}
if(nc<0)
nc=-nc
if(nc<3)
nc=cells.length%6==0?6:8
if(nc>cells.length)
nc=cells.length;hr=font.size*2
if(wmx<hr*1.5)
wmx=hr*1.5
x0=img.width-img.lm-img.rm
w=wmx*nc
if(w>x0){nc/=2;w/=2}
yl=-1
y=-1+font.size*.6
nr=-1
x0=(x0/cfmt.scale-w)/2
d=[]
for(i=0;i<cells.length;i++){if(i==0||(grid.repbrk&&(bars[i].slice(-1)==':'||bars[i][0]==':'))||parts[i]||k>=nc){y-=hr
yl-=hr
x=x0+wmx/2
k=0
nr++
d[nr]=[]}
d[nr][k]=1
k++
build_cell(cells[i],x,y,yl,hr)
x+=wmx}
abc.out_svg('<path class="stroke" stroke-width="1" d="\n')
draw_hl()
draw_vl()
abc.out_svg('"/>\n')
y=-1+font.size*.7
x=x0
for(i=0;i<bars.length;i++){bar=bars[i]
if(bar[0]==':'){abc.out_svg('<text class="'+cls+'" x="')
abc.out_sxsy(x-5,'" y="',y)
abc.out_svg('" style="font-weight:bold;font-size:'+
(font.size*1.5).toFixed(1)+'px">:</text>\n')}
if(i==0||(grid.repbrk&&(bar.slice(-1)==':'||bar[0]==':'))||parts[i]||k>=nc){y-=hr;x=x0
k=0
if(parts[i]){w=abc.strwh(parts[i])[0]
abc.out_svg('<text class="'+cls+'" x="')
abc.out_sxsy(x-2-w,'" y="',y)
abc.out_svg('" style="font-weight:bold">'+
parts[i]+'</text>\n')}}
k++
if(bar.slice(-1)==':'){abc.out_svg('<text class="'+cls+'" x="')
abc.out_sxsy(x+5,'" y="',y)
abc.out_svg('" style="font-weight:bold;font-size:'+
(font.size*1.5).toFixed(1)+'px">:</text>\n')}
x+=wmx}
abc.vskip(hr*(nr+1)+6)}
var p_voice,n,font,f2
abc.set_page()
img=abc.get_img()
font=abc.get_font('grid')
if(font.class)
font.class+=' mid'
else
font.class='mid'
cls=abc.font_class(font)
abc.param_set_font("gsfont",font.name+' '+(font.size*.7).toFixed(1))
f2=cfmt.gsfont
if(font.weight)
f2.weight=font.weight
if(font.style)
f2.style=font.style
f2.class=font.class
abc.add_style("\n.mid {text-anchor:middle}")
abc.blk_flush()
build_grid(s,font)
abc.blk_flush()},set_stems:function(of){var C=abc2svg.C,abc=this,tsfirst=abc.get_tsfirst(),voice_tb=abc.get_voice_tb(),cfmt=abc.cfmt(),grid=cfmt.grid
function cs_filter(a_cs){var i,cs,t
for(i=0;i<a_cs.length;i++){cs=a_cs[i]
if(cs.type!='g')
continue
t=cs.text
if(cfmt.altchord){for(i++;i<a_cs.length;i++){cs=a_cs[i]
if(cs.type!='g')
continue
t=cs.text
break}}
return t.replace(/\[|\]/g,'')}}
function get_beat(s){var beat=C.BLEN/4
if(!s.a_meter[0]||s.a_meter[0].top[0]=='C'||!s.a_meter[0].bot)
return beat
beat=C.BLEN/s.a_meter[0].bot[0]|0
if(s.a_meter[0].bot[0]==8&&s.a_meter[0].top[0]%3==0)
beat=C.BLEN/8*3
return beat}
function build_chords(sb){var s,i,w,bt,rep,bars=[],chords=[],parts=[],chord=[],beat=get_beat(voice_tb[0].meter),wm=voice_tb[0].meter.wmeasure,cur_beat=0,beat_i=0,wmx=0,some_chord=0
bars.push('|')
for(s=tsfirst;s;s=s.ts_next){while(s.time>cur_beat){if(beat_i<3)
beat_i++
cur_beat+=beat}
if(s.part)
parts[chords.length]=s.part.text
switch(s.type){case C.NOTE:case C.REST:case C.SPACE:if(!s.a_gch||chord[beat_i])
break
bt=cs_filter(s.a_gch)
if(!bt)
break
w=abc.strwh(bt.replace(/<[^>]+>/gm,''))
if(w[0]>wmx)
wmx=w[0]
bt=new String(bt)
bt.wh=w
chord[beat_i]=bt
break
case C.BAR:i=s.bar_num
bt=s.bar_type
while(s.ts_next&&s.ts_next.time==s.time){if(s.ts_next.dur||s.ts_next.type==C.SPACE)
break
s=s.ts_next
if(s.type==C.METER){beat=get_beat(s)
wm=s.wmeasure
continue}
if(s.type!=C.BAR)
continue
if(s.bar_type[0]==':'&&bt[0]!=':')
bt=':'+bt
if(s.bar_type.slice(-1)==':'&&bt.slice(-1)!=':')
bt+=':'
if(s.bar_num)
i=s.bar_num
if(s.part)
parts[chords.length+1]=s.part.text}
if(grid.norep)
bt='|'
if(s.time<wm){if(chord.length){chords.push(chord)
bars.push(bt)}else{bars[0]=bt}}else{if(!i)
break
chords.push(chord)
bars.push(bt)}
if(chord.length)
some_chord++
chord=[]
cur_beat=s.time
beat_i=0
if(bt.indexOf(':')>=0)
rep=true
break
case C.METER:beat=get_beat(s)
wm=s.wmeasure
break}}
if(chord.length){bars.push('')
chords.push(chord)}
if(!some_chord)
return
wmx+=abc.strwh(rep?'    ':'  ')[0]
sb.chords=chords
sb.bars=bars
if(grid.parts&&parts.length)
sb.parts=parts
sb.wmx=wmx}
if(grid){var C=abc2svg.C,tsfirst=this.get_tsfirst(),fmt=tsfirst.fmt,voice_tb=this.get_voice_tb(),p_v=voice_tb[this.get_top_v()],s={type:C.BLOCK,subtype:'grid',dur:0,time:0,p_v:p_v,v:p_v.v,st:p_v.st}
if(!cfmt.gridfont)
abc.param_set_font("gridfont","serif 16")
abc.set_font('grid')
build_chords(s)
if(!s.chords){}else if(grid.nomusic){this.set_tsfirst(s)}else if(grid.n<0){for(var s2=tsfirst;s2.ts_next;s2=s2.ts_next);s.time=s2.time
s.prev=p_v.last_sym.prev
s.prev.next=s
s.next=p_v.last_sym
p_v.last_sym.prev=s
s.ts_prev=s2.ts_prev
s.ts_prev.ts_next=s
s.ts_next=s2
s2.ts_prev=s
if(s2.seqst){s.seqst=true
s2.seqst=false}}else{s.next=p_v.sym
s.ts_next=tsfirst
tsfirst.ts_prev=s
this.set_tsfirst(s)
p_v.sym.prev=s
p_v.sym=s}
s.fmt=s.prev?s.prev.fmt:fmt}
of()},set_fmt:function(of,cmd,parm){if(cmd=="grid"){if(!parm)
parm="1";parm=parm.split(/\s+/)
var grid={n:Number(parm.shift())}
if(isNaN(grid.n)){if(parm.length){this.syntax(1,this.errs.bad_val,"%%grid")
return}
grid.n=1}
while(parm.length){var item=parm.shift()
if(item=="norepeat")
grid.norep=true
else if(item=="nomusic")
grid.nomusic=true
else if(item=="parts")
grid.parts=true
else if(item=="repbrk")
grid.repbrk=true
else if(item.slice(0,8)=="include=")
grid.ls=item.slice(8).split(',')}
this.cfmt().grid=grid
return}
of(cmd,parm)},set_hooks:function(abc){abc.block_gen=abc2svg.grid.block_gen.bind(abc,abc.block_gen)
abc.set_stems=abc2svg.grid.set_stems.bind(abc,abc.set_stems)
abc.set_format=abc2svg.grid.set_fmt.bind(abc,abc.set_format)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.grid=abc2svg.grid.set_hooks
