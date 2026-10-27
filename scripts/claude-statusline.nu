#!/usr/bin/env nu

# Claude Code status line: model, context usage, session cost, plan rate limits.
# Claude Code pipes session JSON on stdin; fields can be missing (e.g. rate_limits
# only appears for subscription plans after the first response), so every lookup is optional.

def pct_color [p: number] {
  if $p >= 80 { ansi red } else if $p >= 50 { ansi yellow } else { ansi green }
}

# Fixed-width gauge using eighth blocks so small changes stay visible
def bar [p: number, width: int = 10] {
  let p = ([([$p 0] | math max) 100] | math min)
  let eighths = ($p * $width * 8 / 100 | math round | into int)
  let full = ($eighths // 8)
  let rem = ($eighths mod 8)
  let partial = if $rem > 0 { ["" "▏" "▎" "▍" "▌" "▋" "▊" "▉"] | get $rem } else { "" }
  let empty = ($width - $full - ($partial | str length --grapheme-clusters))
  let filled = ("█" | fill --character "█" --width $full)
  let rest = ("" | fill --character "·" --width $empty)
  $"(pct_color $p)(if $full > 0 { $filled } else { '' })($partial)(ansi dark_gray)($rest)(ansi reset)"
}

def gauge [label: string, p: number] {
  let p = ($p | math round)
  $"(ansi light_gray)($label)(ansi reset) (bar $p) (pct_color $p)($p | fill --alignment right --width 3)%(ansi reset)"
}

def limit_text [label: string, limit] {
  if $limit == null { return null }
  let p = ($limit.used_percentage? | default 0)
  let reset = if $limit.resets_at? != null {
    let t = ($limit.resets_at * 1_000_000_000 | into datetime | date to-timezone local)
    $" (ansi dark_gray)↻($t | format date '%m/%d %H:%M')(ansi reset)"
  } else { "" }
  $"(gauge $label $p)($reset)"
}

def main [] {
  # Read via cat: `open /dev/stdin` fails when stdin is a socket
  let s = (^cat | from json)

  let model = ($s.model?.display_name? | default "?")
  let ctx = ($s.context_window?.used_percentage?)
  let cost = ($s.cost?.total_cost_usd?)

  let parts = [
    $"(ansi cyan)($model)(ansi reset)"
    (if $ctx != null { gauge "ctx" $ctx })
    (if $cost != null { $"$($cost | math round --precision 2)" })
    (limit_text "5h" $s.rate_limits?.five_hour?)
    (limit_text "7d" $s.rate_limits?.seven_day?)
  ]

  print ($parts | compact | str join " │ ")
}
