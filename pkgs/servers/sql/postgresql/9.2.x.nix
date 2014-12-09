{ stdenv, fetchurl, zlib, readline, libossp_uuid, openssl }:

with stdenv.lib;

let version = "9.2.9"; in

stdenv.mkDerivation rec {
  name = "postgresql-${version}";

  src = fetchurl {
    url = "mirror://postgresql/source/v${version}/${name}.tar.bz2";
    sha256 = "94ec6d330f125b6fc725741293073b07d7d20cc3e7b8ed127bc3d14ad2370197";
  };

  buildInputs = [ zlib readline openssl ] ++ optionals (!stdenv.isDarwin) [ libossp_uuid ];

  enableParallelBuilding = true;

  makeFlags = [ "world" ];

  configureFlags = [
    "--with-openssl"
    ]
    ++ optionals (!stdenv.isDarwin) ["--with-ossp-uuid"]
    ;

  patches = [
    ./disable-resolve_symlinks.patch
    ./less-is-more.patch
    ./postgresql-9.4-dont-check-private-key.patch
    ];

  installTargets = [ "install-world" ];

  LC_ALL = "C";

  passthru = {
    inherit readline;
    psqlSchema = "9.2";
  };

  meta = {
    homepage = http://www.postgresql.org/;
    description = "A powerful, open source object-relational database system";
    license = stdenv.lib.licenses.postgresql;
    maintainers = [ stdenv.lib.maintainers.ocharles ];
    hydraPlatforms = stdenv.lib.platforms.linux;
  };
}
