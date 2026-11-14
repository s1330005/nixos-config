{ pkgs, ... }:

{
  xdg.configFile."hypr/hyprland.lua" = {
    force = true;
    source = ../../hypr/hyprland.lua;
  };

  home.packages = with pkgs; [
    # screenshots (niri has them built in)
    grim
    slurp
    wl-clipboard
    jq
    # eww-workspaces reads Hyprland's event socket
    socat
  ];
}
