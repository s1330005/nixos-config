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
        font = "Noto Sans";
        corner_radius = 12;
        frame_width = 1;
        padding = 16;
        horizontal_padding = 16;
        icon_size = 48;
        origin = "top-right";
        offset = "8x35";
        width = 350;
        height = 300;
        transparency = 10;
        stack_duplicates = false;
        gap_size = 5;
        notification_limit = 12;
        show_indicators = false;
        icon_corner_radius = 6;
      };

      urgency_low = {
        background = "#2D353B";
        foreground = "#D3C6AA";
        frame_color = "#859289";
        timeout = 6;
      };

      urgency_normal = {
        background = "#2D353B";
        foreground = "#D3C6AA";
        frame_color = "#859289";
        timeout = 8;
      };

      urgency_critical = {
        background = "#2D353B";
        foreground = "#D3C6AA";
        frame_color = "#E67E80";
        timeout = 0;
      };
    };
  };

  # Set dark mode
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # Hide titlebar buttons
  dconf.settings = {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":";
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
    inkscape
    obsidian
    go
    nodejs
    deno
    discord-ptb
    github-cli
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

  # Launcher
  programs.walker = {
    enable = true;
    runAsService = true;
    config.theme = "everforest";
    themes."everforest" = {
      style = ''
        @define-color window_bg_color #2D353B;
        @define-color accent_bg_color #859289;
        @define-color theme_fg_color #D3C6AA;
        @define-color error_bg_color #E67E80;
        @define-color error_fg_color #514045;

        * {
          all: unset;
        }

        popover {
          background: lighter(@window_bg_color);
          border: 1px solid darker(@accent_bg_color);
          border-radius: 18px;
          padding: 10px;
        }

        .normal-icons {
          -gtk-icon-size: 16px;
        }

        .large-icons {
          -gtk-icon-size: 32px;
        }

        scrollbar {
          opacity: 0;
        }

        .box-wrapper {
          box-shadow:
            0 19px 38px rgba(0, 0, 0, 0.3),
            0 15px 12px rgba(0, 0, 0, 0.22);
          background: @window_bg_color;
          padding: 20px;
          border-radius: 20px;
          border: 1px solid darker(@accent_bg_color);
        }

        .preview-box,
        .elephant-hint,
        .placeholder {
          color: @theme_fg_color;
        }

        .box {
        }

        .search-container {
          border-radius: 10px;
        }

        .input placeholder {
          opacity: 0.5;
        }

        .input selection {
          background: lighter(lighter(lighter(@window_bg_color)));
        }

        .input {
          caret-color: @theme_fg_color;
          background: lighter(@window_bg_color);
          padding: 10px;
          color: @theme_fg_color;
        }

        .input:focus,
        .input:active {
        }

        .content-container {
        }

        .placeholder {
        }

        .scroll {
        }

        .list {
          color: @theme_fg_color;
        }

        child {
        }

        .item-box {
          border-radius: 10px;
          padding: 10px;
        }

        .item-quick-activation {
          background: alpha(@accent_bg_color, 0.25);
          border-radius: 5px;
          padding: 10px;
        }

        /* child:hover .item-box, */
        child:selected .item-box,
        row:selected .item-box {
          background: alpha(@accent_bg_color, 0.25);
        }

        .item-text-box {
        }

        .item-subtext {
          font-size: 12px;
          opacity: 0.5;
        }

        .providerlist .item-subtext {
          font-size: unset;
          opacity: 0.75;
        }

        .item-image-text {
          font-size: 28px;
        }

        .preview {
          border: 1px solid alpha(@accent_bg_color, 0.25);
          /* padding: 10px; */
          border-radius: 10px;
          color: @theme_fg_color;
        }

        .calc .item-text {
          font-size: 24px;
        }

        .calc .item-subtext {
        }

        .symbols .item-image {
          font-size: 24px;
        }

        .todo.done .item-text-box {
          opacity: 0.25;
        }

        .todo.urgent {
          font-size: 24px;
        }

        .todo.active {
          font-weight: bold;
        }

        .bluetooth.disconnected {
          opacity: 0.5;
        }

        .preview .large-icons {
          -gtk-icon-size: 64px;
        }

        .keybinds {
          padding-top: 10px;
          border-top: 1px solid lighter(@window_bg_color);
          font-size: 12px;
          color: @theme_fg_color;
        }

        .global-keybinds {
        }

        .item-keybinds {
        }

        .keybind {
        }

        .keybind-button {
          opacity: 0.5;
        }

        .keybind-button:hover {
          opacity: 0.75;
        }

        .keybind-bind {
          text-transform: lowercase;
          opacity: 0.35;
        }

        .keybind-label {
          padding: 2px 4px;
          border-radius: 4px;
          border: 1px solid @theme_fg_color;
        }

        .error {
          padding: 10px;
          background: @error_bg_color;
          color: @error_fg_color;
        }

        :not(.calc).current {
          font-style: italic;
        }

        .preview-content.archlinuxpkgs,
        .preview-content.dnfpackages {
          font-family: monospace;
        }
      '';
    };
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
  # programs.ghostty = {
  #   enable = true;
  #   settings = {
  #     theme = "Everforest Dark Hard";
  #     background-opacity = 0.85;
  #     background-blur = true;
  #     window-padding-x = 8;
  #     window-padding-y = 8;
  #     window-padding-balance = true;
  #     font-family = [
  #       "JetBrainsMonoNL Nerd Font Mono"
  #       "IPAexGothic"
  #       "Noto Sans CJK JP"
  #     ];
  #     font-size = 12;
  #     font-style-bold = false;
  #     font-style-italic = false;
  #     font-style-bold-italic = false;
  #   };
  # };

  # Alacritty
  programs.alacritty = {
    enable = true;
    theme = "everforest_dark_hard";
    settings = {
      window = {
        decorations = "none";
        opacity = 0.95;
        padding = {
          x = 8;
          y = 8;
        };
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 12.0;
      };
    };
  };

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
  xdg.desktopEntries."discord-ptb" = {
    name = "Discord";
    exec = "DiscordPTB";
    icon = "discord-ptb";
    terminal = false;
    categories = [
      "Network"
      "InstantMessaging"
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

      theme = {
        mode = "dark";
        light = "One Light";
        dark = "Everforest Dark Hard (material)";
      };

      soft_wrap = "none";

      title_bar.show_sign_in = false;
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

  # icon theme
  gtk = {
    enable = true;
    theme = {
      name = "Yaru-prussiangreen";
      package = pkgs.yaru-theme;
    };
    iconTheme = {
      name = "Yaru-prussiangreen";
      package = pkgs.yaru-theme;
    };
  };

  # niri
  xdg.configFile."niri/config.kdl" = {
    force = true;
    source = ./niri/config.kdl;
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
  home.file.".local/bin/eww-volume-icon" = {
    executable = true;
    source = ./scripts/eww-volume-icon.nu;
  };
  home.file.".local/bin/eww-volume-text" = {
    executable = true;
    source = ./scripts/eww-volume-text.nu;
  };
  home.file.".local/bin/eww-battery" = {
    executable = true;
    source = ./scripts/eww-battery.nu;
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
