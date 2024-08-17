{
  lib,
  buildPythonPackage,
  python3Packages,
  fetchPypi
}:

buildPythonPackage rec {
  pname = "pysimpleguiqt";
  version = "5.0.0";
  format = "setuptools";

  src = fetchPypi {
    pname = "PySimpleGUIQt";
    inherit version;
    hash = "sha256-7HYZqYMn6OpU+DMu+U1gv3CnnIr7sBxGkZ/uQOwy+xk=";
  };

  dependencies = with python3Packages; [
    pyside2
  ];

  propagatedBuildInputs = [ ];

  meta = with lib; {
    description = "Python GUIs for Humans";
    homepage = "https://github.com/PySimpleGUI/PySimpleGUI";
    license = licenses.unfree;
    maintainers = with maintainers; [ eymeric ];
    broken = true; # update to v5 broke the package, it now needs rsa and is trying to access an X11 socket?
  };
}
