#!/usr/bin/env bash
# Builds the FrostOS live ISO.
#
# GitHub Actions runs this inside an Arch Linux container (see .github/workflows/build-iso.yml).
# You can also run it on a real Arch Linux machine:  sudo ./scripts/build-iso.sh
#
# How it works: we copy Arch's official "releng" archiso profile (the one used to
# build the official Arch ISO), put FrostOS and FrostDE on top, then build.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$REPO_DIR/work}"
OUT_DIR="${OUT_DIR:-$REPO_DIR/out}"
PROFILE_DIR="$WORK_DIR/profile"
LOCAL_REPO="$WORK_DIR/localrepo"
AIROOTFS="$PROFILE_DIR/airootfs"
FROSTDE="$REPO_DIR/frostde"

if [[ $EUID -ne 0 ]]; then
    echo "Please run this as root, for example: sudo $0" >&2
    exit 1
fi

echo "==> Installing build tools"
pacman-key --init >/dev/null 2>&1 || true
pacman -Syu --noconfirm --needed archiso librsvg inter-font noto-fonts dconf python

echo "==> Checking FrostDE files"
python -m py_compile "$FROSTDE/settings/frost-settings"
for f in "$FROSTDE"/bin/*; do bash -n "$f"; done

echo "==> Preparing the archiso profile"
rm -rf "$PROFILE_DIR" "$WORK_DIR/build" "$LOCAL_REPO"
mkdir -p "$WORK_DIR" "$OUT_DIR"
cp -r /usr/share/archiso/configs/releng "$PROFILE_DIR"

# 1. FrostOS files go on top of the releng files.
cp -rT "$REPO_DIR/iso/airootfs" "$AIROOTFS"

# 2. Package list = releng packages + FrostOS packages (comments and duplicates removed).
cat "$PROFILE_DIR/packages.x86_64" "$REPO_DIR/iso/packages.x86_64" \
    | sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' -e '/^$/d' \
    | sort -u > "$PROFILE_DIR/packages.merged"
mv "$PROFILE_DIR/packages.merged" "$PROFILE_DIR/packages.x86_64"

# 3. ISO name and file permissions. Later lines in profiledef.sh override earlier ones.
cat "$REPO_DIR/iso/profiledef-extra.sh" >> "$PROFILE_DIR/profiledef.sh"

# 4. AUR packages (Brave, icons) go into a local repo that only this build uses.
bash "$REPO_DIR/scripts/build-aur.sh" "$LOCAL_REPO"
cat >> "$PROFILE_DIR/pacman.conf" <<EOF

[frostos-local]
SigLevel = Optional TrustAll
Server = file://$LOCAL_REPO
EOF

# 5. FrostDE itself.
install -d "$AIROOTFS/usr/share/frostde" "$AIROOTFS/usr/bin" "$AIROOTFS/usr/share/applications" \
           "$AIROOTFS/usr/share/wayland-sessions" "$AIROOTFS/etc/greetd" \
           "$AIROOTFS/etc/dconf/db/local.d" "$AIROOTFS/etc/dconf/profile"
cp -r "$FROSTDE/shell" "$FROSTDE/gtk" "$AIROOTFS/usr/share/frostde/"
cp "$FROSTDE/hypr/hyprland.lua" "$FROSTDE/hypr/hyprlock.conf" "$FROSTDE/settings.json" "$AIROOTFS/usr/share/frostde/"
cp "$FROSTDE"/bin/* "$FROSTDE/settings/frost-settings" "$AIROOTFS/usr/bin/"
cp "$FROSTDE/applications/org.frostos.Settings.desktop" "$AIROOTFS/usr/share/applications/"
cp "$FROSTDE/applications/frostde.desktop" "$AIROOTFS/usr/share/wayland-sessions/"
cp "$FROSTDE/greetd/config.toml" "$AIROOTFS/etc/greetd/config.toml"
cp "$FROSTDE/dconf/00-frostde" "$AIROOTFS/etc/dconf/db/local.d/"
cp "$FROSTDE/dconf/user-profile" "$AIROOTFS/etc/dconf/profile/user"
dconf compile "$AIROOTFS/etc/dconf/db/local" "$AIROOTFS/etc/dconf/db/local.d"
echo "FrostOS $(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d) (FrostDE preview)" > "$AIROOTFS/etc/frostos-release"

# 6. Boot menu: names and background.
{ grep -rlZ 'Arch Linux' "$PROFILE_DIR/syslinux" "$PROFILE_DIR/efiboot" "$PROFILE_DIR/grub" 2>/dev/null || true; } \
    | xargs -0 -r sed -i -e 's/Arch Linux install medium/FrostOS Live/g' -e 's/Arch Linux/FrostOS/g'
if [[ -f "$PROFILE_DIR/syslinux/splash.png" ]]; then
    rsvg-convert -w 640 -h 480 "$REPO_DIR/branding/bootsplash.svg" -o "$PROFILE_DIR/syslinux/splash.png"
fi

# 7. Wallpapers, rendered from the SVG sources in branding/.
WP="$AIROOTFS/usr/share/backgrounds/frostos"
mkdir -p "$WP"
rsvg-convert -w 3840 -h 2160 "$REPO_DIR/branding/wallpaper-light.svg" -o "$WP/frost-light.png"
rsvg-convert -w 3840 -h 2160 "$REPO_DIR/branding/wallpaper-dark.svg"  -o "$WP/frost-dark.png"

# 8. Services. The Arch ISO uses systemd-networkd + iwd and logs root in on a
#    text screen; FrostOS uses NetworkManager and greetd (which starts FrostDE).
SYSD="$AIROOTFS/etc/systemd/system"
echo "Removing from releng:"
find "$SYSD" ! -type d \( -name 'systemd-networkd*' -o -name 'iwd.service' \) -print -delete
rm -fv "$SYSD/getty@tty1.service.d/autologin.conf"
enable_unit() { # <folder inside /etc/systemd/system> <link name> <unit file>
    mkdir -p "$SYSD/$1"
    ln -sfn "$3" "$SYSD/$1/$2"
}
enable_unit . display-manager.service /usr/lib/systemd/system/greetd.service
enable_unit multi-user.target.wants NetworkManager.service /usr/lib/systemd/system/NetworkManager.service
enable_unit . dbus-org.freedesktop.nm-dispatcher.service /usr/lib/systemd/system/NetworkManager-dispatcher.service
enable_unit bluetooth.target.wants bluetooth.service /usr/lib/systemd/system/bluetooth.service
enable_unit . dbus-org.bluez.service /usr/lib/systemd/system/bluetooth.service
enable_unit graphical.target.wants power-profiles-daemon.service /usr/lib/systemd/system/power-profiles-daemon.service
enable_unit multi-user.target.wants frostos-flathub.service /etc/systemd/system/frostos-flathub.service
ln -sfn /usr/lib/systemd/system/graphical.target "$SYSD/default.target"

# 9. Flathub (the main Flatpak app store): download its official repo file.
curl -fsSL --retry 3 -o "$AIROOTFS/usr/share/frostos/flathub.flatpakrepo" \
    https://dl.flathub.org/repo/flathub.flatpakrepo
grep -q '^GPGKey=' "$AIROOTFS/usr/share/frostos/flathub.flatpakrepo"

# 10. Previews of the artwork, uploaded next to the ISO.
mkdir -p "$OUT_DIR/previews"
rsvg-convert -w 1920 -h 1080 "$REPO_DIR/branding/wallpaper-light.svg" -o "$OUT_DIR/previews/wallpaper-light.png"
rsvg-convert -w 1920 -h 1080 "$REPO_DIR/branding/wallpaper-dark.svg"  -o "$OUT_DIR/previews/wallpaper-dark.png"
[[ -f "$PROFILE_DIR/syslinux/splash.png" ]] && cp "$PROFILE_DIR/syslinux/splash.png" "$OUT_DIR/previews/bootmenu.png"

echo "==> Building the ISO (this takes a while)"
mkarchiso -v -w "$WORK_DIR/build" -o "$OUT_DIR" "$PROFILE_DIR"

# 11. Checks on the finished system.
ROOTFS="$WORK_DIR/build/x86_64/airootfs"
if [[ -d "$ROOTFS" ]]; then
    grep -q '^NAME="FrostOS"' "$ROOTFS/usr/lib/os-release" \
        && echo "::notice title=Branding::os-release says FrostOS" \
        || echo "::warning title=Branding::os-release was not changed to FrostOS"
    for app in org.gnome.Nautilus org.gnome.Ptyxis org.gnome.Software; do
        [[ -f "$ROOTFS/usr/local/share/applications/$app.desktop" ]] \
            || echo "::warning title=Branding::$app was not renamed"
    done
    for bin in Hyprland qs frostde-session frost-settings greetd agreety; do
        [[ -x "$ROOTFS/usr/bin/$bin" ]] || echo "::error title=Missing::/usr/bin/$bin is not in the ISO"
    done
    [[ -d "$ROOTFS/usr/share/icons/WhiteSur" ]] || echo "::warning title=Icons::WhiteSur icon theme is missing"
fi

echo "==> Done! The ISO is in $OUT_DIR"
ls -lh "$OUT_DIR"
