{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:

let
  # fcitx5's own keyboard layout should match the physical keyboard, which
  # differs per host (see hosts/<hostname>/default.nix).
  fcitxLayout = if osConfig.networking.hostName == "desktop" then "jp" else "us";

  # zellij の IDE レイアウト用: サイドバーの yazi から、同じタブの editor ペイン (Helix) でファイルを開く
  yaziOpenInHelix = pkgs.writeShellScript "yazi-open-in-helix" ''
    zellij=${lib.getExe config.programs.zellij.package}
    pane=$("$zellij" action list-panes -j -t | ${lib.getExe pkgs.jq} -r --argjson me "$ZELLIJ_PANE_ID" '
      map(select(.is_plugin | not)) as $t
      | ($t[] | select(.id == $me) | .tab_id) as $tab
      | first($t[] | select(.tab_id == $tab and .title == "editor" and (.exited | not)) | "terminal_\(.id)")')
    if [ -z "$pane" ]; then
      # editor ペインが無ければ右に作る
      exec "$zellij" action new-pane --direction right --name editor -- hx "$@"
    fi
    "$zellij" action write -p "$pane" 27 # Esc でノーマルモードに戻す
    for f in "$@"; do
      "$zellij" action write-chars -p "$pane" ":open \"''${f//\"/\\\"}\""
      "$zellij" action write -p "$pane" 13
    done
    "$zellij" action focus-pane-id "$pane"
  '';
  # 選択行の両端の丸いグリフを全塗りブロックにして四角いハイライトにする (幅は変えない)
  yaziTheme.indicator.padding = {
    open = "█";
    close = "█";
  };
  # ステータスバーのモード表示: Nvim Dark では blue/red が明るく既定の文字色 (白系) と gray 背景だと読みにくいので、
  # 文字を黒、副セグメントの背景を darkgray にする
  yaziTheme.mode = {
    normal_main = { fg = "black"; bg = "blue"; bold = true; };
    normal_alt = { fg = "blue"; bg = "darkgray"; };
    select_main = { fg = "black"; bg = "red"; bold = true; };
    select_alt = { fg = "red"; bg = "darkgray"; };
    unset_main = { fg = "black"; bg = "red"; bold = true; };
    unset_alt = { fg = "red"; bg = "darkgray"; };
  };
  # PDF は Enter で外部ウィンドウではなく端末内の tdf で開く (画像は既定どおり xdg-open → viu-ghostty の別ウィンドウ)
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

  home.username = "sam";
  home.homeDirectory = "/home/sam";
  home.stateVersion = "26.05";

  # Notification
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

  # Set dark mode
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-name = "Noto Sans 11";
      document-font-name = "Noto Sans 11";
    };
  };

  # Hide titlebar buttons
  dconf.settings = {
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
    # electron 43.8.3 renders a black window (webFrame TypeError in renderer_init)
    (obsidian.override { electron = electron_42; })
    go
    nodejs
    deno
    github-cli
    fd
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

  # Cursor theme
  home.pointerCursor = {
    name = "Yaru";
    package = pkgs.yaru-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # GTK theme (Nautilus 等)
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
    # Nautilus は GTK4 (libadwaita) なので gtk4 側にも明示的に指定する
    gtk4.theme = config.gtk.theme;
  };

  # Launcher
  programs.walker = {
    enable = true;
    runAsService = true;
  };

  # Shell
  programs = {
    nushell = {
      enable = true;
      extraConfig = ''
        let carapace_completer = {|spans|
        carapace $spans.0 nushell ...$spans | from json
        }
        $env.config = {
         show_banner: false,
         completions: {
         case_sensitive: false # case-sensitive completions
         quick: true    # set to false to prevent auto-selecting completions
         partial: true    # set to false to prevent partial filling of the prompt
         algorithm: "fuzzy"    # prefix or fuzzy
         external: {
         # set to false to prevent nushell looking into $env.PATH to find more suggestions
             enable: true 
         # set to lower can improve completion performance at the cost of omitting some options
             max_results: 100 
             completer: $carapace_completer # check 'carapace_completer' 
           }
         }
        } 
        $env.PATH = ($env.PATH | 
        split row (char esep) |
        prepend /home/myuser/.apps |
        append /usr/bin/env
        )
      '';
      shellAliases = {
        vi = "hx";
        vim = "hx";
        nano = "hx";
      };
    };
    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
        };
      };
    };
  };

  # Git
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
    };
  };

  # Ghostty
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

  # Alacritty (Ghostty と同じ見た目)
  # programs.alacritty = {
  #   enable = true;
  #   settings = {
  #     window = {
  #       decorations = "none";
  #       padding = {
  #         x = 8;
  #         y = 8;
  #       };
  #       dynamic_padding = true;
  #     };
  #     font = let
  #       family = "JetBrainsMonoNL Nerd Font Mono";
  #     in {
  #       normal = {
  #         inherit family;
  #         style = "Regular";
  #       };
  #       bold = {
  #         inherit family;
  #         style = "Regular";
  #       };
  #       italic = {
  #         inherit family;
  #         style = "Regular";
  #       };
  #       bold_italic = {
  #         inherit family;
  #         style = "Regular";
  #       };
  #       size = 12.0;
  #     };
  #     # Ghostty "Nvim Dark" theme
  #     colors = {
  #       primary = {
  #         background = "#14161b";
  #         foreground = "#e0e2ea";
  #       };
  #       cursor = {
  #         text = "#e0e2ea";
  #         cursor = "#9b9ea4";
  #       };
  #       selection = {
  #         text = "#e0e2ea";
  #         background = "#4f5258";
  #       };
  #       normal = {
  #         black = "#07080d";
  #         red = "#ffc0b9";
  #         green = "#b3f6c0";
  #         yellow = "#fce094";
  #         blue = "#a6dbff";
  #         magenta = "#ffcaff";
  #         cyan = "#8cf8f7";
  #         white = "#eef1f8";
  #       };
  #       bright = {
  #         black = "#4f5258";
  #         red = "#ffc0b9";
  #         green = "#b3f6c0";
  #         yellow = "#fce094";
  #         blue = "#a6dbff";
  #         magenta = "#ffcaff";
  #         cyan = "#8cf8f7";
  #         white = "#eef1f8";
  #       };
  #     };
  #   };
  # };

  # File Manager
  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;
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

  # Terminal Multiplexer
  programs.zellij = {
    enable = true;
  };

  # VSCode 風レイアウト (`ide` で起動): 左 yazi / 右上 Helix / 右下 ターミナル
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

  # サイドバー用の yazi 設定 (ファイル一覧の1列だけ表示し、テキストは editor ペインで開く)
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
    # サイドバーは狭いので zellij のフローティングペインで開く (閉じるとペインも消える)
    opener.view-pdf = [
      {
        run = "${lib.getExe config.programs.zellij.package} run --floating --close-on-exit -- ${yaziViewPdf} \"$1\"";
        for = "unix";
      }
    ];
  };

  xdg.configFile."yazi-sidebar/theme.toml".source = (pkgs.formats.toml { }).generate "yazi-sidebar-theme.toml" yaziTheme;

  # Music Player (rmpc + MPD)
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
        engines = {
          "ddg" = {
            urls = [
              {
                template = "https://duckduckgo.com/";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "https://duckduckgo.com/favicon.ico";
            definedAliases = [ "@ddg" ];
          };
        };
      };
    };
  };

  # Hide icons for walker
  xdg.desktopEntries."org.fcitx.fcitx5-qt6-gui-wrapper" = {
    name = "fcitx5-qt6-gui-wrapper";
    noDisplay = true;
    exec = "false";
  };
  xdg.desktopEntries."org.fcitx.Fcitx5" = {
    name = "Fcitx 5";
    noDisplay = true;
    exec = "false";
  };
  xdg.desktopEntries."org.fcitx.fcitx5-migrator" = {
    name = "fcitx5-migrator";
    noDisplay = true;
    exec = "false";
  };
  xdg.desktopEntries."kcm_fcitx5" = {
    name = "kcm_fcitx5";
    noDisplay = true;
    exec = "false";
  };
  xdg.desktopEntries."fcitx5-configtool" = {
    name = "Fcitx5 Config";
    noDisplay = true;
    exec = "false";
  };
  xdg.desktopEntries."org.fcitx.fcitx5-config-qt" = {
    name = "fcitx5-config-qt";
    noDisplay = true;
    exec = "false";
  };
  xdg.desktopEntries."org.fcitx.fcitx5-qt5-gui-wrapper" = {
    name = "fcitx5-qt5-gui-wrapper";
    noDisplay = true;
    exec = "false";
  };
  xdg.desktopEntries."fcitx5-wayland-launcher" = {
    name = "fcitx5-wayland-launcher";
    noDisplay = true;
    exec = "false";
  };
  xdg.desktopEntries."kbd-layout-viewer5" = {
    name = "kbd-layout-viewer5";
    noDisplay = true;
    exec = "false";
  };

  # rmpc.desktop は Terminal=true で直接起動できないため隠す
  xdg.desktopEntries."rmpc" = {
    name = "rmpc";
    noDisplay = true;
    exec = "false";
  };

  # 標準の Helix.desktop は Terminal=true で直接起動できないため隠す
  xdg.desktopEntries."Helix" = {
    name = "Helix";
    noDisplay = true;
    exec = "false";
  };

  # Helix を Ghostty 内で開く (ファイル関連付け用)
  xdg.desktopEntries."helix-ghostty" = {
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

  # tdf を Ghostty 内で開く (PDF の関連付け用)
  xdg.desktopEntries."tdf-ghostty" = {
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

  # basalt (Obsidian ノートの TUI) を Ghostty 内で起動 (ランチャー用)
  xdg.desktopEntries."basalt-ghostty" = {
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

  # meli (メール TUI) を Ghostty 内で起動 (ランチャー用)
  # meli パッケージは .desktop もアイコンも同梱しないため Yaru の mail-app を使う
  xdg.desktopEntries."meli-ghostty" = {
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

  # viu を Ghostty 内で開く (画像の関連付け用)
  # viu は表示後すぐ終了するので、キー入力までウィンドウを残す
  xdg.desktopEntries."viu-ghostty" = {
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

  # Text Editor
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
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  #programs.zed-editor = {
    #enable = true;

    #userSettings = {
      #cli_default_open_behavior = "existing_window";
      #diff_view_style = "unified";

      #project_panel.dock = "left";
      #outline_panel.dock = "left";
      #collaboration_panel.dock = "left";
      #git_panel.dock = "left";

      #agent = {
        #dock = "right";
        #favorite_models = [ ];
        #model_parameters = [ ];
      #};

      #telemetry = {
        #diagnostics = false;
        #metrics = false;
      #};

      #session.trust_all_worktrees = true;

      #icon_theme = "Zed (Default)";
      #ui_font_size = 16;
      #buffer_font_size = 14.5;
      #buffer_font_family = "JetBrainsMono Nerd Font";
      #buffer_font_fallbacks = [
        #"IPAexGothic"
        #"Noto Sans CJK JP"
      #];
      #terminal.font_fallbacks = [
        #"IPAexGothic"
        #"Noto Sans CJK JP"
      #];
      #buffer_line_height = "standard";

      #theme = {
        #mode = "dark";
        #light = "One Light";
        #dark = "Everforest Dark Hard (material)";
      #};

      #soft_wrap = "none";

      #title_bar.show_sign_in = false;
    #};
  #};

  # VSCode
  programs.vscode = {
    enable = true;
    # vscode 1.144 moved bundled ripgrep; nixpkgs' postPatch still rm's the old path.
    # Remove this override once nixpkgs is fixed.
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

  # Hide icon
  #xdg = {
  #  enable = true;
  #  desktopEntries = {
  #    btop = {
  #      name = "btop";
  #      noDisplay = true;
  #    };
  #  };
  #};

  # XDG user directories (Desktop, Documents, Downloads, ...)
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # niri
  xdg.configFile."niri/config.kdl" = {
    force = true;
    source = ./niri/config.kdl;
  };

  # Claude Code settings (shared across machines)
  home.file.".claude/settings.json" = {
    force = true;
    source = ./claude/settings.json;
  };

  home.file.".claude/statusline.nu" = {
    executable = true;
    source = ./scripts/claude-statusline.nu;
  };

  home.file.".claude/CLAUDE.md" = {
    force = true;
    source = ./claude/CLAUDE.md;
  };

  # eww script for niri
  home.file.".local/bin/eww-start" = {
    executable = true;
    source = ./scripts/eww-start.nu;
  };

  # Fcitx config
  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
      [Groups/0]
      Name=Default
      Default Layout=${fcitxLayout}
      DefaultIM=mozc

      [Groups/0/Items/0]
      Name=keyboard-${fcitxLayout}
      Layout=

      [Groups/0/Items/1]
      Name=mozc
      Layout=

      [GroupOrder]
      0=Default
    '';
  };

  # KDE color scheme (BreezeDark). fcitx5's "plasma" theme is generated from
  # these colors by fcitx5-plasma-theme-generator.
  xdg.configFile."kdeglobals" = {
    force = true;
    source = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
  };

  xdg.configFile."fcitx5/conf/classicui.conf" = {
    force = true;
    text = ''
      # Vertical Candidate List
      Vertical Candidate List=False
      # Use mouse wheel to go to prev or next page
      WheelForPaging=True
      # Font
      Font="Sans 10"
      # Menu Font
      MenuFont="Sans 10"
      # Tray Font
      TrayFont="Sans Bold 10"
      # Tray Label Outline Color
      TrayOutlineColor=#000000
      # Tray Label Text Color
      TrayTextColor=#ffffff
      # Prefer Text Icon
      PreferTextIcon=False
      # Show Layout Name In Icon
      ShowLayoutNameInIcon=True
      # Use input method language to display text
      UseInputMethodLanguageToDisplayText=True
      # Theme
      Theme=plasma
      # Dark Theme
      DarkTheme=plasma
      # Follow system light/dark color scheme
      UseDarkTheme=False
      # Follow system accent color if it is supported by theme and desktop
      UseAccentColor=True
      # Use Per Screen DPI on X11
      PerScreenDPI=False
      # Force font DPI on Wayland
      ForceWaylandDPI=0
      # Enable fractional scale under Wayland
      EnableFractionalScale=True
    '';
  };

  # Widget bar
  xdg.configFile."eww/eww.yuck" = {
    force = true;
    source = ./eww/eww.yuck;
  };

  xdg.configFile."eww/eww.css" = {
    force = true;
    source = ./eww/eww.css;
  };

  # eww sh files
  home.file.".local/bin/eww-net-icon" = {
    executable = true;
    source = ./scripts/eww-net-icon.nu;
  };
  home.file.".local/bin/eww-workspaces" = {
    executable = true;
    source = ./scripts/eww-workspaces.nu;
  };
  home.file.".local/bin/eww-volume-text" = {
    executable = true;
    source = ./scripts/eww-volume-text.nu;
  };
  home.file.".local/bin/eww-vpn" = {
    executable = true;
    source = ./scripts/eww-vpn.nu;
  };
  home.file.".local/bin/eww-battery" = {
    executable = true;
    source = ./scripts/eww-battery.nu;
  };

  home.file.".local/bin/eww-sysinfo" = {
    executable = true;
    source = ./scripts/eww-sysinfo.nu;
  };

  home.file.".local/bin/eww-gpu" = {
    executable = true;
    source = pkgs.runCommandCC "eww-gpu" { nativeBuildInputs = [ pkgs.rustc ]; } "rustc --edition 2021 -C opt-level=2 -o $out ${./scripts/eww-gpu.rs}";
  };

  home.file.".local/bin/eww-wallpaper" = {
    executable = true;
    source = ./scripts/eww-wallpaper.nu;
  };

  # lock screen
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
