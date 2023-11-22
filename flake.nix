{
  description = "A Haskell kernel for IPython.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
    nixpkgsMaster.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    hls.url = "github:haskell/haskell-language-server";
  };

  outputs = { self, hls, nixpkgs, nixpkgsMaster, flake-utils, ... }:
    # "x86_64-darwin" "aarch64-darwin"
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs { inherit system; };
      pkgsMaster = import nixpkgsMaster { inherit system; };

      # release = import ./nix/release.nix;
      release810 = import ./nix/release-8.10.nix;
      release90 = import ./nix/release-9.0.nix;
      release92 = import ./nix/release-9.2.nix;
      release94 = import ./nix/release-9.4.nix;
      release96 = import ./nix/release-9.6.nix;
      release98 = import ./nix/release-9.8.nix;

      mkEnv = nixpkgsSrc: releaseFn: hsPkgs: displayPkgs:
        releaseFn {
          inherit nixpkgsSrc;
          system = system;
          packages = displayPkgs;
          systemPackages = p: with p; [
            gnuplot # for the ihaskell-gnuplot runtime
          ];
        };

      mkExe = nixpkgsSrc: releaseFn: hsPkgs: (mkEnv nixpkgsSrc releaseFn hsPkgs (_:[])).ihaskellExe;

      inherit (pkgs.haskell.packages) ghc88 ghc810 ghc90 ghc92;
      inherit (pkgsMaster.haskell.packages) ghc94 ghc96 ghc98;

      # mkDevShell = nixpkgsSrc: hsPkgs:
      #   let
      #     compilerVersion = compilerVersionFromHsPkgs hsPkgs;
      #     devIHaskell = hsPkgs.developPackage {
      #       root =  pkgs.lib.cleanSource ./.;
      #       name = "ihaskell";
      #       returnShellEnv = false;
      #       modifier = pkgs.haskell.lib.dontCheck;
      #       overrides = (mkEnv nixpkgsSrc release hsPkgs (_:[])).ihaskellOverlay ;
      #       withHoogle = true;
      #     };

      #     devModifier = drv:
      #       pkgs.haskell.lib.addBuildTools drv (with hsPkgs; [
      #         cabal-install
      #         (pkgs.python3.withPackages (p: [p.jupyterlab]))
      #         self.inputs.hls.packages.${system}."haskell-language-server-${compilerVersion}"
      #         pkgs.cairo # for the ihaskell-charts HLS dev environment
      #         pkgs.pango # for the ihaskell-diagrams HLS dev environment
      #         pkgs.lapack # for the ihaskell-plot HLS dev environment
      #         pkgs.blas # for the ihaskell-plot HLS dev environment
      #       ]);
      #   in
      #     (devModifier devIHaskell).envFunc {withHoogle=true;};

      exes = rec {
        # ihaskell-ghc88  = mkExe release   ghc88;
        ihaskell-ghc810 = mkExe nixpkgs release810 ghc810;
        ihaskell-ghc90  = mkExe nixpkgs release90 ghc90;
        ihaskell-ghc92  = mkExe nixpkgs release92 ghc92;
        ihaskell-ghc94  = mkExe nixpkgsMaster release94 ghc94;
        ihaskell-ghc96  = mkExe nixpkgsMaster release96 ghc96;
        ihaskell-ghc98  = mkExe nixpkgsMaster release98 ghc98;
        ihaskell        = ihaskell-ghc810;
      };

    in {
      packages = exes // rec {
        # Development environment
        # ihaskell-dev-88  = mkDevShell nixpkgs ghc88;
        # ihaskell-dev-810 = mkDevShell nixpkgs ghc810;
        # ihaskell-dev-90  = mkDevShell nixpkgs ghc90;
        # ihaskell-dev-92  = mkDevShell nixpkgs ghc92;
        # ihaskell-dev-94  = mkDevShell nixpkgs ghc94;
        # ihaskell-dev-96  = mkDevShell nixpkgs ghc96;
        # ihaskell-dev-98  = mkDevShell nixpkgsMaster ghc98;
        # ihaskell-dev     = ihaskell-dev-96;

        all = pkgs.linkFarm "ihaskell-exes" exes;

        # Full Jupyter environment with all Display modules (build is not incremental)
        # result/bin/jupyter-lab
        # ihaskell-env-display = mkEnv ghc810 (p: with p; [
        #   ihaskell-aeson
        #   ihaskell-blaze
        #   ihaskell-charts
        #   ihaskell-diagrams
        #   ihaskell-gnuplot
        #   ihaskell-graphviz
        #   ihaskell-hatex
        #   ihaskell-juicypixels
        #   ihaskell-magic
        #   ihaskell-plot
        #   ihaskell-widgets
        # ]);
      };

      defaultPackage = self.packages.${system}.ihaskell;

      # devShell = self.packages.${system}.ihaskell-dev;
    });
}
