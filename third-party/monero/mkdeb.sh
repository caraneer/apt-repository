#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
WORKDIR="$(mktemp -d -t monero-deb.XXXXXXXXXX)"
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
cp "$SOURCEDIR/DEBIAN/templates" "$PKGROOT/DEBIAN/templates"
chmod 0755 "$PKGROOT/DEBIAN/postinst"
cp -R "$SOURCEDIR/lib" "$PKGROOT/lib"
cp -R "$SOURCEDIR/usr/share" "$PKGROOT/usr/share"

echo "Building package..."
mkdir -p "${POOL_DIR}/monero"
dpkg-deb --build "$PKGROOT" "${POOL_DIR}/monero/monero_${VERSION}_amd64.deb"
echo "Done: ${POOL_DIR}/monero/monero_${VERSION}_amd64.deb"
