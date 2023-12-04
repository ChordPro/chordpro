//combine.js-module to add a combine chord line
if(typeof abc2svg=="undefined")
var abc2svg={}
abc2svg.combine={comb_v:function(){var C=abc2svg.C,abc=this
function get_cmb(s){var p,s2=s.ts_next,i=s.p_v.id.indexOf('.')
if(i>=0){p=s.p_v.id.slice(0,i)
while(s2&&s2.time==s.time){if(s2.p_v.id.indexOf(p)==0)
break
s2=s2.ts_next}}
return s2}
function may_combine(s){var nhd2,s2=get_cmb(s)
if(!s2||(s2.type!=C.NOTE&&s2.type!=C.REST))
return false
if(s2.st!=s.st||s2.time!=s.time||s2.dur!=s.dur)
return false
if(s.combine<=0&&s2.type!=s.type)
return false
if(s.a_gch&&s2.a_gch)
return false
if(s.type==C.REST){if(s.type==s2.type&&s.invis&&!s2.invis)
return false
return true}
if(s2.a_ly)
return false
if(s2.beam_st!=s.beam_st||s2.beam_end!=s.beam_end)
return false;nhd2=s2.nhd
if(s.combine<=1&&s.notes[0].pit<=s2.notes[nhd2].pit+1)
return false
return true}
function combine_notes(s,s2){var nhd,type,m,not
for(m=0;m<=s2.nhd;m++){not=abc.clone(s2.notes[m])
not.noplay=true
s.notes.push(not)}
s.nhd=nhd=s.notes.length-1;s.notes.sort(abc2svg.pitcmp)
if(s.combine>=3){for(m=nhd;m>0;m--){if(s.notes[m].pit==s.notes[m-1].pit&&s.notes[m].acc==s.notes[m-1].acc)
s.notes.splice(m,1)}
s.nhd=nhd=s.notes.length-1}
s.ymx=3*(s.notes[nhd].pit-18)+4;s.ymn=3*(s.notes[0].pit-18)-4;type=s.notes[0].tie_ty
if((type&0x07)==C.SL_AUTO)
s.notes[0].tie_ty=C.SL_BELOW|(type&C.SL_DOTTED);type=s.notes[nhd].tie_ty
if((type&0x07)==C.SL_AUTO)
s.notes[nhd].tie_ty=C.SL_ABOVE|(type&C.SL_DOTTED)}
function do_combine(s){var s2,s3,type,i,n,sl
s2=get_cmb(s)
if(!s.in_tuplet&&s2.combine!=undefined&&s2.combine>=0&&may_combine(s2))
s2=do_combine(s2)
if(s.type!=s2.type){if(s2.type!=C.REST){s2=s;s=s2.ts_next}}else if(s.type==C.REST){if(s.invis&&!s2.invis)
delete s.invis}else{combine_notes(s,s2)
if(s2.ti1)
s.ti1=true
if(s2.ti2)
s.ti2=true}
if(s2.sls){if(s.sls)
Array.prototype.push.apply(s.sls,s2.sls)
else
s.sls=s2.sls
for(i=0;i<s2.sls.length;i++){sl=s2.sls[i]
if(sl.se)
sl.se.slsr=s
sl.ty=C.SL_BELOW}
delete s2.sls}
s3=s2.slsr
if(s3){for(i=0;i<s3.sls.length;i++){sl=s3.sls[i]
if(sl.se==s2)
sl.se=s}}
if(s2.a_gch)
s.a_gch=s2.a_gch
if(s2.a_dd){if(!s.a_dd)
s.a_dd=s2.a_dd
else
Array.prototype.push.apply(s.a_dd,s2.a_dd)}
s2.play=s2.invis=true
return s}
var s,s2,g,i,r
for(s=abc.get_tsfirst();s;s=s.ts_next){switch(s.type){case C.REST:if(s.combine==undefined||s.combine<0)
continue
if(may_combine(s))
s=do_combine(s)
default:continue
case C.NOTE:if(s.combine==undefined||s.combine<=0)
continue
break}
if(!s.beam_st)
continue
s2=s
while(1){if(!may_combine(s2)){s2=null
break}
if(s2.beam_end)
break
do{s2=s2.next}while(s2.type!=C.NOTE&&s2.type!=C.REST)}
if(!s2)
continue
s2=s
while(1){s2=do_combine(s2)
if(s2.beam_end)
break
do{s2=s2.next}while(s2.type!=C.NOTE&&s2.type!=C.REST)}}},do_pscom:function(of,text){if(text.slice(0,13)=="voicecombine ")
this.set_v_param("combine",text.split(/[ \t]/)[1])
else
of(text)},new_note:function(of,gr,tp){var curvoice=this.get_curvoice()
var s=of(gr,tp)
if(s&&s.notes&&curvoice.combine!=undefined)
s.combine=curvoice.combine
return s},set_stem_dir:function(of){of();abc2svg.combine.comb_v.call(this)},set_vp:function(of,a){var i,curvoice=this.get_curvoice()
for(i=0;i<a.length;i++){if(a[i]=="combine="){curvoice.combine=a[i+1]
break}}
of(a)},set_hooks:function(abc){abc.do_pscom=abc2svg.combine.do_pscom.bind(abc,abc.do_pscom);abc.new_note=abc2svg.combine.new_note.bind(abc,abc.new_note);abc.set_stem_dir=abc2svg.combine.set_stem_dir.bind(abc,abc.set_stem_dir);abc.set_vp=abc2svg.combine.set_vp.bind(abc,abc.set_vp)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.combine=abc2svg.combine.set_hooks
