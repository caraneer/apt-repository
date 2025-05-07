#!/bin/bash
set -euo pipefail

echo "Determining script directory…"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
echo "SCRIPT_DIR is $SCRIPT_DIR"

echo "Updating apt cache…"
sudo apt update

echo "Installing sshfs (no-install-recommends)…"
sudo apt install -y --no-install-recommends sshfs || true

echo "Ensuring ~/.ssh exists…"
mkdir -p ~/.ssh

echo "Writing SSH key to ~/.ssh/id_rsa…"
echo "${SSH_KEY}" > ~/.ssh/id_rsa
echo "Setting permissions on private key…"
chmod 600 ~/.ssh/id_rsa

echo "Scanning SSH host key…"
ssh-keyscan -H "${SSH_HOST}" >> ~/.ssh/known_hosts

echo "Ensuring mount point exists at ${SSH_MOUNT_PATH}…"
mkdir -p "${SSH_MOUNT_PATH}"

echo "Mounting remote directory via sshfs…"
sshfs -o IdentityFile=~/.ssh/id_rsa,StrictHostKeyChecking=no \
      "${SSH_USER}@${SSH_HOST}:${SSH_REMOTE_PATH}" \
      "${SSH_MOUNT_PATH}"

echo "Discovering local .deb files in ${SCRIPT_DIR}/../bootstrap_pkgs…"
readarray -t LOCAL_DEBS < <(find "${SCRIPT_DIR}/../bootstrap_pkgs" \
                           -maxdepth 1 -type f -name '*.deb' | sort)
echo "Found ${#LOCAL_DEBS[@]} .deb files: ${LOCAL_DEBS[*]}"

echo "Installing local .deb packages…"
sudo apt install -y --no-install-recommends "${LOCAL_DEBS[@]}"

echo "All steps completed successfully."
