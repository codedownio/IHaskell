{
  description = "A Haskell kernel for IPython.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    hls.url = "github:haskell/haskell-language-server";
  };

  outputs = { self, hls, nixpkgs, flake-utils, ... }:
    # "x86_64-darwin" "aarch64-darwin"
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs { inherit system; };

      compilerVersionFromHsPkgs = hsPkgs:
        pkgs.lib.replaceStrings [ "." ] [ "" ] hsPkgs.ghc.version;

      release = import ./nix/release.nix;
      release90 = import ./nix/release-9.0.nix;
      release92 = import ./nix/release-9.2.nix;
      release94 = import ./nix/release-9.4.nix;
      release96 = import ./nix/release-9.6.nix;

      mkEnv = releaseFn: hsPkgs: displayPkgs:
        releaseFn {
          compiler = "ghc${compilerVersionFromHsPkgs hsPkgs}";
          nixpkgs = pkgs;
          packages = displayPkgs;
          systemPackages = p: with p; [
            gnuplot # for the ihaskell-gnuplot runtime
          ];
        };

      mkExe = releaseFn: hsPkgs: (mkEnv releaseFn hsPkgs (_:[])).ihaskellExe;

      inherit (pkgs.haskell.packages) ghc88 ghc810 ghc90 ghc92 ghc94 ghc96;

      mkDevShell = hsPkgs:
        let
          compilerVersion = compilerVersionFromHsPkgs hsPkgs;
          devIHaskell = hsPkgs.developPackage {
            root =  pkgs.lib.cleanSource ./.;
            name = "ihaskell";
            returnShellEnv = false;
            modifier = pkgs.haskell.lib.dontCheck;
            overrides = (mkEnv release hsPkgs (_:[])).ihaskellOverlay ;
            withHoogle = true;
          };

          devModifier = drv:
            pkgs.haskell.lib.addBuildTools drv (with hsPkgs; [
              cabal-install
              (pkgs.python3.withPackages (p: [p.jupyterlab]))
              self.inputs.hls.packages.${system}."haskell-language-server-${compilerVersion}"
              pkgs.cairo # for the ihaskell-charts HLS dev environment
              pkgs.pango # for the ihaskell-diagrams HLS dev environment
              pkgs.lapack # for the ihaskell-plot HLS dev environment
              pkgs.blas # for the ihaskell-plot HLS dev environment
            ]);
        in
          (devModifier devIHaskell).envFunc {withHoogle=true;};

      exes = rec {
        # ihaskell-ghc88  = mkExe release   ghc88;
        ihaskell-ghc810 = mkExe release   ghc810;
        ihaskell-ghc90  = mkExe release90 ghc90;
        ihaskell-ghc92  = mkExe release92 ghc92;
        ihaskell-ghc94  = mkExe release94 ghc94;
        ihaskell-ghc96  = mkExe release96 ghc96;
        ihaskell        = ihaskell-ghc810;
      };

    in {
      packages = exes // rec {
        # Development environment
        ihaskell-dev-88  = mkDevShell ghc88;
        ihaskell-dev-810 = mkDevShell ghc810;
        ihaskell-dev-90  = mkDevShell ghc90;
        ihaskell-dev-92  = mkDevShell ghc92;
        ihaskell-dev-94  = mkDevShell ghc94;
        ihaskell-dev-96  = mkDevShell ghc96;
        ihaskell-dev     = ihaskell-dev-810;

        all = pkgs.linkFarm "ihaskell-exes" exes;

        # Full Jupyter environment with all Display modules (build is not incremental)
        # result/bin/jupyter-lab
        ihaskell-env-display = mkEnv ghc810 (p: with p; [
          ihaskell-aeson
          ihaskell-blaze
          ihaskell-charts
          ihaskell-diagrams
          ihaskell-gnuplot
          ihaskell-graphviz
          ihaskell-hatex
          ihaskell-juicypixels
          ihaskell-magic
          ihaskell-plot
          ihaskell-widgets
        ]);
      };

      defaultPackage = self.packages.${system}.ihaskell;

      devShell = self.packages.${system}.ihaskell-dev;
    });
}
