#!/usr/bin/env bash
# Tests FrostDE without a real screen and takes screenshots.
#
#   1. Checks FrostDE's Hyprland config with Hyprland itself.
#   2. Starts the FrostDE shell and Frost Settings on an invisible screen (the
#      "sway" compositor in headless mode) and saves screenshots of the menu
#      bar, Dock, Launchpad, Spotlight, Control Center, a notification, dark
#      mode and Frost Settings.
#   3. Collects QML / Python errors.
#
# Runs as root in an Arch Linux container (GitHub Actions). Screenshots and logs
# go to $OUT_DIR/screenshots.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT_DIR:-$REPO_DIR/out}/screenshots"
FROSTDE="$REPO_DIR/frostde"
mkdir -p "$OUT"
chmod 777 "$OUT"

echo "==> Installing test tools"
pacman-key --init >/dev/null 2>&1 || true
pacman -Syu --noconfirm --needed \
    hyprland lua quickshell qt6-wayland qt6-svg qt6-imageformats sway grim wtype \
    python python-gobject gtk4 libadwaita adwaita-icon-theme \
    inter-font noto-fonts ttf-jetbrains-mono ttf-nerd-fonts-symbols \
    libnotify dbus librsvg mesa glib2 dconf >/dev/null

echo "==> Rebuilding quickshell against the current Qt"
bash "$REPO_DIR/scripts/build-aur.sh" /tmp/localrepo arch/quickshell
pacman -U --noconfirm /tmp/localrepo/quickshell-[0-9]*.pkg.tar.zst

# Arch gives sway a file capability that unprivileged containers refuse to run.
setcap -r /usr/bin/sway 2>/dev/null || true

