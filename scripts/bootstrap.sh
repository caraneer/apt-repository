#!/bin/bash
set -euo pipefail

echo "Determining script directory…"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
echo "SCRIPT_DIR is $SCRIPT_DIR"

echo "Updating apt cache…"
sudo apt update

echo "Installing s3fs (no-install-recommends)…"
sudo apt install -y --no-install-recommends s3fs || true

echo "Ensuring ~/.ssh exists…"
mkdir -p ~/.ssh

echo "Writing SSH key to ~/.ssh/id_rsa…"
echo "${SSH_KEY}" > ~/.ssh/id_rsa
echo "Setting permissions on private key…"
chmod 600 ~/.ssh/id_rsa

echo "Mounting remote directory via s3fs…"
s3fs "${S3_BUCKET_NAME}" "${S3_MOUNT_PATH}" \
    -o "url=${S3_URL}" \
    -o use_path_request_style \
    -o default_acl=public-read \
    -o update_parent_dir_stat \
    ;

echo "Discovering local .deb files in ${SCRIPT_DIR}/../bootstrap_pkgs…"
readarray -t LOCAL_DEBS < <(find "${SCRIPT_DIR}/../bootstrap_pkgs" \
                           -maxdepth 1 -type f -name '*.deb' | sort)
echo "Found ${#LOCAL_DEBS[@]} .deb files: ${LOCAL_DEBS[*]}"

echo "Installing local .deb packages…"
sudo apt install -y --no-install-recommends "${LOCAL_DEBS[@]}"

echo "All steps completed successfully."
