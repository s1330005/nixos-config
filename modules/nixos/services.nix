{ username, ... }:

{
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
