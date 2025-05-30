#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
WORKDIR="$(mktemp -d -t redis-config-deb.XXXXXXXXXX)"
echo "WORKDIR=$WORKDIR";
PKGROOT="$WORKDIR/pkg"
VERSION="0.1.0-1"

echo "Preparing package directory..."
mkdir -p "$PKGROOT";

cp -r "$SOURCEDIR/DEBIAN" "$PKGROOT/DEBIAN"
sed -i "s/VERSION_REPLACEME/$VERSION/" "$PKGROOT/DEBIAN/control"

mkdir -p "$PKGROOT/usr/share/caraneer-config-redis/templates"
install -m 0644 "$SOURCEDIR/simconf-templates/redis.conf.tera" \
                "$PKGROOT/usr/share/caraneer-config-redis/templates/"
install -m 0644 "$SOURCEDIR/simconf-templates/99-caraneer-redis-overcommit.conf.tera" \
                "$PKGROOT/usr/share/caraneer-config-redis/templates/"
install -m 0644 "$SOURCEDIR/simconf-templates/manage_thp.sh.tera" \
                "$PKGROOT/usr/share/caraneer-config-redis/templates/"

mkdir -p "$PKGROOT/usr/share/caraneer-config-redis/systemd"
install -m 0644 "$SOURCEDIR/usr/lib/systemd/system/disable-thp.service" \
                "$PKGROOT/usr/share/caraneer-config-redis/systemd/"


simconf toml-to-template "$SOURCEDIR/templates.toml" "$PKGROOT/DEBIAN/templates"

echo "Building package..."
mkdir -p "${POOL_DIR}/caraneer-config-redis"
dpkg-deb --build --root-owner-group "$PKGROOT" "${POOL_DIR}/caraneer-config-redis/caraneer-config-redis_${VERSION}_all.deb"
echo "Done: ${POOL_DIR}/caraneer-config-redis/caraneer-config-redis_${VERSION}_all.deb"