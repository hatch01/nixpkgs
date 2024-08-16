{ lib
, stdenv
, python3
, fetchFromGitHub
, libnotify
, gtk3
, SDL2
, pcsclite
}:
python3.pkgs.buildPythonApplication rec {
  pname = "uniblow";
  version = "2.7.0";

  src = fetchFromGitHub {
    owner = "bitlogik";
    repo = "uniblow";
    rev = "v${version}";
    sha256 = "sha256-xLpHpYmM+vVgagBklvTdensA5FpyrfQEkzOzuWKtDrA=";
  };

  buildInputs = [
    libnotify
    gtk3
    SDL2
    pcsclite
  ];

  propagatedBuildInputs = with python3.pkgs; [
    pyscard
  ];

/*  postInstall = lib.optionalString stdenv.isLinux ''
    substituteInPlace $out/share/applications/electrum.desktop \
      --replace 'Exec=sh -c "PATH=\"\\$HOME/.local/bin:\\$PATH\"; electrum %u"' \
                "Exec=$out/bin/electrum %u" \
      --replace 'Exec=sh -c "PATH=\"\\$HOME/.local/bin:\\$PATH\"; electrum --testnet %u"' \
                "Exec=$out/bin/electrum --testnet %u"
  '';
*/
  meta = with lib; {
    description = "Lightweight Bitcoin wallet";
    longDescription = ''
      An easy-to-use Bitcoin client featuring wallets generated from
      mnemonic seeds (in addition to other, more advanced, wallet options)
      and the ability to perform transactions without downloading a copy
      of the blockchain.
    '';
    homepage = "https://electrum.org/";
    downloadPage = "https://electrum.org/#download";
    changelog = "https://github.com/spesmilo/electrum/blob/master/RELEASE-NOTES";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ joachifm np prusnak chewblacka ];
    mainProgram = "electrum";
  };
}
