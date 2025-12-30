{ inputs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.disko
    ../../modules/infrastructure/sops.nix
    ../../modules/services/comin.nix
    ../../modules/services/media-stack.nix
  ];

  networking.hostName = "roubaix";
  system.stateVersion = "24.11";

  # Boot loader for EFI systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable SSH for remote access
  services.openssh.enable = true;

  # Secrets configuration
  sops.secrets = {
    "user-password" = {
      neededForUsers = true;
    };
  };

  # Use hashed password from sops secret (override initialPassword from common)
  users.users.bruno = {
    initialPassword = lib.mkForce null;
    hashedPasswordFile = "/run/secrets/user-password";
  };

  # Media stack configuration
  homelab.services.mediaStack = {
    enable = true;
    enableSecrets = true;
    baseDomain = "brunofashionblog.fr";
    mediaDir = "/mnt/media";
    downloadDir = "/mnt/data/torrents";
    enableSSL = true;
    acmeEmail = "bruno@brunofashionblog.fr";  # Update with your email
  };

  # Add bruno to media group for access to media files
  users.users.bruno.extraGroups = [ "media" ];
}
