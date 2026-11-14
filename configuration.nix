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
      systemd-boot.configurationLimit = 3; # ブートメニューに出す世代を3つまでに
      systemd-boot.consoleMode = "0"; # 80x25 の最小解像度モードにして文字を大きく表示
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ "vt.global_cursor_default=0" ]; # hide the console cursor
    consoleLogLevel = 0; # hide kernel/udev/systemd logs on the console (adds loglevel=0)
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

  # Open port
  networking.firewall.allowedTCPPorts = [
    5173
    4321
    3000
  ];

  # Graphics
  hardware.graphics.enable = true;

  # AMD iGPU + Nvidia GTX 1650 (prime offload)
  hardware.amdgpu.opencl.enable = true;
  # amdgpu を initrd で読み込み、fbcon の切り替えをコンソールフォント設定より前に済ませる
  # (後から読み込まれるとフォントがカーネル既定に戻る)
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
    GTK_IM_MODULE = lib.mkForce ""; # hide the message displayed at startup
    EDITOR = "hx";
    VISUAL = "hx";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
  };

  # US keyboard (NixOS default, no xkb/keyMap override needed)
  # tuigreet は TTY 上で描画するので、JetBrains Mono を PSF に変換してコンソールフォントにする
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
              # サイズは -p (pt, 96dpi) で調整
              otf2bdf -p 16 -r 96 -c C -l '32_126 160_255 9472_9599' \
                ${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf > raw.bdf || true
              # bdf2psf は AVERAGE_WIDTH = 幅*10 を要求するので DWIDTH から補正
              w=$(awk '/^DWIDTH/{print $2; exit}' raw.bdf)
              sed "s/^AVERAGE_WIDTH .*/AVERAGE_WIDTH $((w*10))/" raw.bdf > f.bdf
              B=${pkgs.bdf2psf}/share/bdf2psf
              bdf2psf --fb f.bdf $B/standard.equivalents $B/ascii.set+$B/linux.set+$B/useful.set 512 \
                $out/share/consolefonts/JetBrainsMono.psf
            '';
      in
      "${jetbrainsMonoPsf}/share/consolefonts/JetBrainsMono.psf";
  };

  # Login manager (greetd + tuigreet)
  services.greetd = {
    enable = true;
    settings.default_session =
      let
        tuigreetCmd = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
        # 下部のキーガイド (F2 command / F3 session / F12 power など) を非表示
        tuigreetEnv = pkgs.lib.concatMapStringsSep " " (k: "TUIGREET_STATUS_SHOW_${k}=false") [
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
  # tuigreet の画面にカーネル/systemd のログが混ざらないようにする
  systemd.services.greetd.serviceConfig = {
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # Window manager
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];
  programs.niri.enable = true;
  # niri-session の `systemctl --user import-environment` (引数なし) が
  # "Calling import-environment without a list of variable names is deprecated" を出すので、
  # 変数名を明示して渡すように niri-session だけ差し替える (niri 本体は再ビルドしない)
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

  # Screen locker
  programs.hyprlock.enable = true;

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # User
  users.users.sam = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.nushell;
  };

  # Docker
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

  # Syncthing
  services.syncthing = {
    enable = true;
    openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
    user = "sam";
    group = "users";
    dataDir = "/home/sam/.local/share/syncthing";
    configDir = "/home/sam/.local/share/syncthing/config";   
  };

  # Apps
  nixpkgs.config.allowUnfree = true;
  # obsidian を electron_42 で固定しているため (home.nix 参照)
  nixpkgs.config.permittedInsecurePackages = [ "electron-42.11.18" ];
  documentation.nixos.enable = false; # hide NixOS documentation
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

    (lib.hiPrio pkgs.uutils-coreutils-noprefix) # use uutils instead of coreutils
    helix
    wget
    curl
    xh
    git
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

  # Set dafault Apps
  xdg.mime.enable = true;
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
    "application/pdf" = "tdf-ghostty.desktop";
    "image/png" = "viu-ghostty.desktop";
    "image/jpeg" = "viu-ghostty.desktop";
    "image/jpg" = "viu-ghostty.desktop";
    "image/gif" = "viu-ghostty.desktop";
    "image/bmp" = "viu-ghostty.desktop";
    "image/tiff" = "viu-ghostty.desktop";
    "image/webp" = "viu-ghostty.desktop";
    "text/plain" = "helix-ghostty.desktop";
    "text/x-python" = "helix-ghostty.desktop";
    "text/x-csrc" = "helix-ghostty.desktop";
    "text/x-chdr" = "helix-ghostty.desktop";
    "text/x-c++src" = "helix-ghostty.desktop";
    "text/x-java" = "helix-ghostty.desktop";
    "text/x-rust" = "helix-ghostty.desktop";
    "text/x-shellscript" = "helix-ghostty.desktop";
    "text/x-script.python" = "helix-ghostty.desktop";
    "text/javascript" = "helix-ghostty.desktop";
    "text/typescript" = "helix-ghostty.desktop";
    "text/x-lua" = "helix-ghostty.desktop";
    "text/x-makefile" = "helix-ghostty.desktop";
    "text/markdown" = "helix-ghostty.desktop";
    "text/x-markdown" = "helix-ghostty.desktop";
    "text/css" = "helix-ghostty.desktop";
    "text/xml" = "helix-ghostty.desktop";
    "text/yaml" = "helix-ghostty.desktop";
    "text/x-yaml" = "helix-ghostty.desktop";
    "text/x-toml" = "helix-ghostty.desktop";
    "application/json" = "helix-ghostty.desktop";
    "application/x-yaml" = "helix-ghostty.desktop";
    "application/xml" = "helix-ghostty.desktop";
    "application/javascript" = "helix-ghostty.desktop";
    "application/x-sh" = "helix-ghostty.desktop";
    "application/x-shellscript" = "helix-ghostty.desktop";
    "application/toml" = "helix-ghostty.desktop";
  };

  # Make the bash script work
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

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # システム世代を最新3つだけ残し、それ以外は削除して GC する（毎日）
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
