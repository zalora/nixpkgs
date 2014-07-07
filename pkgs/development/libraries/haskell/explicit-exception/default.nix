{ cabal, transformers }:

cabal.mkDerivation (self: {
  pname = "explicit-exception";
  version = "0.1.7.3";
  sha256 = "0f1p1llz6z4ag1wnf57mgm861cbw7va0g0m8klp6f6pnirdhlwz1";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [ transformers ];
  meta = {
    homepage = "http://www.haskell.org/haskellwiki/Exception";
    description = "Exceptions which are explicit in the type signature";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.andres ];
  };
})
