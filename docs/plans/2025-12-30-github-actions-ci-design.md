# GitHub Actions CI Design

## Overview

Set up GitHub Actions CI for NixOS homelab with two-tier testing: quick validation on every push, full VM tests on PRs and weekly schedule.

## Architecture

### Workflows

1. **ci.yml** - Quick validation on every push
   - Runs `nix flake check` for syntax and evaluation
   - ~1-2 minutes

2. **test.yml** - Full NixOS VM tests
   - Triggers: PRs to main, weekly (Sunday 00:00 UTC), manual
   - Runs all 7 service tests in parallel via matrix strategy
   - Tests: jellyfin, sonarr, radarr, prowlarr, qbittorrent, nginx, media-stack

### Platform

- CI runs on x86_64-linux (GitHub hosted runners)
- Local testing remains on aarch64-linux (Apple Silicon)
- Both architectures defined in flake.nix checks

## Changes Required

### flake.nix

Add `checks.x86_64-linux` alongside existing `checks.aarch64-linux`:

```nix
checks.x86_64-linux = let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  tests = import ./tests { inherit pkgs; };
in {
  inherit (tests) jellyfin sonarr radarr prowlarr qbittorrent nginx media-stack;
};
```

### .github/workflows/ci.yml

Quick validation workflow using Determinate Systems Nix installer.

### .github/workflows/test.yml

Full test workflow with:
- Matrix strategy for parallel test execution
- KVM support for NixOS VM tests
- Scheduled weekly runs
- Manual trigger option

## Rationale

- x86_64-linux matches production host (Roubaix)
- Weekly scheduled runs catch upstream nixpkgs breakage
- Matrix strategy parallelizes tests for faster feedback
- Separate workflows allow quick feedback on every push while reserving expensive VM tests for PRs
