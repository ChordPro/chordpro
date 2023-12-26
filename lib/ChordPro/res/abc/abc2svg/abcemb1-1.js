// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2019 Jean-Francois Moine - LGPL3+
//#javascript
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
function dom_loaded(){var errtxt='',app="abcemb",new_page,playing,abcplay,tune_dur,scroll_to,dt,sY,page,pe,jsdir=document.currentScript?document.currentScript.src.match(/.*\//):(function(){var s_a=document.getElementsByTagName('script')
for(var k=0;k<s_a.length;k++){if(s_a[k].src.indexOf('abcemb1-')>=0)
return s_a[k].src.match(/.*\//)||''}
return""})(),playconf={onend:function(){playing=false}}
user={errmsg:function(msg,l,c){errtxt+=clean_txt(msg)+'\n'},get_abcmodel:function(tsfirst,voice_tb){var d,i,n,pf,s=tsfirst
while(1){if(s.tempo&&!pf){d=0;n=s.tempo_notes.length
for(i=0;i<n;i++)
d+=s.tempo_notes[i];pf=d*s.tempo/60}
if(!s.ts_next)
break
s=s.ts_next}
if(!pf)
pf=abc2svg.C.BLEN/8;tune_dur=s.time/pf},img_out:function(str){new_page+=str},page_format:true}
function clean_txt(txt){return txt.replace(/<|>|&.*?;|&/g,function(c){switch(c){case'<':return"&lt;"
case'>':return"&gt;"
case'&':return"&amp;"}
return c})}
function do_scroll(old){if(!old){var d=document.documentElement;dt=tune_dur/d.scrollHeight
var ttop=dt*d.clientHeight/4
document.getElementById("ss").style.display="block"
scroll_to=setTimeout(do_scroll,ttop*1000,1)
window.scrollTo(0,8);sY=0}else{if(sY==window.pageYOffset){document.getElementById("ss").style.display="none"
scroll_to=null
return}
sY=window.pageYOffset;window.scrollTo(0,sY+1);scroll_to=setTimeout(do_scroll,dt*1000,1)}}
window.onmouseup=function(event){var e=document.getElementById("dc")
if(e){if(event.target.className=="db")
e.classList.toggle("show")
else if(e.classList.contains("show"))
e.classList.remove("show")}}
abc2svg.src_upd=function(){page=document.getElementById('ta').value
abc2svg.get_sel()}
abc2svg.src_edit=function(){document.body.innerHTML='\
<textarea id="ta" rows="50" cols="80">'+page+'</textarea>\
<br/>\
<a href="#" onclick="abc2svg.src_upd()"> Apply </a> - \
<a href="#" onclick="abc2svg.get_sel()"> Cancel </a>'}
abc2svg.st_scroll=function(){if(scroll_to){clearTimeout(scroll_to);document.getElementById("ss").style.display="none"
scroll_to=null}else{scroll_to=setTimeout(do_scroll,500,0)}}
abc2svg.playseq=function(select){var outputs
if(!abcplay){delete user.img_out;user.get_abcmodel=function(tsfirst,voice_tb){abcplay.add(tsfirst,voice_tb)}
abcplay=AbcPlay(playconf)}
if(playing){if(scroll_to){clearTimeout(scroll_to);scroll_to=null}
abcplay.stop();return}
playing=true
if(!pe){var abc=new abc2svg.Abc(user);abcplay.clear();abc.tosvg("play","%%play")
if(select)
abc.tosvg(app,"%%select "+select)
try{abc.tosvg(app,page)}catch(e){alert(e.message+'\nabc2svg tosvg bug - stack:\n'+e.stack);playing=false;pe=null
return}
pe=abcplay.clear()}
if(document.documentElement.scrollHeight>window.innerHeight)
scroll_to=setTimeout(do_scroll,500,0);abcplay.play(0,100000,pe)}
abc2svg.loadjs=function(fn,relay,onerror){var s=document.createElement('script');if(/:\/\//.test(fn))
s.src=fn
else
s.src=jsdir+fn;s.type='text/javascript'
if(relay)
s.onload=relay;s.onerror=onerror||function(){alert('error loading '+fn)}
document.head.appendChild(s)}
abc2svg.get_sel=function(){var j,k,n=0,i=0,t=(typeof list_head=="undefined"?"Tunes:":list_head)+'<ul>\n'
for(;;){i=page.indexOf("\nX:",i)
if(i<0)
break
j=page.indexOf("\nT:",++i)
if(j<0)
break
n++;t+='<li><a \
style="cursor:pointer;color:blue;text-decoration:underline" \
onclick="abc2svg.do_render(\''+page.slice(i,j)+'\')">'
k=page.indexOf("\n",j+1);t+=page.slice(j+3,k)
if(page[k+1]=='T'&&page[k+2]==':'){j=k+3;k=page.indexOf("\n",j)
if(k>0)
t+=" - "+page.slice(j,k)}
t+='</a></li>\n';i=k}
if(n<=1){abc2svg.do_render()
return}
t+='</ul>';document.body.innerHTML=t}
function render(){var select=window.location.hash.slice(1)
var sty=document.createElement('style')
sty.innerHTML='\
.dd{position:fixed;top:0;bottom:0;right:0;height:40px;cursor:pointer;font-size:16px}\
#ss{display:none;background-color:red}\
.db{display:block;margin:5px; padding:5px;background-color:yellow}\
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
user.anno_stop=function(){};abc=new abc2svg.Abc(user)
new_page=""
if(typeof follow=="function")
follow(abc,user,playconf)
if(select){if(typeof AbcPlay!="undefined")
new_page+='<div onclick="abc2svg.playseq(\''+
select+'\')">'
abc.tosvg(app,"%%select "+select)}else if(typeof AbcPlay!="undefined"){new_page+='<div onclick="abc2svg.playseq()">'}
try{abc.tosvg(app,page)}catch(e){alert("abc2svg javascript error: "+e.message+"\nStack:\n"+e.stack)}
if(typeof AbcPlay!="undefined")
new_page+='</div>'
if(errtxt){new_page+='<pre style="background:#ff8080">'+
errtxt+"</pre>\n";errtxt=""}
new_page+='\
<div id="dd" class="dd">\
<label class="db">|||</label>\
<div id="dc" class="dc">\
<label id="edit" onclick="abc2svg.src_edit()">Source edit</label>\
<label id="list" onclick="abc2svg.get_sel()">Tune list</label>\
<label id="play" onclick="abc2svg.st_scroll()">Scroll</label>\
</div>\
</div>\
<label id="ss" class="dd" onclick="abc2svg.st_scroll()">Scroll<br/>stop</label>'
try{document.body.innerHTML=new_page}catch(e){alert("abc2svg bad generated SVG: "+e.message+"\nStack:\n"+e.stack)
return}
setTimeout(function(){if(typeof AbcPlay!="undefined"||document.documentElement.scrollHeight<=window.innerHeight)
document.getElementById("play").style.display="none"},500)}
if(!abc2svg.Abc){abc2svg.loadjs("abc2svg-1.js",dom_loaded)
return}
page=document.body.innerHTML;abc2svg.abc_end=function(){}
if(abc2svg.modules.load(page,render))
render()}
window.addEventListener("load",function(){setTimeout(dom_loaded,500)})
