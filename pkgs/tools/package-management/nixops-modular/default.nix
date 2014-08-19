{ pythonPackages, pkgs,
  fetchgit, libxslt, docbook5_xsl, openssh }:

let

  getNixModule = src: name: "${src}/nix/${name}.nix";

in

pythonPackages.buildPythonPackage rec {
  name = "nixops-modular-1.2";
  namePrefix = "";

  src = fetchgit {
    url = "https://github.com/zalora/nixops.git";
    rev = "630cb0d";
    sha256 = "18p1z57q4xdbiwigdrzwcyczry7cjbdkg0j44nkcdm0r07qc6i25";
  };

  manual = "${src}/doc/manual";
  manualResource = "${manual}/resource.nix";

  buildInputs = [ libxslt ];

  pythonPath =
    [ pythonPackages.prettytable
      pythonPackages.boto
      pythonPackages.sqlite3
      pythonPackages.hetzner
    ];

  doCheck = false;

  postInstall =
    ''

    cp ${import manual { revision = src.rev; }} doc/manual/machine-options.xml
    ${pkgs.lib.concatMapStrings (fn: ''
        cp ${import manualResource { revision = src.rev; module = (getNixModule src fn); }} doc/manual/${fn}-options.xml
        '') [ "sqs-queue" "ec2-keypair" "s3-bucket" "iam-role" "ssh-keypair" ]}

      make -C doc/manual install docbookxsl=${docbook5_xsl}/xml/xsl/docbook \
        docdir=$out/share/doc/nixops mandir=$out/share/man

      mkdir -p $out/share/nix/nixops
      cp -av nix/* $out/share/nix/nixops

      # Add openssh to nixops' PATH. On some platforms, e.g. CentOS and RHEL
      # the version of openssh is causing errors when have big networks (40+)
      wrapProgram $out/bin/nixops --prefix PATH : "${openssh}/bin"
    '';

  meta = {
    homepage = https://github.com/zalora/nixops;
    description = "Modular NixOS cloud provisioning and deployment tool";
  };
}
