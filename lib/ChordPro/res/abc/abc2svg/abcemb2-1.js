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
var errtxt='',elts,tunes='',indx=[],select,playing,abcplay,playconf={onend:endplay},a_pe=[],glop,old_gm,jsdir=document.currentScript?document.currentScript.src.match(/.*\//):(function(){var s_a=document.getElementsByTagName('script')
for(var k=0;k<s_a.length;k++){if(s_a[k].src.indexOf('abcemb2-')>=0)
return s_a[k].src.match(/.*\//)||''}
return""})(),user={errmsg:function(msg,l,c){errtxt+=clean_txt(msg)+'\n'},img_out:function(str){new_page+=str},page_format:true}
function clean_txt(txt){return txt.replace(/<|>|&.*?;|&/g,function(c){switch(c){case'<':return"&lt;"
case'>':return"&gt;"
case'&':return"&amp;"}
return c})}
function endplay(){playing=false}
function playseq(i){var outputs
if(!abcplay){if(typeof AbcPlay=="undefined"){playseq=function(){}
return}
abcplay=AbcPlay(playconf)}
if(playing){abcplay.stop()
return}
playing=true
if(!a_pe[i]){abc=new abc2svg.Abc(user);abcplay.clear();abc.tosvg("play","%%play")
if(select)
abc.tosvg('abcemb2',select)
try{if(glop!=undefined)
abc.tosvg("abcemb2",tunes,indx[glop],indx[glop+1]);abc.tosvg("abcemb2-"+i,tunes,indx[i],indx[i+1])}catch(e){alert(e.message+'\nabc2svg tosvg bug - stack:\n'+e.stack);playing=false;a_pe[seq]=null
return}
a_pe[i]=abcplay.clear()}
abcplay.play(0,100000,a_pe[i])}
function dom_loaded(){function toabc(s){return s.replace(/&gt;/g,'>').replace(/&lt;/g,'<').replace(/&amp;/g,'&').replace(/[ \t]+(%%)/g,'$1').replace(/[ \t]+(.:)/g,'$1')}
abc2svg.loadjs=function(fn,relay,onerror){var s=document.createElement('script');if(/:\/\//.test(fn))
s.src=fn
else
s.src=jsdir+fn;s.type='text/javascript'
if(relay)
s.onload=relay;s.onerror=onerror||function(){alert('error loading '+fn)}
document.head.appendChild(s)}
elts=document.getElementsByClassName('abc')
for(var i=0;i<elts.length;i++){var elt=elts[i];indx[i]=tunes.length;tunes+=toabc(elt.innerHTML)+'\n'}
indx[i]=tunes.length;ready()}
function ready(){var i,j,abc
if(!abc2svg.modules.load(tunes,ready))
return
abc2svg.abc_end=function(){}
var sel=window.location.hash.slice(1)
if(sel)
select='%%select '+decodeURIComponent(sel);if(typeof follow=="function")
user.anno_stop=function(){};abc=new abc2svg.Abc(user)
if(typeof follow=="function")
follow(abc,user,playconf)
for(i=0;i<elts.length;i++){new_page=""
j=tunes.indexOf('X:',indx[i])
if(j>=0&&j<indx[i+1])
new_page+='<div onclick="playseq('+i+')">\n'
else if(glop==undefined)
glop=i
if(sel){abc.tosvg('abcemb2',select);sel=''}
try{abc.tosvg('abcemb2',tunes,indx[i],indx[i+1])}catch(e){alert("abc2svg javascript error: "+e.message+"\nStack:\n"+e.stack)}
if(errtxt){new_page+='<pre style="background:#ff8080">'+
errtxt+"</pre>\n";errtxt=""}
try{elts[i].innerHTML=new_page}catch(e){alert("abc2svg bad generated SVG: "+e.message+"\nStack:\n"+e.stack)}
if(j>=0&&j<indx[i+1])
new_page+='</div>\n'
abc2svg.abc_end()}
delete user.img_out;old_gm=user.get_abcmodel;user.get_abcmodel=function(tsfirst,voice_tb,music_types,info){if(old_gm)
old_gm(tsfirst,voice_tb,music_types,info);abcplay.add(tsfirst,voice_tb)}}
window.addEventListener("load",function(){setTimeout(dom_loaded,500)})
