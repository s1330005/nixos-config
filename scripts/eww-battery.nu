#!/usr/bin/env nu

def battery_status [] {
  let bat = (glob /sys/class/power_supply/BAT* | sort | first | default null)

  if $bat == null {
    {available: false, capacity: 0, charging: false}
  } else {
    {
      available: true
      capacity: (open --raw $"($bat)/capacity" | str trim | into int)
      charging: ((open --raw $"($bat)/status" | str trim) == "Charging")
    }
  } | to json --raw
}

print (battery_status)

# upower only signals that something changed; the value is re-read from sysfs
^upower --monitor
| lines
| each { print (battery_status) }
| ignore
