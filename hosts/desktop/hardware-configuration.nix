{ ... }:

# Placeholder. On the desktop (JIS-keyboard) machine, replace this file with its real,
# already-working hardware-configuration.nix (the one already on that machine, including any
# hand-edits) — do NOT regenerate from scratch, since that loses manual tweaks.
# Only run nixos-generate-config if that machine never had one (brand-new install):
#   sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix
throw ''
  hosts/desktop/hardware-configuration.nix has not been set yet.
  Copy the desktop machine's existing hardware-configuration.nix here, or if it has none,
  run on that machine:
    sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix
''
