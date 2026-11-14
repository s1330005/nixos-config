#!/usr/bin/env nu

# Focus a workspace by the id that eww-workspaces reports, on niri or Hyprland
def main [id: int] {
  if ($env.HYPRLAND_INSTANCE_SIGNATURE? | is-not-empty) {
    ^hyprctl dispatch $"hl.dsp.focus\({ workspace = ($id) }\)"
  } else {
    ^niri msg action focus-workspace $id
  }
}
