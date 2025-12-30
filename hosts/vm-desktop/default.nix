{ pkgs, ... }:

{
  networking.hostName = "vm-desktop";
  system.stateVersion = "24.11";

  # Display server
  services.xserver.enable = true;

  # GNOME Desktop
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Or use Hyprland instead (comment out GNOME above):
  # programs.hyprland.enable = true;

  # Graphics for QEMU virtio-gpu
  hardware.graphics.enable = true;

  # Desktop packages
  environment.systemPackages = with pkgs; [
    firefox
    kitty
  ];
}
