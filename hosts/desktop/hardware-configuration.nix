{ ... }:

# Placeholder. On the desktop (JIS-keyboard) machine, replace this file with its real
# hardware config, e.g.:
#   sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix
# or copy that machine's existing /etc/nixos/hardware-configuration.nix here.
throw ''
  hosts/desktop/hardware-configuration.nix has not been generated yet.
  Run on the desktop machine:
    sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix
''
