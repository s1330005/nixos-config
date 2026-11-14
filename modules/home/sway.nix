{ pkgs, ... }:

{
  xdg.configFile."sway/config" = {
    force = true;
    source = ../../sway/config;
  };

  home.file.".local/bin/sway-screenshot" = {
    executable = true;
    source = ../../scripts/sway-screenshot.nu;
  };

  home.packages = with pkgs; [
    # screenshots on Hyprland and Sway (niri has them built in)
    grim
    slurp
    wl-clipboard
    jq
  ];
}
