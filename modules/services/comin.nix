{ inputs, config, lib, ... }:

{
  imports = [ inputs.comin.nixosModules.comin ];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/brunolca/nixos-lab.git";
        branches.main.name = "main";
      }
    ];
  };
}
