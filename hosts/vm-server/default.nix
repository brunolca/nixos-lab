{ pkgs, ... }:

{
  networking.hostName = "vm-server";
  system.stateVersion = "24.11";

  # Example services - uncomment to experiment
  # services.nginx.enable = true;
  # services.postgresql.enable = true;
  # virtualisation.docker.enable = true;

  # Additional server packages
  environment.systemPackages = with pkgs; [
    tmux
    ripgrep
    jq
  ];
}
