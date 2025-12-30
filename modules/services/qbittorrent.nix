{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.homelab.services.qbittorrent;

  # Config template with password hash placeholder
  qbittorrentConfigTemplate = pkgs.writeText "qBittorrent.conf" ''
    [BitTorrent]
    Session\Port=${toString cfg.torrentPort}

    [LegalNotice]
    Accepted=true

    [Preferences]
    Downloads\SavePath=${cfg.downloadDir}
    WebUI\LocalHostAuth=false
    WebUI\Port=${toString cfg.port}
    WebUI\Username=admin
    WebUI\Password_PBKDF2=@PASSWORD_HASH@
  '';
in
{
  options.homelab.services.qbittorrent = {
    enable = mkEnableOption "qBittorrent torrent client";

    enableSecrets = mkOption {
      type = types.bool;
      default = false;
      description = "Enable declarative secrets management via sops-nix";
    };

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

    users.groups.${cfg.group} = {};

    # Sops secrets declaration
    sops.secrets = mkIf cfg.enableSecrets {
      "media/qbittorrent/password-hash" = {
        owner = cfg.user;
        group = cfg.group;
        mode = "0440";
        restartUnits = [ "qbittorrent.service" ];
      };
    };

    systemd.services.qbittorrent = {
      description = "qBittorrent-nox service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = mkIf cfg.enableSecrets ''
        # Ensure config directory exists
        mkdir -p ${cfg.configDir}/.config/qBittorrent

        # Inject password hash from sops secret
        PASSWORD_HASH=$(cat ${config.sops.secrets."media/qbittorrent/password-hash".path})
        ${pkgs.gnused}/bin/sed "s|@PASSWORD_HASH@|$PASSWORD_HASH|g" ${qbittorrentConfigTemplate} \
          > ${cfg.configDir}/.config/qBittorrent/qBittorrent.conf
        chown ${cfg.user}:${cfg.group} ${cfg.configDir}/.config/qBittorrent/qBittorrent.conf
        chmod 0600 ${cfg.configDir}/.config/qBittorrent/qBittorrent.conf
      '';

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
    ] ++ (optionals cfg.enableSecrets [
      "d ${cfg.configDir}/.config/qBittorrent 0750 ${cfg.user} ${cfg.group} -"
    ]);
  };
}
