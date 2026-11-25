#!/usr/bin/env bash
# Builds the FrostOS live ISO.
#
# GitHub Actions runs this inside an Arch Linux container (see .github/workflows/build-iso.yml).
# You can also run it on a real Arch Linux machine:  sudo ./scripts/build-iso.sh
#
# How it works: we copy Arch's official "releng" archiso profile (the one used to
# build the official Arch ISO), put the FrostOS files from iso/ on top, then build.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$REPO_DIR/work}"
OUT_DIR="${OUT_DIR:-$REPO_DIR/out}"
PROFILE_DIR="$WORK_DIR/profile"
LOCAL_REPO="$WORK_DIR/localrepo"
AIROOTFS="$PROFILE_DIR/airootfs"

if [[ $EUID -ne 0 ]]; then
    echo "Please run this as root, for example: sudo $0" >&2
    exit 1
fi

echo "==> Installing build tools"
pacman-key --init >/dev/null 2>&1 || true
pacman -Syu --noconfirm --needed archiso librsvg inter-font noto-fonts nodejs jq

echo "==> Checking FrostOS config files"
LNF="$REPO_DIR/iso/airootfs/usr/share/plasma/look-and-feel"
node --check "$LNF/org.frostos.light/contents/layouts/org.kde.plasma.desktop-layout.js"
while IFS= read -r -d '' json; do
    jq empty "$json" || { echo "ERROR: $json is not valid JSON" >&2; exit 1; }
done < <(find "$REPO_DIR/iso" -name '*.json' -print0)

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

# 4. AUR packages (Brave) go into a local repo that only this build uses.
bash "$REPO_DIR/scripts/build-aur.sh" "$LOCAL_REPO"
cat >> "$PROFILE_DIR/pacman.conf" <<EOF

[frostos-local]
SigLevel = Optional TrustAll
Server = file://$LOCAL_REPO
EOF

# 5. Boot menu: names and background.
{ grep -rlZ 'Arch Linux' "$PROFILE_DIR/syslinux" "$PROFILE_DIR/efiboot" "$PROFILE_DIR/grub" 2>/dev/null || true; } \
    | xargs -0 -r sed -i -e 's/Arch Linux install medium/FrostOS Live/g' -e 's/Arch Linux/FrostOS/g'
if [[ -f "$PROFILE_DIR/syslinux/splash.png" ]]; then
    rsvg-convert -w 640 -h 480 "$REPO_DIR/branding/bootsplash.svg" -o "$PROFILE_DIR/syslinux/splash.png"
fi

# 6. Wallpapers (light + dark; Plasma picks the right one for the color scheme)
#    and theme previews, rendered from the SVG sources in branding/.
WP="$AIROOTFS/usr/share/wallpapers/FrostOS/contents"
mkdir -p "$WP/images" "$WP/images_dark"
for size in 3840x2160 1920x1080; do
    w="${size%x*}"; h="${size#*x}"
    rsvg-convert -w "$w" -h "$h" "$REPO_DIR/branding/wallpaper-light.svg" -o "$WP/images/$size.png"
    rsvg-convert -w "$w" -h "$h" "$REPO_DIR/branding/wallpaper-dark.svg"  -o "$WP/images_dark/$size.png"
done
rsvg-convert -w 400 -h 225 "$REPO_DIR/branding/wallpaper-light.svg" -o "$WP/screenshot.png"
for v in light dark; do
    mkdir -p "$AIROOTFS/usr/share/plasma/look-and-feel/org.frostos.$v/contents/previews"
    rsvg-convert -w 640 -h 360 "$REPO_DIR/branding/wallpaper-$v.svg" \
        -o "$AIROOTFS/usr/share/plasma/look-and-feel/org.frostos.$v/contents/previews/preview.png"
    cp "$AIROOTFS/usr/share/plasma/look-and-feel/org.frostos.$v/contents/previews/preview.png" \
        "$AIROOTFS/usr/share/plasma/look-and-feel/org.frostos.$v/contents/previews/fullscreenpreview.jpg"
done

