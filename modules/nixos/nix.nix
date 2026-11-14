{ config, ... }:

{
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
}
