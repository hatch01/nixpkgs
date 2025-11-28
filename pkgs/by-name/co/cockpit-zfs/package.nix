{
  bash,
  fetchFromGitHub,
  lib,
  lsscsi,
  makeWrapper,
  nodejs,
  python312,
  smartmontools,
  stdenv,
  util-linux,
  yarn-berry_4,
  zfs,
}:

let
  yarn-berry = yarn-berry_4;
  python = python312;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "cockpit-zfs";
  version = "1.2.12-2";

  src = fetchFromGitHub {
    owner = "45Drives";
    repo = "cockpit-zfs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-oeXSOxogfAazRsKfngq2+DOyo//wRJQSqm7gaCza4WY=";
    fetchSubmodules = true;
  };

  missingHashes = ./missing-hashes.json;

  offlineCache = yarn-berry.fetchYarnBerryDeps {
    inherit (finalAttrs) src missingHashes;
    hash = "sha256-YnR1SqBGnxEQaGUGMNTHHEGcOIhuGbWnqMdr4eRGXcA=";
  };

  nativeBuildInputs = [
    nodejs
    yarn-berry
    yarn-berry.yarnBerryConfigHook
    makeWrapper
  ];

  propagatedBuildInputs = [
    smartmontools
    (python.withPackages (ps: [ ps.pyudev ps.py-libzfs ]))
    zfs
    lsscsi
    util-linux
  ];

  env = {
    # Disable post-install scripts that try to access network (electron, plantuml-pipe)
    YARN_ENABLE_SCRIPTS = "0";
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  };

  postPatch =
    let
      # houston-common-lib has @types/electron which pulls in electron.
      # Electron's postinstall downloads binaries, which fails in sandbox.
      # Since this is a Cockpit plugin (not an Electron app), we don't need electron.
      houstonLibDir = "houston-common/houston-common-lib";
      houstonUiDir = "houston-common/houston-common-ui";
    in
    ''
      # Remove electron type dependency
      substituteInPlace ${houstonLibDir}/package.json \
        --replace-fail '"@types/electron": "^1.6.12",' ""
      substituteInPlace ${houstonLibDir}/tsconfig.json \
        --replace-fail '"types": ["electron"]' '"types": []'

      # Skip TypeScript type checking (fails without electron types)
      substituteInPlace ${houstonLibDir}/package.json \
        --replace-fail '"build": "tsc --noEmit && vite build"' '"build": "vite build"'
      substituteInPlace ${houstonUiDir}/package.json \
        --replace-fail '"build": "run-p type-check \"build-only {@}\" --"' '"build": "vite build"'

      # Externalize vue and electron in houston-common-lib (peer dependencies)
      substituteInPlace ${houstonLibDir}/vite.config.ts \
        --replace-fail 'external: (id) => {' 'external: (id) => {
        if (id === "vue" || id.startsWith("vue/") || id === "electron" || id.startsWith("electron/")) return true;'

      # Disable VueDevTools and dts plugins (fail with Yarn PnP)
      substituteInPlace ${houstonUiDir}/vite.config.ts \
        --replace-fail "import VueDevTools from 'vite-plugin-vue-devtools'" "" \
        --replace-fail "VueDevTools()," "" \
        --replace-fail "import dts from 'vite-plugin-dts'" ""
      sed -i '/dts({/,/})/d' ${houstonUiDir}/vite.config.ts
    '';

  buildPhase = ''
    runHook preBuild

    yarn workspaces foreach -Rpt --from 'cockpit-zfs' run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/cockpit/zfs
    cp -r zfs/dist/* $out/share/cockpit/zfs/

    # Install system files (dbus config, systemd services, zed scripts)
    if [ -d system_files ]; then
      cp -r system_files/* $out/
    fi

    # Wrap all Python scripts in the backend directory
    if [ -d $out/opt/45drives/houston ]; then
      for script in $out/opt/45drives/houston/*.py; do
        if [ -f "$script" ]; then
          makeWrapper ${python}/bin/python3 $script-wrapped \
            --add-flags $script \
            --prefix PATH : /run/current-system/sw/bin
          mv $script-wrapped $script
          chmod +x $script
        fi
      done
    fi

    # Optionally wrap Bash scripts in /etc/45drives/
    if [ -d $out/etc/45drives ]; then
      for script in $out/etc/45drives/*.sh; do
        if [ -f "$script" ]; then
          makeWrapper ${bash}/bin/bash $script-wrapped \
            --add-flags $script \
            --prefix PATH : /run/current-system/sw/bin
          mv $script-wrapped $script
          chmod +x $script
        fi
      done
    fi

    runHook postInstall
  '';

  meta = {
    description = "Cockpit plugin for ZFS management by 45Drives";
    homepage = "https://github.com/45Drives/cockpit-zfs";
    changelog = "https://github.com/45Drives/cockpit-zfs/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ eymeric ];
  };
})
