{ cabal, mysqlConfig, zlib, openssl }:

cabal.mkDerivation (self: {
  pname = "mysql";
  version = "0.1.1.7";
  sha256 = "0hl8z8ynadvvhn4garjrax2b59iqddj884mv3s6804lcjjyc49d0";
  buildTools = [ mysqlConfig ];
  extraLibraries = [ zlib openssl ];
  meta = {
    homepage = "https://github.com/bos/mysql";
    description = "A low-level MySQL client library";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
