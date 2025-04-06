#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
WORKDIR="/tmp/monerod-deb"
PKGROOT="$WORKDIR/pkg"

# Grab the latest tarball name and version
TARBALL_NAME=$(curl -s https://www.getmonero.org/downloads/hashes.txt | grep -oP 'monero-linux-x64-v[\d.]+' | head -n1)tar.bz2
VERSION="$(echo "$TARBALL_NAME" | grep -oP 'v\K[0-9]+(\.[0-9]+)*')-1"
TARBALL_URL="https://downloads.getmonero.org/cli/$TARBALL_NAME"
EXTRACT_DIR="$WORKDIR/monero-src"

echo "Downloading: $TARBALL_URL"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
curl -LO "$TARBALL_URL"

echo "Extracting: $TARBALL_NAME"
mkdir -p "$EXTRACT_DIR"
tar -xjf "$TARBALL_NAME" -C "$EXTRACT_DIR" --strip-components=1

echo "Preparing package directory..."
rm -rf "$PKGROOT"
mkdir -p "$PKGROOT/DEBIAN"
mkdir -p "$PKGROOT/usr/bin"
mkdir -p "$PKGROOT/lib/systemd/system"

# Copy all monero* executables to /usr/bin
for bin in "$EXTRACT_DIR"/monero*; do
    if [[ -x "$bin" && -f "$bin" ]]; then
        cp "$bin" "$PKGROOT/usr/bin/"
        chmod 0755 "$PKGROOT/usr/bin/$(basename "$bin")"
    fi
done

# Copy control and service files
sed "s/VERSION_REPLACEME/$VERSION/" "$SOURCEDIR/DEBIAN/control" > "$PKGROOT/DEBIAN/control"
cp "$SOURCEDIR/DEBIAN/postinst" "$PKGROOT/DEBIAN/postinst"
chmod 0755 "$PKGROOT/DEBIAN/postinst"
cp "$SOURCEDIR/lib/systemd/system/monerod.service" "$PKGROOT/lib/systemd/system/monerod.service"

echo "Building package..."
pool_dir="${WEBROOT_DIR}/pool/${PKG_DISTRO}/third-party/monero";
mkdir -p "${pool_dir}"
dpkg-deb --build "$PKGROOT" "${pool_dir}/monero_${VERSION}_amd64.deb"
echo "Done: monero_${VERSION}_amd64.deb"
