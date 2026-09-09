#!/usr/bin/env nu

def volume_icon [] {
  let volume = (^wpctl get-volume "@DEFAULT_AUDIO_SINK@" | str trim)

  if ($volume | str contains "0.00") {
    "󰖁"
  } else {
    "󰕾"
  }
}

volume_icon

^pactl subscribe
| lines
| each { |line|
    if $line =~ "Event 'change' on sink" {
      print (volume_icon)
    }
  }
| ignore
