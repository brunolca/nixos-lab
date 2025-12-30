{ ... }:

{
  users.users.bruno = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    initialPassword = "nixos";
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here for passwordless access
      # "ssh-ed25519 AAAA..."
    ];
  };

  # Allow sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;
}
