{ nixpkgsSrc
, system
, baseOverlay
}:

let
  nixpkgs = import nixpkgsSrc { inherit system; overlays = [baseOverlay]; };

in

{ compiler ? "ghc90"
, packages ? (_: [])
, jupyterlab ? nixpkgs.python3.withPackages (ps: [ ps.jupyterlab ps.notebook ])
, rtsopts ? "-M3g -N2"
, staticExecutable ? false
, systemPackages ? (_: [])
}:

import ./release.nix {
  inherit nixpkgs jupyterlab compiler packages rtsopts systemPackages;
}
