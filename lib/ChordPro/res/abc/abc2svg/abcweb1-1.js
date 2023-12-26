//abcweb1-1.js file to include in html pages with abc2svg-1.js
window.onerror=function(msg,url,line){if(typeof msg=='string')
alert("window error: "+msg+"\nURL: "+url+"\nLine: "+line)
else if(typeof msg=='object')
alert("window error: "+msg.type+' '+msg.target.src)
else
alert("window error: "+msg)
return false}
window.onbeforeprint=function(){var e=document.getElementById("dd")
if(e)
e.style.display="none"}
window.onafterprint=function(){var e=document.getElementById("dd")
if(e)
e.style.display="block"}
var user
if(typeof abc2svg=="undefined")
var abc2svg={}
function dom_loaded(){var abc,new_page,playing,abcplay,tune_dur,scroll_to,dt,sY,page,a_inc={},errtxt='',app="abcweb1",playconf={onend:function(){playing=false}},tune_lst,jsdir=document.currentScript?document.currentScript.src.match(/.*\//):(function(){var s_a=document.getElementsByTagName('script')
for(var k=0;k<s_a.length;k++){if(s_a[k].src.indexOf(app)>=0)
return s_a[k].src.match(/.*\//)||''}
return""})()
user={read_file:function(fn){return a_inc[fn]},errmsg:function(msg,l,c){errtxt+=clean_txt(msg)+'\n'},get_abcmodel:function(tsfirst,voice_tb){var d,i,n,pf,s=tsfirst
while(1){if(s.tempo&&!pf){d=0
n=s.tempo_notes.length
for(i=0;i<n;i++)
d+=s.tempo_notes[i]
pf=d*s.tempo/60}
if(!s.ts_next)
break
s=s.ts_next}
if(!pf)
pf=abc2svg.C.BLEN/8
tune_dur=s.time/pf},img_out:function(str){new_page+=str}}
function fix_abc(s){var j,i=s.indexOf('<script')
if(i>=0){i=s.indexOf('type="text/vnd.abc"',i)
if(i>0){i=s.indexOf('\n',i)+1
j=s.indexOf('</script',i)
return s.slice(i,j)}}
return s}
function clean_txt(txt){return txt.replace(/<|>|&.*?;|&/g,function(c){switch(c){case'<':return"&lt;"
case'>':return"&gt;"
case'&':return"&amp;"}
return c})}
function do_scroll(old){var d,ttop
if(!old){d=document.documentElement
dt=tune_dur/d.scrollHeight
ttop=dt*d.clientHeight/4
document.getElementById("ss").style.display="block"
scroll_to=setTimeout(do_scroll,ttop*1000,1)
window.scrollTo(0,8)
sY=0}else{if(sY==window.pageYOffset){document.getElementById("ss").style.display="none"
scroll_to=null
return}
sY=window.pageYOffset
window.scrollTo(0,sY+1)
scroll_to=setTimeout(do_scroll,dt*1000,1)}}
abc2svg.src_upd=function(){page=document.getElementById('ta').value
abc2svg.get_sel()}
abc2svg.src_edit=function(){document.body.innerHTML='\
<textarea id="ta" rows="50" cols="80" style="overflow:scroll">'
+page+'</textarea>\
<br/>\
<a href="#" onclick="abc2svg.src_upd()"> Apply </a> - \
<a href="#" onclick="abc2svg.get_sel()"> Cancel </a>'}
abc2svg.st_scroll=function(){if(scroll_to){clearTimeout(scroll_to)
document.getElementById("ss").style.display="none"
scroll_to=null}else{scroll_to=setTimeout(do_scroll,500,0)}}
abc2svg.loadjs=function(fn,relay,onerror){var s=document.createElement('script')
if(/:\/\//.test(fn))
s.src=fn
else
s.src=jsdir+fn
s.onload=relay
s.onerror=function(){if(onerror)
onerror(fn)
else
alert('error loading '+fn)}
document.head.appendChild(s)}
abc2svg.get_sel=function(){var j,k,n=0,i=0,t=(typeof list_head=="undefined"?"Tunes:":list_head)+'<ul>\n'
tt=typeof list_tail=="undefined"?"(all tunes)":list_tail
for(;;){i=page.indexOf("\nX:",i)
if(i<0)
break
k=page.indexOf("\n",++i)
j=page.indexOf("\nT:",i)
n++
t+='<li \
style="cursor:pointer;color:blue;text-decoration:underline" \
onclick="abc2svg.do_render(\''+page.slice(i,k)+'$\')">'+
page.slice(i+2,k).replace(/%.*/,'')
if(j>0&&j<i+20){k=page.indexOf("\n",j+1)
t+=" "+page.slice(j+3,k).replace(/%.*/,'')
if(page[k+1]=='T'&&page[k+2]==':'){j=k+3
k=page.indexOf("\n",j)
t+=" - "+page.slice(j,k).replace(/%.*/,'')}}
t+='</li>\n'
i=k}
if(n<=1){abc2svg.do_render()
return}
t+='<li \
style="cursor:pointer;color:blue;text-decoration:underline" \
onclick="abc2svg.do_render(\'.*\')">'+tt+'</li>\n\
</ul>'
document.body.innerHTML=t
if(window.location.hash)
window.location.hash=''}
function render(){var select=window.location.hash.slice(1)
var sty=document.createElement('style')
sty.innerHTML='\
.dd{position:fixed;top:0;bottom:0;right:0;height:40px;cursor:pointer;font-size:16px}\
#ss{display:none;background-color:red}\
.db{margin:5px;background-color:yellow}\
.db:hover,.db:focus{background-color:lightgreen}\
.dc{position:absolute;left:-70px;min-width:100px;display:none;background-color:yellow}\
.dc label{display:block;padding:0 5px 0 5px;margin:2px}\
.dc label:hover{outline:solid;outline-width:2px}\
.show{display:block}'
document.head.appendChild(sty)
if(!select)
abc2svg.get_sel()
else
abc2svg.do_render(decodeURIComponent(select))}
abc2svg.do_render=function(select){if(typeof follow=="function")
user.anno_stop=function(){}
tune_lst=[]
abc=new abc2svg.Abc(user)
new_page=""
if(typeof follow=="function")
follow(abc,user,playconf)
if(select){abc.tosvg(app,"%%select "+select)
window.location.hash=encodeURIComponent(select)}
try{abc.tosvg(app,page)}catch(e){alert("abc2svg javascript error: "+e.message+"\nStack:\n"+e.stack)}
abc2svg.abc_end()
if(errtxt){new_page+='<pre class="nop" style="background:#ff8080">'+
errtxt+"</pre>\n"
errtxt=""}
new_page+='\
<div id="dd" class="dd nop">\
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" class="db">\
<path d="M4 6h15v2.5H4zm0 5h15v2.5H4zm0 5h15v2.5H4z" fill="black"/>\
</svg>\
<div id="dc" class="dc">\
<label id="edit" onclick="abc2svg.src_edit()">Source edit</label>\
<label id="list" onclick="abc2svg.get_sel()">Tune list</label>\
<label id="play" onclick="abc2svg.st_scroll()">Scroll</label>\
</div>\
</div>\
<label id="ss" class="dd nop" onclick="abc2svg.st_scroll()">Scroll<br/>stop</label>'
try{document.body.innerHTML=new_page}catch(e){alert("abc2svg bad generated SVG: "+e.message+"\nStack:\n"+e.stack)
return}
var elts=document.getElementsByTagName('svg')
for(var i=0;i<elts.length;i++)
elts[i].addEventListener('click',click)
setTimeout(function(){if(typeof AbcPlay!="undefined"||document.documentElement.scrollHeight<=window.innerHeight)
document.getElementById("play").style.display="none"},500)}
function include(){var i,j,fn,r,k=0
while(1){i=page.indexOf('%%abc-include ',k)
if(i<0){render()
return}
i+=14
j=page.indexOf('\n',i)
fn=page.slice(i,j).trim()
if(!a_inc[fn])
break
k=j}
r=new XMLHttpRequest()
r.open('GET',fn,true)
r.onload=function(){if(r.status===200){a_inc[fn]=r.responseText
if(abc2svg.modules.load(a_inc[fn],include))
include()}else{a_inc[fn]='%\n'
alert('Error getting '+fn+'\n'+r.statusText)
include()}}
r.onerror=function(){a_inc[fn]='%\n'
alert('Error getting '+fn+'\n'+r.statusText)
include()}
r.send()}
if(!abc2svg.Abc){abc2svg.loadjs("abc2svg-1.js",dom_loaded)
return}
page=fix_abc(document.body.innerHTML)
function click(evt){if(playing){abcplay.stop()
return}
var e,s,j,c=evt.target
e=document.getElementById("dc")
if(e&&e.classList.contains("show")){e.classList.remove("show")
return}
e=c
while(1){if(c==document)
return
if(c.tagName.toLowerCase()=='svg')
break
c=c.parentNode}
c=c.getAttribute('class')
if(!c)
return
if(c=="db"){e=document.getElementById("dc")
e.classList.toggle("show")
return}
if(!abcplay){if(typeof AbcPlay=="undefined")
return
if(abc.cfmt().soundfont)
playconf.sfu=abc.cfmt().soundfont
abcplay=AbcPlay(playconf)}
c=c.match(/tune(\d+)/)
if(!c)
return
c=c[1]
if(!tune_lst[c]){tune_lst[c]=abc.tunes[c]
abcplay.add(tune_lst[c][0],tune_lst[c][1],tune_lst[c][3])}
s=tune_lst[c][0]
c=e.getAttribute('class')
if(c)
c=c.match(/abcr _(\d+)_/)
if(c){c=c[1]
while(s&&s.istart!=c)
s=s.ts_next
if(!s){alert("play bug: no such symbol in the tune")
return}}
playing=true
abcplay.play(s,null)}
abc2svg.abc_end=function(){}
if(abc2svg.modules.load(page,include))
include()}
window.addEventListener("load",dom_loaded)
