{ pkgs, ... }:

{
  xdg.configFile."hypr/hyprland.lua" = {
    force = true;
    source = ../../hypr/hyprland.lua;
  };

  home.packages = with pkgs; [
    # eww-workspaces reads Hyprland's event socket
    socat
  ];
}
