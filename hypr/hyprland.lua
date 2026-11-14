-- Hyprland config, kept close to niri/config.kdl (scrolling layout + same keybinds).
-- Binds that niri has but Hyprland lacks are listed at the bottom.

local mod = "SUPER"
local bin = "/home/sam/.local/bin"

-- ── Startup ────────────────────────────────────────────────
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(bin .. "/eww-wallpaper")
    hl.exec_cmd(bin .. "/eww-start")
end)

-- ── Environment ────────────────────────────────────────────
hl.env("XCURSOR_THEME", "Yaru")
hl.env("XCURSOR_SIZE", "24")

-- ── Outputs ────────────────────────────────────────────────
hl.monitor({ output = "eDP-1", mode = "2560x1600@60.001", position = "0x0", scale = 1.25 })
-- niri uses 1.3; Hyprland needs a scale that divides the resolution evenly
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@120.000", position = "auto", scale = 1.333333 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- ── General / Layout ───────────────────────────────────────
hl.config({
    general = {
        layout = "scrolling",
        gaps_in = 3, -- applied per side, so 6px between windows like niri
        -- top 30px leaves room for the eww bar (niri: struts { top 30; })
        gaps_out = { top = 36, right = 6, bottom = 6, left = 6 },
        border_size = 2,
        col = {
            active_border = "rgba(e8e4dccc)",
            inactive_border = "rgba(475258cc)",
        },
    },

    scrolling = {
        column_width = 0.5,
        explicit_column_widths = "0.333, 0.5, 0.667",
        fullscreen_on_one_column = false,
        focus_fit_method = 1,
        wrap_focus = false,
        wrap_swapcol = false,
    },

    decoration = {
        rounding = 10,
        shadow = { enabled = false },
        blur = { enabled = false },
    },

    input = {
        numlock_by_default = true,
        follow_mouse = 1,
        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
})

-- ── Window rules ───────────────────────────────────────────
hl.window_rule({
    name = "firefox-pip",
    match = { class = "firefox$", title = "^Picture-in-Picture$" },
    float = true,
})

-- Hide password managers from screen capture
hl.window_rule({
    name = "hide-keepassxc",
    match = { class = "^org\\.keepassxc\\.KeePassXC$" },
    no_screen_share = true,
})
hl.window_rule({
    name = "hide-secrets",
    match = { class = "^org\\.gnome\\.World\\.Secrets$" },
    no_screen_share = true,
})

-- ── Key bindings ───────────────────────────────────────────
local function bind(keys, dsp, opts)
    hl.bind(keys, dsp, opts)
end
local function m(keys) return mod .. " + " .. keys end
local exec = hl.dsp.exec_cmd
local layout = hl.dsp.layout
local locked = { locked = true }
local repeating = { locked = true, repeating = true }

-- Apps
bind(m("Return"), exec("ghostty"))
bind(m("Space"), exec("walker"))
bind(m("B"), exec("firefox"))
bind(m("N"), exec("nautilus"))
bind(m("M"), exec("thunderbird"))
bind(m("ALT + S"), exec("pkill orca || exec orca"), locked)

-- Media & brightness
bind("XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0"), repeating)
bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), repeating)
bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked)
bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
bind("XF86AudioPlay", exec("playerctl play-pause"), locked)
bind("XF86AudioStop", exec("playerctl stop"), locked)
bind("XF86AudioPrev", exec("playerctl previous"), locked)
bind("XF86AudioNext", exec("playerctl next"), locked)
bind("XF86MonBrightnessUp", exec("brightnessctl --class=backlight set +10%"), repeating)
bind("XF86MonBrightnessDown", exec("brightnessctl --class=backlight set 10%-"), repeating)

-- Window
bind(m("C"), hl.dsp.window.close())

-- Focus / Move / Monitor, for arrows and hjkl
local dirs = {
    { "Left", "H", "l", "left" },
    { "Down", "J", "d", "down" },
    { "Up", "K", "u", "up" },
    { "Right", "L", "r", "right" },
}
for _, d in ipairs(dirs) do
    local arrow, vim, short, long = d[1], d[2], d[3], d[4]
    for _, key in ipairs({ arrow, vim }) do
        -- focus-column-* / focus-window-*
        bind(m(key), layout("focus " .. short))
        -- move-column-left/right, move-window-up/down
        if short == "l" or short == "r" then
            bind(m("CTRL + " .. key), layout("swapcol " .. short))
        else
            bind(m("CTRL + " .. key), hl.dsp.window.move({ direction = long }))
        end
        -- focus-monitor-*
        bind(m("SHIFT + " .. key), hl.dsp.focus({ monitor = short }))
        -- move-column-to-monitor-*
        bind(m("SHIFT + CTRL + " .. key), hl.dsp.window.move({ monitor = short }))
    end
