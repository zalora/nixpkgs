{ stdenv, pkgconfig, cmake, bluez, ffmpeg, libao, mesa, gtk2, glib
, gettext, git, libpthreadstubs, libXrandr, libXext, readline
, openal, libXdmcp, portaudio, SDL, wxGTK30, fetchgit
, pulseaudio ? null }:

stdenv.mkDerivation rec {
  name = "dolphin-emu-20141201";
  src = fetchgit {
    url = git://github.com/dolphin-emu/dolphin.git;
    rev = "54f1e3a3c148d36e694d8bb08d282225bdcb3440";
    sha256 = "1i0ps3ayga6m4v0jyflv2x6rr3cjrym0laafjdslggqkk04b2vjp";
    fetchSubmodules = false;
  };

  cmakeFlags = ''
    -DGTK2_GLIBCONFIG_INCLUDE_DIR=${glib}/lib/glib-2.0/include
    -DGTK2_GDKCONFIG_INCLUDE_DIR=${gtk2}/lib/gtk-2.0/include
    -DGTK2_INCLUDE_DIRS=${gtk2}/include/gtk-2.0
    -DCMAKE_BUILD_TYPE=Release
    -DENABLE_LTO=True
  '';

  enableParallelBuilding = true;

  buildInputs = [ pkgconfig cmake bluez ffmpeg libao mesa gtk2 glib
                  gettext libpthreadstubs libXrandr libXext readline openal
                  git libXdmcp portaudio SDL wxGTK30 pulseaudio ];

  meta = {
    homepage = http://dolphin-emu.org/;
    description = "Gamecube/Wii/Triforce emulator for x86_64 and ARM";
    license = stdenv.lib.licenses.gpl2;
    platforms = stdenv.lib.platforms.linux;
    maintainers = with stdenv.lib.maintainers; [ MP2E ];
  };
}
