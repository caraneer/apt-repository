#!/bin/bash
# This scripts expects to ran in the working directory with the same name as the distro codename
set -euo pipefail
distro="$(basename $(pwd))";
do_hash() {
    HASH_NAME=$1
    HASH_CMD=$2
    echo "${HASH_NAME}:"
    for f in $(find -type f); do
        f=$(echo $f | cut -c3-) # remove ./ prefix
        # Don't include old release file(s)
        if [ "$f" = "Release" ] || [ "$f" = "Release.gpg" ] || [ "$f" = "InRelease" ]; then
            continue
        fi
        # Don't include auto-generated index.html's
        if echo "$f" | grep -qE "(^|/)index.html$"; then
            continue;
        fi;
        echo " $(${HASH_CMD} ${f}  | cut -d" " -f1) $(wc -c $f)"
    done
}
folders=$(find . -maxdepth 1 -type d ! -name "* *" ! -name "." -printf "%f ")
cat << EOF
Origin: Caraneer Software Inc. Debian package repository
Label: caraneer
Suite: stable
Codename: ${distro}
Architectures: all arm64 amd64
Components: ${folders}
Description: Software distribution for Caraneer Software Inc. Provided AS-IS.
Date: $(date -Ru)
EOF
do_hash "MD5Sum" "md5sum"
do_hash "SHA1" "sha1sum"
do_hash "SHA256" "sha256sum"
do_hash "SHA512" "sha512sum"
