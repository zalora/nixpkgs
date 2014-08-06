{ config, lib, pkgs, serverInfo, php, ... }:

with lib;

let

  mkHost = host: port: driver: with serverInfo.fullConfig.services;
    if port != null then "${host}:${toString port}"
    else if (host == "") || (host == "localhost") || (hasPrefix "/" host)
      then (
      if driver == "pgsql" then "${host}:${toString postgresql.port}" else
      if hasPrefix "mysql" driver then "${host}:${toString mysql.port}" else ""
    )
    else "${host}";

  defaultAuthServer = head config.servers;

  mywebsqlRoot = pkgs.stdenv.mkDerivation rec {
    name = "mywebsql";

    buildInputs = [ pkgs.unzip ];

    src = pkgs.fetchgit {
      rev = "98b544be7ccf3db54930070231c8308f869b8132";
      url = "https://github.com/zalora/MyWebSQL.git";
      sha256 = "1y5kz0fbkl0x86q3vcr98aa0smx2d13dql7c7la1gyj23wqh5jl6";
      /* Submodules are extra themes and available via ssh */
      fetchSubmodules = false;
    };

    patches = [
    ];

    installPhase =
      ''
        ensureDir $out
        cp -r * $out
        rm \
          $out/config/auth.php \
          $out/config/config.php \
          $out/config/database.php \
          $out/config/servers.php \
          $out/install.php
        cp ${authConfig} $out/config/auth.php
        cp ${configConfig} $out/config/config.php
        cp ${databaseConfig} $out/config/database.php
        cp ${serversConfig} $out/config/servers.php
      '';

    authConfig = with defaultAuthServer; pkgs.writeText "auth.php"
      ''
        <?php
        define('AUTH_TYPE', '${config.authType}');
        define('AUTH_LOGIN', '${config.authLogin}');
        define('AUTH_PASSWORD', '${config.authPassword}');
        define('SECURE_LOGIN', ${if config.secureLogin then "TRUE" else "FALSE"});
        ?>
      '';

    configConfig = pkgs.writeText "config.php"
      ''
        <?php
        define('DEFAULT_EDITOR', '${config.editor}');
        define('DEFAULT_LANGUAGE', '${config.langauge}');
        define('DEFAULT_THEME', '${config.theme}');
        define('HOTKEYS_ENABLED', ${if config.hotkeys then "TRUE" else "FALSE"});
        define('LOG_MESSAGES', ${if config.logMessages then "TRUE" else "FALSE"});
        define('MAX_RECORD_TO_DISPLAY', ${toString config.maxRecordsToDisplay});
        define('MAX_TEXT_LENGTH_DISPLAY', ${toString config.maxTextLengthDisplay});
        ${optionalString (config.traceFilePath != null) "define('TRACE_FILEPATH', '${config.traceFilePath}');"}
        define('TRACE_MESSAGES', ${if config.traceMessages then "TRUE" else "FALSE"});
        ?>
      '';

    databaseConfig = pkgs.writeText "database.php"
      ''
        <?php
        $DB_LIST = array(
        ${concatStringsSep ",\n"
          (map (s: "'${s.title}' => array ( " + (concatStringsSep ", " (map (d: "'${d}'") s.databases)) + " )")
            (filter (s: s.databases != null) config.servers)
          )
         }
        );
        ?>
      '';

    serversConfig = pkgs.writeText "servers.php"
      ''
        <?php
        $ALLOW_CUSTOM_SERVERS = ${if config.allowCustomServers then "TRUE" else "FALSE"};
        $ALLOW_CUSTOM_SERVER_TYPES = 'mysqli,pgsql';
        $SERVER_LIST = array(
        ${concatStringsSep ",\n"
            (map (s: ''
               '${s.title}' => array (
                 'host' => '${mkHost s.host s.port s.driver}'
               , 'driver' => '${s.driver}'
               ${optionalString s.ssl.enable ''
                 , 'ssl' => TRUE
                 ${optionalString (s.ssl.userPath != null) ", 'ssl-user-path' => '${s.ssl.userPath}'"}
                 ${optionalString s.ssl.verifyServerCert ''
                   , 'ssl-verify-server-cert' => TRUE
                   ${optionalString (s.ssl.CA != null) ", 'ssl-ca' => '${s.ssl.CA}'"}
                   ''}
               ''}
               )
               '')
              config.servers
            )
         }
        );
        ?>
      '';
  };

