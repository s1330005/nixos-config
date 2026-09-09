#!/usr/bin/env nu

def get_workspaces [] {
  ^niri msg -j workspaces
  | from json
  | select id idx is_active
  | sort-by idx
  | to json --raw
}

get_workspaces

^niri msg -j event-stream
| lines
| each { |line|
    if $line =~ '"WorkspaceActivated"|"WorkspacesChanged"|"WorkspaceActiveWindowChanged"' {
      print (get_workspaces)
    }
  }
| ignore
