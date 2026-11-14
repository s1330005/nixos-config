#!/usr/bin/env nu

const DIR = "/etc/nixos/wallpapers"

# the daemons may still be starting at login
def --wrapped awww_retry [...args: string] {
  for _ in 1..20 {
    if (do { ^awww img --transition-type none ...$args } | complete | get exit_code) == 0 { break }
    sleep 250ms
  }
}

def main [] {
  awww_retry $"($DIR)/wallpaper.jpg"
  awww_retry -n overlay $"($DIR)/blur-wallpaper.jpg"
}
