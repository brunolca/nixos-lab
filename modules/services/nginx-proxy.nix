{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.homelab.services.nginx;
  homelabCfg = config.homelab.services;
in
{
  options.homelab.services.nginx = {
    enable = mkEnableOption "Nginx reverse proxy for homelab services";

    baseDomain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Base domain for services (e.g., brunofashionblog.fr)";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = false;
      description = "Enable ACME SSL certificates";
    };

    email = mkOption {
      type = types.str;
      default = "";
      description = "Email for ACME certificates";
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = cfg.enableSSL;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts = {
        # Jellyfin
        "jellyfin.${cfg.baseDomain}" = mkIf (homelabCfg ? jellyfin && homelabCfg.jellyfin.enable) {
          forceSSL = cfg.enableSSL;
          enableACME = cfg.enableSSL;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8096";
            proxyWebsockets = true;
          };
        };

        # Sonarr
        "sonarr.${cfg.baseDomain}" = mkIf (homelabCfg ? arr && homelabCfg.arr.enable && homelabCfg.arr.sonarr.enable) {
          forceSSL = cfg.enableSSL;
          enableACME = cfg.enableSSL;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8989";
          };
        };

        # Radarr
        "radarr.${cfg.baseDomain}" = mkIf (homelabCfg ? arr && homelabCfg.arr.enable && homelabCfg.arr.radarr.enable) {
          forceSSL = cfg.enableSSL;
          enableACME = cfg.enableSSL;
          locations."/" = {
            proxyPass = "http://127.0.0.1:7878";
          };
        };

        # Prowlarr
        "prowlarr.${cfg.baseDomain}" = mkIf (homelabCfg ? arr && homelabCfg.arr.enable && homelabCfg.arr.prowlarr.enable) {
          forceSSL = cfg.enableSSL;
          enableACME = cfg.enableSSL;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9696";
          };
        };

        # qBittorrent
        "qbittorrent.${cfg.baseDomain}" = mkIf (homelabCfg ? qbittorrent && homelabCfg.qbittorrent.enable) {
          forceSSL = cfg.enableSSL;
          enableACME = cfg.enableSSL;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString (homelabCfg.qbittorrent.port or 8080)}";
          };
        };

        # Bazarr
        "bazarr.${cfg.baseDomain}" = mkIf (homelabCfg ? bazarr && homelabCfg.bazarr.enable) {
          forceSSL = cfg.enableSSL;
          enableACME = cfg.enableSSL;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString (homelabCfg.bazarr.port or 6767)}";
          };
        };
      };
    };

    # ACME configuration
    security.acme = mkIf cfg.enableSSL {
      acceptTerms = true;
      defaults.email = cfg.email;
    };

    # Open firewall
    networking.firewall.allowedTCPPorts = [ 80 ] ++ (if cfg.enableSSL then [ 443 ] else []);
  };
}
