#!/usr/bin/env nu

def is_wireless [iface: string] {
  ($"/sys/class/net/($iface)/wireless" | path exists)
}

def is_up [iface: string] {
  (open --raw $"/sys/class/net/($iface)/operstate" | str trim) == "up"
}

let ifaces = (
  ls /sys/class/net
  | get name
  | path basename
  | where {|i| $i != "lo" and $i !~ '^(veth|docker|br-|virbr|wg|tun|tap)' }
)

let wired = ($ifaces | where {|i| $i =~ '^(eth|en)' and not (is_wireless $i) and (is_up $i) })
let wireless = ($ifaces | where {|i| (is_wireless $i) and (is_up $i) })

if not ($wired | is-empty) {
  print "󰌗"
} else if not ($wireless | is-empty) {
  print ""
} else {
  print ""
}
