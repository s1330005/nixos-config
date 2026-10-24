#!/usr/bin/env nu

const ICON_WIRED = "󰌗"
const ICON_WIFI = ""
const ICON_OFF = ""

def is_up [iface: string] {
  (open --raw $"/sys/class/net/($iface)/operstate" | str trim) == "up"
}

def is_wireless [iface: string] {
  $"/sys/class/net/($iface)/wireless" | path exists
}

def net_icon [] {
  let up = (
    ls /sys/class/net
    | get name
    | path basename
    | where {|i| $i != "lo" and $i !~ '^(veth|docker|br-|virbr|wg|tun|tap)' }
    | where {|i| is_up $i }
  )

  if ($up | any {|i| $i =~ '^(eth|en)' and not (is_wireless $i) }) {
    $ICON_WIRED
  } else if ($up | any {|i| is_wireless $i }) {
    $ICON_WIFI
  } else {
    $ICON_OFF
  }
}

print (net_icon)

^ip monitor link
| lines
| each { print (net_icon) }
| ignore
