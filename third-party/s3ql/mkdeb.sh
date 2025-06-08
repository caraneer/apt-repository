#!/bin/bash
# For some reason I thought s3ql was on pip, even though that's wrong, I'll still
set -euo pipefail

SOURCEDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
WORKDIR="$(mktemp -d -t s3ql-deb.XXXXXXXXXX)"
echo "WORKDIR=$WORKDIR";
PKGROOT="$WORKDIR/pkg"

echo "Preparing package directory..."
mkdir -p "$PKGROOT";

# Copy package files
cp -r "$SOURCEDIR/DEBIAN" "$PKGROOT/DEBIAN"
cp -r "$SOURCEDIR/usr" "$PKGROOT/usr"
simconf toml-to-template "$SOURCEDIR/templates.toml" "$PKGROOT/DEBIAN/templates"

# Download the thing
echo "Fetching latest non-pre-release S3QL release using gh CLI..."

release_json=$(gh release view --repo s3ql/s3ql --json tagName,assets)
tag=$(echo "$release_json" | jq -r '.tagName')
version="${tag#s3ql-}"
if [[ "${version}" = "5.3.0" ]]; then
    version="${version}-2"
else
    version="${version}-1"
fi;
sed "s/VERSION_REPLACEME/$version/" "$SOURCEDIR/DEBIAN/control" > "$PKGROOT/DEBIAN/control"

asset_url=$(echo "$release_json" |
	jq -r '.assets[] | select(.name | test("^s3ql-.*\\.tar\\.gz$")) | .url')

echo "Latest release: $tag (version $version)"
echo "Downloading: $asset_url"

gh api "$asset_url" > "$WORKDIR/s3ql.tar.gz"

echo "Extracting..."
mkdir -p $PKGROOT/usr/share/s3ql;
tar -xzf "$WORKDIR/s3ql.tar.gz" --strip-components=1 -C "$PKGROOT/usr/share/s3ql"

for bin in "$PKGROOT/usr/share/s3ql/bin"/*; do
	base=$(basename "$bin")
	wrapper="$PKGROOT/usr/sbin/$base"
	echo "#!/bin/sh
VENV_DIR=\"/opt/s3ql-venv\"
export PATH=\"\$VENV_DIR/bin:\$PATH\"
export VIRTUAL_ENV=\"\$VENV_DIR\"
exec \"\$VENV_DIR/bin/$base\" \"\$@\"
" > "$wrapper"
	chmod +x "$wrapper"
done

echo "Building package..."
mkdir -p "${POOL_DIR}/s3ql"
dpkg-deb --build --root-owner-group "$PKGROOT" "${POOL_DIR}/s3ql/s3ql_${version}_all.deb"
echo "Done: ${POOL_DIR}/s3ql/s3ql_${version}_all.deb"
