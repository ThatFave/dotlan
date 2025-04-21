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
        ({ pkgs, ... }: {
          # Basic system configuration
          system.stateVersion = "23.11";
          networking.hostName = "dotlan";

          # Boot configuration (example values - adjust for your hardware)
          boot.loader.grub = {
            enable = true;
            device = "/dev/sda";
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
            settings = {
              mysqld = {
                innodb_buffer_pool_size = "256M";
                key_buffer_size = "128M";
              };
            };
          };

          # PHP-FPM configuration
          services.phpfpm.pools."php56" = {
            user = "phpuser";
            group = "phpgroup";
            phpPackage = (import php-nixpkgs { inherit (pkgs) system; }).php;
            phpOptions = ''
              extension = mysqli.so
              extension = pdo_mysql.so
            '';
            settings = {
              "listen.owner" = "nginx";
              "listen.group" = "nginx";
              "pm" = "dynamic";
              "pm.max_children" = 5;
              "pm.start_servers" = 2;
              "pm.min_spare_servers" = 1;
              "pm.max_spare_servers" = 3;
            };
          };

          # PHP user/group
          users.users.phpuser = {
            isSystemUser = true;
            group = "phpgroup";
          };
          users.groups.phpgroup = {};

          # System packages
          environment.systemPackages = [
            (import mysql-nixpkgs { inherit (pkgs) system; }).mysql
            (import php-nixpkgs { inherit (pkgs) system; }).php
            pkgs.tailscale
            pkgs.nginx
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

          # Tailscale (not activated)
          services.tailscale.enable = true;

          # Optional: Nginx configuration
          services.nginx = {
            enable = true;
            virtualHosts."default" = {
              locations."/" = {
                root = "/var/www/html";
                index = "index.php index.html";
              };
              locations."~ \.php$" = {
                extraConfig = ''
                  fastcgi_pass unix:${config.services.phpfpm.pools.php56.socket};
                  fastcgi_index index.php;
                  include ${pkgs.nginx}/conf/fastcgi_params;
                '';
              };
            };
          };
        })
      ];
    };
  };
}