# 7. The dark global theme shares the light theme's desktop layout and splash screen.
cp -r "$AIROOTFS/usr/share/plasma/look-and-feel/org.frostos.light/contents/layouts" \
      "$AIROOTFS/usr/share/plasma/look-and-feel/org.frostos.light/contents/splash" \
      "$AIROOTFS/usr/share/plasma/look-and-feel/org.frostos.dark/contents/"

# 8. System-wide KDE defaults = FrostOS settings + the Frost Light colors, so the
#    very first login already has FrostOS colors.
cat "$REPO_DIR/iso/config/kdeglobals.in" "$AIROOTFS/usr/share/color-schemes/FrostLight.colors" \
    > "$AIROOTFS/etc/xdg/kdeglobals"

# 9. Services. The Arch ISO uses systemd-networkd + iwd and logs root in on a
#    text screen; FrostOS uses NetworkManager and the SDDM login manager instead.
SYSD="$AIROOTFS/etc/systemd/system"
echo "Removing from releng:"
find "$SYSD" ! -type d \( -name 'systemd-networkd*' -o -name 'iwd.service' \) -print -delete
rm -fv "$SYSD/getty@tty1.service.d/autologin.conf"
enable_unit() { # <folder inside /etc/systemd/system> <link name> <unit in /usr/lib/systemd/system or /etc/systemd/system>
    mkdir -p "$SYSD/$1"
    ln -sfn "$3" "$SYSD/$1/$2"
}
enable_unit . display-manager.service /usr/lib/systemd/system/sddm.service
enable_unit multi-user.target.wants NetworkManager.service /usr/lib/systemd/system/NetworkManager.service
enable_unit . dbus-org.freedesktop.nm-dispatcher.service /usr/lib/systemd/system/NetworkManager-dispatcher.service
enable_unit bluetooth.target.wants bluetooth.service /usr/lib/systemd/system/bluetooth.service
enable_unit . dbus-org.bluez.service /usr/lib/systemd/system/bluetooth.service
enable_unit graphical.target.wants power-profiles-daemon.service /usr/lib/systemd/system/power-profiles-daemon.service
enable_unit multi-user.target.wants frostos-flathub.service /etc/systemd/system/frostos-flathub.service

# 10. Flathub (the main Flatpak app store): download its official repo file.
curl -fsSL --retry 3 -o "$AIROOTFS/usr/share/frostos/flathub.flatpakrepo" \
    https://dl.flathub.org/repo/flathub.flatpakrepo
grep -q '^GPGKey=' "$AIROOTFS/usr/share/frostos/flathub.flatpakrepo"

# 11. Previews of the artwork, uploaded next to the ISO so they can be checked
#     without booting.
mkdir -p "$OUT_DIR/previews"
cp "$WP/images/1920x1080.png" "$OUT_DIR/previews/wallpaper-light.png"
cp "$WP/images_dark/1920x1080.png" "$OUT_DIR/previews/wallpaper-dark.png"
[[ -f "$PROFILE_DIR/syslinux/splash.png" ]] && cp "$PROFILE_DIR/syslinux/splash.png" "$OUT_DIR/previews/bootmenu.png"
for icon in frostos-logo frostos frostos-launchpad; do
    rsvg-convert -w 256 -h 256 "$AIROOTFS/usr/share/icons/hicolor/scalable/apps/$icon.svg" -o "$OUT_DIR/previews/$icon.png"
done

echo "==> Building the ISO (this takes a while)"
mkarchiso -v -w "$WORK_DIR/build" -o "$OUT_DIR" "$PROFILE_DIR"

# 12. Make sure the FrostOS branding hook ran while the packages were installed.
ROOTFS="$WORK_DIR/build/x86_64/airootfs"
if [[ -d "$ROOTFS" ]]; then
    grep -q '^NAME="FrostOS"' "$ROOTFS/usr/lib/os-release" \
        && echo "::notice title=Branding::os-release says FrostOS" \
        || echo "::warning title=Branding::os-release was not changed to FrostOS"
    for app in org.kde.dolphin org.kde.konsole systemsettings org.kde.discover; do
        [[ -f "$ROOTFS/usr/local/share/applications/$app.desktop" ]] \
            || echo "::warning title=Branding::$app was not renamed"
    done
fi

echo "==> Done! The ISO is in $OUT_DIR"
ls -lh "$OUT_DIR"
