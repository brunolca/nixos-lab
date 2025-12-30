# Sonarr TV show manager test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "sonarr";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules/services/arr-stack.nix ];

    virtualisation = {
      memorySize = 1024;
      cores = 2;
    };

    documentation.enable = false;

    homelab.services.arr = {
      enable = true;
      sonarr.enable = true;
      radarr.enable = false;
      prowlarr.enable = false;
      mediaDir = "/var/lib/media";
      downloadDir = "/var/lib/torrents";
    };
  };

  testScript = ''
    machine.start()

    # Wait for Sonarr to start
    machine.wait_for_unit("sonarr.service")
    machine.succeed("systemctl is-active sonarr.service")

    # Wait for port to be available
    machine.wait_for_open_port(8989)

    # Verify HTTP endpoint responds
    machine.succeed("curl -sf http://localhost:8989")

    # Check directories were created
    machine.succeed("test -d /var/lib/media/tv")
    machine.succeed("test -d /var/lib/torrents/tv")
  '';
}
