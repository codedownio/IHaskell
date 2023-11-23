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

      envs = pkgs.lib.mapAttrs' (version: releaseFn: {
        name = "ihaskell-env-" + version;
        value = (releaseFn {
          jupyterlab = pkgsMaster.python3.withPackages (ps: [ ps.jupyterlab ps.notebook ]);
          systemPackages = p: with p; [
            gnuplot # for the ihaskell-gnuplot runtime
          ];
        });
      }) versions;

      exes = pkgs.lib.mapAttrs' (envName: env: {
        name = builtins.replaceStrings ["-env"] [""] envName;
        value = env.ihaskellExe;
      }) envs;

      devShells = pkgs.lib.mapAttrs' (version: releaseFn: {
        name = "ihaskell-dev-" + version;
        value = pkgs.callPackage ./nix/mkDevShell.nix {
          inherit hls system version;
          haskellPackages = (releaseFn {}).haskellPackages;
          ihaskellOverlay = (releaseFn {}).ihaskellOverlay;
        };
      }) versions;

    in {
      packages = envs // exes // devShells // rec  {
        # For easily testing that everything builds
        allEnvs = pkgs.linkFarm "ihaskell-envs" envs;
        allExes = pkgs.linkFarm "ihaskell-exes" exes;
        allDevShells = pkgs.linkFarm "ihaskell-dev-shells" devShells;

        # Full Jupyter environment with all Display modules (build is not incremental)
        # result/bin/jupyter-lab
        ihaskell-env-display = versions.ghc810 {
          packages = p: with p; [
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
          ];
        };
      };

      defaultPackage = self.packages.${system}.ihaskell-ghc810;

      devShell = self.packages.${system}.ihaskell-dev-ghc810;
    });
}
