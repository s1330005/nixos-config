#!/usr/bin/env nu

def battery_tier [capacity: int] {
  if $capacity >= 95 {
    100
  } else if $capacity >= 85 {
    90
  } else if $capacity >= 75 {
    80
  } else if $capacity >= 65 {
    70
  } else if $capacity >= 55 {
    60
  } else if $capacity >= 45 {
    50
  } else if $capacity >= 35 {
    40
  } else if $capacity >= 25 {
    30
  } else if $capacity >= 15 {
    20
  } else {
    10
  }
}

def battery_icon [tier: int, charging: bool] {
  if $charging {
    if $tier == 100 {
      "󰂅"
    } else if $tier == 90 {
      "󰂋"
    } else if $tier == 80 {
      "󰂊"
    } else if $tier == 70 {
      "󰢞"
    } else if $tier == 60 {
      "󰂉"
    } else if $tier == 50 {
      "󰢝"
    } else if $tier == 40 {
      "󰂈"
    } else if $tier == 30 {
      "󰂇"
    } else if $tier == 20 {
      "󰂆"
    } else {
      "󰢜"
    }
  } else {
    if $tier == 100 {
      "󰁹"
    } else if $tier == 90 {
      "󰂂"
    } else if $tier == 80 {
      "󰂁"
    } else if $tier == 70 {
      "󰂀"
    } else if $tier == 60 {
      "󰁿"
    } else if $tier == 50 {
      "󰁾"
    } else if $tier == 40 {
      "󰁽"
    } else if $tier == 30 {
      "󰁼"
    } else if $tier == 20 {
      "󰁻"
    } else {
      "󰁺"
    }
  }
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
    let tier = (battery_tier $capacity)
    let icon = (battery_icon $tier $charging)
    let low = ((not $charging) and ($capacity <= 15))

    {available: true, capacity: $capacity, status: $status, charging: $charging, low: $low, icon: $icon}
  }
}

battery_status | to json --raw

