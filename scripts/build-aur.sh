#!/usr/bin/env bash
# Builds extra packages for the ISO and puts them in a small local package
# repository ("frostos-local") that the ISO build installs from.
#
# Two kinds of entries (see iso/aur-packages.txt):
#   name          a package from the AUR (aur.archlinux.org)
#   arch/name     an official Arch package, rebuilt from Arch's own recipe.
#                 Used for quickshell, which must be built against the exact
#                 Qt version in the ISO or it can crash.
#
# Called by scripts/build-iso.sh and scripts/test-frostde.sh. Must run as root on Arch Linux.
# Usage: build-aur.sh <output folder> [package ...]
#        (without packages, the list in iso/aur-packages.txt is used)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_REPO="${1:?usage: build-aur.sh <output folder> [package ...]}"
shift
BUILD_USER="aurbuild"
BUILD_DIR="/home/$BUILD_USER/build"

echo "==> Installing package build tools"
pacman -S --noconfirm --needed base-devel git

# makepkg refuses to run as root, so builds run as a normal user that may only
# use sudo for pacman (to install build dependencies).
id "$BUILD_USER" >/dev/null 2>&1 || useradd -m "$BUILD_USER"
echo "$BUILD_USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" > "/etc/sudoers.d/$BUILD_USER"
chmod 440 "/etc/sudoers.d/$BUILD_USER"

mkdir -p "$LOCAL_REPO" "$BUILD_DIR"
chown "$BUILD_USER:" "$LOCAL_REPO" "$BUILD_DIR"

if (( $# > 0 )); then
    packages=("$@")
else
    mapfile -t packages < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$REPO_DIR/iso/aur-packages.txt")
fi

for entry in "${packages[@]}"; do
    if [[ "$entry" == arch/* ]]; then
        pkg="${entry#arch/}"
        url="https://gitlab.archlinux.org/archlinux/packaging/packages/$pkg.git"
        echo "==> Rebuilding $pkg from Arch's recipe"
    else
        pkg="$entry"
        url="https://aur.archlinux.org/$pkg.git"
        echo "==> Building $pkg from the AUR"
    fi
    rm -rf "${BUILD_DIR:?}/$pkg"
    sudo -u "$BUILD_USER" git clone --depth 1 "$url" "$BUILD_DIR/$pkg"
    if [[ ! -f "$BUILD_DIR/$pkg/PKGBUILD" ]]; then
        echo "ERROR: '$entry' was not found." >&2
        exit 1
    fi
    if [[ "$entry" == arch/* ]]; then
        # A slightly higher release number (e.g. 1 -> 1.1), so pacman never
        # swaps our rebuild for Arch's copy of the same version.
        sed -i -E 's/^pkgrel=([0-9]+)$/pkgrel=\1.1/' "$BUILD_DIR/$pkg/PKGBUILD"
    fi
    (
        cd "$BUILD_DIR/$pkg"
        sudo -u "$BUILD_USER" env PKGDEST="$LOCAL_REPO" makepkg --syncdeps --noconfirm --clean --nocheck
    )
done

echo "==> Creating the frostos-local package repository"
repo-add "$LOCAL_REPO/frostos-local.db.tar.gz" "$LOCAL_REPO"/*.pkg.tar.zst
ls -lh "$LOCAL_REPO"
