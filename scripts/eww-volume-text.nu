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

volume_text

^pactl subscribe
| lines
| each { |line|
    if $line =~ "Event 'change' on sink" {
      print (volume_text)
    }
  }
| ignore
