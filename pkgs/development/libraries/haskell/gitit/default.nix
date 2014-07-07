{ cabal, base64Bytestring, blazeHtml, ConfigFile, feed, filepath
, filestore, ghcPaths, happstackServer, highlightingKate, hslogger
, HStringTemplate, HTTP, json, mtl, network, pandoc, pandocTypes
, parsec, random, recaptcha, safe, SHA, split, syb, tagsoup, text
, time, uri, url, utf8String, xhtml, xml, xssSanitize, zlib
}:

cabal.mkDerivation (self: {
  pname = "gitit";
  version = "0.10.4";
  sha256 = "1z06v1pamrpm70zisrw3z3kv0d19dsjkmm75pvj5yxkacxv7qk7n";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [
    base64Bytestring blazeHtml ConfigFile feed filepath filestore
    ghcPaths happstackServer highlightingKate hslogger HStringTemplate
    HTTP json mtl network pandoc pandocTypes parsec random recaptcha
    safe SHA split syb tagsoup text time uri url utf8String xhtml xml
    xssSanitize zlib
  ];
  jailbreak = true;
  meta = {
    homepage = "http://gitit.net";
    description = "Wiki using happstack, git or darcs, and pandoc";
    license = "GPL";
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.andres ];
  };
})
