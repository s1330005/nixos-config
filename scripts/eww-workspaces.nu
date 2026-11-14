#!/usr/bin/env nu

const NIRI_EVENTS = '"WorkspaceActivated"|"WorkspacesChanged"|"WorkspaceActiveWindowChanged"|"WindowsChanged"|"WindowOpenedOrChanged"|"WindowClosed"|"WindowFocusChanged"|"WindowLayoutsChanged"'
const HYPR_EVENTS = '^(workspace|workspacev2|createworkspace|destroyworkspace|moveworkspace|focusedmon|activewindowv2|openwindow|closewindow|movewindow|changefloatingmode)>>'

# com.mitchellh.ghostty -> Ghostty
def app_name [app_id: any] {
  if $app_id == null or $app_id == "" { return "?" }
  $app_id | split row "." | last | str capitalize
}

def niri_state [] {
  # follow the on-screen order: scrolling columns left to right, floating windows last
  let windows = (
    ^niri msg -j windows
    | from json
    | sort-by id
    | sort-by {|w| $w.layout.pos_in_scrolling_layout | default [999999 999999] }
  )
  let workspaces = (^niri msg -j workspaces | from json | sort-by idx)
  let active = ($workspaces | where is_active | get -o 0.id)

  let apps = (
    $windows
    | where workspace_id == $active
    | each {|w| {name: (app_name $w.app_id), focused: $w.is_focused} }
  )

  {
    workspaces: ($workspaces | select id idx is_active)
    apps: $apps
  }
}

def hypr_state [] {
  let active = (^hyprctl -j activeworkspace | from json)
  let focused = (^hyprctl -j activewindow | from json | get -o address)

  # same shape as niri: workspaces on the focused monitor, id doubles as the label
  let workspaces = (
    ^hyprctl -j workspaces
    | from json
    | where id > 0 and monitor == $active.monitor
    | sort-by id
    | each {|ws| {id: $ws.id, idx: $ws.id, is_active: ($ws.id == $active.id)} }
  )

  # on-screen order: tiled left to right, floating windows last
  let apps = (
    ^hyprctl -j clients
    | from json
    | where workspace.id == $active.id
    | sort-by {|w| [($w.floating | into int) $w.at.0 $w.at.1] }
    | each {|w| {name: (app_name $w.class), focused: ($w.address == $focused)} }
  )

  {workspaces: $workspaces, apps: $apps}
}

# Sway windows under a node in tree order (left to right), floating ones last
def sway_windows [node: record] {
  let tiled = ($node.nodes? | default [])
  let floating = ($node.floating_nodes? | default [])
  if ($tiled | is-empty) and ($floating | is-empty) {
    if $node.type in [con floating_con] { [$node] } else { [] }
  } else {
    $tiled ++ $floating | reduce -f [] {|child, acc| $acc ++ (sway_windows $child) }
  }
}

def sway_state [] {
  # workspaces on the focused output, `visible` marks the one shown there
  let all = (^swaymsg -t get_workspaces | from json)
  let current = ($all | where focused | first)
  let workspaces = (
    $all
    | where output == $current.output and num >= 0
    | sort-by num
    | each {|ws| {id: $ws.num, idx: $ws.num, is_active: $ws.visible} }
  )

  let ws_node = (
    ^swaymsg -t get_tree
    | from json
    | get nodes
    | reduce -f [] {|out, acc| $acc ++ ($out.nodes? | default []) }
    | where name == $current.name
    | first
  )
  let apps = (
    sway_windows $ws_node
    | each {|w|
        let id = ($w.app_id? | default ($w.window_properties?.class? | default ""))
        {name: (app_name $id), focused: $w.focused}
      }
  )

  {workspaces: $workspaces, apps: $apps}
}

def emit [state: closure] {
  print (do $state | to json --raw)
}

if ($env.SWAYSOCK? | is-not-empty) {
  emit { sway_state }
  # one compact line per event
  ^swaymsg -t subscribe -m '["workspace","window"]'
  | ^jq -c --unbuffered .
  | lines
  | each { emit { sway_state } }
  | ignore
} else if ($env.HYPRLAND_INSTANCE_SIGNATURE? | is-not-empty) {
  emit { hypr_state }
  let sock = $"($env.XDG_RUNTIME_DIR)/hypr/($env.HYPRLAND_INSTANCE_SIGNATURE)/.socket2.sock"
  ^socat -U - $"UNIX-CONNECT:($sock)"
  | lines
  | where {|line| $line =~ $HYPR_EVENTS }
  | each { emit { hypr_state } }
  | ignore
} else {
  emit { niri_state }
  ^niri msg -j event-stream
  | lines
  | where {|line| $line =~ $NIRI_EVENTS }
  | each { emit { niri_state } }
  | ignore
}
