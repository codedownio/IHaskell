let
  ghcVersion = "ghc94";

  overlay = sel: sup: {
    haskell = sup.haskell // {
      packages = sup.haskell.packages // {
        ${ghcVersion} = sup.haskell.packages.${ghcVersion}.override {
          overrides = self: super: {
            ghc-syntax-highlighter = super.callCabal2nix "ghc-syntax-highlighter" (sup.fetchFromGitHub {
              owner = "mrkkrp";
              repo = "ghc-syntax-highlighter";
              # 0.0.10.0
              rev = "71ff751eaa6034d4aef254d6bc5a8be4f6595344";
              sha256 = "wQmWSuvIJpg11zKl1qOSWpqxjp2DoJwa20vaS2KHypM=";
            }) {};

            ghc-lib-parser = super.ghc-lib-parser_9_6_3_20231014;
            ghc-lib-parser-ex = super.ghc-lib-parser-ex_9_6_0_2;
          };
        };
      };
    };
  };

in

{ nixpkgsSrc
, system
}:

let
  nixpkgs = import nixpkgsSrc { inherit system; overlays = [overlay]; };

in

{ compiler ? ghcVersion
, packages ? (_: [])
, pythonPackages ? (_: [])
, rtsopts ? "-M3g -N2"
, staticExecutable ? false
, systemPackages ? (_: [])
}:

import ./release.nix {
  inherit nixpkgs;
  inherit compiler packages pythonPackages rtsopts systemPackages;
}
