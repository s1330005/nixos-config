#!/usr/bin/env nu

# wpctl fails while PipeWire or the sink is still coming up at login;
# return null instead of erroring so the listener survives
def volume_text [] {
  let out = (try { ^wpctl get-volume "@DEFAULT_AUDIO_SINK@" | complete } catch { return null })
  if $out.exit_code != 0 { return null }

  let vol = (try { $out.stdout | split row " " | get 1 | into float } catch { return null })
  $"($vol * 100 | math round | into int)%"
}

def emit [] {
  let text = (volume_text)
  if $text != null { print $text }
}

# pactl exits when pipewire-pulse is not up yet or restarts, so reconnect.
# 'new' on sink catches the device appearing after login, server catches
# default-sink switches (e.g. plugging in earphones)
loop {
  emit
  # `|| true`: a non-zero exit would abort the whole script (try buffers the stream)
  ^sh -c "LC_ALL=C stdbuf -oL pactl subscribe || true"
  | lines
  | where {|line| $line =~ "'(new|change)' on (sink|server|card)" }
  | each { emit }
  | ignore
  sleep 1sec
}
