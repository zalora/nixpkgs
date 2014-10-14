{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.services.syslog-ng;

  syslogngConfig = pkgs.writeText "syslog-ng.conf" ''
    @version: 3.5
    @include "scl.conf"
    ${cfg.extraConfig}
  '';

  ctrlSocket = "/run/syslog-ng/syslog-ng.ctl";
  pidFile = "/run/syslog-ng/syslog-ng.pid";
  persistFile = "/var/syslog-ng/syslog-ng.persist";

  syslogngOptions = [
    "--foreground"
    "--module-path=${concatStringsSep ":" (["${cfg.package}/lib/syslog-ng"] ++ cfg.extraModulePaths)}"
    "--cfgfile=${syslogngConfig}"
    "--control=${ctrlSocket}"
    "--persist-file=${persistFile}"
    "--pidfile=${pidFile}"
  ];

in {

  options = {

    services.syslog-ng = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the syslog-ng daemon.
        '';
      };
      package = mkOption {
        type = types.package;
        default = pkgs.syslogng;
        description = ''
          The package providing syslog-ng binaries.
        '';
      };
      listenToJournal = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether syslog-ng should listen to the syslog socket used
          by journald, and therefore receive all logs that journald
          produces.
        '';
      };
      extraModulePaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "${pkgs.syslogng_incubator}/lib/syslog-ng" ];
        description = ''
          A list of paths that should be included in syslog-ng's
          <literal>--module-path</literal> option. They should usually
          end in <literal>/lib/syslog-ng</literal>
        '';
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Configuration added to the end of <literal>syslog-ng.conf</literal>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.sockets.syslog = mkIf cfg.listenToJournal {
      wantedBy = [ "sockets.target" ];
      socketConfig.Service = "syslog-ng.service";
    };
    systemd.services.syslog-ng = {
      description = "syslog-ng daemon";
      preStart = "mkdir -p /{var,run}/syslog-ng";
      wantedBy = optional (!cfg.listenToJournal) "multi-user.target";
      after = [ "multi-user.target" ]; # makes sure hostname etc is set
      serviceConfig = {
        Type = "notify";
        Sockets = if cfg.listenToJournal then "syslog.socket" else null;
        StandardOutput = "null";
        Restart = "on-failure";
        ExecStart = "${cfg.package}/sbin/syslog-ng ${concatStringsSep " " syslogngOptions}";
      };
    };
  };

}
