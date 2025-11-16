#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
WORKDIR="$(mktemp -d -t acmetool-deb.XXXXXXXXXX)"
echo "WORKDIR=$WORKDIR";
PKGROOT="$WORKDIR/pkg"
version="0.2.4-1"

echo "Preparing package directory..."
mkdir -p "$PKGROOT";

# Copy package files
cp -r "$SOURCEDIR/DEBIAN" "$PKGROOT/DEBIAN"
mkdir -p "$PKGROOT/usr/share/caraneer-config-acmetool";
cp -r "$SOURCEDIR/simconf-templates" "$PKGROOT/usr/share/caraneer-config-acmetool/templates"
cp -r "$SOURCEDIR/hooks" "$PKGROOT/usr/share/caraneer-config-acmetool/hooks"
simconf toml-to-template "$SOURCEDIR/templates.toml" "$PKGROOT/DEBIAN/templates"

sed "s/VERSION_REPLACEME/$version/" "$SOURCEDIR/DEBIAN/control" > "$PKGROOT/DEBIAN/control"

echo "Building package..."
mkdir -p "${POOL_DIR}/caraneer-config-acmetool"
dpkg-deb --build "$PKGROOT" "${POOL_DIR}/caraneer-config-acmetool/caraneer-config-acmetool_${version}_all.deb"
echo "Done: ${POOL_DIR}/caraneer-config-acmetool/caraneer-config-acmetool_${version}_all.deb"
