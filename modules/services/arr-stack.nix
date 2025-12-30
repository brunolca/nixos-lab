{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.homelab.services.arr;

  # Config templates with placeholder for API key
  sonarrConfigTemplate = pkgs.writeText "sonarr-config.xml" ''
    <Config>
      <LogLevel>info</LogLevel>
      <EnableSsl>False</EnableSsl>
      <Port>8989</Port>
      <UrlBase></UrlBase>
      <BindAddress>*</BindAddress>
      <ApiKey>@API_KEY@</ApiKey>
      <AuthenticationMethod>None</AuthenticationMethod>
      <UpdateMechanism>BuiltIn</UpdateMechanism>
      <Branch>main</Branch>
      <LaunchBrowser>False</LaunchBrowser>
      <AnalyticsEnabled>False</AnalyticsEnabled>
    </Config>
  '';

  radarrConfigTemplate = pkgs.writeText "radarr-config.xml" ''
    <Config>
      <LogLevel>info</LogLevel>
      <EnableSsl>False</EnableSsl>
      <Port>7878</Port>
      <UrlBase></UrlBase>
      <BindAddress>*</BindAddress>
      <ApiKey>@API_KEY@</ApiKey>
      <AuthenticationMethod>None</AuthenticationMethod>
      <UpdateMechanism>BuiltIn</UpdateMechanism>
      <Branch>master</Branch>
      <LaunchBrowser>False</LaunchBrowser>
      <AnalyticsEnabled>False</AnalyticsEnabled>
    </Config>
  '';

  prowlarrConfigTemplate = pkgs.writeText "prowlarr-config.xml" ''
    <Config>
      <LogLevel>info</LogLevel>
      <EnableSsl>False</EnableSsl>
      <Port>9696</Port>
      <UrlBase></UrlBase>
      <BindAddress>*</BindAddress>
      <ApiKey>@API_KEY@</ApiKey>
      <AuthenticationMethod>None</AuthenticationMethod>
      <UpdateMechanism>BuiltIn</UpdateMechanism>
      <Branch>master</Branch>
      <LaunchBrowser>False</LaunchBrowser>
      <AnalyticsEnabled>False</AnalyticsEnabled>
    </Config>
  '';
in
{
  options.homelab.services.arr = {
    enable = mkEnableOption "*arr media management stack";

    enableSecrets = mkOption {
      type = types.bool;
      default = false;
      description = "Enable declarative secrets management via sops-nix";
    };

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

    # Sops secrets declarations
    sops.secrets = mkIf cfg.enableSecrets {
      "media/api-keys/sonarr" = mkIf cfg.sonarr.enable {
        owner = cfg.user;
        group = cfg.group;
        mode = "0440";
        restartUnits = [ "sonarr.service" ];
      };
      "media/api-keys/radarr" = mkIf cfg.radarr.enable {
        owner = cfg.user;
        group = cfg.group;
        mode = "0440";
        restartUnits = [ "radarr.service" ];
      };
      "media/api-keys/prowlarr" = mkIf cfg.prowlarr.enable {
        owner = "prowlarr";
        group = "prowlarr";
        mode = "0440";
        restartUnits = [ "prowlarr.service" ];
      };
    };

    # Sonarr - TV Shows
    services.sonarr = mkIf cfg.sonarr.enable {
      enable = true;
      openFirewall = true;
      user = cfg.user;
      group = cfg.group;
    };

    systemd.services.sonarr = mkIf (cfg.sonarr.enable && cfg.enableSecrets) {
      preStart = ''
        # Inject API key from sops secret into config
        API_KEY=$(cat ${config.sops.secrets."media/api-keys/sonarr".path})
        ${pkgs.gnused}/bin/sed "s/@API_KEY@/$API_KEY/g" ${sonarrConfigTemplate} \
          > /var/lib/sonarr/.config/Sonarr/config.xml
        chown ${cfg.user}:${cfg.group} /var/lib/sonarr/.config/Sonarr/config.xml
        chmod 0600 /var/lib/sonarr/.config/Sonarr/config.xml
      '';
    };

    # Radarr - Movies
    services.radarr = mkIf cfg.radarr.enable {
      enable = true;
      openFirewall = true;
      user = cfg.user;
      group = cfg.group;
    };

    systemd.services.radarr = mkIf (cfg.radarr.enable && cfg.enableSecrets) {
      preStart = ''
        # Inject API key from sops secret into config
        API_KEY=$(cat ${config.sops.secrets."media/api-keys/radarr".path})
        ${pkgs.gnused}/bin/sed "s/@API_KEY@/$API_KEY/g" ${radarrConfigTemplate} \
          > /var/lib/radarr/.config/Radarr/config.xml
        chown ${cfg.user}:${cfg.group} /var/lib/radarr/.config/Radarr/config.xml
        chmod 0600 /var/lib/radarr/.config/Radarr/config.xml
      '';
    };

    # Prowlarr - Indexer Manager
    services.prowlarr = mkIf cfg.prowlarr.enable {
      enable = true;
      openFirewall = true;
    };

    systemd.services.prowlarr = mkIf (cfg.prowlarr.enable && cfg.enableSecrets) {
      preStart = ''
        # Inject API key from sops secret into config
        API_KEY=$(cat ${config.sops.secrets."media/api-keys/prowlarr".path})
        ${pkgs.gnused}/bin/sed "s/@API_KEY@/$API_KEY/g" ${prowlarrConfigTemplate} \
          > /var/lib/prowlarr/.config/Prowlarr/config.xml
        chown prowlarr:prowlarr /var/lib/prowlarr/.config/Prowlarr/config.xml
        chmod 0600 /var/lib/prowlarr/.config/Prowlarr/config.xml
      '';
    };

    # Ensure directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir}/tv 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir}/movies 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.downloadDir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.downloadDir}/tv 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.downloadDir}/movies 0775 ${cfg.user} ${cfg.group} -"
    ] ++ (optionals cfg.enableSecrets [
      # Config directories for secret injection
      "d /var/lib/sonarr/.config/Sonarr 0750 ${cfg.user} ${cfg.group} -"
      "d /var/lib/radarr/.config/Radarr 0750 ${cfg.user} ${cfg.group} -"
      "d /var/lib/prowlarr/.config/Prowlarr 0750 prowlarr prowlarr -"
    ]);
  };
}
