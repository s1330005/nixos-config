{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Open files from the sidebar yazi in the tab's editor pane (Helix)
  yaziOpenInHelix = pkgs.writeShellScript "yazi-open-in-helix" ''
    zellij=${lib.getExe config.programs.zellij.package}
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
  # Square selection highlight
  yaziTheme.indicator.padding = {
    open = "█";
    close = "█";
  };
  # Readable mode colors on Nvim Dark
  yaziTheme.mode = {
    normal_main = { fg = "black"; bg = "blue"; bold = true; };
    normal_alt = { fg = "blue"; bg = "darkgray"; };
    select_main = { fg = "black"; bg = "red"; bold = true; };
    select_alt = { fg = "red"; bg = "darkgray"; };
    unset_main = { fg = "black"; bg = "red"; bold = true; };
    unset_alt = { fg = "red"; bg = "darkgray"; };
  };
  # Open PDFs in-terminal with tdf
  yaziOpenRules.prepend_rules = [
    { mime = "application/pdf"; use = [ "view-pdf" ]; }
  ];
  yaziViewPdf = lib.getExe pkgs.tdf;
  yaziSidebar = pkgs.writeShellScript "yazi-sidebar" ''
    YAZI_CONFIG_HOME=${config.xdg.configHome}/yazi-sidebar exec yazi "$@"
  '';
in

{
  imports = [
    inputs.walker.homeManagerModules.default
  ];

  home.stateVersion = "26.05";

  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "Inter 10";
        corner_radius = 8;
        frame_width = 1;
        padding = 12;
        horizontal_padding = 14;
        icon_size = 48;
        origin = "top-right";
        offset = "8x35";
        width = 350;
        height = 300;
        transparency = 0;
        stack_duplicates = false;
        gap_size = 5;
        notification_limit = 12;
        show_indicators = false;
        icon_corner_radius = 6;
      };

      urgency_low = {
        background = "#262626";
        foreground = "#DADADA";
        frame_color = "#3F3F3F";
        timeout = 6;
      };

      urgency_normal = {
        background = "#262626";
        foreground = "#DADADA";
        frame_color = "#3F3F3F";
        timeout = 8;
      };

      urgency_critical = {
        background = "#262626";
        foreground = "#DADADA";
        frame_color = "#FB464C";
        timeout = 0;
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-name = "Noto Sans 11";
      document-font-name = "Noto Sans 11";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":";
      titlebar-font = "Noto Sans Bold 11";
    };
  };

  home.packages = with pkgs; [
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    cargo-watch
    cargo-edit
    restic
    hdparm
    typst
    python3
    uv
    inkscape

    (obsidian.override { electron = electron_42; }) # electron 43 renders a black window
    go
    nodejs
    deno
    github-cli
    fd
    tree
    simplex-chat-desktop
    tdf
    viu
    basalt
    (writeShellScriptBin "ide" ''
      [ -n "$1" ] && cd "$1"
      exec zellij --layout ide
    '')
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.pointerCursor = {
    name = "Yaru";
    package = pkgs.yaru-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Yaru-blue-dark";
      package = pkgs.yaru-theme;
    };
    iconTheme = {
      name = "Yaru-blue";
      package = pkgs.yaru-theme;
    };
    # Nautilus uses GTK4
    gtk4.theme = config.gtk.theme;
  };

  programs.walker = {
    enable = true;
    runAsService = true;
  };

  programs = {
    nushell = {
      enable = true;
      settings = {
        show_banner = false;
        completions = {
          case_sensitive = false;
          algorithm = "fuzzy";
        };
      };
      shellAliases = {
        vi = "hx";
        vim = "hx";
        nano = "hx";
      };
    };
    carapace.enable = true;

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
        };
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      user.name = "sam";
      user.email = "sam@example.com";
    };
  };

  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Nvim Dark";
      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;
      font-family = [
        "JetBrainsMonoNL Nerd Font Mono"
        "IPAexGothic"
        "Noto Sans CJK JP"
      ];
      font-size = 12;
      font-style-bold = false;
      font-style-italic = false;
      font-style-bold-italic = false;
    };
  };

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

  programs.zellij = {
    enable = true;
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
  xdg.configFile."yazi-sidebar/yazi.toml".source = (pkgs.formats.toml { }).generate "yazi-sidebar.toml" {
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
        run = "${lib.getExe config.programs.zellij.package} run --floating --close-on-exit -- ${yaziViewPdf} \"$1\"";
        for = "unix";
      }
    ];
  };

  xdg.configFile."yazi-sidebar/theme.toml".source = (pkgs.formats.toml { }).generate "yazi-sidebar-theme.toml" yaziTheme;

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };
  programs.rmpc.enable = true;

  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        "sidebar.verticalTabs" = true;
        "sidebar.visibility" = "always-show";
        "sidebar.main.tools" = "history,bookmarks";
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "dom.webgpu.enabled" = true;
        "dom.webgpu.unsafe-powerful-device.enabled" = true;
        "gfx.webrender.all" = true;
      };
      search = {
        force = true;
        default = "ddg";
      };
    };
  };

  # Hide from walker
  xdg.desktopEntries =
    lib.genAttrs
      [
        "org.fcitx.fcitx5-qt6-gui-wrapper"
        "org.fcitx.Fcitx5"
        "org.fcitx.fcitx5-migrator"
        "kcm_fcitx5"
        "fcitx5-configtool"
        "org.fcitx.fcitx5-config-qt"
        "org.fcitx.fcitx5-qt5-gui-wrapper"
        "fcitx5-wayland-launcher"
        "kbd-layout-viewer5"
        "rmpc"
        "Helix"
      ]
      (name: {
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

      # Keep the window open until a key is pressed
      "viu-ghostty" = {
        name = "viu";
        genericName = "Image Viewer";
        noDisplay = true;
        exec = "ghostty -e ${pkgs.writeShellScript "viu-view" ''
          ${lib.getExe pkgs.viu} -- "$@"
          read -rsn1
        ''} %f";
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

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  xdg.configFile."niri/config.kdl" = {
    force = true;
    source = ./niri/config.kdl;
  };

  home.file =
    lib.genAttrs
      (map (n: ".local/bin/eww-${n}") [
        "start"
        "net-icon"
        "workspaces"
        "volume-text"
        "vpn"
        "battery"
        "sysinfo"
        "wallpaper"
      ])
      (path: {
        executable = true;
        source = ./scripts + "/${baseNameOf path}.nu";
      })
    // {
      ".claude/settings.json" = {
        force = true;
        source = ./claude/settings.json;
      };

      ".claude/statusline.nu" = {
        executable = true;
        source = ./scripts/claude-statusline.nu;
      };

      ".claude/CLAUDE.md" = {
        force = true;
        source = ./claude/CLAUDE.md;
      };

      ".local/bin/eww-gpu" = {
        executable = true;
        source = pkgs.runCommandCC "eww-gpu" { nativeBuildInputs = [ pkgs.rustc ]; } "rustc --edition 2021 -C opt-level=2 -o $out ${./scripts/eww-gpu.rs}";
      };
    };

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

  xdg.configFile."eww" = {
    force = true;
    source = ./eww;
    recursive = true;
  };

  xdg.configFile."hypr/hyprlock.conf" = {
    force = true;
    text = ''
      general {
        disable_loading_bar = false
        hide_cursor = true
        grace = 0
        no_fade_in = false
      }

      background {
        monitor =
        path = /etc/nixos/wallpapers/wallpaper.jpg
        brightness = 0.8
        contrast = 1.0
        vibrancy = 0.2
        vibrancy_darkness = 0.0
      }

      label {
        monitor =
          text = cmd[update:1000] echo "$(date +"%-H:%M")"
          color = rgba(255, 255, 255, 1.0)
          font_size = 120
          font_family = Roboto Medium
          position = 0, 500
          halign = center
          valign = center
      }
      input-field {
        size = 350, 50
        position = 0, -500
        halign = center
        valign = center
        rounding = 16
        dots_center = true
        outer_color = rgba(255, 255, 255, 0.5)
        inner_color = rgba(0, 0, 0, 0.2)
        font_color = rgba(255, 255, 255, 1.0)
        outline_thickness = 2
      }
    '';
  };
}
