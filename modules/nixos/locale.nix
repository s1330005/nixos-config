{ lib, pkgs, ... }:

{
  time.timeZone = "Asia/Tokyo";

  i18n = {
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
    };
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "ja_JP.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  environment.variables.GTK_IM_MODULE = lib.mkForce ""; # silence startup warning
}
