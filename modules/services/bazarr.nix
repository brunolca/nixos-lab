{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.homelab.services.bazarr;

  # Bazarr config template with placeholders for secrets
  bazarrConfigTemplate = pkgs.writeText "bazarr-config.ini" ''
    [general]
    port = ${toString cfg.port}
    base_url = /
    debug = False
    branch = master
    auto_update = False
    single_language = False
    minimum_score = 0
    use_scenename = True
    use_postprocessing = False
    postprocessing_cmd =
    use_postprocessing_threshold = False
    postprocessing_threshold = 90
    use_embedded_subs = True
    embedded_subs_show_desired = True
    utf8_encode = True
    ignore_pgs_subs = False
    ignore_vobsub_subs = False
    ignore_ass_subs = False
    adaptive_searching = True
    enabled_providers = ["opensubtitles"]

    [sonarr]
    ip = 127.0.0.1
    port = 8989
    base_url = /
    apikey = @SONARR_API_KEY@
    ssl = False
    full_update = Daily
    only_monitored = False
    series_sync = 60
    episodes_sync = 60
    excluded_tags = []
    excluded_series_types = []

    [radarr]
    ip = 127.0.0.1
    port = 7878
    base_url = /
    apikey = @RADARR_API_KEY@
    ssl = False
    full_update = Daily
    only_monitored = False
    movies_sync = 60
    excluded_tags = []

    [opensubtitles]
    username = @OPENSUBTITLES_USER@
    password = @OPENSUBTITLES_PASS@

    [subsync]
    use_subsync = False
    use_subsync_threshold = False
    subsync_threshold = 90
    use_subsync_movie_threshold = False
    subsync_movie_threshold = 70
    debug = False

    [analytics]
    enabled = False
  '';
in
{
  options.homelab.services.bazarr = {
    enable = mkEnableOption "Bazarr subtitle manager";

    enableSecrets = mkOption {
      type = types.bool;
      default = false;
      description = "Enable declarative secrets management via sops-nix";
    };

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

    # Sops secrets declarations
    sops.secrets = mkIf cfg.enableSecrets {
      "media/api-keys/sonarr" = {
        owner = cfg.user;
        group = cfg.group;
        mode = "0440";
      };
      "media/api-keys/radarr" = {
        owner = cfg.user;
        group = cfg.group;
        mode = "0440";
      };
      "media/bazarr/opensubtitles/username" = {
        owner = cfg.user;
        group = cfg.group;
        mode = "0440";
        restartUnits = [ "bazarr.service" ];
      };
      "media/bazarr/opensubtitles/password" = {
        owner = cfg.user;
        group = cfg.group;
        mode = "0440";
        restartUnits = [ "bazarr.service" ];
      };
    };

    # Inject secrets into config before service starts
    systemd.services.bazarr = mkIf cfg.enableSecrets {
      after = [ "sonarr.service" "radarr.service" ];

      preStart = ''
        # Ensure config directory exists
        mkdir -p /var/lib/bazarr

        # Read all required secrets
        SONARR_KEY=$(cat ${config.sops.secrets."media/api-keys/sonarr".path})
        RADARR_KEY=$(cat ${config.sops.secrets."media/api-keys/radarr".path})
        OPENSUB_USER=$(cat ${config.sops.secrets."media/bazarr/opensubtitles/username".path})
        OPENSUB_PASS=$(cat ${config.sops.secrets."media/bazarr/opensubtitles/password".path})

        # Multi-stage substitution to generate config
        cat ${bazarrConfigTemplate} \
          | ${pkgs.gnused}/bin/sed "s/@SONARR_API_KEY@/$SONARR_KEY/g" \
          | ${pkgs.gnused}/bin/sed "s/@RADARR_API_KEY@/$RADARR_KEY/g" \
          | ${pkgs.gnused}/bin/sed "s/@OPENSUBTITLES_USER@/$OPENSUB_USER/g" \
          | ${pkgs.gnused}/bin/sed "s/@OPENSUBTITLES_PASS@/$OPENSUB_PASS/g" \
          > /var/lib/bazarr/config/config.ini

        chown ${cfg.user}:${cfg.group} /var/lib/bazarr/config/config.ini
        chmod 0600 /var/lib/bazarr/config/config.ini
      '';
    };

    # Ensure media directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir}/tv 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir}/movies 0775 ${cfg.user} ${cfg.group} -"
    ] ++ (optionals cfg.enableSecrets [
      "d /var/lib/bazarr/config 0750 ${cfg.user} ${cfg.group} -"
    ]);
  };
}
