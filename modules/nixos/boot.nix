{ pkgs, ... }:

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
}
