#!/usr/bin/env nu

def battery_icon [] {
  "󱐋"
}

def battery_status [] {
  let bat_list = (glob /sys/class/power_supply/BAT* | sort)

  if ($bat_list | is-empty) {
    {available: false, capacity: 0, status: "Unknown", charging: false, low: false, icon: "󰂑"}
  } else {
    let bat = ($bat_list | first)
    let capacity = (open --raw $"($bat)/capacity" | str trim | into int)
    let status = (open --raw $"($bat)/status" | str trim)
    let charging = ($status == "Charging")
    let icon = (battery_icon)
    let low = ((not $charging) and ($capacity <= 15))

    {available: true, capacity: $capacity, status: $status, charging: $charging, low: $low, icon: $icon}
  }
}

battery_status | to json --raw

