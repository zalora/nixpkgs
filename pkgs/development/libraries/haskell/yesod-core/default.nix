# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, aeson, async, blazeBuilder, blazeHtml, blazeMarkup
, caseInsensitive, cereal, clientsession, conduit, conduitExtra
, cookie, dataDefault, deepseq, exceptions, fastLogger, hspec
, httpTypes, HUnit, liftedBase, monadControl, monadLogger, mtl
, network, parsec, pathPieces, QuickCheck, random, resourcet, safe
, shakespeare, streamingCommons, text, time, transformers
, transformersBase, unixCompat, unorderedContainers, vector, wai
, waiExtra, waiLogger, warp
}:

cabal.mkDerivation (self: {
  pname = "yesod-core";
  version = "1.4.2";
  sha256 = "0qi1shmbsi8vkxzvyzqzgmdapnbfkkjvhkshkmr7rrdhkdbnkbxl";
  buildDepends = [
    aeson blazeBuilder blazeHtml blazeMarkup caseInsensitive cereal
    clientsession conduit conduitExtra cookie dataDefault deepseq
    exceptions fastLogger httpTypes liftedBase monadControl monadLogger
    mtl parsec pathPieces random resourcet safe shakespeare text time
    transformers transformersBase unixCompat unorderedContainers vector
    wai waiExtra waiLogger warp
  ];
  testDepends = [
    async blazeBuilder conduit conduitExtra hspec httpTypes HUnit
    liftedBase network pathPieces QuickCheck random resourcet
    shakespeare streamingCommons text transformers wai waiExtra
  ];
  jailbreak = true;
  meta = {
    homepage = "http://www.yesodweb.com/";
    description = "Creation of type-safe, RESTful web applications";
    license = self.stdenv.lib.licenses.mit;
    platforms = self.ghc.meta.platforms;
  };
})
