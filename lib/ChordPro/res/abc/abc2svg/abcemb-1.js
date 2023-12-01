// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2020 Jean-Francois Moine - LGPL3+
//#javascript
window.onerror=function(msg,url,line){if(typeof msg=='string')
alert("window error: "+msg+"\nURL: "+url+"\nLine: "+line)
else if(typeof msg=='object')
alert("window error: "+msg.type+' '+msg.target.src)
else
alert("window error: "+msg)
return false}
var user
if(typeof abc2svg=="undefined")
var abc2svg={}
function dom_loaded(){var errtxt='',new_page='',playing,abcplay,page,a_src=[],a_pe=[],glop,old_gm,jsdir=document.currentScript?document.currentScript.src.match(/.*\//):(function(){var s_a=document.getElementsByTagName('script')
for(var k=0;k<s_a.length;k++){if(s_a[k].src.indexOf('abcemb-')>=0)
return s_a[k].src.match(/.*\//)||''}
return""})(),playconf={onend:function(){playing=false}}
user={errmsg:function(msg,l,c){errtxt+=clean_txt(msg)+'\n'},img_out:function(str){new_page+=str},page_format:true}
function clean_txt(txt){return txt.replace(/<|>|&.*?;|&/g,function(c){switch(c){case'<':return"&lt;"
case'>':return"&gt;"
case'&':return"&amp;"}
return c})}
function endplay(){playing=false}
abc2svg.playseq=function(seq){var outputs
if(!abcplay){if(typeof AbcPlay=="undefined"){abc2svg.playseq=function(){}
return}
abcplay=AbcPlay(playconf)}
if(playing){abcplay.stop();return}
playing=true
if(!a_pe[seq]){var abc=new abc2svg.Abc(user);abcplay.clear();abc.tosvg("play","%%play")
try{if(glop)
abc.tosvg("abcemb",page,glop[0],glop[1]);abc.tosvg("abcemb"+seq,page,a_src[seq][0],a_src[seq][1])}catch(e){alert(e.message+'\nabc2svg tosvg bug - stack:\n'+e.stack);playing=false;a_pe[seq]=null
return}
a_pe[seq]=abcplay.clear()}
abcplay.play(0,100000,a_pe[seq])}
abc2svg.loadjs=function(fn,relay,onerror){var s=document.createElement('script');if(/:\/\//.test(fn))
s.src=fn
else
s.src=jsdir+fn;s.type='text/javascript'
if(relay)
s.onload=relay;s.onerror=onerror||function(){alert('error loading '+fn)}
document.head.appendChild(s)}
function render(){var i=0,j,k,res,abc,seq=0,re=/\n%abc|\nX:/g,re_stop=/\nX:|\n<|\n%.begin/g,select=window.location.hash.slice(1);if(typeof follow=="function")
user.anno_stop=function(){};abc=new abc2svg.Abc(user)
j=page.indexOf("<mei ")
if(j>=0){k=page.indexOf("</mei>")+6
abc.mei2mus(page.slice(j,k))
document.body.innerHTML=new_page
return}
if(typeof follow=="function")
follow(abc,user,playconf)
if(select){select=decodeURIComponent(select);select=page.search(select)
if(select<0)
select=0}
for(;;){res=re.exec(page)
if(!res)
break
j=re.lastIndex-res[0].length;new_page+=page.slice(i,j);re_stop.lastIndex=++j
while(1){res=re_stop.exec(page)
if(!res||res[0][1]!="%")
break
k=page.indexOf(res[0].replace("begin","end"),re_stop.lastIndex)
if(k<0)
break
re_stop.lastIndex=k}
if(!res||k<0)
k=page.length
else
k=re_stop.lastIndex-2;if(!select||page[j]!='X'||(select>=j&&select<k)){if(page[j]=='X'){new_page+='<div onclick="abc2svg.playseq('+
a_src.length+')">\n';a_src.push([j,k])}else if(!glop){glop=[j,k]}
try{abc.tosvg('abcemb',page,j,k)}catch(e){alert("abc2svg javascript error: "+e.message+"\nStack:\n"+e.stack)}
if(errtxt){new_page+='<pre style="background:#ff8080">'+
errtxt+"</pre>\n";errtxt=""}
abc2svg.abc_end()
if(page[j]=='X')
new_page+='</div>\n'}
i=k
if(i>=page.length)
break
if(page[i]=='X')
i--
re.lastIndex=i}
try{document.body.innerHTML=new_page+page.slice(i)}catch(e){alert("abc2svg bad generated SVG: "+e.message+"\nStack:\n"+e.stack)}
delete user.img_out;old_gm=user.get_abcmodel;user.get_abcmodel=function(tsfirst,voice_tb,music_types,info){if(old_gm)
old_gm(tsfirst,voice_tb,music_types,info);abcplay.add(tsfirst,voice_tb)}}
page=document.body.innerHTML
if(!abc2svg.Abc){abc2svg.loadjs(page.indexOf("<mei ")>=0?"mei2svg-1.js":"abc2svg-1.js",dom_loaded)
return}
abc2svg.abc_end=function(){}
if(abc2svg.modules.load(page,render))
render()}
window.addEventListener("load",function(){setTimeout(dom_loaded,500)})
