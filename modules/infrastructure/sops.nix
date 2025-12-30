{ inputs, config, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;

    # Use age for encryption
    age = {
      # Derive key from SSH host key (for real hosts)
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Where to store the derived key
      keyFile = "/var/lib/sops-nix/key.txt";
      # Auto-generate key on first boot
      generateKey = true;
    };

    # Define secrets here or in host-specific configs
    # secrets = {
    #   "user-password" = {
    #     neededForUsers = true;
    #   };
    # };
  };
}
