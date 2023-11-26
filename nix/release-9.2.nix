{ nixpkgsSrc
, system
, baseOverlay
}:

let
  nixpkgs = import nixpkgsSrc { inherit system; overlays = [baseOverlay]; };

in

{ compiler ? "ghc92"
, packages ? (_: [])
, extraEnvironmentBinaries ? []
, rtsopts ? "-M3g -N2"
, staticExecutable ? false
, systemPackages ? (_: [])
}:

import ./release.nix {
  inherit nixpkgs compiler packages extraEnvironmentBinaries rtsopts staticExecutable systemPackages;
}
