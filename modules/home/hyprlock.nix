{
  xdg.configFile."hypr/hyprlock.conf" = {
    force = true;
    text = ''
      general {
        disable_loading_bar = false
        hide_cursor = true
        grace = 0
        no_fade_in = false
      }

      background {
        monitor =
        path = /etc/nixos/wallpapers/wallpaper.jpg
        brightness = 0.8
        contrast = 1.0
        vibrancy = 0.2
        vibrancy_darkness = 0.0
      }

      label {
        monitor =
          text = cmd[update:1000] echo "$(date +"%-H:%M")"
          color = rgba(255, 255, 255, 1.0)
          font_size = 120
          font_family = Roboto Medium
          position = 0, 500
          halign = center
          valign = center
      }
      input-field {
        size = 350, 50
        position = 0, -500
        halign = center
        valign = center
        rounding = 16
        dots_center = true
        outer_color = rgba(255, 255, 255, 0.5)
        inner_color = rgba(0, 0, 0, 0.2)
        font_color = rgba(255, 255, 255, 1.0)
        outline_thickness = 2
      }
    '';
  };
}
