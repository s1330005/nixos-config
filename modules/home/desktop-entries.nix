{ lib, ... }:

let
  # Hide from walker
  hidden = [
    "org.fcitx.fcitx5-qt6-gui-wrapper"
    "org.fcitx.Fcitx5"
    "org.fcitx.fcitx5-migrator"
    "kcm_fcitx5"
    "fcitx5-configtool"
    "org.fcitx.fcitx5-config-qt"
    "org.fcitx.fcitx5-qt5-gui-wrapper"
    "fcitx5-wayland-launcher"
    "kbd-layout-viewer5"
  ];
in
{
  xdg.desktopEntries = lib.genAttrs hidden (name: {
    inherit name;
    noDisplay = true;
    exec = "false";
  });
}
