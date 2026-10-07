{
  lib,
  stdenv,
  rustPlatform,
  rustc,
  fetchFromGitHub,
  pkg-config,
  patchelf,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  vulkan-loader,
  libxkbcommon,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  wayland,
  nix-update-script,
}:

let
  runtimeDeps = [
    libxkbcommon
    libx11
    libxcb
    libxcursor
    libxi
    wayland
    vulkan-loader
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "photocraft";
  version = "0.5.0";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "storytold";
    repo = "photocraft";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ye8Fv4CPBUtqi1ZAJvXfpvyaXk7Ga9BAwl2nrsLEZWA=";
  };

  cargoHash = "sha256-Id7pMLTkMvW/3/CESTGnWpdVVoF7yJLnbNMTQVt8n3s=";

  cargoBuildFlags = [
    "--package=photocraft"
    "--package=photocraft-cli"
  ];

  # The `photocraft` crate runs live GPU tests; software rendering in CI is too slow.
  cargoTestFlags = [
    "--package=photocraft-cli"
  ];

  nativeBuildInputs = [
    pkg-config
    patchelf
    makeWrapper
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "ai.storyteller.photocraft";
      desktopName = "PhotoCraft";
      genericName = "Image Editor";
      comment = "Edit photos and layered PSD documents";
      exec = "photocraft %F";
      tryExec = "photocraft";
      icon = "ai.storyteller.photocraft";
      terminal = false;
      startupNotify = true;
      startupWMClass = "photocraft";
      categories = [
        "Graphics"
        "2DGraphics"
        "RasterGraphics"
        "Photography"
      ];
      keywords = [
        "photo"
        "image"
        "editor"
        "psd"
        "photoshop"
        "layers"
        "retouch"
        "paint"
      ];
      mimeTypes = [
        "application/x-photocraft"
        "image/vnd.adobe.photoshop"
        "image/x-psd"
        "image/x-psb"
        "image/png"
        "image/jpeg"
        "image/tiff"
        "image/webp"
        "image/gif"
        "image/bmp"
        "image/x-tga"
        "image/x-icon"
        "image/vnd.microsoft.icon"
        "image/x-portable-anymap"
        "image/x-portable-bitmap"
        "image/x-portable-graymap"
        "image/x-portable-pixmap"
        "image/x-exr"
        "image/vnd.radiance"
        "image/avif"
        "image/qoi"
      ];
    })
  ];

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    mkdir -p $out/share/icons
    cp -R ${finalAttrs.src}/assets/app-icon/hicolor $out/share/icons/
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --add-rpath ${lib.makeLibraryPath runtimeDeps} $out/bin/photocraft
    wrapProgram $out/bin/photocraft --set PHOTOCRAFT_SKIP_LIB_CHECK 1
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open-source, native image editor with layered PSD/PSB support";
    homepage = "https://github.com/storytold/photocraft";
    changelog = "https://github.com/storytold/photocraft/releases/tag/v${finalAttrs.version}";
    # Bundled assets: see ATTRIBUTION.md in upstream. SCOWL word list: # scowl
    license =
      with lib.licenses;
      AND [
        (OR [
          mit
          asl20
        ])
        ofl
        isc
        cc-by-30
        cc0
      ];
    maintainers = with lib.maintainers; [ cleboost ];
    mainProgram = "photocraft";
    platforms = rustc.meta.platforms;
  };
})