in
{
  enablePHP = true;

  extraConfig =
    ''
      ${optionalString (config.urlPrefix != "") ''
        Alias ${config.urlPrefix} ${mywebsqlRoot}
      ''}

      <Directory ${mywebsqlRoot}>
          Order allow,deny
          Allow from all
          DirectoryIndex index.php
      </Directory>
    '';

  options = {

    urlPrefix = mkOption {
      type = types.string;
      default = "/mywebsql";
      description = ''
        The URL prefix under which the MyWebSQL service appears.
      '';
    };

    authType = mkOption {
      type = types.enum [ "LOGIN" "BASIC" "NONE" "SPROXY" ];
      default = "LOGIN";
      description = ''
        defines the login/startup behaviour of the application
        NONE    = no userid/password is asked for
        BASIC   = browser requests authentication dialog
        LOGIN   = user enters userid and password manually
        SPROXY  = use Sproxy for authenticating users via Google OAuth2
      '';
    };

    authLogin = mkOption {
      default = "test";
      description = ''
        User name to connect to the server (for authType "NONE")
      '';
    };

    authPassword = mkOption {
      type = types.string;
      default = "";
      description = ''
        Password to connect to the server (for authType "NONE")
      '';
    };

    secureLogin = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Avoid sending plain text login info for
        additional security (disabled for HTTPS
        automatically). Requires openssl and gmp
        extenstions.
      '';
    };

    logMessages = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Send 'critical' messages to the PHP default log file (including failed queries)
      '';
    };

    traceMessages = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Logs verbose stuff to the trace file (only enable for debugging)
      '';
    };

    traceFilePath = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/tmp/mywebsql.log";
      description = ''
        Use this log file instead of the PHP default one (only when traceMessages is enabled)
      '';
    };

    maxRecordsToDisplay = mkOption {
      type = types.int;
      default = 100;
      description = ''
        Only this much records will be shown in browser at one time to keep it responsive
      '';
    };

    maxTextLengthDisplay = mkOption {
      type = types.int;
      default = 80;
      description = ''
        Blobs/text size larger than this is truncated in grid view format
      '';
    };

    editor = mkOption {
      type = types.enum [ "simple" "codemirror" "codemirror2" ];
      default = "codemirror";
      description = ''
        Default editor
      '';
    };

    theme = mkOption {
      type = types.enum [ "aero" "bootstrap" "chocolate"
        "dark" "default" "human" "light" "paper" "pinky" ];
      default = "default";
      description = ''
        Default theme
      '';
    };

    langauge = mkOption {
      type = types.enum [ "af" "bg" "ca" "cs" "da" "de"
        "el" "en" "es" "et" "fi" "fr" "gl" "he" "hr" "hu"
        "id" "it" "ja" "ko" "lt" "lv" "ms" "nl" "no" "pl" "pt"
        "ro" "ru" "sk" "sl" "sq" "sr" "sv" "th" "tr" "uk" "zh" ];
      default = "en";
      description = ''
        Default langauge
      '';
    };

    hotkeys = mkOption {
      type = types.bool;
      default = true;
      description = ''
       Enable hotkeys
      '';
    };

    allowCustomServers = mkOption {
      type = types.bool;
      default = false;
      description = ''
       Allow a free form server name to be entered instead
       of selecting existing one from the list
      '';
    };

    servers = mkOption {
      type = types.listOf (
        types.submodule (
        { options, ... }:
        { options = {
            title = mkOption {
              type = types.string;
              default = "";
              description = ''
                Name of the server for displaying to user
              '';
            };
            host = mkOption {
              type = types.string;
              default = "/tmp";
              description = ''
                Database host (hostname, unix socket directory, IP, etc.)
              '';
            };
            port = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = ''
                Database port
              '';
            };
            driver = mkOption {
              type = types.enum [ "pgsql" "mysqli" "mysql5" ];
              default = "pgsql";
              description = ''
                Database driver (PHP extension)
              '';
            };
            databases = mkOption {
              type = types.nullOr (types.listOf types.string);
              default = null;
              description = ''
                Available databases (null means all);
              '';
            };
            ssl = mkOption {
              default = {
                enable = false;
                CA = null;
                userPath = null;
              };
              type =  types.submodule (
                { options, ... }:
                { options = {
                  enable = mkOption {
                    type = types.bool;
                    default = false;
                    description = ''
                       Enable SSL connections
                    '';
                  };
                  verifyServerCert = mkOption {
                    type = types.bool;
                    default = false;
                    description = ''
                       Verify server SSL certificate
                    '';
                  };
                  CA = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    example = "/run/my-ca-cert.pem";
                    description = ''
                       Certificate Authority (CA) certificate
                    '';
                  };
                  userPath = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    example = "/var/ssl/users";
                    description = ''
                      Directory with client SSL keys and certificates
                    '';
                  };
                };
              });
            };
          };
        })
      );
      default = [
        {
          title = "Local PostgreSQL server";
          host = "/tmp";
          driver = "pgsql";
        }
        {
          title = "Local MySQL server";
          host = "localhost";
          driver = "mysqli";
          databases = [ "test" ];
        }
      ];
      example = [
        {
          title = "Local PostgreSQL server";
          host = "localhost";
          port = 5432;
          driver = "pgsql";
          databases = [ "testdb" ];
        }
      ];
      description = ''
       Defining more that one server here will give user
       the option to select a server at login time. Used
       only when authType is LOGIN. The first server in this list
       is used when authType is NONE or BASIC.
      '';
    };

  }; /* options */

  extraPath = [ ];

}
