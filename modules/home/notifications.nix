let
  colors = {
    background = "#262626";
    foreground = "#DADADA";
    frame_color = "#3F3F3F";
  };
in
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "Inter 10";
        corner_radius = 8;
        frame_width = 1;
        padding = 12;
        horizontal_padding = 14;
        icon_size = 48;
        origin = "top-right";
        offset = "8x35";
        width = 350;
        height = 300;
        transparency = 0;
        stack_duplicates = false;
        gap_size = 5;
        notification_limit = 12;
        show_indicators = false;
        icon_corner_radius = 6;
      };

      urgency_low = colors // {
        timeout = 6;
      };

      urgency_normal = colors // {
        timeout = 8;
      };

      urgency_critical = colors // {
        frame_color = "#FB464C";
        timeout = 0;
      };
    };
  };
}
