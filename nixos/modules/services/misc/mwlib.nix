{ config, lib, pkgs, ... }:
let
  pypkgs = pkgs.python27Packages;

  inherit (lib) types mkOption mkIf optionalString
                concatStringsSep concatMapStringsSep;
  inherit (config.services.mwlib) nserve qserve nslave;
  inherit (pypkgs) python mwlib;

  user = mkOption {
    default = "nobody";
    type = types.str;
    description = "User to run as.";
  };
in
{

  options.services.mwlib = {

    nserve = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to enable nserve. Nserve is a HTTP
          server.  The Collection extension is talking to
          that program directly.  Nserve uses at least
          one qserve instance in order to distribute
          and manage jobs.
        '';
      }; # nserve.enable

      port = mkOption {
        default = 8899;
        type = types.int;
        description = "Specify port to listen on.";
      }; # nserve.port

      address = mkOption {
        default = "127.0.0.1";
        type = types.str;
        description = "Specify network interface to listen on.";
      }; # nserve.address

      qserve = mkOption {
        default = [ "${qserve.address}:${toString qserve.port}" ];
        type = types.listOf types.str;
        description = "Register qserve instance.";
      }; # nserve.qserve

      inherit user;
    }; # nserve

    qserve = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          A job queue server used to distribute and manage
          jobs. You should start one qserve instance
          for each machine that is supposed to render pdf
          files. Unless you’re operating the Wikipedia
          installation, one machine should suffice.
        '';
      }; # qserve.enable

      port = mkOption {
        default = 14311;
        type = types.int;
        description = "Specify port to listen on.";
      }; # qserve.port

      address = mkOption {
        default = "127.0.0.1";
        type = types.str;
        description = "Specify network interface to listen on.";
      }; # qserve.address

      datadir = mkOption {
        default = "/var/lib/mwlib-qserve";
        type = types.path;
        description = "qserve data directory (FIXME: unused?)";
      }; # qserve.datadir

      allow = mkOption {
        default = [ "127.0.0.1" ];
        type = types.listOf types.str;
        description = "List of allowed client IPs. Empty means any.";
      }; # qserve.allow

      inherit user;
    }; # qserve

    nslave = {
      enable = mkOption {
        default = qserve.enable;
        type = types.bool;
        description = ''
          Pulls new jobs from exactly one qserve instance
          and calls the zip and render programs
          in order to download article collections and
          convert them to different output formats. Nslave
          uses a cache directory to store the generated
          documents. Nslave also starts an internal http
          server serving the content of the cache directory.
        '';
      }; # nslave.enable

      cachedir = mkOption {
        default = "/var/cache/mwlib-nslave";
        type = types.path;
        description = "Directory to store generated documents.";
      }; # nslave.cachedir

      numprocs = mkOption {
        default = 10;
        type = types.int;
        description = "Number of parallel jobs to be executed.";
      }; # nslave.numprocs

      http = mkOption {
        default = {};
        description = ''
          Internal http server serving the content of the cache directory.
          You have to enable it, or use your own way for serving files
          and set the http.url option accordingly.
          '';
        type = types.submodule ({
          options = {
            enable = mkOption {
              default = true;
              type = types.bool;
              description = "Enable internal http server.";
            }; # nslave.http.enable

            port = mkOption {
              default = 8898;
              type = types.int;
              description = "Port to listen to when serving files from cache.";
            }; # nslave.http.port

            address = mkOption {
              default = "127.0.0.1";
              type = types.str;
              description = "Specify network interface to listen on.";
            }; # nslave.http.address

            url = mkOption {
              default = "http://localhost:${toString nslave.http.port}/cache";
              type = types.str;
              description = ''
                Specify URL for accessing generated files from cache.
                The Collection extension of Mediawiki won't be able to
                download files without it.
                '';
            }; # nslave.http.url
          };
        }); # types.submodule
      }; # nslave.http

      inherit user;
    }; # nslave

  }; # options.services

  config = { 

    systemd.services.mwlib-nserve = mkIf nserve.enable
    {
      description = "mwlib network interface";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "mwlib-qserve.service" ];

      serviceConfig = {
        ExecStart = concatStringsSep " " (
          [
            "${mwlib}/bin/nserve"
            "--port ${toString nserve.port}"
            "--interface ${nserve.address}"
          ] ++ nserve.qserve
        );
        User = nserve.user;
      };
    }; # systemd.services.mwlib-nserve

    systemd.services.mwlib-qserve = mkIf qserve.enable
    {
      description = "mwlib job queue server";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "local-fs.target" ];

      preStart = ''
        mkdir -pv '${qserve.datadir}'
        chown -Rc ${qserve.user}:`id -ng ${qserve.user}` '${qserve.datadir}'
        chmod -Rc u=rwX,go= '${qserve.datadir}'
      '';

      serviceConfig = {
        ExecStart = concatStringsSep " " (
          [
            "${mwlib}/bin/mw-qserve"
            "-p ${toString qserve.port}"
            "-i ${qserve.address}"
            "-d ${qserve.datadir}"
          ] ++ map (a: "-a ${a}") qserve.allow
        );
        User = qserve.user;
        PermissionsStartOnly = true;
      };
    }; # systemd.services.mwlib-qserve

    systemd.services.mwlib-nslave = mkIf nslave.enable
    {
      description = "mwlib worker";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "local-fs.target" ];

      preStart = ''
        mkdir -pv '${nslave.cachedir}'
        chown -Rc ${nslave.user}:`id -ng ${nslave.user}` '${nslave.cachedir}'
        chmod -Rc u=rwX,go= '${nslave.cachedir}'
      '';

      path = with pkgs; [ imagemagick pdftk ];
      environment = {
        PYTHONPATH = concatMapStringsSep ":"
          (m: "${pypkgs.${m}}/lib/${python.libPrefix}/site-packages")
          [ "mwlib-rl" "mwlib-ext" "pygments" "pyfribidi" ];
      };

      serviceConfig = {
        ExecStart = concatStringsSep " " (
          [
            "${mwlib}/bin/nslave"
            "--cachedir ${nslave.cachedir}"
            "--numprocs ${toString nslave.numprocs}"
            "--url ${nslave.http.url}"
          ] ++ (
            if nslave.http.enable then
            [
              "--serve-files-port ${toString nslave.http.port}"
              "--serve-files-address ${nslave.http.address}"
            ] else
            [
              "--no-serve-files"
            ]
          ));
        User = nslave.user;
        PermissionsStartOnly = true;
      };
    }; # systemd.services.mwlib-nslave

  }; # config
}
