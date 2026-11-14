{ lib, pkgs, ... }:

let
  scripts = ../../scripts;

  # Nushell helpers called from eww.yuck, installed as ~/.local/bin/eww-<name>
  nuScripts = [
    "start"
    "net-icon"
    "workspaces"
    "volume-text"
    "vpn"
    "battery"
    "sysinfo"
    "wallpaper"
  ];
in
{
  xdg.configFile."eww" = {
    force = true;
    source = ../../eww;
    recursive = true;
  };

  home.file =
    lib.genAttrs (map (n: ".local/bin/eww-${n}") nuScripts) (path: {
      executable = true;
      source = scripts + "/${baseNameOf path}.nu";
    })
    // {
      ".local/bin/eww-gpu" = {
        executable = true;
        source = pkgs.runCommandCC "eww-gpu" {
          nativeBuildInputs = [ pkgs.rustc ];
        } "rustc --edition 2021 -C opt-level=2 -o $out ${scripts + "/eww-gpu.rs"}";
      };
    };
}
