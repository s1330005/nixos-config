{ pkgs, ... }:

{
  programs.niri.enable = true;
  # Pass explicit names to `import-environment` to silence its deprecation warning
  programs.niri.package =
    let
      niri = pkgs.niri;
    in
    pkgs.symlinkJoin {
      name = "${niri.name}-patched-session";
      inherit (niri) version meta passthru;
      paths = [ niri ];
      postBuild = ''
        rm $out/bin/niri-session
        substitute ${niri}/bin/niri-session $out/bin/niri-session \
          --replace-fail 'systemctl --user import-environment' \
            "systemctl --user import-environment \$(${pkgs.gawk}/bin/awk 'BEGIN{for(v in ENVIRON) if (v ~ /^[A-Za-z_][A-Za-z0-9_]*\$/ && v != \"AWKPATH\" && v != \"AWKLIBPATH\") print v}')"
        chmod +x $out/bin/niri-session
      '';
    };

  # Pick "Hyprland (uwsm-managed)" in tuigreet: UWSM brings up graphical-session.target
  # like niri-session does, so walker/dunst/polkit start in both sessions
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Pick "Sway (UWSM)" in tuigreet, same reasoning as Hyprland above
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    # default pulls in foot/wmenu/swaylock/...; we use ghostty/walker instead
    extraPackages = [ ];
  };
  programs.uwsm.waylandCompositors.sway = {
    prettyName = "Sway";
    comment = "Sway compositor managed by UWSM";
    binPath = "/run/current-system/sw/bin/sway";
  };

  systemd.user.services.polkit-kde-agent = {
    description = "PolicyKit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  services.upower.enable = true;
  services.gvfs.enable = true; # for nautilus
}
