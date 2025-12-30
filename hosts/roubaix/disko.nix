{ ... }:

{
  # Declarative disk partitioning
  # Adjust device path (/dev/sda, /dev/nvme0n1, etc.) for actual hardware
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";  # TODO: Update for actual Roubaix disk
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
