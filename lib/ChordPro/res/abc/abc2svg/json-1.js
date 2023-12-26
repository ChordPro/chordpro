// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2020 Jean-Francois Moine - LGPL3+
//#javascript
function AbcJSON(nindent){var inb=Array((nindent||2)+1).join(' ')
AbcJSON.prototype.gen_json=function(tsfirst,voice_tb,anno_type,info){var json,i,j,l,v,s,h,ind2=inb+inb,ind3=ind2+inb,ind4=ind3+inb,links={next:true,prev:true,ts_next:true,ts_prev:true,extra:true,note:true,p_v:true,s:true,sn:true,tie_s:true,dd_st:true,sym:true,last_sym:true,last_note:true,lyric_restart:true,sym_restart:true,rep_p:true,rep_v:true,rep_s:true},objstk=[]
function attr_gen(ind,attr,val){var i,e,l,indn=ind+inb
if(links[attr]){switch(attr){case"extra":json+=h+ind+'"extra": [';h='\n'
for(e=val;e;e=e.next)
attr_gen(indn,null,e);json+='\n'+ind+']'
break
case"tie_s":json+=h+ind+'"ti1": true'
break}
return}
json+=h+ind
if(attr)
json+='"'+attr.toString()+'": ';switch(typeof(val)){case"undefined":json+="null"
break
case"object":if(!val){json+="null"
break}
if(objstk.indexOf(val)>=0){json+="!!! to_json: loop in '"+attr+"' !!!"
break}
objstk.push(val)
if(Array.isArray(val)){if(val.length==0){json+="[]"
break}
h='[\n';l=val.length
for(i=0;i<l;i++)
attr_gen(indn,null,val[i]);json+='\n'+ind+']'}else{h='{\n'
for(i in val)
if(val.hasOwnProperty(i))
attr_gen(indn,i,val[i]);json+='\n'+ind+'}'}
objstk.pop()
break
default:json+=JSON.stringify(val)
break}
h=',\n'}
json='';h='{\n';attr_gen(inb,"music_types",anno_type);h=',\n'+inb+'"music_type_ids": {\n';l=anno_type.length
for(i=0;i<l;i++){if(anno_type[i]){json+=h+ind2+'"'+anno_type[i]+'": '+i;h=',\n'}}
h='\n'+inb+'},\n';attr_gen(inb,"info",info);json+=',\n'+inb+'"voices": [';v=0;h='\n'
while(1){h+=ind2+'{\n'+
ind3+'"voice_properties": {\n'
for(i in voice_tb[v])
if(voice_tb[v].hasOwnProperty(i))
attr_gen(ind4,i,voice_tb[v][i]);json+='\n'+ind3+'},\n'+
ind3+'"symbols": [';s=voice_tb[v].sym
if(!s){json+=']\n'+ind3+'}'}else{h='\n'
for(;s;s=s.next)
attr_gen(ind4,null,s);json+='\n'+ind3+']\n'+
ind2+'}'}
h=',\n'
if(!voice_tb[++v])
break}
return json+'\n'+inb+']\n}\n'}}
