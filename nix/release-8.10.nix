{ nixpkgsSrc
, system
}:

let
  nixpkgs = import nixpkgsSrc { inherit system; };

in

{ compiler ? "ghc810"
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
