# qBittorrent torrent client test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "qbittorrent";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules/services/qbittorrent.nix ];

    virtualisation = {
      memorySize = 1024;
      cores = 2;
    };

    documentation.enable = false;

    homelab.services.qbittorrent = {
      enable = true;
      port = 8080;
      downloadDir = "/var/lib/torrents";
    };
  };

  testScript = ''
    machine.start()

    # Wait for qBittorrent to start
    machine.wait_for_unit("qbittorrent.service")
    machine.succeed("systemctl is-active qbittorrent.service")

    # Wait for port to be available
    machine.wait_for_open_port(8080)

    # Verify HTTP endpoint responds (qBittorrent returns 401 without auth, but that's OK)
    machine.succeed("curl -s http://localhost:8080 | grep -q 'qBittorrent'")

    # Check download directory was created
    machine.succeed("test -d /var/lib/torrents")
  '';
}
