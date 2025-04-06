#!/bin/sh
# This is script is made to index packages 
set -euo pipefail

export SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
# export WEBROOT_DIR=$(cd -- "${SCRIPT_DIR}" && cd ../www && pwd);
# This is really to represent that we don't have any runtime dependencies (other than perhaps other packages which we
# distribute) other than glibc. We also make best-efforts to build for "old" yet still supported versions of glibc.
# Currently that means building on the oldest version of ubuntu that GitHub lets us.
export PKG_DISTRO="gnu-generic";

${SCRIPT_DIR}/check-for-dependencies.sh;
gh auth status;

echo "WEBROOT_DIR=$WEBROOT_DIR";

echo "Step 1: get deb pkgs";
cd "${SCRIPT_DIR}"
find ./get -maxdepth 2 -type f -name "get.sh" ! -name "* *" ! -name "." -exec {} \;

echo "Step 2: dpkg-scanpackages";
for release_channel in "arm64" "amd64"; do
	for arch in "arm64" "amd64"; do
		echo "Building index for ${PKG_DISTRO} ${release_channel} ${arch}";
		dists_dir="${WEBROOT_DIR}/dists/${PKG_DISTRO}/${release_channel}/binary-${arch}";
		mkdir -p "${dists_dir}";
		mkdir -p "${WEBROOT_DIR}/pool/${PKG_DISTRO}/${release_channel}"; # Needed so we build an empty index
		cd "${WEBROOT_DIR}";
		dpkg-scanpackages --multiversion --arch "${arch}" "pool/${PKG_DISTRO}/${release_channel}" > "${dists_dir}/Packages";
		cat "${dists_dir}/Packages" | gzip -9 > "${dists_dir}/Packages.gz";
	done;
done;

echo "Step 3: generate release files";
cd "${WEBROOT_DIR}/dists/${PKG_DISTRO}";
${SCRIPT_DIR}/generate-release.sh > Release;
cat Release | gpg --default-key "Aritz's Release Key" -abs > Release.gpg
cat Release | gpg --default-key "Aritz's Release Key" -abs --clearsign > InRelease

echo "Step 4: generate folder indexs";
cd "${WEBROOT_DIR}";
find . -type d -print -exec sh -c 'tree "$0" \
    -H "." \
    -L 1 \
    --noreport \
    --dirsfirst \
    --charset utf-8 \
    -I "index.html" \
    -T "Index of /$(echo $0 | cut -c3-)" \
    --ignore-case \
    --timefmt "%d-%b-%Y %H:%M" \
    -s \
    -D \
    -C \
    -i \
    -o "$0/index.html"; sed -i "s/  .VERSION.*/  .VERSION { display: none; }/g" "$0/index.html"; sed -i "s|<a class=\"DIR\" href=\"[./]*\">\.</a>|<a class=\"DIR\" href=\"..\">..</a>|g" "$0/index.html";' {} \;
