{
  description = "NixOS configuration for dotlan server with MySQL 8.0.34 and PHP 5.6.36";

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
        ({ config, pkgs, ... }: {  # Added config to module arguments
          # Basic system configuration
          system.stateVersion = "24.11";
          networking.hostName = "dotlan";
          i18n.defaultLocale = "en_US.UTF-8";

          # Boot configuration (example values)
          boot.loader = {
            efi = {
                canTouchEfiVariables = true;
                efiSysMountPoint = "/boot/efi";
            };
            grub = {
                efiSupport = true;
                device = "nodev";
            };
          };

          # Filesystem configuration (example values)
          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
          };

          # MySQL configuration
          services.mysql = {
            enable = true;
            package = (import mysql-nixpkgs { inherit (pkgs) system; }).mysql;
          };

          # System packages
          environment.systemPackages = [
            (import mysql-nixpkgs { inherit (pkgs) system; }).mysql
            (import php-nixpkgs { inherit (pkgs) system; }).php
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
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0P7n8nCfFc79DDIEQfVzRZ+zaX3L9F8NRqsXoirdWL Main"
          ];

          # Tailscale
          services.tailscale.enable = true;
        })
      ];
    };
  };
}
