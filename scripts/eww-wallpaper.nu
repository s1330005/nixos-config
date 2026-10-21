#!/usr/bin/env nu

# usage: eww-wallpaper [next|restore]
def main [action: string = "next"] {
  let dir = "/etc/nixos/wallpapers"
  let state = $"($env.HOME)/.local/state/wallpaper"
  let names = (
    ls $dir
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

  let transition = if $action == "restore" { ["--transition-type" "none"] } else { ["--transition-type" "fade" "--transition-duration" "1" "--transition-fps" "60"] }

  # the daemons may still be starting at login
  for _ in 1..20 {
    let ok = (do { ^awww img $"($dir)/($name).jpg" ...$transition } | complete | get exit_code) == 0
    if $ok { break }
    sleep 250ms
  }
  for _ in 1..20 {
    let ok = (do { ^awww img -n overlay $"($dir)/blur-($name).jpg" ...$transition } | complete | get exit_code) == 0
    if $ok { break }
    sleep 250ms
  }
}
