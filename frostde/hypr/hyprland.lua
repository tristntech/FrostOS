-- ====================================================================
--  FrostDE: window engine settings (Hyprland 0.57+, Lua config)
--
--  Hyprland draws the windows, blur, shadows and animations. Everything
--  else you see (menu bar, Dock, Launchpad, ...) is the FrostDE shell in
--  /usr/share/frostde/shell.
--
--  Your own changes go in ~/.config/frostde/hyprland-user.lua
--  (loaded at the end, so it can override anything here).
--  Hyprland docs: https://wiki.hypr.land/configuring/
-- ====================================================================

-- frostde-session sets these before starting Hyprland.
local in_vm    = os.getenv("FROSTDE_VM") == "1"
local software = os.getenv("FROSTDE_SOFTWARE_RENDERING") == "1"
local light_effects = software          -- blur and shadows are too slow without a GPU

-- --- Screens ---------------------------------------------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- --- Apps --------------------------------------------------------------
local terminal = "ptyxis --new-window"
local files    = "nautilus --new-window"
local browser  = "brave"
local settings = "frost-settings"

-- --- Start the desktop -------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("qs -p /usr/share/frostde/shell")
    hl.exec_cmd("frostde-welcome")
end)

-- --- Environment -------------------------------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- --- Look --------------------------------------------------------------
hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 1,
        col = {
            active_border   = "rgba(17304a40)",
            inactive_border = "rgba(17304a26)",
        },
        resize_on_border = true,
        extend_border_grab_area = 12,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2.4,        -- smoother "squircle" corners
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = not light_effects,
            range        = 32,
            render_power = 3,
            offset       = { 0, 10 },
            color          = "rgba(0a141e55)",
            color_inactive = "rgba(0a141e30)",
        },

        blur = {
            enabled   = not light_effects,
            size      = 10,
            passes    = 3,
            noise     = 0.015,
            contrast  = 1.0,
            brightness = 1.0,
            vibrancy  = 0.2,
            popups    = true,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = 0x0b1828,
    },

    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },

    cursor = {
        -- most virtual machines need software cursors
        no_hardware_cursors = in_vm and 1 or 2,
    },

    debug = {
        enable_stdout_logs = true,
    },
})

-- --- Animations: quick and smooth, macOS-like -------------------------
hl.curve("frost",    { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("frostOut", { type = "bezier", points = { { 0.4, 0 }, { 1, 1 } } })
hl.curve("springy",  { type = "spring", mass = 1, stiffness = 260, damping = 24 })

hl.animation({ leaf = "global",     enabled = true, speed = 6,   bezier = "frost" })
hl.animation({ leaf = "windows",    enabled = true, speed = 4.5, spring = "springy" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3.5, spring = "springy", style = "popin 88%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2,   bezier = "frostOut", style = "popin 88%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,   bezier = "frost" })
hl.animation({ leaf = "layersIn",   enabled = true, speed = 3,   bezier = "frost", style = "fade" })
hl.animation({ leaf = "layersOut",  enabled = true, speed = 2,   bezier = "frostOut", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4,   bezier = "frost", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "frost", style = "slidevert" })

-- --- Keyboard, mouse and touchpad -----------------------------------
hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Three-finger swipe switches desktops, like on a Mac.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- --- Windows: float freely, like on a Mac ----------------------------
hl.window_rule({
    name   = "frostde-float",
    match  = { class = ".*" },
    float  = true,
    center = true,
})

-- --- Frosted glass behind the FrostDE shell -------------------------
for _, ns in ipairs({
    "frostde-menubar", "frostde-dock", "frostde-launchpad", "frostde-spotlight",
    "frostde-controlcenter", "frostde-notifications", "frostde-notificationcenter",
}) do
    hl.layer_rule({
        name         = "blur-" .. ns,
        match        = { namespace = "^" .. ns .. "$" },
        blur         = not light_effects,
        blur_popups  = not light_effects,
        ignore_alpha = 0.05,
    })
end

-- --- Keyboard shortcuts (Super = the Command key on a Mac) -----------
local mod = "SUPER"

-- FrostDE
hl.bind(mod .. " + Space", hl.dsp.global("frostde:spotlight"))
hl.bind(mod .. " + A",     hl.dsp.global("frostde:launchpad"))
hl.bind(mod .. " + N",     hl.dsp.global("frostde:notifications"))
hl.bind(mod .. " + K",     hl.dsp.global("frostde:controlcenter"))

-- Apps
hl.bind(mod .. " + Return",  hl.dsp.exec_cmd(terminal))
hl.bind("CTRL + ALT + T",    hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + E",       hl.dsp.exec_cmd(files))
hl.bind(mod .. " + B",       hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + comma",   hl.dsp.exec_cmd(settings))

-- Windows
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + M", hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
hl.bind(mod .. " + H", hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))   -- tile / float this window

-- Move and resize with Super + mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Desktops (workspaces)
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + CTRL + left",  hl.dsp.focus({ workspace = "e-1" }))

-- Session
hl.bind(mod .. " + L",         hl.dsp.exec_cmd("frostde-lock"))
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exec_cmd("frostde-logout"))

-- Screenshots (like Cmd+Shift+3 / Cmd+Shift+4 on a Mac)
hl.bind(mod .. " + SHIFT + 3", hl.dsp.exec_cmd("frostde-screenshot screen"))
hl.bind(mod .. " + SHIFT + 4", hl.dsp.exec_cmd("frostde-screenshot area"))
hl.bind("Print",               hl.dsp.exec_cmd("frostde-screenshot area"))

-- Volume, brightness and media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- --- Your settings ---------------------------------------------------
-- monitors.lua and keyboard.lua are written by Frost Settings;
-- hyprland-user.lua is yours to edit.
for _, name in ipairs({ "monitors.lua", "keyboard.lua", "hyprland-user.lua" }) do
    local ok, err = pcall(function()
        local path = os.getenv("HOME") .. "/.config/frostde/" .. name
        local f = io.open(path, "r")
        if f then
            f:close()
            dofile(path)
        end
    end)
    if not ok then
        print("FrostDE: could not load " .. name .. ": " .. tostring(err))
    end
end
