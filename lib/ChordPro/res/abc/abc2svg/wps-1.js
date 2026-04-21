// wps.js
// (c) 2009 Tomas Hlavaty
// reference: http://logand.com/sw/wps/log.html

function isQuoted(V) {
  return V.q;
}

function quote(V) {
  V.q = true;
  return V;
}

function unquote(V) {
  delete V.q;
  return V;
}

function Symbol(N) {
  this.nm = N;
  return this;
}

function isSymbol(V) {
  return V &&  V.constructor === Symbol;
}

function symbolName(V) {
  return V.nm;
}

function isArray(V) {
  return V &&  V.constructor === Array;
}

function inDs(Ds, K) {
  for(var I = Ds.length - 1; 0 <= I; --I) {
	if("undefined" != typeof Ds[I][K])
	  return Ds[I];
  }
  return false;
}

function member(C, L) {
  return 0 <= L.indexOf(C);
}

function PsParser() {
  var Self = this;
  function init(L) {
    Self.L = L;
    Self.N = L.length;
    Self.I = 0;
    Self.D = 0;
  }
  function peek() {return Self.I < Self.N && Self.L[Self.I];}
  function xchar() {return Self.I < Self.N && Self.L[Self.I++];}
  function skip() { // TODO white space ffeed + null???
    while(Self.I < Self.N && member(Self.L[Self.I], " \t\n"))
      Self.I++;
  }
  function comment() {
    while("%" == peek()) {
      while(peek() && "\n" != peek())
        xchar();
      skip();
    }
  }
  function text() {
    // TODO hex text in <>
    // TODO ASCII base-85 <~ and ~>
    xchar();
    var L = [];
    var N = 1;
    while(0 < N && peek()) {
      var C = xchar();
      switch(C) {
        case "(":
          N++;
          break;
        case ")":
          N--;
          if(N <= 0) C = false;
          break;
        case "\\":
          C = xchar();
          switch(C) {
            case "(": break;
            case ")": break;
            case "\\": break;
            case "n": C = "\n"; break;
            case "r": C = "\r"; break;
            case "t": C = "\t"; break;
            // TODO \n (ignore \n) \b \f \ddd octal
            default:
              C = false;
          }
          break;
      }
      if(C !== false) L.push(C);
    }
    return L.join("");
  }
  function symbol() {
    // TODO 1e10 1E-5 real numbers
    // TODO radix numbers 8#1777 16#FFFE 2#1000
    var C = xchar();
    if(member(C, "()<>/% \t\n")) throw new Error("Symbol expected, got " + C);
    var N = member(C, "+-0123456789.");
    var F = "." == C;
    var L = [C];
    while(peek() && !member(peek(), "()<>[]{}/% \t\n")) {
      C = xchar();
      L.push(C);
      if(N && !member(C, "0123456789")) {
        if(!F && "." == C) F = true;
        else N = false;
      }
    }
    L = L.join("");
    if(1 == L.length && member(L, "+-.")) N = false;
    return N ? (F ? parseFloat(L) : parseInt(L, 10)) : new Symbol(L);
  }
  function token() {
    skip();
    switch(peek()) { // TODO read dict in <> <~~> <<>> immediate literal //
      case false: return undefined;
      case "%": return comment();
      case "[": return new Symbol(xchar());
      case "]": return new Symbol(xchar());
      case "{": Self.D++; return new Symbol(xchar());
      case "}": Self.D--; return new Symbol(xchar());
      case "/": xchar(); var X = symbol(); return quote(X);
      case "(": return text();
      case "<":
        xchar();
        if("<" != peek()) throw new Error("Encoded strings not implemented yet");
        xchar();
        return new Symbol("<<");
      case ">":
        xchar();
        if(">" != peek()) throw new Error("Unexpected >");
        xchar();
        return new Symbol(">>");
      default: return symbol();
    }
  }
  PsParser.prototype.init = init;
  PsParser.prototype.peek = peek;
  PsParser.prototype.token = token;
  return this;
}

