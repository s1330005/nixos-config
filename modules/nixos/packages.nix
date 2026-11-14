{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  nixpkgs.config.allowUnfree = true;
  # obsidian is pinned to electron_42
  nixpkgs.config.permittedInsecurePackages = [ "electron-42.11.18" ];

  documentation.nixos.enable = false;

  environment.systemPackages = with pkgs; [
    inputs.awww.packages.${system}.awww
    inputs.browser-previews.packages.${system}.google-chrome
    eww
    just
    xwayland-satellite
    adwaita-icon-theme
    yaru-theme
    nautilus
    pulseaudio
    brightnessctl

    (lib.hiPrio uutils-coreutils-noprefix)
    git # system-wide so root can manage /etc/nixos
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

  # For #!/bin/bash scripts
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];
}
