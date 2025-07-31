#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
WORKDIR=$(mktemp -d -t bs-otel-deb.XXXXXXXX)
PKGROOT="$WORKDIR/pkg"

mkdir -p "$PKGROOT" "$POOL_DIR/betterstack-otel"

cp -r "$SOURCEDIR/DEBIAN" "$PKGROOT/DEBIAN"
cp -r "$SOURCEDIR/usr"    "$PKGROOT/usr"

mkdir -p "$PKGROOT/usr/lib/systemd/system"
cp "$SOURCEDIR/usr/lib/systemd/system/otelcol-contrib.service" "$PKGROOT/usr/lib/systemd/system/"

simconf toml-to-template "$SOURCEDIR/templates.toml" "$PKGROOT/DEBIAN/templates"

release_json=$(gh release view --repo open-telemetry/opentelemetry-collector-contrib --json tagName)
tag=$(echo "$release_json" | jq -r '.tagName')
collector_ver="${tag#v}"
version="${collector_ver}-1"

sed "s/VERSION_REPLACEME/$version/" "$SOURCEDIR/DEBIAN/control" > "$PKGROOT/DEBIAN/control"

build_arch=$(dpkg --print-architecture)
case "$build_arch" in
  amd64)   gh_arch=amd64  ;;
  arm64)   gh_arch=arm64  ;;
  *) echo "Unsupported build arch $build_arch" >&2; exit 1 ;;
esac

tarball_name="otelcol-contrib_${collector_ver}_linux_${gh_arch}.tar.gz"
echo "[mkdeb] Downloading ${tarball_name} …"
curl -fsSL \
  "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${collector_ver}/${tarball_name}" \
  -o "$WORKDIR/${tarball_name}"

mkdir -p "$PKGROOT/usr/share/betterstack-otel"
cp "$WORKDIR/${tarball_name}" "$PKGROOT/usr/share/betterstack-otel/"

mkdir -p "$PKGROOT/usr/bin"
ln -s "/opt/otelcol-${collector_ver}/otelcol-contrib" "$PKGROOT/usr/bin/otelcol-contrib"

pkg_path="$POOL_DIR/betterstack-otel/betterstack-otel_${version}_all.deb"
echo "[mkdeb] Building $pkg_path …"
dpkg-deb --build --root-owner-group "$PKGROOT" "$pkg_path"
echo "[mkdeb] Done: $pkg_path"
