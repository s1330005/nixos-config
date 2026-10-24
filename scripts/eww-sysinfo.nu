#!/usr/bin/env nu

const INTERVAL = 1sec

def cpu_times [] {
  let f = (open --raw /proc/stat | lines | first | split row --regex '\s+' | skip 1 | first 8 | into int)
  {idle: ($f.3 + $f.4), total: ($f | math sum)}
}

def mem_percent [] {
  let m = (open --raw /proc/meminfo | lines | parse '{key}: {kb} kB' | transpose -r -d | into int MemTotal MemAvailable)
  (($m.MemTotal - $m.MemAvailable) * 100 / $m.MemTotal | math floor)
}

mut prev = (cpu_times)
loop {
  sleep $INTERVAL
  let cur = (cpu_times)
  let total = ($cur.total - $prev.total)
  let cpu = if $total == 0 { 0 } else { (($total - ($cur.idle - $prev.idle)) * 100 / $total | math floor) }
  $prev = $cur

  print ({cpu: $cpu, mem: (mem_percent)} | to json --raw)
}
