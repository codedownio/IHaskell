{ compiler ? "ghc90"
, nixpkgsSrc
, system
, packages ? (_: [])
, pythonPackages ? (_: [])
, rtsopts ? "-M3g -N2"
, staticExecutable ? false
, systemPackages ? (_: [])
}:

import ./release.nix {
  inherit compiler system packages pythonPackages rtsopts systemPackages;

  nixpkgs = import nixpkgsSrc { inherit system; };
}
