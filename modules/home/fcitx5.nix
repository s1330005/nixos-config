{ pkgs, ... }:

{
  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=mozc

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=mozc
      Layout=

      [GroupOrder]
      0=Default
    '';
  };

  # fcitx5's "plasma" theme is generated from these colors
  xdg.configFile."kdeglobals" = {
    force = true;
    source = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
  };

  xdg.configFile."fcitx5/conf/classicui.conf" = {
    force = true;
    text = ''
      Vertical Candidate List=False
      WheelForPaging=True
      Font="Sans 10"
      MenuFont="Sans 10"
      TrayFont="Sans Bold 10"
      TrayOutlineColor=#000000
      TrayTextColor=#ffffff
      PreferTextIcon=False
      ShowLayoutNameInIcon=True
      UseInputMethodLanguageToDisplayText=True
      Theme=plasma
      DarkTheme=plasma
      UseDarkTheme=False
      UseAccentColor=True
      PerScreenDPI=False
      ForceWaylandDPI=0
      EnableFractionalScale=True
    '';
  };
}
