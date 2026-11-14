{ lib, pkgs, ... }:

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
    "Helix"
  ];

  # Keep the window open until a key is pressed
  viuView = pkgs.writeShellScript "viu-view" ''
    ${lib.getExe pkgs.viu} -- "$@"
    read -rsn1
  '';
in
{
  xdg.desktopEntries =
    lib.genAttrs hidden (name: {
      inherit name;
      noDisplay = true;
      exec = "false";
    })
    // {
      "helix-ghostty" = {
        name = "Helix";
        genericName = "Text Editor";
        exec = "ghostty -e hx %F";
        icon = "helix";
        terminal = false;
        categories = [
          "Utility"
          "TextEditor"
        ];
      };

      "tdf-ghostty" = {
        name = "tdf";
        genericName = "PDF Viewer";
        noDisplay = true;
        exec = "ghostty -e tdf %f";
        terminal = false;
        mimeType = [ "application/pdf" ];
        categories = [
          "Office"
          "Viewer"
        ];
      };

      "basalt-ghostty" = {
        name = "Basalt";
        genericName = "Note Taking";
        exec = "ghostty -e basalt";
        icon = "${pkgs.basalt.src}/assets/basalt.png";
        terminal = false;
        categories = [
          "Office"
          "Utility"
        ];
      };

      # meli ships no icon
      "meli-ghostty" = {
        name = "meli";
        genericName = "Mail Client";
        exec = "ghostty -e meli";
        icon = "mail-app";
        terminal = false;
        categories = [
          "Network"
          "Email"
        ];
      };

      "viu-ghostty" = {
        name = "viu";
        genericName = "Image Viewer";
        noDisplay = true;
        exec = "ghostty -e ${viuView} %f";
        terminal = false;
        mimeType = [
          "image/png"
          "image/jpeg"
          "image/jpg"
          "image/gif"
          "image/bmp"
          "image/tiff"
          "image/webp"
        ];
        categories = [
          "Graphics"
          "Viewer"
        ];
      };
    };
}
