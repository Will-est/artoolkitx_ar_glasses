#!/bin/bash

# Install ARToolKitX AR Glasses dependencies (Debian/Ubuntu/Fedora/RHEL)
# set -euo pipefail

debian_packages=(
    build-essential
    artoolkitx-lib
    artoolkitx-dev
    artoolkitx-examples
    autoconf
    automake
    libtool
    pkg-config
    freeglut3-dev
    libv4l-dev
    libopencv-dev
    libudev-dev
    libglib2.0-dev
    zlib1g-dev
)

rpm_packages=(
    gcc
    gcc-c++
    make
    cmake
    libjpeg-turbo-devel
    mesa-libGL-devel
    mesa-libGLU-devel
    SDL2-devel
    systemd-devel
    libv4l-devel
    libdc1394-devel
    gstreamer1-devel
    libsqlite3x-devel
    libcurl-devel
    openssl-devel
)

# Detect package manager
if type dpkg-query >/dev/null 2>&1; then
    PKG_MGR="apt"
    packages=("${debian_packages[@]}")
elif type rpm >/dev/null 2>&1; then
    PKG_MGR="dnf"
    packages=("${rpm_packages[@]}")
    # Fallback to yum if dnf not available
    if ! command -v dnf >/dev/null 2>&1 && command -v yum >/dev/null 2>&1; then
        PKG_MGR="yum"
    fi
else
    echo "Error: Unsupported system. Requires Debian/Ubuntu or Fedora/RHEL." >&2
    exit 1
fi

# Use sudo if not root
SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "Error: run as root or install sudo." >&2
        exit 1
    fi
fi

# Determine missing packages
missing=()
if [ "$PKG_MGR" = "apt" ]; then
    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
else
    for pkg in "${packages[@]}"; do
        rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
fi

if [ "${#missing[@]}" -eq 0 ]; then
    echo "All dependencies are already installed."
    exit 0
fi

# Install missing packages
if [ "$PKG_MGR" = "apt" ]; then
    [ "${SKIP_APT_UPDATE:-0}" -ne 1 ] && $SUDO apt-get update
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends "${missing[@]}"
else
    $SUDO "$PKG_MGR" install -y "${missing[@]}"
fi

echo "Installed ${#missing[@]} package(s): ${missing[*]}"
