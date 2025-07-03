#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
WORKDIR="$(mktemp -d -t vector-deb.XXXXXXXXXX)"
echo "WORKDIR=$WORKDIR";
PKGROOT="$WORKDIR/pkg"
version="0.1.1-1"

echo "Preparing package directory..."
mkdir -p "$PKGROOT/DEBIAN";

# Copy maintainer scripts
install -m 0755 "$SOURCEDIR/DEBIAN/postinst" "$PKGROOT/DEBIAN/postinst"
install -m 0755 "$SOURCEDIR/DEBIAN/postrm" "$PKGROOT/DEBIAN/postrm"
install -m 0755 "$SOURCEDIR/DEBIAN/config" "$PKGROOT/DEBIAN/config"

# Copy package content
mkdir -p "$PKGROOT/usr/share/caraneer-config-vector/templates"
cp "$SOURCEDIR/simconf-templates/vector.yaml.tera" "$PKGROOT/usr/share/caraneer-config-vector/templates/"

# Generate debconf templates and control file
simconf toml-to-template "$SOURCEDIR/templates.toml" "$PKGROOT/DEBIAN/templates"
sed "s/VERSION_REPLACEME/$version/" "$SOURCEDIR/DEBIAN/control" > "$PKGROOT/DEBIAN/control"

echo "Building package..."
mkdir -p "${POOL_DIR}/caraneer-config-vector"
dpkg-deb --build --root-owner-group "$PKGROOT" "${POOL_DIR}/caraneer-config-vector/caraneer-config-vector_${version}_all.deb"
echo "Done: ${POOL_DIR}/caraneer-config-vector/caraneer-config-vector_${version}_all.deb"