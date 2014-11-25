{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "nasm-${version}";
  version = "2.11.05"; # do not update until syslinux is fixed with that version

  src = fetchurl {
    url = "http://www.nasm.us/pub/nasm/releasebuilds/${version}/${name}.tar.bz2";
    sha256 = "1sgspnascc0asmwlv3jm1mq4vzx653sa7vlg48z20pfybk7pnhaa";
  };

  meta = with stdenv.lib; {
    homepage = http://www.nasm.us/;
    description = "An 80x86 and x86-64 assembler designed for portability and modularity";
    platforms = platforms.unix;
    maintainers = with maintainers; [ pSub ];
  };
}
