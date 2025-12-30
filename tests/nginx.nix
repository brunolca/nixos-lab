# Nginx reverse proxy test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "nginx-proxy";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/services/jellyfin.nix
      ../modules/services/nginx-proxy.nix
    ];

    virtualisation = {
      memorySize = 2048;
      cores = 2;
    };

    documentation.enable = false;

    # Enable jellyfin as a backend
    homelab.services.jellyfin = {
      enable = true;
      mediaDir = "/var/lib/media";
    };

    # Enable nginx proxy
    homelab.services.nginx = {
      enable = true;
      baseDomain = "test.local";
      enableSSL = false;
    };
  };

  testScript = ''
    machine.start()

    # Wait for backend service
    machine.wait_for_unit("jellyfin.service")
    machine.wait_for_open_port(8096)

    # Wait for nginx
    machine.wait_for_unit("nginx.service")
    machine.wait_for_open_port(80)

    # Test direct backend access
    machine.succeed("curl -sf http://localhost:8096")

    # Test nginx proxy with Host header
    machine.succeed("curl -sf -H 'Host: jellyfin.test.local' http://localhost")

    # Verify nginx config was generated
    machine.succeed("test -f /etc/nginx/nginx.conf")
  '';
}
