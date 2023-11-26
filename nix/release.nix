{ compiler
, nixpkgs
, jupyterlab
, packages ? (_: [])
, rtsopts ? "-M3g -N2"
, staticExecutable ? false
, systemPackages ? (_: [])
, enableHlint ? true
}:

let
  # Haskell packages set with IHaskell packages added
  haskellPackages = nixpkgs.haskell.packages."${compiler}".override (old: {
    overrides = nixpkgs.lib.composeExtensions
      (old.overrides or (_: _: {}))
      (import ./ihaskell_overlay.nix { inherit compiler nixpkgs enableHlint; });
  });

  # GHC with desired packages. This includes user-configured packages + ihaskell itself, so
  # you can import IHaskell.Display
  ihaskellEnv = haskellPackages.ghcWithPackages (ps: (packages ps) ++ [ps.ihaskell]);

  # ihaskell binary wrapper which adds the "-l" argument
  ihaskellGhcLib = nixpkgs.writeShellScriptBin "ihaskell" ''
    ${ihaskellEnv}/bin/ihaskell -l $(${ihaskellEnv}/bin/ghc --print-libdir) "$@"
  '';

  # Jupyter directory with "kernels/haskell/kernel.json", plus logo and kernel.js
  jupyterDirKernel = let
    kernelFile = {
      display_name = "Haskell";
      argv = [
        "${ihaskellGhcLib}/bin/ihaskell"
        "kernel"
        "{connection_file}"
        "+RTS"
      ] ++ (nixpkgs.lib.splitString " " rtsopts) ++ [
        "-RTS"
      ];
      language = "haskell";
    };
  in
    nixpkgs.runCommand "ihaskell-kernel" {} ''
      export kerneldir=$out/kernels/haskell
      mkdir -p $kerneldir
      cp ${../html}/* $kerneldir
      echo '${builtins.toJSON kernelFile}' > $kerneldir/kernel.json
    '';

  # Separate Jupyter directory with the "labextensions" dir.
  # TODO: just copy this alongside the HTML in jupyterDir?
  jupyterDirLabExtensions = nixpkgs.runCommand "ihaskell-labextension" {} ''
    mkdir -p $out/labextensions/
    ln -s ${../jupyterlab-ihaskell/labextension} $out/labextensions/jupyterlab-ihaskell
  '';

  # Combine the paths in jupyterDirKernel and jupyterDirLabExtensions
  ihaskellDataDir = nixpkgs.buildEnv {
    name = "ihaskell-data-dir-" + compiler;
    paths = [ jupyterDirKernel jupyterDirLabExtensions ];
  };

in

nixpkgs.buildEnv {
  name = "ihaskell-with-packages-" + compiler;
  nativeBuildInputs = [ nixpkgs.makeWrapper ];
  paths = [ ihaskellEnv jupyterlab ];
  postBuild = ''
    for prg in $out/bin"/"*;do
      if [[ -f $prg && -x $prg ]]; then
        wrapProgram $prg \
          --prefix PATH : "${nixpkgs.lib.makeBinPath ([ihaskellEnv] ++ (systemPackages nixpkgs))}" \
          --prefix JUPYTER_PATH : "${ihaskellDataDir}"
      fi
    done
  '';

  passthru = {
    # statically linking against haskell libs reduces closure size at the expense
    # of startup/reload time, so we make it configurable
    ihaskellExe = if staticExecutable
                  then nixpkgs.haskell.lib.justStaticExecutables haskellPackages.ihaskell
                  else nixpkgs.haskell.lib.enableSharedExecutables haskellPackages.ihaskell;
  };
}
