//abc2svg-jazzchord.js-Adds jazz chord styling to chord symbols
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.jazzchord={defrep:{"-":"–","°":"o","º":"o","ᵒ":"o","0":"ø","^":"∆"},gch_build:function(of,s){var gch,ix,r,t,fmt=s.fmt
if(!fmt.jazzchord){of(s)
return}
function jzch(t){var r='',a=t.match(/(\[?[A-G])([#♯b♭]?)([^/]*)\/?(.*)\)?/)
if(!a)
return t
if(a[2])
r="$7"+a[2]
if(a[3][0]=='m'&&a[3].slice(0,3)!="maj"){if(!r)
r+="$7"
if(a[3].slice(0,3)=="min"){r+=a[3].slice(0,3)
a[3]=a[3].slice(3)}else{r+='m'
a[3]=a[3].slice(1)}}
if(a[3])
r+=(r?"$0":'')+"$8"+a[3]
if(a[4])
r+=(r?"$0":'')+"$9/"+a[4]
if(!r)
return t
return a[1]+r+"$0"}
for(ix=0;ix<s.a_gch.length;ix++){gch=s.a_gch[ix]
t=gch.text
if(gch.type!='g'||t.indexOf('$')>=0)
continue
switch(t){case"/":gch.text="\ue101";continue
case"%":gch.text="\ue500";continue
case"%%":gch.text="\ue501";continue}
if(fmt.jzreg){t=t.replace(fmt.jzRE,function(x){return fmt.jzrep[x]})}
if(fmt.jazzchord==1){if(t[0]=='(')
t=t.slice(1,-1)
t=t.split('(')
r=jzch(t[0])
if(t.length>1)
r+='('+jzch(t[1])}else{r=t}
if(gch.text[0]=='(')
gch.text='('+r+')'
else
gch.text=r}
of(s)},set_fmt:function(of,cmd,parm){var i,k,s,cfmt=this.cfmt()
if(cmd=="jazzchord"){cfmt.jazzchord=this.get_bool(parm)
if(!cfmt.jazzchord)
return
if(parm[0]=='2')
cfmt.jazzchord=2
if(!cfmt.jzreg){cfmt.jzreg="-|°|º|ᵒ|0|\\^"
cfmt.jzrep=Object.create(abc2svg.jazzchord.defrep)
cfmt.jzRE=new RegExp(cfmt.jzreg,'g')}
if(parm&&parm.indexOf('=')>0){parm=parm.split(/[\s]+/)
for(cmd=0;cmd<parm.length;cmd++){k=parm[cmd].split('=')
if(k.length!=2)
continue
s=k[1]
k=k[0]
i=cfmt.jzreg.indexOf(k)
if(i>=0){if(s){cfmt.jzrep[k]=s}else{cfmt.jzreg=cfmt.jzreg.replace(k,'')
cfmt.jzreg=cfmt.jzreg.replace('||','|')
delete cfmt.jzrep[k]}}else{cfmt.jzreg+='|'+k
cfmt.jzrep[k]=s}
cfmt.jzRE=new RegExp(cfmt.jzreg,'g')}}
return}
of(cmd,parm)},set_hooks:function(abc){abc.gch_build=abc2svg.jazzchord.gch_build.bind(abc,abc.gch_build)
abc.set_format=abc2svg.jazzchord.set_fmt.bind(abc,abc.set_format)
abc.add_style("\
\n.jc7{font-size:90%}\
\n.jc8{baseline-shift:25%;font-size:75%;letter-spacing:-0.05em}\
\n.jc9{font-size:75%;letter-spacing:-0.05em}\
")
abc.param_set_font("setfont-7","* * class=jc7")
abc.param_set_font("setfont-8","* * class=jc8")
abc.param_set_font("setfont-9","* * class=jc9")}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.jazzchord=abc2svg.jazzchord.set_hooks
