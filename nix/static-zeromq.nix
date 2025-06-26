{ pkgsCross
, pkgsStatic
}:

(pkgsCross.musl64.zeromq.override { libsodium = pkgsStatic.libsodium; }).overrideAttrs (oldAttrs: {
  configureFlags = [
    "--enable-static"
    "--disable-shared"
  ];

  NIX_CFLAGS_COMPILE = "-static";

  cmakeFlags = [
    "-DBUILD_SHARED=OFF"
    "-DZMQ_BUILD_TESTS=OFF"
  ];
})
