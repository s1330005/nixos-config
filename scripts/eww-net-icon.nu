#!/usr/bin/env nu

let route = (^ip route get 8.8.8.8 | complete)

if $route.exit_code != 0 {
  print ""
  exit 0
}

let iface = (
  $route.stdout
  | parse --regex 'dev (?P<iface>\S+)'
  | get --optional 0.iface
)

if ($iface | is-empty) {
  print ""
} else if $iface =~ '^(eth|en|eno|enp)' {
  print "󰌗"
} else {
  print ""
}
