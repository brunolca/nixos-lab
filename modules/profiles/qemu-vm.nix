{ modulesPath, lib, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # Boot configuration for QEMU
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" ];

  # Root filesystem (for VMs without disko)
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  # QEMU guest agent for better integration
  services.qemuGuest.enable = true;

  # VM-specific: allow password auth for easy testing
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
}
