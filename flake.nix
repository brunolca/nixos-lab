{
  description = "NixOS GitOps Homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, disko, ... }@inputs:
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

        # Real hosts
        roubaix = lib.mkHost { name = "roubaix"; system = "x86_64-linux"; };
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

      # NixOS VM tests (aarch64-linux to match Apple Silicon + linux-builder)
      checks.aarch64-linux = let
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        tests = import ./tests { inherit pkgs; };
      in {
        inherit (tests) jellyfin sonarr radarr prowlarr qbittorrent bazarr nginx media-stack;
      };

      # NixOS VM tests (x86_64-linux for GitHub Actions CI)
      checks.x86_64-linux = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        tests = import ./tests { inherit pkgs; };
      in {
        inherit (tests) jellyfin sonarr radarr prowlarr qbittorrent bazarr nginx media-stack;
      };
    };
}
