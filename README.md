# FrostOS

*A cooler way to compute.* FrostOS is a lightweight Arch Linux-based OS with its own desktop, **FrostDE**, designed to look and feel like macOS. The full spec is in [info.md](info.md).

> **Status: FrostDE preview.** This builds a **live ISO** you can boot in a VM. There is **no installer yet**: nothing is written to disk.

## FrostDE

FrostDE is FrostOS's own desktop. Its parts:

| Layer | What | Where |
|---|---|---|
| Shell | Menu bar, Dock, Launchpad, Spotlight, Control Center, notifications, wallpaper | [`frostde/shell/`](frostde/shell) (QML, runs on [Quickshell](https://quickshell.org)) |
| Settings | **Frost Settings**: Wi-Fi, Bluetooth, Sound, Displays, Appearance, Dock, Keyboard, Date & Time, Battery, Users, Privacy & Security, Storage, Software Update, About | [`frostde/settings/frost-settings`](frostde/settings/frost-settings) (Python, GTK 4, libadwaita) |
| Window engine | Draws windows, blur, rounded corners, shadows, animations | [Hyprland](https://hypr.land), set up by [`frostde/hypr/hyprland.lua`](frostde/hypr/hyprland.lua) |
| Session | Starts everything, with a fallback for VMs without 3D graphics | [`frostde/bin/frostde-session`](frostde/bin/frostde-session) |

**What works like a Mac:**
- **Menu bar:** snowflake menu (About, Settings, Sleep, Restart, Shut Down, Lock, Log Out), the app name with its menu, a Window menu, a Help menu, status icons, date and time.
- **Dock:** icons magnify, open apps get a dot and launching apps bounce. It has Launchpad and Trash, a right-click menu (Keep in Dock, Quit), and optional auto-hide.
- **Launchpad**, **Spotlight** (apps, sums, web search), **Control Center** (Wi-Fi, Bluetooth, Do Not Disturb, Dark Mode, brightness, volume) and **Notification Center**.
- **Windows:** windows float freely, and window buttons sit on the left as red, yellow and green circles. Windows have rounded corners, soft shadows and frosted blur.
- **Light and dark mode:** switches the shell, the wallpaper and the apps together.

**Not done yet:**
- **Minimize button:** Hyprland doesn't offer minimizing to apps, so apps show only the red and green buttons. Minimize with **Super + M** or Window → Minimize; restore from the Dock.
- **Super + Tab app switcher**, Mission Control and desktop icons.
- **App menus:** the menu bar shows FrostDE's own menus, not each app's File/Edit/View menus.
- **Custom login screen:** a text login appears after you log out.
- **Installer, Wine/Bottles, Waydroid and the custom Frost Store** (Frost Store is GNOME Software for now).
- **macOS apps:** research only. FrostOS does **not** claim to run macOS apps.

FrostDE copies the macOS layout and behavior, but not Apple's artwork. The logo, wallpapers and Frost icons are original. App icons come from the free WhiteSur icon theme, and the font is Inter.

## Keyboard shortcuts

Super is the key with the Windows logo (it does what Command does on a Mac).

| Keys | Action |
|---|---|
| Super + Space | Spotlight |
| Super + A | Launchpad |
| Super + K / Super + N | Control Center / Notification Center |
| Super + Return, E, B, comma | Terminal, Files, Brave, Frost Settings |
| Super + W or Q | Close window |
| Super + M or H | Minimize |
| Super + F / Super + Ctrl + F | Full screen / Zoom |
| Super + 1…9, Super + Ctrl + ←/→ | Switch desktop |
| Super + Shift + 3 / 4 | Screenshot of the screen / an area |
| Super + L, Super + Shift + Q | Lock, Log out |

## Get the ISO

Every push to `main` runs two jobs on GitHub Actions:

1. **Test FrostDE (screenshots)** takes about 5 minutes. It checks the Hyprland config, starts the FrostDE shell and Frost Settings on an invisible screen, and saves screenshots (artifact **frostde-screenshots**).
2. **Build the ISO** takes about 20–40 minutes and only runs if the test passed. Download the artifact **frostos-iso** and unzip it.

## Test in VirtualBox

| Setting | Value |
|---|---|
| Type / Version | Linux / Arch Linux (64-bit) |
| Memory | 4096 MB or more |
| CPUs | 2 or more |
| Display | **VMSVGA**, 128 MB video memory |
| 3D acceleration | Try **on** first. If the screen stays black, turn it off. |
| Storage | Attach the `.iso` as the optical drive. No hard disk is needed yet. |

FrostOS logs you in as `frost` (no password). If you end up at a text screen, log in as `frost` and type `frostde-session`. Logs are in `~/.cache/frostde/`.

## Project layout

```
frostde/                  FrostDE: shell, Frost Settings, Hyprland config, session scripts, GTK styling
branding/                 SVG sources for wallpapers and the boot menu background
iso/packages.x86_64       packages FrostOS adds to the Arch ISO
iso/aur-packages.txt      AUR packages built during the ISO build (Brave, WhiteSur icons)
iso/airootfs/             files copied into the system as-is
scripts/build-iso.sh      builds the ISO (in an Arch Linux container on GitHub Actions)
scripts/build-aur.sh      builds the AUR packages into a local repo for the ISO
scripts/test-frostde.sh   runs FrostDE headless and takes screenshots
```

## Credits

FrostOS is built on [Arch Linux](https://archlinux.org), [Hyprland](https://hypr.land) and [Quickshell](https://quickshell.org). It is not affiliated with Arch Linux, Apple or Brave. The snowflake logo and wallpapers are original FrostOS artwork. Icons: [WhiteSur](https://github.com/vinceliuice/WhiteSur-icon-theme) (GPL-3.0). Fonts: Inter, JetBrains Mono, Symbols Nerd Font.
