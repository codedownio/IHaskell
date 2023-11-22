let
  ghcVersion = "ghc96";

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

            ghc-lib-parser = self.ghc-lib-parser_9_6_3_20231014;

            zeromq4-haskell = super.zeromq4-haskell.overrideAttrs (oldAttrs: {
              buildInputs = oldAttrs.buildInputs ++ [super.libsodium];
            });
          };
        };
      };
    };
  };

in

{ compiler ? ghcVersion
, nixpkgsSrc
, system
, packages ? (_: [])
, pythonPackages ? (_: [])
, rtsopts ? "-M3g -N2"
, staticExecutable ? false
, systemPackages ? (_: [])
}:

import ./release.nix {
  inherit compiler packages pythonPackages rtsopts systemPackages;

  nixpkgs = import nixpkgsSrc { inherit system; overlays = [ overlay ]; };
}
