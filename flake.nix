{
  description = "NixOS GitOps Homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, ... }@inputs:
    let
      # Import helper functions
      lib = import ./lib { inherit nixpkgs self inputs; };

      # Darwin system for devShell
      darwinPkgs = nixpkgs.legacyPackages.aarch64-darwin;
    in
    {
      nixosConfigurations = {
        # VMs (aarch64-linux for local testing on Apple Silicon)
        vm-minimal = lib.mkVM { name = "vm-minimal"; };
        vm-server = lib.mkVM { name = "vm-server"; };
        vm-desktop = lib.mkVM { name = "vm-desktop"; };

        # Real hosts (uncomment when ready)
        # roubaix = lib.mkHost { name = "roubaix"; system = "x86_64-linux"; };
      };

      devShells.aarch64-darwin.default = darwinPkgs.mkShell {
        packages = with darwinPkgs; [
          qemu
          sops
          age
        ];
        shellHook = ''
          echo "NixOS Homelab - run ./scripts/run-vm <config> build"
        '';
      };
    };
}
