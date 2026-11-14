{
  config,
  lib,
  pkgs,
  ...
}:

{
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
}
