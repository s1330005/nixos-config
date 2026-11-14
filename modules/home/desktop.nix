{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.walker.homeManagerModules.default ];

  xdg.configFile."niri/config.kdl" = {
    force = true;
    source = ../../niri/config.kdl;
  };

  programs.walker = {
    enable = true;
    runAsService = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-name = "Noto Sans 11";
      document-font-name = "Noto Sans 11";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":";
      titlebar-font = "Noto Sans Bold 11";
    };
  };

  home.pointerCursor = {
    name = "Yaru";
    package = pkgs.yaru-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Yaru-blue-dark";
      package = pkgs.yaru-theme;
    };
    iconTheme = {
      name = "Yaru-blue-dark";
      package = pkgs.yaru-theme;
    };
    # Nautilus uses GTK4
    gtk4.theme = config.gtk.theme;
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
