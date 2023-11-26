{ compiler
, nixpkgs
, jupyterlab
, packages ? (_: [])
, rtsopts ? "-M3g -N2"
, staticExecutable ? false
, systemPackages ? (_: [])
, enableHlint ? true
}:

let
  ihaskell-src = nixpkgs.callPackage ./ihaskell-src.nix {};

  displays = self: builtins.listToAttrs (
    map
      (display: { name = "ihaskell-${display}-" + compiler; value = self.callCabal2nix display "${ihaskell-src}/ihaskell-display/ihaskell-${display}" {}; })
      [ "aeson" "blaze" "charts" "diagrams" "gnuplot" "graphviz" "hatex" "juicypixels" "magic" "plot" "rlangqq" "static-canvas" "widgets" ]);

  haskellPackages = nixpkgs.haskell.packages."${compiler}".override (old: {
    overrides = nixpkgs.lib.composeExtensions (old.overrides or (_: _: {})) ihaskellOverlay;
  });

  ihaskellOverlay = (self: super: {
    ihaskell = let
      baseIhaskell = nixpkgs.haskell.lib.overrideCabal (self.callCabal2nix "ihaskell" ihaskell-src {}) (_drv: {
        preCheck = ''
          export HOME=$TMPDIR/home
          export PATH=$PWD/dist/build/ihaskell:$PATH
          export GHC_PACKAGE_PATH=$PWD/dist/package.conf.inplace/:$GHC_PACKAGE_PATH
        '';
        configureFlags = (_drv.configureFlags or []) ++ (nixpkgs.lib.optionals (!enableHlint) [ "-f" "-use-hlint" ]);
      });
    in
      if enableHlint
      then baseIhaskell
      else baseIhaskell.overrideScope (self: super: { hlint = null; });

    ghc-parser     = self.callCabal2nix "ghc-parser" (builtins.path { path = ../ghc-parser; name = "ghc-parser-src"; }) {};
    ipython-kernel = self.callCabal2nix "ipython-kernel" (builtins.path { path = ../ipython-kernel; name = "ipython-kernel-src"; }) {};
  } // displays self);

  # statically linking against haskell libs reduces closure size at the expense
  # of startup/reload time, so we make it configurable
  ihaskellExe = if staticExecutable
                then nixpkgs.haskell.lib.justStaticExecutables haskellPackages.ihaskell
                else nixpkgs.haskell.lib.enableSharedExecutables haskellPackages.ihaskell;

  ihaskellEnv = haskellPackages.ghcWithPackages packages;

  ihaskellKernelSpecFunc = ihaskellGhcLib: rtsopts:
    let
      kernelFile = {
        display_name = "Haskell";
        argv = [
          "${ihaskellGhcLib}/bin/ihaskell"
          "kernel"
          "{connection_file}"
          "+RTS"
        ] ++ (nixpkgs.lib.splitString " " rtsopts) ++ [
          "-RTS"
        ];
        language = "haskell";
      };
    in
      nixpkgs.runCommand "ihaskell-kernel" {} ''
        export kerneldir=$out/kernels/haskell
        mkdir -p $kerneldir
        cp ${../html}/* $kerneldir
        echo '${builtins.toJSON kernelFile}' > $kerneldir/kernel.json
      '';

  ihaskellLabextension = nixpkgs.runCommand "ihaskell-labextension" {} ''
    mkdir -p $out/labextensions/
    ln -s ${../jupyterlab-ihaskell/labextension} $out/labextensions/jupyterlab-ihaskell
  '';

  ihaskellGhcLib = nixpkgs.writeShellScriptBin "ihaskell" ''
    ${ihaskellEnv}/bin/ihaskell -l $(${ihaskellEnv}/bin/ghc --print-libdir) "$@"
  '';

  ihaskellDataDir = nixpkgs.buildEnv {
    name = "ihaskell-data-dir-" + compiler;
    paths = [
      (ihaskellKernelSpecFunc ihaskellGhcLib rtsopts)
      ihaskellLabextension
    ];
  };

in

nixpkgs.buildEnv {
  name = "ihaskell-with-packages-" + compiler;
  nativeBuildInputs = [ nixpkgs.makeWrapper ];
  paths = [ ihaskellEnv jupyterlab ];
  postBuild = ''
    for prg in $out/bin"/"*;do
      if [[ -f $prg && -x $prg ]]; then
        wrapProgram $prg \
          --prefix PATH : "${nixpkgs.lib.makeBinPath ([ihaskellEnv] ++ (systemPackages nixpkgs))}" \
          --prefix JUPYTER_PATH : "${ihaskellDataDir}"
      fi
    done
  '';

  passthru = {
    inherit ihaskellExe;
  };
}
