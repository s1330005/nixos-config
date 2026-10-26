#!/usr/bin/env nu

# wg-quick creates/removes the interface, and wireguard reports operstate "unknown",
# so check for an administratively up wg/tun interface instead
def vpn_status [] {
  let up = (
    ls /sys/class/net
    | get name
    | path basename
    | where {|i| $i =~ '^(wg|tun)' }
    # the interface can vanish between ls and open while wg-quick is tearing it down
    | where {|i| try { (open --raw $"/sys/class/net/($i)/flags" | str trim | into int) mod 2 == 1 } catch { false } }
  )
  if ($up | is-empty) { "OFF" } else { "ON" }
}

print (vpn_status)

^ip monitor link
| lines
| each { print (vpn_status) }
| ignore
