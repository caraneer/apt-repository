#!/bin/bash
set -euo pipefail

WORKDIR="$(mktemp -d -t ojs-deb.XXXXXXXXXX)"
PKGROOT="$WORKDIR/pkg"
EXTRACT_DIR="$WORKDIR/ojs-src"

# Get latest OJS tarball
TARBALL_URL=$(curl -s https://pkp.sfu.ca/software/ojs/download/archive/ | grep -Eo 'https://pkp\.sfu\.ca/ojs/download/ojs-[0-9.]+\.tar\.gz' | head -n1)
TARBALL_NAME="${TARBALL_URL##*/}"
VERSION="$(echo "$TARBALL_NAME" | grep -oP '[0-9]+(\.[0-9]+)*')-1"

echo "Downloading: $TARBALL_URL"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
curl -LO "$TARBALL_URL"

echo "Extracting: $TARBALL_NAME"
mkdir -p "$EXTRACT_DIR"
tar -xzf "$TARBALL_NAME" -C "$EXTRACT_DIR" --strip-components=1

echo "Preparing package directory..."
rm -rf "$PKGROOT"
mkdir -p "$PKGROOT/DEBIAN"
mkdir -p "$PKGROOT/usr/share/ojs/php"
mkdir -p "$PKGROOT/usr/share/ojs/templates"
mkdir -p "$PKGROOT/etc/nginx/conf.d"
mkdir -p "$PKGROOT/var/lib/ojs"
mkdir -p "$PKGROOT/var/cache/ojs"
mkdir -p "$PKGROOT/etc/ojs"

# Copy PHP source
cp -r "$EXTRACT_DIR"/* "$PKGROOT/usr/share/ojs/php/"

# Copy package files
cp control "$PKGROOT/DEBIAN/control"
cp templates "$PKGROOT/DEBIAN/templates"
cp postinst "$PKGROOT/DEBIAN/postinst"
chmod 755 "$PKGROOT/DEBIAN/postinst"
cp nginx_service.conf.tera "$PKGROOT/usr/share/ojs/templates/nginx_service.conf.tera"
cp config.inc.php.tera "$PKGROOT/usr/share/ojs/templates/config.inc.php.tera"

echo "Building package..."
mkdir -p "${POOL_DIR}/ojs"
dpkg-deb --build --root-owner-group "$PKGROOT" "${POOL_DIR}/ojs/ojs_${VERSION}_all.deb"
echo "Done: ${POOL_DIR}/ojs/ojs_${VERSION}_all.deb"
