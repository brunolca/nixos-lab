{ inputs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.disko.nixosModules.disko
    ../../modules/infrastructure/sops.nix
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
}
