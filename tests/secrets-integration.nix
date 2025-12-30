# Secrets integration test - verifies config injection works
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "secrets-integration";

  nodes.machine = { config, pkgs, lib, ... }: {
    imports = [
      ../modules/services/arr-stack.nix
      ../modules/services/qbittorrent.nix
      ../modules/services/bazarr.nix
    ];

    virtualisation = {
      memorySize = 4096;
      cores = 4;
      diskSize = 4096;
    };

    documentation.enable = false;

    # Enable services with secrets
    homelab.services.arr = {
      enable = true;
      enableSecrets = true;
      mediaDir = "/var/lib/media";
      downloadDir = "/var/lib/torrents";
    };

    homelab.services.qbittorrent = {
      enable = true;
      enableSecrets = true;
      downloadDir = "/var/lib/torrents";
    };

    homelab.services.bazarr = {
      enable = true;
      enableSecrets = true;
      mediaDir = "/var/lib/media";
    };

    # Mock sops secrets with plaintext test values
    # In real deployment, sops-nix creates these from encrypted secrets
    sops.secrets = {
      "media/api-keys/sonarr".path = lib.mkForce "/run/secrets/media/api-keys/sonarr";
      "media/api-keys/radarr".path = lib.mkForce "/run/secrets/media/api-keys/radarr";
      "media/api-keys/prowlarr".path = lib.mkForce "/run/secrets/media/api-keys/prowlarr";
      "media/qbittorrent/password-hash".path = lib.mkForce "/run/secrets/media/qbittorrent/password-hash";
      "media/bazarr/opensubtitles/username".path = lib.mkForce "/run/secrets/media/bazarr/opensubtitles/username";
      "media/bazarr/opensubtitles/password".path = lib.mkForce "/run/secrets/media/bazarr/opensubtitles/password";
    };

    # Create mock secret files before services start
    system.activationScripts.mockSecrets = lib.stringAfter [ "users" "groups" ] ''
      mkdir -p /run/secrets/media/api-keys
      mkdir -p /run/secrets/media/qbittorrent
      mkdir -p /run/secrets/media/bazarr/opensubtitles

      echo -n "0000000000000000000000000000000000000000000000000000000000000001" > /run/secrets/media/api-keys/sonarr
      echo -n "0000000000000000000000000000000000000000000000000000000000000002" > /run/secrets/media/api-keys/radarr
      echo -n "0000000000000000000000000000000000000000000000000000000000000003" > /run/secrets/media/api-keys/prowlarr
      echo -n "@ByteArray(dGVzdHNhbHQ=:dGVzdGhhc2g=)" > /run/secrets/media/qbittorrent/password-hash
      echo -n "test_user" > /run/secrets/media/bazarr/opensubtitles/username
      echo -n "test_pass" > /run/secrets/media/bazarr/opensubtitles/password

      chmod 440 /run/secrets/media/api-keys/*
      chmod 440 /run/secrets/media/qbittorrent/*
      chmod 440 /run/secrets/media/bazarr/opensubtitles/*

      chown media:media /run/secrets/media/api-keys/sonarr
      chown media:media /run/secrets/media/api-keys/radarr
      chown prowlarr:prowlarr /run/secrets/media/api-keys/prowlarr
      chown qbittorrent:media /run/secrets/media/qbittorrent/password-hash
      chown media:media /run/secrets/media/bazarr/opensubtitles/*
    '';
  };

  testScript = ''
    machine.start()

    # Wait for all services to start
    with subtest("Services start with secrets enabled"):
        machine.wait_for_unit("sonarr.service")
        machine.wait_for_unit("radarr.service")
        machine.wait_for_unit("prowlarr.service")
        machine.wait_for_unit("qbittorrent.service")
        machine.wait_for_unit("bazarr.service")

    # Verify config files were created with injected secrets
    with subtest("Sonarr config has API key"):
        machine.succeed("test -f /var/lib/sonarr/.config/Sonarr/config.xml")
        machine.succeed("grep -q '0000000000000000000000000000000000000000000000000000000000000001' /var/lib/sonarr/.config/Sonarr/config.xml")

    with subtest("Radarr config has API key"):
        machine.succeed("test -f /var/lib/radarr/.config/Radarr/config.xml")
        machine.succeed("grep -q '0000000000000000000000000000000000000000000000000000000000000002' /var/lib/radarr/.config/Radarr/config.xml")

    with subtest("Prowlarr config has API key"):
        machine.succeed("test -f /var/lib/prowlarr/.config/Prowlarr/config.xml")
        machine.succeed("grep -q '0000000000000000000000000000000000000000000000000000000000000003' /var/lib/prowlarr/.config/Prowlarr/config.xml")

    with subtest("qBittorrent config has password hash"):
        machine.succeed("test -f /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf")
        machine.succeed("grep -q 'Password_PBKDF2' /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf")

    with subtest("Bazarr config has Sonarr/Radarr API keys"):
        machine.succeed("test -f /var/lib/bazarr/config/config.ini")
        # Check Sonarr API key is injected
        machine.succeed("grep -q '0000000000000000000000000000000000000000000000000000000000000001' /var/lib/bazarr/config/config.ini")
        # Check Radarr API key is injected
        machine.succeed("grep -q '0000000000000000000000000000000000000000000000000000000000000002' /var/lib/bazarr/config/config.ini")
        # Check OpenSubtitles credentials
        machine.succeed("grep -q 'test_user' /var/lib/bazarr/config/config.ini")

    # Verify services are responding
    with subtest("Services respond on their ports"):
        machine.wait_for_open_port(8989)  # Sonarr
        machine.wait_for_open_port(7878)  # Radarr
        machine.wait_for_open_port(9696)  # Prowlarr
        machine.wait_for_open_port(8080)  # qBittorrent
        machine.wait_for_open_port(6767)  # Bazarr

        machine.succeed("curl -sf http://localhost:8989")
        machine.succeed("curl -sf http://localhost:7878")
        machine.succeed("curl -sf http://localhost:9696")
        machine.succeed("curl -sf http://localhost:6767")

    print("All secrets integration tests passed!")
  '';
}
