# NixOS VM Tests for homelab services
{ pkgs }:

let
  lib = import ./lib.nix { inherit pkgs; };
in
{
  # Individual service tests
  jellyfin = import ./services/jellyfin.nix { inherit pkgs lib; };
  sonarr = import ./services/sonarr.nix { inherit pkgs lib; };
  radarr = import ./services/radarr.nix { inherit pkgs lib; };
  prowlarr = import ./services/prowlarr.nix { inherit pkgs lib; };
  qbittorrent = import ./services/qbittorrent.nix { inherit pkgs lib; };
  bazarr = import ./services/bazarr.nix { inherit pkgs lib; };

  # Nginx reverse proxy test
  nginx = import ./nginx.nix { inherit pkgs lib; };

  # Full integration test
  media-stack = import ./media-stack.nix { inherit pkgs lib; };

  # Secrets integration test
  secrets-integration = import ./secrets-integration.nix { inherit pkgs lib; };
}
