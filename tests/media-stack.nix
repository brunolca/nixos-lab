# Full media stack integration test
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "media-stack";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/services/media-stack.nix ];

    virtualisation = {
      memorySize = 4096;
      cores = 4;
      diskSize = 4096;
    };

    documentation.enable = false;

    homelab.services.mediaStack = {
      enable = true;
      baseDomain = "test.local";
      mediaDir = "/var/lib/media";
      downloadDir = "/var/lib/torrents";
      enableSSL = false;
    };
  };

  testScript = ''
    machine.start()

    # Wait for all services to start
    with subtest("All services start"):
        machine.wait_for_unit("jellyfin.service")
        machine.wait_for_unit("sonarr.service")
        machine.wait_for_unit("radarr.service")
        machine.wait_for_unit("prowlarr.service")
        machine.wait_for_unit("qbittorrent.service")
        machine.wait_for_unit("bazarr.service")
        machine.wait_for_unit("nginx.service")

    # Verify all ports are open
    with subtest("All ports accessible"):
        machine.wait_for_open_port(8096)   # Jellyfin
        machine.wait_for_open_port(8989)   # Sonarr
        machine.wait_for_open_port(7878)   # Radarr
        machine.wait_for_open_port(9696)   # Prowlarr
        machine.wait_for_open_port(8080)   # qBittorrent
        machine.wait_for_open_port(6767)   # Bazarr
        machine.wait_for_open_port(80)     # Nginx

    # Test direct service access
    with subtest("Direct service access"):
        machine.succeed("curl -sf http://localhost:8096")  # Jellyfin
        machine.succeed("curl -sf http://localhost:8989")  # Sonarr
        machine.succeed("curl -sf http://localhost:7878")  # Radarr
        machine.succeed("curl -sf http://localhost:9696")  # Prowlarr
        machine.succeed("curl -sf http://localhost:6767")  # Bazarr

    # Test nginx reverse proxy
    with subtest("Nginx reverse proxy"):
        machine.succeed("curl -sf -H 'Host: jellyfin.test.local' http://localhost")
        machine.succeed("curl -sf -H 'Host: sonarr.test.local' http://localhost")
        machine.succeed("curl -sf -H 'Host: radarr.test.local' http://localhost")
        machine.succeed("curl -sf -H 'Host: prowlarr.test.local' http://localhost")
        machine.succeed("curl -sf -H 'Host: bazarr.test.local' http://localhost")

    # Verify directory structure
    with subtest("Directory structure"):
        machine.succeed("test -d /var/lib/media")
        machine.succeed("test -d /var/lib/media/tv")
        machine.succeed("test -d /var/lib/media/movies")
        machine.succeed("test -d /var/lib/torrents")
        machine.succeed("test -d /var/lib/torrents/tv")
        machine.succeed("test -d /var/lib/torrents/movies")

    # Verify user/group setup
    with subtest("User and group permissions"):
        machine.succeed("id media")  # media user exists
        machine.succeed("stat -c '%U:%G' /var/lib/media | grep -q 'media:media'")

    # Verify firewall allows required ports
    with subtest("Firewall configuration"):
        machine.succeed("iptables -L INPUT -n | grep -q '80'")

    print("All media stack tests passed!")
  '';
}
