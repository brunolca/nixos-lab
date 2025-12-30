{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # TODO: Generate this file on the actual Roubaix server with:
  #   nixos-generate-config --show-hardware-config > hardware.nix
  #
  # This is a placeholder for x86_64 hardware.

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];  # or kvm-amd for AMD CPUs

  # Networking (adjust interface name after hardware detection)
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
