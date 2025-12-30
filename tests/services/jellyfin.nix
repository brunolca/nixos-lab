# Jellyfin media server test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "jellyfin";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules/services/jellyfin.nix ];

    virtualisation = {
      memorySize = 2048;
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
    machine.succeed("systemctl is-active jellyfin.service")

    # Wait for port to be available
    machine.wait_for_open_port(8096)

    # Verify HTTP endpoint responds
    machine.succeed("curl -sf http://localhost:8096")

    # Check media directory was created
    machine.succeed("test -d /var/lib/media")
  '';
}
