#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

sudo apt update
sudo apt install -y --no-install-recommends SSH

mkdir -p ~/.ssh
echo "${SSH_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

ssh-keyscan -H "${SSH_HOST}" >> ~/.ssh/known_hosts

mkdir -p "${SSH_MOUNT_PATH}"
sshfs -o IdentityFile=~/.ssh/id_rsa,StrictHostKeyChecking=no \
      "${SSH_USER}@${SSH_HOST}:${SSH_REMOTE_PATH}" \
      "${SSH_MOUNT_PATH}"

readarray -t LOCAL_DEBS < <(find "${SCRIPT_DIR}/../bootstrap_pkgs" \
                           -maxdepth 1 -type f -name '*.deb' | sort)
sudo apt install -y --no-install-recommends "${LOCAL_DEBS[@]}"
