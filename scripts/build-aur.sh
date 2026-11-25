#!/usr/bin/env bash
# Builds the AUR packages listed in iso/aur-packages.txt and puts them in a small
# local package repository ("frostos-local") that the ISO build installs from.
#
# Called by scripts/build-iso.sh. Must run as root on Arch Linux.
# Usage: build-aur.sh <output folder>
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_REPO="${1:?usage: build-aur.sh <output folder>}"
BUILD_USER="aurbuild"
BUILD_DIR="/home/$BUILD_USER/build"

echo "==> Installing AUR build tools"
pacman -S --noconfirm --needed base-devel git

# makepkg refuses to run as root, so builds run as a normal user that may only
# use sudo for pacman (to install build dependencies).
id "$BUILD_USER" >/dev/null 2>&1 || useradd -m "$BUILD_USER"
echo "$BUILD_USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" > "/etc/sudoers.d/$BUILD_USER"
chmod 440 "/etc/sudoers.d/$BUILD_USER"

mkdir -p "$LOCAL_REPO" "$BUILD_DIR"
chown "$BUILD_USER:" "$LOCAL_REPO" "$BUILD_DIR"

mapfile -t packages < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$REPO_DIR/iso/aur-packages.txt")

for pkg in "${packages[@]}"; do
    echo "==> Building $pkg from the AUR"
    rm -rf "${BUILD_DIR:?}/$pkg"
    sudo -u "$BUILD_USER" git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$BUILD_DIR/$pkg"
    if [[ ! -f "$BUILD_DIR/$pkg/PKGBUILD" ]]; then
        echo "ERROR: '$pkg' was not found in the AUR." >&2
        exit 1
    fi
    (
        cd "$BUILD_DIR/$pkg"
        sudo -u "$BUILD_USER" env PKGDEST="$LOCAL_REPO" makepkg --syncdeps --noconfirm --clean
    )
done

echo "==> Creating the frostos-local package repository"
repo-add "$LOCAL_REPO/frostos-local.db.tar.gz" "$LOCAL_REPO"/*.pkg.tar.zst
ls -lh "$LOCAL_REPO"
