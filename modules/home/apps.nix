{ config, ... }:

{
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
}
