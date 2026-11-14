{ username, ... }:

{
  services.snapper = {
    snapshotInterval = "daily";
    cleanupInterval = "1d";
    configs.root = {
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
    user = username;
    group = "users";
    dataDir = "/home/${username}/.local/share/syncthing";
    configDir = "/home/${username}/.local/share/syncthing/config";
  };
}
