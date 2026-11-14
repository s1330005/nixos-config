{ lib, pkgs, ... }:

{
  programs.helix = {
    enable = true;
    settings = {
      theme = "base16_transparent";
      editor = {
        auto-format = true;
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
      };
    };
    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt;
      }
      {
        name = "rust";
        auto-format = true;
        formatter.command = lib.getExe pkgs.rustfmt;
        language-servers = [ "rust-analyzer" ];
      }
      {
        name = "kdl";
        auto-format = true;
        formatter = {
          command = lib.getExe pkgs.kdlfmt;
          args = [
            "format"
            "-"
          ];
        };
      }
      {
        name = "css";
        auto-format = true;
        formatter = {
          command = lib.getExe pkgs.prettier;
          args = [
            "--parser"
            "css"
          ];
        };
      }
    ];
  };

  programs.vscode = {
    enable = true;
    # Workaround: vscode 1.144 moved bundled rg; drop once nixpkgs is fixed
    package = pkgs.vscode.overrideAttrs (old: {
      postPatch =
        builtins.replaceStrings
          [ "resources/app/node_modules/@vscode/ripgrep/bin/rg" ]
          [ "resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/linux-x64/rg" ]
          old.postPatch;
    });
    profiles.default.userSettings = {
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'IPAexGothic', 'Noto Sans CJK JP', monospace";
      "editor.fontLigatures" = true;
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'IPAexGothic', 'Noto Sans CJK JP'";
      "window.controlsStyle" = "hidden";
    };
  };
}