echo "==> Installing FrostDE into the test container"
install -d /usr/share/frostde /usr/share/backgrounds/frostos /usr/share/applications
cp -r "$FROSTDE/shell" "$FROSTDE/gtk" /usr/share/frostde/
cp "$FROSTDE/hypr/hyprland.lua" "$FROSTDE/hypr/hyprlock.conf" "$FROSTDE/settings.json" /usr/share/frostde/
install -m 755 "$FROSTDE"/bin/* "$FROSTDE/settings/frost-settings" /usr/local/bin/
cp "$FROSTDE/applications/org.frostos.Settings.desktop" /usr/share/applications/
cp -r "$REPO_DIR/iso/airootfs/usr/share/icons/hicolor/scalable/apps/." /usr/share/icons/hicolor/scalable/apps/
rsvg-convert -w 1440 -h 900 "$REPO_DIR/branding/wallpaper-light.svg" -o /usr/share/backgrounds/frostos/frost-light.png
rsvg-convert -w 1440 -h 900 "$REPO_DIR/branding/wallpaper-dark.svg"  -o /usr/share/backgrounds/frostos/frost-dark.png

id tester >/dev/null 2>&1 || useradd -m tester
TH=/home/tester
install -d -o tester "$TH/.config/frostde" "$TH/.config/hypr" "$TH/.config/gtk-4.0"
install -o tester "$FROSTDE/settings.json" "$TH/.config/frostde/settings.json"
install -o tester "$FROSTDE/gtk/gtk4.css" "$TH/.config/gtk-4.0/gtk.css"
echo 'dofile("/usr/share/frostde/hyprland.lua")' > "$TH/.config/hypr/hyprland.lua"
chown -R tester: "$TH/.config"
install -d -o tester -m 700 /tmp/runtime-tester

failed=0

echo "==> 1. Checking the Hyprland config"
luac -p "$FROSTDE/hypr/hyprland.lua"
if verify="$(runuser -u tester -- env XDG_RUNTIME_DIR=/tmp/runtime-tester HOME="$TH" \
        Hyprland --verify-config -c "$TH/.config/hypr/hyprland.lua" 2>&1)"; then
    echo "::notice title=Hyprland config::$(Hyprland --version | head -n 1): config OK"
else
    echo "$verify" | tail -n 60
    echo "::error title=Hyprland config::$(echo "$verify" | grep -iE 'error|invalid|unknown|expected|fail' | head -n 15 | tr '\n' '|' | cut -c1-3000)"
    failed=1
fi
echo "$verify" > "$OUT/hyprland-verify.log"

echo "==> 2. Running the FrostDE shell on a headless screen"
cat > /tmp/sway.conf <<'EOF'
output HEADLESS-1 resolution 1440x900 scale 1
default_border none
default_floating_border none
for_window [app_id=".*"] floating enable, resize set 900 600, move position center
seat * hide_cursor 1
EOF

cat > /tmp/inner.sh <<'EOF'
set -u
OUT="$1"
SHELL_DIR=/usr/share/frostde/shell
export XDG_RUNTIME_DIR=/tmp/runtime-tester
export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 WLR_HEADLESS_OUTPUTS=1
export LIBGL_ALWAYS_SOFTWARE=1
sway -c /tmp/sway.conf >"$OUT/sway.log" 2>&1 &
for _ in $(seq 1 50); do
    sock="$(ls "$XDG_RUNTIME_DIR" 2>/dev/null | grep -E '^wayland-[0-9]+$' | head -n 1)"
    [ -n "$sock" ] && break
    sleep 0.2
done
export WAYLAND_DISPLAY="$sock"
unset WLR_BACKENDS WLR_RENDERER WLR_HEADLESS_OUTPUTS
export QT_QPA_PLATFORM=wayland QS_ICON_THEME=Adwaita GSK_RENDERER=cairo
echo "Wayland display: $WAYLAND_DISPLAY"

start_shell() {
    qs -p "$SHELL_DIR" >"$OUT/quickshell.log" 2>&1 &
    QS_PID=$!
    sleep 7
}
start_shell
if ! kill -0 "$QS_PID" 2>/dev/null; then
    echo "Quickshell stopped; trying again with Qt's software renderer"
    mv "$OUT/quickshell.log" "$OUT/quickshell-gl.log"
    export QT_QUICK_BACKEND=software
    start_shell
fi

ipc() {
    qs ipc -p "$SHELL_DIR" call frostde "$1" >/dev/null 2>&1 \
        || qs -p "$SHELL_DIR" ipc call frostde "$1" >/dev/null 2>&1 \
        || echo "ipc call $1 failed" >>"$OUT/test-errors.log"
}
shot() { grim "$OUT/$1.png"; }

shot 01-desktop-light
notify-send --app-name=FrostOS --icon=frostos "Welcome to FrostOS" "This is what a notification looks like."
sleep 1.5; shot 02-notification
ipc controlCenter; sleep 1.2; shot 03-control-center; ipc controlCenter; sleep 0.5
ipc launchpad;     sleep 1.5; shot 04-launchpad;      ipc launchpad;     sleep 0.5
ipc spotlight;     sleep 1;   wtype "set" 2>/dev/null; sleep 1; shot 05-spotlight; ipc spotlight; sleep 0.5
ipc notifications; sleep 1.2; shot 06-notification-center; ipc notifications; sleep 0.5

frost-settings --page appearance >"$OUT/frost-settings.log" 2>&1 &
sleep 5; shot 07-settings-light

sed -i 's/"appearance": "light"/"appearance": "dark"/' "$HOME/.config/frostde/settings.json"
sleep 2.5; shot 08-dark-mode
frost-settings --page about >>"$OUT/frost-settings.log" 2>&1
sleep 3; shot 09-settings-about

qs ipc -p "$SHELL_DIR" show >"$OUT/ipc-targets.txt" 2>&1 || true
kill "$QS_PID" 2>/dev/null
pkill -f frost-settings 2>/dev/null
swaymsg exit >/dev/null 2>&1
exit 0
EOF

runuser -u tester -- env HOME="$TH" dbus-run-session -- bash /tmp/inner.sh "$OUT" || failed=1

echo "==> 3. Looking for errors"
if [[ ! -s "$OUT/01-desktop-light.png" ]]; then
    echo "::error title=Screenshots::No screenshot was taken. See sway.log."
    failed=1
fi
qs_errors="$(grep -hiE 'error|warn|ReferenceError|TypeError|is not a type|not defined|failed|Cannot' \
              "$OUT"/quickshell*.log 2>/dev/null | grep -v 'Qt Quick Layouts' | head -n 40 || true)"
if [[ -n "$qs_errors" ]]; then
    echo "$qs_errors"
    echo "::warning title=FrostDE shell messages::$(echo "$qs_errors" | head -n 20 | tr '\n' '|' | cut -c1-3500)"
fi
if grep -qiE 'failed to load|Configuration Loaded.*fail|could not load' "$OUT"/quickshell.log 2>/dev/null; then
    echo "::error title=FrostDE shell::The shell did not load. See quickshell.log in the screenshots artifact."
    failed=1
fi
if grep -q 'Traceback' "$OUT/frost-settings.log" 2>/dev/null; then
    echo "::error title=Frost Settings::$(grep -A12 Traceback "$OUT/frost-settings.log" | tr '\n' '|' | cut -c1-3000)"
    failed=1
fi
ls -l "$OUT"
exit $failed
