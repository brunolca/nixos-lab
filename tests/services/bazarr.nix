# Bazarr subtitle manager test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "bazarr";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules/services/bazarr.nix ];

    virtualisation = {
      memorySize = 1024;
      cores = 2;
    };

    documentation.enable = false;

    homelab.services.bazarr = {
      enable = true;
      mediaDir = "/var/lib/media";
    };
  };

  testScript = ''
    machine.start()

    # Wait for Bazarr to start
    machine.wait_for_unit("bazarr.service")
    machine.succeed("systemctl is-active bazarr.service")

    # Wait for port to be available
    machine.wait_for_open_port(6767)

    # Verify HTTP endpoint responds
    machine.succeed("curl -sf http://localhost:6767")

    # Check directories were created
    machine.succeed("test -d /var/lib/media/tv")
    machine.succeed("test -d /var/lib/media/movies")
  '';
}
