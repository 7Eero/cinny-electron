{
  lib,
  stdenv,
  makeDesktopItem,
  copyDesktopItems,
  makeWrapper,
  electron,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  nodejs,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "cinny-electron";
  version = "1.1.1";

  src = ./.;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = "sha256-zh5l8cKVjFiV+/5i9K079brU+CEmpJSajMmxfQ7N8Z0=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
    copyDesktopItems
    makeWrapper
  ];

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  };

  preBuild = ''
    # electron builds must be writable
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist
  '';

  buildPhase = ''
    runHook preBuild

    pnpm build
    pnpm exec electron-builder \
      --dir \
      -c.electronDist=electron-dist \
      -c.electronVersion=${electron.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/cinny-electron
    cp -r dist/*unpacked/resources/* $out/share/cinny-electron/

    install -Dm644 resources/icon.png $out/share/icons/hicolor/512x512/apps/cinny-electron.png
    install -Dm644 resources/cinny.svg $out/share/icons/hicolor/scalable/apps/cinny-electron.svg

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper ${electron}/bin/electron $out/bin/cinny-electron \
      --add-flags $out/share/cinny-electron/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "cinny-electron";
      desktopName = "Cinny";
      comment = "Electron wrapper around Cinny, yet another Matrix client";
      exec = "cinny-electron %u";
      icon = "cinny-electron";
      startupWMClass = "Cinny";
      genericName = "Matrix Client";
      keywords = [
        "matrix"
        "chat"
        "messaging"
        "cinny"
      ];
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
      mimeTypes = [
        "x-scheme-handler/matrix"
      ];
    })
  ];

  meta = {
    description = "Electron wrapper around Cinny, yet another Matrix client";
    homepage = "https://github.com/Enovale/cinny-electron";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
    mainProgram = "cinny-electron";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
