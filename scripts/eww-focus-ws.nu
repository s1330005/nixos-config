#!/usr/bin/env nu

# Focus a workspace by the id that eww-workspaces reports, on niri, Hyprland or Sway
def main [id: int] {
  if ($env.SWAYSOCK? | is-not-empty) {
    ^swaymsg workspace number $id
  } else if ($env.HYPRLAND_INSTANCE_SIGNATURE? | is-not-empty) {
    ^hyprctl dispatch $"hl.dsp.focus\({ workspace = ($id) }\)"
  } else {
    ^niri msg action focus-workspace $id
  }
}
