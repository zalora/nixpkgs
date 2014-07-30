# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, deepseq }:

cabal.mkDerivation (self: {
  pname = "text";
  version = "0.11.0.6";
  sha256 = "103l1c8jfwpddsqzwj9jqh89vay8ax1znxqgjqprv2fvr7s0zvkp";
  buildDepends = [ deepseq ];
  doCheck = false;
  meta = {
    homepage = "http://bitbucket.org/bos/text";
    description = "An efficient packed Unicode text type";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.andres ];
  };
})
