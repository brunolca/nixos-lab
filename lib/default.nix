{ nixpkgs, self, ... }:
{
  # Create a NixOS VM configuration (for local testing)
  mkVM = { name, system ? "aarch64-linux" }: nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit self; };
    modules = [
      ../modules/common
      ../modules/profiles/qemu-vm.nix
      ../hosts/${name}
    ];
  };

  # Create a real host configuration
  mkHost = { name, system ? "x86_64-linux" }: nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit self; };
    modules = [
      ../modules/common
      ../hosts/${name}
    ];
  };
}
