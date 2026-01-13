#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします..."
docker build -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 1_1-1_check_rpki_client_installed.sh を実行します..."

docker run --rm \
  --entrypoint /bin/bash \
  -e RPKI_CLIENT_BIN="${RPKI_CLIENT_BIN:-/usr/local/sbin/rpki-client}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  1_1-1_check_rpki_client_installed.sh

