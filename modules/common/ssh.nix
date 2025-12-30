{ lib, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      # Default to key-only; VMs override to allow password
      PasswordAuthentication = lib.mkDefault false;
    };
  };
}
