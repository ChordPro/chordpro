// abc2svg - ABC to SVG translator
// @source: https://chiselapp.com/user/moinejf/repository/abc2svg
// Copyright (C) 2014-2021 Jean-Francois Moine - LGPL3+
//temper.js-module to define the temperament
abc2svg.temper={set_fmt:function(of,cmd,param){if(cmd=="temperament"){var i,tb,tb40=new Float32Array(40),ls=new Float32Array(param.split(/ +/))
for(i=0;i<ls.length;i++){if(isNaN(ls[i]))
break
ls[i]=i+ls[i]/100}
switch(i){case 12:tb=[10,11,0,1,2,0,0,1,2,3,4,0,2,3,4,5,6,3,4,5,6,7,0,5,6,7,8,9,0,7,8,9,10,11,0,9,10,11,0,1]
break
default:this.syntax(1,this.errs.bad_val,"%%temperament")
return}
for(i=0;i<40;i++)
tb40[i]=ls[tb[i]]
this.cfmt().temper=tb40
return}
of(cmd,param)},set_hooks:function(abc){abc.set_format=abc2svg.temper.set_fmt.bind(abc,abc.set_format)}}
abc2svg.modules.hooks.push(abc2svg.temper.set_hooks);abc2svg.modules.temperament.loaded=true
