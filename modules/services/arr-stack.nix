{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.homelab.services.arr;
in
{
  options.homelab.services.arr = {
    enable = mkEnableOption "*arr media management stack";

    sonarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Sonarr (TV shows)";
      };
      domain = mkOption {
        type = types.str;
        default = "sonarr.localhost";
      };
    };

    radarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Radarr (Movies)";
      };
      domain = mkOption {
        type = types.str;
        default = "radarr.localhost";
      };
    };

    prowlarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prowlarr (Indexer manager)";
      };
      domain = mkOption {
        type = types.str;
        default = "prowlarr.localhost";
      };
    };

    mediaDir = mkOption {
      type = types.str;
      default = "/mnt/media";
      description = "Base path for media";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/mnt/data/torrents";
      description = "Base path for downloads";
    };

    user = mkOption {
      type = types.str;
      default = "media";
      description = "User for media services";
    };

    group = mkOption {
      type = types.str;
      default = "media";
      description = "Group for media services";
    };
  };

  config = mkIf cfg.enable {
    # Create media user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = {};

    # Sonarr - TV Shows
    services.sonarr = mkIf cfg.sonarr.enable {
      enable = true;
      openFirewall = true;
      user = cfg.user;
      group = cfg.group;
    };

    # Radarr - Movies
    services.radarr = mkIf cfg.radarr.enable {
      enable = true;
      openFirewall = true;
      user = cfg.user;
      group = cfg.group;
    };

    # Prowlarr - Indexer Manager
    services.prowlarr = mkIf cfg.prowlarr.enable {
      enable = true;
      openFirewall = true;
    };

    # Ensure directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir}/tv 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir}/movies 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.downloadDir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.downloadDir}/tv 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.downloadDir}/movies 0775 ${cfg.user} ${cfg.group} -"
    ];
  };
}
