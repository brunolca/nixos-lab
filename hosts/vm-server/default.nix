{ pkgs, ... }:

{
  imports = [
    ../../modules/services/media-stack.nix
  ];

  networking.hostName = "vm-server";
  system.stateVersion = "24.11";

  # Media stack for testing
  homelab.services.mediaStack = {
    enable = true;
    baseDomain = "localhost";
    mediaDir = "/var/lib/media";
    downloadDir = "/var/lib/torrents";
    enableSSL = false;
  };

  # Additional server packages
  environment.systemPackages = with pkgs; [
    tmux
    ripgrep
    jq
  ];
}
