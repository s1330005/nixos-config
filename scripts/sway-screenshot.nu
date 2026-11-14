#!/usr/bin/env nu

# Save a screenshot to ~/Pictures/Screenshots and copy it to the clipboard
# mode: region (pick with slurp) | output (focused monitor) | window (focused window)
def main [mode: string = "region"] {
  let dir = ("~/Pictures/Screenshots" | path expand)
  mkdir $dir
  let file = ($dir | path join $"Screenshot from (date now | format date '%Y-%m-%d %H-%M-%S').png")

  match $mode {
    "region" => { ^grim -g (^slurp | str trim) $file }
    "output" => {
      let name = (^swaymsg -t get_outputs | from json | where focused | first | get name)
      ^grim -o $name $file
    }
    "window" => {
      let geom = (
        ^swaymsg -t get_tree
        | ^jq -r '.. | select(.focused? == true) | "\(.rect.x + .window_rect.x),\(.rect.y + .window_rect.y) \(.window_rect.width)x\(.window_rect.height)"'
        | str trim
      )
      ^grim -g $geom $file
    }
    _ => { error make {msg: $"unknown mode: ($mode)"} }
  }

  open --raw $file | ^wl-copy --type image/png
}
