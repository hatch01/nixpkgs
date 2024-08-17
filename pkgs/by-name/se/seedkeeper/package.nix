{ lib
, stdenv
, pcsclite
, python311
, fetchPypi
, fetchFromGitHub
, fetchFromGitLab
, fetchurl
}:
let
  pname = "seedKeeperTool";
  version = "0.1.3";
  # Using python311 because python312 break versioneer used by ecdsa
  python = python311.override {
    self = python;
    packageOverrides = self: super: {
      pyside2 = super.pyside2.overrideAttrs (oldAttrs: rec {
        version = "5.12.6";
        src = fetchurl {
          url = "https://download.qt.io/official_releases/QtForPython/pyside2/PySide2-${version}-src/pyside-setup-everywhere-src-${version}.tar.xz";
          hash = "sha256-UzefQ4kaa8cvw0T1lj133gkWNEY3EyquY0Z337uhhdg=";
        };
        patches = [
          ./dont_ignore_optional_modules.patch
        ];
        postPatch = ''
          cd sources/pyside2
        '';

      });
      pysatochip = super.pysatochip.overridePythonAttrs (oldAttrs: rec {
        pname = "pysatochip";
        version = "0.12.3";
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-JNs1imXAQCwpnAxi78+7/JjklBgc0w05lpSaxmfVtNQ=";
        };
      });
      pyscard = super.pyscard.overridePythonAttrs (oldAttrs: rec {
        version = "1.9.9";
        src = fetchFromGitHub {
          owner = "LudovicRousseau";
          repo = "pyscard";
          rev = "release-${version}";
          hash = "sha256-CYDvCisKBMmxgCA8nGDciy3kmbu0ewDpa1NfhgkifD8=";
        };
        nativeCheckInputs = [];
        NIX_CFLAGS_COMPILE = lib.optionalString (! stdenv.isDarwin)
          "-I ${lib.getDev pcsclite}/include/PCSC";
      });

       pysimpleguiqt = super.pysimpleguiqt.overridePythonAttrs (oldAttrs: rec {
        version = "0.31.0";
        src = fetchPypi {
          pname = "PySimpleGUIQt";
          inherit version;
          sha256 = "sha256-sVUkFOcFkfywlK86Gn/84TMlcixfwSAwwcWPzsrMazs=";
        };
        dependencies = with python311.pkgs; [
          pyside2
        ];
      });
      ecdsa = super.ecdsa.overridePythonAttrs (oldAttrs: rec {
        pname = "ecdsa";
        version = "0.15";
        format = null;
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-jxKsMX+KExjvp1dX7wplGr4S5R/Br4g4+5EHlEUicnc=";
        };
      });
      mnemonic = super.mnemonic.overridePythonAttrs (oldAttrs: rec {
        version = "0.19";
        pyproject = null;
        format = "setuptools";
        src = fetchFromGitHub {
          owner = "trezor";
          repo = "python-mnemonic";
          rev = "v${version}";
          hash = "sha256-WOk4uL1nGxz/fK/INDhjd/8DOR1NDWJ5vP7NGdvXQ2c=";
        };
      });
      pypng = super.pypng.overridePythonAttrs (oldAttrs: rec {
        pname = "pypng";
        version = "0.0.20";
        src = fetchFromGitLab {
          owner = "drj11";
          repo = "pypng";
          rev = "refs/tags/${pname}-${version}";
          hash = "sha256-XdlPWcl2dev54ZFJHJ1PHuum38TG/5ew58vrthTnGyI=";
        };
        # patches are only needed to test the package so just droping it out
        patches = [];
        doCheck = false;
      });
    };
  };
in
python.pkgs.buildPythonApplication rec {
  inherit pname version;

  pyproject = true;

  src = fetchFromGitHub {
    owner = "Toporin";
    repo = "Seedkeeper-Tool";
    rev = "v${version}";
    hash = "sha256-AqAZTfkr0WGm7k8Qxn2pLK57Ly2nCu7xymYOHfU85vM=";
  };

  build-system = with python.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python.pkgs; [
    pyqrcode
    pypng
    mnemonic
    ecdsa
    pyscard
    pysatochip
    certifi
    rsa

    # GUI
    pysimpleguiqt
    pyside2
  ];

  meta = {
    # ...
  };
}
