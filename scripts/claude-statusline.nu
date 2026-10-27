#!/usr/bin/env nu

# Claude Code status line: model, context usage, session cost, plan rate limits.
# Claude Code pipes session JSON on stdin; fields can be missing (e.g. rate_limits
# only appears for subscription plans after the first response), so every lookup is optional.

def pct_color [p: number] {
  if $p >= 80 { ansi red } else if $p >= 50 { ansi yellow } else { ansi green }
}

def limit_text [label: string, limit] {
  if $limit == null { return null }
  let p = ($limit.used_percentage? | default 0 | math round)
  let reset = if $limit.resets_at? != null {
    let t = ($limit.resets_at * 1_000_000_000 | into datetime | date to-timezone local)
    $" ↻($t | format date '%m/%d %H:%M')"
  } else { "" }
  $"($label) (pct_color $p)($p)%(ansi reset)($reset)"
}

def main [] {
  let s = (open --raw /dev/stdin | from json)

  let model = ($s.model?.display_name? | default "?")
  let ctx = ($s.context_window?.used_percentage?)
  let cost = ($s.cost?.total_cost_usd?)

  let parts = [
    $"(ansi cyan)($model)(ansi reset)"
    (if $ctx != null { let p = ($ctx | math round); $"ctx (pct_color $p)($p)%(ansi reset)" })
    (if $cost != null { $"$($cost | math round --precision 2)" })
    (limit_text "5h" $s.rate_limits?.five_hour?)
    (limit_text "7d" $s.rate_limits?.seven_day?)
  ]

  print ($parts | compact | str join " │ ")
}
