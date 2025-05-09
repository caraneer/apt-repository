#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
WORKDIR="$(mktemp -d -t nginx-deb.XXXXXXXXXX)"
echo "WORKDIR=$WORKDIR";
PKGROOT="$WORKDIR/pkg"
version="0.1.1-1"

echo "Preparing package directory..."
mkdir -p "$PKGROOT";

# Copy package files
cp -r "$SOURCEDIR/DEBIAN" "$PKGROOT/DEBIAN"
mkdir -p "$PKGROOT/usr/share/caraneer-config-nginx";
cp -r "$SOURCEDIR/simconf-templates" "$PKGROOT/usr/share/caraneer-config-nginx/templates"
simconf toml-to-template "$SOURCEDIR/templates.toml" "$PKGROOT/DEBIAN/templates"

sed "s/VERSION_REPLACEME/$version/" "$SOURCEDIR/DEBIAN/control" > "$PKGROOT/DEBIAN/control"

echo "Building package..."
mkdir -p "${POOL_DIR}/caraneer-config-nginx"
dpkg-deb --build "$PKGROOT" "${POOL_DIR}/caraneer-config-nginx/caraneer-config-nginx_${version}_all.deb"
echo "Done: ${POOL_DIR}/caraneer-config-nginx/caraneer-config-nginx_${version}_all.deb"
