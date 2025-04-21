# dotlan setup
commands:
- install nixos
- nix-shell -p git
- git clone https://github.com/thatfave/dotlan
- cd dotlan && nixos-rebuild switch --flake .#dotlan
