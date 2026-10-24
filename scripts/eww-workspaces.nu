#!/usr/bin/env nu

const EVENTS = '"WorkspaceActivated"|"WorkspacesChanged"|"WorkspaceActiveWindowChanged"|"WindowsChanged"|"WindowOpenedOrChanged"|"WindowClosed"|"WindowFocusChanged"|"WindowLayoutsChanged"'

# com.mitchellh.ghostty -> Ghostty
def app_name [app_id: any] {
  if $app_id == null { return "?" }
  $app_id | split row "." | last | str capitalize
}

def get_workspaces [] {
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
  | to json --raw
}

get_workspaces

^niri msg -j event-stream
| lines
| where {|line| $line =~ $EVENTS }
| each { print (get_workspaces) }
| ignore
