{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 3;
      systemd-boot.consoleMode = "0"; # larger text
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ "vt.global_cursor_default=0" ];
    consoleLogLevel = 0;
  };

  networking.networkmanager.enable = true;
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [
        "10.2.0.2/32"
      ];
      privateKeyFile = "/etc/wireguard/proton-privatekey";
      dns = [
        "10.2.0.1"
      ];

      peers = [{
        publicKey = "7FslkahrdLwGbv4QSX5Cft5CtQLmBUlpWC382SSF7Hw=";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = "103.125.235.19:51820";
      }];
    };
  };
  networking.firewall.checkReversePath = false; # for VPN

  services.upower.enable = true;

  services.snapper = {
  snapshotInterval = "daily";
  cleanupInterval = "1d";
  configs = {
    root = {
      SUBVOLUME = "/";
      ALLOW_GROUPS = [ "wheel" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_MIN_AGE = "1800";
      TIMELINE_LIMIT_HOURLY = "0";
      TIMELINE_LIMIT_DAILY = "30";
      TIMELINE_LIMIT_WEEKLY = "0";
      TIMELINE_LIMIT_MONTHLY = "0";
      TIMELINE_LIMIT_YEARLY = "0";
    };
  };
  };

  networking.firewall.allowedTCPPorts = [
    5173
    4321
    3000
  ];

  hardware.graphics.enable = true;

  hardware.amdgpu.opencl.enable = true;
  # Load amdgpu early so the console font isn't reset
  hardware.amdgpu.initrd.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];
  hardware.nvidia = {
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = false;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  time.timeZone = "Asia/Tokyo";

  i18n = {
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
    };
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "ja_JP.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };
  environment.variables = {
    GTK_IM_MODULE = lib.mkForce ""; # silence startup warning
    EDITOR = "hx";
    VISUAL = "hx";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
  };

  # JetBrains Mono as console font (for tuigreet)
  console = {
    earlySetup = true;
    font =
      let
        jetbrainsMonoPsf =
          pkgs.runCommand "jetbrains-mono-psf"
            {
              nativeBuildInputs = [
                pkgs.otf2bdf
                pkgs.bdf2psf
                pkgs.gawk
              ];
            }
            ''
              mkdir -p $out/share/consolefonts
              otf2bdf -p 16 -r 96 -c C -l '32_126 160_255 9472_9599' \
                ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf > raw.bdf || true
              # bdf2psf requires AVERAGE_WIDTH = width*10
              w=$(awk '/^DWIDTH/{print $2; exit}' raw.bdf)
              sed "s/^AVERAGE_WIDTH .*/AVERAGE_WIDTH $((w*10))/" raw.bdf > f.bdf
              B=${pkgs.bdf2psf}/share/bdf2psf
              bdf2psf --fb f.bdf $B/standard.equivalents $B/ascii.set+$B/linux.set+$B/useful.set 512 \
                $out/share/consolefonts/JetBrainsMono.psf
            '';
      in
      "${jetbrainsMonoPsf}/share/consolefonts/JetBrainsMono.psf";
  };

  services.greetd = {
    enable = true;
    settings.default_session =
      let
        tuigreetCmd = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
        # Hide the key hints
        tuigreetEnv = lib.concatMapStringsSep " " (k: "TUIGREET_STATUS_SHOW_${k}=false") [
          "RESET"
          "COMMAND"
          "SESSION"
          "POWER"
          "BACKGROUND"
          "SESSION_STATUS"
          "CAPS_LOCK"
        ];
      in
      {
        command = "${pkgs.coreutils}/bin/env ${tuigreetEnv} ${tuigreetCmd}";
        user = "greeter";
      };
  };
  # Keep kernel/systemd logs off the greeter
  systemd.services.greetd.serviceConfig = {
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  nixpkgs.overlays = [ inputs.niri.overlays.niri ];
  programs.niri.enable = true;
  # Pass explicit names to `import-environment` to silence its deprecation warning
  programs.niri.package =
    let
      niri = pkgs.niri-unstable;
    in
    pkgs.symlinkJoin {
      name = "${niri.name}-patched-session";
      inherit (niri) version meta passthru cargoBuildNoDefaultFeatures cargoBuildFeatures;
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

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  users.users.sam = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.nushell;
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      storage-driver = "overlay2";
    };
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "sam";
    group = "users";
    dataDir = "/home/sam/.local/share/syncthing";
    configDir = "/home/sam/.local/share/syncthing/config";   
  };

  nixpkgs.config.allowUnfree = true;
  # obsidian is pinned to electron_42
  nixpkgs.config.permittedInsecurePackages = [ "electron-42.11.18" ];
  documentation.nixos.enable = false;
  services.gvfs.enable = true; # for nautilus
  environment.systemPackages = with pkgs; [
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
    inputs.browser-previews.packages.${pkgs.stdenv.hostPlatform.system}.google-chrome
    eww
    just
    xwayland-satellite
    adwaita-icon-theme
    yaru-theme
    nautilus
    pulseaudio
    brightnessctl

    (lib.hiPrio uutils-coreutils-noprefix)
    curl
    xh
    ripgrep
    fastfetch
    lm_sensors
    gcc
    steam-run
    wine64
    jaq
    numbat
    dust
    dysk
    bottom
    caligula
    meli
    libreoffice-fresh
    thunderbird

    keepassxc
    (chromium.override {
      commandLineArgs = [
        "--enable-features=AcceleratedVideoEncoder,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    })
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  xdg.mime.enable = true;
  xdg.mime.defaultApplications =
    {
      "application/pdf" = "tdf-ghostty.desktop";
    }
    // lib.genAttrs [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ] (_: "firefox.desktop")
    // lib.genAttrs (map (t: "image/${t}") [
      "png"
      "jpeg"
      "jpg"
      "gif"
      "bmp"
      "tiff"
      "webp"
    ]) (_: "viu-ghostty.desktop")
    // lib.genAttrs (
      map (t: "text/${t}") [
        "plain"
        "x-python"
        "x-csrc"
        "x-chdr"
        "x-c++src"
        "x-java"
        "x-rust"
        "x-shellscript"
        "x-script.python"
        "javascript"
        "typescript"
        "x-lua"
        "x-makefile"
        "markdown"
        "x-markdown"
        "css"
        "xml"
        "yaml"
        "x-yaml"
        "x-toml"
      ]
      ++ map (t: "application/${t}") [
        "json"
        "x-yaml"
        "xml"
        "javascript"
        "x-sh"
        "x-shellscript"
        "toml"
      ]
    ) (_: "helix-ghostty.desktop");

  # For #!/bin/bash scripts
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      roboto
      inter
      google-fonts
      ipaexfont
    ];

    fontconfig = {
      defaultFonts = {
        sansSerif = [
          "Noto Sans CJK JP"
          "Noto Color Emoji"
        ];
        serif = [
          "Noto Serif CJK JP"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Daily: keep the latest 3 generations and GC
  systemd.services.nix-keep-3-generations = {
    description = "Keep only the latest 3 NixOS generations and collect garbage";
    serviceConfig.Type = "oneshot";
    script = ''
      ${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +3
      ${config.nix.package}/bin/nix-collect-garbage
    '';
  };
  systemd.timers.nix-keep-3-generations = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  system.stateVersion = "26.05";
}
