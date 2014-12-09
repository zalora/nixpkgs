{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) ntp;

  stateDir = "/var/lib/ntp";

  ntpUser = "ntp";

  configFile = pkgs.writeText "ntp.conf" ''
    # Keep the drift file in ${stateDir}/ntp.drift.  However, since we
    # chroot to ${stateDir}, we have to specify it as /ntp.drift.
    driftfile /ntp.drift

    restrict default kod nomodify notrap nopeer noquery
    restrict -6 default kod nomodify notrap nopeer noquery
    restrict 127.0.0.1
    restrict -6 ::1

    ${toString (map (server: "server " + server + " iburst\n") config.services.ntp.servers)}
  '';

  ntpFlags = "-c ${configFile} -u ${ntpUser}:nogroup -i ${stateDir}";

in

{

  ###### interface

  options = {

    services.ntp = {

      enable = mkOption {
        default = !config.boot.isContainer;
        description = ''
          Whether to synchronise your machine's time using the NTP
          protocol.
        '';
      };

      servers = mkOption {
        default = [
          "0.nixos.pool.ntp.org"
          "1.nixos.pool.ntp.org"
          "2.nixos.pool.ntp.org"
          "3.nixos.pool.ntp.org"
        ];
        description = ''
          The set of NTP servers from which to synchronise.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf config.services.ntp.enable {

    # Make tools such as ntpq available in the system path
    environment.systemPackages = [ pkgs.ntp ];

    users.extraUsers = singleton
      { name = ntpUser;
        uid = config.ids.uids.ntp;
        description = "NTP daemon user";
        home = stateDir;
      };

    jobs.ntpd =
      { description = "NTP Daemon";

        wantedBy = [ "multi-user.target" ];

        path = [ ntp ];

        preStart =
          ''
            mkdir -m 0755 -p ${stateDir}
            chown ${ntpUser} ${stateDir}
          '';

        exec = "ntpd -g -n ${ntpFlags}";
      };

  };

}
