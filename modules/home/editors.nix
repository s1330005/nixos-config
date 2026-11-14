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

  programs.zed-editor = {
    enable = true;

    userSettings = {
      cli_default_open_behavior = "existing_window";
      diff_view_style = "unified";

      project_panel.dock = "left";
      outline_panel.dock = "left";
      collaboration_panel.dock = "left";
      git_panel.dock = "left";

      agent = {
        dock = "right";
        favorite_models = [ ];
        model_parameters = [ ];
      };

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      session.trust_all_worktrees = true;

      icon_theme = "Zed (Default)";
      ui_font_size = 16;
      buffer_font_size = 14.5;
      buffer_font_family = "JetBrainsMono Nerd Font";
      buffer_line_height = "standard";

      soft_wrap = "none";

      title_bar.show_sign_in = false;
    };
  };
}
