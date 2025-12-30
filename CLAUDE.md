# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NixOS GitOps Homelab - Declarative infrastructure for home servers with VM testing capability.

## Environment

- **OS**: NixOS (Declarative & Immutable)
- **Deployment**: GitOps via comin (pull-based) - planned
- **Secrets**: sops-nix (Age encryption) - planned
- **Disk**: disko (declarative partitioning) - planned

## Guardrails

1. **No imperative changes** - all modifications via .nix files and git commits
2. **Secrets via sops-nix only** - use `config.sops.secrets.<name>.path`, never plain text
3. **Test in VM first** - validate changes in vm-server before real hardware
4. **Ad-hoc tools** - use `nix shell nixpkgs#<tool>` for tools not in config

## Commands

```bash
# Validate configuration
nix flake check

# Build without deploying
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Build and run a VM (recommended for testing)
./scripts/run-vm vm-minimal build
./scripts/run-vm vm-server build
./scripts/run-vm vm-desktop build

# Run headless with SSH on port 2222
./scripts/run-vm <config> headless

# Edit secrets (once sops-nix is configured)
sops secrets/secrets.yaml
```

Default VM credentials: `bruno` / `nixos`

## Architecture

```
flake.nix                    # Entry point with mkVM/mkHost helpers
├── lib/default.nix          # Helper functions for host/VM creation
├── hosts/                   # Per-host configurations
│   ├── vm-minimal/          # Minimal VM for testing
│   ├── vm-server/           # Server VM for service testing
│   ├── vm-desktop/          # Desktop VM with GNOME
│   └── roubaix/             # Real hardware (planned)
├── modules/
│   ├── common/              # Shared config (nix, users, ssh)
│   ├── profiles/            # Hardware profiles (qemu-vm.nix)
│   ├── infrastructure/      # sops, comin (planned)
│   └── services/            # Reusable service modules (planned)
└── secrets/                 # sops-encrypted secrets (planned)
```

**Key patterns**:
- `lib.mkVM` creates aarch64-linux VMs for local testing on Apple Silicon
- `lib.mkHost` creates real host configurations (x86_64-linux for Roubaix)
- All hosts inherit from `modules/common/`
- VMs add `modules/profiles/qemu-vm.nix`

## Adding a New Service

1. Create module in `modules/services/<service>.nix`
2. Test in vm-server: `./scripts/run-vm vm-server build`
3. Add to real host config once verified
4. Commit and push - comin will deploy (once configured)
