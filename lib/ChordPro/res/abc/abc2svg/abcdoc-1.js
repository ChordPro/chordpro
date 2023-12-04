//#javascript
var user
(function(){window.onerror=function(msg,url,line){if(typeof msg=='string')
alert("window error: "+msg+"\nURL: "+url+"\nLine: "+line)
else if(typeof msg=='object')
alert("window error: "+msg.type+' '+msg.target.src)
else
alert("window error: "+msg)
return false}
function abcdoc(){var errtxt='',new_page='',page,jsdir=document.currentScript?document.currentScript.src.match(/.*\//):(function(){var s_a=document.getElementsByTagName('script')
for(var k=0;k<s_a.length;k++){if(s_a[k].src.indexOf('abcdoc-')>=0)
return s_a[k].src.match(/.*\//)||''}
return""})()
user={errmsg:function(msg,l,c){errtxt+=clean_txt(msg)+'\n'},img_out:function(str){new_page+=str}}
function clean_txt(txt){return txt.replace(/<|>|&.*?;|&/g,function(c){switch(c){case'<':return"&lt;"
case'>':return"&gt;"
case'&':return"&amp;"}
return c})}
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
function render(){var i=0,j,k,res,re,re_stop=/\n<|\n%.begin/g,abc=new abc2svg.Abc(user);if(page.indexOf('<script type="text/vnd.abc"')>=0)
re=/<script type="text\/vnd.abc"/g
else
re=/\n%abc|\nX:/g
for(;;){res=re.exec(page)
if(!res)
break
j=re.lastIndex-res[0].length;new_page+=page.slice(i,j);if(page[j]=='<'){j=page.indexOf(">",re.lastIndex)+2
k=page.indexOf("</script>",j)
tune=page.slice(j,k)
k+=10}else{re_stop.lastIndex=++j
while(1){res=re_stop.exec(page)
if(!res||res[0]=="\n<")
break
k=page.indexOf(res[0].replace("begin","end"),re_stop.lastIndex)
if(k<0)
break
re_stop.lastIndex=k}
if(!res||k<0)
k=page.length
else
k=re_stop.lastIndex-2
tune=page.slice(j,k)}
new_page+='<pre style="display:inline-block; vertical-align: top">'+
clean_txt(tune)+'</pre>\n\
<div style="display:inline-block; vertical-align: top">\n'
try{abc.tosvg('abcdoc',tune)}catch(e){alert("abc2svg javascript error: "+e.message+"\nStack:\n"+e.stack)}
if(errtxt){i=page.indexOf("\n",j);i=page.indexOf("\n",i+1);alert("Errors in\n"+
page.slice(j,i)+"\n...\n\n"+errtxt);errtxt=""}
abc2svg.abc_end();new_page+='</div><br/>\n';i=k
if(k>=page.length)
break
re.lastIndex=i}
try{document.body.innerHTML=new_page+page.slice(i)}catch(e){alert("abc2svg bad generated SVG: "+e.message+"\nStack:\n"+e.stack)}}
page=document.body.innerHTML;abc2svg.abc_end=function(){}
if(abc2svg.modules.load(page,render))
render()}
function dom_loaded(){if(typeof abc2svg!="object"||!abc2svg.modules){setTimeout(dom_loaded,500)
return}
abcdoc()}
document.addEventListener("DOMContentLoaded",dom_loaded,false)})()
