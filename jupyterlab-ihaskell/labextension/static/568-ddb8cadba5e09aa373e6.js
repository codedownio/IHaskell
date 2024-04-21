"use strict";(self.webpackChunkjupyterlab_ihaskell=self.webpackChunkjupyterlab_ihaskell||[]).push([[568],{568:(e,t,r)=>{Object.defineProperty(t,"__esModule",{value:!0});const n=r(373),a=r(428),i=r(101),o={id:"ihaskell",autoStart:!0,description:"A CodeMirror extension for IHaskell",requires:[a.IEditorLanguageRegistry],activate:async(e,t)=>{const r=new n.LanguageSupport(n.StreamLanguage.define(i.haskell));t.addLanguage({name:"ihaskell",mime:"text/x-ihaskell",support:r,extensions:["hs"]})}};t.default=o},101:(e,t)=>{function r(e,t,r){return t(r),r(e,t)}Object.defineProperty(t,"__esModule",{value:!0});var n=/[a-z_]/,a=/[A-Z]/,i=/\d/,o=/[0-9A-Fa-f]/,l=/[0-7]/,u=/[a-z_A-Z0-9'\xa1-\uffff]/,s=/[-!#$%&*+.\/<=>?@\\^|~:]/,c=/[(),;[\]`{}]/,f=/[ \t\v\f]/;function d(e,t){if(e.eatWhile(f))return null;var d=e.next();if(c.test(d)){if("{"==d&&e.eat("-")){var p="comment";return e.eat("#")&&(p="meta"),r(e,t,h(p,1))}return null}if("'"==d)return e.eat("\\"),e.next(),e.eat("'")?"string":"error";if('"'==d)return r(e,t,m);if(a.test(d))return e.eatWhile(u),e.eat(".")?"qualifier":"type";if(n.test(d))return e.eatWhile(u),"variable";if(i.test(d)){if("0"==d){if(e.eat(/[xX]/))return e.eatWhile(o),"integer";if(e.eat(/[oO]/))return e.eatWhile(l),"number"}return e.eatWhile(i),p="number",e.match(/^\.\d+/)&&(p="number"),e.eat(/[eE]/)&&(p="number",e.eat(/[-+]/),e.eatWhile(i)),p}return"."==d&&e.eat(".")?"keyword":s.test(d)?"-"==d&&e.eat(/-/)&&(e.eatWhile(/-/),!e.eat(s))?(e.skipToEnd(),"comment"):(e.eatWhile(s),"variable"):"error"}function h(e,t){return 0==t?d:function(r,n){for(var a=t;!r.eol();){var i=r.next();if("{"==i&&r.eat("-"))++a;else if("-"==i&&r.eat("}")&&0==--a)return n(d),e}return n(h(e,a)),e}}function m(e,t){for(;!e.eol();){var r=e.next();if('"'==r)return t(d),"string";if("\\"==r){if(e.eol()||e.eat(f))return t(p),"string";e.eat("&")||e.next()}}return t(d),"error"}function p(e,t){return e.eat("\\")?r(e,t,m):(e.next(),t(d),"error")}var g=function(){var e={};function t(t){return function(){for(var r=0;r<arguments.length;r++)e[arguments[r]]=t}}return t("keyword")("case","class","data","default","deriving","do","else","foreign","if","import","in","infix","infixl","infixr","instance","let","module","newtype","of","then","type","where","_"),t("keyword")("..",":","::","=","\\","<-","->","@","~","=>"),t("builtin")("!!","$!","$","&&","+","++","-",".","/","/=","<","<*","<=","<$>","<*>","=<<","==",">",">=",">>",">>=","^","^^","||","*","*>","**"),t("builtin")("Applicative","Bool","Bounded","Char","Double","EQ","Either","Enum","Eq","False","FilePath","Float","Floating","Fractional","Functor","GT","IO","IOError","Int","Integer","Integral","Just","LT","Left","Maybe","Monad","Nothing","Num","Ord","Ordering","Rational","Read","ReadS","Real","RealFloat","RealFrac","Right","Show","ShowS","String","True"),t("builtin")("abs","acos","acosh","all","and","any","appendFile","asTypeOf","asin","asinh","atan","atan2","atanh","break","catch","ceiling","compare","concat","concatMap","const","cos","cosh","curry","cycle","decodeFloat","div","divMod","drop","dropWhile","either","elem","encodeFloat","enumFrom","enumFromThen","enumFromThenTo","enumFromTo","error","even","exp","exponent","fail","filter","flip","floatDigits","floatRadix","floatRange","floor","fmap","foldl","foldl1","foldr","foldr1","fromEnum","fromInteger","fromIntegral","fromRational","fst","gcd","getChar","getContents","getLine","head","id","init","interact","ioError","isDenormalized","isIEEE","isInfinite","isNaN","isNegativeZero","iterate","last","lcm","length","lex","lines","log","logBase","lookup","map","mapM","mapM_","max","maxBound","maximum","maybe","min","minBound","minimum","mod","negate","not","notElem","null","odd","or","otherwise","pi","pred","print","product","properFraction","pure","putChar","putStr","putStrLn","quot","quotRem","read","readFile","readIO","readList","readLn","readParen","reads","readsPrec","realToFrac","recip","rem","repeat","replicate","return","reverse","round","scaleFloat","scanl","scanl1","scanr","scanr1","seq","sequence","sequence_","show","showChar","showList","showParen","showString","shows","showsPrec","significand","signum","sin","sinh","snd","span","splitAt","sqrt","subtract","succ","sum","tail","take","takeWhile","tan","tanh","toEnum","toInteger","toRational","truncate","uncurry","undefined","unlines","until","unwords","unzip","unzip3","userError","words","writeFile","zip","zip3","zipWith","zipWith3"),e}();const k={name:"haskell",startState:function(){return{f:d}},copyState:function(e){return{f:e.f}},token:function(e,t){var r=t.f(e,(function(e){t.f=e})),n=e.current();return g.hasOwnProperty(n)?g[n]:r},languageData:{commentTokens:{line:"--",block:{open:"{-",close:"-}"}}}};t.haskell=k}}]);