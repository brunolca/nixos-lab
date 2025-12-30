{
  description = "NixOS VM Lab - Learn and test NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Helper to create a NixOS config for QEMU/aarch64
      mkVM = name: nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./modules/common.nix
          ./configs/${name}.nix
          ({ modulesPath, ... }: {
            imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

            # Boot configuration for QEMU
            boot.loader.grub.enable = true;
            boot.loader.grub.device = "/dev/vda";
            boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" ];

            # Root filesystem
            fileSystems."/" = {
              device = "/dev/vda1";
              fsType = "ext4";
            };

            # QEMU guest agent for better integration
            services.qemuGuest.enable = true;
          })
        ];
      };
    in
    {
      nixosConfigurations = {
        minimal = mkVM "minimal";
        server = mkVM "server";
        desktop = mkVM "desktop";
      };
    };
}
