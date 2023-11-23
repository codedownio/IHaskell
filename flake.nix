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

      versions = {
        ghc810 = import ./nix/release-8.10.nix { inherit system; nixpkgsSrc = nixpkgs; };
        ghc90 = import ./nix/release-9.0.nix { inherit system; nixpkgsSrc = nixpkgs; };
        ghc92 = import ./nix/release-9.2.nix { inherit system; nixpkgsSrc = nixpkgs; };
        ghc94 = import ./nix/release-9.4.nix { inherit system; nixpkgsSrc = nixpkgsMaster; };
        ghc96 = import ./nix/release-9.6.nix { inherit system; nixpkgsSrc = nixpkgsMaster; };
        ghc98 = import ./nix/release-9.8.nix { inherit system; nixpkgsSrc = nixpkgsMaster;  };
      };

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

      exes = pkgs.lib.mapAttrs' (version: releaseFn: {
        name = "ihaskell-" + version;
        value = (releaseFn {
          systemPackages = p: with p; [
            gnuplot # for the ihaskell-gnuplot runtime
          ];
        }).ihaskellExe;
      }) versions;

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

        allExes = pkgs.linkFarm "ihaskell-exes" exes;

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

      defaultPackage = self.packages.${system}.ihaskell-ghc810;

      # devShell = self.packages.${system}.ihaskell-dev;
    });
}
