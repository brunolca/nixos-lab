{ pkgs, lib, ... }:

{
  # User account
  users.users.bruno = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here for passwordless access
      # "ssh-ed25519 AAAA..."
    ];
  };

  # Allow sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Essential packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
  ];

  # Networking (mkDefault allows desktop to override with NetworkManager)
  networking.useDHCP = lib.mkDefault true;

  # Timezone
  time.timeZone = "America/Sao_Paulo";
}
