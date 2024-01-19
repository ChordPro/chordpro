//edit.js-file used in the abc2svg editor
window.onerror=function(msg,url,line){if(typeof msg=='string')
alert("window error: "+msg+"\nURL: "+url+"\nLine: "+line)
else if(typeof msg=='object')
alert("window error: "+msg.type+' '+msg.target.src)
else
alert("window error: "+msg)
return false}
window.onbeforeunload=function(){if(chg)
return""}
var abc_images,abc_fname=["noname.abc",""],abc_mtime=[],abc,syms,ctxMenu,elt_ref={},selx=[0,0],selx_sav=[],play={},pop,texts={},chg=0,jsdir=document.currentScript?document.currentScript.src.match(/.*\//):(function(){var s_a=document.getElementsByTagName('script')
for(var k=0;k<s_a.length;k++){if(s_a[k].src.indexOf('edit-')>=0)
return s_a[k].src.match(/.*\//)||''}
return""})()
var user={read_file:function(fn){elt_ref["s"+srcidx].style.display="inline"
return elt_ref.src1.value},errbld:function(sev,txt,fn,idx){var msg=sev+' '+clean_txt(txt)
if(idx>=0)
elt_ref.diverr.innerHTML+='<b onclick="gotoabc(-1,'+idx+')" style="cursor: pointer; display: inline-block">'+
msg+"</b><br/>\n"
else
elt_ref.diverr.innerHTML+=msg+"<br/>\n"},img_out:function(str){abc_images+=str},anno_stop:function(type,start,stop,x,y,w,h,s){if(["beam","slur","tuplet"].indexOf(type)>=0)
return
syms[start]=s
abc.out_svg('<rect class="abcr _'+start+'_" x="');abc.out_sxsy(x,'" y="',y);abc.out_svg('" width="'+w.toFixed(2)+'" height="'+abc.sh(h).toFixed(2)+'"/>\n')},page_format:true},srcidx=0
function storage(t,k,v){try{t=t?localStorage:sessionStorage
if(!t)
return
if(v)
t.setItem(k,v)
else if(v===0)
t.removeItem(k)
else
return t.getItem(k)}catch(e){}}
function clean_txt(txt){return txt.replace(/<|>|&.*?;|&/g,function(c){switch(c){case'<':return"&lt;"
case'>':return"&gt;"
case'&':return"&amp;"}
return c})}
function loadlang(lang,no_memo){abc2svg.loadjs('edit-'+lang+'.js',function(){loadtxt()});abc2svg.loadjs('err-'+lang+'.js')
if(!no_memo)
storage(true,"lang",lang=="en"?0:lang)}
function popshow(area,visible){var e=document.getElementById(area)
if(pop){if(pop==e)
visible=false
else
pop.style.visibility='hidden'}
e.style.visibility=visible?'visible':'hidden';pop=visible?e:null}
function loadtune(){var files=document.getElementById("abcfile").files
abc_fname[srcidx]=files[0].name
var reader=new FileReader();reader.onloadend=function(evt){var s=srcidx==0?"source":"src1";elt_ref[s].value=evt.target.result;elt_ref["s"+srcidx].value=abc_fname[srcidx];chg=-1
src_change()}
reader.readAsText(files[0],"UTF-8")}
function selsrc(idx){if(idx==srcidx)
return
var o=srcidx?"src"+srcidx:"source",n=idx?"src"+idx:"source";elt_ref[o].style.display="none";elt_ref[n].style.display="inline";elt_ref["s"+srcidx].style.backgroundColor="#ffd0d0";elt_ref["s"+idx].style.backgroundColor="#80ff80";srcidx=idx}
function render(){var i,j,content=elt_ref.source.value;if(!content)
return
i=content.indexOf('%%abc-include ')
if(i>=0){var sl=elt_ref.s1
if(!sl.value){sl.style.display="inline";j=content.indexOf('\n',i);sl.value=content.slice(i+14,j);selsrc(1);alert(texts.load+sl.value)
return}}
elt_ref.diverr.innerHTML='';selx[0]=selx[1]=0;chg++
render2()}
function render2(){var content=elt_ref.source.value,def=(abc2svg.a_inc&&abc2svg.a_inc["default.abc"])||''
if(!abc2svg.modules.load(content+elt_ref.src1.value+def,render2))
return
if(abc2svg.modules.pageheight.loaded){abc2svg.get_mtime=function(fn){var files=document.getElementById("abcfile").files
if(files&&files[0].lastModified)
return new Date(files[0].lastModified)
return new Date()}}
abc=new abc2svg.Abc(user);abc_images='';syms=[]
if(abc2svg.a_inc&&abc2svg.a_inc["default.abc"]){try{abc.tosvg("default.abc",abc2svg.a_inc["default.abc"])}catch(e){alert(e.message+'\nabc2svg tosvg bug - stack:\n'+e.stack)
return}}
try{abc.tosvg(abc_fname[0],content)}catch(e){alert(e.message+'\nabc2svg tosvg bug - stack:\n'+e.stack)
return}
abc2svg.abc_end()
try{elt_ref.target.innerHTML=abc_images}catch(e){alert(e.message+'\nabc2svg image bug - abort')
return}
document.getElementById("er").style.display=elt_ref.diverr.innerHTML?'inline':'none'}
function soffs(r,c){var m,s=elt_ref.source,o=0
while(--r>=0){o=s.value.indexOf('\n',o)+1
if(o<=0)
return s.value.length-1}
m=s.value.indexOf('\n',o)
o+=c
if(o>m)
o=m
return o}
function gotoabc(l,c){var s=elt_ref.source
selsrc(0)
if(l>=0)
c=soffs(l,Number(c))
s.blur()
s.setSelectionRange(c,c)
s.focus()
s.setSelectionRange(c,syms[c]?syms[c].iend:c+1)}
function selsvg(evt){var v,cl=evt.target.getAttribute('class')
play.loop=false;if(ctxMenu&&ctxMenu.style.display=="block"){ctxMenu.style.display="none"
return}
if(play.playing&&!play.stop){play.stop=-1;play.abcplay.stop()
return}
s=elt_ref.source;s.blur();v=cl&&cl.substr(0,4)=='abcr'?Number(cl.slice(6,-1)):0
s.setSelectionRange(v,v)
s.focus()
if(v)
s.setSelectionRange(v,syms[v].iend)}
function setsel(idx,v){var i,elts,s,old_v=selx[idx];if(v==old_v)
return
if(old_v){elts=document.getElementsByClassName('_'+old_v+'_');i=elts.length
while(--i>=0)
elts[i].style.fillOpacity=0}
if(v){elts=document.getElementsByClassName('_'+v+'_');i=elts.length
while(--i>=0)
elts[i].style.fillOpacity=0.4}
selx[idx]=v}
function do_scroll(elt){var x=0,y=0,b=elt.getBoundingClientRect(),d=elt_ref.target.parentElement,r=elt.parentNode.getBoundingClientRect()
if(b.x<d.offsetLeft||b.x+b.width>d.offsetLeft+d.clientWidth*.7)
x=b.x-d.offsetLeft-d.clientWidth*.3
if(r.y<d.offsetTop||r.y+r.height>d.offsetTop+d.clientHeight*.7)
y=r.y-d.offsetTop-d.clientHeight*.3
if(x||y)
d.scrollBy({top:y,left:x,behavior:(x<0||y)?'instant':'smooth'})}
function seltxt(evt){var s,elts,e=0,elt=elt_ref.source,start=elt.selectionStart,end=elt.selectionEnd
play.loop=false
if(!start){if(end==elt.value.length)
return
setsel(0,0);setsel(1,0)
return}
if(syms){syms.forEach(function(sym,is){if(!s){if(is>=start)
s=is}else if(sym.iend<=end){e=is}})}
if(!s)
return
if(selx[0]!=s)
setsel(0,s)
if(selx[1]!=e)
setsel(1,e);elts=document.getElementsByClassName('_'+s+'_')
if(elts[0])
do_scroll(elts[0])}
function saveas(){var s=srcidx==0?"source":"src1",source=elt_ref[s].value,link=document.createElement("a");if(abc_fname[srcidx]=="noname.abc")
elt_ref["s"+srcidx].value=abc_fname[srcidx]=prompt(texts.fn,abc_fname[srcidx])
link.download=abc_fname[srcidx];link.href="data:text/plain;charset=utf-8,"+
encodeURIComponent(source);link.onclick=destroyClickedElement;link.style.display="none";document.body.appendChild(link);link.click()
chg=0}
function destroyClickedElement(evt){document.body.removeChild(evt.target)}
function setfont(){var fs=document.getElementById("fontsize").value.toString();elt_ref.source.style.fontSize=elt_ref.src1.style.fontSize=fs+"px";storage(true,"fontsz",fs=="14"?0:fs)}
function set_sfu(v){play.abcplay.set_sfu(v)
storage(true,"sfu",v=="Scc1t2"?0:v)}
function set_speed(iv){var spvl=document.getElementById("spvl"),v=Math.pow(3,(iv-10)*.1);play.abcplay.set_speed(v);spvl.innerHTML=v}
function set_vol(v){var gvl=document.getElementById("gvl");gvl.innerHTML=v.toFixed(2);play.abcplay.set_vol(v)
storage(true,"volume",v==0.7?0:v.toFixed(2))}
function notehlight(i,on){if(play.stop){if(on)
return
if(play.stop<0)
play.stop=i
if(i==selx[1])
return}
var elts=document.getElementsByClassName('_'+i+'_');if(elts&&elts[0]){if(on)
do_scroll(elts[0]);elts[0].style.fillOpacity=on?0.4:0}}
function endplay(repv){if(play.loop){play.abcplay.play(play.si,play.ei)
return}
play.playing=false;play.repv=repv
selx[0]=selx[1]=0;setsel(0,selx_sav[0]);setsel(1,selx_sav[1])}
function play_tune(what){if(!abc)
return
var i,si,ei,elt,C=abc2svg.C,tunes=abc.tunes
if(play.playing){if(!play.stop){play.stop=-1;play.abcplay.stop()}
return}
function gnrn(sym,loop){var i
while(1){switch(sym.type){case C.NOTE:i=sym.nhd+1
while(--i>=0){if(sym.notes[i].ti2)
break}
if(i<0)
return sym
break
case C.REST:case C.GRACE:return sym
case C.BLOCK:switch(sym.subtype){case"midictl":case"midiprog":return sym}
break}
if(!sym.ts_next){if(!loop)
return gprn(sym,1)
return sym}
sym=sym.ts_next}}
function gprn(sym,loop){var i
while(1){switch(sym.type){case C.NOTE:i=sym.nhd+1
while(--i>=0){if(sym.notes[i].ti2)
break}
if(i<0)
return sym
break
case C.REST:case C.GRACE:return sym
case C.BLOCK:switch(sym.subtype){case"midictl":case"midiprog":return sym}
break}
if(!sym.ts_prev){if(!loop)
return gnrn(sym,1)
return sym}
sym=sym.ts_prev}}
function gsot(si){var sym=syms[si].p_v.sym
while(!sym.seqst)
sym=sym.ts_prev
return sym}
function get_se(si){var sym=syms[si]
while(!sym.seqst)
sym=sym.ts_prev
return sym}
function get_ee(si){var sym=syms[si]
while(sym.ts_next&&!sym.ts_next.seqst)
sym=sym.ts_next
return sym}
function play_start(si,ei){if(!si)
return
selx_sav[0]=selx[0];selx_sav[1]=selx[1];setsel(0,0);setsel(1,0);play.stop=0;play.abcplay.play(si,ei,play.repv)}
ctxMenu.style.display="none";play.playing=true;if(tunes.length){while(1){elt=tunes.shift()
if(!elt)
break
play.abcplay.add(elt[0],elt[1],elt[3])}
play.si=play.ei=null
play.stop=0
play.loop=false}
if(what==2&&play.loop){play_start(play.si,play.ei)
return}
if(what==3&&play.stop>0){play_start(get_se(play.stop),play.ei)
return}
if(what!=0&&selx[0]&&selx[1]){si=get_se(selx[0]);ei=get_ee(selx[1])}else if(what!=0&&selx[0]){si=get_se(selx[0]);ei=null}else if(what!=0&&selx[1]){si=gsot(selx[1])
ei=get_ee(selx[1])}else{elt=play.click.svg
si=elt.getElementsByClassName('abcr')
if(!si.length){play.playing=false
return}
i=Number(si[0].getAttribute('class').slice(6,-1))
si=gsot(i)
ei=null}
if(what!=3){play.si=si;play.ei=ei;play.loop=what==2
play.repv=0}
play_start(si,ei)}
function edit_init(){var a,i,e
if(typeof abc2svg!="object"||!abc2svg.modules){setTimeout(edit_init,500)
return}
abc2svg.loadjs=function(fn,relay,onerror){var s=document.createElement('script');if(/:\/\//.test(fn))
s.src=fn
else
s.src=jsdir+fn;s.type='text/javascript'
if(relay)
s.onload=relay;s.onerror=onerror||function(){alert('error loading '+fn)}
document.head.appendChild(s)}
abc2svg.abc_end=function(){}
function set_pref(){var v=storage(true,"fontsz")
if(v){elt_ref.source.style.fontSize=elt_ref.src1.style.fontSize=v+"px";document.getElementById("fontsize").value=Number(v)}
v=storage(true,"lang");if(!v){v=(navigator.languages?navigator.languages[0]:navigator.language).split('-')[0]
switch(v){case"de":case"en":case"fr":case"it":break
case"pt":v="pt_BR";break
default:v="en";break}}
loadlang(v,true)}
document.getElementById("abc2svg").innerHTML='abc2svg-'+abc2svg.version+' ('+abc2svg.vdate+')'
a=["diverr","source","src1","s0","s1","target"]
for(i=0;i<a.length;i++){e=a[i]
elt_ref[e]=document.getElementById(e)}
document.getElementById("saveas").onclick=saveas;elt_ref.s0.onclick=function(){selsrc(0)};elt_ref.s1.onclick=function(){selsrc(1)};elt_ref.target.onclick=selsvg;elt_ref.source.onselect=seltxt;window.onbeforeprint=function(){selx_sav[0]=selx[0];selx_sav[1]=selx[1];setsel(0,0);setsel(1,0)};window.onafterprint=function(){setsel(0,selx_sav[0]);setsel(1,selx_sav[1])}
if(window.AudioContext||window.webkitAudioContext||navigator.requestMIDIAccess){abc2svg.loadjs("snd-1.js",function(){play.abcplay=AbcPlay({onend:endplay,onnote:notehlight,});document.getElementById("playdiv1").style.display=document.getElementById("playdiv3").style.display=document.getElementById("playdiv4").style.display="list-item";document.getElementById("sfu").value=play.abcplay.set_sfu();document.getElementById("gvol").setAttribute("value",play.abcplay.set_vol()*10)
document.getElementById("gvl").setAttribute("value",(play.abcplay.set_vol()*10).toFixed(2))});function show_menu(evt){var x,y,elt=evt.target,cl=elt.getAttribute('class')
if(cl&&cl.substr(0,4)=='abcr'){setsel(1,Number(cl.slice(6,-1)))
evt.preventDefault()
return}
ctxMenu=document.getElementById("ctxMenu");if(ctxMenu.style.display=="block")
return
evt.preventDefault()
play.click={svg:elt,Y:evt.pageY}
ctxMenu.style.display="block";x=evt.pageX-elt_ref.target.parentNode.offsetLeft
+elt_ref.target.parentNode.scrollLeft;y=evt.pageY+elt_ref.target.parentNode.scrollTop;ctxMenu.style.left=(x-30)+"px";ctxMenu.style.top=(y-10)+"px"}
e=elt_ref.target
e.ondblclick=show_menu
e.oncontextmenu=show_menu}
set_pref()}
function drag_enter(evt){evt.stopImmediatePropagation();evt.preventDefault()}
function drop(evt){evt.stopImmediatePropagation();evt.preventDefault()
var data=evt.dataTransfer.getData("text")
if(data){var x=evt.layerX,y=elt_ref.source.scrollTop+evt.layerY,h=elt_ref.source.offsetHeight/elt_ref.source.rows,w=elt_ref.source.offsetWidth/elt_ref.source.cols
w=(x/w)|0
h=(y/h)|0
h=soffs(h,w)
var e=evt.target
e.value=e.value.slice(0,h)
+data
+e.value.slice(h)
src_change()
return}
data=evt.dataTransfer.files
if(data.length){var reader=new FileReader(),s=srcidx==0?"source":"src1"
elt_ref["s"+srcidx].value=abc_fname[srcidx]=data[0].name
reader.onload=function(evt){elt_ref[s].value=evt.target.result
chg=-1
src_change()}
reader.readAsText(data[0],"UTF-8")}}
var timer
function src_change(){clearTimeout(timer);if(!play.playing)
timer=setTimeout(render,2000)}
window.addEventListener("load",edit_init)