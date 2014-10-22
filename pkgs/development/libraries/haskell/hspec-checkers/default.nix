{ cabal, hspec, checkers }:

cabal.mkDerivation (self: {
  pname = "hspec-checkers";
  version = "0.1.0";
  sha256 = "043qzgjp9ch9wqm269dd87jn8wk5c90q25098hnz8ilv5pnywk6d";
  buildDepends = [ hspec checkers ];
  testDepends = [ hspec checkers ];
  meta = {
    homepage = "https://github.com/zalora/hspec-checkers";
    description = "Allows to use checkers properties from hspec";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
