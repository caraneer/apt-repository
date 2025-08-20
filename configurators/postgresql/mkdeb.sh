#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
WORKDIR="$(mktemp -d -t postgresql-deb.XXXXXXXXXX)"
echo "WORKDIR=$WORKDIR";
PKGROOT="$WORKDIR/pkg"
version="0.1.8-1"

echo "Preparing package directory..."
mkdir -p "$PKGROOT";

# Copy package files
cp -r "$SOURCEDIR/DEBIAN" "$PKGROOT/DEBIAN"
mkdir -p "$PKGROOT/usr/share/caraneer-config-postgresql";
cp -r "$SOURCEDIR/simconf-templates" "$PKGROOT/usr/share/caraneer-config-postgresql/templates"
cp -r "$SOURCEDIR/bin" "$PKGROOT/usr/bin"
mkdir -p "$PKGROOT/usr/lib/systemd";
cp -r "$SOURCEDIR/systemd" "$PKGROOT/usr/lib/systemd/system"
simconf toml-to-template "$SOURCEDIR/templates.toml" "$PKGROOT/DEBIAN/templates"

sed "s/VERSION_REPLACEME/$version/" "$SOURCEDIR/DEBIAN/control" > "$PKGROOT/DEBIAN/control"

echo "Building package..."
mkdir -p "${POOL_DIR}/caraneer-config-postgresql"
dpkg-deb --build --root-owner-group "$PKGROOT" "${POOL_DIR}/caraneer-config-postgresql/caraneer-config-postgresql_${version}_all.deb"
echo "Done: ${POOL_DIR}/caraneer-config-postgresql/caraneer-config-postgresql_${version}_all.deb"