end

-- Workspaces ("r±1" = next/previous on this monitor, creating it if empty, like niri)
for _, k in ipairs({ { "Page_Down", "U", "r+1" }, { "Page_Up", "I", "r-1" } }) do
    for _, key in ipairs({ k[1], k[2] }) do
        bind(m(key), hl.dsp.focus({ workspace = k[3] }))
        bind(m("CTRL + " .. key), hl.dsp.window.move({ workspace = k[3] }))
    end
end

for i = 1, 9 do
    bind(m(tostring(i)), hl.dsp.focus({ workspace = i }))
    bind(m("CTRL + " .. i), hl.dsp.window.move({ workspace = i }))
end

-- Mouse wheel
bind(m("mouse_down"), hl.dsp.focus({ workspace = "r+1" }))
bind(m("mouse_up"), hl.dsp.focus({ workspace = "r-1" }))
bind(m("CTRL + mouse_down"), hl.dsp.window.move({ workspace = "r+1" }))
bind(m("CTRL + mouse_up"), hl.dsp.window.move({ workspace = "r-1" }))
bind(m("mouse_right"), layout("focus r"))
bind(m("mouse_left"), layout("focus l"))
bind(m("CTRL + mouse_right"), layout("swapcol r"))
bind(m("CTRL + mouse_left"), layout("swapcol l"))
bind(m("SHIFT + mouse_down"), layout("focus r"))
bind(m("SHIFT + mouse_up"), layout("focus l"))
bind(m("CTRL + SHIFT + mouse_down"), layout("swapcol r"))
bind(m("CTRL + SHIFT + mouse_up"), layout("swapcol l"))

-- Drag / resize with the mouse (niri: Mod+LMB / Mod+RMB)
bind(m("mouse:272"), hl.dsp.window.drag(), { mouse = true })
bind(m("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Columns
bind(m("bracketleft"), layout("consume_or_expel prev"))
bind(m("bracketright"), layout("consume_or_expel next"))
bind(m("comma"), layout("consume"))
bind(m("period"), layout("expel"))
bind(m("W"), hl.dsp.group.toggle()) -- closest thing to a tabbed column
bind(m("Q"), layout("center"))
bind(m("CTRL + C"), layout("fit visible"))

-- Sizing
bind(m("R"), layout("colresize +conf"))
bind(m("F"), hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(m("SHIFT + F"), hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(m("CTRL + F"), layout("fit active"))
bind(m("minus"), layout("colresize -0.1"))
bind(m("equal"), layout("colresize +0.1"))
bind(m("SHIFT + minus"), hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
bind(m("SHIFT + equal"), hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- Floating
bind(m("V"), hl.dsp.window.float({ action = "toggle" }))
bind(m("SHIFT + V"), function()
    local w = hl.get_active_window()
    if w and w.floating then
        hl.dispatch(hl.dsp.window.cycle_next({ tiled = true }))
    else
        hl.dispatch(hl.dsp.window.cycle_next({ floating = true }))
    end
end)

-- Screenshots (niri saves to ~/Pictures/Screenshots and copies to the clipboard)
local shot = 'f=~/Pictures/Screenshots/"Screenshot from $(date "+%Y-%m-%d %H-%M-%S").png"; '
    .. 'mkdir -p ~/Pictures/Screenshots && '
bind("Print", exec(shot .. 'grim -g "$(slurp)" "$f" && wl-copy < "$f"'))
bind("CTRL + Print", exec(shot .. 'grim -o "$(hyprctl -j activeworkspace | jq -r .monitor)" "$f" && wl-copy < "$f"'))
bind("ALT + Print", exec(shot
    .. 'grim -g "$(hyprctl -j activewindow | jq -r \'"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"\')" "$f" && wl-copy < "$f"'))

-- Session
bind(m("SHIFT + P"), hl.dsp.dpms({ action = "disable" }))
bind(m("SHIFT + E"), exec("uwsm stop"))
bind("CTRL + ALT + Delete", exec("uwsm stop"))

-- Not available in Hyprland (niri only):
--   Mod+O overview, Mod+Shift+/ hotkey overlay, Mod+Home/End,
--   Mod+Shift+U/I/PgUp/PgDn (reorder workspaces), Mod+Shift+R / Mod+Ctrl+R (window height presets),
--   Mod+Escape (shortcut inhibit toggle)
