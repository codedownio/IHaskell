{
  description = "A Haskell kernel for IPython.";

  inputs.nixpkgs25_05.url = "github:NixOS/nixpkgs/release-25.05";
  inputs.nixpkgsMaster.url = "github:NixOS/nixpkgs/master";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    inputs.nixpkgs.follows = "nixpkgsMaster";
  };
  inputs.hls = {
    url = "github:haskell/haskell-language-server";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.nix-filter.url = "github:numtide/nix-filter";
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix/master";

  nixConfig = {
    extra-substituters = [ "https://ihaskell.cachix.org" ];
    extra-trusted-public-keys = [ "ihaskell.cachix.org-1:WoIvex/Ft/++sjYW3ntqPUL3jDGXIKDpX60pC8d5VLM="];
  };

  outputs = { self, nixpkgs25_05, nixpkgsMaster, flake-utils, gitignore, hls, nix-filter, haskellNix, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      baseOverlay = _self: _super: { inherit nix-filter; };
      pkgsMaster = import nixpkgsMaster { inherit system; overlays = [baseOverlay]; };

      jupyterlab = pkgsMaster.python3.withPackages (ps: [ ps.jupyterlab ps.notebook ]);

      src = pkgsMaster.callPackage ./nix/ihaskell-src.nix {};

      srcWithStackYaml = stackYaml: let
        baseSrc = pkgsMaster.lib.cleanSourceWith {
          src = gitignore.lib.gitignoreSource ./.;
          filter = name: type:
            !(baseNameOf name == "flake.nix");
        };
      in
        pkgsMaster.runCommand "src-with-${stackYaml}" {} ''
          cp -r ${baseSrc} $out
          chmod u+w $out
          cd $out
          rm stack.yaml
          cp ${stackYaml} stack.yaml
          cp ${stackYaml}.lock stack.yaml.lock
          sed -i 's/\.\././g' stack.yaml

          echo "FINAL STACK.YAML:"
          cat stack.yaml
        '';

      baseModules = {
        packages.ihaskell.components.exes.ihaskell.libs = [
          pkgsMaster.pkgsStatic.libsodium
          (pkgsMaster.callPackage ./nix/static-zeromq.nix {})
        ];
      };

      flakeStatic = pkgsSrc: compiler-nix-name: srcToUse: modules:
        let
          pkgs = import pkgsSrc {
            inherit system;
            overlays = [baseOverlay haskellNix.overlay] ++ [
              (self: super: {
                hixProject = compiler-nix-name: src: extraModules:
                  super.haskell-nix.hix.project {
                    projectFileName = "stack.yaml";
                    src = srcToUse;
                    evalSystem = system;
                    inherit compiler-nix-name;
                    modules = extraModules;
                  };
              })
            ];
            inherit (haskellNix) config;
          };
        in
          (pkgs.pkgsCross.musl64.hixProject compiler-nix-name src ([baseModules] ++ [{
            packages.ihaskell.components.exes.ihaskell.enableShared = false;
            # packages.ihaskell.components.exes.ihaskell.configureFlags = [
            #   ''--ghc-options="-pgml g++ -optl=-fuse-ld=gold -optl-Wl,--allow-multiple-definition -optl-Wl,--whole-archive -optl-Wl,-Bstatic -optl-Wl,-Bdynamic -optl-Wl,--no-whole-archive"''
            # ];
            packages.ihaskell.components.exes.ihaskell.libs = [];
            packages.ihaskell.components.exes.ihaskell.build-tools = [pkgs.pkgsCross.musl64.gcc];
          }] ++ modules)).flake {};

      # Map from GHC version to release function
      versions = let
        mkVersion = pkgsSrc: compiler: overlays: extraArgs: let
          pkgs = import pkgsSrc {
            inherit system;
            overlays = [baseOverlay haskellNix.overlay] ++ overlays;
            inherit (haskellNix) config;
          };
        in
          {
            name = compiler;
            value = pkgs.callPackage ./nix/release.nix ({
              inherit compiler;
            } // extraArgs);
          };
      in
        pkgsMaster.lib.listToAttrs [
          (mkVersion nixpkgs25_05  "ghc98"  [(import ./nix/overlay-9.8.nix)]  {})
          (mkVersion nixpkgsMaster "ghc910" [(import ./nix/overlay-9.10.nix)] {})
          (mkVersion nixpkgsMaster "ghc912" [(import ./nix/overlay-9.12.nix)] {})
        ];

      # Helper function for building environments with a given set of packages
      mkEnvs = prefix: packages: pkgsMaster.lib.mapAttrs' (version: releaseFn: {
        name = prefix + version;
        value = (releaseFn {
          # Note: this can be changed to other Jupyter systems like jupyter-console
          extraEnvironmentBinaries = [ jupyterlab ];
          systemPackages = p: with p; [
            gnuplot # for the ihaskell-gnuplot runtime
          ];
          inherit packages;
        });
      }) versions;

      # Basic envs with Jupyterlab and IHaskell
      envs = mkEnvs "ihaskell-env-" (_: []);

      # Envs with Jupyterlab, IHaskell, and all display packages
      displayEnvs = mkEnvs "ihaskell-env-display-" (p: map (n: builtins.getAttr n p) (import ./nix/displays.nix));

      # Executables only, pulled from passthru on the envs
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

      enableOsStringModule = {
        # Needed since GHC 9.10
        packages.unix.components.library.configureFlags = [''-f os-string''];
        packages.directory.components.library.configureFlags = [''-f os-string''];
        packages.file-io.components.library.configureFlags = [''-f os-string''];
      };

    in {
      packages = envs // displayEnvs // exes // devShells // rec {
        # For easily testing that everything builds
        allEnvs = pkgsMaster.linkFarm "ihaskell-envs" envs;
        allDisplayEnvs = pkgsMaster.linkFarm "ihaskell-display-envs" displayEnvs;
        allExes = pkgsMaster.linkFarm "ihaskell-exes" exes;
        allDevShells = pkgsMaster.linkFarm "ihaskell-dev-shells" devShells;

        # To use in CI
        inherit jupyterlab;
        print-nixpkgs-master = pkgsMaster.writeShellScriptBin "print-nixpkgs-master.sh" "echo ${pkgsMaster.path}";

        static92 = (flakeStatic nixpkgsMaster "ghc928" (srcWithStackYaml "stack/stack-9.2.yaml") []).packages."ihaskell:exe:ihaskell";
        static94 = (flakeStatic nixpkgsMaster "ghc948" (srcWithStackYaml "stack/stack-9.4.yaml") []).packages."ihaskell:exe:ihaskell";
        static96 = (flakeStatic nixpkgsMaster "ghc967" (srcWithStackYaml "stack/stack-9.6.yaml") []).packages."ihaskell:exe:ihaskell";
        static98 = (flakeStatic nixpkgsMaster "ghc984" (srcWithStackYaml "stack/stack-9.8.yaml") []).packages."ihaskell:exe:ihaskell";
        static910 = (flakeStatic nixpkgsMaster "ghc9102" (srcWithStackYaml "stack/stack-9.10.yaml") [enableOsStringModule]).packages."ihaskell:exe:ihaskell";
        static912 = (flakeStatic nixpkgsMaster "ghc9122" (srcWithStackYaml "stack/stack-9.12.yaml") [enableOsStringModule (import ./nix/ghc912-module.nix)]).packages."ihaskell:exe:ihaskell";

        staticAll = pkgsMaster.runCommand "ihaskell-static-all" {} ''
          mkdir -p $out/bin

          # cp {static92}/bin/ihaskell $out/bin/ihaskell
          # cp {static94}/bin/ihaskell $out/bin/ihaskell
          cp ${static96}/bin/ihaskell $out/bin/ihaskell
          cp ${static98}/bin/ihaskell $out/bin/ihaskell-98
          cp ${static910}/bin/ihaskell $out/bin/ihaskell-910
          cp ${static912}/bin/ihaskell $out/bin/ihaskell-912
        '';
      };

      # Run the acceptance tests on each env
      checks = pkgsMaster.lib.mapAttrs (envName: env:
        pkgsMaster.stdenv.mkDerivation {
          name = envName + "-check";
          inherit src;
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

      defaultPackage = self.packages.${system}.ihaskell-env-ghc98;

      devShells = {
        default = pkgsMaster.mkShell {
          buildInputs = with pkgsMaster; [
            blas
            cairo
            expat
            file
            fribidi
            glib
            gmp
            lapack
            libdatrie
            libselinux
            libsepol
            libsodium
            libsysprof-capture
            libthai
            ncurses
            pango
            pcre2
            pkg-config
            util-linux
            xorg.libXdmcp
            zeromq
            zlib
          ];
        };
      };
    });
}
