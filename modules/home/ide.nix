# Terminal IDE: zellij `ide` layout with a yazi sidebar that opens files in Helix.
# Also configures the standalone yazi, which shares its theme and open rules.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  zellij = lib.getExe config.programs.zellij.package;
  toml = pkgs.formats.toml { };

  # Open files from the sidebar yazi in the tab's editor pane (Helix)
  yaziOpenInHelix = pkgs.writeShellScript "yazi-open-in-helix" ''
    zellij=${zellij}
    pane=$("$zellij" action list-panes -j -t | ${lib.getExe pkgs.jq} -r --argjson me "$ZELLIJ_PANE_ID" '
      map(select(.is_plugin | not)) as $t
      | ($t[] | select(.id == $me) | .tab_id) as $tab
      | first($t[] | select(.tab_id == $tab and .title == "editor" and (.exited | not)) | "terminal_\(.id)")')
    if [ -z "$pane" ]; then
      exec "$zellij" action new-pane --direction right --name editor -- hx "$@"
    fi
    "$zellij" action write -p "$pane" 27 # Esc
    for f in "$@"; do
      "$zellij" action write-chars -p "$pane" ":open \"''${f//\"/\\\"}\""
      "$zellij" action write -p "$pane" 13
    done
    "$zellij" action focus-pane-id "$pane"
  '';

  yaziSidebar = pkgs.writeShellScript "yazi-sidebar" ''
    YAZI_CONFIG_HOME=${config.xdg.configHome}/yazi-sidebar exec yazi "$@"
  '';

  yaziTheme = {
    # Square selection highlight
    indicator.padding = {
      open = "█";
      close = "█";
    };
    # Readable mode colors on Nvim Dark
    mode = {
      normal_main = {
        fg = "black";
        bg = "blue";
        bold = true;
      };
      normal_alt = {
        fg = "blue";
        bg = "darkgray";
      };
      select_main = {
        fg = "black";
        bg = "red";
        bold = true;
      };
      select_alt = {
        fg = "red";
        bg = "darkgray";
      };
      unset_main = {
        fg = "black";
        bg = "red";
        bold = true;
      };
      unset_alt = {
        fg = "red";
        bg = "darkgray";
      };
    };
  };

  # Open PDFs in-terminal with tdf
  yaziOpenRules.prepend_rules = [
    {
      mime = "application/pdf";
      use = [ "view-pdf" ];
    }
  ];
  yaziViewPdf = lib.getExe pkgs.tdf;
in
{
  programs.zellij.enable = true;

  programs.yazi = {
    enable = true;
    theme = yaziTheme;
    settings.open = yaziOpenRules;
    settings.opener.edit = [
      {
        run = "hx \"$@\"";
        block = true;
        for = "unix";
      }
    ];
    settings.opener.view-pdf = [
      {
        run = "${yaziViewPdf} \"$1\"";
        block = true;
        for = "unix";
      }
    ];
  };

  # `ide` layout: yazi | Helix / terminal
  xdg.configFile."zellij/layouts/ide.kdl".text = ''
    layout {
        default_tab_template {
            pane size=1 borderless=true {
                plugin location="zellij:tab-bar"
            }
            children
            pane size=1 borderless=true {
                plugin location="zellij:status-bar"
            }
        }
        tab name="IDE" focus=true {
            pane split_direction="vertical" {
                pane name="files" size="20%" command="${yaziSidebar}"
                pane split_direction="horizontal" size="80%" {
                    pane name="editor" size="75%" command="hx" focus=true
                    pane name="terminal" size="25%"
                }
            }
        }
    }
  '';

  # Sidebar yazi: single column, opens files in the editor pane
  xdg.configFile."yazi-sidebar/yazi.toml".source = toml.generate "yazi-sidebar.toml" {
    mgr.ratio = [
      0
      1
      0
    ];
    open = yaziOpenRules;
    opener.edit = [
      {
        run = "${yaziOpenInHelix} \"$@\"";
        for = "unix";
      }
    ];
    opener.view-pdf = [
      {
        run = "${zellij} run --floating --close-on-exit -- ${yaziViewPdf} \"$1\"";
        for = "unix";
      }
    ];
  };

  xdg.configFile."yazi-sidebar/theme.toml".source = toml.generate "yazi-sidebar-theme.toml" yaziTheme;
}
