{ inputs, pkgs, ... }:

{
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];
  programs.niri.enable = true;
  # Pass explicit names to `import-environment` to silence its deprecation warning
  programs.niri.package =
    let
      niri = pkgs.niri-unstable;
    in
    pkgs.symlinkJoin {
      name = "${niri.name}-patched-session";
      inherit (niri)
        version
        meta
        passthru
        cargoBuildNoDefaultFeatures
        cargoBuildFeatures
        ;
      paths = [ niri ];
      postBuild = ''
        rm $out/bin/niri-session
        substitute ${niri}/bin/niri-session $out/bin/niri-session \
          --replace-fail 'systemctl --user import-environment' \
            "systemctl --user import-environment \$(${pkgs.gawk}/bin/awk 'BEGIN{for(v in ENVIRON) if (v ~ /^[A-Za-z_][A-Za-z0-9_]*\$/ && v != \"AWKPATH\" && v != \"AWKLIBPATH\") print v}')"
        chmod +x $out/bin/niri-session
      '';
    };

  programs.hyprlock.enable = true;

  services.upower.enable = true;
  services.gvfs.enable = true; # for nautilus
}
