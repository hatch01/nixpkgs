{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

let
  python = python3Packages.override {
    overrides = self: super: {
    };
  };
in
python.buildPythonPackage rec {
  pname = "Satochip-Utils";
  version = "0.2.0-beta";

  src = fetchFromGitHub {
    owner = "Toporin";
    repo = "Satochip-Utils";
    #rev = "v${version}";
    rev = "master";
    hash = "sha256-Qr9jnZtfGF0AstLQ5smlk008hEcR+iHL1015KIOQqcI=";
    #hash = "sha256-vvrYsGmxC4gip4agQauxOgD+Vw5eGkvPas499ST3Lf8=";
  };

  propagatedBuildInputs = with python; [
    tkinter
    customtkinter
    pillow
    mnemonic
    pysatochip
    pillow
    pyscard
    pyqrcode
  ];

  patches = [
   ./setup.patch
  ];

  preInstall = ''
    mkdir -p $out/bin
    mkdir -p $out/lib
    cp -r ${src}/* $out/bin/
    echo '#!${python.python}/bin/python' > $out/bin/${pname}
    cat ${src}/satochip_utils.py >> $out/bin/${pname}

    #echo '${python.python}/bin/python ${placeholder "out"}/lib/satochip_utils.py "$@"' > $out/bin/${pname}
    chmod +x $out/bin/${pname}
  '';


  meta = {
    changelog = "https://github.com/Toporin/Satochip-Utils/blob/master/CHANGELOG.md";
    description = "Application that unifies the functionality of Satochip card constellation";
    homepage = "https://github.com/Toporin/Satochip-Utils";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.eymeric ];
  };
}
