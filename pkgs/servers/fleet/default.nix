{ stdenv, lib, go, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "fleet-${version}";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "coreos";
    repo = "fleet";
    rev = "v${version}";
    sha256 = "0gjminfprprs1nmg9y9a0qkyl9spixrk4pc2b7bl0lxdgpq2yiid";
  };

  buildInputs = [ go ];

  buildPhase = ''
    patchShebangs build
    ./build
  '';

  installPhase = ''
    mkdir -p $out
    mv bin $out
  '';

  meta = with stdenv.lib; {
    description = "A distributed init system";
    homepage = http://coreos.com/using-coreos/clustering/;
    license = licenses.asl20;
    maintainers = with maintainers; [ cstrahan offline ];
    platforms = platforms.unix;
  };
}
