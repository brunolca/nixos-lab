# Shared test utilities for NixOS VM tests
{ pkgs }:

{
  # Common test machine configuration
  baseConfig = { config, pkgs, lib, ... }: {
    # Minimal VM settings for faster tests
    virtualisation = {
      memorySize = 1024;
      cores = 2;
    };

    # Disable unnecessary services for faster boot
    documentation.enable = false;
    boot.loader.grub.enable = false;

    # Basic networking
    networking.firewall.enable = true;
  };

  # Helper to create a service test
  mkServiceTest = { name, module, config, testScript, extraModules ? [] }:
    pkgs.testers.runNixOSTest {
      inherit name;

      nodes.machine = { config, pkgs, lib, ... }: {
        imports = [
          ../modules/services/${module}
        ] ++ extraModules;

        virtualisation = {
          memorySize = 1024;
          cores = 2;
        };

        documentation.enable = false;
      } // config;

      testScript = ''
        machine.start()
        ${testScript}
      '';
    };

  # Common test assertions
  assertions = {
    # Check service is running
    serviceRunning = service: ''
      machine.wait_for_unit("${service}.service")
      machine.succeed("systemctl is-active ${service}.service")
    '';

    # Check port is open
    portOpen = port: ''
      machine.wait_for_open_port(${toString port})
    '';

    # Check HTTP endpoint responds
    httpResponds = port: ''
      machine.succeed("curl -sf http://localhost:${toString port}")
    '';

    # Check directory exists with owner
    dirExistsWithOwner = { path, owner, group }: ''
      machine.succeed("test -d ${path}")
      machine.succeed("stat -c '%U:%G' ${path} | grep -q '${owner}:${group}'")
    '';
  };
}
