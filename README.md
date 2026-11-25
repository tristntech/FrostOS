# FrostOS

*A cooler way to compute.* FrostOS is a lightweight Arch Linux-based OS with a clean, light-blue look, inspired by macOS layouts but with its own design. The full spec is in [info.md](info.md).

> **Status: Phase 1 (foundation) + start of Phase 2 (desktop look).** This builds a **live ISO** you can boot in a VM. There is **no installer yet**: nothing is written to disk.

## Get the ISO

Every push to `main` builds the ISO on GitHub Actions (about 30–60 minutes).

1. Open the **Actions** tab and click the newest green **Build FrostOS ISO** run.
2. Under **Artifacts**, download **frostos-iso** (a zip containing the `.iso`) and unzip it.
3. **frostos-previews** has PNGs of the wallpapers, logo and boot menu, so you can look at them without booting.

## Test in VirtualBox

| Setting | Value |
|---|---|
| Type / Version | Linux / Arch Linux (64-bit) |
| Memory | 4096 MB or more |
| CPUs | 2 or more |
| Display | Graphics controller **VMSVGA**, video memory 128 MB |
| 3D acceleration | Start **off**. Turn it on later to test smoother animations. |
| Storage | Attach the `.iso` as the optical drive. No hard disk is needed yet. |

Boot it. FrostOS should log you in automatically as the user `frost` (no password).

## What is in the live ISO

| Area | What you get | How |
|---|---|---|
| Base | Arch Linux, systemd, PipeWire, NetworkManager, Bluetooth, Wayland + XWayland | Arch's official `releng` ISO profile + extra packages |
| Desktop | KDE Plasma 6 on Wayland | Picked over a custom shell: blur, animations, a settings app, a store and a file manager all already work, so nothing gets reinvented |
| Top bar | Snowflake menu, app menu, Wi-Fi/Bluetooth/battery/volume, notifications, date and time | Plasma panel |
| Dock | Centered, floating, translucent. Launchpad, pinned apps with running indicators, Trash. Position, size and hiding can be changed in edit mode | Plasma panel set to "fit content" |
| Windows | Close/minimize/maximize on the left, blur, "magic lamp" minimize, snapping, 4 workspaces | KWin |
| Theme | **FrostOS Light** and **FrostOS Dark** global themes, Frost color schemes, FrostOS wallpapers (light + dark), snowflake splash screen | `org.frostos.light` / `org.frostos.dark` |
| Frost Settings | KDE System Settings | renamed |
| Frost Files | Dolphin | renamed |
| Frost Terminal | Konsole with the Frost profile (frosted navy, JetBrains Mono) | renamed |
| Frost Store | Discover with Arch packages + Flathub | renamed |
| Browser | **Brave**, default browser, pinned to the dock | official `brave-bin` AUR package, built during the ISO build |
| Utilities | KWrite/Kate, Ark, Gwenview, Haruna, KCalc, KClock, Spectacle, System Monitor | Arch packages |

**Reduce motion:** Frost Settings → Animation speed → slide to *Instant*.
**Light/dark:** Frost Settings → Quick Settings, or Global Theme.

## Not done yet (planned)

- **Installer** (Calamares + Btrfs snapshots): Phase 7. The live ISO cannot install yet.
- **Dock magnification**: Plasma's dock has no magnify-on-hover. Needs a custom dock widget.
- **Fully rounded window corners**: Breeze rounds only some corners. A KWin effect is planned.
- **Custom login/lock screen**: SDDM uses Breeze with the FrostOS wallpaper for now.
- **Boot splash (Plymouth)**, **setup wizard**, **FrostOS update app**: Phase 6.
- **Windows apps (Wine/Bottles)** and **Android apps (Waydroid)**: Phase 4. Not installed yet.
- **macOS apps**: research only. FrostOS does **not** claim to run macOS apps.

## Project layout

```
branding/                 SVG sources for wallpapers and the boot menu background
iso/packages.x86_64       packages FrostOS adds to the Arch ISO
iso/aur-packages.txt      AUR packages built during the ISO build (Brave)
iso/airootfs/             files copied into the system as-is
  etc/xdg/                KDE defaults (window manager, splash, terminal, default apps)
  etc/pacman.d/hooks/     keeps FrostOS branding after package updates
  usr/share/plasma/look-and-feel/   FrostOS Light / Dark global themes (layout = top bar + dock)
  usr/share/color-schemes/          Frost Light / Frost Dark colors
  usr/share/konsole/                Frost Terminal profiles and colors
  usr/share/icons/hicolor/          snowflake logo, app icon, Launchpad icon
iso/config/kdeglobals.in  system-wide KDE settings (fonts, theme, browser)
scripts/build-iso.sh      builds the ISO (runs in an Arch Linux container on GitHub Actions)
scripts/build-aur.sh      builds the AUR packages into a local repo for the ISO
```

To build on a real Arch Linux machine: `sudo ./scripts/build-iso.sh` (output goes to `out/`).

## Credits

FrostOS is built on [Arch Linux](https://archlinux.org) and [KDE Plasma](https://kde.org/plasma-desktop/). It is not affiliated with Arch Linux, KDE, Apple or Brave. The snowflake logo and wallpapers are original FrostOS artwork.
