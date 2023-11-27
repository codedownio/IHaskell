{
  description = "A Haskell kernel for IPython.";

  inputs.nixpkgs23_05.url = "github:NixOS/nixpkgs/release-23.05";
  inputs.nixpkgsMaster.url = "github:NixOS/nixpkgs/master";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.hls.url = "github:haskell/haskell-language-server";
  inputs.nix-filter.url = "github:numtide/nix-filter";

  outputs = { self, nixpkgs23_05, nixpkgsMaster, flake-utils, hls, nix-filter, ... }:
    # "x86_64-darwin" "aarch64-darwin"
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      baseOverlay = self: super: { inherit nix-filter; };
      pkgs23_05 = import nixpkgs23_05 { inherit system; overlays = [baseOverlay]; };
      pkgsMaster = import nixpkgsMaster { inherit system; overlays = [baseOverlay]; };

      versions = let
        mkVersion = pkgsSrc: compiler: overlays: extraArgs: {
          name = compiler;
          value = pkgsMaster.callPackage ./nix/release.nix ({
            inherit compiler;
            nixpkgs = import pkgsSrc { inherit system; overlays = [baseOverlay] ++ overlays; };
          } // extraArgs);
        };
        in
          pkgsMaster.lib.listToAttrs [
            (mkVersion nixpkgs23_05  "ghc810" []                               {})
            (mkVersion nixpkgs23_05  "ghc90"  []                               {})
            (mkVersion nixpkgs23_05  "ghc92"  []                               {})
            (mkVersion nixpkgsMaster "ghc94"  [(import ./nix/overlay-9.4.nix)] {})
            (mkVersion nixpkgsMaster "ghc96"  [(import ./nix/overlay-9.6.nix)] {})
            (mkVersion nixpkgsMaster "ghc98"  [(import ./nix/overlay-9.6.nix)] { enableHlint = false; })
          ];

      jupyterlab = pkgsMaster.python3.withPackages (ps: [ ps.jupyterlab ps.notebook ]);

      envs = pkgsMaster.lib.mapAttrs' (version: releaseFn: {
        name = "ihaskell-env-" + version;
        value = (releaseFn {
          # Note: this can be changed to other Jupyter systems like jupyter-console
          extraEnvironmentBinaries = [ jupyterlab ];
          systemPackages = p: with p; [
            gnuplot # for the ihaskell-gnuplot runtime
          ];
        });
      }) versions;

      exes = pkgsMaster.lib.mapAttrs' (envName: env: {
        name = builtins.replaceStrings ["-env"] [""] envName;
        value = env.ihaskellExe;
      }) envs;

      devShells = pkgsMaster.lib.mapAttrs' (version: releaseFn: {
        name = "ihaskell-dev-" + version;
        value = pkgsMaster.callPackage ./nix/mkDevShell.nix {
          inherit hls system version;
          haskellPackages = (releaseFn {}).haskellPackages;
          ihaskellOverlay = (releaseFn {}).ihaskellOverlay;
        };
      }) versions;

    in {
      packages = envs // exes // devShells // rec  {
        # For easily testing that everything builds
        allEnvs = pkgsMaster.linkFarm "ihaskell-envs" envs;
        allExes = pkgsMaster.linkFarm "ihaskell-exes" exes;
        allDevShells = pkgsMaster.linkFarm "ihaskell-dev-shells" devShells;

        print-nixpkgs-stable = pkgsMaster.writeShellScriptBin "print-nixpkgs-stable.sh" "echo ${pkgs23_05.path}";
        print-nixpkgs-master = pkgsMaster.writeShellScriptBin "print-nixpkgs-master.sh" "echo ${pkgsMaster.path}";
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

      checks = pkgsMaster.lib.mapAttrs (envName: env:
        pkgsMaster.stdenv.mkDerivation {
          name = envName + "-check";
          src = pkgsMaster.callPackage ./nix/ihaskell-src.nix {};
          nativeBuildInputs = with pkgsMaster; [jq bash];
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
