#!/usr/bin/env nu

def volume_text [] {
  let vol = (
    ^wpctl get-volume "@DEFAULT_AUDIO_SINK@"
    | str trim
    | split row --regex '\s+'
    | get 1
    | into float
  )

  $"(($vol * 100 | math floor | into int))%"
}

def volume_icon [] {
  let volume = (^wpctl get-volume "@DEFAULT_AUDIO_SINK@" | str trim)

  if ($volume | str contains "0.00") {
    "󰖁"
  } else {
    "󰕾"
  }
}

^eww open-many clock cpu-window mem-window launcher-window workspaces-window date-window volume-window net-window cputemp-window battery-window
sleep 300ms
^eww update $"volume_text=(volume_text)"
^eww update $"volume_icon=(volume_icon)"
