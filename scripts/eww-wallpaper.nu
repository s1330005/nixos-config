#!/usr/bin/env nu

const DIR = "/etc/nixos/wallpapers"

# the daemons may still be starting at login
def --wrapped awww_retry [...args: string] {
  for _ in 1..20 {
    if (do { ^awww img ...$args } | complete | get exit_code) == 0 { break }
    sleep 250ms
  }
}

# usage: eww-wallpaper [next|restore]
def main [action: string = "next"] {
  let state = $"($env.HOME)/.local/state/wallpaper"
  let names = (
    ls $DIR
    | get name
    | path parse
    | where extension == "jpg" and not ($it.stem | str starts-with "blur-")
    | get stem
    | sort
  )

  let current = if ($state | path exists) { open --raw $state | str trim } else { $names | first }
  let idx = ($names | enumerate | where item == $current | get index | first | default 0)
  let name = if $action == "next" { $names | get (($idx + 1) mod ($names | length)) } else { $names | get $idx }

  mkdir ($state | path dirname)
  $name | save -f $state

  let transition = if $action == "restore" {
    ["--transition-type" "none"]
  } else {
    ["--transition-type" "fade" "--transition-duration" "1" "--transition-fps" "60"]
  }

  awww_retry $"($DIR)/($name).jpg" ...$transition
  awww_retry -n overlay $"($DIR)/blur-($name).jpg" ...$transition
}
