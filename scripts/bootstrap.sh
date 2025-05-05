#!/bin/bash
set -euo pipefail
export SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P);
sudo apt update

cat <<'EOF' | envsubst | sudo debconf-set-selections --verbose
s3ql s3ql/mounts.amount string 1
s3ql s3ql/mounts.0.scheme select ${S3QL_SCHEME}
s3ql s3ql/mounts.0.hostname string ${S3QL_HOSTNAME}
s3ql s3ql/mounts.0.bucket string ${S3QL_BUCKET}
s3ql s3ql/mounts.0.access_key string ${S3QL_ACCESS_KEY}
s3ql s3ql/mounts.0.secret_key password ${S3QL_SECRET_KEY}
s3ql s3ql/mounts.0.mount_path string ${S3QL_MOUNT_PATH}
EOF

readarray -t LOCAL_DEBS < <(find "${SCRIPT_DIR}/../bootstrap_pkgs" -maxdepth 1 -type f -name '*.deb' | sort)

sudo apt install -y --no-install-recommends "${LOCAL_DEBS[@]}"
sudo systemctl start s3ql-mounts.service
