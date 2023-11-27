{ callPackage
, haskell
, lib

, compiler
, enableHlint
}:

self: super:

let
  ihaskell-src = callPackage ./ihaskell-src.nix {};

  displays = let
    mkDisplay = display: {
      name = "ihaskell-${display}-" + compiler;
      value = self.callCabal2nix display "${ihaskell-src}/ihaskell-display/ihaskell-${display}" {};
    };
  in
    builtins.listToAttrs (map mkDisplay [
      "aeson"
      "blaze"
      "charts"
      "diagrams"
      "gnuplot"
      "graphviz"
      "hatex"
      "juicypixels"
      "magic"
      "plot"
      "rlangqq"
      "static-canvas"
      "widgets"
    ]);

in

{
  ihaskell = let
    baseIhaskell = haskell.lib.overrideCabal (self.callCabal2nix "ihaskell" ihaskell-src {}) (_drv: {
      preCheck = ''
        export HOME=$TMPDIR/home
        export PATH=$PWD/dist/build/ihaskell:$PATH
        export GHC_PACKAGE_PATH=$PWD/dist/package.conf.inplace/:$GHC_PACKAGE_PATH
      '';
      configureFlags = (_drv.configureFlags or []) ++ (lib.optionals (!enableHlint) [ "-f" "-use-hlint" ]);
    });
  in
    if enableHlint
    then baseIhaskell
    else baseIhaskell.overrideScope (self: super: { hlint = null; });

  ghc-parser     = self.callCabal2nix "ghc-parser" (builtins.path { path = ../ghc-parser; name = "ghc-parser-src"; }) {};
  ipython-kernel = self.callCabal2nix "ipython-kernel" (builtins.path { path = ../ipython-kernel; name = "ipython-kernel-src"; }) {};
} // displays
