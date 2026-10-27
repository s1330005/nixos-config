#!/usr/bin/env nu

^eww daemon

# Any eww client spawns its own daemon when it fails to talk to the running one
# (even after `eww ping` succeeds), so pass --no-daemonize to forbid that and retry instead
let windows = [bar-window clock cpu-window gpu-window mem-window workspaces-window volume-window net-window vpn-window battery-window]
for _ in 1..50 {
  if (do { ^eww --no-daemonize open-many ...$windows } | complete).exit_code == 0 { break }
  sleep 200ms
}
