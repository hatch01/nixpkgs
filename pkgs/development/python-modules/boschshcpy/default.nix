{
  lib,
  buildPythonPackage,
  cryptography,
  fetchFromGitHub,
  getmac,
  pythonOlder,
  requests,
  setuptools,
  zeroconf,
}:

buildPythonPackage rec {
  pname = "boschshcpy";
  version = "0.2.105";
  pyproject = true;

  disabled = pythonOlder "3.10";

  src = fetchFromGitHub {
    owner = "tschamm";
    repo = "boschshcpy";
    tag = version;
    hash = "sha256-aouZryqn2qMdfqTFXP49UUY0X1HzQCldLQUBfnlUfHI=";
  };

  build-system = [ setuptools ];

  dependencies = [
    cryptography
    getmac
    requests
    zeroconf
  ];

  # Project has no tests
  doCheck = false;

  pythonImportsCheck = [ "boschshcpy" ];

  meta = with lib; {
    description = "Python module to work with the Bosch Smart Home Controller API";
    homepage = "https://github.com/tschamm/boschshcpy";
    license = with licenses; [ bsd3 ];
    maintainers = with maintainers; [ fab ];
  };
}
