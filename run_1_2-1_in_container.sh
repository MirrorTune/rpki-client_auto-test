#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Docker イメージ rpki-client-test:latest をビルドします..."
BUILD_ARGS=()
if [[ -n "${RPKI_CLIENT_VERSION:-}" ]]; then
  BUILD_ARGS+=(--build-arg "RPKI_CLIENT_VERSION=${RPKI_CLIENT_VERSION}")
fi
docker build "${BUILD_ARGS[@]}" -t rpki-client-test:latest "${SCRIPT_DIR}"

echo "[INFO] コンテナ内で 1_2-1_check_tal_directory.sh を実行します..."

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  --entrypoint /bin/bash \
  -e TAL_DIR="${TAL_DIR:-}" \
  -v "${SCRIPT_DIR}:/work" \
  -w /work \
  rpki-client-test:latest \
  1_2-1_check_tal_directory.sh

