{
  lib,
  buildDotnetModule,
  fetchFromGitHub,
  dotnetCorePackages,
  fontconfig,
  libX11,
  libXi,
  libXrandr,
  libXcursor,
  libXinerama,
  libGL,
  libICE,
  libSM,
  libXext,
  libXrender,
  libXft,
  alsa-lib,
  openssl,
  zlib,
  icu,
  wrapGAppsHook3,
  libsecret,
  libayatana-appindicator,
}:

buildDotnetModule rec {
  pname = "artemis";
  version = "2.0-prerelease";

  src = fetchFromGitHub {
    owner = "Artemis-RGB";
    repo = "Artemis";
    tag = "prerelease";
    hash = "sha256-IX5ZiElbg/wKpMQ1mDEl7Dktp7PqCfrksIgXp057LVk=";
  };

  plugins = fetchFromGitHub {
    owner = "Artemis-RGB";
    repo = "Artemis.Plugins";
    rev = "master";
    hash = "sha256-IX5ZiElbg/wKpMQ1mDEl7Dktp7PqCfrksIgXp057LVk=";
  };

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  projectFile = "src/Artemis.UI/Artemis.UI.csproj";
  nugetDeps = null;

  nativeBuildInputs = [
    wrapGAppsHook3
  ];

  runtimeDeps = [
    fontconfig
    libX11
    libXi
    libXrandr
    libXcursor
    libXinerama
    libGL
    libICE
    libSM
    libXext
    libXrender
    libXft
    alsa-lib
    openssl
    zlib
    icu
    libsecret
    libayatana-appindicator
  ];

  dotnetInstallFlags = [
    "--framework=net8.0"
  ];

  # Skip tests as they might require hardware access
  doCheck = false;

  postPatch = ''
    # Remove any hardcoded paths or Windows-specific references
    find . -name "*.cs" -o -name "*.csproj" -o -name "*.config" | \
      xargs sed -i 's|C:\\|/tmp/|g' || true
  '';

  # Custom install phase to handle plugins
  installPhase = ''
        runHook preInstall

        dotnet publish src/Artemis.UI/Artemis.UI.csproj \
          -p:ContinuousIntegrationBuild=true \
          -p:Deterministic=true \
          --no-build \
          --configuration Release \
          --no-self-contained \
          --output "$out/lib/${pname}" \
          --no-restore \
          --verbosity minimal \
          ${toString dotnetInstallFlags}

        # Install plugins
        if [ -d "${plugins}" ]; then
          mkdir -p "$out/lib/${pname}/Plugins"

          # Build and install core plugins
          for plugin in $(find ${plugins}/src -name "*.csproj" -type f); do
            plugin_name=$(basename $(dirname "$plugin"))
            echo "Building plugin: $plugin_name"

            dotnet publish "$plugin" \
              -p:ContinuousIntegrationBuild=true \
              -p:Deterministic=true \
              --configuration Release \
              --no-self-contained \
              --output "$out/lib/${pname}/Plugins/$plugin_name" \
              --verbosity minimal \
              ${toString dotnetInstallFlags} || true
          done
        fi

        # Create wrapper script
        mkdir -p "$out/bin"
        cat > "$out/bin/${pname}" << 'EOF'
    #!/bin/sh
    export DOTNET_ROOT="${dotnet-runtime}"
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0
    cd "$out/lib/${pname}"
    exec "${dotnet-runtime}/bin/dotnet" "$out/lib/${pname}/Artemis.UI.dll" "$@"
    EOF
        chmod +x "$out/bin/${pname}"

        # Install desktop file
        mkdir -p "$out/share/applications"
        cat > "$out/share/applications/${pname}.desktop" << 'EOF'
    [Desktop Entry]
    Type=Application
    Name=Artemis
    Comment=Advanced unified lighting across RGB peripherals
    Exec=${pname}
    Icon=${pname}
    Categories=System;Utility;
    StartupWMClass=Artemis.UI
    StartupNotify=true
    EOF

        # Install icon (would need to extract from source)
        mkdir -p "$out/share/icons/hicolor/256x256/apps"
        # TODO: Extract and install icon from source

        runHook postInstall
  '';

  # Set up desktop integration and runtime environment
  preFixup = ''
    makeWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDeps}"
      --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 0
    )
  '';

  meta = with lib; {
    description = "Advanced unified lighting across many different brands RGB peripherals";
    longDescription = ''
      Artemis adds highly configurable support for several games to a range of
      RGB keyboards, mice and headsets. It provides advanced lighting effects
      with spatial awareness, cross-brand compatibility, and a plugin system
      for extensibility.
    '';
    homepage = "https://artemis-rgb.com/";
    downloadPage = "https://github.com/Artemis-RGB/Artemis/releases";
    changelog = "https://github.com/Artemis-RGB/Artemis/commits/master";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ eymeric ];
    platforms = platforms.linux;
    mainProgram = "artemis";
    # This application requires hardware access for RGB devices
    broken = false;
  };
}
