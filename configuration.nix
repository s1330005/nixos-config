{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.silentSDDM.nixosModules.default
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };
    kernelParams = [
      "quiet"
      "loglevel=0"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "vt.global_cursor_default=0"
      "rd.systemd.show_status=false"
      "systemd.show_status=false"
      "systemd.log_level=emerg"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  systemd.settings.Manager = {
    ShowStatus = "no";
    StatusUnitFormat = "none";
  };

  networking.networkmanager.enable = true;
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [
        "10.2.0.2/32"
        "2a07:b944::2:2/128"
      ];
      privateKeyFile = "/etc/wireguard/proton-privatekey";
      dns = [
        "10.2.0.1"
        "2a07:b944::2:1"
      ];

      peers = [{
        publicKey = "dnLzpdaCyBlnnYS9iBwhPXoTXBQQNStT6/Tx6CytOmg=";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = "146.70.202.162:51820";
      }];
    };
  };
  networking.firewall.checkReversePath = false; # for VPN

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

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

  # Graphics (GPU-specific driver config lives under hosts/<hostname>/default.nix)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
    ];
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
    extraLocaleSettings = {
      LANGUAGE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF8";
      LC_ADDRESS = "en_US.UTF8";
      LC_IDENTIFICATION = "en_US.UTF8";
      LC_MEASUREMENT = "en_US.UTF8";
      LC_MESSAGES = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF8";
      LC_NAME = "en_US.UTF8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF8";
      LC_TELEPHONE = "en_US.UTF8";
      LC_TIME = "en_US.UTF8";
      LC_COLLATE = "en_US.UTF8";
    };
  };
  environment.variables = {
    GTK_IM_MODULE = lib.mkForce ""; # hide the message displayed at startup
  };

  # Keyboard layout is host-specific; see hosts/<hostname>/default.nix
  console = {
    font = "Lat2-Terminus16";
  };

  # Login manager
  system.activationScripts.sddmAvatar = {
    text = ''
      mkdir -p /var/lib/AccountsService/icons
      cp ${./wallpapers/wallpaper.jpg} /var/lib/AccountsService/icons/sam
      chmod 644 /var/lib/AccountsService/icons/sam
    '';
  };
  programs.silentSDDM = {
    enable = true;
    theme = "everforest";
    settings = {
      General.scale = 1.5;
      "LockScreen.Clock" = {
        position = "top-center";
        format = "h:mm";
        font-family = "Roboto Medium";
        font-size = 80;
        font-weight = 800;
      };
      "LockScreen.Date" = {
        format = "yyyy/M/d ddd";
        font-family = "Roboto Medium";
        font-size = 18;
        margin-top = 3;
      };
    };
  };

  # Window manager
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-unstable;

  # Screen locker
  programs.hyprlock.enable = true;

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
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
    packages = with pkgs; [
      tree
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
      log-driver = "journald";
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
  documentation.nixos.enable = false; # hide NixOS documentation
  programs.steam.enable = true;
  programs.xwayland.enable = true;
  services.gvfs.enable = true; # for nautilus
  environment.systemPackages = with pkgs; [
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
    eww
    wayland
    xwayland-satellite
    adwaita-icon-theme
    yaru-theme
    pulseaudio
    brightnessctl
    wireguard-tools

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

    nautilus
    amberol
    gnome-calculator
    gnome-disk-utility
    gnome-characters
    gnome-font-viewer
    loupe
    papers
    resources
    foliate
    libreoffice-fresh
    tor-browser
    (chromium.override {
      commandLineArgs = [
        "--enable-features=AcceleratedVideoEncoder,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
        "--enable-features=VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport"
        "--enable-features=UseMultiPlaneFormatForHardwareVideo"
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
    "application/pdf" = "org.gnome.Papers.desktop";
    "image/png" = "org.gnome.Loupe.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/jpg" = "org.gnome.Loupe.desktop";
    "image/gif" = "org.gnome.Loupe.desktop";
    "image/bmp" = "org.gnome.Loupe.desktop";
    "image/tiff" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "audio/wav" = [ "amberol.desktop" ];
    "audio/x-wav" = [ "amberol.desktop" ];
    "audio/mpeg" = [ "amberol.desktop" ];
    "audio/mp3" = [ "amberol.desktop" ];
    "audio/flac" = [ "amberol.desktop" ];
    "text/plain" = "dev.zed.Zed.desktop";
    "text/x-python" = "dev.zed.Zed.desktop";
    "text/x-csrc" = "dev.zed.Zed.desktop";
    "text/x-chdr" = "dev.zed.Zed.desktop";
    "text/x-c++src" = "dev.zed.Zed.desktop";
    "text/x-java" = "dev.zed.Zed.desktop";
    "text/x-rust" = "dev.zed.Zed.desktop";
    "text/x-shellscript" = "dev.zed.Zed.desktop";
    "text/x-script.python" = "dev.zed.Zed.desktop";
    "text/javascript" = "dev.zed.Zed.desktop";
    "text/typescript" = "dev.zed.Zed.desktop";
    "text/x-lua" = "dev.zed.Zed.desktop";
    "text/x-makefile" = "dev.zed.Zed.desktop";
    "text/markdown" = "dev.zed.Zed.desktop";
    "text/x-markdown" = "dev.zed.Zed.desktop";
    "text/css" = "dev.zed.Zed.desktop";
    "text/xml" = "dev.zed.Zed.desktop";
    "text/yaml" = "dev.zed.Zed.desktop";
    "text/x-yaml" = "dev.zed.Zed.desktop";
    "text/x-toml" = "dev.zed.Zed.desktop";
    "application/json" = "dev.zed.Zed.desktop";
    "application/x-yaml" = "dev.zed.Zed.desktop";
    "application/xml" = "dev.zed.Zed.desktop";
    "application/javascript" = "dev.zed.Zed.desktop";
    "application/x-sh" = "dev.zed.Zed.desktop";
    "application/x-shellscript" = "dev.zed.Zed.desktop";
    "application/toml" = "dev.zed.Zed.desktop";
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

    fontDir.enable = true;

    fontconfig = {
      defaultFonts = {
        sansSerif = [ "Noto Sans CJK JP" ];
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

  system.stateVersion = "26.05";
}
