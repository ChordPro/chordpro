//wps.js
function isQuoted(V){return V.q}
function quote(V){V.q=true;return V}
function unquote(V){delete V.q;return V}
function Symbol(N){this.nm=N;return this}
function isSymbol(V){return V&&V.constructor===Symbol}
function symbolName(V){return V.nm}
function isArray(V){return V&&V.constructor===Array}
function inDs(Ds,K){for(var I=Ds.length-1;0<=I;--I){if("undefined"!=typeof Ds[I][K])
return Ds[I]}
return false}
function member(C,L){return 0<=L.indexOf(C)}
function PsParser(){var Self=this;function init(L){Self.L=L;Self.N=L.length;Self.I=0;Self.D=0}
function peek(){return Self.I<Self.N&&Self.L[Self.I]}
function xchar(){return Self.I<Self.N&&Self.L[Self.I++]}
function skip(){while(Self.I<Self.N&&member(Self.L[Self.I]," \t\n"))
Self.I++}
function comment(){while("%"==peek()){while(peek()&&"\n"!=peek())
xchar();skip()}}
function text(){xchar();var L=[];var N=1;while(0<N&&peek()){var C=xchar();switch(C){case"(":N++;break;case")":N--;if(N<=0)C=false;break;case"\\":C=xchar();switch(C){case"(":break;case")":break;case"\\":break;case"n":C="\n";break;case"r":C="\r";break;case"t":C="\t";break;default:C=false}
break}
if(C!==false)L.push(C)}
return L.join("")}
function symbol(){var C=xchar();if(member(C,"()<>/% \t\n"))throw new Error("Symbol expected, got "+C);var N=member(C,"+-0123456789.");var F="."==C;var L=[C];while(peek()&&!member(peek(),"()<>[]{}/% \t\n")){C=xchar();L.push(C);if(N&&!member(C,"0123456789")){if(!F&&"."==C)F=true;else N=false}}
L=L.join("");if(1==L.length&&member(L,"+-."))N=false;return N?(F?parseFloat(L):parseInt(L,10)):new Symbol(L)}
function token(){skip();switch(peek()){case false:return undefined;case"%":return comment();case"[":return new Symbol(xchar());case"]":return new Symbol(xchar());case"{":Self.D++;return new Symbol(xchar());case"}":Self.D--;return new Symbol(xchar());case"/":xchar();var X=symbol();return quote(X);case"(":return text();case"<":xchar();if("<"!=peek())throw new Error("Encoded strings not implemented yet");xchar();return new Symbol("<<");case">":xchar();if(">"!=peek())throw new Error("Unexpected >");xchar();return new Symbol(">>");default:return symbol()}}
PsParser.prototype.init=init;PsParser.prototype.peek=peek;PsParser.prototype.token=token;return this}
function Ps0(Os,Ds,Es){function run(X,Z){if(isSymbol(X)&&!isQuoted(X)){var K=symbolName(X);var D=inDs(Ds,K);if(!D)
throw new Error("bind error '"+K+"'");Es.push([false,D[K]])}else if(Z&&isArray(X)&&isQuoted(X)){if(0<X.length){var F=X[0];var R=quote(X.slice(1));if(0<R.length)Es.push([false,R]);run(F,false)}}else if("function"==typeof X)X();else Os.push(X)}
function exec(){var X=Os.pop();run(X,false)}
function step(){var C=Es.pop();var L=C.shift();var X=C.pop();for(var I=0;I<C.length;I++)
Os.push(C[I]);run(X,true)}
var PsP=new PsParser;function parse(L){PsP.init(L);while(PsP.peek()){var T=PsP.token();if(T||T===0){Os.push(T);if(PsP.D<=0||isSymbol(T)&&(member(symbolName(T),"[]{}")||"<<"==symbolName(T)||">>"==symbolName(T))){exec();while(0<Es.length)
step()}}}
return Os}
Ps0.prototype.run=run;Ps0.prototype.exec=exec;Ps0.prototype.step=step;Ps0.prototype.parse=parse;return this}
function Wps(psvg_i){var psvg=psvg_i;var Os=[];var Sd={};var Ds=[Sd];var Es=[];var Ps=new Ps0(Os,Ds,Es);Sd["true"]=function(){Os.push(true)};Sd["false"]=function(){Os.push(false)};Sd["null"]=function(){Os.push(null)};Sd["sub"]=function(){var X=Os.pop();Os.push(Os.pop()-X)};Sd["mul"]=function(){Os.push(Os.pop()*Os.pop())};Sd["div"]=function(){var X=Os.pop();Os.push(Os.pop()/X)};Sd["mod"]=function(){var X=Os.pop();Os.push(Os.pop()%X)};var M={};Sd["mark"]=function(){Os.push(M)};Sd["counttomark"]=function(){var N=0;for(var I=Os.length-1;0<=I;I--)
if(M===Os[I])return Os.push(N);else N++;throw new Error("Mark not found")};Sd["<<"]=Sd["mark"];Sd[">>"]=function(){var D={};while(0<Os.length){var V=Os.pop();if(M===V)return Os.push(D);D[Os.pop()]=V}
throw new Error("Mark not found")};Sd["exch"]=function(){var Y=Os.pop();var X=Os.pop();Os.push(Y);Os.push(X)};Sd["clear"]=function(){Os.length=0};Sd["pop"]=function(){Os.pop()};Sd["index"]=function(){Os.push(Os[Os.length-2-Os.pop()])};Sd["roll"]=function(){var J=Os.pop();var N=Os.pop();var X=[];var Y=[];if(J<0)
J=N+J
for(var I=0;I<N;I++)
if(I<J)X.unshift(Os.pop());else Y.unshift(Os.pop());for(I=0;I<J;I++)Os.push(X.shift());for(I=0;I<N-J;I++)Os.push(Y.shift())};Sd["copy"]=function(){var N=Os.pop();if("object"==typeof N){var X=Os.pop();for(var I in X)
N[I]=X[I];Os.push(N)}else{var X=Os.length-N;for(var I=0;I<N;I++)
Os.push(Os[X+I])}};Sd["length"]=function(){Os.push(Os.pop().length)};Sd["astore"]=function(){var A=Os.pop();var N=A.length;for(var I=N-1;0<=I;I--)
A[I]=Os.pop();Os.push(A)};Sd["array"]=function(){Os.push(new Array(Os.pop()))};Sd["eq"]=function(){var Y=Os.pop();var X=Os.pop();Os.push(X==Y)};Sd["lt"]=function(){var Y=Os.pop();var X=Os.pop();Os.push(X<Y)};Sd["ifelse"]=function(){var N=Os.pop();var P=Os.pop();var C=Os.pop();Es.push([false,C===true?P:N])};Sd["and"]=function(){var A=Os.pop();var B=Os.pop();if(true===A||false===A){Os.push(A==true&&B===true)
return}
Os.push(A&B)}
Sd["repeat"]=function Xrepeat(){var B=Os.pop();var N=Os.pop();if(1<N)Es.push([true,N-1,B,Xrepeat]);if(0<N)Es.push([false,B])};Sd["for"]=function Xfor(){var B=Os.pop();var L=Os.pop();var K=Os.pop();var J=Os.pop();if(K<0){if(L<=J+K)Es.push([true,J+K,K,L,B,Xfor]);if(L<=J)Es.push([false,J,B])}else{if(J+K<=L)Es.push([true,J+K,K,L,B,Xfor]);if(J<=L)Es.push([false,J,B])}};Sd["exec"]=function(){Es.push([false,Os.pop()])};Sd["cvx"]=function(){var X=Os.pop();if(isSymbol(X)&&isQuoted(X))Os.push(unquote(X));else if(isArray(X)&&!isQuoted(X))Os.push(quote(X));else Os.push(X)};Sd["dict"]=function(){Os.pop();Os.push({})};Sd["get"]=function(){var K=Os.pop();var D=Os.pop();if(isSymbol(K))Os.push(D[symbolName(K)]);else Os.push(D[K])};Sd["getinterval"]=function(){var N=Os.pop(),K=Os.pop()+N,D=Os.pop(),A=[]
while(--N>=0)
A.push(D[K++])
Os.push(A)};Sd["put"]=function(){var V=Os.pop();var K=Os.pop();var D=Os.pop();if(isSymbol(K))D[symbolName(K)]=V;else D[K]=V};Sd["begin"]=function(){Ds.push(Os.pop())};Sd["end"]=function(){Ds.pop()};Sd["currentdict"]=function(){Os.push(Ds[Ds.length-1])};Sd["where"]=function(){var K=symbolName(Os.pop());var D=inDs(Ds,K);if(D){Os.push(D);Os.push(true)}else Os.push(false)};Sd["save"]=function(){var X=Ds.slice();for(var I=0;I<X.length;I++){var A=X[I];var B={};for(var J in A)
B[J]=A[J];X[I]=B}
Os.push(X)};Sd["restore"]=function(){var X=Os.pop();while(0<Ds.length)
Ds.pop();while(0<X.length)
Ds.unshift(X.pop())};Sd["type"]=function(){var A=Os.pop();var X;if(null===A)X="nulltype";else if(true===A||false===A)X="booleantype";else if(M===A)X="marktype";else if("string"==typeof A)X="stringtype";else if(isSymbol(A))X=isQuoted(A)?"nametype":"operatortype";else if("function"==typeof A)X="operatortype";else if(isArray(A))X="arraytype";else if("object"==typeof A)X="dicttype";else if(1*A==A)X=A%1==0?"integertype":"realtype";else throw new Error("Undefined type '"+A+"'");Os.push(X)};var Sb=true;Sd[".strictBind"]=function(){Sb=true===Os.pop()};Sd["bind"]=function(){Os.push(bind(Os.pop()))};function bind(X){if(isSymbol(X)&&!isQuoted(X)){return X}else if(isArray(X)&&isQuoted(X)){var N=X.length;var A=[];for(var I=0;I<N;I++){var Xi=X[I];var Xb=bind(Xi);if(isArray(Xi))
A=A.concat(isQuoted(Xi)?quote([Xb]):[Xb]);else
A=A.concat(Xb)}
return quote(A)}
return X}
Sd["="]=function(){var X=Os.pop();alert(X&&X.nm||X)};Sd["=="]=function(){alert(Os.pop())};Sd["stack"]=function(){alert(Os)};Sd["pstack"]=function(){alert(Os)};Sd[".call"]=function(){var N=Os.pop();var K=Os.pop();var D=Os.pop();var X=[];for(var I=0;I<N;I++)X.unshift(Os.pop());if(!D[K])throw new Error(".call: "+K+" undef")
Os.push(D[K].apply(D,X))};Sd[".call0"]=function(){var N=Os.pop(),K=Os.pop(),D=Os.pop(),X=[]
for(var I=0;I<N;I++)X.unshift(Os.pop());if(!D[K])throw new Error(".call0: "+K+" undef")
D[K].apply(D,X)};Sd[".svg"]=function(){Os.push(psvg)};Sd[".math"]=function(){Os.push(Math)};Sd[".date"]=function(){Os.push(new Date())};Sd[".window"]=function(){Os.push(window)};Sd[".callback"]=function(){var X=Os.pop();Os.push(function(){Ps.run(X,true);while(0<Es.length)
Ps.step()})};Sd[".minv"]=function(){var M=Os.pop();var a=M[0];var b=M[1];var d=M[2];var e=M[3];var g=M[4];var h=M[5];Os.push([e,b,d,a,d*h-e*g,b*g-a*h])};Sd[".mmul"]=function(){var B=Os.pop();var A=Os.pop();var a=A[0];var b=A[1];var d=A[2];var e=A[3];var g=A[4];var h=A[5];var r=B[0];var s=B[1];var u=B[2];var v=B[3];var x=B[4];var y=B[5];Os.push([a*r+b*u,a*s+b*v,d*r+e*u,d*s+e*v,g*r+h*u+x,g*s+h*v+y])};Sd[".xy"]=function(){var M=Os.pop();var Y=Os.pop();var X=Os.pop();Os.push(M[0]*X+M[2]*Y+M[4]);Os.push(M[1]*X+M[3]*Y+M[5])};Sd[".rgb"]=function(){var B=Os.pop();var G=Os.pop();var R=Os.pop();Os.push("rgb("+R+","+G+","+B+")")};Sd[".rgba"]=function(){var A=Os.pop();var B=Os.pop();var G=Os.pop();var R=Os.pop();Os.push("rgba("+R+","+G+","+B+","+A+")")};function parse(){var T=arguments;if(T.length)
for(var I=0;I<T.length;I++)
Ps.parse(T[I]);else Ps.parse(T);return Os}
Wps.prototype.parse=parse;return this}
if(typeof abc2svg=="undefined")
var abc2svg={}
function Psvg(abcobj_r){var svgbuf='',abcobj=abcobj_r,wps=new Wps(this),g=0,gchg,gcur={cx:0,cy:0,xoffs:0,yoffs:0,xscale:1,yscale:1,rotate:0,sin:0,cos:1,linewidth:0.7,dash:''},gc_stack=[],x_rot=0,y_rot=0,font_n="",font_n_old="",font_s=0,path;function getorig(){setg(0);return[gcur.xoffs-gcur.xorig,gcur.yoffs-gcur.yorig]}
function defg1(){gchg=false;setg(0);svgbuf+="<g"
if(gcur.xscale!=1||gcur.yscale!=1||gcur.rotate){svgbuf+=' transform="'
if(gcur.xscale!=1||gcur.yscale!=1){if(gcur.xscale==gcur.yscale)
svgbuf+="scale("+gcur.xscale.toFixed(3)+")"
else
svgbuf+="scale("+gcur.xscale.toFixed(3)+","+gcur.yscale.toFixed(3)+")"}
if(gcur.rotate){if(gcur.xoffs||gcur.yoffs){var x,xtmp=gcur.xoffs,y=gcur.yoffs,_sin=gcur.sin,_cos=gcur.cos;x=xtmp*_cos-y*_sin;y=xtmp*_sin+y*_cos;svgbuf+=" translate("+x.toFixed(1)+","+
y.toFixed(1)+")";x_rot=gcur.xoffs;y_rot=gcur.yoffs;gcur.xoffs=0;gcur.yoffs=0}
svgbuf+=" rotate("+gcur.rotate.toFixed(2)+")"}
svgbuf+='"'}
output_font(false)
if(gcur.rgb)
svgbuf+=' style="color:'+gcur.rgb+'"';svgbuf+=">\n";g=1}
function objdup(obj){var k,tmp=new obj.constructor()
for(k in obj)
if(obj.hasOwnProperty(k))
tmp[k]=obj[k]
return tmp}
function output_font(back){var name=gcur.font_n
if(!name)
return
var prop="",i=name.indexOf("Italic"),j=100,o=name.indexOf("Oblique"),b=name.indexOf("Bold"),flags=0
if(b>0){prop=' font-weight="bold"';j=b;flags=2}
if(i>0||o>0){if(i>0){prop+=' font-style="italic"';if(i<j)
j=i;flags|=4}
if(o>0){prop+=' font-style="oblique"';if(o<j)
j=o;flags=8}}
if(j!=100){if(name[j-1]=='-')
j--;name=name.slice(0,j)}
if(back){if(!(flags&2)&&font_n_old.indexOf("Bold")>=0)
prop+=' font-weight="normal"';if(!(flags&12)&&(font_n_old.indexOf("Italic")>=0||font_n_old.indexOf("Oblique")>=0))
prop+=' font-style="normal"'}
svgbuf+=' font-family="'+name+'"'+
prop+' font-size="'+gcur.font_s+'"'}
function path_def(){if(path)
return
setg(1);gcur.px=gcur.cx;gcur.py=gcur.cy;path='<path d="m'+(gcur.xoffs+gcur.cx).toFixed(1)+' '+(gcur.yoffs-gcur.cy).toFixed(1)+'\n'}
function path_end(){svgbuf+=path;path=''}
function setg(newg){if(g==2){svgbuf+="</text>\n";g=1}
if(newg==0){if(g){g=0;svgbuf+="</g>\n"
if(gcur.rotate){gcur.xoffs=x_rot;gcur.yoffs=y_rot;x_rot=0;y_rot=0}}}else if(gchg){defg1()}}
function strw(s){return s.length*gcur.font_s*0.5}
Psvg.prototype.strw=strw;function arc(x,y,r,a1,a2,arcn){var x1,y1,x2,y2
if(a1>=360)
a1-=360
if(a2>=360)
a2-=360;x1=x+r*Math.cos(a1*Math.PI/180);y1=y+r*Math.sin(a1*Math.PI/180)
if(gcur.cx!=undefined){if(path){if(x1!=gcur.cx||y1!=gcur.cy)
path+='l'
else
path+='m';path+=(x1-gcur.cx).toFixed(1)+" "+
(-(y1-gcur.cy)).toFixed(1)}else{gcur.cx=x1;gcur.cy=y1;path_def()}}else{if(path)
path=''
gcur.cx=x1;gcur.cy=y1;path_def()}
if(a1==a2){a2=180-a1;x2=x+r*Math.cos(a2*Math.PI/180);y2=y+r*Math.sin(a2*Math.PI/180);path+='a'+r.toFixed(2)+' '+r.toFixed(2)+' 0 0 '+
(arcn?'1 ':'0 ')+
(x2-x1).toFixed(2)+' '+
(y1-y2).toFixed(2)+' '+
r.toFixed(2)+' '+r.toFixed(2)+' 0 0 '+
(arcn?'1 ':'0 ')+
(x1-x2).toFixed(2)+' '+
(y2-y1).toFixed(2)+'\n';gcur.cx=x1;gcur.cy=y1}else{x2=x+r*Math.cos(a2*Math.PI/180);y2=y+r*Math.sin(a2*Math.PI/180);path+='a'+r.toFixed(2)+' '+r.toFixed(2)+' 0 0 '+
(arcn?'1 ':'0 ')+
(x2-x1).toFixed(2)+' '+
(y1-y2).toFixed(2)+'\n';gcur.cx=x2;gcur.cy=y2}}
Psvg.prototype.arc=arc
Psvg.prototype.arcn=function(x,y,r,a1,a2){arc(x,y,r,a1,a2,true)}
Psvg.prototype.closepath=function(){if(path&&gcur.cx)
rlineto(gcur.px-gcur.cx,gcur.py-gcur.cy)}
Psvg.prototype.cx=function(){return gcur.cx}
Psvg.prototype.cy=function(){return gcur.cy}
Psvg.prototype.curveto=function(x1,y1,x2,y2,x,y){path_def();path+="\tC"+
(gcur.xoffs+x1).toFixed(1)+" "+(gcur.yoffs-y1).toFixed(1)+" "+
(gcur.xoffs+x2).toFixed(1)+" "+(gcur.yoffs-y2).toFixed(1)+" "+
(gcur.xoffs+x).toFixed(1)+" "+(gcur.yoffs-y).toFixed(1)+"\n";gcur.cx=x;gcur.cy=y}
Psvg.prototype.eofill=function(){path_end();svgbuf+='" fill-rule="evenodd" fill="currentColor"/>\n'}
Psvg.prototype.fill=function(){path_end();svgbuf+='" fill="currentColor"/>\n'}
Psvg.prototype.gsave=function(){gc_stack.push(objdup(gcur))}
Psvg.prototype.grestore=function(){gcur=gc_stack.pop();gchg=true}
Psvg.prototype.lineto=function(x,y){path_def()
if(x==gcur.cx)
path+="\tv"+(gcur.cy-y).toFixed(1)+"\n"
else if(y==gcur.cy)
path+="\th"+(x-gcur.cx).toFixed(1)+"\n"
else
path+="\tl"+(x-gcur.cx).toFixed(1)+" "+
(gcur.cy-y).toFixed(1)+"\n";gcur.cx=x;gcur.cy=y}
Psvg.prototype.moveto=function(x,y){gcur.cx=x;gcur.cy=y
if(path){path+="\tM"+(gcur.xoffs+gcur.cx).toFixed(1)+" "+
(gcur.yoffs-gcur.cy).toFixed(1)+"\n"}else if(g==2){svgbuf+="</text>\n";g=1}}
Psvg.prototype.newpath=function(){gcur.cx=gcur.cy=undefined}
Psvg.prototype.rcurveto=function(x1,y1,x2,y2,x,y){path_def();path+="\tc"+
x1.toFixed(1)+" "+(-y1).toFixed(1)+" "+
x2.toFixed(1)+" "+(-y2).toFixed(1)+" "+
x.toFixed(1)+" "+(-y).toFixed(1)+"\n";gcur.cx+=x;gcur.cy+=y}
function rlineto(x,y){path_def()
if(x==0)
path+="\tv"+(-y).toFixed(1)+"\n"
else if(y==0)
path+="\th"+x.toFixed(1)+"\n"
else
path+="\tl"+x.toFixed(1)+" "+
(-y).toFixed(1)+"\n";gcur.cx+=x;gcur.cy+=y}
Psvg.prototype.rlineto=rlineto;Psvg.prototype.rmoveto=function(x,y){if(path){path+="\tm"+x.toFixed(1)+" "+
(-y).toFixed(1)+"\n"}else if(g==2){svgbuf+="</text>\n";g=1}
gcur.cx+=x;gcur.cy+=y}
Psvg.prototype.rotate=function(a){setg(0)
var x,xtmp=gcur.xoffs,y=gcur.yoffs,_sin=gcur.sin,_cos=gcur.cos;x=xtmp*_cos-y*_sin;y=xtmp*_sin+y*_cos;gcur.xoffs=x/gcur.xscale;gcur.yoffs=y/gcur.yscale;xtmp=gcur.cx;y=gcur.cy;x=xtmp*_cos-y*_sin;y=-xtmp*_sin+y*_cos;gcur.cx=x/gcur.xscale;gcur.cy=y/gcur.yscale;a=360-a;gcur.rotate+=a
if(gcur.rotate>180)
gcur.rotate-=360
else if(gcur.rotate<=-180)
gcur.rotate+=360
a=gcur.rotate*Math.PI/180;gcur.sin=_sin=Math.sin(a);gcur.cos=_cos=Math.cos(a);x=gcur.cx;gcur.cx=(x*_cos+gcur.cy*_sin)*gcur.xscale;gcur.cy=(-x*_sin+gcur.cy*_cos)*gcur.yscale;x=gcur.xoffs;gcur.xoffs=(x*_cos+gcur.yoffs*_sin)*gcur.xscale;gcur.yoffs=(-x*_sin+gcur.yoffs*_cos)*gcur.yscale;gchg=true}
Psvg.prototype.scale=function(sx,sy){gcur.xoffs/=sx;gcur.yoffs/=sy;gcur.cx/=sx;gcur.cy/=sy;gcur.xscale*=sx;gcur.yscale*=sy;gchg=true}
Psvg.prototype.selectfont=function(s,h){s=s.nm;if(font_s!=h||s!=font_n){gcur.font_n_old=gcur.font_n;gcur.font_n=s;gcur.font_s=h;gchg=true}}
Psvg.prototype.setdash=function(a,o){var n=a.length,i
if(n==0){gcur.dash=''
return}
gcur.dash=' stroke-dashoffset="'+o+'"  stroke-dasharray="';i=0
while(1){gcur.dash+=a[i]
if(--n==0)
break
gcur.dash+=' '}
gcur.dash+='"'}
Psvg.prototype.setlinewidth=function(w){gcur.linewidth=w}
Psvg.prototype.setrgbcolor=function(r,g,b){var rgb=0x1000000+
(Math.floor(r*255)<<16)+
(Math.floor(g*255)<<8)+
Math.floor(b*255);rgb=rgb.toString(16);rgb=rgb.replace('1','#')
if(rgb!=gcur.rgb){gcur.rgb=rgb;gchg=true}}
Psvg.prototype.show=function(s){var span,x,y
if(gchg){if(g==2)
span=true
else
defg1()}
x=gcur.cx;y=gcur.cy
if(span){svgbuf+="<tspan\n\t";output_font(true);svgbuf+=">"}else if(g!=2){if(!g)
defg1()
svgbuf+='<text x="'+(x+gcur.xoffs).toFixed(1)+'" y="'+
(gcur.yoffs-y).toFixed(1)+'">';g=2}
svgbuf+=s.replace(/<|>|&/g,function(c){switch(c){case'<':return"&lt;"
case'>':return"&gt;"
case'&':return"&amp;"}})
if(span)
svgbuf+="</tspan>";gcur.cx=x+strw(s)}
Psvg.prototype.stroke=function(){path_end()
if(gcur.linewidth!=0.7)
svgbuf+='" stroke-width="'+gcur.linewidth.toFixed(1);svgbuf+='" stroke="currentColor" fill="none"'+gcur.dash+'/>\n'}
Psvg.prototype.translate=function(x,y){gcur.xoffs+=x;gcur.yoffs-=y;gcur.cx-=x;gcur.cy-=y}
Psvg.prototype.arp=function(val,x,y){var xy=getorig();ps_flush();abcobj.out_arp((x+xy[0])*abcobj.stv_g().scale,y-xy[1],val)}
Psvg.prototype.ltr=function(val,x,y){var xy=getorig();ps_flush();abcobj.out_ltr((x+xy[0])*abcobj.stv_g().scale,y-xy[1],val)}
Psvg.prototype.xygl=function(x,y,gl){var xy=getorig();ps_flush();abcobj.xygl((x+xy[0])*abcobj.stv_g().scale,y-xy[1],gl)}
Psvg.prototype.xygls=function(str,x,y,gl){var xy=getorig();ps_flush();abcobj.out_deco_str((x+xy[0])*abcobj.stv_g().scale,y-xy[1],gl,str)}
Psvg.prototype.xyglv=function(val,x,y,gl){var xy=getorig();ps_flush();abcobj.out_deco_val((x+xy[0])*abcobj.stv_g().scale,y-xy[1],gl,val)}
Psvg.prototype.y0=function(y){var staff_tb=abcobj.get_staff_tb()
return y+staff_tb[0].y}
Psvg.prototype.y1=function(y){var staff_tb=abcobj.get_staff_tb()
return y+staff_tb[1].y}
function ps_flush(g0){if(g0)
setg(0);if(!svgbuf)
return
abcobj.out_svg(svgbuf);svgbuf=''}
Psvg.prototype.ps_flush=ps_flush
Psvg.prototype.ps_eval=function(txt){wps.parse(txt);ps_flush(true)}
function pscall(f,x,y,script){gcur.xorig=gcur.xoffs=abcobj.sx(0);gcur.yorig=gcur.yoffs=abcobj.sy(0);gcur.cx=0;gcur.cy=0;wps.parse(script+
(x/abcobj.stv_g().scale).toFixed(1)+' '+y.toFixed(1)+' '+f);ps_flush(true)
return true}
Psvg.prototype.psdeco=function(x,y,de){var dd,de2,script,defl,f=de.dd.glyph,Os=wps.parse('/'+f+' where'),A=Os.pop(),staff_tb=abcobj.get_staff_tb()
if(!A)
return false;defl=0
if(de.defl.nost)
defl=1
if(de.defl.noen)
defl|=2
if(de.s.stem>=0)
defl|=4;Os.pop();script='/defl '+defl+' def '
if(de.lden){script+=x.toFixed(1)+' '+y.toFixed(1)+' ';de2=de.start;x=de2.x;y=de2.y+staff_tb[de2.st].y
if(x>de.x-20)
x=de.x-20}
dd=de.dd
if(de.has_val){script+=de.val+' '}else if(dd.str){script+='('+dd.str+') ';y+=dd.h*0.2}
return pscall(f,x,y,script)}
Psvg.prototype.psxygl=function(x,y,gl){var Os=wps.parse('/'+gl+' where'),A=Os.pop()
if(!A)
return false
Os.pop()
return pscall(gl,x,y,'dlw ')}
Psvg.prototype.svgcall=function(f,x,y,v1,v2){var xy=getorig();ps_flush();f((x+xy[0])*abcobj.stv_g().scale,y-xy[1],v1,v2)}
wps.parse("\
currentdict/systemdict currentdict put\n\
systemdict/{/mark cvx put\n\
systemdict/[/mark cvx put\n\
systemdict/]\n\
/counttomark cvx\n\
/array cvx\n\
/astore cvx\n\
/exch cvx\n\
/pop cvx\n\
5 array astore cvx put\n\
systemdict/}/] cvx/cvx cvx 2 array astore cvx put\n\
systemdict/def{currentdict 2 index 2 index put pop pop}put\n\
\n\
/maxlength 1000 def % TODO\n\
/.bdef{bind def}bind def\n\
/.xdef{exch def}.bdef\n\
/dup{0 index}.bdef\n\
/load{dup where pop exch get}.bdef\n\
/.ldef{load def}.bdef\n\
/if{{}ifelse}.bdef\n\
/cleartomark{array pop}.bdef\n\
/known{exch begin where{currentdict eq}{false}if end}.bdef\n\
/store{1 index where{3 1 roll put}{def}ifelse}.bdef\n\
/not{{false}{true}ifelse}.bdef\n\
%/.logand{{{true}{false}ifelse}{pop false}ifelse}.bdef\n\
%/and/.logand .ldef % TODO numeric and\n\
/.logor{{pop true}{{true}{false}ifelse}ifelse}.bdef\n\
/or/.logor .ldef % TODO numeric or\n\
/ne{eq not}.bdef\n\
/ge{lt not}.bdef\n\
/le{1 index 1 index eq 3 1 roll lt or}.bdef\n\
/gt{le not}.bdef\n\
/.repeat{1 1 4 2 roll for}.bdef\n\
\n\
%% math\n\
\n\
/floor{.math(floor)1 .call}.bdef\n\
\n\
/neg{0 exch sub}.bdef\n\
/add{neg sub}.bdef\n\
/idiv{div floor}.bdef\n\
\n\
/.pi{.math(PI)get}.bdef\n\
\n\
/abs{.math(abs)1 .call}.bdef\n\
%/.acos{.math(acos)1 .call}.bdef\n\
%/.asin{.math(asin)1 .call}.bdef\n\
/atan{.math(atan2)2 .call 180 mul .pi div}.bdef\n\
%/.atan2{.math(atan2)2 .call}.bdef\n\
%/ceiling{.math(ceil)1 .call}.bdef\n\
/cos{.pi mul 180 div .math(cos)1 .call}.bdef\n\
%/.exp{.math(exp)1 .call}.bdef\n\
%/log{.math(log)1 .call}.bdef\n\
%/.max{.math(max)2 .call}.bdef\n\
%/.min{.math(min)2 .call}.bdef\n\
%/.pow{.math(pow)2 .call}.bdef\n\
%/.random{.math(random)0 .call}.bdef\n\
%/rand{.random}.bdef % TODO follow spec\n\
%/round{.math(round)1 .call}.bdef\n\
%/sin{.math(sin)1 .call}.bdef\n\
%/sqrt{.math(sqrt)1 .call}.bdef\n\
%/.tan{.math(tan)1 .call}.bdef\n\
%/truncate{.math(truncate)1 .call}.bdef % TODO Math.truncate does not exist!\n\
\n\
% graphic\n\
/arc{.svg(arc)5 .call0}.bdef\n\
/arcn{.svg(arcn)5 .call0}.bdef\n\
/closepath{.svg(closepath)0 .call}.bdef\n\
/currentpoint{.svg(cx)0 .call .svg(cy)0 .call}.bdef\n\
/curveto{.svg(curveto)6 .call0}.bdef\n\
/eofill{.svg(eofill)0 .call0}.bdef\n\
/fill{.svg(fill)0 .call0}.bdef\n\
/grestore{.svg(grestore)0 .call0}.bdef\n\
/gsave{.svg(gsave)0 .call0}.bdef\n\
/lineto{.svg(lineto)2 .call0}.bdef\n\
/moveto{.svg(moveto)2 .call0}.bdef\n\
/newpath{.svg(newpath)0 .call0}.bdef\n\
/rcurveto{.svg(rcurveto)6 .call0}.bdef\n\
/rlineto{.svg(rlineto)2 .call0}.bdef\n\
/rmoveto{.svg(rmoveto)2 .call0}.bdef\n\
/rotate{.svg(rotate)1 .call0}.bdef\n\
/scale{.svg(scale)2 .call0}.bdef\n\
/selectfont{.svg(selectfont)2 .call0}.bdef\n\
/setdash{.svg(setdash)2 .call0}.bdef\n\
/setlinewidth{.svg(setlinewidth)1 .call0}.bdef\n\
/setrgbcolor{.svg(setrgbcolor)3 .call0}.bdef\n\
/show{.svg(show)1 .call0}.bdef\n\
/stroke{.svg(stroke)0 .call0}.bdef\n\
/stringwidth{.svg(strw)1 .call 1}.bdef  %fixme: height KO\n\
/translate{.svg(translate)2 .call0}.bdef\n\
\n\
/setgray{255 mul dup dup setrgbcolor}.bdef\n\
% abcm2ps syms.c\n\
/!{bind def}bind def\n\
/T/translate load def\n\
/M/moveto load def\n\
/RM/rmoveto load def\n\
/L/lineto load def\n\
/RL/rlineto load def\n\
/C/curveto load def\n\
/RC/rcurveto load def\n\
/SLW/setlinewidth load def\n\
/defl 0 def\n\
/dlw{0.7 SLW}!\n\
/xymove{/x 2 index def/y 1 index def M}!\n\
/showc{dup stringwidth pop .5 mul neg 0 RM show}!\n\
%\n\
% abcm2ps internal glyphs\n\
/arp{.svg(arp)3 .call0}.bdef\n\
/ltr{.svg(ltr)3 .call0}.bdef\n\
/ft0{(acc-1).svg(xygl)3 .call0}.bdef\n\
/nt0{(acc3).svg(xygl)3 .call0}.bdef\n\
/sh0{(acc1).svg(xygl)3 .call0}.bdef\n\
/dsh0{(acc2).svg(xygl)3 .call0}.bdef\n\
/trl{(trl).svg(xygl)3 .call0}.bdef\n\
/lmrd{(lmrd).svg(xygl)3 .call0}.bdef\n\
/turn{(turn).svg(xygl)3 .call0}.bdef\n\
/umrd{(umrd).svg(xygl)3 .call0}.bdef\n\
/y0{.svg(y0)1 .call}.bdef\n\
/y1{.svg(y1)1 .call}.bdef\n")}
abc2svg.psvg={do_begin_end:function(of,type,opt,text){if(type!="ps"){of(type,opt,text)
return}
if(opt=='nosvg')
return
if(!this.psvg)
this.psvg=new Psvg(this);this.psvg.ps_eval.call(this.psvg,text)},psdeco:function(of,x,y,de){if(!this.psvg)
return false
return this.psvg.psdeco.call(this.psvg,x,y,de)},psxygl:function(of,x,y,gl){if(!this.psvg)
return false
return this.psvg.psxygl.call(this.psvg,x,y,gl)},set_hooks:function(abc){abc.do_begin_end=abc2svg.psvg.do_begin_end.bind(abc,abc.do_begin_end);abc.psdeco=abc2svg.psvg.psdeco.bind(abc,abc.psdeco);abc.psxygl=abc2svg.psvg.psxygl.bind(abc,abc.psxygl)}}
if(!abc2svg.mhooks)
abc2svg.mhooks={}
abc2svg.mhooks.psvg=abc2svg.psvg.set_hooks
