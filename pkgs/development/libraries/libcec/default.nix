{ stdenv, fetchurl, autoreconfHook, pkgconfig, udev }:

let version = "2.1.4"; in

stdenv.mkDerivation {
  name = "libcec-${version}";

  src = fetchurl {
    url = "https://github.com/Pulse-Eight/libcec/archive/libcec-${version}.tar.gz";
    sha256 = "0iz11zclbs3gk4ddq0pm4vyq015qmvy4nb9sra3vk6jw58izbgkr";
  };

  buildInputs = [ autoreconfHook pkgconfig udev ];

  meta = {
    description = "USB CEC adapter communication library";
    homepage = "http://libcec.pulse-eight.com";
    repositories.git = "https://github.com/Pulse-Eight/libcec.git";
    license = "GPLv2+";
    platforms = stdenv.lib.platforms.linux;
  };
}
