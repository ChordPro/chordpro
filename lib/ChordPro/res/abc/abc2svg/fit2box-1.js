//fit2box.js-module for filling a tune in a box
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.fit2box={do_fit:function(mus){var r,sv,v,w,h,hh,sc,marg,tit,cl,parse=mus.get_parse(),f=parse.file,fn=parse.fname,cfmt=mus.cfmt(),wb=cfmt.fit2box[0],hb=cfmt.fit2box[1],user=mus.get_user(),io=user.img_out,ob=""
user.img_out=function(p){ob+=p}
function getparm(parm){var j,v,i=f.indexOf("%%"+parm)
if(i>=0&&(!i||f[i-1]=='\n')){j=f.indexOf('\n',i)
v=f.slice(i,j).split(/\s+/)
v=mus.get_unit(v[1])}else{v=cfmt[parm]}
return v}
function setparm(parm,v){var i,j,p="%%"+parm
i=f.indexOf(p)
if(i>=0&&(!i||f[i-1]=='\n')){j=f.indexOf('\n',i)
f=f.replace(f.slice(i,j),p+' '+v)}else{f=p+' '+v+'\n'+f}}
if(wb=="*")
wb=getparm("pagewidth")
if(hb=="*")
hb=getparm("pageheight")
if(!hb)
hb=1123
setparm("stretchlast","0")
setparm("stretchstaff","0")
marg=getparm("leftmargin")
setparm("leftmargin","0")
setparm("rightmargin","0")
setparm("pagewidth",(wb*2).toFixed(2))
if(f.indexOf("\n%%pagescale ")>=0)
f=f.replace(/(\n%%pagescale).*/,"$1 1")
else
f=f.replace(/(\nK:.*)/,"$1\n%%pagescale 1")
cfmt.trimsvg=1
cfmt.fullsvg="a"
if(abc2svg.fit2box.otosvg)
abc2svg.fit2box.otosvg(fn,f)
else
mus.tosvg(fn,f)
cfmt=mus.cfmt()
w=h=hh=0
r=ob.match(/<svg[^>]*/g)
if(!r){user.img_out=io
return}
while(1){sv=r.shift()
if(!sv)
break
v=sv.match(/viewBox="0 0 ([\d.]+) ([\d.]+)"/)
cl=sv.match(/class="([^"]+)"/)
if(!tit||cl[1]=="header"||cl[1]=="footer"){hh+=+v[2]
if(cl[1]!="header"&&cl[1]!="footer")
tit=1
continue}
if(+v[1]>w)
w=+v[1]
h+=+v[2]}
sc=(hb-hh)/h
w+=24
v=(wb-marg*2)/w
if(v<=sc){sc=v}else{v=Math.round((wb-w*sc)/2)
if(v<marg)
marg=v}
setparm("pagewidth",wb)
setparm("leftmargin",marg.toFixed(0))
setparm("rightmargin",marg.toFixed(0))
setparm("pagescale",sc)
setparm("stretchstaff",1)
setparm("stretchlast",1)
cfmt.fullsvg=""
cfmt.trimsvg=0
mus.tunes.shift()
user.img_out=io
if(abc2svg.fit2box.otosvg){mus.tosvg=abc2svg.fit2box.otosvg
abc2svg.fit2box.otosvg=null}
mus.tosvg(fn,f)
abc2svg.fit2box.on=0},tosvg:function(of,fn,file,bol,eof){var parse=this.get_parse()
parse.fname=fn
parse.file=bol?file.slice(bol):file
parse.eol=0
abc2svg.fit2box.on=1
abc2svg.fit2box.do_fit(this)},set_fmt:function(of,cmd,parm){if(cmd!="fit2box")
return of(cmd,parm)
if(abc2svg.fit2box.on)
return
abc2svg.fit2box.on=1
if(!parm){if(abc2svg.fit2box.otosvg){this.tosvg=abc2svg.fit2box.otosvg
abc2svg.fit2box.otosvg=null}
return}
var cfmt=this.cfmt(),parse=this.get_parse(),f=parse.file
cfmt.fit2box=parm.split(/\s+/)
if(f.indexOf("X:")<0){if(!abc2svg.fit2box.otosvg){abc2svg.fit2box.otosvg=this.tosvg
this.tosvg=abc2svg.fit2box.tosvg.bind(this,this.tosvg)}
return}
parse.file=parse.file.slice(parse.eol)
parse.eol=0
abc2svg.fit2box.do_fit(this)
parse.file=f
parse.eol=parse.file.length-2},set_hooks:function(abc){abc.set_format=abc2svg.fit2box.set_fmt.bind(abc,abc.set_format)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.fit2box=abc2svg.fit2box.set_hooks