function Ps0(Os, Ds, Es) {
  function run(X, Z) {
    if(isSymbol(X) && !isQuoted(X)) { // executable name
      var K = symbolName(X);
      var D = inDs(Ds, K);
      if(!D)
        throw new Error("bind error '" + K + "'");
      Es.push([false, D[K]]);
    } else if(Z && isArray(X) && isQuoted(X)) { // proc from Es
      if(0 < X.length) {
        var F = X[0];
        var R = quote(X.slice(1));
        if(0 < R.length) Es.push([false, R]);
        run(F, false);
      }
    } else if("function" == typeof X) X(); // operator
    else Os.push(X);
  }
  function exec() {
    var X = Os.pop();
    run(X, false);
  }
  function step() {
    var C = Es.pop();
    var L = C.shift(); // TODO use for 'exit'
    var X = C.pop();
    for(var I = 0; I < C.length; I++)
      Os.push(C[I]);
    run(X, true);
  }
  var PsP = new PsParser;
  function parse(L) {
    PsP.init(L);
    while(PsP.peek()) {
      var T = PsP.token();
      if(T || T === 0) {
        Os.push(T);
        if(PsP.D <= 0 || isSymbol(T) &&
           (member(symbolName(T), "[]{}") ||
            "<<" == symbolName(T) || ">>" == symbolName(T))) {
          exec();
          while(0 < Es.length)
            step();
        }
      }
    }
    return Os;
  }
  Ps0.prototype.run = run;
  Ps0.prototype.exec = exec;
  Ps0.prototype.step = step;
  Ps0.prototype.parse = parse;
  return this;
}

