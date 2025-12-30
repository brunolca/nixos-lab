{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.homelab.services.jellyfin;
in
{
  options.homelab.services.jellyfin = {
    enable = mkEnableOption "Jellyfin media server";

    domain = mkOption {
      type = types.str;
      default = "jellyfin.localhost";
      description = "Domain for Jellyfin";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "/mnt/media";
      description = "Path to media directory";
    };
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    # Ensure media directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0755 jellyfin jellyfin -"
    ];
  };
}
