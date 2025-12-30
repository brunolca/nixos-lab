{ config, lib, pkgs, ... }:

# Media stack - combines all media services for easy import
# Import this module and enable homelab.services.mediaStack

with lib;
let
  cfg = config.homelab.services.mediaStack;
in
{
  imports = [
    ./jellyfin.nix
    ./arr-stack.nix
    ./qbittorrent.nix
    ./nginx-proxy.nix
  ];

  options.homelab.services.mediaStack = {
    enable = mkEnableOption "Complete media stack";

    baseDomain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Base domain for all services";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "/mnt/media";
      description = "Base media directory";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/mnt/data/torrents";
      description = "Download directory for torrents";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = false;
      description = "Enable HTTPS with ACME";
    };

    acmeEmail = mkOption {
      type = types.str;
      default = "";
      description = "Email for ACME certificates";
    };
  };

  config = mkIf cfg.enable {
    # Enable all services
    homelab.services = {
      jellyfin = {
        enable = true;
        mediaDir = cfg.mediaDir;
      };

      arr = {
        enable = true;
        mediaDir = cfg.mediaDir;
        downloadDir = cfg.downloadDir;
      };

      qbittorrent = {
        enable = true;
        downloadDir = cfg.downloadDir;
      };

      nginx = {
        enable = true;
        baseDomain = cfg.baseDomain;
        enableSSL = cfg.enableSSL;
        email = cfg.acmeEmail;
      };
    };

    # Add qbittorrent user to media group for shared access
    users.users.qbittorrent.extraGroups = [ "media" ];
  };
}
