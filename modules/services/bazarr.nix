{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.homelab.services.bazarr;
in
{
  options.homelab.services.bazarr = {
    enable = mkEnableOption "Bazarr subtitle manager";

    domain = mkOption {
      type = types.str;
      default = "bazarr.localhost";
    };

    port = mkOption {
      type = types.port;
      default = 6767;
      description = "Web UI port";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "/mnt/media";
      description = "Base media directory (must match Sonarr/Radarr)";
    };

    user = mkOption {
      type = types.str;
      default = "media";
    };

    group = mkOption {
      type = types.str;
      default = "media";
    };
  };

  config = mkIf cfg.enable {
    # Use built-in NixOS bazarr service
    services.bazarr = {
      enable = true;
      listenPort = cfg.port;
      openFirewall = true;
      user = cfg.user;
      group = cfg.group;
    };

    # Ensure media user/group exist
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = {};

    # Ensure media directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir}/tv 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir}/movies 0775 ${cfg.user} ${cfg.group} -"
    ];
  };
}
