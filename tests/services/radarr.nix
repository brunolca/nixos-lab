# Radarr movie manager test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "radarr";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules/services/arr-stack.nix ];

    virtualisation = {
      memorySize = 1024;
      cores = 2;
    };

    documentation.enable = false;

    homelab.services.arr = {
      enable = true;
      sonarr.enable = false;
      radarr.enable = true;
      prowlarr.enable = false;
      mediaDir = "/var/lib/media";
      downloadDir = "/var/lib/torrents";
    };
  };

  testScript = ''
    machine.start()

    # Wait for Radarr to start
    machine.wait_for_unit("radarr.service")
    machine.succeed("systemctl is-active radarr.service")

    # Wait for port to be available
    machine.wait_for_open_port(7878)

    # Verify HTTP endpoint responds
    machine.succeed("curl -sf http://localhost:7878")

    # Check directories were created
    machine.succeed("test -d /var/lib/media/movies")
    machine.succeed("test -d /var/lib/torrents/movies")
  '';
}
