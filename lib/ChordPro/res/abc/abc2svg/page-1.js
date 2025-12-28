//page.js-module to generate pages
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.page={abc_end:function(of){var page=this.page
if(page&&page.in_page)
abc2svg.page.close_page(page)
if(abc2svg.page.user_out){this.get_user().img_out=abc2svg.page.user_out
abc2svg.page.user_out=null
abc2svg.abc_end=of}
of()},svg_tag:function(w,h,ty,user){w=Math.ceil(w)
h=Math.ceil(h)
return'<svg xmlns="http://www.w3.org/2000/svg" version="1.1"\n\
 xmlns:xlink="http://www.w3.org/1999/xlink"\n\
 class="'
+ty+'" '
+(user.imagesize!=undefined?(user.imagesize):('width="'+w+'px" height="'+h+'px"'))
+' viewBox="0 0 '+w+' '+h+'">'},gen_hf:function(page,ty){var a,i,j,k,x,y,y0,s,str,font=page.abc.get_font(ty.substr(0,6)),cfmt=page.abc.cfmt(),fh=font.size*1.1,pos=['">','" text-anchor="middle">','" text-anchor="end">']
function clean_txt(txt){return txt.replace(/<|>|&.*?;|&/g,function(c){switch(c){case'<':return"&lt;"
case'>':return"&gt;"
case'&':return"&amp;"}
return c})}
function clr(str){return str.indexOf('\u00ff')>=0?'':str}
function header_footer(o_font,str){var c,d,i,k,t,n_font,s,noc,c_font=o_font,nl=1,j=0,r=["","",""]
if(str[0]=='"')
str=str.slice(1,-1)
while(1){i=str.indexOf('$',j)
if(i<0)
break
c=str[++i]
s='$'+c
switch(c){case'd':if(!abc2svg.get_mtime)
break
d=abc2svg.get_mtime(abc.get_parse().fname)
case'D':if(c=='D')
d=new Date()
if(cfmt.dateformat[0]=='"')
cfmt.dateformat=cfmt.dateformat.slice(1,-1)
d=strftime(cfmt.dateformat,d)
break
case'F':d=typeof document!="undefined"?window.location.href:page.abc.get_parse().fname
break
case'I':c=str[++i]
s+=c
case'T':t=page.abc.info()[c]
d=t?t.split('\n',1)[0]:''
break
case'P':case'Q':j=str.indexOf('\t',i)
noc=str.indexOf('$P',i)
noc=noc>0&&noc<j?'':'\u00ff',t=c=='P'?page.pn:page.pna
switch(str[i+1]){case'0':s+='0'
d=(t&1)?noc:t
break
case'1':s+='1'
d=(t&1)?t:noc
break
default:d=t
break}
break
case'V':d="abc2svg-"+abc2svg.version
break
default:d=''
if(c=='0')
n_font=o_font
else if(c>='1'&&c<'9')
n_font=page.abc.get_font("u"+c)
else
break
if(n_font==c_font)
break
if(c_font!=o_font)
d+="</tspan>"
c_font=n_font
if(c_font==o_font)
break
d+='<tspan class="'+
font_class(n_font)+'">'
break}
str=str.replace(s,d)
j=i}
if(c_font!=o_font)
str+="</tspan>";str=str.split('\n')
r[4]=str.length
for(j=0;j<str.length;j++){if(j!=0)
for(i=0;i<3;i++)
r[i]+='\n'
t=str[j].split('\t')
if(t.length==1){r[1]+=clr(t[0])}else{for(i=0;i<3;i++){if(t[i])
r[i]+=clr(t[i])}}}
return r}
function font_class(font){if(font.class)
return'f'+font.fid+cfmt.fullsvg+' '+font.class
return'f'+font.fid+cfmt.fullsvg}
if(!(page.pn&1))
str=page[ty+'2']||page[ty]
else
str=page[ty]
if(str[0]=='-'){if(page.pn==1)
return 0
str=str.slice(1)}
a=header_footer(font,clean_txt(str))
y0=font.size*.8
for(i=0;i<3;i++){str=a[i]
if(!str)
continue
if(i==0)
x=cfmt.leftmargin
else if(i==1)
x=cfmt.pagewidth/2
else
x=cfmt.pagewidth-cfmt.rightmargin
y=y0
k=0
while(1){j=str.indexOf('\n',k)
if(j>=0)
s=str.slice(k,j)
else
s=str.slice(k)
if(s)
page.hf+='<text class="'+
font_class(font)+'" x="'+x.toFixed(1)+'" y="'+y.toFixed(1)+
pos[i]+
s+'</text>\n'
if(j<0)
break
k=j+1
y+=fh}}
return fh*a[4]},open_page:function(page,ht){var h,abc=page.abc,cfmt=abc.cfmt(),sty='<div style="line-height:0'
page.pn++
page.pna++
if(page.first)
page.first=false
else
sty+=";page-break-before:always"
if(page.gutter)
sty+=";margin-left:"+
((page.pn&1)?page.gutter:-page.gutter).toFixed(1)+"px"
abc2svg.page.user_out(sty+'">')
page.in_page=true
ht+=page.topmargin
page.hmax=cfmt.pageheight-page.botmargin-ht
page.hf=''
if(page.header){abc.clr_sty()
if(!cfmt.headerfont)
abc.param_set_font("headerfont","text,serif 16")
h=abc2svg.page.gen_hf(page,"header")
if(!h&&page.pn==1&&page.header1)
h=abc2svg.page.gen_hf(page,"header1")
sty=abc.get_font_style()
if(cfmt.fullsvg||sty!=page.hsty){page.hsty=sty
sty='<style>'+sty+'\n</style>\n'}else{sty=''}
if(ht+h)
abc2svg.page.user_out(abc2svg.page.svg_tag(cfmt.pagewidth,ht+h,"header",abc.get_user())
+sty+'<g transform="translate(0,'+
page.topmargin.toFixed(1)+')">\n'+
page.hf+'</g>\n</svg>')
page.hmax-=h;page.hf=''}else if(ht){abc2svg.page.user_out(abc2svg.page.svg_tag(cfmt.pagewidth,ht,"header",abc.get_user())
+'\n</svg>')}
if(page.footer){abc.clr_sty()
if(!cfmt.footerfont)
abc.param_set_font("footerfont","text,serif 16")
page.fh=abc2svg.page.gen_hf(page,"footer")
sty=abc.get_font_style()
if(cfmt.fullsvg||sty!=page.fsty){page.fsty=sty
page.ffsty='<style>'+sty+'\n</style>\n'}else{page.ffsty=''}
page.hmax-=page.fh}
page.h=0},close_page:function(page){var h,cfmt=page.abc.cfmt()
page.in_page=false
if(page.footer){h=page.hmax+page.fh-page.h
if(h)
abc2svg.page.user_out(abc2svg.page.svg_tag(cfmt.pagewidth,h,"footer",page.abc.get_user())+
page.ffsty+'<g transform="translate(0,'+
(h-page.fh).toFixed(1)+')">\n'+
page.hf+'</g>\n</svg>')}
abc2svg.page.user_out('</div>')
page.h=0},img_in:function(p){var h,ht,nh,page=this.page
function blkcpy(page){while(page.blk.length)
abc2svg.page.user_out(page.blk.shift())
page.blk=null}
switch(p.slice(0,4)){case"<div":if(p.indexOf('newpage')>0||(page.oneperpage&&this.info().X)||!page.h){if(page.in_page)
abc2svg.page.close_page(page)
abc2svg.page.open_page(page,0)}
page.blk=[]
page.hb=page.h
break
case"<svg":h=Number(p.match(/viewBox="0 0 [\d.]+ ([\d.]+)"/)[1])
while(h+page.h>=page.hmax){ht=page.blk?0:this.cfmt().topspace
if(page.blk){if(!page.hb){blkcpy(page)
nh=0}else{nh=page.h-page.hb
page.h=page.hb}}
abc2svg.page.close_page(page)
abc2svg.page.open_page(page,ht)
if(page.blk){blkcpy(page)
page.h=nh}
if(h>page.hmax)
break}
if(page.blk)
page.blk.push(p)
else
abc2svg.page.user_out(p)
page.h+=h
break
case"</di":if(page.blk)
blkcpy(page)
break}},set_fmt:function(of,cmd,parm){var v,user=this.get_user(),cfmt=this.cfmt(),page=this.page
if(cmd=="pageheight"){v=this.get_unit(parm)
if(isNaN(v)){this.syntax(1,this.errs.bad_val,'%%'+cmd)
return}
if(!user.img_out||!abc2svg.abc_end)
v=0
cfmt.pageheight=v
if(!v){if(abc2svg.page.user_out){user.img_out=abc2svg.page.user_out
abc2svg.page.user_out=null
abc2svg.page.abc_end=abc2svg.page.abc_end_o}
delete this.page
return}
if(!page||!abc2svg.page.user_out){this.page=page={abc:this,topmargin:38,botmargin:38,h:0,pn:0,pna:0,ffsty:'',first:true}
if(cfmt.header){page.header=cfmt.header;cfmt.header=null}
if(cfmt.footer){page.footer=cfmt.footer;cfmt.footer=null}
if(cfmt.header1){page.header1=cfmt.header1
cfmt.header1=null}
if(cfmt.header2){page.header2=cfmt.header2
cfmt.header2=null}
if(cfmt.footer2){page.footer2=cfmt.footer2
cfmt.footer2=null}
if(cfmt.botmargin!=undefined){v=this.get_unit(cfmt.botmargin)
if(!isNaN(v))
page.botmargin=v}
if(cfmt.topmargin!=undefined){v=this.get_unit(cfmt.topmargin)
if(!isNaN(v))
page.topmargin=v}
if(cfmt.gutter!=undefined){v=this.get_unit(cfmt.gutter)
if(!isNaN(v))
page.gutter=v}
if(cfmt.oneperpage)
page.oneperpage=this.get_bool(cfmt.oneperpage)
if(!cfmt.dateformat)
cfmt.dateformat="%b %e, %Y %H:%M"
if(!abc2svg.page.user_out){abc2svg.page.user_out=user.img_out
abc2svg.page.abc_end_o=abc2svg.abc_end}
abc2svg.abc_end=abc2svg.page.abc_end.bind(this,abc2svg.abc_end)
user.img_out=abc2svg.page.img_in.bind(this)}
return}
if(page){switch(cmd){case"header":case"footer":case"header1":case"header2":case"footer2":page[cmd]=parm
return
case"newpage":if(!parm)
break
v=Number(parm)
if(isNaN(v)){this.syntax(1,this.errs.bad_val,'%%'+cmd)
return}
page.pn=v-1
return
case"gutter":case"botmargin":case"topmargin":v=this.get_unit(parm)
if(isNaN(v)){this.syntax(1,this.errs.bad_val,'%%'+cmd)
return}
page[cmd]=v
return
case"oneperpage":page[cmd]=this.get_bool(parm)
return}}
of(cmd,parm)},set_hooks:function(abc){abc.set_format("page-format",1)
abc.set_format=abc2svg.page.set_fmt.bind(abc,abc.set_format)
abc.set_pagef()}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.page=abc2svg.page.set_hooks
function strftime(sFormat,date){if(!(date instanceof Date))date=new Date();var nDay=date.getDay(),nDate=date.getDate(),nMonth=date.getMonth(),nYear=date.getFullYear(),nHour=date.getHours(),aDays=['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'],aMonths=['January','February','March','April','May','June','July','August','September','October','November','December'],aDayCount=[0,31,59,90,120,151,181,212,243,273,304,334],isLeapYear=function(){return(nYear%4===0&&nYear%100!==0)||nYear%400===0},getThursday=function(){var target=new Date(date);target.setDate(nDate-((nDay+6)%7)+3);return target},zeroPad=function(nNum,nPad){return((Math.pow(10,nPad)+nNum)+'').slice(1)};return sFormat.replace(/%[a-z]/gi,function(sMatch){return(({'%a':aDays[nDay].slice(0,3),'%A':aDays[nDay],'%b':aMonths[nMonth].slice(0,3),'%B':aMonths[nMonth],'%c':date.toUTCString(),'%C':Math.floor(nYear/100),'%d':zeroPad(nDate,2),'%e':nDate,'%F':date.toISOString().slice(0,10),'%G':getThursday().getFullYear(),'%g':(getThursday().getFullYear()+'').slice(2),'%H':zeroPad(nHour,2),'%I':zeroPad((nHour+11)%12+1,2),'%j':zeroPad(aDayCount[nMonth]+nDate+((nMonth>1&&isLeapYear())?1:0),3),'%k':nHour,'%l':(nHour+11)%12+1,'%m':zeroPad(nMonth+1,2),'%n':nMonth+1,'%M':zeroPad(date.getMinutes(),2),'%p':(nHour<12)?'AM':'PM','%P':(nHour<12)?'am':'pm','%s':Math.round(date.getTime()/1000),'%S':zeroPad(date.getSeconds(),2),'%u':nDay||7,'%V':(function(){var target=getThursday(),n1stThu=target.valueOf();target.setMonth(0,1);var nJan1=target.getDay();if(nJan1!==4)target.setMonth(0,1+((4-nJan1)+7)%7);return zeroPad(1+Math.ceil((n1stThu-target)/604800000),2)})(),'%w':nDay,'%x':date.toLocaleDateString(),'%X':date.toLocaleTimeString(),'%y':(nYear+'').slice(2),'%Y':nYear,'%z':date.toTimeString().replace(/.+GMT([+-]\d+).+/,'$1'),'%Z':date.toTimeString().replace(/.+\((.+?)\)$/,'$1')}[sMatch]||'')+'')||sMatch})}

