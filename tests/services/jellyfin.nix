# Jellyfin media server test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "jellyfin";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules/services/jellyfin.nix ];

    virtualisation = {
      memorySize = 4096;
      diskSize = 3 * 1024;  # 3GB - Jellyfin needs 512MB+ free in /var/log
      cores = 2;
    };

    documentation.enable = false;

    homelab.services.jellyfin = {
      enable = true;
      mediaDir = "/var/lib/media";
    };
  };

  testScript = ''
    machine.start()

    # Wait for Jellyfin to start
    machine.wait_for_unit("jellyfin.service")

    # Wait for port to be available (Jellyfin can take time to initialize)
    machine.wait_for_open_port(8096, timeout=120)

    # Verify HTTP endpoint responds (with retries - Jellyfin startup can be slow)
    machine.wait_until_succeeds("curl -sf http://localhost:8096", timeout=60)

    # Check media directory was created
    machine.succeed("test -d /var/lib/media")
  '';
}
