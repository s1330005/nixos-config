#!/usr/bin/env nu

^eww daemon

# Any eww client spawns its own daemon when it cannot connect, so wait until
# this one is reachable before opening windows (otherwise two daemons end up running)
for _ in 1..50 {
  if (do { ^eww ping } | complete).exit_code == 0 { break }
  sleep 100ms
}

^eww open-many bar-window clock cpu-window gpu-window mem-window workspaces-window volume-window net-window vpn-window battery-window
