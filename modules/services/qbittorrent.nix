{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.homelab.services.qbittorrent;
in
{
  options.homelab.services.qbittorrent = {
    enable = mkEnableOption "qBittorrent torrent client";

    domain = mkOption {
      type = types.str;
      default = "qbittorrent.localhost";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Web UI port";
    };

    torrentPort = mkOption {
      type = types.port;
      default = 6881;
      description = "Torrent listening port";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/mnt/data/torrents";
      description = "Download directory";
    };

    configDir = mkOption {
      type = types.str;
      default = "/var/lib/qbittorrent";
      description = "Configuration directory";
    };

    user = mkOption {
      type = types.str;
      default = "qbittorrent";
    };

    group = mkOption {
      type = types.str;
      default = "media";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.configDir;
      createHome = true;
    };

    systemd.services.qbittorrent = {
      description = "qBittorrent-nox service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=${toString cfg.port}";
        Restart = "on-failure";
        StateDirectory = "qbittorrent";
      };
    };

    # Firewall
    networking.firewall = {
      allowedTCPPorts = [ cfg.port cfg.torrentPort ];
      allowedUDPPorts = [ cfg.torrentPort ];
    };

    # Ensure directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.configDir} 0750 ${cfg.user} ${cfg.group} -"
    ];
  };
}
