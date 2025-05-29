#!/bin/bash
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
WORKDIR=$(mktemp -d -t nebula-deb.XXXXXXXXXX)
PKGROOT="$WORKDIR/pkg"
ARCHIVE="$WORKDIR/nebula.tar.gz"

echo "[nebula] discovering latest release via gh"
release_json=$(gh release view --repo slackhq/nebula --json tagName,assets)
tag=$(jq -r '.tagName' <<<"$release_json")
version="${tag#v}"
if [[ "${version}" = "1.9.5" ]]; then
    version="${version}-15"
else
    version="${version}-1"
fi;
asset_url=$(echo "$release_json" | jq -r '.assets[] | select(.name=="nebula-linux-amd64.tar.gz") | .url')

[[ -z "$asset_url" ]] && { echo "Cannot find amd64 asset in latest release"; exit 1; }

echo "[nebula] downloading $tag → $asset_url"
gh api "$asset_url" > "$ARCHIVE"

echo "[nebula] extracting"
mkdir -p "$WORKDIR/nebula-extract"
tar -xzf "$ARCHIVE" -C "$WORKDIR/nebula-extract"

echo "[nebula] staging package tree"
mkdir -p "$PKGROOT/DEBIAN" \
         "$PKGROOT/usr/bin" \
         "$PKGROOT/usr/share/nebula/examples" \
         "$PKGROOT/usr/share/nebula/templates" \
         "$PKGROOT/usr/lib/systemd/system"

# ─── binaries ───────────────────────────────────────────────────────────────
install -m 0755 "$WORKDIR/nebula-extract/nebula"      "$PKGROOT/usr/bin/"
install -m 0755 "$WORKDIR/nebula-extract/nebula-cert" "$PKGROOT/usr/bin/"

# ─── control file ───────────────────────────────────────────────────────────
sed "s/VERSION_REPLACEME/${version}/" \
    "$SOURCEDIR/DEBIAN/control" > "$PKGROOT/DEBIAN/control"

# ─── simconf templates ──────────────────────────────────────────────────────
simconf toml-to-template "$SOURCEDIR/templates.toml" \
                          "$PKGROOT/DEBIAN/templates"
install -m 0644 "$SOURCEDIR/usr/share/nebula/templates/config.yml.tera" \
                "$PKGROOT/usr/share/nebula/templates/"
install -m 0644 "$SOURCEDIR/usr/share/nebula/templates/ca.crt.tera" \
                "$PKGROOT/usr/share/nebula/templates/"
install -m 0644 "$SOURCEDIR/usr/share/nebula/templates/host.crt.tera" \
                "$PKGROOT/usr/share/nebula/templates/"
install -m 0644 "$SOURCEDIR/usr/share/nebula/templates/host.key.tera" \
                "$PKGROOT/usr/share/nebula/templates/"
install -m 0644 "$SOURCEDIR/usr/share/nebula/templates/nebula-dns.sh.tera" \
                "$PKGROOT/usr/share/nebula/templates/"

# ─── maintainer scripts ─────────────────────────────────────────────────────
install -m 0755 "$SOURCEDIR/DEBIAN/postinst" "$PKGROOT/DEBIAN/postinst"
install -m 0755 "$SOURCEDIR/DEBIAN/postrm"   "$PKGROOT/DEBIAN/postrm"
install -m 0755 "$SOURCEDIR/DEBIAN/config"   "$PKGROOT/DEBIAN/config"

# ─── service + sample config ────────────────────────────────────────────────
install -m 0644 "$SOURCEDIR/usr/lib/systemd/system/nebula.service" \
                "$PKGROOT/usr/lib/systemd/system/"
install -m 0644 "$SOURCEDIR/usr/lib/systemd/system/nebula-dns.service" \
                "$PKGROOT/usr/lib/systemd/system/"
install -m 0644 "$SOURCEDIR/usr/share/nebula/examples/config.yml" \
                "$PKGROOT/usr/share/nebula/examples/"

# ─── build ──────────────────────────────────────────────────────────────────
echo "[nebula] building .deb"
mkdir -p "${POOL_DIR}/nebula"
dpkg-deb --build --root-owner-group "$PKGROOT" "${POOL_DIR}/nebula/nebula_${version}_amd64.deb"
echo "[nebula] package created → ${POOL_DIR}/nebula/nebula_${version}_amd64.deb"
