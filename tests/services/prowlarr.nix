# Prowlarr indexer manager test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "prowlarr";

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
      radarr.enable = false;
      prowlarr.enable = true;
      mediaDir = "/var/lib/media";
      downloadDir = "/var/lib/torrents";
    };
  };

  testScript = ''
    machine.start()

    # Wait for Prowlarr to start
    machine.wait_for_unit("prowlarr.service")
    machine.succeed("systemctl is-active prowlarr.service")

    # Wait for port to be available
    machine.wait_for_open_port(9696)

    # Verify HTTP endpoint responds
    machine.succeed("curl -sf http://localhost:9696")
  '';
}
