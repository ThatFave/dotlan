{
  description = "Server configuration with MySQL 8.0.34, PHP 5.6.36, and Tailscale";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mysql-nixpkgs = {
      url = "github:NixOS/nixpkgs/9957cd48326fe8dbd52fdc50dd2502307f188b0d";
      flake = false;
    };
    php-nixpkgs = {
      url = "github:NixOS/nixpkgs/a5c9c6373aa35597cd5a17bc5c013ed0ca462cf0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, mysql-nixpkgs, php-nixpkgs, ... }@inputs: {
    nixosConfigurations.dotlan = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          # Set hostname
          networking.hostName = "dotlan";

          # Install packages from specific nixpkgs revisions
          environment.systemPackages = let
            mysqlPkgs = import mysql-nixpkgs { inherit (pkgs) system; };
            phpPkgs = import php-nixpkgs { inherit (pkgs) system; };
          in [
            mysqlPkgs.mysql
            phpPkgs.php
            pkgs.tailscale
          ];

          # SSH configuration
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "prohibit-password";
            };
          };

          # Add SSH public key
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0P7n8nCfFc79DDIEQfVzRZ+zaX3L9F8NRqsXoirdWL Main"
          ];

          # Optional: Add Tailscale service without activation
          services.tailscale.enable = true;
        })
      ];
    };
  };
}
