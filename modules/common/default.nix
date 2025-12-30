{ pkgs, lib, ... }:

{
  imports = [
    ./nix.nix
    ./users.nix
    ./ssh.nix
  ];

  # Timezone
  time.timeZone = "America/Sao_Paulo";

  # Essential packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
    tmux
    ripgrep
    jq
  ];

  # Networking defaults
  networking.useDHCP = lib.mkDefault true;
}
