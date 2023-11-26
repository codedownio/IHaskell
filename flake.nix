{
  description = "A Haskell kernel for IPython.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
  inputs.nixpkgsMaster.url = "github:NixOS/nixpkgs/master";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.hls.url = "github:haskell/haskell-language-server";
  inputs.nix-filter.url = "github:numtide/nix-filter";

  outputs = { self, nixpkgs, nixpkgsMaster, flake-utils, hls, nix-filter, ... }:
    # "x86_64-darwin" "aarch64-darwin"
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      baseOverlay = self: super: { inherit nix-filter; };
      pkgs = import nixpkgs { inherit system; overlays = [baseOverlay]; };
      pkgsMaster = import nixpkgsMaster { inherit system; overlays = [baseOverlay]; };

      versions = {
        ghc810 = import ./nix/release-8.10.nix { inherit system baseOverlay; nixpkgsSrc = nixpkgs; };
        ghc90 = import ./nix/release-9.0.nix { inherit system baseOverlay; nixpkgsSrc = nixpkgs; };
        ghc92 = import ./nix/release-9.2.nix { inherit system baseOverlay; nixpkgsSrc = nixpkgs; };
        ghc94 = import ./nix/release-9.4.nix { inherit system baseOverlay; nixpkgsSrc = nixpkgsMaster; };
        ghc96 = import ./nix/release-9.6.nix { inherit system baseOverlay; nixpkgsSrc = nixpkgsMaster; };
        ghc98 = import ./nix/release-9.8.nix { inherit system baseOverlay; nixpkgsSrc = nixpkgsMaster;  };
      };

      jupyterlab = pkgsMaster.python3.withPackages (ps: [ ps.jupyterlab ps.notebook ]);

      envs = pkgs.lib.mapAttrs' (version: releaseFn: {
        name = "ihaskell-env-" + version;
        value = (releaseFn {
          # Note: this can be changed to other Jupyter systems like jupyter-console
          extraEnvironmentBinaries = [ jupyterlab ];
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

        print-nixpkgs-stable = pkgs.writeShellScriptBin "print-nixpkgs-stable.sh" "echo ${pkgs.path}";
        print-nixpkgs-master = pkgs.writeShellScriptBin "print-nixpkgs-master.sh" "echo ${pkgsMaster.path}";
        inherit jupyterlab;

        # Full Jupyter environment with all Display modules (build is not incremental)
        # result/bin/jupyter-lab
        # ihaskell-env-display = versions.ghc810 {
        #   packages = p: with p; [
        #     ihaskell-aeson
        #     ihaskell-blaze
        #     ihaskell-charts
        #     ihaskell-diagrams
        #     ihaskell-gnuplot
        #     ihaskell-graphviz
        #     ihaskell-hatex
        #     ihaskell-juicypixels
        #     ihaskell-magic
        #     ihaskell-plot
        #     ihaskell-widgets
        #   ];
        # };
      };

      checks = pkgs.lib.mapAttrs (envName: env:
        pkgs.stdenv.mkDerivation {
          name = envName + "-check";
          src = pkgs.callPackage ./nix/ihaskell-src.nix {};
          nativeBuildInputs = with pkgs; [jq bash];
          doCheck = true;
          checkPhase = ''
            mkdir -p home
            export HOME=$(pwd)/home
            bash ./test/acceptance.nbconvert.sh ${env}/bin/jupyter nbconvert
          '';
          installPhase = ''
            touch $out
          '';
        }
      ) envs;

      defaultPackage = self.packages.${system}.ihaskell-ghc810;

      devShell = self.packages.${system}.ihaskell-dev-ghc810;
    });
}
