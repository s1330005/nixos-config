-- Hyprland config: stock example config (dwindle layout) with niri's keybinds.
-- https://wiki.hypr.land/Configuring/Start/

local mainMod = "SUPER"
local bin = "/home/sam/.local/bin"

local terminal = "ghostty"
local fileManager = "nautilus"
local menu = "walker"
local browser = "firefox"

-- ── Monitors ───────────────────────────────────────────────
hl.monitor({ output = "eDP-1", mode = "2560x1600@60.001", position = "0x0", scale = 1.25 })
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@120.000", position = "auto", scale = 1.333333 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- ── Autostart ──────────────────────────────────────────────
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(bin .. "/eww-wallpaper")
    hl.exec_cmd(bin .. "/eww-start")
end)

-- ── Environment ────────────────────────────────────────────
hl.env("XCURSOR_THEME", "Yaru")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- ── Look and feel ──────────────────────────────────────────
hl.config({
    general = {
        -- match niri: gaps 6 + struts { top 30; }
        gaps_in = 3, -- applied per side, so 6px between windows
        gaps_out = { top = 36, right = 6, bottom = 6, left = 6 },
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    input = {
        kb_layout = "us",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
        },
    },
})

-- Default curves and animations
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- 3-finger horizontal swipe switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- ── Key bindings (same keys as niri/config.kdl) ────────────
local exec = hl.dsp.exec_cmd
local function m(keys) return mainMod .. " + " .. keys end
local function bind(keys, dsp, opts) hl.bind(keys, dsp, opts) end
local locked = { locked = true }
local repeating = { locked = true, repeating = true }

-- Apps
bind(m("Return"), exec(terminal))
bind(m("Space"), exec(menu))
bind(m("B"), exec(browser))
bind(m("N"), exec(fileManager))
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
        bind(m(key), hl.dsp.focus({ direction = long }))
        bind(m("CTRL + " .. key), hl.dsp.window.move({ direction = long }))
        bind(m("SHIFT + " .. key), hl.dsp.focus({ monitor = short }))
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
bind(m("mouse_right"), hl.dsp.focus({ direction = "right" }))
bind(m("mouse_left"), hl.dsp.focus({ direction = "left" }))
bind(m("CTRL + mouse_right"), hl.dsp.window.move({ direction = "right" }))
bind(m("CTRL + mouse_left"), hl.dsp.window.move({ direction = "left" }))
bind(m("SHIFT + mouse_down"), hl.dsp.focus({ direction = "right" }))
bind(m("SHIFT + mouse_up"), hl.dsp.focus({ direction = "left" }))
bind(m("CTRL + SHIFT + mouse_down"), hl.dsp.window.move({ direction = "right" }))
bind(m("CTRL + SHIFT + mouse_up"), hl.dsp.window.move({ direction = "left" }))

-- Drag / resize with the mouse (niri: Mod+LMB / Mod+RMB)
bind(m("mouse:272"), hl.dsp.window.drag(), { mouse = true })
bind(m("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Tabs (niri: tabbed column)
bind(m("W"), hl.dsp.group.toggle())

-- Sizing
bind(m("R"), hl.dsp.layout("togglesplit")) -- dwindle: closest to niri's width presets
bind(m("F"), hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(m("SHIFT + F"), hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(m("minus"), hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
bind(m("equal"), hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
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

-- Screenshots: saved to ~/Pictures/Screenshots and copied to the clipboard
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

-- niri binds with no Hyprland/dwindle equivalent:
--   Mod+O overview, Mod+Shift+/ hotkey overlay, Mod+Home/End,
--   Mod+Shift+U/I/PgUp/PgDn (reorder workspaces), Mod+[ ] , . Q Ctrl+C (column ops),
--   Mod+Ctrl+F, Mod+Shift+R / Mod+Ctrl+R, Mod+Escape

-- ── Window rules ───────────────────────────────────────────
hl.window_rule({
    -- Ignore maximize requests from all apps
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

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
