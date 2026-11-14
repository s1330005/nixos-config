{ pkgs, ... }:

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

  # GNOME apps; default handlers are set in modules/nixos/mime.nix
  home.packages = with pkgs; [
    amberol
    loupe
    papers
  ];
}