function Wps(psvg_i) {
	var psvg = psvg_i;
  var Os = [];
  var Sd = {};
  var Ds = [Sd];
  var Es = [];
  var Ps = new Ps0(Os, Ds, Es);

  // trivial
  Sd["true"] = function() {Os.push(true);};
  Sd["false"] = function() {Os.push(false);};
  Sd["null"] = function() {Os.push(null);};
  // math
  Sd["sub"] = function() {var X = Os.pop(); Os.push(Os.pop() - X);};
  Sd["mul"] = function() {Os.push(Os.pop() * Os.pop());};
  Sd["div"] = function() {var X = Os.pop(); Os.push(Os.pop() / X);};
  Sd["mod"] = function() {var X = Os.pop(); Os.push(Os.pop() % X);};
  // stack
  var M = {};
  Sd["mark"] = function() {Os.push(M);};
  Sd["counttomark"] = function() {
    var N = 0;
    for(var I = Os.length - 1; 0 <= I; I--)
      if(M === Os[I]) return Os.push(N);
      else N++;
    throw new Error("Mark not found");
  };
  Sd["<<"] = Sd["mark"]; // TODO doc
  Sd[">>"] = function() { // TODO doc
    var D = {};
    while(0 < Os.length) {
      var V = Os.pop();
      if(M === V) return Os.push(D);
      D[Os.pop()] = V;
    }
    throw new Error("Mark not found");
  };
  Sd["exch"] = function() {
    var Y = Os.pop();
    var X = Os.pop();
    Os.push(Y);
    Os.push(X);
  };
  Sd["clear"] = function() {Os.length = 0;};
  Sd["pop"] = function() {Os.pop();};
  Sd["index"] = function() {
    Os.push(Os[Os.length - 2 - Os.pop()]);
  };
  Sd["roll"] = function() { // TODO in ps
    var J = Os.pop();
    var N = Os.pop();
    var X = [];
    var Y = [];
//jfm patch
    if (J < 0)
    	J = N + J
    for(var I = 0; I < N; I++)
      if(I < J) X.unshift(Os.pop());
      else Y.unshift(Os.pop());
    for(I = 0; I < J; I++) Os.push(X.shift());
    for(I = 0; I < N - J; I++) Os.push(Y.shift());
  };
  Sd["copy"] = function() {
	var N = Os.pop();
	if("object" == typeof N) {
	  var X = Os.pop();
	  for(var I in X)
        N[I] = X[I];
      Os.push(N);
    } else {
      var X = Os.length - N;
      for(var I = 0; I < N; I++)
        Os.push(Os[X + I]);
    }
  };
  // array
  Sd["length"] = function() {Os.push(Os.pop().length);};
  Sd["astore"] = function() {
    var A = Os.pop();
    var N = A.length;
    for(var I = N - 1; 0 <= I; I--)
      A[I] = Os.pop();
    Os.push(A);
  };
  Sd["array"] = function() {Os.push(new Array(Os.pop()));};
  // conditionals
  Sd["eq"] = function() {var Y = Os.pop(); var X = Os.pop(); Os.push(X == Y);};
  Sd["lt"] = function() {var Y = Os.pop(); var X = Os.pop(); Os.push(X < Y);};
  // control
  Sd["ifelse"] = function() {
    var N = Os.pop();
    var P = Os.pop();
    var C = Os.pop();
    Es.push([false, C === true ? P : N]);
  };
//jfm++
	Sd["and"] = function() {
		var A = Os.pop();
		var B = Os.pop();
		if (true === A || false === A) {
			Os.push(A == true && B === true)
			return
		}
		Os.push(A & B)
	}
//jfm--
  Sd["repeat"] = function Xrepeat() { // TODO in ps
    var B = Os.pop();
    var N = Os.pop();
    if(1 < N) Es.push([true, N - 1, B, Xrepeat]);
    if(0 < N) Es.push([false, B]);
  };
  Sd["for"] = function Xfor() { // TODO in ps
    var B = Os.pop();
    var L = Os.pop();
    var K = Os.pop();
    var J = Os.pop();
    if(K < 0) {
      if(L <= J + K) Es.push([true, J + K, K, L, B, Xfor]);
      if(L <= J) Es.push([false, J, B]);
    } else {
      if(J + K <= L) Es.push([true, J + K, K, L, B, Xfor]);
      if(J <= L) Es.push([false, J, B]);
    }
  };
  Sd["exec"] = function() {Es.push([false, Os.pop()]);};
  Sd["cvx"] = function() {
    var X = Os.pop();
    if(isSymbol(X) && isQuoted(X)) Os.push(unquote(X)); // executable name
    else if(isArray(X) && !isQuoted(X)) Os.push(quote(X)); // proc
    // TODO string -> parse
    else Os.push(X);
  };
  // dictionary
  Sd["dict"] = function() {Os.pop(); Os.push({});};
  Sd["get"] = function() {
    var K = Os.pop();
    var D = Os.pop();
    // TODO other datatypes
    if(isSymbol(K)) Os.push(D[symbolName(K)]);
    else Os.push(D[K]);
  };
  Sd["getinterval"] = function() {
    var N = Os.pop(),
	K = Os.pop() + N,
	D = Os.pop(),
	A = []
	while (--N >= 0)
		A.push(D[K++])
	Os.push(A);
  };
  Sd["put"] = function() {
    var V = Os.pop();
    var K = Os.pop();
    var D = Os.pop();
    // TODO other datatypes
    if(isSymbol(K)) D[symbolName(K)] = V;
    else D[K] = V;
  };
  Sd["begin"] = function() {Ds.push(Os.pop());};
  Sd["end"] = function() {Ds.pop();};
  Sd["currentdict"] = function() {Os.push(Ds[Ds.length - 1]);};
  Sd["where"] = function() {
    var K = symbolName(Os.pop());
    var D = inDs(Ds, K);
	if(D) {
	  Os.push(D);
	  Os.push(true);
	} else Os.push(false);
  };
  // miscellaneous
  Sd["save"] = function() {
    var X = Ds.slice();
    for(var I = 0; I < X.length; I++) {
      var A = X[I];
      var B = {};
      for(var J in A)
        B[J] = A[J];
      X[I] = B;
    }
    Os.push(X);
  };
  Sd["restore"] = function() {
    var X = Os.pop();
    while(0 < Ds.length)
      Ds.pop();
    while(0 < X.length)
      Ds.unshift(X.pop());
  };
  Sd["type"] = function() {
    var A = Os.pop();
    var X;
    if(null === A) X = "nulltype";
    else if(true === A || false === A) X = "booleantype";
    else if(M === A) X = "marktype";
    else if("string" == typeof A) X = "stringtype";
    else if(isSymbol(A)) X = isQuoted(A) ? "nametype" : "operatortype";
    else if("function" == typeof A) X = "operatortype";
    else if(isArray(A)) X = "arraytype";
    else if("object" == typeof A) X = "dicttype";
    else if(1 * A == A) X = A % 1 == 0 ? "integertype" : "realtype";
    else throw new Error("Undefined type '" + A + "'");
    Os.push(X);
    // filetype
    // packedarraytype (LanguageLevel 2)
    // fonttype
    // gstatetype (LanguageLevel 2)
    // savetype
  };
  var Sb = true;
  Sd[".strictBind"] = function() {Sb = true === Os.pop();};
  Sd["bind"] = function() {Os.push(bind(Os.pop()));};
  function bind(X) {
    if(isSymbol(X) && !isQuoted(X)) {
//jfm++
//      var K = symbolName(X);
//      var D = inDs(Ds, K);
//      if(Sb) {
//        if(!D)
//          throw new Error("bind error '" + K + "'");
//        return bind(D[K]);
//      } else return !D ? X : bind(D[K]);
	return X
//jfm--
    } else if(isArray(X) && isQuoted(X)) {
      var N = X.length;
      var A = [];
      for(var I = 0; I < N; I++) {
        var Xi = X[I];
        var Xb = bind(Xi);
        if(isArray(Xi))
          A = A.concat(isQuoted(Xi) ? quote([Xb]) : [Xb]);
        else
          A = A.concat(Xb);
      }
      return quote(A);
    }
    return X;
  }
  // debugging
  Sd["="] = function() {var X = Os.pop(); alert(X && X.nm || X);}; // TODO
  Sd["=="] = function() {alert(Os.pop());}; // TODO
  Sd["stack"] = function() {alert(Os);}; // TODO
  Sd["pstack"] = function() {alert(Os);}; // TODO
  // js ffi
  Sd[".call"] = function() {
    var N = Os.pop();
    var K = Os.pop();
    var D = Os.pop();
    var X = [];
    for(var I = 0; I < N; I++) X.unshift(Os.pop());
    if (!D[K]) throw new Error(".call: " + K + " undef")
    Os.push(D[K].apply(D, X));
  };
//jfm++
  Sd[".call0"] = function() {
    var N = Os.pop(),
	K = Os.pop(),
	D = Os.pop(),
	X = []
    for(var I = 0; I < N; I++) X.unshift(Os.pop());
    if (!D[K]) throw new Error(".call0: " + K + " undef")
    D[K].apply(D, X);
  };
  Sd[".svg"] = function() {Os.push(psvg)};
//jfm--
  Sd[".math"] = function() {Os.push(Math);};
  Sd[".date"] = function() {Os.push(new Date());}; // TODO split new and Date
  Sd[".window"] = function() {Os.push(window);};
  Sd[".callback"] = function() { // TODO event arg?
    var X = Os.pop();
    Os.push(function() {
              Ps.run(X, true);
              while(0 < Es.length)
                Ps.step();
            });
  };
  // html5
  Sd[".minv"] = function() { // TODO in ps
    var M = Os.pop();
    var a = M[0]; var b = M[1];
    var d = M[2]; var e = M[3];
    var g = M[4]; var h = M[5];
    Os.push([e, b, d, a, d*h-e*g, b*g-a*h]);
  };
  Sd[".mmul"] = function() { // TODO in ps
    var B = Os.pop();
    var A = Os.pop();
    var a = A[0]; var b = A[1];
    var d = A[2]; var e = A[3];
    var g = A[4]; var h = A[5];
    var r = B[0]; var s = B[1];
    var u = B[2]; var v = B[3];
    var x = B[4]; var y = B[5];
    Os.push([a*r+b*u, a*s+b*v, d*r+e*u, d*s+e*v, g*r+h*u+x, g*s+h*v+y]);
  };
  Sd[".xy"] = function() { // TODO in ps
    var M = Os.pop();
    var Y = Os.pop();
    var X = Os.pop();
    Os.push(M[0] * X + M[2] * Y + M[4]);
    Os.push(M[1] * X + M[3] * Y + M[5]);
  };
  // TODO js ffi to manipulate strings so the following can be in ps
  Sd[".rgb"] = function() { // TODO in ps
    var B = Os.pop();
    var G = Os.pop();
    var R = Os.pop();
    Os.push("rgb(" + R + "," + G + "," + B + ")");
  };
  Sd[".rgba"] = function() { // TODO in ps
    var A = Os.pop();
    var B = Os.pop();
    var G = Os.pop();
    var R = Os.pop();
    Os.push("rgba(" + R + "," + G + "," + B + "," + A + ")");
  };

  function parse() {
    var T = arguments;
    if(T.length)
      for(var I = 0; I < T.length; I++)
        Ps.parse(T[I]);
    else Ps.parse(T);
    return Os;
  }
  Wps.prototype.parse = parse;
  return this;
}
